#!/usr/bin/env node
/**
 * Interactive Search Module
 *
 * Implements the interactive search loop with state machine, action parsing,
 * and memory loading for the save-context skill.
 *
 * @module interactive-search
 * @version 1.0.0
 *
 * Tasks: T024-T026, T030-T031
 * User Stories: US9 (Quick Actions Menu), US10 (Load Selected Memory)
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

// ───────────────────────────────────────────────────────────────
// STATE MACHINE
// ───────────────────────────────────────────────────────────────

/**
 * Valid states for the interactive search state machine
 */
const States = {
  IDLE: 'IDLE',
  RESULTS: 'RESULTS',
  PREVIEW: 'PREVIEW',
  FILTERED: 'FILTERED',
  CLUSTERED: 'CLUSTERED',
  LOAD: 'LOAD',
  EXIT: 'EXIT'
};

/**
 * State transition map defining valid transitions
 */
const Transitions = {
  IDLE: { search: 'RESULTS' },
  RESULTS: {
    view: 'PREVIEW',
    filter: 'FILTERED',
    cluster: 'CLUSTERED',
    load: 'LOAD',
    quit: 'EXIT'
  },
  PREVIEW: {
    back: 'RESULTS',
    load: 'LOAD',
    open: 'PREVIEW'
  },
  FILTERED: {
    back: 'RESULTS',
    view: 'PREVIEW',
    clear: 'RESULTS',
    load: 'LOAD',
    quit: 'EXIT'
  },
  CLUSTERED: {
    back: 'RESULTS',
    view: 'PREVIEW',
    uncluster: 'RESULTS',
    load: 'LOAD',
    quit: 'EXIT'
  },
  LOAD: {
    done: 'EXIT',
    back: 'RESULTS'
  },
  EXIT: {}
};

// ───────────────────────────────────────────────────────────────
// ACTION TYPES
// ───────────────────────────────────────────────────────────────

/**
 * Action type enumeration
 */
const ActionTypes = {
  VIEW: 'view',
  OPEN: 'open',
  LOAD: 'load',
  CLUSTER: 'cluster',
  UNCLUSTER: 'uncluster',
  FILTER: 'filter',
  CLEAR: 'clear',
  NEXT: 'next',
  PREV: 'prev',
  BACK: 'back',
  HELP: 'help',
  QUIT: 'quit',
  SEARCH: 'search',
  INVALID: 'invalid'
};

// ───────────────────────────────────────────────────────────────
// ACTION PARSER (T026)
// ───────────────────────────────────────────────────────────────

/**
 * Regular expressions for parsing action commands
 */
const ACTION_PATTERNS = {
  // View: v#, v #, v#n, view #, view#
  view: /^v(?:iew)?\s*(\d+)$/i,

  // Open: o#, o #, open #, open#
  open: /^o(?:pen)?\s*(\d+)$/i,

  // Load: l#, l #, load #, load#
  load: /^l(?:oad)?\s*(\d+)$/i,

  // Cluster: c, cluster
  cluster: /^c(?:luster)?$/i,

  // Uncluster: u, uncluster
  uncluster: /^u(?:ncluster)?$/i,

  // Filter: f <filter>, filter <filter>
  filter: /^f(?:ilter)?\s+(.+)$/i,

  // Clear filters: clear
  clear: /^clear$/i,

  // Next page: n, next
  next: /^n(?:ext)?$/i,

  // Previous page: p, prev, previous
  prev: /^p(?:rev(?:ious)?)?$/i,

  // Back: b, back
  back: /^b(?:ack)?$/i,

  // Help: ?, help
  help: /^(\?|help)$/i,

  // Quit: q, quit, exit
  quit: /^(?:q(?:uit)?|exit)$/i
};

/**
 * Parse user input into an action object
 *
 * @param {string} input - Raw user input
 * @returns {Object} Parsed action with type, target, and params
 *
 * @example
 * parseAction('v1')      // { type: 'view', target: 1 }
 * parseAction('f folder:049') // { type: 'filter', params: { raw: 'folder:049' } }
 * parseAction('invalid') // { type: 'invalid', error: 'Unknown command' }
 */
