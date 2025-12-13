#!/usr/bin/env node

/**
 * Filter & Cluster Module for Interactive Memory Search
 *
 * Provides filtering and clustering functionality for search results:
 * - Filter parser for folder, date, and tag filters
 * - Filter application with AND logic
 * - Clustering by spec folder
 * - Clustered format display
 *
 * Tasks: T041-T044 (US4: Result Filtering), T048-T051 (US5: Result Clustering)
 *
 * @module filter-cluster
 * @version 1.0.0
 */

'use strict';

const path = require('path');

// ───────────────────────────────────────────────────────────────
// CONSTANTS
// ───────────────────────────────────────────────────────────────

/**
 * Filter syntax patterns
 * Supported syntaxes:
 *   folder:049-auth      - Filter by spec folder (partial match)
 *   date:>2025-12-01     - Filter by date (after)
 *   date:<2025-12-01     - Filter by date (before)
 *   date:2025-12-01..2025-12-07  - Date range
 *   tag:oauth            - Filter by tag
 */
const FILTER_PATTERNS = {
  folder: /^folder:(.+)$/i,
  dateAfter: /^date:>(\d{4}-\d{2}-\d{2})$/i,
  dateBefore: /^date:<(\d{4}-\d{2}-\d{2})$/i,
  dateRange: /^date:(\d{4}-\d{2}-\d{2})\.\.(\d{4}-\d{2}-\d{2})$/i,
  tag: /^tag:(.+)$/i
};

// ───────────────────────────────────────────────────────────────
// FILTER PARSING (T041)
// ───────────────────────────────────────────────────────────────

/**
 * Parse filter string into filter object
 *
 * Supports multiple filters combined with spaces (AND logic):
 *   "folder:auth tag:jwt" - matches entries in auth folder with jwt tag
 *
 * @param {string} filterStr - Filter string, e.g., "folder:auth tag:jwt"
 * @returns {Object} Parsed filter object
 * @returns {string|null} returns.folder - Folder partial match string
 * @returns {Date|null} returns.dateFrom - Filter date (inclusive)
 * @returns {Date|null} returns.dateTo - Filter end date (inclusive)
 * @returns {string[]} returns.tags - Array of tag filters
 *
 * @example
 * parseFilter("folder:auth tag:jwt")
 * // => { folder: "auth", dateFrom: null, dateTo: null, tags: ["jwt"] }
 *
 * @example
 * parseFilter("date:2025-12-01..2025-12-07")
 * // => { folder: null, dateFrom: Date, dateTo: Date, tags: [] }
 */
function parseFilter(filterStr) {
  const result = {
    folder: null,
    dateFrom: null,
    dateTo: null,
    tags: []
  };

  if (!filterStr || typeof filterStr !== 'string') {
    return result;
  }

  // Normalize and split by whitespace
  const parts = filterStr.trim().split(/\s+/);

  for (const part of parts) {
    // Skip empty parts
    if (!part) continue;

    // Check folder filter
    const folderMatch = part.match(FILTER_PATTERNS.folder);
    if (folderMatch) {
      result.folder = folderMatch[1].toLowerCase();
      continue;
    }

    // Check date range (must check before single date operators)
    const dateRangeMatch = part.match(FILTER_PATTERNS.dateRange);
    if (dateRangeMatch) {
      result.dateFrom = parseDate(dateRangeMatch[1]);
      result.dateTo = parseDate(dateRangeMatch[2], true); // End of day
      continue;
    }

    // Check date after
    const dateAfterMatch = part.match(FILTER_PATTERNS.dateAfter);
    if (dateAfterMatch) {
      result.dateFrom = parseDate(dateAfterMatch[1]);
      continue;
    }

    // Check date before
    const dateBeforeMatch = part.match(FILTER_PATTERNS.dateBefore);
    if (dateBeforeMatch) {
      result.dateTo = parseDate(dateBeforeMatch[1], true); // End of day
      continue;
    }

    // Check tag filter
    const tagMatch = part.match(FILTER_PATTERNS.tag);
    if (tagMatch) {
      result.tags.push(tagMatch[1].toLowerCase());
      continue;
    }

    // Unknown filter syntax - ignore with warning (could log in debug mode)
  }

  return result;
}

