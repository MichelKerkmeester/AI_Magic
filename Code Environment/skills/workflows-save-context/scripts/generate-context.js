#!/usr/bin/env node

/**
 * Save Context - Generate Expanded Conversation Documentation
 *
 * This script generates comprehensive conversation context documentation
 * from conversation session data provided via JSON input file.
 */

const fs = require('fs/promises');
const fsSync = require('fs');
const path = require('path');
const readline = require('readline');

// Content filtering stats (filtering happens in transform-transcript.js)
const { getFilterStats } = require('./lib/content-filter');

// Semantic summarization for meaningful implementation summaries
const {
  generateImplementationSummary,
  formatSummaryAsMarkdown,
  extractFileChanges
} = require('./lib/semantic-summarizer');

// ───────────────────────────────────────────────────────────────
// CONFIGURATION
// ───────────────────────────────────────────────────────────────

// Load configuration from config.jsonc with fallback to defaults
// Documentation comments are placed below the JSON object in config.jsonc
function loadConfig() {
  const defaultConfig = {
    maxResultPreview: 500,
    maxConversationMessages: 100,
    maxToolOutputLines: 100,
    messageTimeWindow: 300000,
    contextPreviewHeadLines: 50,
    contextPreviewTailLines: 20,
    timezoneOffsetHours: 0
  };

  const configPath = path.join(__dirname, '..', 'config.jsonc');

  try {
    if (fsSync.existsSync(configPath)) {
      const configContent = fsSync.readFileSync(configPath, 'utf-8');

      // Extract only the JSON portion (everything before the first // comment line)
      const lines = configContent.split('\n');
      let jsonEndIndex = lines.length;

      for (let i = 0; i < lines.length; i++) {
        const trimmedLine = lines[i].trim();
        if (trimmedLine.startsWith('//')) {
          jsonEndIndex = i;
          break;
        }
      }

      const jsonContent = lines.slice(0, jsonEndIndex).join('\n');
      const userConfig = JSON.parse(jsonContent);
      return { ...defaultConfig, ...userConfig };
    }
  } catch (error) {
    console.warn(`⚠️  Failed to load config.jsonc: ${error.message}`);
    console.warn('   Using default configuration values');
  }

  return defaultConfig;
}

const userConfig = loadConfig();

const CONFIG = {
  SKILL_VERSION: '1.3.0',
  MESSAGE_COUNT_TRIGGER: 20, // Auto-save every 20 messages
  MAX_RESULT_PREVIEW: userConfig.maxResultPreview,
  MAX_CONVERSATION_MESSAGES: userConfig.maxConversationMessages,
  MAX_TOOL_OUTPUT_LINES: userConfig.maxToolOutputLines,
  TRUNCATE_FIRST_LINES: userConfig.contextPreviewHeadLines,
  TRUNCATE_LAST_LINES: userConfig.contextPreviewTailLines,
  MESSAGE_TIME_WINDOW: userConfig.messageTimeWindow,
  TIMEZONE_OFFSET_HOURS: userConfig.timezoneOffsetHours,
  TOOL_PREVIEW_LINES: 10, // lines to show in tool result preview
  TEMPLATE_DIR: path.join(__dirname, '..', 'templates'),
  PROJECT_ROOT: process.cwd(),
  DATA_FILE: process.argv[2] || null, // Accept data file as first argument
  SPEC_FOLDER_ARG: process.argv[3] || null // Accept spec folder as second argument (optional)
};

// ───────────────────────────────────────────────────────────────
// ARGUMENT VALIDATION
// ───────────────────────────────────────────────────────────────

/**
 * Validate command-line arguments early to provide helpful error messages
 */
function validateArguments() {
  // Validate SPEC_FOLDER_ARG format if provided
  if (CONFIG.SPEC_FOLDER_ARG) {
    // Check format: must be ###-name
    if (!/^\d{3}-/.test(CONFIG.SPEC_FOLDER_ARG)) {
      console.error(`\n❌ Invalid spec folder format: ${CONFIG.SPEC_FOLDER_ARG}`);
      console.error('Expected format: ###-feature-name (e.g., "122-skill-standardization")\n');

      // Try to find similar folders
      const specsDir = path.join(CONFIG.PROJECT_ROOT, 'specs');
      if (fsSync.existsSync(specsDir)) {
        try {
          const available = fsSync.readdirSync(specsDir);
          const matches = available.filter(name =>
            name.includes(CONFIG.SPEC_FOLDER_ARG) && /^\d{3}-/.test(name)
          );

          if (matches.length > 0) {
            console.error('Did you mean one of these?');
            matches.forEach(match => console.error(`  - ${match}`));
            console.error('');
          } else {
            // Show all available spec folders
            const allSpecs = available
              .filter(name => /^\d{3}-/.test(name))
              .filter(name => !name.match(/^(z_|.*archive.*|.*old.*|.*\.archived.*)/i))
              .sort()
              .reverse();

            if (allSpecs.length > 0) {
              console.error('Available spec folders:');
              allSpecs.slice(0, 5).forEach(folder => {
                console.error(`  - ${folder}`);
              });
              if (allSpecs.length > 5) {
                console.error(`  ... and ${allSpecs.length - 5} more\n`);
              } else {
                console.error('');
              }
            }
          }
        } catch {
          // Silently ignore read errors
        }
      }

      console.error('Usage: node generate-context.js <data-file> [spec-folder-name]\n');
      process.exit(1);
    }
  }
}

// Run validation immediately
validateArguments();

// ───────────────────────────────────────────────────────────────
// CONTEXT BUDGET MANAGEMENT
// ───────────────────────────────────────────────────────────────

/**
 * Check if auto-save should trigger based on message count
 * @param {number} messageCount - Total number of messages in conversation
 * @returns {boolean} - True if should auto-save
 */
function shouldAutoSave(messageCount) {
  // Auto-save every MESSAGE_COUNT_TRIGGER messages
  if (messageCount > 0 && messageCount % CONFIG.MESSAGE_COUNT_TRIGGER === 0) {
    return true;
  }
  return false;
}

// ───────────────────────────────────────────────────────────────
// DATA LOADING
// ───────────────────────────────────────────────────────────────

async function loadCollectedData() {
  if (!CONFIG.DATA_FILE) {
    console.log('   ⚠️  No data file provided, using fallback simulation mode');
    return null;
  }

  try {
    const dataContent = await fs.readFile(CONFIG.DATA_FILE, 'utf-8');
    const data = JSON.parse(dataContent);
    console.log('   ✓ Loaded conversation data');
    return data;
  } catch (error) {
    console.log(`   ⚠️  Failed to load data file: ${error.message}`);
    console.log('   ⚠️  Falling back to simulation mode');
    return null;
  }
}

// ───────────────────────────────────────────────────────────────
// HELPER FUNCTIONS
// ───────────────────────────────────────────────────────────────

/**
 * Format timestamp with multiple output formats
 * @param {Date|string} date - Date to format (defaults to current time)
 * @param {string} format - Output format: 'iso' | 'readable' | 'date' | 'time' | 'filename' | 'date-dutch' | 'time-short'
 * @returns {string} Formatted timestamp
 */
function formatTimestamp(date = new Date(), format = 'iso') {
  const d = date instanceof Date ? date : new Date(date);

  // Validate date
  if (isNaN(d.getTime())) {
    console.warn(`⚠️  Invalid date: ${date}, using current time`);
    return formatTimestamp(new Date(), format);
  }

  // Apply timezone offset (convert hours to milliseconds)
  const offsetMs = CONFIG.TIMEZONE_OFFSET_HOURS * 60 * 60 * 1000;
  const adjustedDate = new Date(d.getTime() + offsetMs);

  const isoString = adjustedDate.toISOString();
  const [datePart, timePart] = isoString.split('T');
  const timeWithoutMs = timePart.split('.')[0];

  switch (format) {
    case 'iso':
      return isoString.split('.')[0] + 'Z'; // 2025-11-08T14:30:00Z

    case 'readable':
      return `${datePart} @ ${timeWithoutMs}`; // 2025-11-08 @ 14:30:00

    case 'date':
      return datePart; // 2025-11-08

    case 'date-dutch': {
      // Dutch format: DD-MM-YY
      const [year, month, day] = datePart.split('-');
      const shortYear = year.slice(-2); // Last 2 digits of year
      return `${day}-${month}-${shortYear}`; // 09-11-25
    }

    case 'time':
      return timeWithoutMs; // 14:30:00

    case 'time-short': {
      // Short time format: HH-MM (no seconds)
      const [hours, minutes] = timeWithoutMs.split(':');
      return `${hours}-${minutes}`; // 14-30
    }

    case 'filename':
      return `${datePart}_${timeWithoutMs.replace(/:/g, '-')}`; // 2025-11-08_14-30-00

    default:
      console.warn(`⚠️  Unknown format "${format}", using ISO`);
      return isoString;
  }
}

function truncateToolOutput(output, maxLines = CONFIG.MAX_TOOL_OUTPUT_LINES) {
  if (!output) return '';

  const lines = output.split('\n');

  if (lines.length <= maxLines) {
    return output;
  }

  const firstLines = lines.slice(0, CONFIG.TRUNCATE_FIRST_LINES);
  const lastLines = lines.slice(-CONFIG.TRUNCATE_LAST_LINES);
  const truncatedCount = lines.length - CONFIG.TRUNCATE_FIRST_LINES - CONFIG.TRUNCATE_LAST_LINES;

  return [
    ...firstLines,
    '',
    `... [Truncated: ${truncatedCount} lines] ...`,
    '',
    ...lastLines
  ].join('\n');
}

/**
 * V8.2: Normalize file paths to clean relative format
 * @param {string} filePath - Raw file path (absolute or relative)
 * @param {string} projectRoot - Project root directory
 * @returns {string} Clean relative path
 */