function parseAction(input) {
  if (!input || typeof input !== 'string') {
    return {
      type: ActionTypes.INVALID,
      error: 'Empty input'
    };
  }

  const trimmed = input.trim();

  if (!trimmed) {
    return {
      type: ActionTypes.INVALID,
      error: 'Empty input'
    };
  }

  // Check each pattern
  for (const [actionType, pattern] of Object.entries(ACTION_PATTERNS)) {
    const match = trimmed.match(pattern);
    if (match) {
      const action = { type: actionType };

      // Extract target number for view/open/load
      if (['view', 'open', 'load'].includes(actionType)) {
        action.target = parseInt(match[1], 10);
        if (isNaN(action.target) || action.target < 1) {
          return {
            type: ActionTypes.INVALID,
            error: `Invalid result number: ${match[1]}. Use a positive integer.`
          };
        }
      }

      // Extract filter expression
      if (actionType === 'filter') {
        action.params = { raw: match[1] };
      }

      return action;
    }
  }

  // No pattern matched
  return {
    type: ActionTypes.INVALID,
    error: `Unknown command: "${trimmed}". Type ? for help.`
  };
}

/**
 * Parse filter expression into structured filter object
 *
 * Supported filter formats:
 * - folder:name or folder:049-auth
 * - date:>YYYY-MM-DD or date:<YYYY-MM-DD or date:YYYY-MM-DD..YYYY-MM-DD
 * - tag:name or tag:oauth
 *
 * @param {string} filterExpr - Raw filter expression
 * @returns {Object} Parsed filter object
 */
function parseFilter(filterExpr) {
  if (!filterExpr || typeof filterExpr !== 'string') {
    return { error: 'Empty filter expression' };
  }

  const filters = {};
  const parts = filterExpr.trim().split(/\s+/);

  for (const part of parts) {
    // Folder filter: folder:name
    const folderMatch = part.match(/^folder:(.+)$/i);
    if (folderMatch) {
      filters.folder = folderMatch[1];
      continue;
    }

    // Date filter: date:>YYYY-MM-DD, date:<YYYY-MM-DD, date:YYYY-MM-DD..YYYY-MM-DD
    const dateMatch = part.match(/^date:([<>]?)(\d{4}-\d{2}-\d{2})(?:\.\.(\d{4}-\d{2}-\d{2}))?$/i);
    if (dateMatch) {
      const [, operator, date1, date2] = dateMatch;
      if (operator === '>') {
        filters.dateFrom = date1;
      } else if (operator === '<') {
        filters.dateTo = date1;
      } else if (date2) {
        filters.dateFrom = date1;
        filters.dateTo = date2;
      } else {
        // Exact date
        filters.dateFrom = date1;
        filters.dateTo = date1;
      }
      continue;
    }

    // Tag filter: tag:name
    const tagMatch = part.match(/^tag:(.+)$/i);
    if (tagMatch) {
      filters.tags = filters.tags || [];
      filters.tags.push(tagMatch[1].toLowerCase());
      continue;
    }

    // If no known prefix, treat as a folder filter
    if (!part.includes(':')) {
      filters.folder = part;
    }
  }

  if (Object.keys(filters).length === 0) {
    return { error: `Invalid filter format: "${filterExpr}"` };
  }

  return filters;
}

// ───────────────────────────────────────────────────────────────
// STATE MACHINE CONTROLLER
// ───────────────────────────────────────────────────────────────

/**
 * Interactive search state machine controller
 */
class SearchStateMachine {
  /**
   * Create a new state machine
   * @param {Object} options - Configuration options
   */
  constructor(options = {}) {
    this.state = States.IDLE;
    this.results = [];
    this.filteredResults = null;
    this.clusteredResults = null;
    this.selectedResult = null;
    this.query = '';
    this.filters = {};
    this.pagination = {
      page: 1,
      pageSize: options.pageSize || 10,
      totalResults: 0
    };
    this.history = [];
    this.options = options;
  }

  /**
   * Get the current state
   * @returns {string} Current state
   */
  getState() {
    return this.state;
  }