/**
 * Parse date string to Date object
 * @param {string} dateStr - Date in YYYY-MM-DD format
 * @param {boolean} [endOfDay=false] - If true, set time to end of day
 * @returns {Date|null} Parsed date or null if invalid
 */
function parseDate(dateStr, endOfDay = false) {
  if (!dateStr) return null;

  const match = dateStr.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (!match) return null;

  const year = parseInt(match[1], 10);
  const month = parseInt(match[2], 10) - 1; // JS months are 0-indexed
  const day = parseInt(match[3], 10);

  // Validate date components
  if (month < 0 || month > 11 || day < 1 || day > 31) {
    return null;
  }

  const date = new Date(year, month, day);

  // Verify the date is valid (handles invalid days like Feb 30)
  if (date.getFullYear() !== year ||
      date.getMonth() !== month ||
      date.getDate() !== day) {
    return null;
  }

  if (endOfDay) {
    date.setHours(23, 59, 59, 999);
  }

  return date;
}

/**
 * Check if filter object is empty (no filters applied)
 * @param {Object} filters - Parsed filter object
 * @returns {boolean} True if no filters are set
 */
function isEmptyFilter(filters) {
  if (!filters) return true;

  return !filters.folder &&
         !filters.dateFrom &&
         !filters.dateTo &&
         (!filters.tags || filters.tags.length === 0);
}

// ───────────────────────────────────────────────────────────────
// FILTER APPLICATION (T042)
// ───────────────────────────────────────────────────────────────

/**
 * Apply filters to results array
 *
 * All filters use AND logic - results must match ALL specified filters.
 *
 * @param {Array} results - Search results array
 * @param {Object} filters - Parsed filter object from parseFilter()
 * @returns {Array} Filtered results array
 *
 * @example
 * const filtered = applyFilter(results, { folder: "auth", tags: ["jwt"] });
 * // Returns only results in folders containing "auth" AND having "jwt" tag
 */
function applyFilter(results, filters) {
  if (!Array.isArray(results) || results.length === 0) {
    return [];
  }

  if (isEmptyFilter(filters)) {
    return results;
  }

  return results.filter(result => {
    // Check folder filter (partial match, case-insensitive)
    if (filters.folder) {
      const resultFolder = extractFolderName(result);
      if (!resultFolder || !resultFolder.toLowerCase().includes(filters.folder)) {
        return false;
      }
    }

    // Check date filters
    const resultDate = extractResultDate(result);
    if (resultDate) {
      // Check dateFrom (after or equal)
      if (filters.dateFrom && resultDate < filters.dateFrom) {
        return false;
      }

      // Check dateTo (before or equal)
      if (filters.dateTo && resultDate > filters.dateTo) {
        return false;
      }
    } else if (filters.dateFrom || filters.dateTo) {
      // If date filter specified but result has no date, exclude it
      return false;
    }

    // Check tag filters (all tags must match - AND logic)
    if (filters.tags && filters.tags.length > 0) {
      const resultTags = extractTags(result);
      const resultTagsLower = resultTags.map(t => t.toLowerCase());

      for (const filterTag of filters.tags) {
        // Check if any result tag contains the filter tag (partial match)
        const hasTag = resultTagsLower.some(t => t.includes(filterTag));
        if (!hasTag) {
          return false;
        }
      }
    }

    return true;
  });
}

/**
 * Extract folder name from result object
 * Handles multiple property names for flexibility
 * @param {Object} result - Search result object
 * @returns {string|null} Folder name or null
 */
function extractFolderName(result) {
  if (!result) return null;

  // Try different property names
  return result.spec_folder ||
         result.specFolder ||
         result.folder ||
         extractFolderFromPath(result.file_path || result.filePath);
}

