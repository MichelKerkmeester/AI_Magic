/**
 * Result Formatter Module - Rich output formatting for interactive memory search
 *
 * Provides terminal-aware formatting for search results, previews, and action menus.
 * Supports color output with NO_COLOR fallback and graceful degradation for narrow terminals.
 *
 * @module result-formatter
 * @version 1.0.0
 *
 * Implements:
 *   - T016-T019: formatCard(), formatResultsPage(), truncation
 *   - T079-T082: Color support, NO_COLOR fallback, narrow terminal
 *
 * Output Format Reference: /specs/015-interactive-memory-search/output_format_design.md
 */

'use strict';

const path = require('path');

// ───────────────────────────────────────────────────────────────
// CONFIGURATION
// ───────────────────────────────────────────────────────────────

/**
 * ANSI escape codes for terminal colors
 * @constant {Object}
 */
const COLORS = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  underline: '\x1b[4m',
  gray: '\x1b[90m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  green: '\x1b[32m',
  white: '\x1b[37m',
  boldWhite: '\x1b[1;37m'
};

/**
 * Default formatting options
 * @constant {Object}
 */
const DEFAULTS = {
  pageSize: 10,
  minTerminalWidth: 40,
  narrowThreshold: 60,
  normalThreshold: 100
};

// ───────────────────────────────────────────────────────────────
// TERMINAL DETECTION
// ───────────────────────────────────────────────────────────────

/**
 * Get current terminal width
 * @returns {number} Terminal width in columns (default 80)
 */
function getTerminalWidth() {
  if (process.stdout && process.stdout.columns) {
    return process.stdout.columns;
  }
  return 80;
}

/**
 * Check if terminal supports color output
 *
 * Respects NO_COLOR and FORCE_COLOR environment variables.
 * Checks TERM environment for color capability.
 *
 * @returns {boolean} True if color output is supported
 *
 * @example
 * if (supportsColor()) {
 *   console.log('\x1b[32mGreen text\x1b[0m');
 * }
 */
function supportsColor() {
  // NO_COLOR spec: https://no-color.org/
  if (process.env.NO_COLOR !== undefined && process.env.NO_COLOR !== '') {
    return false;
  }

  // FORCE_COLOR overrides all other checks
  if (process.env.FORCE_COLOR !== undefined && process.env.FORCE_COLOR !== '0') {
    return true;
  }

  // Not a TTY - no color
  if (!process.stdout || !process.stdout.isTTY) {
    return false;
  }

  // Check TERM environment variable
  const term = process.env.TERM || '';

  // dumb terminals don't support color
  if (term === 'dumb') {
    return false;
  }

  // Common terminals that support color
  if (term.includes('color') ||
      term.includes('256') ||
      term.includes('xterm') ||
      term.includes('screen') ||
      term.includes('vt100') ||
      term.includes('ansi') ||
      term.includes('linux') ||
      term.includes('cygwin') ||
      term.includes('rxvt')) {
    return true;
  }

  // macOS Terminal and iTerm2
  if (process.env.TERM_PROGRAM === 'Apple_Terminal' ||
      process.env.TERM_PROGRAM === 'iTerm.app') {
    return true;
  }

  // Windows Terminal, VS Code, etc.
  if (process.env.WT_SESSION || process.env.VSCODE_GIT_IPC_HANDLE) {
    return true;
  }

  // Default: assume color support if TTY
  return true;
}

/**
 * Get layout mode based on terminal width
 * @param {number} [width] - Terminal width (auto-detected if not provided)
 * @returns {'narrow'|'normal'|'wide'} Layout mode
 */
function getLayoutMode(width = null) {
  const termWidth = width || getTerminalWidth();

  if (termWidth < DEFAULTS.narrowThreshold) {
    return 'narrow';
  } else if (termWidth < DEFAULTS.normalThreshold) {
    return 'normal';
  } else {
    return 'wide';
  }
}

// ───────────────────────────────────────────────────────────────
// COLOR HELPERS
// ───────────────────────────────────────────────────────────────

/**
 * Apply color code if color is supported
 * @param {string} text - Text to colorize
 * @param {string} colorCode - ANSI color code
 * @param {boolean} [colorEnabled] - Override color detection
 * @returns {string} Colorized text or plain text
 */