function toRelativePath(filePath, projectRoot = CONFIG.PROJECT_ROOT) {
  if (!filePath) return '';
  let cleaned = filePath;

  // Strip project root if absolute
  if (cleaned.startsWith(projectRoot)) {
    cleaned = cleaned.slice(projectRoot.length);
    // Remove leading slash
    if (cleaned.startsWith('/')) cleaned = cleaned.slice(1);
  }

  // Strip any leading ./
  cleaned = cleaned.replace(/^\.\//, '');

  // For very long paths (>60 chars), abbreviate middle
  if (cleaned.length > 60) {
    const parts = cleaned.split('/');
    if (parts.length > 3) {
      return `${parts[0]}/.../${parts.slice(-2).join('/')}`;
    }
  }

  return cleaned;
}

/**
 * V8.3: Validate if a description is meaningful (not garbage)
 * @param {string} description - File description to validate
 * @returns {boolean} True if description is valid and meaningful
 */
function isDescriptionValid(description) {
  if (!description || description.length < 8) return false;

  const garbagePatterns = [
    /^#+\s/,                            // Markdown headers: ## Foo
    /^[-*]\s/,                          // List bullets: - foo, * bar
    /\s(?:and|or|to|the)\s*$/i,         // Incomplete: "Fixed the"
    /^(?:modified?|updated?)\s+\w+$/i,  // Generic: "Modified file"
    /^filtering\s+(?:pipeline|system)$/i, // Generic fallback
    /^And\s+[`'"]?/i,                   // Fragment: "And `foo"
    /^Modified during session$/i,       // Default fallback
    /\[PLACEHOLDER\]/i,                 // Unfilled template
  ];

  return !garbagePatterns.some(p => p.test(description));
}

/**
 * V8.3: Clean description text for display
 * @param {string} desc - Raw description
 * @returns {string} Cleaned description
 */
function cleanDescription(desc) {
  if (!desc) return '';
  let cleaned = desc.trim();

  // Remove markdown formatting
  cleaned = cleaned.replace(/^#+\s+/, '');        // ## headers
  cleaned = cleaned.replace(/^[-*]\s+/, '');      // - bullets
  cleaned = cleaned.replace(/`([^`]+)`/g, '$1');  // `backticks`
  cleaned = cleaned.replace(/\*\*([^*]+)\*\*/g, '$1'); // **bold**

  // Remove trailing punctuation
  cleaned = cleaned.replace(/[.,;:]+$/, '');

  // Truncate to max 60 chars
  if (cleaned.length > 60) {
    cleaned = cleaned.substring(0, 57) + '...';
  }

  // Capitalize first letter
  if (cleaned.length > 0) {
    cleaned = cleaned.charAt(0).toUpperCase() + cleaned.slice(1);
  }

  return cleaned;
}

/**
 * Detect tool calls from conversation facts with strict pattern matching
 * Avoids false positives from prose text like "Read more about..."
 * @param {string} text - Text to analyze for tool calls
 * @returns {Object|null} { tool: string, confidence: string } or null
 */
function detectToolCall(text) {
  if (!text || typeof text !== 'string') return null;

  // Pattern 1: Explicit tool marker "Tool: Read"
  const explicitMatch = text.match(/\bTool:\s*(\w+)/i);
  if (explicitMatch) {
    return { tool: explicitMatch[1], confidence: 'high' };
  }

  // Pattern 2: Tool call syntax "Read(" at start or after whitespace
  const callSyntaxMatch = text.match(/^\s*(Read|Edit|Write|Bash|Grep|Glob|Task|WebFetch|WebSearch|Skill)\s*\(/);
  if (callSyntaxMatch) {
    return { tool: callSyntaxMatch[1], confidence: 'high' };
  }

  // Pattern 3: Using tool phrase "using Read tool"
  const usingToolMatch = text.match(/\busing\s+(Read|Edit|Write|Bash|Grep|Glob|Task|WebFetch|WebSearch)\s+tool\b/i);
  if (usingToolMatch) {
    return { tool: usingToolMatch[1], confidence: 'medium' };
  }

  // Pattern 4: Called tool phrase "called Read(...)"
  const calledMatch = text.match(/\bcalled?\s+(Read|Edit|Write|Bash|Grep|Glob|Task|WebFetch|WebSearch)\s*\(/i);
  if (calledMatch) {
    return { tool: calledMatch[1], confidence: 'medium' };
  }

  return null;
}

/**
 * Check if detected tool match is actually prose context (not a real tool call)
 * @param {string} text - Full text being analyzed
 * @param {number} matchStartIndex - Index where match was found
 * @returns {boolean} True if this is prose context, false if legitimate tool call
 */
function isProseContext(text, matchStartIndex) {
  if (matchStartIndex < 0) return false;

  const before = text.substring(Math.max(0, matchStartIndex - 20), matchStartIndex);
  const after = text.substring(matchStartIndex, Math.min(text.length, matchStartIndex + 50));

  // Check for sentence boundaries around match
  const sentenceBefore = /[.!?]\s*$/;
  const lowercaseAfter = /^[a-z]/; // Tool names should be capitalized

  if (sentenceBefore.test(before) && lowercaseAfter.test(after)) {
    return true;
  }

  // Check for common prose patterns: "read more", "read about", "to read"
  const contextWindow = before.substring(Math.max(0, before.length - 10)) + after.substring(0, 30);
  const prosePatterns = [
    /\bread\s+more\b/i,
    /\bread\s+about\b/i,
    /\bread\s+the\b/i,
    /\bto\s+read\b/i,
    /\byou\s+should\s+read\b/i
  ];

  for (const pattern of prosePatterns) {
    if (pattern.test(contextWindow)) {
      return true;
    }
  }

  return false;
}

function summarizeExchange(userMessage, assistantResponse, toolCalls = []) {
  // V6.4: Create intelligent 2-3 sentence summary with better truncation
  // Extract first complete sentence if possible, otherwise use 200 chars
  let userIntent;
  if (userMessage.length <= 200) {
    userIntent = userMessage;
  } else {
    // Try to find a sentence boundary
    const sentenceEnd = userMessage.substring(0, 200).match(/^(.+?[.!?])\s/);
    userIntent = sentenceEnd ? sentenceEnd[1] : userMessage.substring(0, 200) + '...';
  }

  const mainTools = toolCalls.slice(0, 3).map(t => t.tool).join(', ');
  const toolSummary = toolCalls.length > 0
    ? ` Used tools: ${mainTools}${toolCalls.length > 3 ? ` and ${toolCalls.length - 3} more` : ''}.`
    : '';

  // V6.4: Extract key outcome from assistant response (first 2 sentences or 300 chars)
  const sentences = assistantResponse.match(/[^.!?]+[.!?]+/g) || [];
  const outcome = sentences.length > 0
    ? sentences.slice(0, 2).join(' ').trim()
    : assistantResponse.substring(0, 300);

  return {
    userIntent,
    outcome: outcome + (outcome.length < assistantResponse.length ? '...' : ''),
    toolSummary,
    fullSummary: `${userIntent} → ${outcome}${toolSummary}`
  };
}

function classifyConversationPhase(toolCalls, messageContent) {
  // Detect phase based on tools used and content
  const tools = toolCalls.map(t => t.tool?.toLowerCase() || '');
  const content = messageContent.toLowerCase();

  // Research phase: mostly reads, greps, globs
  if (tools.some(t => ['read', 'grep', 'glob', 'webfetch', 'websearch'].includes(t))) {
    return 'Research';
  }

  // Planning phase: asking questions, discussing approaches
  if (content.includes('plan') || content.includes('approach') || content.includes('should we')) {
    return 'Planning';
  }

  // Implementation phase: edits, writes
  if (tools.some(t => ['edit', 'write', 'bash'].includes(t))) {
    return 'Implementation';
  }

  // Debugging phase: error keywords
  if (content.includes('error') || content.includes('fix') || content.includes('debug')) {
    return 'Debugging';
  }

  // Verification phase: testing keywords
  if (content.includes('test') || content.includes('verify') || content.includes('check')) {
    return 'Verification';
  }

  return 'Discussion';
}

function extractKeyArtifacts(messages) {
  const artifacts = {
    filesCreated: [],
    filesModified: [],
    commandsExecuted: [],
    errorsEncountered: []
  };

  for (const msg of messages) {
    if (!msg.tool_calls) continue;

    for (const tool of msg.tool_calls) {
      const toolName = tool.tool?.toLowerCase() || '';

      if (toolName === 'write') {
        artifacts.filesCreated.push({
          path: tool.file_path || 'unknown',
          timestamp: msg.timestamp
        });
      } else if (toolName === 'edit') {
        artifacts.filesModified.push({
          path: tool.file_path || 'unknown',
          timestamp: msg.timestamp
        });
      } else if (toolName === 'bash') {
        artifacts.commandsExecuted.push({
          command: tool.command || 'unknown',
          timestamp: msg.timestamp
        });
      }

      // Check for errors in tool results
      if (tool.result && typeof tool.result === 'string') {
        if (tool.result.includes('Error:') || tool.result.includes('error:')) {
          artifacts.errorsEncountered.push({
            error: tool.result.substring(0, 200),
            timestamp: msg.timestamp
          });
        }
      }
    }
  }

  return artifacts;
}

function validateDataStructure(data) {
  // Ensure all required boolean flags are set
  const validated = { ...data };

  // Set boolean flags based on data presence
  if (validated.CODE_BLOCKS) {
    validated.HAS_CODE_BLOCKS = Array.isArray(validated.CODE_BLOCKS) && validated.CODE_BLOCKS.length > 0;
  }

  if (validated.PROS) {
    // Ensure PROS is array of objects
    if (!Array.isArray(validated.PROS)) {
      validated.PROS = validated.PROS ? [{ PRO: String(validated.PROS) }] : [];
    } else if (validated.PROS.length > 0 && typeof validated.PROS[0] === 'string') {
      validated.PROS = validated.PROS.map(p => ({ PRO: p }));
    }
  }

  if (validated.CONS) {
    // Ensure CONS is array of objects
    if (!Array.isArray(validated.CONS)) {
      validated.CONS = validated.CONS ? [{ CON: String(validated.CONS) }] : [];
    } else if (validated.CONS.length > 0 && typeof validated.CONS[0] === 'string') {
      validated.CONS = validated.CONS.map(c => ({ CON: c }));
    }
  }

  // Only set HAS_PROS_CONS if arrays have content
  if (validated.PROS && Array.isArray(validated.PROS) && validated.PROS.length > 0) {
    validated.HAS_PROS_CONS = true;
  } else if (validated.CONS && Array.isArray(validated.CONS) && validated.CONS.length > 0) {
    validated.HAS_PROS_CONS = true;
  } else {
    validated.HAS_PROS_CONS = false;
  }

  if (validated.DESCRIPTION) {
    validated.HAS_DESCRIPTION = true;
  }

  if (validated.NOTES) {
    validated.HAS_NOTES = Array.isArray(validated.NOTES) && validated.NOTES.length > 0;
  }

  if (validated.RELATED_FILES) {
    validated.HAS_RELATED_FILES = Array.isArray(validated.RELATED_FILES) && validated.RELATED_FILES.length > 0;
  }

  if (validated.RESULT_PREVIEW) {
    validated.HAS_RESULT = true;
  }

  if (validated.DECISION_TREE) {
    validated.HAS_DECISION_TREE = true;
  }

  if (validated.CAVEATS) {
    validated.HAS_CAVEATS = Array.isArray(validated.CAVEATS) && validated.CAVEATS.length > 0;
  }

  if (validated.FOLLOWUP) {
    validated.HAS_FOLLOWUP = Array.isArray(validated.FOLLOWUP) && validated.FOLLOWUP.length > 0;
  }

  // Add missing boolean flags
  if (validated.OPTIONS) {
    validated.HAS_OPTIONS = Array.isArray(validated.OPTIONS) && validated.OPTIONS.length > 0;
  }

  if (validated.EVIDENCE) {
    validated.HAS_EVIDENCE = Array.isArray(validated.EVIDENCE) && validated.EVIDENCE.length > 0;
  }

  if (validated.PHASES) {
    validated.HAS_PHASES = Array.isArray(validated.PHASES) && validated.PHASES.length > 0;
  }

  if (validated.MESSAGES) {
    validated.HAS_MESSAGES = Array.isArray(validated.MESSAGES) && validated.MESSAGES.length > 0;
  }

  // Recursively validate nested arrays
  for (const key in validated) {
    if (Array.isArray(validated[key])) {
      validated[key] = validated[key].map(item => {
        if (typeof item === 'object' && item !== null) {
          return validateDataStructure(item);
        }
        return item;
      });
    }
  }

  return validated;
}

// ───────────────────────────────────────────────────────────────
// MAIN WORKFLOW
// ───────────────────────────────────────────────────────────────

async function main() {
  try {
    console.log('🚀 Starting save-context skill...\n');

    // Step 1: Load collected data
    console.log('📥 Step 1: Loading collected data...');
    const collectedData = await loadCollectedData();
    console.log(`   ✓ Loaded data from ${collectedData ? 'data file' : 'simulation'}\n`);

    // Step 2: Detect spec folder with context alignment
    console.log('📁 Step 2: Detecting spec folder...');
    const specFolder = await detectSpecFolder(collectedData);
    const specFolderName = path.basename(specFolder);
    console.log(`   ✓ Using: ${specFolder}\n`);

    // Step 3: Setup context directory
    console.log('📂 Step 3: Setting up context directory...');
    const contextDir = await setupContextDirectory(specFolder);
    console.log(`   ✓ Created: ${contextDir}\n`);

    // Steps 4-7: Parallel data extraction (optimized for 50-60% faster execution)
    console.log('🔄 Steps 4-7: Extracting data (parallel execution)...\n');

    const [sessionData, conversations, decisions, diagrams, workflowData] = await Promise.all([
      (async () => {
        console.log('   📋 Collecting session data...');
        const result = await collectSessionData(collectedData, specFolderName);
        console.log('   ✓ Session data collected');
        return result;
      })(),
      (async () => {
        console.log('   💬 Extracting conversations...');
        const result = await extractConversations(collectedData);
        console.log(`   ✓ Found ${result.MESSAGES.length} messages`);
        return result;
      })(),
      (async () => {
        console.log('   🧠 Extracting decisions...');
        const result = await extractDecisions(collectedData);
        console.log(`   ✓ Found ${result.DECISIONS.length} decisions`);
        return result;
      })(),
      (async () => {
        console.log('   📊 Extracting diagrams...');
        const result = await extractDiagrams(collectedData);
        console.log(`   ✓ Found ${result.DIAGRAMS.length} diagrams`);
        return result;
      })(),
      (async () => {
        console.log('   🔀 Generating workflow flowchart...');
        const phases = extractPhasesFromData(collectedData);
        const flowchart = generateWorkflowFlowchart(phases);
        const patternType = detectWorkflowPattern(phases);
        const phaseDetails = buildPhaseDetails(phases);

        // Extract features and use cases
        const features = extractFlowchartFeatures(phases, patternType);
        const useCases = getPatternUseCases(patternType);

        // Generate use case title from cached spec folder name
        const useCaseTitle = specFolderName.replace(/^\d+-/, '').replace(/-/g, ' ');

        console.log(`   ✓ Workflow data generated (${patternType}) - flowchart disabled for cleaner output`);
        return {
          WORKFLOW_FLOWCHART: flowchart,
          HAS_WORKFLOW_DIAGRAM: false, // Disabled: bullets-only mode per user preference
          PATTERN_TYPE: patternType.charAt(0).toUpperCase() + patternType.slice(1),
          PATTERN_LINEAR: patternType === 'linear',
          PATTERN_PARALLEL: patternType === 'parallel',
          PHASES: phaseDetails,
          HAS_PHASES: phaseDetails.length > 0,
          USE_CASE_TITLE: useCaseTitle,
          FEATURES: features,
          USE_CASES: useCases
        };
      })()
    ]);

    console.log('\n   ✅ All extraction complete (parallel execution)\n');

    // Step 7.5: Generate semantic implementation summary
    console.log('🧠 Step 7.5: Generating semantic summary...');

    // Get RAW user prompts BEFORE any filtering for semantic analysis
    // Using unfiltered data preserves context for better classification
    const rawUserPrompts = collectedData?.user_prompts || [];
    const allMessages = rawUserPrompts.map(m => ({
      prompt: m.prompt || '',
      content: m.prompt || '',
      timestamp: m.timestamp
    }));

    // Generate implementation summary with semantic understanding
    const implementationSummary = generateImplementationSummary(
      allMessages,
      collectedData?.observations || []
    );

    // Enhance FILES with semantic descriptions from the summarizer
    const semanticFileChanges = extractFileChanges(allMessages, collectedData?.observations || []);

    // V5.2: Helper with null safety - Extract basename from path for exact matching
    const getBasename = (p) => {
      if (!p || typeof p !== 'string') return '';
      return p.split('/').pop() || '';
    };

    // Merge semantic file descriptions into sessionData.FILES
    // FIX v4: Use UNIQUE basename matching to prevent collision with same-named files
    const enhancedFiles = sessionData.FILES.map(file => {
      const filePath = file.FILE_PATH;
      const fileBasename = getBasename(filePath);

      // Priority 1: Try EXACT full path match first
      if (semanticFileChanges.has(filePath)) {
        const info = semanticFileChanges.get(filePath);
        return {
          FILE_PATH: file.FILE_PATH,
          DESCRIPTION: info.description !== 'Modified during session' ? info.description : file.DESCRIPTION,
          ACTION: info.action === 'created' ? 'Created' : 'Modified'
        };
      }

      // Priority 2: Try basename match ONLY if unique
      let matchCount = 0;
      let basenameMatch = null;

      for (const [path, info] of semanticFileChanges) {
        const pathBasename = getBasename(path);
        if (pathBasename === fileBasename) {
          matchCount++;
          basenameMatch = { path, info };
        }
      }

      // P3.1: Log collision detection for debugging
      if (matchCount > 1) {
        console.warn(`   ⚠️  Multiple files with basename '${fileBasename}' - using default description`);
      }

      // Only apply basename match if it's UNIQUE (no collision)
      if (matchCount === 1 && basenameMatch) {
        const info = basenameMatch.info;
        return {
          FILE_PATH: file.FILE_PATH,
          DESCRIPTION: info.description !== 'Modified during session' ? info.description : file.DESCRIPTION,
          ACTION: info.action === 'created' ? 'Created' : 'Modified'
        };
      }

      return file;
    });

    // Build implementation summary markdown
    const IMPLEMENTATION_SUMMARY = formatSummaryAsMarkdown(implementationSummary);
    const HAS_IMPLEMENTATION_SUMMARY = implementationSummary.filesCreated.length > 0 ||
                                       implementationSummary.filesModified.length > 0 ||
                                       implementationSummary.decisions.length > 0;

    console.log(`   ✓ Generated summary: ${implementationSummary.filesCreated.length} created, ${implementationSummary.filesModified.length} modified, ${implementationSummary.decisions.length} decisions\n`);

    // Step 8: Populate templates
    console.log('📝 Step 8: Populating template...');

    // Build filename: {date}_{time}__{folder-name}.md
    // Dutch format: DD-MM-YY_HH-MM (2-digit year, no seconds)
    // Example: 09-11-25_07-52__skill-refinement.md
    const folderName = sessionData.SPEC_FOLDER.replace(/^\d+-/, '');
    const contextFilename = `${sessionData.DATE}_${sessionData.TIME}__${folderName}.md`;

    const files = {
      [contextFilename]: await populateTemplate('context', {
        ...sessionData,
        ...conversations,
        ...workflowData,
        // Override FILES with enhanced semantic descriptions
        FILES: enhancedFiles,
        MESSAGE_COUNT: conversations.MESSAGES.length,
        DECISION_COUNT: decisions.DECISIONS.length,
        DIAGRAM_COUNT: diagrams.DIAGRAMS.length,
        PHASE_COUNT: conversations.PHASE_COUNT,
        DECISIONS: decisions.DECISIONS,
        HIGH_CONFIDENCE_COUNT: decisions.HIGH_CONFIDENCE_COUNT,
        MEDIUM_CONFIDENCE_COUNT: decisions.MEDIUM_CONFIDENCE_COUNT,
        LOW_CONFIDENCE_COUNT: decisions.LOW_CONFIDENCE_COUNT,
        FOLLOWUP_COUNT: decisions.FOLLOWUP_COUNT,
        HAS_AUTO_GENERATED: diagrams.HAS_AUTO_GENERATED,
        FLOW_TYPE: diagrams.FLOW_TYPE,
        AUTO_CONVERSATION_FLOWCHART: diagrams.AUTO_CONVERSATION_FLOWCHART,
        AUTO_DECISION_TREES: diagrams.AUTO_DECISION_TREES,
        DIAGRAMS: diagrams.DIAGRAMS,
        // Semantic implementation summary
        IMPLEMENTATION_SUMMARY: IMPLEMENTATION_SUMMARY,
        HAS_IMPLEMENTATION_SUMMARY: HAS_IMPLEMENTATION_SUMMARY,
        IMPL_TASK: implementationSummary.task,
        IMPL_SOLUTION: implementationSummary.solution,
        IMPL_FILES_CREATED: implementationSummary.filesCreated,
        IMPL_FILES_MODIFIED: implementationSummary.filesModified,
        IMPL_DECISIONS: implementationSummary.decisions,
        IMPL_OUTCOMES: implementationSummary.outcomes,
        HAS_IMPL_FILES_CREATED: implementationSummary.filesCreated.length > 0,
        HAS_IMPL_FILES_MODIFIED: implementationSummary.filesModified.length > 0,
        HAS_IMPL_DECISIONS: implementationSummary.decisions.length > 0,
        HAS_IMPL_OUTCOMES: implementationSummary.outcomes.length > 0 && implementationSummary.outcomes[0] !== 'Session completed'
      }),
      'metadata.json': JSON.stringify({
        timestamp: `${sessionData.DATE} ${sessionData.TIME}`,
        messageCount: sessionData.MESSAGE_COUNT,
        decisionCount: decisions.DECISIONS.length,
        diagramCount: diagrams.DIAGRAMS.length,
        skillVersion: CONFIG.SKILL_VERSION,
        autoTriggered: shouldAutoSave(sessionData.MESSAGE_COUNT),
        // Content filtering stats
        filtering: getFilterStats(),
        // Semantic summary stats
        semanticSummary: {
          task: implementationSummary.task.substring(0, 100),
          filesCreated: implementationSummary.filesCreated.length,
          filesModified: implementationSummary.filesModified.length,
          decisions: implementationSummary.decisions.length,
          messageStats: implementationSummary.messageStats
        }
      }, null, 2)
    };

    // Add low-quality warning header if quality score is below threshold
    const filterStats = getFilterStats();
    if (filterStats.qualityScore < 20) {
      const warningHeader = `> **Note:** This session had limited actionable content (quality score: ${filterStats.qualityScore}/100). ${filterStats.noiseFiltered} noise entries and ${filterStats.duplicatesRemoved} duplicates were filtered.\n\n`;
      files[contextFilename] = warningHeader + files[contextFilename];
      console.log(`   ⚠️  Low quality session (${filterStats.qualityScore}/100) - warning header added`);
    }

    console.log(`   ✓ Template populated (quality: ${filterStats.qualityScore}/100)\n`);

    // Step 9: Write files with atomic writes and rollback on failure
    console.log('💾 Step 9: Writing files...');

    // Validate files for leaked placeholders before writing
    function detectLeakedPlaceholders(content, filename) {
      // Check for complete placeholders
      const leaked = content.match(/\{\{[A-Z_]+\}\}/g);
      if (leaked) {
        console.warn(`⚠️  Leaked placeholders detected in ${filename}: ${leaked.join(', ')}`);
        console.warn(`   Context around leak: ${content.substring(content.indexOf(leaked[0]) - 100, content.indexOf(leaked[0]) + 100)}`);
        throw new Error(`❌ Leaked placeholders in ${filename}: ${leaked.join(', ')}`);
      }

      // Check for partial/malformed placeholders
      const partialLeaked = content.match(/\{\{[^}]*$/g);
      if (partialLeaked) {
        console.warn(`⚠️  Partial placeholder detected in ${filename}: ${partialLeaked.join(', ')}`);
        throw new Error(`❌ Malformed placeholder in ${filename}`);
      }

      // Check for unclosed conditional blocks (both {{#...}} and {{^...}} need {{/...}})
      const openBlocks = (content.match(/\{\{[#^][A-Z_]+\}\}/g) || []).length;
      const closeBlocks = (content.match(/\{\{\/[A-Z_]+\}\}/g) || []).length;
      if (openBlocks !== closeBlocks) {
        console.warn(`⚠️  Unclosed conditional blocks in ${filename}: ${openBlocks} open, ${closeBlocks} closed`);
        throw new Error(`❌ Template syntax error in ${filename}: unclosed blocks`);
      }
    }

    const writtenFiles = [];
    let writeError = null;

    try {
      for (const [filename, content] of Object.entries(files)) {
        // Validate content before writing
        detectLeakedPlaceholders(content, filename);

        const filePath = path.join(contextDir, filename);

        try {
          // Write to temp file first (atomic write pattern)
          const tempPath = filePath + '.tmp';
          await fs.writeFile(tempPath, content, 'utf-8');

          // Verify write succeeded by checking file size
          const stat = await fs.stat(tempPath);
          const expectedSize = Buffer.byteLength(content, 'utf-8');
          if (stat.size !== expectedSize) {
            throw new Error(`Write verification failed: size mismatch (${stat.size} vs ${expectedSize} bytes)`);
          }

          // Atomic rename (replaces existing file if present)
          await fs.rename(tempPath, filePath);

          writtenFiles.push(filename);
          const lines = content.split('\n').length;
          console.log(`   ✓ ${filename} (${lines} lines)`);

        } catch (fileError) {
          writeError = new Error(`Failed to write ${filename}: ${fileError.message}`);
          console.error(`   ✗ ${filename}: ${fileError.message}`);
          throw writeError;
        }
      }
    } catch (error) {
      // Rollback all written files on any failure
      if (writtenFiles.length > 0) {
        console.log('\n⚠️  Error occurred during file writing. Rolling back...');

        for (const filename of writtenFiles) {
          try {
            const filePath = path.join(contextDir, filename);
            await fs.unlink(filePath);
            console.log(`   ✓ Rolled back ${filename}`);
          } catch (unlinkError) {
            console.warn(`   ⚠️  Could not remove ${filename}: ${unlinkError.message}`);
          }
        }

        console.log('\n❌ All changes rolled back due to write failure.\n');
      }

      throw error;
    }

    console.log();

    // Step 10: Success confirmation
    console.log('✅ Context saved successfully!\n');
    console.log(`Location: ${contextDir}\n`);
    console.log('Files created:');
    for (const [filename, content] of Object.entries(files)) {
      const lines = content.split('\n').length;
      console.log(`  • ${filename} (${lines} lines)`);
    }
    console.log();
    console.log('Summary:');
    console.log(`  • ${conversations.MESSAGES.length} messages captured`);
    console.log(`  • ${decisions.DECISIONS.length} key decisions documented`);
    console.log(`  • ${diagrams.DIAGRAMS.length} diagrams preserved`);
    console.log(`  • Session duration: ${sessionData.DURATION}\n`);

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

// ───────────────────────────────────────────────────────────────
// SPEC FOLDER DETECTION
// ───────────────────────────────────────────────────────────────

async function detectSpecFolder(collectedData = null) {
  const cwd = process.cwd();
  const specsDir = path.join(CONFIG.PROJECT_ROOT, 'specs');

  // V6.1: Check if spec folder was provided in JSON data FIRST (highest priority)
  if (collectedData && collectedData.SPEC_FOLDER) {
    const specFolderFromData = collectedData.SPEC_FOLDER;
    const specFolderPath = path.join(specsDir, specFolderFromData);

    // Verify the folder exists
    try {
      await fs.access(specFolderPath);
      console.log(`   ✓ Using spec folder from data: ${specFolderFromData}`);
      return specFolderPath;
    } catch {
      console.warn(`   ⚠️  Spec folder from data not found: ${specFolderFromData}, trying CLI arg...`);
      // Fall through to CLI arg check
    }
  }

  // Check if spec folder was provided as command-line argument
  if (CONFIG.SPEC_FOLDER_ARG) {
    const specFolderPath = path.join(specsDir, CONFIG.SPEC_FOLDER_ARG);

    // Verify the folder exists
    try {
      await fs.access(specFolderPath);
      return specFolderPath;
    } catch {
      // Provide detailed error with available options
      console.error(`\n❌ Specified spec folder not found: ${CONFIG.SPEC_FOLDER_ARG}\n`);
      console.error('Expected format: ###-feature-name (e.g., "122-skill-standardization")\n');

      // Show available spec folders
      try {
        const entries = await fs.readdir(specsDir);
        const available = entries
          .filter(name => /^\d{3}-/.test(name))
          .filter(name => !name.match(/^(z_|.*archive.*|.*old.*|.*\.archived.*)/i))
          .sort()
          .reverse();

        if (available.length > 0) {
          console.error('Available spec folders:');
          available.slice(0, 10).forEach(folder => {
            console.error(`  - ${folder}`);
          });
          if (available.length > 10) {
            console.error(`  ... and ${available.length - 10} more\n`);
          } else {
            console.error('');
          }
        }

        // Check if argument might be a partial match
        const partialMatches = available.filter(name =>
          name.includes(CONFIG.SPEC_FOLDER_ARG)
        );
        if (partialMatches.length > 0) {
          console.error('Did you mean one of these?');
          partialMatches.forEach(match => console.error(`  - ${match}`));
          console.error('');
        }
      } catch {
        // Silently ignore if we can't read specs directory
      }

      console.error('Usage: node generate-context.js <data-file> [spec-folder-name]\n');
      process.exit(1);
    }
  }

  // Check if we're in a spec folder
  if (cwd.includes('/specs/')) {
    const match = cwd.match(/(.*\/specs\/[^\/]+)/);
    if (match) {
      return match[1];
    }
  }

  // Find spec folders (specsDir already declared at function start)
  try {
    const entries = await fs.readdir(specsDir);
    let specFolders = entries
      .filter(name => /^\d{3}-/.test(name))
      .sort()
      .reverse();

    // Filter out archive folders
    specFolders = filterArchiveFolders(specFolders);

    if (specFolders.length === 0) {
      // No spec folders found - error and exit
      console.error('\n❌ Cannot save context: No spec folder found\n');
      console.error('save-context requires a spec folder to save memory documentation.');
      console.error('Every conversation with file changes must have a spec folder per conversation-documentation rules.\n');
      console.error('Please create a spec folder first:');
      console.error('  mkdir -p specs/###-feature-name/\n');
      console.error('Then re-run save-context.\n');
      console.error('See: .claude/knowledge/conversation_documentation.md\n');
      process.exit(1);
    }

    // If no conversation data, use most recent (backward compatible)
    if (!collectedData || specFolders.length === 1) {
      return path.join(specsDir, specFolders[0]);
    }

    // Skip alignment check in auto-save mode (hooks use this)
    if (process.env.AUTO_SAVE_MODE === 'true') {
      return path.join(specsDir, specFolders[0]);
    }

    // Context alignment check
    const conversationTopics = extractConversationTopics(collectedData);
    const mostRecent = specFolders[0];
    const alignmentScore = calculateAlignmentScore(conversationTopics, mostRecent);

    // If alignment is strong enough, auto-select most recent
    if (alignmentScore >= ALIGNMENT_CONFIG.THRESHOLD) {
      return path.join(specsDir, mostRecent);
    }

    // Low alignment - prompt user to choose
    console.log(`\n   ⚠️  Conversation topic may not align with most recent spec folder`);
    console.log(`   Most recent: ${mostRecent} (${alignmentScore}% match)\n`);

    // Calculate scores for top alternatives
    const alternatives = specFolders.slice(0, Math.min(5, specFolders.length)).map(folder => ({
      folder,
      score: calculateAlignmentScore(conversationTopics, folder)
    }));

    // Sort by score descending
    alternatives.sort((a, b) => b.score - a.score);

    // Display options
    console.log('   Alternative spec folders:');
    alternatives.forEach((alt, index) => {
      console.log(`   ${index + 1}. ${alt.folder} (${alt.score}% match)`);
    });
    console.log(`   ${alternatives.length + 1}. Specify custom folder path\n`);

    // Prompt user
    const choice = await promptUserChoice(
      `   Select target folder (1-${alternatives.length + 1}): `,
      alternatives.length + 1
    );

    // Handle choice
    if (choice <= alternatives.length) {
      return path.join(specsDir, alternatives[choice - 1].folder);
    } else {
      // Custom folder path
      const customPath = await promptUser('   Enter spec folder name: ');
      return path.join(specsDir, customPath);
    }

  } catch (error) {
    // If error is from promptUser, re-throw
    if (error.message.includes('retry attempts')) {
      throw error;
    }
    // specs directory doesn't exist - error and exit
    console.error('\n❌ Cannot save context: No spec folder found\n');
    console.error('save-context requires a spec folder to save memory documentation.');
    console.error('Every conversation with file changes must have a spec folder per conversation-documentation rules.\n');
    console.error('Please create a spec folder first:');
    console.error('  mkdir -p specs/###-feature-name/\n');
    console.error('Then re-run save-context.\n');
    console.error('See: .claude/knowledge/conversation_documentation.md\n');
    process.exit(1);
  }
}

// ───────────────────────────────────────────────────────────────
// TOPIC EXTRACTION & ALIGNMENT
// ───────────────────────────────────────────────────────────────

/**
 * Configuration for alignment checking
 */
const ALIGNMENT_CONFIG = {
  THRESHOLD: 70, // Require 70% match before auto-selecting
  ARCHIVE_PATTERNS: ['z_', 'archive', 'old', '.archived'],
  STOPWORDS: ['the', 'this', 'that', 'with', 'for', 'and', 'from', 'fix', 'update', 'add', 'remove']
};

/**
 * Extract conversation topics from collected data
 * @param {Object} collectedData - Conversation data structure
 * @returns {Array<string>} Array of topic keywords
 */
function extractConversationTopics(collectedData) {
  const topics = new Set();

  // Extract from recent_context.request (primary signal)
  if (collectedData.recent_context?.[0]?.request) {
    const request = collectedData.recent_context[0].request.toLowerCase();
    const words = request.match(/\b[a-z]{3,}\b/gi) || [];
    words.forEach(w => topics.add(w.toLowerCase()));
  }

  // Extract from observation titles (secondary signal)
  if (collectedData.observations) {
    for (const obs of collectedData.observations.slice(0, 3)) {
      if (obs.title) {
        const words = obs.title.match(/\b[a-z]{3,}\b/gi) || [];
        words.forEach(w => topics.add(w.toLowerCase()));
      }
    }
  }

  // Filter stopwords and short words
  return Array.from(topics).filter(t =>
    !ALIGNMENT_CONFIG.STOPWORDS.includes(t) && t.length >= 3
  );
}

/**
 * Parse spec folder name to extract topic keywords
 * @param {string} folderName - e.g., "015-auth-system"
 * @returns {Array<string>} Topic keywords ["auth", "system"]
 */
function parseSpecFolderTopic(folderName) {
  // Remove numeric prefix: "015-auth-system" → "auth-system"
  const topic = folderName.replace(/^\d+-/, '');
  // Split on hyphens and underscores: "auth-system" → ["auth", "system"]
  return topic.split(/[-_]/).filter(w => w.length > 0);
}

/**
 * Calculate alignment score between conversation and spec folder
 * @param {Array<string>} conversationTopics - From extractConversationTopics()
 * @param {string} specFolderName - e.g., "015-auth-system"
 * @returns {number} Score 0-100 (percentage match)
 */
function calculateAlignmentScore(conversationTopics, specFolderName) {
  const specTopics = parseSpecFolderTopic(specFolderName);

  if (specTopics.length === 0) return 0;

  // Count how many spec topics appear in conversation topics
  let matches = 0;
  for (const specTopic of specTopics) {
    // Check for exact match or substring match
    if (conversationTopics.some(ct =>
      ct.includes(specTopic) || specTopic.includes(ct)
    )) {
      matches++;
    }
  }

  // Calculate percentage
  return Math.round((matches / specTopics.length) * 100);
}

/**
 * Filter out archive folders from spec folder list
 * @param {Array<string>} folders - List of folder names
 * @returns {Array<string>} Filtered list without archives
 */
function filterArchiveFolders(folders) {
  return folders.filter(folder => {
    const lowerFolder = folder.toLowerCase();
    return !ALIGNMENT_CONFIG.ARCHIVE_PATTERNS.some(pattern =>
      lowerFolder.includes(pattern)
    );
  });
}

/**
 * Prompt user with numbered choices and validate input
 * @param {string} question - Prompt text
 * @param {number} maxChoice - Maximum valid choice number
 * @param {number} maxAttempts - Maximum retry attempts (default 3)
 * @returns {Promise<number>} Selected choice number (1-indexed)
 */
async function promptUserChoice(question, maxChoice, maxAttempts = 3) {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    const answer = await promptUser(question);
    const choice = parseInt(answer);

    if (!isNaN(choice) && choice >= 1 && choice <= maxChoice) {
      return choice;
    }

    if (attempt < maxAttempts) {
      console.log(`   ❌ Invalid choice. Please enter a number between 1 and ${maxChoice}.\n`);
    }
  }

  throw new Error('Maximum retry attempts exceeded. Please run the command again.');
}

// ───────────────────────────────────────────────────────────────
// CONTEXT DIRECTORY SETUP
// ───────────────────────────────────────────────────────────────

/**
 * Prompt user for input in terminal
 */
function promptUser(question) {
  // Safety check: don't create readline interface if no TTY available
  if (!process.stdout.isTTY || !process.stdin.isTTY) {
    throw new Error('Cannot prompt user: No TTY available (running in non-interactive mode)');
  }

  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

/**
 * Ensure memory directory exists within spec folder
 * Uses single memory/ folder with timestamped markdown files
 */
async function setupContextDirectory(specFolder) {
  // Always create memory/ subfolder within spec folder
  const contextDir = path.join(specFolder, 'memory');

  // Ensure directory exists (create if needed)
  // No prompts - files are timestamped so no conflicts
  await fs.mkdir(contextDir, { recursive: true });

  return contextDir;
}

// ───────────────────────────────────────────────────────────────
// DATA COLLECTION FROM MCP
// ───────────────────────────────────────────────────────────────

async function collectSessionData(collectedData, specFolderName = null) {
  const now = new Date();
  // Use provided specFolderName (cached) or detect as fallback
  const folderName = specFolderName || path.basename(await detectSpecFolder());
  const dateOnly = formatTimestamp(now, 'date-dutch');  // DD-MM-YY format
  const timeOnly = formatTimestamp(now, 'time-short');  // HH-MM format

  // Fallback to simulation if no data
  if (!collectedData) {
    console.log('   ⚠️  Using simulation data');
    return {
      TITLE: folderName.replace(/^\d{3}-/, '').replace(/-/g, ' '),
      DATE: dateOnly,
      TIME: timeOnly,
      SPEC_FOLDER: folderName,
      DURATION: 'N/A (simulated)',
      SUMMARY: '⚠️ SIMULATION MODE - No real conversation data available. This is placeholder data for testing.',
      FILES: [
        { FILE_PATH: '⚠️ SIMULATION MODE', DESCRIPTION: 'No files were tracked - using fallback data' }
      ],
      OUTCOMES: [
        { OUTCOME: '⚠️ SIMULATION MODE - Real conversation data not available' }
      ],
      TOOL_COUNT: 0,
      QUICK_SUMMARY: '⚠️ SIMULATION MODE - Provide conversation data via JSON file for real output',
      SKILL_VERSION: CONFIG.SKILL_VERSION
    };
  }

  // Process real MCP data
  const sessionInfo = collectedData.recent_context?.[0] || {};
  const observations = collectedData.observations || [];
  const userPrompts = collectedData.user_prompts || [];
  const messageCount = userPrompts.length || 0;

  // Check if auto-save triggered
  if (shouldAutoSave(messageCount)) {
    console.log(`\n   📊 Context Budget: ${messageCount} messages reached. Auto-saving context...\n`);
  }

  // Calculate duration
  let duration = 'N/A';
  if (userPrompts.length > 0) {
    const firstTimestamp = new Date(userPrompts[0].timestamp || now);
    const lastTimestamp = new Date(userPrompts[userPrompts.length - 1].timestamp || now);
    const durationMs = lastTimestamp - firstTimestamp;
    const minutes = Math.floor(durationMs / 60000);
    const hours = Math.floor(minutes / 60);
    duration = hours > 0 ? `${hours}h ${minutes % 60}m` : `${minutes}m`;
  }

  // V8: Extract files with normalized paths and deduplication
  const filesMap = new Map();

  // V8.4: Helper to add files with normalized path deduplication
  // Prefers shorter valid descriptions (concise > verbose)
  const addFile = (rawPath, description) => {
    const normalized = toRelativePath(rawPath);
    if (!normalized) return;

    const existing = filesMap.get(normalized);
    const cleaned = cleanDescription(description);

    // Keep existing if new description is invalid or longer
    if (existing) {
      if (isDescriptionValid(cleaned) && cleaned.length < existing.length) {
        filesMap.set(normalized, cleaned);
      }
    } else {
      filesMap.set(normalized, cleaned || 'Modified during session');
    }
  };

  // V7.1: FIRST, check for FILES array (primary input format with full descriptions)
  if (collectedData.FILES && Array.isArray(collectedData.FILES)) {
    for (const fileInfo of collectedData.FILES) {
      const filePath = fileInfo.FILE_PATH || fileInfo.path;
      const description = fileInfo.DESCRIPTION || fileInfo.description || 'Modified during session';
      if (filePath) addFile(filePath, description);
    }
  }

  // Also check for files_modified array (legacy format)
  if (collectedData.files_modified && Array.isArray(collectedData.files_modified)) {
    for (const fileInfo of collectedData.files_modified) {
      addFile(fileInfo.path, fileInfo.changes_summary || 'Modified during session');
    }
  }

  // Also extract from observations
  for (const obs of observations) {
    if (obs.files) {
      for (const file of obs.files) {
        addFile(file, 'Modified during session');
      }
    }
    // Also check facts for files
    if (obs.facts) {
      for (const fact of obs.facts) {
        if (fact.files && Array.isArray(fact.files)) {
          for (const file of fact.files) {
            addFile(file, 'Modified during session');
          }
        }
      }
    }
  }

  // V8.1: Limit to 10 key files, prioritizing those with valid descriptions
  const filesEntries = Array.from(filesMap.entries());
  const withValidDesc = filesEntries.filter(([_, desc]) => isDescriptionValid(desc));
  const withFallback = filesEntries.filter(([_, desc]) => !isDescriptionValid(desc));

  const FILES = [...withValidDesc, ...withFallback]
    .slice(0, 10)
    .map(([filePath, description]) => ({
      FILE_PATH: filePath,
      DESCRIPTION: description
    }));

  // V7.2: Extract outcomes from ALL observation types (not just change/feature)
  // Include: bugfix, feature, change, discovery, decision, refactor
  const OUTCOMES = observations
    .slice(0, 10)
    .map(obs => ({
      OUTCOME: obs.title || obs.narrative?.substring(0, 150),
      TYPE: obs.type || 'observation'
    }));

  // Create session summary from recent context or observations
  const SUMMARY = sessionInfo.learning
    || observations.slice(0, 3).map(o => o.narrative).join(' ')
    || 'Session focused on implementing and testing features.';

  // Count tools used
  const TOOL_COUNT = userPrompts.reduce((count, prompt) => {
    // Estimate based on prompt content - this will be improved with better data
    return count + (prompt.prompt?.includes('Read') || prompt.prompt?.includes('Edit') ? 1 : 0);
  }, 0);

  // Extract task from FIRST user prompt if no observations available
  // This prevents falling back to generic "Development session"
  const firstPrompt = userPrompts[0]?.prompt || '';
  const taskFromPrompt = firstPrompt.match(/^(.{20,100}?)(?:[.!?\n]|$)/)?.[1];

  // V7.3: Build detailed OBSERVATIONS array for template
  const OBSERVATIONS_DETAILED = observations.map(obs => ({
    TYPE: (obs.type || 'observation').toUpperCase(),
    TITLE: obs.title || 'Observation',
    NARRATIVE: obs.narrative || '',
    HAS_FILES: obs.files && obs.files.length > 0,
    FILES_LIST: obs.files ? obs.files.join(', ') : '',
    HAS_FACTS: obs.facts && obs.facts.length > 0,
    FACTS_LIST: obs.facts ? obs.facts.join(' | ') : ''
  }));

  // V7.4: Detect related spec/plan files in the spec folder
  const SPEC_FILES = [];
  const specFolderPath = collectedData.SPEC_FOLDER
    ? path.join(CONFIG.PROJECT_ROOT, 'specs', collectedData.SPEC_FOLDER)
    : null;

  if (specFolderPath) {
    const specDocFiles = ['spec.md', 'plan.md', 'tasks.md', 'checklist.md', 'research.md'];
    for (const docFile of specDocFiles) {
      const filePath = path.join(specFolderPath, docFile);
      try {
        await fs.access(filePath);
        SPEC_FILES.push({
          FILE_NAME: docFile,
          FILE_PATH: `./${docFile}`
        });
      } catch {
        // File doesn't exist, skip
      }
    }
  }

  return {
    TITLE: folderName.replace(/^\d{3}-/, '').replace(/-/g, ' '),
    DATE: dateOnly,
    TIME: timeOnly,
    SPEC_FOLDER: folderName,
    DURATION: duration,
    SUMMARY: SUMMARY,
    // V8.5: Add HAS_FILES flag for conditional template rendering
    FILES: FILES.length > 0 ? FILES : [],
    HAS_FILES: FILES.length > 0,
    OUTCOMES: OUTCOMES.length > 0 ? OUTCOMES : [{ OUTCOME: 'Session in progress' }],
    TOOL_COUNT,
    MESSAGE_COUNT: messageCount,
    QUICK_SUMMARY: observations[0]?.title || sessionInfo.request || taskFromPrompt?.trim() || 'Development session',
    SKILL_VERSION: CONFIG.SKILL_VERSION,
    // V7.3: Add detailed observations for template
    OBSERVATIONS: OBSERVATIONS_DETAILED,
    HAS_OBSERVATIONS: OBSERVATIONS_DETAILED.length > 0,
    // V7.4: Add spec/plan file references
    SPEC_FILES: SPEC_FILES,
    HAS_SPEC_FILES: SPEC_FILES.length > 0
  };
}

async function extractConversations(collectedData) {
  // Validate and warn about data quality
  if (!collectedData) {
    console.log('   ⚠️  Using simulation data for conversations');
    return {
      MESSAGES: [
        {
          TIMESTAMP: formatTimestamp(new Date(), 'readable'),
          ROLE: 'User',
          CONTENT: 'This is a simulated user message.',
          TOOL_CALLS: []
        },
        {
          TIMESTAMP: formatTimestamp(new Date(), 'readable'),
          ROLE: 'Assistant',
          CONTENT: 'This is a simulated assistant response.',
          TOOL_CALLS: [
            {
              TOOL_NAME: 'Read',
              DESCRIPTION: 'Read example.js',
              HAS_RESULT: true,
              RESULT_PREVIEW: 'const example = "simulated";',
              HAS_MORE: false
            }
          ]
        }
      ],
      MESSAGE_COUNT: 2,
      DURATION: 'N/A (simulated)',
      FLOW_PATTERN: 'Sequential with Decision Points',
      PHASE_COUNT: 4,
      PHASES: [
        { PHASE_NAME: 'Research', DURATION: '10 min' },
        { PHASE_NAME: 'Clarification', DURATION: '2 min' },
        { PHASE_NAME: 'Implementation', DURATION: '30 min' },
        { PHASE_NAME: 'Verification', DURATION: '5 min' }
      ],
      AUTO_GENERATED_FLOW: generateConversationFlowchart([]),
      TOOL_COUNT: 1,
      DATE: new Date().toISOString().split('T')[0]
    };
  }

  // Process real MCP data with quality warnings
  const userPrompts = collectedData.user_prompts || [];
  const observations = collectedData.observations || [];

  // Warn if data is suspiciously empty
  if (userPrompts.length === 0 && observations.length === 0) {
    console.warn('   ⚠️  Warning: No conversation data found');
    console.warn('   ⚠️  Generated output may be minimal or empty');
  }

  if (userPrompts.length === 0) {
    console.warn(`   ⚠️  No user prompts found (empty conversation)`);
  }

  if (observations.length === 0) {
    console.warn(`   ⚠️  No observations found (no events documented)`);
  }

  // Build conversation messages by interleaving user prompts and assistant observations
  const MESSAGES = [];
  const phaseTimestamps = new Map(); // Track phase durations

  // V6.3: Trust pre-filtered data from transform-transcript.js
  // FIXED: Removed redundant filter that was causing count divergence
  const validPrompts = userPrompts;  // Already filtered by transform-transcript.js

  for (let i = 0; i < validPrompts.length; i++) {
    const userPrompt = validPrompts[i];

    // Add user message
    const rawTimestamp = userPrompt.timestamp || new Date().toISOString();
    const userMessage = {
      TIMESTAMP: formatTimestamp(rawTimestamp, 'readable'),
      ROLE: 'User',
      CONTENT: userPrompt.prompt.trim(),
      TOOL_CALLS: []
    };
    MESSAGES.push(userMessage);

    // Find corresponding assistant observations (within reasonable time window)
    const userTime = new Date(rawTimestamp);
    const relatedObs = observations.filter(obs => {
      const obsTime = new Date(obs.timestamp);
      const timeDiff = Math.abs(obsTime - userTime);
      return timeDiff < CONFIG.MESSAGE_TIME_WINDOW;
    });

    // Create assistant response with intelligent summarization
    if (relatedObs.length > 0) {
      // Extract tool calls from observations using improved detection
      const TOOL_CALLS = relatedObs.flatMap(obs => {
        if (!obs.facts) return [];

        return obs.facts.map(fact => {
          // Validate fact is a string
          if (!fact || typeof fact !== 'string') return null;

          // Use new strict tool detection
          const detection = detectToolCall(fact);
          if (!detection) return null;

          // Verify not prose context - find where the tool name appears
          const toolIndex = fact.search(new RegExp(`\\b${detection.tool}\\b`, 'i'));
          if (toolIndex >= 0 && isProseContext(fact, toolIndex)) {
            return null; // Skip prose matches like "Read more about..."
          }

          // Only include high/medium confidence detections
          if (detection.confidence === 'low') return null;

          const fileMatch = fact.match(/File:\s*([^\n]+)/i) || fact.match(/(?:file_path|path):\s*([^\n]+)/i);
          const resultMatch = fact.match(/Result:\s*([^\n]+)/i);

          return {
            TOOL_NAME: detection.tool,
            DESCRIPTION: fileMatch?.[1] || fact.substring(0, 100),
            HAS_RESULT: !!resultMatch,
            RESULT_PREVIEW: resultMatch?.[1] ? truncateToolOutput(resultMatch[1], CONFIG.TOOL_PREVIEW_LINES) : '',
            HAS_MORE: resultMatch?.[1]?.split('\n').length > CONFIG.TOOL_PREVIEW_LINES
          };
        }).filter(Boolean);
      });

      // Create intelligent summary of assistant response
      const narratives = relatedObs.map(o => o.narrative).filter(Boolean);
      const summary = summarizeExchange(
        userMessage.CONTENT,
        narratives.join(' '),
        TOOL_CALLS
      );

      const assistantMessage = {
        TIMESTAMP: formatTimestamp(relatedObs[0].timestamp || rawTimestamp, 'readable'),
        ROLE: 'Assistant',
        CONTENT: summary.fullSummary,
        TOOL_CALLS: TOOL_CALLS.slice(0, 10) // Limit to 10 tools per message
      };

      MESSAGES.push(assistantMessage);

      // Track phase for this exchange
      const phase = classifyConversationPhase(TOOL_CALLS, userMessage.CONTENT);
      if (!phaseTimestamps.has(phase)) {
        phaseTimestamps.set(phase, []);
      }
      phaseTimestamps.get(phase).push(new Date(userMessage.TIMESTAMP));
    }
  }

  // Sort all messages by timestamp to ensure chronological order
  // User and assistant timestamps from different sources can appear out of order
  MESSAGES.sort((a, b) => {
    const timeA = new Date(a.TIMESTAMP.replace(' @ ', 'T')).getTime();
    const timeB = new Date(b.TIMESTAMP.replace(' @ ', 'T')).getTime();
    return timeA - timeB;
  });

  // Ensure user messages come before their assistant responses when timestamps are equal
  for (let i = 0; i < MESSAGES.length - 1; i++) {
    const curr = MESSAGES[i];
    const next = MESSAGES[i + 1];
    const currTime = new Date(curr.TIMESTAMP.replace(' @ ', 'T')).getTime();
    const nextTime = new Date(next.TIMESTAMP.replace(' @ ', 'T')).getTime();

    // If same timestamp but user follows assistant, swap them
    if (currTime === nextTime && curr.ROLE === 'Assistant' && next.ROLE === 'User') {
      [MESSAGES[i], MESSAGES[i + 1]] = [MESSAGES[i + 1], MESSAGES[i]];
    }
  }

  // Calculate phases and durations
  const PHASES = Array.from(phaseTimestamps.entries()).map(([PHASE_NAME, timestamps]) => {
    if (timestamps.length === 0) {
      return { PHASE_NAME, DURATION: 'N/A' };
    }

    const firstTime = timestamps[0];
    const lastTime = timestamps[timestamps.length - 1];
    const durationMs = lastTime - firstTime;
    const minutes = Math.floor(durationMs / 60000);

    return {
      PHASE_NAME,
      DURATION: minutes > 0 ? `${minutes} min` : '< 1 min'
    };
  });

  // Calculate total duration
  let duration = 'N/A';
  if (MESSAGES.length > 0) {
    const firstTime = new Date(MESSAGES[0].TIMESTAMP);
    const lastTime = new Date(MESSAGES[MESSAGES.length - 1].TIMESTAMP);
    const durationMs = lastTime - firstTime;
    const minutes = Math.floor(durationMs / 60000);
    const hours = Math.floor(minutes / 60);
    duration = hours > 0 ? `${hours}h ${minutes % 60}m` : `${minutes}m`;
  }

  // Determine flow pattern
  const hasDecisions = MESSAGES.some(m => m.CONTENT.toLowerCase().includes('option') || m.CONTENT.toLowerCase().includes('decide'));
  const hasParallel = PHASES.length > 3;
  const FLOW_PATTERN = hasDecisions
    ? 'Sequential with Decision Points'
    : hasParallel
    ? 'Multi-Phase Workflow'
    : 'Linear Sequential';

  // Count tools
  const TOOL_COUNT = MESSAGES.reduce((count, msg) => count + msg.TOOL_CALLS.length, 0);

  // Generate flowchart from actual conversation data
  const AUTO_GENERATED_FLOW = generateConversationFlowchart(PHASES, userPrompts[0]?.prompt);

  return {
    MESSAGES,
    MESSAGE_COUNT: MESSAGES.length,
    DURATION: duration,
    FLOW_PATTERN,
    PHASE_COUNT: PHASES.length,
    PHASES,
    AUTO_GENERATED_FLOW,
    TOOL_COUNT,
    DATE: new Date().toISOString().split('T')[0]
  };
}

async function extractDecisions(collectedData) {
  // Fallback to simulation if no data
  if (!collectedData) {
    console.log('   ⚠️  Using simulation data for decisions');
    const decisions = [
      {
        INDEX: 1,
        TITLE: 'Simulated Decision Example',
        CONTEXT: 'This is a simulated decision for testing purposes.',
        TIMESTAMP: formatTimestamp(),
        OPTIONS: [
          {
            OPTION_NUMBER: 1,
            LABEL: 'Option A',
            DESCRIPTION: 'First option description',
            HAS_PROS_CONS: true,
            PROS: [{ PRO: 'Simple to implement' }],
            CONS: [{ CON: 'Limited flexibility' }]
          },
          {
            OPTION_NUMBER: 2,
            LABEL: 'Option B',
            DESCRIPTION: 'Second option description',
            HAS_PROS_CONS: true,
            PROS: [{ PRO: 'More flexible' }],
            CONS: [{ CON: 'More complex' }]
          }
        ],
        CHOSEN: 'Option B',
        RATIONALE: 'Flexibility was prioritized over simplicity for this use case.',
        HAS_PROS: true,
        PROS: [
          { PRO: 'Flexible architecture' },
          { PRO: 'Extensible design' }
        ],
        HAS_CONS: true,
        CONS: [
          { CON: 'Higher initial complexity' }
        ],
        CONFIDENCE: 85,
        HAS_EVIDENCE: true,
        EVIDENCE: [
          { EVIDENCE_ITEM: 'example.js:123' }
        ],
        HAS_CAVEATS: true,
        CAVEATS: [
          { CAVEAT_ITEM: 'Requires additional setup time' }
        ],
        HAS_FOLLOWUP: true,
        FOLLOWUP: [
          { FOLLOWUP_ITEM: 'Review performance after implementation' }
        ]
      }
    ];

    // Generate decision trees with full decision objects
    decisions.forEach(dec => {
      dec.DECISION_TREE = generateDecisionTree(dec);
      dec.HAS_DECISION_TREE = dec.DECISION_TREE.length > 0;
    });

    return {
      DECISIONS: decisions.map(validateDataStructure),
      DECISION_COUNT: 1,
      HIGH_CONFIDENCE_COUNT: 1,
      MEDIUM_CONFIDENCE_COUNT: 0,
      LOW_CONFIDENCE_COUNT: 0,
      FOLLOWUP_COUNT: 0
    };
  }

  // Process real MCP data - extract decision observations
  const decisionObservations = (collectedData.observations || [])
    .filter(obs => obs.type === 'decision');

  const decisions = decisionObservations.map((obs, index) => {
    // Parse decision details from observation narrative and facts
    const narrative = obs.narrative || '';
    const facts = obs.facts || [];

    // Extract options from facts with robust parsing
    const optionMatches = facts.filter(f => f.includes('Option') || f.includes('Alternative'));
    const OPTIONS = optionMatches.map((opt, i) => {
      // More robust label extraction
      const labelMatch = opt.match(/Option\s+([A-Za-z0-9]+):?/)
        || opt.match(/Alternative\s+([A-Za-z0-9]+):?/)
        || opt.match(/^(\d+)\./);

      const label = labelMatch?.[1] || `${i + 1}`;

      // More robust description extraction
      let description = opt;
      if (opt.includes(':')) {
        const parts = opt.split(':');
        description = parts.slice(1).join(':').trim(); // Handle multiple colons
      } else if (labelMatch) {
        // Remove label prefix if present but no colon
        description = opt.replace(labelMatch[0], '').trim();
      }

      // Validate description is meaningful
      if (!description || description.length < 3) {
        description = opt; // Fall back to full text
      }

      return {
        OPTION_NUMBER: i + 1,
        LABEL: `Option ${label}`,
        DESCRIPTION: description,
        HAS_PROS_CONS: false,
        PROS: [],
        CONS: []
      };
    });

    // Extract chosen option
    const chosenMatch = narrative.match(/chose|selected|decided on|went with:?\s+([^\.\n]+)/i);
    const CHOSEN = chosenMatch?.[1]?.trim() || (OPTIONS.length > 0 ? OPTIONS[0].LABEL : 'N/A');

    // Extract rationale
    const rationaleMatch = narrative.match(/because|rationale|reason:?\s+([^\.\n]+)/i);
    const RATIONALE = rationaleMatch?.[1]?.trim() || narrative.substring(0, 200);

    // Extract confidence if mentioned
    const confidenceMatch = narrative.match(/confidence:?\s*(\d+)%?/i);
    const CONFIDENCE = confidenceMatch ? parseInt(confidenceMatch[1]) : 75;

    // Extract pros/cons if mentioned (use word boundaries to avoid "disadvantage" matching "advantage")
    const PROS = facts
      .filter(f => {
        const lower = f.toLowerCase();
        return lower.match(/\bpro:\s/) || lower.match(/\badvantage:\s/);
      })
      .map(p => {
        const parts = p.split(':');
        // If colon exists, take everything after first colon, otherwise use full string
        const text = parts.length > 1 ? parts.slice(1).join(':').trim() : p;
        return { PRO: text };
      });

    const CONS = facts
      .filter(f => {
        const lower = f.toLowerCase();
        return lower.match(/\bcon:\s/) || lower.match(/\bdisadvantage:\s/);
      })
      .map(c => {
        const parts = c.split(':');
        // If colon exists, take everything after first colon, otherwise use full string
        const text = parts.length > 1 ? parts.slice(1).join(':').trim() : c;
        return { CON: text };
      });

    // Extract follow-up actions
    const FOLLOWUP = facts
      .filter(f => {
        const lower = f.toLowerCase();
        return lower.match(/\bfollow-?up:\s/) || lower.match(/\btodo:\s/) || lower.match(/\bnext step:\s/);
      })
      .map(f => {
        const parts = f.split(':');
        const text = parts.length > 1 ? parts.slice(1).join(':').trim() : f;
        return { FOLLOWUP_ITEM: text };
      });

    // Extract caveats/warnings
    const CAVEATS = facts
      .filter(f => {
        const lower = f.toLowerCase();
        return lower.match(/\bcaveat:\s/) || lower.match(/\bwarning:\s/) || lower.match(/\blimitation:\s/);
      })
      .map(c => {
        const parts = c.split(':');
        const text = parts.length > 1 ? parts.slice(1).join(':').trim() : c;
        return { CAVEAT_ITEM: text };
      });

    // Extract evidence references
    const EVIDENCE = obs.files
      ? obs.files.map(f => ({ EVIDENCE_ITEM: f }))
      : facts
          .filter(f => {
            const lower = f.toLowerCase();
            return lower.match(/\bevidence:\s/) || lower.match(/\bsee:\s/) || lower.match(/\breference:\s/);
          })
          .map(e => {
            const parts = e.split(':');
            const text = parts.length > 1 ? parts.slice(1).join(':').trim() : e;
            return { EVIDENCE_ITEM: text };
          });

    // Build decision object first
    const decision = {
      INDEX: index + 1,
      TITLE: obs.title || `Decision ${index + 1}`,
      CONTEXT: narrative,
      TIMESTAMP: obs.timestamp || new Date().toISOString(),
      OPTIONS,
      CHOSEN,
      RATIONALE,
      HAS_PROS: PROS.length > 0,
      PROS,
      HAS_CONS: CONS.length > 0,
      CONS,
      CONFIDENCE,
      HAS_EVIDENCE: EVIDENCE.length > 0,
      EVIDENCE,
      HAS_CAVEATS: CAVEATS.length > 0,
      CAVEATS,
      HAS_FOLLOWUP: FOLLOWUP.length > 0,
      FOLLOWUP
    };

    // Generate decision tree with full decision object
    decision.DECISION_TREE = OPTIONS.length > 0 ? generateDecisionTree(decision) : '';
    decision.HAS_DECISION_TREE = decision.DECISION_TREE.length > 0;

    return decision;
  });

  // Calculate confidence distribution
  const highConfidence = decisions.filter(d => d.CONFIDENCE >= 80).length;
  const mediumConfidence = decisions.filter(d => d.CONFIDENCE >= 50 && d.CONFIDENCE < 80).length;
  const lowConfidence = decisions.filter(d => d.CONFIDENCE < 50).length;

  // Calculate total follow-up count across all decisions
  const followupCount = decisions.reduce((count, d) => count + d.FOLLOWUP.length, 0);

  return {
    DECISIONS: decisions.map(validateDataStructure),
    DECISION_COUNT: decisions.length,
    HIGH_CONFIDENCE_COUNT: highConfidence,
    MEDIUM_CONFIDENCE_COUNT: mediumConfidence,
    LOW_CONFIDENCE_COUNT: lowConfidence,
    FOLLOWUP_COUNT: followupCount
  };
}

async function extractDiagrams(collectedData) {
  // Fallback to simulation if no data
  if (!collectedData) {
    console.log('   ⚠️  Using simulation data for diagrams');
    return {
      DIAGRAMS: [
        {
          TITLE: 'Example Workflow',
          TIMESTAMP: formatTimestamp(),
          DIAGRAM_TYPE: 'Workflow',
          PATTERN_NAME: 'Sequential Flow',
          COMPLEXITY: 'Low',
          HAS_DESCRIPTION: true,
          DESCRIPTION: 'Simulated workflow diagram',
          ASCII_ART: `┌─────────┐
│  Start  │
└────┬────┘
     │
     ▼
┌─────────┐
│ Process │
└────┬────┘
     │
     ▼
┌─────────┐
│   End   │
└─────────┘`,
          HAS_NOTES: false,
          HAS_RELATED_FILES: false
        }
      ],
      DIAGRAM_COUNT: 1,
      HAS_AUTO_GENERATED: true,
      FLOW_TYPE: 'Conversation Flow',
      AUTO_CONVERSATION_FLOWCHART: generateConversationFlowchart([]),
      AUTO_DECISION_TREES: [],
      AUTO_FLOW_COUNT: 1,
      AUTO_DECISION_COUNT: 0,
      DIAGRAM_TYPES: [
        { TYPE: 'Workflow', COUNT: 1 }
      ],
      PATTERN_SUMMARY: [
        { PATTERN_NAME: 'Sequential Flow', COUNT: 1 }
      ]
    };
  }

  // Process real MCP data - scan for diagrams in observations
  const observations = collectedData.observations || [];
  const decisions = collectedData.observations?.filter(o => o.type === 'decision') || [];
  const userPrompts = collectedData.user_prompts || [];

  // Box-drawing characters to detect ASCII art
  const boxChars = /[┌┐└┘├┤┬┴┼─│╭╮╰╯╱╲▼▲►◄]/;

  const DIAGRAMS = [];

  // Search for diagrams in observation narratives
  for (const obs of observations) {
    const narrative = obs.narrative || '';
    const facts = obs.facts || [];

    // Check if contains ASCII art
    if (boxChars.test(narrative) || facts.some(f => boxChars.test(f))) {
      const asciiArt = boxChars.test(narrative)
        ? narrative
        : facts.find(f => boxChars.test(f)) || '';

      const pattern = classifyDiagramPattern(asciiArt);

      DIAGRAMS.push({
        TITLE: obs.title || 'Detected Diagram',
        TIMESTAMP: obs.timestamp || new Date().toISOString(),
        DIAGRAM_TYPE: obs.type === 'decision' ? 'Decision Tree' : 'Workflow',
        PATTERN_NAME: pattern.pattern,
        COMPLEXITY: pattern.complexity,
        HAS_DESCRIPTION: !!obs.title,
        DESCRIPTION: obs.title || 'Diagram found in conversation',
        ASCII_ART: asciiArt.substring(0, 1000), // Limit size
        HAS_NOTES: false,
        NOTES: [],
        HAS_RELATED_FILES: obs.files && obs.files.length > 0,
        RELATED_FILES: obs.files ? obs.files.map(f => ({ FILE_PATH: f })) : []
      });
    }
  }

  // Generate auto-flowchart from conversation phases
  const phases = extractPhasesFromData(collectedData);
  const AUTO_CONVERSATION_FLOWCHART = generateConversationFlowchart(
    phases,
    userPrompts[0]?.prompt || 'User request'
  );

  // Generate decision trees for all decisions
  const AUTO_DECISION_TREES = decisions.map((dec, index) => {
    const options = dec.facts
      ?.filter(f => f.includes('Option') || f.includes('Alternative'))
      .map(f => f.split(':')[0]?.trim() || f.substring(0, 20)) || [];

    const chosen = dec.narrative?.match(/chose|selected:?\s+([^\.\n]+)/i)?.[1]?.trim() || options[0];

    return {
      INDEX: index + 1,
      DECISION_TITLE: dec.title || `Decision ${index + 1}`,
      DECISION_TREE: generateDecisionTree(dec.title || 'Decision', options, chosen)
    };
  });

  // Count diagram types
  const diagramTypeCounts = new Map();
  for (const diagram of DIAGRAMS) {
    const count = diagramTypeCounts.get(diagram.DIAGRAM_TYPE) || 0;
    diagramTypeCounts.set(diagram.DIAGRAM_TYPE, count + 1);
  }

  const DIAGRAM_TYPES = Array.from(diagramTypeCounts.entries()).map(([TYPE, COUNT]) => ({ TYPE, COUNT }));

  // Count pattern types
  const patternCounts = new Map();
  for (const diagram of DIAGRAMS) {
    const count = patternCounts.get(diagram.PATTERN_NAME) || 0;
    patternCounts.set(diagram.PATTERN_NAME, count + 1);
  }

  const PATTERN_SUMMARY = Array.from(patternCounts.entries()).map(([PATTERN_NAME, COUNT]) => ({ PATTERN_NAME, COUNT }));

  return {
    DIAGRAMS: DIAGRAMS.map(validateDataStructure),
    DIAGRAM_COUNT: DIAGRAMS.length,
    HAS_AUTO_GENERATED: true,
    FLOW_TYPE: 'Conversation Flow',
    AUTO_CONVERSATION_FLOWCHART,
    AUTO_DECISION_TREES,
    AUTO_FLOW_COUNT: 1,
    AUTO_DECISION_COUNT: AUTO_DECISION_TREES.length,
    DIAGRAM_TYPES,
    PATTERN_SUMMARY
  };
}

function extractPhasesFromData(collectedData) {
  // Fallback for simulation mode
  if (!collectedData || !collectedData.observations || collectedData.observations.length === 0) {
    return [
      {
        PHASE_NAME: 'Research',
        DURATION: '5 min',
        ACTIVITIES: ['Exploring codebase', 'Reading documentation', 'Understanding requirements']
      },
      {
        PHASE_NAME: 'Planning',
        DURATION: '3 min',
        ACTIVITIES: ['Designing solution', 'Creating task breakdown']
      },
      {
        PHASE_NAME: 'Implementation',
        DURATION: '15 min',
        ACTIVITIES: ['Writing code', 'Applying changes', 'Refactoring']
      },
      {
        PHASE_NAME: 'Verification',
        DURATION: '2 min',
        ACTIVITIES: ['Running tests', 'Validating results']
      }
    ];
  }

  // Extract phases from observations
  const observations = collectedData.observations;
  const phaseMap = new Map();

  for (const obs of observations) {
    // Classify each observation into a phase
    // Extract tools from string facts using improved detection
    const tools = obs.facts?.flatMap(f => {
      if (typeof f !== 'string') return [];

      // Use new strict tool detection
      const detection = detectToolCall(f);
      if (!detection) return [];

      // Verify not prose context
      const toolIndex = f.search(new RegExp(`\\b${detection.tool}\\b`, 'i'));
      if (toolIndex >= 0 && isProseContext(f, toolIndex)) {
        return []; // Skip prose matches
      }

      return [detection.tool];
    }) || [];
    const content = obs.narrative || '';

    const phase = classifyConversationPhase(
      tools.map(t => ({ tool: t })),
      content
    );

    if (!phaseMap.has(phase)) {
      phaseMap.set(phase, { count: 0, duration: 0, activities: [] });
    }

    const phaseData = phaseMap.get(phase);
    phaseData.count++;

    // Extract activities from observation narrative with quality validation
    if (content && content.trim().length > 10) { // Min length check
      // Truncate at word boundary
      let activity = content.substring(0, 50);
      const lastSpace = activity.lastIndexOf(' ');
      if (lastSpace > 30) { // Keep reasonable length
        activity = activity.substring(0, lastSpace);
      }

      // Add ellipsis if truncated
      if (activity.length < content.length) {
        activity += '...';
      }

      // Check for meaningful content (not just punctuation)
      const meaningfulContent = activity.replace(/[^a-zA-Z0-9]/g, '');
      if (meaningfulContent.length < 5) continue; // Skip if too short

      // Simple deduplication (exact match)
      if (!phaseData.activities.includes(activity)) {
        phaseData.activities.push(activity);
      }
    }
  }

  return Array.from(phaseMap.entries()).map(([name, data]) => ({
    PHASE_NAME: name,
    DURATION: `${data.count} actions`,
    ACTIVITIES: data.activities.slice(0, 3)
  }));
}

// ───────────────────────────────────────────────────────────────
// FLOWCHART GENERATION
// ───────────────────────────────────────────────────────────────

function generateConversationFlowchart(phases = [], initialRequest = 'User Request') {
  // Truncate and pad helper
  const pad = (text, length) => {
    const truncated = text.substring(0, length);
    return truncated.padEnd(length);
  };

  if (phases.length === 0) {
    // Return simple sequential flow if no phases
    return `╭────────────────────╮
│  ${pad(initialRequest, 16)}  │
╰────────────────────╯
         │
         ▼
   ╭────────╮
   │  Done  │
   ╰────────╯`;
  }

  // Build multi-phase flowchart with visual hierarchy
  let flowchart = `╭────────────────────╮
│  ${pad(initialRequest, 16)}  │
╰────────────────────╯
         │`;

  for (let i = 0; i < phases.length; i++) {
    const phase = phases[i];
    const phaseName = phase.PHASE_NAME || `Phase ${i + 1}`;
    const duration = phase.DURATION || 'N/A';

    // Use standard process boxes for phases
    flowchart += `
         ▼
┌────────────────────┐
│  ${pad(phaseName, 16)}  │
│  ${pad(duration, 16)}  │
└────────────────────┘`;

    // Add connector for next phase
    if (i < phases.length - 1) {
      flowchart += `
         │`;
    }
  }

  // Add terminal completion box
  flowchart += `
         │
         ▼
   ╭────────╮
   │ ✅ Done │
   ╰────────╯`;

  return flowchart;
}

/**
 * Generate workflow flowchart from conversation phases
 * Detects pattern type and generates appropriate visualization
 * Matches parallel-execution.md reference style with wider boxes and inline details
 */
function generateWorkflowFlowchart(phases = []) {
  if (phases.length === 0) {
    return null; // No flowchart if no phases
  }

  // Helper for text padding to 56 chars (reference standard)
  const pad = (text, length = 56) => text.substring(0, length).padEnd(length);

  let flowchart = '';

  // Start terminal (56 chars wide)
  flowchart = `╭────────────────────────────────────────────────────────╮
│${pad('CONVERSATION WORKFLOW', 58).replace(/^(.*)$/, (m) => {
    const padding = Math.floor((58 - 'CONVERSATION WORKFLOW'.length) / 2);
    return ' '.repeat(padding) + 'CONVERSATION WORKFLOW' + ' '.repeat(58 - padding - 'CONVERSATION WORKFLOW'.length);
  })}│
╰────────────────────────────────────────────────────────╯
                        │
                        ▼`;

  const patternType = detectWorkflowPattern(phases);

  if (patternType === 'linear') {
    // Linear sequential flow with detailed boxes
    for (let i = 0; i < phases.length; i++) {
      const phase = phases[i];
      const phaseName = phase.PHASE_NAME || `Phase ${i + 1}`;
      const duration = phase.DURATION || 'Duration unknown';
      const activities = phase.ACTIVITIES || [];

      flowchart += `
┌────────────────────────────────────────────────────────┐
│  ${pad(phaseName, 52)}  │`;

      // Add activity bullets (up to 3)
      for (let j = 0; j < Math.min(3, activities.length); j++) {
        flowchart += `
│  • ${pad(activities[j], 50)}  │`;
      }

      flowchart += `
│  ${pad('Duration: ' + duration, 52)}  │
└────────────────────────────────────────────────────────┘`;

      if (i < phases.length - 1) {
        flowchart += `
                        │
                        ▼`;
      }
    }
  } else if (patternType === 'parallel') {
    // Parallel execution pattern with section dividers
    const firstPhase = phases[0];
    const parallelPhases = phases.slice(1, Math.min(4, phases.length));

    // Preparation phase
    flowchart += `
┌────────────────────────────────────────────────────────┐
│  ${pad(firstPhase.PHASE_NAME || 'Preparation', 52)}  │
│  • ${pad((firstPhase.ACTIVITIES || [])[0] || 'Initial setup', 50)}  │
│  Duration: ${pad(firstPhase.DURATION || 'N/A', 44)}  │
└────────────────────────────────────────────────────────┘
                        │
                        ▼
──────────────────────────────────────────────────────────
PARALLEL EXECUTION - ${parallelPhases.length} concurrent phases
──────────────────────────────────────────────────────────
                        │`;

    // Branch visualization
    if (parallelPhases.length === 2) {
      flowchart += `
      ┌─────────────────┼─────────────────┐
      │                 │                 │
      ▼                 ▼                 ▼`;
    } else {
      flowchart += `
      ┌─────────────────┼─────────────────┐
      │                 │                 │
      ▼                 ▼                 ▼`;
    }

    // Parallel phase boxes (narrower for side-by-side)
    flowchart += `
┌──────────┐      ┌──────────┐      ┌──────────┐`;

    const maxLines = Math.max(...parallelPhases.map(p => (p.ACTIVITIES || []).length + 3));
    for (let line = 0; line < maxLines; line++) {
      flowchart += '\n│';
      for (let i = 0; i < 3 && i < parallelPhases.length; i++) {
        const phase = parallelPhases[i];
        let text = '';

        if (line === 0) {
          text = (phase.PHASE_NAME || `Phase ${i + 1}`).substring(0, 8).padEnd(8);
        } else if (line === 1) {
          text = '        '; // Empty line
        } else if (line === 2) {
          const activity = (phase.ACTIVITIES || [])[0] || '';
          text = ('• ' + activity).substring(0, 8).padEnd(8);
        } else if (line < (phase.ACTIVITIES || []).length + 2) {
          const activity = (phase.ACTIVITIES || [])[line - 2] || '';
          text = ('• ' + activity).substring(0, 8).padEnd(8);
        } else if (line === maxLines - 2) {
          text = '        '; // Empty line
        } else if (line === maxLines - 1) {
          text = (phase.DURATION || 'N/A').substring(0, 8).padEnd(8);
        } else {
          text = '        ';
        }

        flowchart += ` ${text} │${i < 2 && i < parallelPhases.length - 1 ? '      ' : ''}`;
      }
    }

    flowchart += `
└──────────┘      └──────────┘      └──────────┘
      │                 │                 │
      │                 │                 │
      └─────────────────┼─────────────────┘
                        │
                        ▼    (All phases complete)
──────────────────────────────────────────────────────────
SYNCHRONIZATION POINT
──────────────────────────────────────────────────────────`;
  }

  // End terminal
  flowchart += `
                        │
                        ▼
╭────────────────────────────────────────────────────────╮
│${pad('WORKFLOW COMPLETE', 58).replace(/^(.*)$/, (m) => {
    const padding = Math.floor((58 - 'WORKFLOW COMPLETE'.length) / 2);
    return ' '.repeat(padding) + 'WORKFLOW COMPLETE' + ' '.repeat(58 - padding - 'WORKFLOW COMPLETE'.length);
  })}│
╰────────────────────────────────────────────────────────╯`;

  return flowchart;
}

/**
 * Detect workflow pattern from phases
 * Simplified to 2 patterns: linear (≤4 phases) or parallel (>4 phases)
 */
function detectWorkflowPattern(phases = []) {
  if (phases.length === 0) return 'linear';

  // Parallel: many phases (> 4)
  if (phases.length > 4) {
    return 'parallel';
  }

  // Linear: sequential progression (≤ 4 phases)
  return 'linear';
}

/**
 * Build phase details for workflow template
 */
function buildPhaseDetails(phases = []) {
  return phases.map((phase, index) => ({
    INDEX: index + 1,
    PHASE_NAME: phase.PHASE_NAME || `Phase ${index + 1}`,
    DURATION: phase.DURATION || 'N/A',
    ACTIVITIES: phase.ACTIVITIES || [],
    HAS_TRANSITION: index < phases.length - 1,
    FROM_PHASE: phase.PHASE_NAME || `Phase ${index + 1}`,
    TO_PHASE: phases[index + 1]?.PHASE_NAME || 'Complete',
    TRANSITION_TRIGGER: phase.TRANSITION_TRIGGER || 'Completion of previous phase'
  }));
}

/**
 * Extract key features demonstrated in the flowchart
 * Analyzes phases and pattern type to identify what the flowchart shows
 * Simplified to 2 patterns: linear and parallel
 */
function extractFlowchartFeatures(phases = [], patternType = 'linear') {
  const features = [];

  // Pattern-specific features
  if (patternType === 'parallel') {
    features.push({
      FEATURE_NAME: 'Parallel execution',
      FEATURE_DESC: 'Multiple phases running concurrently'
    });
    features.push({
      FEATURE_NAME: 'Synchronization points',
      FEATURE_DESC: 'Coordination between parallel streams'
    });
  } else {
    // Linear pattern
    features.push({
      FEATURE_NAME: 'Sequential progression',
      FEATURE_DESC: 'Step-by-step workflow execution'
    });
  }

  // Phase-based features (data-driven)
  if (phases.length > 0) {
    const hasActivities = phases.some(p => p.ACTIVITIES && p.ACTIVITIES.length > 0);
    if (hasActivities) {
      features.push({
        FEATURE_NAME: 'Detailed activities',
        FEATURE_DESC: 'Inline breakdown of phase tasks'
      });
    }

    const hasDurations = phases.every(p => p.DURATION && p.DURATION !== 'N/A');
    if (hasDurations) {
      features.push({
        FEATURE_NAME: 'Timing information',
        FEATURE_DESC: 'Duration tracking for each phase'
      });
    }
  }

  // Generic features
  features.push({
    FEATURE_NAME: 'Phase count',
    FEATURE_DESC: `${phases.length} distinct phases tracked`
  });

  return features;
}

/**
 * Get use case scenarios based on pattern type
 * Maps workflow patterns to applicable real-world scenarios
 * Simplified to 2 patterns: linear and parallel
 */
function getPatternUseCases(patternType = 'linear') {
  const useCaseMap = {
    linear: [
      'Sequential feature implementations',
      'Bug fixes and patches',
      'Documentation generation',
      'Single-file modifications',
      'Simple refactoring',
      'Research-driven development'
    ],
    parallel: [
      'Concurrent development tasks',
      'Multi-file refactoring',
      'Parallel research and implementation',
      'Independent feature development',
      'Distributed problem-solving',
      'Complex system changes'
    ]
  };

  return useCaseMap[patternType] || useCaseMap.linear;
}

// ───────────────────────────────────────────────────────────────
// DECISION TREE VISUALIZATION HELPERS
// ───────────────────────────────────────────────────────────────

/**
 * Pad or truncate text to specified width
 */
function padText(text, width, align = 'left') {
  const cleaned = text.substring(0, width);
  if (align === 'center') {
    const padding = Math.max(0, width - cleaned.length);
    const leftPad = Math.floor(padding / 2);
    const rightPad = padding - leftPad;
    return ' '.repeat(leftPad) + cleaned + ' '.repeat(rightPad);
  }
  return cleaned.padEnd(width);
}

/**
 * Format decision header box with context and metadata
 */
function formatDecisionHeader(title, context, confidence, timestamp) {
  const width = 48;
  const innerWidth = width - 4;

  // Format timestamp
  const date = new Date(timestamp);
  const timeStr = date.toISOString().split('T')[1].substring(0, 8);
  const dateStr = date.toISOString().split('T')[0];

  // Truncate context for header (innerWidth - 9 = max context display width after "Context: " prefix)
  const maxContextWidth = innerWidth - 9;
  const contextSnippet = context ? context.substring(0, maxContextWidth - 3) + (context.length > maxContextWidth - 3 ? '...' : '') : '';

  return `╭${'─'.repeat(width)}╮
│  DECISION: ${padText(title, innerWidth - 10)}  │
│  Context: ${padText(contextSnippet, innerWidth - 9)}  │
│  Confidence: ${confidence}% | ${dateStr} @ ${timeStr}${' '.repeat(Math.max(0, innerWidth - 37 - confidence.toString().length))}  │
╰${'─'.repeat(width)}╯`;
}

/**
 * Format option box with pros/cons
 */
function formatOptionBox(option, isChosen, maxWidth = 20) {
  let box = `┌${'─'.repeat(maxWidth)}┐\n`;
  box += `│  ${padText(option.LABEL || 'Option', maxWidth - 4)}  │\n`;

  // Add pros if present
  if (option.PROS && option.PROS.length > 0) {
    for (const pro of option.PROS.slice(0, 2)) {
      const proText = pro.PRO || pro;
      box += `│  ✓ ${padText(proText, maxWidth - 6)}  │\n`;
    }
  }

  // Add cons if present
  if (option.CONS && option.CONS.length > 0) {
    for (const con of option.CONS.slice(0, 2)) {
      const conText = con.CON || con;
      box += `│  ✗ ${padText(conText, maxWidth - 6)}  │\n`;
    }
  }

  box += `└${'─'.repeat(maxWidth)}┘`;
  return box;
}

/**
 * Format chosen decision box with rationale and evidence
 */
function formatChosenBox(chosen, rationale, evidence) {
  const width = 40;

  let box = `┌${'─'.repeat(width)}┐\n`;
  box += `│  ${padText('✅ CHOSEN: ' + chosen, width - 4)}  │\n`;
  box += `│  ${padText('', width - 4)}  │\n`;

  // Add rationale (split into lines if needed)
  if (rationale) {
    box += `│  ${padText('Rationale:', width - 4)}  │\n`;
    const rationaleText = rationale.substring(0, 100);
    const words = rationaleText.split(' ');
    let line = '';

    for (const word of words) {
      if ((line + ' ' + word).length > width - 4) {
        box += `│  ${padText(line, width - 4)}  │\n`;
        line = word;
      } else {
        line += (line ? ' ' : '') + word;
      }
    }
    if (line) {
      box += `│  ${padText(line, width - 4)}  │\n`;
    }
  }

  // Add evidence if present
  if (evidence && evidence.length > 0) {
    box += `│  ${padText('', width - 4)}  │\n`;
    box += `│  ${padText('Evidence:', width - 4)}  │\n`;
    for (const ev of evidence.slice(0, 3)) {
      const evText = ev.EVIDENCE_ITEM || ev;
      box += `│  ${padText('• ' + evText, width - 4)}  │\n`;
    }
  }

  box += `└${'─'.repeat(width)}┘`;
  return box;
}

/**
 * Format caveats box
 */
function formatCaveatsBox(caveats) {
  if (!caveats || caveats.length === 0) return '';

  const width = 40;
  let box = `┌${'─'.repeat(width)}┐\n`;
  box += `│  ${padText('⚠️  Caveats:', width - 4)}  │\n`;

  for (const caveat of caveats.slice(0, 3)) {
    const text = caveat.CAVEAT_ITEM || caveat;
    box += `│  ${padText('• ' + text, width - 4)}  │\n`;
  }

  box += `└${'─'.repeat(width)}┘`;
  return box;
}

/**
 * Format follow-up actions box
 */
function formatFollowUpBox(followup) {
  if (!followup || followup.length === 0) return '';

  const width = 40;
  let box = `┌${'─'.repeat(width)}┐\n`;
  box += `│  ${padText('📋 Follow-up Actions:', width - 4)}  │\n`;

  for (const action of followup.slice(0, 3)) {
    const text = action.FOLLOWUP_ITEM || action;
    box += `│  ${padText('□ ' + text, width - 4)}  │\n`;
  }

  box += `└${'─'.repeat(width)}┘`;
  return box;
}

/**
 * Generate enhanced decision tree with full decision context
 * Accepts full decision object with all metadata
 */
function generateDecisionTree(decisionData) {
  // Handle legacy format (simple parameters) for backwards compatibility
  if (typeof decisionData === 'string') {
    const title = decisionData;
    const options = arguments[1] || [];
    const chosen = arguments[2] || '';

    // Simple legacy tree
    const pad = (text, length) => text.substring(0, length).padEnd(length);
    return `┌──────────────────────┐
│  ${pad(title, 18)}  │
└──────────────────────┘
         │
         ▼
    ╱──────────╲
   ╱  Options?   ╲
   ╲            ╱
    ╲──────────╱
      ${chosen ? '✓' : ''}`;
  }

  // Extract decision data
  const {
    TITLE = 'Decision',
    CONTEXT = '',
    CONFIDENCE = 75,
    TIMESTAMP = new Date().toISOString(),
    OPTIONS = [],
    CHOSEN = '',
    RATIONALE = '',
    EVIDENCE = [],
    CAVEATS = [],
    FOLLOWUP = []
  } = decisionData;

  if (OPTIONS.length === 0) {
    return formatDecisionHeader(TITLE, CONTEXT, CONFIDENCE, TIMESTAMP) + '\n' +
           '         │\n' +
           '         ▼\n' +
           '   (No options provided)';
  }

  // Start with header
  let tree = formatDecisionHeader(TITLE, CONTEXT, CONFIDENCE, TIMESTAMP);
  tree += '\n                      │\n                      ▼\n';

  // Add decision diamond
  const questionText = OPTIONS.length > 2 ? `Select from ${OPTIONS.length} options?` : 'Choose option?';
  tree += `              ╱${'─'.repeat(questionText.length + 2)}╲\n`;
  tree += `             ╱  ${questionText}  ╲\n`;
  tree += `            ╱${' '.repeat(questionText.length + 4)}╲\n`;
  tree += `            ╲${' '.repeat(questionText.length + 4)}╱\n`;
  tree += `             ╲${'─'.repeat(questionText.length + 2)}╱\n`;

  // Determine which option is chosen
  const chosenOption = OPTIONS.find(opt =>
    opt.LABEL === CHOSEN ||
    CHOSEN.includes(opt.LABEL) ||
    opt.LABEL.includes(CHOSEN)
  );

  // Layout options (max 4 displayed)
  const displayedOptions = OPTIONS.slice(0, 4);
  const spacing = displayedOptions.length === 2 ? 15 : 10;

  // Create branch lines
  if (displayedOptions.length === 2) {
    tree += '               │           │\n';
    tree += `            ${padText(displayedOptions[0].LABEL, 10)}     ${padText(displayedOptions[1].LABEL, 10)}\n`;
    tree += '               │           │\n';
    tree += '               ▼           ▼\n';
  } else {
    let branchLine = '      ';
    for (let i = 0; i < displayedOptions.length; i++) {
      branchLine += '│' + ' '.repeat(spacing);
    }
    tree += branchLine.trimEnd() + '\n';

    // Option labels
    let labelLine = '   ';
    for (const opt of displayedOptions) {
      labelLine += padText(opt.LABEL, spacing + 1);
    }
    tree += labelLine.trimEnd() + '\n';
  }

  // Show option boxes for binary or three-way decisions
  if (displayedOptions.length <= 3) {
    const boxes = displayedOptions.map(opt =>
      formatOptionBox(opt, opt === chosenOption, 18).split('\n')
    );

    const maxLines = Math.max(...boxes.map(b => b.length));

    for (let lineIdx = 0; lineIdx < maxLines; lineIdx++) {
      let line = '';
      for (let boxIdx = 0; boxIdx < boxes.length; boxIdx++) {
        const boxLine = boxes[boxIdx][lineIdx] || ' '.repeat(20);
        line += boxLine + '  ';
      }
      tree += line.trimEnd() + '\n';
    }
  }

  // Show chosen option box
  if (chosenOption || CHOSEN) {
    tree += '             │           │\n';
    tree += '             │           ▼\n';
    tree += '             │  ' + formatChosenBox(CHOSEN, RATIONALE, EVIDENCE).split('\n').join('\n             │  ') + '\n';
    tree += '             │           │\n';
    tree += '             └─────┬─────┘\n';
    tree += '                   │\n';
    tree += '                   ▼\n';
  }

  // Add caveats section if present
  if (CAVEATS && CAVEATS.length > 0) {
    tree += formatCaveatsBox(CAVEATS).split('\n').map(line => '     ' + line).join('\n') + '\n';
    tree += '                   │\n';
    tree += '                   ▼\n';
  }

  // Add follow-up section if present
  if (FOLLOWUP && FOLLOWUP.length > 0) {
    tree += formatFollowUpBox(FOLLOWUP).split('\n').map(line => '     ' + line).join('\n') + '\n';
    tree += '                   │\n';
    tree += '                   ▼\n';
  }

  // Terminal
  tree += '        ╭────────────────╮\n';
  tree += '        │ Decision Logged │\n';
  tree += '        ╰────────────────╯';

  return tree;
}

function classifyDiagramPattern(asciiArt) {
  // Classify diagram by create-flowchart pattern library
  // Based on 7 core patterns from create-flowchart skill

  const art = asciiArt.toLowerCase();
  let complexity = 'Low';
  let pattern = 'Unknown';

  // Count various indicators
  const hasDecisionDiamond = asciiArt.includes('╱') && asciiArt.includes('╲');
  const hasParallelBlock = art.includes('parallel') || asciiArt.includes('───────────────');
  const hasApprovalGate = asciiArt.includes('╔═') || art.includes('approval') || art.includes('gate');
  const hasLoopBack = art.includes('loop') || (asciiArt.includes('└') && asciiArt.includes('┘'));
  const hasNestedProcess = art.includes('sub-process') || art.includes('sub process');
  const hasPipeline = asciiArt.includes('────▶') || (art.includes('stage') && asciiArt.includes('│'));

  // Box count estimation (rough complexity indicator)
  const boxCount = (asciiArt.match(/┌[─]+┐/g) || []).length +
                   (asciiArt.match(/╭[─]+╮/g) || []).length +
                   (asciiArt.match(/╔[═]+╗/g) || []).length;

  // Pattern 5: Approval Gate (highest priority - specific marker)
  if (hasApprovalGate) {
    pattern = 'Approval Gate';
    complexity = 'Medium';
  }
  // Pattern 6: Loop/Iteration
  else if (hasLoopBack) {
    pattern = 'Loop/Iteration';
    complexity = 'Medium';
  }
  // Pattern 3: Parallel Execution
  else if (hasParallelBlock) {
    pattern = 'Parallel Execution';
    complexity = 'High';
  }
  // Pattern 2: Decision Branch
  else if (hasDecisionDiamond) {
    pattern = 'Decision Branch';
    complexity = boxCount > 5 ? 'High' : 'Medium';
  }
  // Pattern 7: Multi-Stage Pipeline
  else if (hasPipeline) {
    pattern = 'Multi-Stage Pipeline';
    complexity = 'Medium';
  }
  // Pattern 4: Nested Sub-Process
  else if (hasNestedProcess) {
    pattern = 'Nested Sub-Process';
    complexity = 'High';
  }
  // Pattern 1: Linear Sequential Flow (default)
  else if (asciiArt.includes('┌') || asciiArt.includes('│') || asciiArt.includes('▼')) {
    pattern = 'Linear Sequential';
    complexity = boxCount > 10 ? 'Medium' : 'Low';
  }

  return { pattern, complexity };
}

// ───────────────────────────────────────────────────────────────
// TEMPLATE RENDERING
// ───────────────────────────────────────────────────────────────

async function populateTemplate(templateName, data) {
  const templatePath = path.join(CONFIG.TEMPLATE_DIR, `${templateName}_template.md`);
  const template = await fs.readFile(templatePath, 'utf-8');

  return renderTemplate(template, data);
}

function cleanupExcessiveNewlines(text) {
  // Replace 3+ consecutive newlines with exactly 2 newlines (one blank line)
  return text.replace(/\n{3,}/g, '\n\n');
}

/**
 * Check if value should be treated as falsy in template conditionals
 * @param {*} value - Value to check
 * @returns {boolean} True if value is falsy
 */
function isFalsy(value) {
  if (value === undefined || value === null || value === false) return true;
  if (typeof value === 'string' && value.toLowerCase() === 'false') return true;
  if (typeof value === 'number' && value === 0) return true;
  if (typeof value === 'string' && value.trim() === '') return true;
  if (Array.isArray(value) && value.length === 0) return true;
  return false;
}

function renderTemplate(template, data, parentData = {}) {
  let result = template;

  // Merge parent data with current data for nested contexts
  const mergedData = { ...parentData, ...data };

  // Array loops: {{#ARRAY}}...{{/ARRAY}} - Process these first to handle nesting
  result = result.replace(/\{\{#(\w+)\}\}([\s\S]*?)\{\{\/\1\}\}/g, (match, key, content) => {
    const value = mergedData[key];

    // Handle boolean flags and falsy values consistently
    if (typeof value === 'boolean') {
      return value ? renderTemplate(content, mergedData, parentData) : '';
    }

    // Handle all falsy values consistently
    if (isFalsy(value)) {
      return '';
    }

    // Handle arrays
    if (!Array.isArray(value)) {
      // Not an array, not boolean, not undefined - treat as truthy conditional
      return renderTemplate(content, mergedData, parentData);
    }

    if (value.length === 0) {
      return '';
    }

    // Render each array item with access to parent context
    return value.map(item => {
      if (typeof item === 'object' && item !== null) {
        // Pass parent data down to nested rendering
        return renderTemplate(content, item, mergedData);
      }
      // Primitive value - create wrapper object with both ITEM and . (dot) support
      return renderTemplate(content, { ITEM: item, '.': item }, mergedData);
    }).join('');
  });

  // Inverted sections: {{^ARRAY}}...{{/ARRAY}} (render if empty/false)
  result = result.replace(/\{\{\^(\w+)\}\}([\s\S]*?)\{\{\/\1\}\}/g, (match, key, content) => {
    const value = mergedData[key];

    // Use consistent falsy checking
    if (isFalsy(value)) {
      return renderTemplate(content, mergedData, parentData);
    }

    return '';
  });

  // Simple variable replacement: {{VAR}} or {{.}}
  result = result.replace(/\{\{([\w.]+)\}\}/g, (match, key) => {
    const value = mergedData[key];

    if (value === undefined || value === null) {
      console.warn(`⚠️  Missing template data for: {{${key}}}`);
      return ''; // Fail-safe: return empty string instead of preserving placeholder
    }

    // Handle arrays - stringify properly instead of [object Object]
    if (Array.isArray(value)) {
      return value.map(item => {
        if (typeof item === 'object' && item !== null) {
          // Extract first property value or stringify
          const firstKey = Object.keys(item)[0];
          return firstKey ? item[firstKey] : JSON.stringify(item);
        }
        return String(item);
      }).join(', ');
    }

    // Handle objects - stringify properly instead of [object Object]
    if (typeof value === 'object') {
      const firstKey = Object.keys(value)[0];
      return firstKey ? value[firstKey] : JSON.stringify(value);
    }

    // Handle booleans
    if (typeof value === 'boolean') {
      return value ? 'Yes' : 'No';
    }

    return String(value);
  });

  // Clean up excessive newlines before returning
  return cleanupExcessiveNewlines(result);
}

// ───────────────────────────────────────────────────────────────
// ENTRY POINT
// ───────────────────────────────────────────────────────────────

if (require.main === module) {
  main().catch((error) => {
    console.error(`❌ Fatal error: ${error.message}`);
    console.error(error.stack);
    process.exit(1);
  });
}

module.exports = { main, detectSpecFolder, collectSessionData };