/**
 * Extract folder name from file path
 * @param {string} filePath - Full file path
 * @returns {string|null} Spec folder name or null
 */
function extractFolderFromPath(filePath) {
  if (!filePath) return null;

  // Match specs/XXX-name pattern
  const match = filePath.match(/specs\/([^/]+)/);
  if (match) {
    return match[1];
  }

  // Try to get parent directory name
  return path.basename(path.dirname(filePath));
}

/**
 * Extract date from result object
 * @param {Object} result - Search result object
 * @returns {Date|null} Result date or null
 */
function extractResultDate(result) {
  if (!result) return null;

  // Try different property names
  const dateValue = result.created_at ||
                    result.createdAt ||
                    result.date ||
                    result.updated_at ||
                    result.updatedAt;

  if (!dateValue) return null;

  // Handle Date objects
  if (dateValue instanceof Date) {
    return dateValue;
  }

  // Handle ISO strings
  if (typeof dateValue === 'string') {
    const parsed = new Date(dateValue);
    return isNaN(parsed.getTime()) ? null : parsed;
  }

  return null;
}

/**
 * Extract tags from result object
 * @param {Object} result - Search result object
 * @returns {string[]} Array of tags
 */
function extractTags(result) {
  if (!result) return [];

  // Try different property names
  const tags = result.tags ||
               result.trigger_phrases ||
               result.triggerPhrases ||
               result.keywords ||
               [];

  // Handle string (comma-separated) or array
  if (typeof tags === 'string') {
    return tags.split(',').map(t => t.trim()).filter(Boolean);
  }

  // Handle JSON string (from database)
  if (typeof tags === 'string' && tags.startsWith('[')) {
    try {
      return JSON.parse(tags);
    } catch {
      return [];
    }
  }

  return Array.isArray(tags) ? tags : [];
}

// ───────────────────────────────────────────────────────────────
// FILTER STATE MANAGEMENT (T043, T044)
// ───────────────────────────────────────────────────────────────

/**
 * Create a filter state manager
 * Manages FILTERED state and clear functionality
 *
 * @param {Array} originalResults - Original unfiltered results
 * @returns {Object} Filter state manager
 */
function createFilterState(originalResults) {
  let currentFilters = null;
  let filteredResults = null;
  let isFiltered = false;

  return {
    /**
     * Get current state
     * @returns {string} 'FILTERED' or 'RESULTS'
     */
    getState() {
      return isFiltered ? 'FILTERED' : 'RESULTS';
    },

    /**
     * Check if filters are currently applied
     * @returns {boolean}
     */
    isFiltered() {
      return isFiltered;
    },

    /**
     * Get current filters
     * @returns {Object|null}
     */
    getFilters() {
      return currentFilters;
    },

    /**
     * Apply filters and return filtered results
     * @param {string} filterStr - Filter string
     * @returns {Array} Filtered results
     */
    apply(filterStr) {
      currentFilters = parseFilter(filterStr);
      filteredResults = applyFilter(originalResults, currentFilters);
      isFiltered = !isEmptyFilter(currentFilters);
      return filteredResults;
    },

    /**
     * Clear all filters (T044)
     * @returns {Array} Original results
     */
    clear() {
      currentFilters = null;
      filteredResults = null;
      isFiltered = false;
      return originalResults;
    },

    /**
     * Get current results (filtered or original)
     * @returns {Array}
     */
    getResults() {
      return isFiltered ? filteredResults : originalResults;
    },

    /**
     * Get filter summary string for display
     * @returns {string}
     */
    getFilterSummary() {
      if (!isFiltered || !currentFilters) {
        return '';
      }

      const parts = [];

      if (currentFilters.folder) {
        parts.push(`folder:${currentFilters.folder}`);
      }

      if (currentFilters.dateFrom && currentFilters.dateTo) {
        const fromStr = formatDateShort(currentFilters.dateFrom);
        const toStr = formatDateShort(currentFilters.dateTo);
        parts.push(`date:${fromStr}..${toStr}`);
      } else if (currentFilters.dateFrom) {
        parts.push(`date:>${formatDateShort(currentFilters.dateFrom)}`);
      } else if (currentFilters.dateTo) {
        parts.push(`date:<${formatDateShort(currentFilters.dateTo)}`);
      }

      for (const tag of currentFilters.tags) {
        parts.push(`tag:${tag}`);
      }

      return parts.join(' ');
    }
  };
}