  /**
   * Get current results based on state
   * @returns {Array} Current result set
   */
  getCurrentResults() {
    if (this.state === States.FILTERED && this.filteredResults) {
      return this.filteredResults;
    }
    if (this.state === States.CLUSTERED && this.clusteredResults) {
      return this.clusteredResults;
    }
    return this.results;
  }

  /**
   * Get paginated results for current page
   * @returns {Array} Results for current page
   */
  getPageResults() {
    const results = this.getCurrentResults();
    const { page, pageSize } = this.pagination;
    const start = (page - 1) * pageSize;
    const end = start + pageSize;
    return results.slice(start, end);
  }

  /**
   * Check if a transition is valid from current state
   * @param {string} action - Action type
   * @returns {boolean} True if transition is valid
   */
  canTransition(action) {
    const transitions = Transitions[this.state] || {};
    return action in transitions;
  }

  /**
   * Execute a state transition
   * @param {string} action - Action type
   * @returns {string|null} New state or null if invalid
   */
  transition(action) {
    const transitions = Transitions[this.state] || {};
    const newState = transitions[action];

    if (newState) {
      this.history.push(this.state);
      this.state = newState;
      return newState;
    }

    return null;
  }

  /**
   * Set search results after a query
   * @param {string} query - Search query
   * @param {Array} results - Search results
   */
  setResults(query, results) {
    this.query = query;
    this.results = results || [];
    this.filteredResults = null;
    this.clusteredResults = null;
    this.selectedResult = null;
    this.pagination.page = 1;
    this.pagination.totalResults = this.results.length;
    this.transition('search');
  }

  /**
   * Select a result by rank
   * @param {number} rank - 1-indexed rank
   * @returns {Object|null} Selected result or null
   */
  selectResult(rank) {
    const results = this.getCurrentResults();
    const index = rank - 1;

    if (index >= 0 && index < results.length) {
      this.selectedResult = results[index];
      return this.selectedResult;
    }

    return null;
  }

  /**
   * Apply a filter to results
   * @param {Object} filter - Filter object
   * @returns {Array} Filtered results
   */
  applyFilter(filter) {
    this.filters = { ...this.filters, ...filter };
    this.filteredResults = this.results.filter(result => {
      // Filter by folder
      if (filter.folder && result.specFolder) {
        if (!result.specFolder.toLowerCase().includes(filter.folder.toLowerCase())) {
          return false;
        }
      }

      // Filter by date range
      if (filter.dateFrom || filter.dateTo) {
        const resultDate = result.date ? new Date(result.date) : null;
        if (!resultDate) return false;

        if (filter.dateFrom && resultDate < new Date(filter.dateFrom)) {
          return false;
        }
        if (filter.dateTo && resultDate > new Date(filter.dateTo)) {
          return false;
        }
      }

      // Filter by tags
      if (filter.tags && filter.tags.length > 0) {
        const resultTags = (result.tags || []).map(t => t.toLowerCase());
        const hasAllTags = filter.tags.every(tag => resultTags.includes(tag));
        if (!hasAllTags) return false;
      }

      return true;
    });

    this.pagination.page = 1;
    this.pagination.totalResults = this.filteredResults.length;
    this.transition('filter');
    return this.filteredResults;
  }

  /**
   * Clear all filters and return to full results
   */
  clearFilters() {
    this.filters = {};
    this.filteredResults = null;
    this.pagination.page = 1;
    this.pagination.totalResults = this.results.length;
    this.transition('clear');
  }

  /**
   * Cluster results by spec folder
   * @returns {Object} Clustered results
   */
  cluster() {
    const clusters = {};
    for (const result of this.results) {
      const folder = result.specFolder || 'Unknown';
      if (!clusters[folder]) {
        clusters[folder] = [];
      }
      clusters[folder].push(result);
    }

    this.clusteredResults = clusters;
    this.transition('cluster');
    return clusters;
  }

  /**
   * Uncluster results (return to flat view)
   */
  uncluster() {
    this.clusteredResults = null;
    this.transition('uncluster');
  }

  /**
   * Navigate to next page
   * @returns {boolean} True if successful
   */
  nextPage() {
    const results = this.getCurrentResults();
    const totalPages = Math.ceil(results.length / this.pagination.pageSize);

    if (this.pagination.page < totalPages) {
      this.pagination.page++;
      return true;
    }
    return false;
  }