function colorize(text, colorCode, colorEnabled = null) {
  const useColor = colorEnabled !== null ? colorEnabled : supportsColor();
  if (useColor) {
    return `${colorCode}${text}${COLORS.reset}`;
  }
  return text;
}

/**
 * Get color code for similarity score
 *
 * Score ranges:
 *   - 80-100%: Green (excellent match)
 *   - 50-79%: Yellow (moderate match)
 *   - 30-49%: Red (weak match)
 *   - <30%: Gray (very weak)
 *
 * @param {number} score - Similarity score 0-100
 * @returns {string} ANSI color code
 */
function getScoreColor(score) {
  if (score >= 80) {
    return COLORS.green;
  } else if (score >= 50) {
    return COLORS.yellow;
  } else if (score >= 30) {
    return COLORS.red;
  } else {
    return COLORS.gray;
  }
}

// ───────────────────────────────────────────────────────────────
// TRUNCATION HELPERS
// ───────────────────────────────────────────────────────────────

/**
 * Truncate text at word boundary
 *
 * Attempts to truncate at a word boundary (space) for cleaner output.
 * Falls back to hard truncation if no suitable break point found.
 *
 * @param {string} text - Text to truncate
 * @param {number} maxLength - Maximum length including ellipsis
 * @returns {string} Truncated text with ellipsis if needed
 *
 * @example
 * truncateAtWord('Hello world this is long', 15);
 * // Returns: 'Hello world...'
 */
function truncateAtWord(text, maxLength) {
  if (!text || typeof text !== 'string') {
    return '';
  }

  if (text.length <= maxLength) {
    return text;
  }

  // Reserve space for ellipsis
  const targetLength = maxLength - 3;

  if (targetLength <= 0) {
    return '...';
  }

  // Try to find last space within target length
  const truncated = text.substring(0, targetLength);
  const lastSpace = truncated.lastIndexOf(' ');

  // If space found and it's not too far back (at least 50% of target length)
  if (lastSpace > targetLength * 0.5) {
    return truncated.substring(0, lastSpace) + '...';
  }

  // Fall back to hard truncation
  return truncated + '...';
}

/**
 * Truncate snippet at sentence boundary when possible
 *
 * @param {string} text - Text to truncate
 * @param {number} maxLength - Maximum length
 * @returns {string} Truncated text
 */
function truncateSnippet(text, maxLength) {
  if (!text || typeof text !== 'string') {
    return '';
  }

  // Clean up text (remove extra whitespace, newlines)
  const cleaned = text.replace(/\s+/g, ' ').trim();

  if (cleaned.length <= maxLength) {
    return cleaned;
  }

  // Try to find sentence boundary within length
  const targetLength = maxLength - 3;
  const truncated = cleaned.substring(0, targetLength);

  // Look for sentence endings
  const sentenceEnd = Math.max(
    truncated.lastIndexOf('. '),
    truncated.lastIndexOf('! '),
    truncated.lastIndexOf('? ')
  );

  // If sentence end found and it's not too far back
  if (sentenceEnd > targetLength * 0.6) {
    return truncated.substring(0, sentenceEnd + 1) + '..';
  }

  // Fall back to word boundary truncation
  return truncateAtWord(cleaned, maxLength);
}

/**
 * Format tags with overflow indicator
 *
 * Displays as many tags as fit in maxWidth, with '+N more' indicator.
 *
 * @param {string[]} tags - Array of tags
 * @param {number} maxWidth - Maximum character width for tags
 * @returns {string} Formatted tags string
 *
 * @example
 * formatTags(['oauth', 'jwt', 'pkce', 'auth', 'security'], 25);
 * // Returns: 'oauth, jwt, pkce +2 more'
 */
function formatTags(tags, maxWidth) {
  if (!Array.isArray(tags) || tags.length === 0) {
    return '';
  }

  // Filter out empty tags
  const validTags = tags.filter(t => t && typeof t === 'string' && t.trim());

  if (validTags.length === 0) {
    return '';
  }

  const result = [];
  let currentWidth = 0;
  let remainingCount = 0;

  for (let i = 0; i < validTags.length; i++) {
    const tag = validTags[i].trim();
    const separator = result.length > 0 ? ', ' : '';
    const tagWidth = separator.length + tag.length;

    // Calculate potential "+N more" suffix width
    const remaining = validTags.length - result.length - 1;
    const moreWidth = remaining > 0 ? ` +${remaining} more`.length : 0;

    // Check if tag fits with room for potential "+N more"
    if (currentWidth + tagWidth + moreWidth <= maxWidth) {
      result.push(tag);
      currentWidth += tagWidth;
    } else {
      remainingCount = validTags.length - result.length;
      break;
    }
  }

  let output = result.join(', ');

  if (remainingCount > 0) {
    output += ` +${remainingCount} more`;
  }

  return output;
}