/**
 * Format date for display (short format)
 * @param {Date} date
 * @returns {string}
 */
function formatDateShort(date) {
  if (!date) return '';
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

// ───────────────────────────────────────────────────────────────
// CLUSTERING (T048)
// ───────────────────────────────────────────────────────────────

/**
 * Cluster results by spec folder
 *
 * Groups results by their spec folder while preserving original result ranks.
 *
 * @param {Array} results - Search results array
 * @returns {Object} Clustered results object
 * @returns {Object.<string, {count: number, results: Array}>} Clusters by folder name
 *
 * @example
 * const clusters = clusterByFolder(results);
 * // => {
 * //   "049-auth-system": { count: 3, results: [...] },
 * //   "015-login-system": { count: 2, results: [...] }
 * // }
 */
function clusterByFolder(results) {
  if (!Array.isArray(results) || results.length === 0) {
    return {};
  }

  const clusters = {};

  for (const result of results) {
    const folderName = extractFolderName(result) || 'uncategorized';

    if (!clusters[folderName]) {
      clusters[folderName] = {
        count: 0,
        results: []
      };
    }

    clusters[folderName].results.push(result);
    clusters[folderName].count++;
  }

  // Sort clusters by count (descending) then by name
  const sortedClusters = {};
  const sortedKeys = Object.keys(clusters).sort((a, b) => {
    // First by count (descending)
    const countDiff = clusters[b].count - clusters[a].count;
    if (countDiff !== 0) return countDiff;
    // Then alphabetically
    return a.localeCompare(b);
  });

  for (const key of sortedKeys) {
    sortedClusters[key] = clusters[key];
  }

  return sortedClusters;
}

/**
 * Flatten clusters back to array (T051)
 *
 * Converts clustered results back to a flat array, maintaining
 * cluster ordering (results from same cluster stay together).
 *
 * @param {Object} clusters - Clustered results from clusterByFolder()
 * @returns {Array} Flat results array
 */
function uncluster(clusters) {
  if (!clusters || typeof clusters !== 'object') {
    return [];
  }

  const results = [];

  for (const folderName of Object.keys(clusters)) {
    const cluster = clusters[folderName];
    if (cluster && Array.isArray(cluster.results)) {
      results.push(...cluster.results);
    }
  }

  return results;
}

// ───────────────────────────────────────────────────────────────
// CLUSTER FORMATTING (T049)
// ───────────────────────────────────────────────────────────────

/**
 * Format clustered results for display
 *
 * Produces output like:
 * ```
 * --- 049-auth-system (3 memories) ---
 *
 * #1 [92%] OAuth callback flow implementation
 *    Date: Dec 5  |  Tags: oauth, jwt, pkce
 *
 * #2 [85%] JWT token refresh strategy
 *    Date: Dec 4  |  Tags: jwt, refresh, security
 * ```
 *
 * @param {Object} clusters - Clustered results from clusterByFolder()
 * @param {Object} [options] - Display options
 * @param {boolean} [options.showSnippet=false] - Include snippet line (3-line format)
 * @param {boolean} [options.showTags=true] - Include tags in metadata line
 * @param {number} [options.terminalWidth=80] - Terminal width for truncation
 * @param {boolean} [options.useColor=false] - Use ANSI color codes
 * @returns {string} Formatted output string
 */
function formatClusters(clusters, options = {}) {
  const {
    showSnippet = false,
    showTags = true,
    terminalWidth = 80,
    useColor = false
  } = options;

  if (!clusters || typeof clusters !== 'object') {
    return 'No results to cluster.';
  }

  const folderNames = Object.keys(clusters);
  if (folderNames.length === 0) {
    return 'No results to cluster.';
  }

  const lines = [];

  // Header
  lines.push('Clustered Results by Spec Folder');
  lines.push('================================');
  lines.push('');

  // Summary
  const totalResults = folderNames.reduce((sum, name) =>
    sum + clusters[name].count, 0);
  lines.push(`Found: ${totalResults} memories in ${folderNames.length} clusters`);
  lines.push('');

  // Each cluster
  for (const folderName of folderNames) {
    const cluster = clusters[folderName];

    // Cluster header
    const memoryWord = cluster.count === 1 ? 'memory' : 'memories';
    lines.push(`--- ${folderName} (${cluster.count} ${memoryWord}) ---`);
    lines.push('');

    // Results in cluster (compact 2-line format per output_format_design.md)
    for (const result of cluster.results) {
      const formattedResult = formatClusterResult(result, {
        showSnippet,
        showTags,
        terminalWidth,
        useColor
      });
      lines.push(formattedResult);
      lines.push('');
    }
  }

  // Action bar
  lines.push('---------------------------------------------------------------------');
  lines.push('Actions: [v]iew #n  |  [u]ncluster  |  [s]elect folder  |  [q]uit');

  return lines.join('\n');
}

/**
 * Format a single result within a cluster (compact 2-line format)
 * @param {Object} result - Search result
 * @param {Object} options - Formatting options
 * @returns {string} Formatted result string
 */
function formatClusterResult(result, options = {}) {
  const {
    showSnippet = false,
    showTags = true,
    terminalWidth = 80,
    useColor = false
  } = options;

  const lines = [];

  // Line 1: Rank, similarity, title
  const rank = result.rank || result._rank || '?';
  const similarity = formatSimilarity(result.similarity || result.avg_similarity || 0);
  const title = truncateText(
    result.title || extractTitleFromPath(result.file_path || result.filePath) || 'Untitled',
    terminalWidth - 15, // Space for rank + score + padding
    true // Truncate at word boundary
  );

  const similarityFormatted = useColor
    ? colorSimilarity(similarity, result.similarity || result.avg_similarity || 0)
    : `[${similarity}]`;

  lines.push(`#${rank} ${similarityFormatted} ${title}`);

  // Line 2: Metadata (date and tags, no folder since we're in a cluster)
  const metaParts = [];

  const date = extractResultDate(result);
  if (date) {
    metaParts.push(`Date: ${formatDisplayDate(date)}`);
  }

  if (showTags) {
    const tags = extractTags(result);
    if (tags.length > 0) {
      const formattedTags = formatTags(tags, terminalWidth - 20);
      metaParts.push(`Tags: ${formattedTags}`);
    }
  }

  if (metaParts.length > 0) {
    lines.push(`   ${metaParts.join('  |  ')}`);
  }

  // Line 3: Snippet (optional)
  if (showSnippet) {
    const snippet = result.snippet ||
                    result.summary ||
                    result.content?.substring(0, 100);
    if (snippet) {
      const truncatedSnippet = truncateText(snippet, terminalWidth - 6, true);
      lines.push(`   "${truncatedSnippet}"`);
    }
  }

  return lines.join('\n');
}

/**
 * Format similarity score for display
 * @param {number} similarity - Similarity score (0-100)
 * @returns {string} Formatted score
 */
function formatSimilarity(similarity) {
  if (typeof similarity !== 'number') return '??%';
  return `${Math.round(similarity)}%`;
}

/**
 * Apply color to similarity based on score
 * @param {string} text - Formatted similarity text
 * @param {number} score - Numerical score
 * @returns {string} Colored text with ANSI codes
 */
function colorSimilarity(text, score) {
  if (score >= 80) {
    return `\x1b[32m[${text}]\x1b[0m`; // Green
  } else if (score >= 50) {
    return `\x1b[33m[${text}]\x1b[0m`; // Yellow
  } else {
    return `\x1b[31m[${text}]\x1b[0m`; // Red
  }
}

/**
 * Format date for display
 * @param {Date} date
 * @returns {string}
 */
function formatDisplayDate(date) {
  if (!date) return '';

  const now = new Date();
  const diffDays = Math.floor((now - date) / (1000 * 60 * 60 * 24));

  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return `${diffDays} days ago`;

  // Format as "Mon DD" for current year, "Mon DD, YYYY" otherwise
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const month = months[date.getMonth()];
  const day = date.getDate();

  if (date.getFullYear() === now.getFullYear()) {
    return `${month} ${day}`;
  }
  return `${month} ${day}, ${date.getFullYear()}`;
}

/**
 * Format tags with overflow handling
 * @param {string[]} tags - Array of tags
 * @param {number} maxWidth - Maximum width
 * @returns {string}
 */
function formatTags(tags, maxWidth) {
  if (!tags || tags.length === 0) return '';

  let result = '';
  let remaining = tags.length;

  for (let i = 0; i < tags.length; i++) {
    const tag = tags[i];
    const separator = i === 0 ? '' : ', ';
    const potentialAddition = separator + tag;

    // Check if adding this tag would exceed width
    // Account for potential "+N more" suffix
    const moreText = ` +${remaining - 1} more`;
    const wouldExceed = result.length + potentialAddition.length > maxWidth - moreText.length;

    if (wouldExceed && i > 0) {
      // Add "+N more" indicator
      const moreCount = tags.length - i;
      result += ` +${moreCount} more`;
      break;
    }

    result += potentialAddition;
    remaining--;
  }

  return result;
}

/**
 * Truncate text at word boundary if possible
 * @param {string} text - Text to truncate
 * @param {number} maxLength - Maximum length
 * @param {boolean} [atWordBoundary=true] - Truncate at word boundary
 * @returns {string}
 */
function truncateText(text, maxLength, atWordBoundary = true) {
  if (!text) return '';
  if (text.length <= maxLength) return text;

  let truncated = text.substring(0, maxLength);

  if (atWordBoundary) {
    // Find last space within the truncated text
    const lastSpace = truncated.lastIndexOf(' ');
    if (lastSpace > maxLength * 0.5) { // Only if we'd keep at least half
      truncated = truncated.substring(0, lastSpace);
    }
  }

  return truncated.trim() + '...';
}

/**
 * Extract title from file path
 * @param {string} filePath
 * @returns {string}
 */
function extractTitleFromPath(filePath) {
  if (!filePath) return null;

  const basename = path.basename(filePath, path.extname(filePath));

  // Remove date prefix (DD-MM-YY_HH-MM__ format)
  const withoutDate = basename.replace(/^\d{2}-\d{2}-\d{2}_\d{2}-\d{2}__/, '');

  // Convert dashes/underscores to spaces and title case
  return withoutDate
    .replace(/[-_]/g, ' ')
    .replace(/\b\w/g, c => c.toUpperCase())
    .trim();
}

// ───────────────────────────────────────────────────────────────
// CLUSTER STATE MANAGEMENT (T050)
// ───────────────────────────────────────────────────────────────

/**
 * Create a cluster state manager
 * Manages CLUSTERED state and transitions
 *
 * @param {Array} results - Search results
 * @returns {Object} Cluster state manager
 */
function createClusterState(results) {
  let clusters = null;
  let isClustered = false;

  return {
    /**
     * Get current state
     * @returns {string} 'CLUSTERED' or 'RESULTS'
     */
    getState() {
      return isClustered ? 'CLUSTERED' : 'RESULTS';
    },

    /**
     * Check if currently clustered
     * @returns {boolean}
     */
    isClustered() {
      return isClustered;
    },

    /**
     * Cluster the results
     * @returns {Object} Clustered results
     */
    cluster() {
      clusters = clusterByFolder(results);
      isClustered = true;
      return clusters;
    },

    /**
     * Uncluster back to flat results (T051)
     * @returns {Array} Flat results
     */
    uncluster() {
      const flat = uncluster(clusters);
      clusters = null;
      isClustered = false;
      return flat;
    },

    /**
     * Get current clusters (null if not clustered)
     * @returns {Object|null}
     */
    getClusters() {
      return clusters;
    },

    /**
     * Get results for a specific folder
     * @param {string} folderName
     * @returns {Array}
     */
    getClusterResults(folderName) {
      if (!clusters || !clusters[folderName]) {
        return [];
      }
      return clusters[folderName].results;
    },

    /**
     * Get list of folder names in clusters
     * @returns {string[]}
     */
    getClusterNames() {
      return clusters ? Object.keys(clusters) : [];
    }
  };
}

// ───────────────────────────────────────────────────────────────
// COMBINED STATE MANAGER
// ───────────────────────────────────────────────────────────────

/**
 * Create a combined filter and cluster state manager
 * Manages transitions between RESULTS, FILTERED, and CLUSTERED states
 *
 * @param {Array} originalResults - Original search results
 * @returns {Object} Combined state manager
 */
function createFilterClusterState(originalResults) {
  const filterState = createFilterState(originalResults);
  let clusterState = null;

  return {
    // Filter operations
    isFiltered: () => filterState.isFiltered(),
    getFilters: () => filterState.getFilters(),
    getFilterSummary: () => filterState.getFilterSummary(),

    applyFilter(filterStr) {
      // Clear clustering when filtering
      clusterState = null;
      return filterState.apply(filterStr);
    },

    clearFilter() {
      // Clear clustering when clearing filters
      clusterState = null;
      return filterState.clear();
    },

    // Cluster operations
    isClustered() {
      return clusterState !== null && clusterState.isClustered();
    },

    cluster() {
      // Cluster the current results (filtered or original)
      const currentResults = filterState.getResults();
      clusterState = createClusterState(currentResults);
      return clusterState.cluster();
    },

    uncluster() {
      if (!clusterState) {
        return filterState.getResults();
      }
      const flat = clusterState.uncluster();
      clusterState = null;
      return flat;
    },

    getClusters() {
      return clusterState ? clusterState.getClusters() : null;
    },

    // Combined state
    getState() {
      if (clusterState && clusterState.isClustered()) {
        return 'CLUSTERED';
      }
      if (filterState.isFiltered()) {
        return 'FILTERED';
      }
      return 'RESULTS';
    },

    /**
     * Get current results based on state
     * @returns {Array|Object} Array for RESULTS/FILTERED, Object for CLUSTERED
     */
    getCurrentResults() {
      if (clusterState && clusterState.isClustered()) {
        return clusterState.getClusters();
      }
      return filterState.getResults();
    },

    /**
     * Get flat results regardless of clustering
     * @returns {Array}
     */
    getFlatResults() {
      return filterState.getResults();
    },

    /**
     * Reset all state
     */
    reset() {
      filterState.clear();
      clusterState = null;
    }
  };
}

// ───────────────────────────────────────────────────────────────
// EXPORTS
// ───────────────────────────────────────────────────────────────

module.exports = {
  // Filter functions (T041, T042)
  parseFilter,
  applyFilter,
  isEmptyFilter,

  // Filter state (T043, T044)
  createFilterState,

  // Cluster functions (T048, T051)
  clusterByFolder,
  uncluster,

  // Cluster formatting (T049)
  formatClusters,
  formatClusterResult,

  // Cluster state (T050)
  createClusterState,

  // Combined state manager
  createFilterClusterState,

  // Utility functions (exported for testing)
  parseDate,
  extractFolderName,
  extractResultDate,
  extractTags,
  formatDateShort,
  formatDisplayDate,
  formatTags,
  truncateText,
  formatSimilarity
};