  /**
   * Navigate to previous page
   * @returns {boolean} True if successful
   */
  prevPage() {
    if (this.pagination.page > 1) {
      this.pagination.page--;
      return true;
    }
    return false;
  }

  /**
   * Get pagination info
   * @returns {Object} Pagination details
   */
  getPaginationInfo() {
    const results = this.getCurrentResults();
    const totalPages = Math.ceil(results.length / this.pagination.pageSize);
    return {
      page: this.pagination.page,
      totalPages,
      totalResults: results.length,
      hasNext: this.pagination.page < totalPages,
      hasPrev: this.pagination.page > 1
    };
  }

  /**
   * Go back to previous state
   */
  back() {
    if (this.history.length > 0) {
      this.state = this.history.pop();
    }
  }

  /**
   * Reset the state machine
   */
  reset() {
    this.state = States.IDLE;
    this.results = [];
    this.filteredResults = null;
    this.clusteredResults = null;
    this.selectedResult = null;
    this.query = '';
    this.filters = {};
    this.pagination = {
      page: 1,
      pageSize: this.pagination.pageSize,
      totalResults: 0
    };
    this.history = [];
  }

  /**
   * Serialize state for session persistence
   * @returns {Object} Serializable state object
   */
  serialize() {
    return {
      state: this.state,
      query: this.query,
      results: this.results,
      filters: this.filters,
      pagination: this.pagination,
      selectedResult: this.selectedResult
    };
  }

  /**
   * Restore state from serialized data
   * @param {Object} data - Serialized state
   */
  restore(data) {
    if (!data) return;
    this.state = data.state || States.IDLE;
    this.query = data.query || '';
    this.results = data.results || [];
    this.filters = data.filters || {};
    this.pagination = data.pagination || this.pagination;
    this.selectedResult = data.selectedResult || null;

    // Reapply filters if present
    if (Object.keys(this.filters).length > 0) {
      this.applyFilter(this.filters);
    }
  }
}

// ───────────────────────────────────────────────────────────────
// ACTION BAR FORMATTER (T024)
// ───────────────────────────────────────────────────────────────

/**
 * Format the action bar for the current state
 *
 * @param {string} state - Current state
 * @param {Object} options - Formatting options
 * @returns {string} Formatted action bar
 */
function formatActionBar(state, options = {}) {
  const separator = '  |  ';
  const useColor = options.color !== false && !process.env.NO_COLOR;

  // Action formatting helper
  const fmt = (key, label) => {
    if (useColor) {
      return `[\x1b[4m${key}\x1b[0m]${label}`;
    }
    return `[${key}]${label}`;
  };

  let actions = [];

  switch (state) {
    case States.RESULTS:
    case States.FILTERED:
    case States.CLUSTERED:
      actions = [
        fmt('v', 'iew #n'),
        fmt('o', 'pen #n'),
        fmt('l', 'oad #n')
      ];

      if (state === States.RESULTS) {
        actions.push(fmt('c', 'luster'));
        actions.push(fmt('f', 'ilter'));
      } else if (state === States.FILTERED) {
        actions.push('clear');
      } else if (state === States.CLUSTERED) {
        actions.push(fmt('u', 'ncluster'));
      }

      actions.push(fmt('?', ' help'));
      actions.push(fmt('q', 'uit'));
      break;

    case States.PREVIEW:
      actions = [
        fmt('o', 'pen file'),
        fmt('l', 'oad'),
        fmt('b', 'ack to results'),
        fmt('?', ' help')
      ];
      break;

    case States.LOAD:
      actions = [
        fmt('b', 'ack'),
        fmt('q', 'uit')
      ];
      break;

    default:
      actions = [fmt('?', ' help'), fmt('q', 'uit')];
  }

  const line = '-'.repeat(69);
  const bar = `${line}\nActions: ${actions.join(separator)}`;
  return bar;
}

// ───────────────────────────────────────────────────────────────
// HELP MENU FORMATTER (T025)
// ───────────────────────────────────────────────────────────────

