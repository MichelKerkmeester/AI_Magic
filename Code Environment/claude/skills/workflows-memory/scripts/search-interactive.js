#!/usr/bin/env node
/**
 * Interactive Memory Search CLI - Entry Point
 *
 * Provides an interactive terminal interface for searching and browsing
 * memory files. Supports pagination, filtering, clustering, and session
 * resumption.
 *
 * @module search-interactive
 * @version 1.0.0
 *
 * Part of Spec 015 - Interactive Memory Search
 * Phase 2: Foundation - Task T009
 *
 * Usage:
 *   node search-interactive.js <query>              # Start new search
 *   node search-interactive.js --resume             # Resume last session
 *   node search-interactive.js --resume <id>        # Resume specific session
 *   node search-interactive.js <query> --no-color   # Disable colors
 *   node search-interactive.js <query> --debug      # Enable debug output
 *
 * Examples:
 *   node search-interactive.js "authentication flow"
 *   node search-interactive.js "oauth jwt" --no-color
 *   node search-interactive.js --resume abc123
 */

'use strict';

const path = require('path');

// Import modules at top level to avoid scope issues
const interactiveSearchModule = require('./lib/interactive-search');

// ───────────────────────────────────────────────────────────────
// VERSION & CONFIGURATION
// ───────────────────────────────────────────────────────────────

const VERSION = '1.0.0';
const SCRIPT_NAME = 'search-interactive';

const DEFAULT_OPTIONS = {
  limit: 20,
  pageSize: 5,
  minSimilarity: 50,
  noColor: false,
  debug: false
};

// ───────────────────────────────────────────────────────────────
// ARGUMENT PARSING
// ───────────────────────────────────────────────────────────────

/**
 * Parse command line arguments
 *
 * @param {string[]} args - Command line arguments (process.argv.slice(2))
 * @returns {Object} Parsed arguments
 *
 * @example
 * parseArgs(['auth', 'flow', '--no-color'])
 * // { query: 'auth flow', noColor: true, ... }
 */
function parseArgs(args) {
  const parsed = {
    query: null,
    resume: false,
    sessionId: null,
    noColor: DEFAULT_OPTIONS.noColor,
    debug: DEFAULT_OPTIONS.debug,
    limit: DEFAULT_OPTIONS.limit,
    pageSize: DEFAULT_OPTIONS.pageSize,
    minSimilarity: DEFAULT_OPTIONS.minSimilarity,
    help: false,
    version: false
  };

  const queryParts = [];

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];

    switch (arg) {
      case '--help':
      case '-h':
        parsed.help = true;
        break;

      case '--version':
      case '-v':
        parsed.version = true;
        break;

      case '--resume':
      case '-r':
        parsed.resume = true;
        // Check if next arg is a session ID (not a flag)
        if (args[i + 1] && !args[i + 1].startsWith('-')) {
          parsed.sessionId = args[++i];
        }
        break;

      case '--no-color':
        parsed.noColor = true;
        break;

      case '--debug':
      case '-d':
        parsed.debug = true;
        break;

      case '--limit':
      case '-l':
        if (args[i + 1]) {
          parsed.limit = parseInt(args[++i], 10) || DEFAULT_OPTIONS.limit;
        }
        break;

      case '--page-size':
        if (args[i + 1]) {
          parsed.pageSize = parseInt(args[++i], 10) || DEFAULT_OPTIONS.pageSize;
        }
        break;

      case '--min-similarity':
        if (args[i + 1]) {
          parsed.minSimilarity = parseInt(args[++i], 10) || DEFAULT_OPTIONS.minSimilarity;
        }
        break;

      default:
        // Collect non-flag arguments as query parts
        if (!arg.startsWith('-')) {
          queryParts.push(arg);
        } else {
          console.warn(`Unknown option: ${arg}`);
        }
    }
  }

  // Join query parts
  if (queryParts.length > 0) {
    parsed.query = queryParts.join(' ');
  }

  return parsed;
}

/**
 * Validate parsed arguments
 *
 * @param {Object} args - Parsed arguments
 * @returns {Object} Validation result { valid: boolean, error: string|null }
 */
