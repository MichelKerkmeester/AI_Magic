#!/usr/bin/env node

/**
 * Pagination Module for Interactive Memory Search
 *
 * Provides pagination state management and navigation for search results.
 * Supports page-based navigation, edge case handling, and formatted display.
 *
 * @module pagination
 * @version 1.0.0
 * @see specs/015-interactive-memory-search/spec.md - US6 Pagination
 */

'use strict';

// ───────────────────────────────────────────────────────────────
// CONFIGURATION
// ───────────────────────────────────────────────────────────────

const DEFAULT_PAGE_SIZE = 10;

// ───────────────────────────────────────────────────────────────
// PAGINATION STATE FACTORY
// ───────────────────────────────────────────────────────────────

/**
 * Create a new pagination state object
 * @returns {Object} Fresh pagination state
 */
function createPaginationState() {
  return {
    page: 1,           // Current page (1-indexed)
    pageSize: DEFAULT_PAGE_SIZE,
    totalResults: 0,
    totalPages: 0
  };
}

// ───────────────────────────────────────────────────────────────
// CORE PAGINATION FUNCTIONS
// ───────────────────────────────────────────────────────────────

/**
 * Initialize pagination for a results array
 *
 * @param {Array} results - Full results array
 * @param {number} [pageSize=10] - Items per page
 * @returns {Object} Initialized pagination state
 *
 * @example
 * const pagination = initPagination(searchResults, 10);
 * // { page: 1, pageSize: 10, totalResults: 25, totalPages: 3 }
 */
function initPagination(results, pageSize = DEFAULT_PAGE_SIZE) {
  if (!Array.isArray(results)) {
    return {
      page: 1,
      pageSize: pageSize,
      totalResults: 0,
      totalPages: 0
    };
  }

  const totalResults = results.length;
  const totalPages = Math.max(1, Math.ceil(totalResults / pageSize));

  return {
    page: 1,
    pageSize: pageSize,
    totalResults: totalResults,
    totalPages: totalPages
  };
}

/**
 * Get results slice for current page
 *
 * @param {Array} results - Full results array
 * @param {Object} pagination - Pagination state
 * @returns {Array} Slice of results for current page
 *
 * @example
 * const pageResults = getPage(allResults, pagination);
 * // Returns items 0-9 for page 1, 10-19 for page 2, etc.
 */
function getPage(results, pagination) {
  if (!Array.isArray(results) || !pagination) {
    return [];
  }

  const { page, pageSize } = pagination;
  const startIndex = (page - 1) * pageSize;
  const endIndex = startIndex + pageSize;

  return results.slice(startIndex, endIndex);
}

/**
 * Go to next page
 *
 * @param {Object} pagination - Current pagination state
 * @returns {Object|null} Updated state with incremented page, or null if at last page
 *
 * @example
 * const newState = nextPage(pagination);
 * if (newState === null) {
 *   console.log('No more results');
 * }
 */
function nextPage(pagination) {
  if (!pagination) {
    return null;
  }

  const { page, totalPages } = pagination;

  // Already at last page
  if (page >= totalPages) {
    return null;
  }

  return {
    ...pagination,
    page: page + 1
  };
}

/**
 * Go to previous page
 *
 * @param {Object} pagination - Current pagination state
 * @returns {Object|null} Updated state with decremented page, or null if at first page
 *
 * @example
 * const newState = prevPage(pagination);
 * if (newState === null) {
 *   console.log('Already on first page');
 * }
 */
function prevPage(pagination) {
  if (!pagination) {
    return null;
  }

  const { page } = pagination;

  // Already at first page
  if (page <= 1) {
    return null;
  }

  return {
    ...pagination,
    page: page - 1
  };
}