/**
 * Format the expanded help menu
 *
 * @param {string} state - Current state
 * @returns {string} Formatted help menu
 */
function formatHelpMenu(state) {
  const lines = [
    '',
    'Available Actions',
    '=================',
    ''
  ];

  // Result actions (when results are available)
  if ([States.RESULTS, States.FILTERED, States.CLUSTERED].includes(state)) {
    lines.push('Result Actions (require #n):');
    lines.push('  v #n, view #n      Preview memory content inline');
    lines.push('  o #n, open #n      Open memory file in $EDITOR');
    lines.push('  l #n, load #n      Load memory into conversation context');
    lines.push('');
  }

  // Preview actions
  if (state === States.PREVIEW) {
    lines.push('Preview Actions:');
    lines.push('  o, open            Open memory file in $EDITOR');
    lines.push('  l, load            Load this memory into context');
    lines.push('  b, back            Return to results list');
    lines.push('');
  }

  // Navigation
  lines.push('Navigation:');
  lines.push('  n, next            Show next page of results');
  lines.push('  p, prev            Show previous page');
  lines.push('  b, back            Return to previous view');
  lines.push('');

  // Filtering (when in results)
  if ([States.RESULTS, States.FILTERED].includes(state)) {
    lines.push('Filtering:');
    lines.push('  c, cluster         Group results by spec folder');
    lines.push('  f folder:NAME      Filter by spec folder');
    lines.push('  f date:>YYYY-MM-DD Filter by date (after)');
    lines.push('  f date:<YYYY-MM-DD Filter by date (before)');
    lines.push('  f tag:NAME         Filter by tag');
    lines.push('  clear              Remove all filters');
    lines.push('');
  }

  // Clustering (when clustered)
  if (state === States.CLUSTERED) {
    lines.push('Clustering:');
    lines.push('  u, uncluster       Return to flat list view');
    lines.push('');
  }

  // General
  lines.push('Other:');
  lines.push('  ?, help            Show this menu');
  lines.push('  q, quit            Exit search mode');
  lines.push('');

  return lines.join('\n');
}

// ───────────────────────────────────────────────────────────────
// LOAD MEMORY FUNCTION (T030-T031)
// ───────────────────────────────────────────────────────────────

/**
 * Load a memory file and output to stdout for the AI agent to consume
 *
 * @param {string} filePath - Path to the memory file
 * @param {Object} options - Load options
 * @returns {Promise<Object>} Result with success status and content
 */
async function loadMemory(filePath, options = {}) {
  try {
    // Validate file path
    if (!filePath || typeof filePath !== 'string') {
      return {
        success: false,
        error: 'Invalid file path'
      };
    }

    // Resolve to absolute path
    const absolutePath = path.isAbsolute(filePath) ? filePath : path.resolve(filePath);

    // Check if file exists
    if (!fs.existsSync(absolutePath)) {
      return {
        success: false,
        error: `Memory file not found: ${absolutePath}`
      };
    }

    // Read the memory file
    const content = fs.readFileSync(absolutePath, 'utf-8');

    if (!content || content.trim().length === 0) {
      return {
        success: false,
        error: 'Memory file is empty'
      };
    }

    // Extract metadata from filename if available
    const filename = path.basename(filePath, '.md');
    const folderName = path.basename(path.dirname(filePath));

    // Format as context injection
    const contextHeader = formatContextHeader(filename, absolutePath, options);
    const formattedContent = formatMemoryContent(content, options);
    const contextFooter = formatContextFooter(filename);

    // Full context output
    const fullContext = [
      contextHeader,
      '',
      formattedContent,
      '',
      contextFooter
    ].join('\n');

    // Output to stdout for the AI agent to consume
    if (options.output !== false) {
      process.stdout.write(fullContext);
      process.stdout.write('\n');
    }

    return {
      success: true,
      content: fullContext,
      path: absolutePath,
      size: content.length
    };
  } catch (error) {
    return {
      success: false,
      error: `Failed to load memory: ${error.message}`
    };
  }
}

/**
 * Format the context header for loaded memory
 *
 * @param {string} filename - Memory filename
 * @param {string} filePath - Full file path
 * @param {Object} options - Format options
 * @returns {string} Formatted header
 */