// ───────────────────────────────────────────────────────────────
// DATE FORMATTING
// ───────────────────────────────────────────────────────────────

/**
 * Format date for display
 *
 * Returns relative date for recent items:
 *   - Today, Yesterday for recent
 *   - 'Mon DD' for same year
 *   - 'Mon DD, YYYY' for different year
 *
 * @param {string|Date} date - Date to format
 * @param {boolean} [extended=false] - Use extended format with day name
 * @returns {string} Formatted date string
 */
function formatDate(date, extended = false) {
  if (!date) {
    return '';
  }

  const d = date instanceof Date ? date : new Date(date);

  if (isNaN(d.getTime())) {
    return '';
  }

  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const dateDay = new Date(d.getFullYear(), d.getMonth(), d.getDate());

  const diffDays = Math.floor((today - dateDay) / (1000 * 60 * 60 * 24));

  // Relative dates for recent items
  if (diffDays === 0) {
    return 'Today';
  } else if (diffDays === 1) {
    return 'Yesterday';
  }

  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  const month = months[d.getMonth()];
  const day = d.getDate();

  if (extended) {
    const dayName = days[d.getDay()];
    const year = d.getFullYear();
    const hours = String(d.getHours()).padStart(2, '0');
    const minutes = String(d.getMinutes()).padStart(2, '0');
    return `${dayName} ${month} ${day}, ${year} ${hours}:${minutes}`;
  }

  // Different year - include year
  if (d.getFullYear() !== now.getFullYear()) {
    return `${month} ${day}, ${d.getFullYear()}`;
  }

  return `${month} ${day}`;
}

// ───────────────────────────────────────────────────────────────
// RESULT CARD FORMATTING
// ───────────────────────────────────────────────────────────────

/**
 * Extract spec folder short name from path
 * @param {string} specFolder - Full spec folder path or name
 * @returns {string} Short folder name without 'specs/' prefix
 */