function validateArgs(args) {
  // Help or version are always valid
  if (args.help || args.version) {
    return { valid: true, error: null };
  }

  // Must have either query or resume flag
  if (!args.query && !args.resume) {
    return {
      valid: false,
      error: 'Either a search query or --resume flag is required'
    };
  }

  // Cannot have both query and resume (unless resuming with refinement)
  // Actually, query + resume could mean "refine previous search" - allow it

  // Validate limit
  if (args.limit < 1 || args.limit > 100) {
    return {
      valid: false,
      error: 'Limit must be between 1 and 100'
    };
  }

  // Validate page size
  if (args.pageSize < 1 || args.pageSize > 20) {
    return {
      valid: false,
      error: 'Page size must be between 1 and 20'
    };
  }

  // Validate min similarity
  if (args.minSimilarity < 0 || args.minSimilarity > 100) {
    return {
      valid: false,
      error: 'Minimum similarity must be between 0 and 100'
    };
  }

  return { valid: true, error: null };
}

// ───────────────────────────────────────────────────────────────
// HELP & VERSION OUTPUT
// ───────────────────────────────────────────────────────────────

/**
 * Display help message
 */
function showHelp() {
  console.log(`
${SCRIPT_NAME} v${VERSION} - Interactive Memory Search

USAGE:
  ${SCRIPT_NAME} <query>                   Start new search
  ${SCRIPT_NAME} --resume [session-id]     Resume previous session
  ${SCRIPT_NAME} <query> [options]         Search with options

OPTIONS:
  --help, -h              Show this help message
  --version, -v           Show version number
  --resume, -r [id]       Resume last session or specific session
  --no-color              Disable colored output
  --debug, -d             Enable debug output
  --limit, -l <n>         Maximum results to fetch (default: ${DEFAULT_OPTIONS.limit})
  --page-size <n>         Results per page (default: ${DEFAULT_OPTIONS.pageSize})
  --min-similarity <n>    Minimum similarity score 0-100 (default: ${DEFAULT_OPTIONS.minSimilarity})

INTERACTIVE COMMANDS:
  After results are displayed, use these commands:

  Navigation:
    n, next               Next page of results
    p, prev               Previous page
    b, back               Return to previous view

  Result Actions:
    v #, view #           Preview memory content inline
    o #, open #           Open memory file in $EDITOR
    l #, load #           Load memory into conversation context

  Filtering:
    c, cluster            Group results by spec folder
    u, uncluster          Return to flat list
    f <filter>            Apply filter (folder:name, date:>YYYY-MM-DD, tag:name)
    clear                 Remove all filters

  Other:
    ?, help               Show help menu
    q, quit               Exit search mode

EXAMPLES:
  ${SCRIPT_NAME} "authentication flow"
  ${SCRIPT_NAME} "oauth jwt security" --no-color
  ${SCRIPT_NAME} --resume
  ${SCRIPT_NAME} --resume abc123-def456

For more information, see: specs/015-interactive-memory-search/
`);
}

/**
 * Display version
 */
function showVersion() {
  console.log(`${SCRIPT_NAME} v${VERSION}`);
}

// ───────────────────────────────────────────────────────────────
// INITIALIZATION
// ───────────────────────────────────────────────────────────────

/**
 * Initialize the interactive search session
 *
 * @param {Object} args - Parsed arguments
 * @returns {Promise<void>}
 */
async function initialize(args) {
  // Set color mode based on args and environment
  if (args.noColor || process.env.NO_COLOR === '1') {
    const formatter = require('./lib/result-formatter');
    formatter.setColorMode(false);
  }

  // Enable debug logging
  if (args.debug) {
    process.env.DEBUG_INTERACTIVE = '1';
    console.log('[DEBUG] Arguments:', JSON.stringify(args, null, 2));
  }

  // Handle resume mode
  if (args.resume) {
    await resumeSession(args);
    return;
  }

  // Start new search
  await startNewSearch(args);
}

/**
 * Resume a previous search session
 *
 * @param {Object} args - Parsed arguments with sessionId
 * @returns {Promise<void>}
 */