function formatContextHeader(filename, filePath, options = {}) {
  const lines = [];
  const divider = '='.repeat(69);

  lines.push(divider);
  lines.push(`LOADED MEMORY: ${filename}`);
  lines.push(divider);
  lines.push(`Source: ${filePath}`);
  lines.push(`Loaded: ${new Date().toISOString()}`);

  if (options.query) {
    lines.push(`Query: "${options.query}"`);
  }

  if (options.similarity !== undefined) {
    lines.push(`Similarity: ${(options.similarity * 100).toFixed(1)}%`);
  }

  lines.push(divider);

  return lines.join('\n');
}

/**
 * Format memory content for context injection
 *
 * @param {string} content - Raw memory content
 * @param {Object} options - Format options
 * @returns {string} Formatted content
 */
function formatMemoryContent(content, options = {}) {
  // If extracting specific anchor, filter content
  if (options.anchor) {
    const extracted = extractAnchor(content, options.anchor);
    if (extracted) {
      return extracted;
    }
  }

  // Return full content by default
  return content;
}

/**
 * Extract a specific anchor section from markdown content
 *
 * @param {string} content - Full markdown content
 * @param {string} anchorId - Anchor ID to extract
 * @returns {string|null} Extracted section or null
 */
function extractAnchor(content, anchorId) {
  const lines = content.split('\n');
  const anchorPattern = new RegExp(`^#+\\s*.*?\\{#${anchorId}\\}`, 'i');
  const headerPattern = /^(#{1,6})\s+/;

  let inSection = false;
  let sectionLevel = 0;
  const sectionLines = [];

  for (const line of lines) {
    if (!inSection) {
      // Look for anchor start
      if (anchorPattern.test(line)) {
        inSection = true;
        const match = line.match(headerPattern);
        sectionLevel = match ? match[1].length : 1;
        sectionLines.push(line);
      }
    } else {
      // Check if we've hit a same-level or higher header
      const match = line.match(headerPattern);
      if (match && match[1].length <= sectionLevel) {
        break;
      }
      sectionLines.push(line);
    }
  }

  if (sectionLines.length === 0) {
    return null;
  }

  return sectionLines.join('\n');
}

/**
 * Format the context footer for loaded memory
 *
 * @param {string} filename - Memory filename
 * @returns {string} Formatted footer
 */
function formatContextFooter(filename) {
  const divider = '='.repeat(69);
  return `${divider}\nEND MEMORY: ${filename}\n${divider}`;
}

/**
 * Open a file in the user's preferred editor
 *
 * @param {string} filePath - Path to file
 * @returns {Promise<boolean>} True if successful
 */
async function openInEditor(filePath) {
  return new Promise((resolve) => {
    const editor = process.env.EDITOR || process.env.VISUAL || 'code';
    const absolutePath = path.isAbsolute(filePath) ? filePath : path.resolve(filePath);

    if (!fs.existsSync(absolutePath)) {
      console.error(`File not found: ${absolutePath}`);
      resolve(false);
      return;
    }

    const child = spawn(editor, [absolutePath], {
      detached: true,
      stdio: 'ignore'
    });

    child.on('error', (error) => {
      console.error(`Failed to open editor: ${error.message}`);
      resolve(false);
    });

    child.unref();
    resolve(true);
  });
}

// ───────────────────────────────────────────────────────────────
// ACTION EXECUTOR
// ───────────────────────────────────────────────────────────────

/**
 * Execute an action and update state
 *
 * @param {SearchStateMachine} machine - State machine instance
 * @param {Object} action - Parsed action
 * @param {Object} context - Execution context
 * @returns {Promise<Object>} Execution result
 */
async function executeAction(machine, action, context = {}) {
  const result = {
    success: false,
    message: '',
    output: null,
    newState: machine.getState()
  };

  switch (action.type) {
    case ActionTypes.VIEW: {
      const selected = machine.selectResult(action.target);
      if (!selected) {
        result.message = `No result #${action.target}. Results: 1-${machine.getCurrentResults().length}`;
      } else {
        machine.transition('view');
        result.success = true;
        result.output = selected;
        result.newState = machine.getState();
        result.message = `Viewing memory #${action.target}`;
      }
      break;
    }

    case ActionTypes.OPEN: {
      const results = machine.getCurrentResults();
      const index = action.target - 1;
      if (index < 0 || index >= results.length) {
        result.message = `No result #${action.target}. Results: 1-${results.length}`;
      } else {
        const selected = results[index];
        const opened = await openInEditor(selected.filePath);
        result.success = opened;
        result.message = opened
          ? `Opened in editor: ${path.basename(selected.filePath)}`
          : 'Failed to open editor';
      }
      break;
    }

    case ActionTypes.LOAD: {
      const results = machine.getCurrentResults();
      const index = action.target - 1;
      if (index < 0 || index >= results.length) {
        result.message = `No result #${action.target}. Results: 1-${results.length}`;
      } else {
        const selected = results[index];
        machine.transition('load');
        const loadResult = await loadMemory(selected.filePath, {
          query: machine.query,
          similarity: selected.similarity,
          output: context.output !== false
        });
        result.success = loadResult.success;
        result.message = loadResult.success
          ? `Loaded memory: ${path.basename(selected.filePath)}`
          : loadResult.error;
        result.output = loadResult;
        result.newState = machine.getState();
      }
      break;
    }

    case ActionTypes.CLUSTER: {
      if (!machine.canTransition('cluster')) {
        result.message = 'Cannot cluster from current state';
      } else {
        const clusters = machine.cluster();
        result.success = true;
        result.output = clusters;
        result.newState = machine.getState();
        result.message = `Grouped into ${Object.keys(clusters).length} folders`;
      }
      break;
    }

    case ActionTypes.UNCLUSTER: {
      if (!machine.canTransition('uncluster')) {
        result.message = 'Cannot uncluster from current state';
      } else {
        machine.uncluster();
        result.success = true;
        result.newState = machine.getState();
        result.message = 'Returned to flat list';
      }
      break;
    }

    case ActionTypes.FILTER: {
      const filter = parseFilter(action.params.raw);
      if (filter.error) {
        result.message = filter.error;
      } else {
        const filtered = machine.applyFilter(filter);
        result.success = true;
        result.output = filtered;
        result.newState = machine.getState();
        result.message = `Filtered to ${filtered.length} results`;
      }
      break;
    }

    case ActionTypes.CLEAR: {
      machine.clearFilters();
      result.success = true;
      result.newState = machine.getState();
      result.message = 'Filters cleared';
      break;
    }

    case ActionTypes.NEXT: {
      const moved = machine.nextPage();
      result.success = moved;
      const info = machine.getPaginationInfo();
      result.message = moved
        ? `Page ${info.page} of ${info.totalPages}`
        : 'No more results';
      break;
    }

    case ActionTypes.PREV: {
      const moved = machine.prevPage();
      result.success = moved;
      const info = machine.getPaginationInfo();
      result.message = moved
        ? `Page ${info.page} of ${info.totalPages}`
        : 'Already at first page';
      break;
    }

    case ActionTypes.BACK: {
      machine.back();
      result.success = true;
      result.newState = machine.getState();
      result.message = 'Returned to previous view';
      break;
    }

    case ActionTypes.HELP: {
      result.success = true;
      result.output = formatHelpMenu(machine.getState());
      result.message = '';
      break;
    }

    case ActionTypes.QUIT: {
      machine.transition('quit');
      result.success = true;
      result.newState = States.EXIT;
      result.message = 'Search session ended';
      break;
    }

    case ActionTypes.INVALID: {
      result.message = action.error || 'Invalid command';
      break;
    }

    default:
      result.message = `Unknown action type: ${action.type}`;
  }

  return result;
}

// ───────────────────────────────────────────────────────────────
// EXPORTS
// ───────────────────────────────────────────────────────────────

module.exports = {
  // State constants
  States,
  Transitions,
  ActionTypes,

  // Action parsing
  parseAction,
  parseFilter,

  // State machine
  SearchStateMachine,

  // Formatters
  formatActionBar,
  formatHelpMenu,

  // Memory loading
  loadMemory,
  openInEditor,
  extractAnchor,

  // Action execution
  executeAction
};