/**
 * Go to a specific page
 *
 * @param {Object} pagination - Current pagination state
 * @param {number} pageNum - Target page number (1-indexed)
 * @returns {Object|null} Updated state with new page, or null if invalid page
 *
 * @example
 * const newState = goToPage(pagination, 3);
 * if (newState === null) {
 *   console.log('Invalid page number');
 * }
 */
function goToPage(pagination, pageNum) {
  if (!pagination) {
    return null;
  }

  const { totalPages } = pagination;

  // Validate page number
  if (typeof pageNum !== 'number' || !Number.isInteger(pageNum)) {
    return null;
  }

  if (pageNum < 1 || pageNum > totalPages) {
    return null;
  }

  return {
    ...pagination,
    page: pageNum
  };
}

// ───────────────────────────────────────────────────────────────
// DISPLAY FORMATTING
// ───────────────────────────────────────────────────────────────

/**
 * Format page indicator for display in header
 *
 * @param {Object} pagination - Pagination state
 * @returns {string} Formatted indicator, e.g., "Page 1/3 (25 results)"
 *
 * @example
 * formatPageIndicator(pagination);
 * // "Page 1/3 (25 results)"
 */
function formatPageIndicator(pagination) {
  if (!pagination) {
    return '';
  }

  const { page, totalPages, totalResults } = pagination;

  // Handle empty results
  if (totalResults === 0) {
    return 'No results';
  }

  // Handle single page (no pagination needed)
  if (totalPages === 1) {
    const resultWord = totalResults === 1 ? 'result' : 'results';
    return `${totalResults} ${resultWord}`;
  }

  // Multi-page format
  const resultWord = totalResults === 1 ? 'result' : 'results';
  return `Page ${page}/${totalPages} (${totalResults} ${resultWord})`;
}

/**
 * Format detailed page range for footer
 *
 * @param {Object} pagination - Pagination state
 * @returns {string} Formatted range, e.g., "[Page 1 of 3 - showing 1-10 of 25 results]"
 *
 * @example
 * formatPageRange(pagination);
 * // "[Page 1 of 3 - showing 1-10 of 25 results]"
 */
function formatPageRange(pagination) {
  if (!pagination) {
    return '';
  }

  const { page, pageSize, totalPages, totalResults } = pagination;

  // Handle empty results
  if (totalResults === 0) {
    return '';
  }

  // Handle single page
  if (totalPages === 1) {
    return '';
  }

  // Calculate range
  const startItem = (page - 1) * pageSize + 1;
  const endItem = Math.min(page * pageSize, totalResults);

  return `[Page ${page} of ${totalPages} - showing ${startItem}-${endItem} of ${totalResults} results]`;
}

// ───────────────────────────────────────────────────────────────
// NAVIGATION STATE
// ───────────────────────────────────────────────────────────────

/**
 * Get navigation availability state
 *
 * @param {Object} pagination - Pagination state
 * @returns {Object} Navigation state: { canNext: boolean, canPrev: boolean }
 *
 * @example
 * const nav = getNavigationState(pagination);
 * if (nav.canNext) {
 *   // Show next button
 * }
 */
function getNavigationState(pagination) {
  if (!pagination) {
    return {
      canNext: false,
      canPrev: false
    };
  }

  const { page, totalPages } = pagination;

  return {
    canNext: page < totalPages,
    canPrev: page > 1
  };
}

/**
 * Check if pagination is needed (more than one page)
 *
 * @param {Object} pagination - Pagination state
 * @returns {boolean} True if multiple pages exist
 */
function needsPagination(pagination) {
  if (!pagination) {
    return false;
  }

  return pagination.totalPages > 1;
}

/**
 * Check if currently on first page
 *
 * @param {Object} pagination - Pagination state
 * @returns {boolean} True if on first page
 */
function isFirstPage(pagination) {
  if (!pagination) {
    return true;
  }

  return pagination.page === 1;
}

/**
 * Check if currently on last page
 *
 * @param {Object} pagination - Pagination state
 * @returns {boolean} True if on last page
 */