async function resumeSession(args) {
  const sessionState = require('./lib/session-state');

  try {
    let session;

    if (args.sessionId) {
      // Load specific session
      session = await sessionState.loadSession(args.sessionId);
      if (!session) {
        console.error(`Session not found or expired: ${args.sessionId}`);
        process.exit(1);
      }
    } else {
      // Load most recent session
      session = await sessionState.getCurrentSession();
      if (!session) {
        console.error('No previous session found. Start a new search with a query.');
        process.exit(1);
      }
    }

    console.log(`Resuming session: ${session.sessionId}`);
    console.log(`Query: "${session.query}"`);
    console.log(`Results: ${session.results?.length || 0}`);
    console.log(`Expires: ${sessionState.getTimeRemainingHuman(session)}`);
    console.log('');

    // Run interactive loop with restored session
    await runInteractive(session, args);
  } catch (error) {
    console.error(`Failed to resume session: ${error.message}`);
    if (args.debug) {
      console.error(error.stack);
    }
    process.exit(1);
  }
}

/**
 * Start a new search session
 *
 * @param {Object} args - Parsed arguments with query
 * @returns {Promise<void>}
 */
async function startNewSearch(args) {
  const sessionState = require('./lib/session-state');

  try {
    console.log(`Searching for: "${args.query}"`);
    console.log('');

    // Perform vector search
    const results = await performSearch(args.query, {
      limit: args.limit,
      minSimilarity: args.minSimilarity
    });

    if (results.length === 0) {
      console.log('No results found matching your query.');
      process.exit(0);
    }

    console.log(`Found ${results.length} matching memories.`);
    console.log('');

    // Create new session
    const session = sessionState.createSession(args.query, results);

    // Save session for potential resume
    await sessionState.saveSession(session);

    if (args.debug) {
      console.log(`[DEBUG] Session created: ${session.sessionId}`);
    }

    // Run interactive loop
    await runInteractive(session, args);
  } catch (error) {
    console.error(`Search failed: ${error.message}`);
    if (args.debug) {
      console.error(error.stack);
    }
    process.exit(1);
  }
}

/**
 * Perform the actual vector search
 *
 * @param {string} query - Search query
 * @param {Object} options - Search options
 * @returns {Promise<Array>} Search results
 */
async function performSearch(query, options = {}) {
  const { generateEmbedding } = require('./lib/embeddings');
  const { vectorSearch, initializeDb } = require('./lib/vector-index');

  // Initialize database
  initializeDb();

  // Generate embedding for query
  const embedding = await generateEmbedding(query);

  if (!embedding) {
    throw new Error('Failed to generate embedding for query');
  }

  // Perform vector search
  const results = vectorSearch(embedding, {
    limit: options.limit || DEFAULT_OPTIONS.limit,
    minSimilarity: options.minSimilarity || DEFAULT_OPTIONS.minSimilarity
  });

  // Transform results for session storage
  return results.map((result, index) => ({
    rank: index + 1,
    memoryId: result.id,
    title: result.title || path.basename(result.file_path, '.md'),
    filePath: result.file_path,
    specFolder: result.spec_folder,
    anchorId: result.anchor_id,
    similarity: result.similarity,
    snippet: result.snippet || '',
    date: result.created_at || null,
    tags: result.tags || []
  }));
}

/**
 * Run the interactive search loop
 *
 * @param {Object} session - Session state
 * @param {Object} args - Parsed arguments
 * @returns {Promise<void>}
 */
async function runInteractive(session, args) {
  const interactiveSearch = interactiveSearchModule;
  const sessionState = require('./lib/session-state');
  const formatter = require('./lib/result-formatter');
  const readline = require('readline');

  // Create state machine with session data
  const machine = new interactiveSearch.SearchStateMachine({
    pageSize: args.pageSize
  });

  // Restore session state
  machine.restore({
    state: session.state,
    query: session.query,
    results: session.results,
    filters: session.filters,
    pagination: session.pagination,
    selectedResult: null
  });

  // Create readline interface
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    prompt: '> '
  });

  // Display initial results
  displayResults(machine, formatter, args);

  // Show action bar
  console.log(interactiveSearch.formatActionBar(machine.getState(), {
    color: !args.noColor
  }));

  // Interactive loop
  const runLoop = () => {
    rl.question('\n> ', async (input) => {
      const trimmed = input.trim();

      // Parse action
      const action = interactiveSearch.parseAction(trimmed);

      if (args.debug) {
        console.log(`[DEBUG] Action: ${JSON.stringify(action)}`);
      }

      // Execute action
      const result = await interactiveSearch.executeAction(machine, action, {
        output: true
      });

      // Handle result
      if (!result.success && result.message) {
        console.log(`\n  ${result.message}`);
      } else if (result.message) {
        console.log(`\n  ${result.message}`);
      }

      // Handle special outputs
      if (action.type === 'help' && result.output) {
        console.log(result.output);
      }

      // Check for exit
      if (machine.getState() === interactiveSearch.States.EXIT) {
        // Save final session state
        session.state = machine.getState();
        await sessionState.saveSession(session);

        console.log('\nSession saved. Use --resume to continue later.');
        rl.close();
        return;
      }

      // Update session state periodically
      session.state = machine.getState();
      session.filters = machine.filters;
      session.pagination = machine.pagination;
      await sessionState.saveSession(session);

      // Redisplay results if state changed
      if (result.newState !== undefined) {
        displayResults(machine, formatter, args);
      }

      // Show action bar
      console.log(interactiveSearch.formatActionBar(machine.getState(), {
        color: !args.noColor
      }));

      // Continue loop
      runLoop();
    });
  };

  // Handle readline close
  rl.on('close', () => {
    process.exit(0);
  });

  // Start the loop
  runLoop();
}