function getShortFolderName(specFolder) {
  if (!specFolder) {
    return '';
  }

  // Remove 'specs/' prefix if present
  let name = specFolder.replace(/^specs\//, '');

  // Remove leading path components
  const parts = name.split('/');
  return parts[parts.length - 1] || name;
}

/**
 * Extract title from result
 *
 * Priority:
 *   1. result.title field
 *   2. H1 extracted from content
 *   3. Filename topic portion
 *
 * @param {Object} result - Search result object
 * @returns {string} Extracted title
 */
function extractTitle(result) {
  if (result.title) {
    return result.title;
  }

  if (result.file_path) {
    // Extract topic from filename: DD-MM-YY_HH-MM__topic.md -> topic
    const basename = path.basename(result.file_path, '.md');
    const topicMatch = basename.match(/__(.+)$/);
    if (topicMatch) {
      // Convert underscores/hyphens to spaces and title case
      return topicMatch[1]
        .replace(/[-_]/g, ' ')
        .replace(/\b\w/g, c => c.toUpperCase());
    }
    return basename;
  }

  return 'Untitled Memory';
}

/**
 * Format a single result card
 *
 * Standard 3-line format:
 *   #n [XX%] Title
 *      Folder: name  |  Date: Mon DD  |  Tags: tag1, tag2
 *      "Snippet excerpt from content..."
 *
 * Narrow format (<60 cols):
 *   #n [XX%] Title
 *      folder | date
 *
 * Wide format (100+ cols):
 *   #n [XX%] Title                                         folder-name
 *      Date: Full Date  |  Tags: tag1, tag2, tag3, more tags
 *      "Longer snippet with more content visible..."
 *
 * @param {Object} result - Search result object
 * @param {Object} [options] - Formatting options
 * @param {number} [options.rank] - Result rank (1-indexed)
 * @param {boolean} [options.useColor] - Enable color output
 * @param {number} [options.terminalWidth] - Terminal width override
 * @param {boolean} [options.showSnippet=true] - Show snippet line
 * @returns {string} Formatted result card
 */
function formatCard(result, options = {}) {
  const {
    rank = 1,
    useColor = supportsColor(),
    terminalWidth = getTerminalWidth(),
    showSnippet = true
  } = options;

  const layout = getLayoutMode(terminalWidth);
  const lines = [];

  // Extract data from result
  const similarity = typeof result.similarity === 'number'
    ? result.similarity
    : 0;
  const title = extractTitle(result);
  const folder = getShortFolderName(result.spec_folder);
  const date = formatDate(result.created_at, layout === 'wide');
  const tags = Array.isArray(result.trigger_phrases)
    ? result.trigger_phrases
    : [];

  // Calculate available widths
  const rankWidth = rank < 10 ? 3 : 4;  // '#1 ' or '#10 '
  const scoreWidth = 6;  // '[XX%] '
  const prefixWidth = rankWidth + scoreWidth;

  // ─── LINE 1: Header Row ───────────────────────────────────────

  const rankStr = colorize(`#${rank}`, COLORS.bold, useColor);
  const scoreColor = getScoreColor(similarity);
  const scoreStr = colorize(`[${Math.round(similarity)}%]`, scoreColor, useColor);

  if (layout === 'wide') {
    // Wide: Title on left, folder right-aligned
    const titleMaxWidth = terminalWidth - prefixWidth - folder.length - 4;
    const truncatedTitle = truncateAtWord(title, titleMaxWidth);
    const titleStr = colorize(truncatedTitle, COLORS.boldWhite, useColor);
    const padding = terminalWidth - prefixWidth - truncatedTitle.length - folder.length - 2;
    const paddingStr = ' '.repeat(Math.max(1, padding));
    const folderStr = colorize(folder, COLORS.gray, useColor);

    lines.push(`${rankStr} ${scoreStr} ${titleStr}${paddingStr}${folderStr}`);
  } else {
    // Normal/Narrow: Just rank, score, title
    const titleMaxWidth = terminalWidth - prefixWidth - 2;
    const titleStr = colorize(
      truncateAtWord(title, titleMaxWidth),
      COLORS.boldWhite,
      useColor
    );
    lines.push(`${rankStr} ${scoreStr} ${titleStr}`);
  }

  // ─── LINE 2: Metadata Row ─────────────────────────────────────

  const indent = '   ';  // 3-space indent for alignment

  if (layout === 'narrow') {
    // Narrow: Just folder and date
    const metaStr = colorize(`${folder} | ${date}`, COLORS.gray, useColor);
    lines.push(`${indent}${metaStr}`);
  } else {
    // Normal/Wide: Full metadata line
    const parts = [];

    if (folder) {
      parts.push(`Folder: ${folder}`);
    }

    if (date) {
      parts.push(`Date: ${date}`);
    }

    if (tags.length > 0) {
      // Calculate available width for tags
      const metaPrefix = parts.join('  |  ');
      const tagsLabelWidth = 'Tags: '.length;
      const separatorWidth = parts.length > 0 ? '  |  '.length : 0;
      const usedWidth = indent.length + metaPrefix.length + separatorWidth + tagsLabelWidth;
      const tagsMaxWidth = terminalWidth - usedWidth - 2;

      const tagsStr = formatTags(tags, Math.max(15, tagsMaxWidth));
      if (tagsStr) {
        parts.push(`Tags: ${tagsStr}`);
      }
    }

    const metaLine = colorize(parts.join('  |  '), COLORS.gray, useColor);
    lines.push(`${indent}${metaLine}`);
  }

  // ─── LINE 3: Snippet Row (if enabled and not narrow) ──────────

  if (showSnippet && layout !== 'narrow' && result.snippet) {
    const snippetMaxWidth = terminalWidth - indent.length - 4;  // Account for quotes
    const snippet = truncateSnippet(result.snippet, snippetMaxWidth);
    const snippetStr = colorize(`"${snippet}"`, COLORS.gray, useColor);
    lines.push(`${indent}${snippetStr}`);
  }

  return lines.join('\n');
}

// ───────────────────────────────────────────────────────────────
// RESULTS PAGE FORMATTING
// ───────────────────────────────────────────────────────────────

/**
 * Format search results page with header and cards
 *
 * @param {Object[]} results - Array of search results
 * @param {string} query - Original search query
 * @param {Object} [options] - Formatting options
 * @param {number} [options.page=1] - Current page number
 * @param {number} [options.totalPages=1] - Total pages
 * @param {number} [options.totalResults] - Total result count
 * @param {number} [options.searchTime] - Search time in ms
 * @param {boolean} [options.useColor] - Enable color output
 * @param {number} [options.terminalWidth] - Terminal width
 * @param {number} [options.startRank=1] - Starting rank for pagination
 * @returns {string} Formatted results page
 */
function formatResultsPage(results, query, options = {}) {
  const {
    page = 1,
    totalPages = 1,
    totalResults = results.length,
    searchTime = null,
    useColor = supportsColor(),
    terminalWidth = getTerminalWidth(),
    startRank = 1
  } = options;

  const lines = [];

  // ─── HEADER ───────────────────────────────────────────────────

  const titleStr = colorize('Memory Search Results', COLORS.bold, useColor);
  lines.push(titleStr);
  lines.push(useColor ? colorize('='.repeat(21), COLORS.gray, useColor) : '=====================');
  lines.push('');

  // Query echo
  lines.push(`Query: "${query}"`);

  // Results count and folder spread
  const folderSet = new Set(results.map(r => r.spec_folder).filter(Boolean));
  const folderCount = folderSet.size;

  let countStr = `Found: ${totalResults} memor${totalResults === 1 ? 'y' : 'ies'}`;
  if (folderCount > 0) {
    countStr += ` across ${folderCount} spec folder${folderCount === 1 ? '' : 's'}`;
  }
  lines.push(countStr);

  // Search time
  if (searchTime !== null) {
    lines.push(`Time: ${(searchTime / 1000).toFixed(2)}s`);
  }

  // Page indicator
  if (totalPages > 1) {
    lines.push(`Page: ${page}/${totalPages}`);
  }

  lines.push('');

  // ─── RESULTS ──────────────────────────────────────────────────

  if (results.length === 0) {
    lines.push(formatEmptyResults(query, useColor));
  } else {
    results.forEach((result, index) => {
      const card = formatCard(result, {
        rank: startRank + index,
        useColor,
        terminalWidth
      });
      lines.push(card);
      lines.push('');  // Blank line between results
    });
  }

  // ─── FOOTER/ACTION BAR ────────────────────────────────────────

  lines.push(formatActionBar({ useColor, terminalWidth }));

  return lines.join('\n');
}

/**
 * Format empty results state
 *
 * @param {string} query - Search query
 * @param {boolean} [useColor] - Enable color
 * @returns {string} Empty state message
 */
function formatEmptyResults(query, useColor = supportsColor()) {
  const lines = [];

  lines.push('No memories match your search query.');
  lines.push('');
  lines.push(colorize('Suggestions:', COLORS.bold, useColor));
  lines.push('  - Try broader terms');
  lines.push('  - Check spelling and try again');
  lines.push('  - Use \'list\' to see all available memories');

  return lines.join('\n');
}

/**
 * Format empty index state
 *
 * @param {boolean} [useColor] - Enable color
 * @returns {string} Empty index message
 */
function formatEmptyIndex(useColor = supportsColor()) {
  const lines = [];

  lines.push(colorize('Memory Search', COLORS.bold, useColor));
  lines.push('=============');
  lines.push('');
  lines.push('No memories indexed yet.');
  lines.push('');
  lines.push('To start:');
  lines.push('  1. Save context in conversations: "save context"');
  lines.push('  2. Memories will be auto-indexed');
  lines.push('');
  lines.push('Actions: [q]uit');

  return lines.join('\n');
}

// ───────────────────────────────────────────────────────────────
// ACTION MENU FORMATTING
// ───────────────────────────────────────────────────────────────

/**
 * Format action bar (inline menu)
 *
 * @param {Object} [options] - Formatting options
 * @param {boolean} [options.useColor] - Enable color
 * @param {number} [options.terminalWidth] - Terminal width
 * @returns {string} Formatted action bar
 */
function formatActionBar(options = {}) {
  const {
    useColor = supportsColor(),
    terminalWidth = getTerminalWidth()
  } = options;

  const lines = [];

  // Separator line
  const separator = '-'.repeat(Math.min(69, terminalWidth - 2));
  lines.push(colorize(separator, COLORS.gray, useColor));

  // Action keys with underlined letters
  const formatKey = (key, label) => {
    if (useColor) {
      return `[${colorize(key, COLORS.underline, true)}]${label}`;
    }
    return `[${key}]${label}`;
  };

  const actions = [
    formatKey('v', 'iew #n'),
    formatKey('o', 'pen #n'),
    formatKey('l', 'oad #n'),
    formatKey('c', 'luster'),
    formatKey('f', 'ilter'),
    formatKey('?', ' help'),
    formatKey('q', 'uit')
  ];

  const actionsLine = `Actions: ${actions.join('  |  ')}`;
  lines.push(actionsLine);
  lines.push('Enter selection: ');

  return lines.join('\n');
}

/**
 * Format expanded help menu
 *
 * @param {Object} [options] - Formatting options
 * @param {boolean} [options.useColor] - Enable color
 * @returns {string} Formatted help menu
 */
function formatHelpMenu(options = {}) {
  const { useColor = supportsColor() } = options;

  const lines = [];

  lines.push(colorize('Available Actions', COLORS.bold, useColor));
  lines.push('=================');
  lines.push('');

  lines.push(colorize('Result Actions (require #n):', COLORS.bold, useColor));
  lines.push('  v #n, view #n      Preview memory content inline');
  lines.push('  o #n, open #n      Open memory file in $EDITOR');
  lines.push('  l #n, load #n      Load memory into conversation context');
  lines.push('  e #n, extract #n   Extract specific anchor section');
  lines.push('');

  lines.push(colorize('Navigation:', COLORS.bold, useColor));
  lines.push('  n, next            Show next page of results');
  lines.push('  p, prev            Show previous page');
  lines.push('  b, back            Return to previous view');
  lines.push('');

  lines.push(colorize('Filtering:', COLORS.bold, useColor));
  lines.push('  c, cluster         Group results by spec folder');
  lines.push('  f, filter          Narrow by tag or date range');
  lines.push('  s, sort            Change sort order (score/date/folder)');
  lines.push('');

  lines.push(colorize('Other:', COLORS.bold, useColor));
  lines.push('  ?, help            Show this menu');
  lines.push('  q, quit            Exit search mode');
  lines.push('');

  lines.push('Enter selection: ');

  return lines.join('\n');
}

// ───────────────────────────────────────────────────────────────
// PREVIEW FORMATTING
// ───────────────────────────────────────────────────────────────

/**
 * Format memory preview (detailed view)
 *
 * @param {Object} memory - Memory object with content
 * @param {Object} [options] - Formatting options
 * @param {boolean} [options.useColor] - Enable color
 * @param {number} [options.terminalWidth] - Terminal width
 * @returns {string} Formatted preview
 */
function formatPreview(memory, options = {}) {
  const {
    useColor = supportsColor(),
    terminalWidth = getTerminalWidth()
  } = options;

  const lines = [];
  const title = extractTitle(memory);

  // ─── HEADER ───────────────────────────────────────────────────

  lines.push(colorize(`Preview: ${title}`, COLORS.bold, useColor));
  lines.push(colorize('='.repeat(Math.min(title.length + 9, terminalWidth - 2)), COLORS.gray, useColor));
  lines.push('');

  // File info
  if (memory.file_path) {
    lines.push(colorize(`File: ${memory.file_path}`, COLORS.gray, useColor));
  }

  // Metadata line
  const metaParts = [];

  if (typeof memory.similarity === 'number') {
    metaParts.push(`Score: ${Math.round(memory.similarity)}% match`);
  }

  if (memory.created_at) {
    metaParts.push(`Created: ${formatDate(memory.created_at, true)}`);
  }

  if (memory.file_size) {
    const kb = (memory.file_size / 1024).toFixed(1);
    metaParts.push(`Size: ${kb} KB`);
  }

  if (metaParts.length > 0) {
    lines.push(colorize(metaParts.join('  |  '), COLORS.gray, useColor));
  }

  // Tags
  const tags = Array.isArray(memory.trigger_phrases) ? memory.trigger_phrases : [];
  if (tags.length > 0) {
    lines.push('');
    lines.push(`Tags: ${tags.join(', ')}`);
  }

  lines.push('');

  // ─── CONTENT SECTIONS ─────────────────────────────────────────

  // Summary section
  if (memory.summary || memory.snippet) {
    lines.push(colorize('Summary', COLORS.bold, useColor));
    lines.push('-------');
    lines.push(memory.summary || memory.snippet);
    lines.push('');
  }

  // Key decisions (if extracted)
  if (memory.decisions && memory.decisions.length > 0) {
    lines.push(colorize('Key Decisions', COLORS.bold, useColor));
    lines.push('-------------');
    memory.decisions.forEach(decision => {
      lines.push(`- ${decision}`);
    });
    lines.push('');
  }

  // Files modified (if extracted)
  if (memory.files_modified && memory.files_modified.length > 0) {
    lines.push(colorize('Files Modified', COLORS.bold, useColor));
    lines.push('--------------');
    memory.files_modified.forEach(file => {
      lines.push(`  ${file}`);
    });
    lines.push('');
  }

  // ─── PREVIEW ACTION BAR ───────────────────────────────────────

  const separator = '-'.repeat(Math.min(69, terminalWidth - 2));
  lines.push(colorize(separator, COLORS.gray, useColor));

  const formatKey = (key, label) => {
    if (useColor) {
      return `[${colorize(key, COLORS.underline, true)}]${label}`;
    }
    return `[${key}]${label}`;
  };

  const actions = [
    formatKey('o', 'pen file'),
    formatKey('l', 'oad'),
    formatKey('e', 'xtract section'),
    formatKey('b', 'ack to results')
  ];

  lines.push(`Actions: ${actions.join('  |  ')}`);
  lines.push('Enter selection: ');

  return lines.join('\n');
}

// ───────────────────────────────────────────────────────────────
// CLUSTERED RESULTS FORMATTING
// ───────────────────────────────────────────────────────────────

/**
 * Format clustered results (grouped by spec folder)
 *
 * @param {Object} clusters - Results grouped by folder { folder: results[] }
 * @param {Object} [options] - Formatting options
 * @param {string} [options.query] - Original query
 * @param {boolean} [options.useColor] - Enable color
 * @param {number} [options.terminalWidth] - Terminal width
 * @returns {string} Formatted clustered results
 */
function formatClusteredResults(clusters, options = {}) {
  const {
    query = '',
    useColor = supportsColor(),
    terminalWidth = getTerminalWidth()
  } = options;

  const lines = [];

  // ─── HEADER ───────────────────────────────────────────────────

  lines.push(colorize('Clustered Results by Spec Folder', COLORS.bold, useColor));
  lines.push('================================');
  lines.push('');

  if (query) {
    lines.push(`Query: "${query}"`);
  }

  // Count totals
  const folderNames = Object.keys(clusters);
  const totalResults = folderNames.reduce((sum, f) => sum + clusters[f].length, 0);
  lines.push(`Found: ${totalResults} memories in ${folderNames.length} clusters`);
  lines.push('');

  // ─── CLUSTERS ─────────────────────────────────────────────────

  // Sort folders by result count (descending)
  const sortedFolders = folderNames.sort((a, b) =>
    clusters[b].length - clusters[a].length
  );

  sortedFolders.forEach(folder => {
    const results = clusters[folder];
    const count = results.length;

    // Folder header
    const folderHeader = `--- ${folder} (${count} memor${count === 1 ? 'y' : 'ies'}) ---`;
    lines.push(colorize(folderHeader, COLORS.bold, useColor));
    lines.push('');

    // Compact 2-line cards within clusters
    results.forEach(result => {
      const card = formatCard(result, {
        rank: result.originalRank || result.rank || 1,
        useColor,
        terminalWidth,
        showSnippet: false  // Compact format - no snippet
      });
      lines.push(card);
      lines.push('');
    });
  });

  // ─── CLUSTER ACTION BAR ───────────────────────────────────────

  const separator = '-'.repeat(Math.min(69, terminalWidth - 2));
  lines.push(colorize(separator, COLORS.gray, useColor));

  const formatKey = (key, label) => {
    if (useColor) {
      return `[${colorize(key, COLORS.underline, true)}]${label}`;
    }
    return `[${key}]${label}`;
  };

  const actions = [
    formatKey('v', 'iew #n'),
    formatKey('u', 'ncluster'),
    formatKey('s', 'elect folder'),
    formatKey('q', 'uit')
  ];

  lines.push(`Actions: ${actions.join('  |  ')}`);
  lines.push('Enter selection: ');

  return lines.join('\n');
}

// ───────────────────────────────────────────────────────────────
// PROGRESS INDICATORS
// ───────────────────────────────────────────────────────────────

/**
 * Format search progress indicator
 *
 * @param {string} stage - Current stage
 * @param {number} [progress] - Progress percentage 0-100
 * @returns {string} Progress line
 */
function formatProgress(stage, progress = null) {
  if (progress !== null) {
    const barWidth = 20;
    const filled = Math.round((progress / 100) * barWidth);
    const empty = barWidth - filled;
    const bar = '='.repeat(filled) + '>' + ' '.repeat(Math.max(0, empty - 1));
    return `  ${stage}... [${bar}] ${progress}%`;
  }
  return `  ${stage}...`;
}

// ───────────────────────────────────────────────────────────────
// MINIMAL/PIPE FORMAT
// ───────────────────────────────────────────────────────────────

/**
 * Format results in minimal pipe-delimited format for scripting
 *
 * @param {Object[]} results - Search results
 * @returns {string} Pipe-delimited output, one result per line
 */
function formatMinimal(results) {
  return results.map(result => {
    const similarity = Math.round(result.similarity || 0);
    const folder = getShortFolderName(result.spec_folder);
    const filename = result.file_path ? path.basename(result.file_path) : '';
    const title = extractTitle(result);

    return `${similarity}|${folder}|${filename}|${title}`;
  }).join('\n');
}

// ───────────────────────────────────────────────────────────────
// LEGACY COMPATIBILITY
// ───────────────────────────────────────────────────────────────

/**
 * Truncate text to specified length with ellipsis (legacy)
 * @param {string} text - Text to truncate
 * @param {number} maxLength - Maximum length
 * @returns {string} - Truncated text
 * @deprecated Use truncateAtWord instead
 */
function truncate(text, maxLength) {
  if (!text || text.length <= maxLength) return text || '';
  return text.substring(0, maxLength - 3) + '...';
}

/**
 * Create a horizontal divider line
 * @param {number} [width] - Width of divider
 * @param {string} [char='-'] - Character to use
 * @returns {string} - Divider string
 */
function divider(width = 60, char = '-') {
  return char.repeat(width);
}

/**
 * Format a similarity score with visual indicator (legacy)
 * @param {number} score - Similarity score (0-100)
 * @returns {string} - Formatted score string
 * @deprecated Use getScoreColor and colorize instead
 */
function formatSimilarityScore(score) {
  const rounded = Math.round(score);
  const color = getScoreColor(rounded);
  return colorize(`${rounded}%`, color);
}

/**
 * Set color mode
 * @param {boolean} enabled - Whether to enable colors
 * @deprecated Set NO_COLOR or FORCE_COLOR environment variables instead
 */
function setColorMode(enabled) {
  // This is now handled via environment variables
  if (enabled) {
    delete process.env.NO_COLOR;
    process.env.FORCE_COLOR = '1';
  } else {
    process.env.NO_COLOR = '1';
    delete process.env.FORCE_COLOR;
  }
}

// ───────────────────────────────────────────────────────────────
// MODULE EXPORTS
// ───────────────────────────────────────────────────────────────

module.exports = {
  // Terminal detection
  getTerminalWidth,
  supportsColor,
  getLayoutMode,

  // Truncation helpers
  truncateAtWord,
  truncateSnippet,
  formatTags,

  // Date formatting
  formatDate,

  // Card formatting
  formatCard,
  extractTitle,

  // Page formatting
  formatResultsPage,
  formatEmptyResults,
  formatEmptyIndex,

  // Action menus
  formatActionBar,
  formatHelpMenu,

  // Preview
  formatPreview,

  // Clustering
  formatClusteredResults,

  // Progress
  formatProgress,

  // Minimal format
  formatMinimal,

  // Color helpers
  colorize,
  getScoreColor,

  // Legacy compatibility
  truncate,
  divider,
  formatSimilarityScore,
  setColorMode,

  // Constants
  COLORS,
  DEFAULTS
};