function isLastPage(pagination) {
  if (!pagination) {
    return true;
  }

  return pagination.page >= pagination.totalPages;
}

// ───────────────────────────────────────────────────────────────
// EDGE CASE MESSAGES
// ───────────────────────────────────────────────────────────────

/**
 * Get appropriate message for navigation edge cases
 *
 * @param {string} action - The navigation action attempted ('next' or 'prev')
 * @param {Object} pagination - Pagination state
 * @returns {string|null} Error message if at boundary, null otherwise
 *
 * @example
 * const msg = getEdgeCaseMessage('prev', pagination);
 * if (msg) {
 *   console.log(msg); // "Already on first page"
 * }
 */
function getEdgeCaseMessage(action, pagination) {
  if (!pagination) {
    return 'No active search results';
  }

  const nav = getNavigationState(pagination);

  if (action === 'next' && !nav.canNext) {
    return 'No more results';
  }

  if (action === 'prev' && !nav.canPrev) {
    return 'Already on first page';
  }

  return null;
}

/**
 * Format action bar hint based on pagination state
 *
 * @param {Object} pagination - Pagination state
 * @returns {string} Action hints for available navigation
 *
 * @example
 * formatPaginationHints(pagination);
 * // "[n]ext page | [p]rev page" or "[n]ext page" or "[p]rev page" or ""
 */
function formatPaginationHints(pagination) {
  const nav = getNavigationState(pagination);
  const hints = [];

  if (nav.canNext) {
    hints.push('[n]ext page');
  }

  if (nav.canPrev) {
    hints.push('[p]rev page');
  }

  return hints.join(' | ');
}

// ───────────────────────────────────────────────────────────────
// SESSION INTEGRATION
// ───────────────────────────────────────────────────────────────

/**
 * Serialize pagination state for session storage
 *
 * @param {Object} pagination - Pagination state
 * @returns {Object} Serializable pagination object
 */
function serializePagination(pagination) {
  if (!pagination) {
    return null;
  }

  return {
    page: pagination.page,
    pageSize: pagination.pageSize,
    totalResults: pagination.totalResults,
    totalPages: pagination.totalPages
  };
}

/**
 * Restore pagination state from session data
 *
 * @param {Object} data - Serialized pagination data
 * @returns {Object|null} Restored pagination state or null if invalid
 */
function deserializePagination(data) {
  if (!data || typeof data !== 'object') {
    return null;
  }

  // Validate required fields
  const requiredFields = ['page', 'pageSize', 'totalResults', 'totalPages'];
  for (const field of requiredFields) {
    if (typeof data[field] !== 'number') {
      return null;
    }
  }

  return {
    page: data.page,
    pageSize: data.pageSize,
    totalResults: data.totalResults,
    totalPages: data.totalPages
  };
}

/**
 * Recalculate pagination when results change (e.g., after filtering)
 *
 * @param {Object} pagination - Current pagination state
 * @param {Array} newResults - New results array
 * @returns {Object} Updated pagination state, reset to page 1
 */
function recalculatePagination(pagination, newResults) {
  const pageSize = pagination?.pageSize || DEFAULT_PAGE_SIZE;
  return initPagination(newResults, pageSize);
}

// ───────────────────────────────────────────────────────────────
// MODULE EXPORTS
// ───────────────────────────────────────────────────────────────

module.exports = {
  // Constants
  DEFAULT_PAGE_SIZE,

  // Factory
  createPaginationState,

  // Core functions
  initPagination,
  getPage,
  nextPage,
  prevPage,
  goToPage,

  // Display formatting
  formatPageIndicator,
  formatPageRange,
  formatPaginationHints,

  // Navigation state
  getNavigationState,
  needsPagination,
  isFirstPage,
  isLastPage,

  // Edge cases
  getEdgeCaseMessage,

  // Session integration
  serializePagination,
  deserializePagination,
  recalculatePagination
};