/**
 * Display current results based on state machine
 *
 * @param {Object} machine - State machine instance
 * @param {Object} formatter - Result formatter module
 * @param {Object} args - Parsed arguments
 */
function displayResults(machine, formatter, args) {
  const state = machine.getState();
  const pagination = machine.getPaginationInfo();

  // Clear screen for clean display
  if (!args.debug) {
    process.stdout.write('\x1Bc');
  }

  // Header
  console.log('');
  console.log(`Query: "${machine.query}"`);
  console.log(`Results: ${pagination.totalResults} | Page ${pagination.page}/${pagination.totalPages}`);
  console.log('-'.repeat(69));

  // Get results to display
  const results = machine.getPageResults();

  if (state === interactiveSearchModule.States.CLUSTERED) {
    // Display clustered results
    const clusters = machine.clusteredResults;
    for (const [folder, items] of Object.entries(clusters)) {
      console.log(`\n  [${folder}] (${items.length} results)`);
      items.slice(0, 3).forEach((item, i) => {
        console.log(`    ${i + 1}. ${item.title || item.filePath}`);
      });
      if (items.length > 3) {
        console.log(`    ... and ${items.length - 3} more`);
      }
    }
  } else if (state === interactiveSearchModule.States.PREVIEW && machine.selectedResult) {
    // Display preview
    const result = machine.selectedResult;
    console.log(`\nPreview: ${result.title}`);
    console.log(`File: ${result.filePath}`);
    console.log(`Similarity: ${result.similarity.toFixed(1)}%`);
    console.log('-'.repeat(69));
    console.log(result.snippet || '[No snippet available]');
    console.log('-'.repeat(69));
  } else {
    // Display flat results
    results.forEach((result, index) => {
      const rank = ((pagination.page - 1) * machine.pagination.pageSize) + index + 1;
      // Similarity is already 0-100, no need to multiply
      const similarity = `${result.similarity.toFixed(0)}%`.padStart(4);
      const folder = result.specFolder ? `[${result.specFolder}]` : '';
      const title = result.title || path.basename(result.filePath);

      console.log(`  ${rank}. ${similarity}  ${folder} ${title}`);
    });
  }

  console.log('');
}

// ───────────────────────────────────────────────────────────────
// MAIN ENTRY POINT
// ───────────────────────────────────────────────────────────────

async function main() {
  const args = parseArgs(process.argv.slice(2));

  // Handle help
  if (args.help) {
    showHelp();
    process.exit(0);
  }

  // Handle version
  if (args.version) {
    showVersion();
    process.exit(0);
  }

  // Validate arguments
  const validation = validateArgs(args);
  if (!validation.valid) {
    console.error(`Error: ${validation.error}`);
    console.error('Use --help for usage information.');
    process.exit(1);
  }

  // Initialize and run
  try {
    await initialize(args);
  } catch (error) {
    console.error(`Fatal error: ${error.message}`);
    if (args.debug) {
      console.error(error.stack);
    }
    process.exit(1);
  }
}

// Run if executed directly
if (require.main === module) {
  main();
}

// ───────────────────────────────────────────────────────────────
// EXPORTS (for testing)
// ───────────────────────────────────────────────────────────────

module.exports = {
  parseArgs,
  validateArgs,
  showHelp,
  showVersion,
  performSearch,
  displayResults,
  VERSION,
  DEFAULT_OPTIONS
};
