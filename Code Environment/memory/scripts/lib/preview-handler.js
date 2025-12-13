#!/usr/bin/env node

/**
 * Preview Handler Module for Interactive Memory Search
 *
 * Provides preview formatting and anchor section extraction for memory files.
 * Implements US3 (Preview Before Load) and US11 (Anchor Section Extraction).
 *
 * @module preview-handler
 * @version 1.0.0
 * @created 2025-12-07
 */

const fs = require('fs');
const path = require('path');

// ───────────────────────────────────────────────────────────────
// ANCHOR ID MAPPING
// ───────────────────────────────────────────────────────────────

/**
 * Standard section mappings from markdown headers to anchor IDs
 * Multiple header variations map to the same canonical anchor ID
 */
const ANCHOR_MAPPINGS = {
  // Summary anchors
  'overview': 'summary',
  'summary': 'summary',
  'session summary': 'summary',
  '1. overview': 'summary',

  // Decision anchors
  'key decisions': 'decisions',
  'decisions': 'decisions',
  '3. decisions': 'decisions',
  'decision': 'decisions',

  // Files anchors
  'files modified': 'files',
  'changed files': 'files',
  'key files': 'files',
  'modified files': 'files',

  // Context anchors
  'context': 'context',
  'session context': 'context',

  // Implementation anchors
  'implementation details': 'implementation',
  'implementation': 'implementation',
  'detailed changes': 'implementation',
  '2. detailed changes': 'implementation',

  // Conversation anchors
  'conversation': 'conversation',
  '4. conversation': 'conversation',
  'conversation flow': 'conversation',
  'message timeline': 'conversation'
};

// ───────────────────────────────────────────────────────────────
// SECTION PARSING
// ───────────────────────────────────────────────────────────────

/**
 * Parse memory markdown into structured sections
 *
 * Extracts key sections from a memory file for preview display.
 * Handles both anchor-tagged sections and plain markdown headers.
 *
 * @param {string} content - Full markdown content
 * @returns {Object} Parsed sections object
 * @returns {string|null} returns.summary - Overview/summary section content
 * @returns {string|null} returns.keyDecisions - Key decisions section content
 * @returns {string|null} returns.filesModified - Files modified section content
 * @returns {Array<{id: string, title: string, content: string}>} returns.anchors - All detected anchors
 *
 * @example
 * const sections = parseMemorySections(memoryContent);
 * console.log(sections.summary);
 * // "sqlite-vec requires BigInt for explicit rowid..."
 */
function parseMemorySections(content) {
  if (!content || typeof content !== 'string') {
    return {
      summary: null,
      keyDecisions: null,
      filesModified: null,
      anchors: []
    };
  }

  const sections = {
    summary: null,
    keyDecisions: null,
    filesModified: null,
    anchors: []
  };

  // Extract anchors from HTML comments
  const anchorPattern = /<!-- anchor: ([^\s]+) -->([\s\S]*?)<!-- \/anchor: \1 -->/g;
  let match;

  while ((match = anchorPattern.exec(content)) !== null) {
    const anchorId = match[1];
    const anchorContent = match[2].trim();

    // Extract title from first heading in anchor content
    const titleMatch = anchorContent.match(/^##?\s+(.+?)(?:\n|$)/m);
    const title = titleMatch ? titleMatch[1].trim() : anchorId;

    sections.anchors.push({
      id: anchorId,
      title: title,
      content: anchorContent
    });
  }

  // Extract standard sections by header
  sections.summary = extractSectionByHeader(content, ['## Overview', '## Summary', '## 1. OVERVIEW']);
  sections.keyDecisions = extractSectionByHeader(content, ['## Key Decisions', '## Decisions', '## 3. DECISIONS']);
  sections.filesModified = extractSectionByHeader(content, ['## Files Modified', '## Changed Files', '## Key Files']);

  // If no sections found via headers, try anchor-based extraction
  if (!sections.summary) {
    const summaryAnchor = sections.anchors.find(a => a.id.includes('summary') || a.id.includes('overview'));
    if (summaryAnchor) {
      sections.summary = extractContentFromAnchor(summaryAnchor.content);
    }
  }

  if (!sections.keyDecisions) {
    const decisionsAnchor = sections.anchors.find(a => a.id.includes('decision'));
    if (decisionsAnchor) {
      sections.keyDecisions = extractContentFromAnchor(decisionsAnchor.content);
    }
  }

  return sections;
}

/**
 * Extract a section from markdown by header
 *
 * @param {string} content - Full markdown content
 * @param {string[]} headers - Array of possible header strings to match
 * @returns {string|null} - Section content or null if not found
 */
function extractSectionByHeader(content, headers) {
  for (const header of headers) {
    const headerIndex = content.indexOf(header);
    if (headerIndex === -1) continue;

    // Find the start of content (after header line)
    const contentStart = content.indexOf('\n', headerIndex);
    if (contentStart === -1) continue;

    // Find the end (next header of same or higher level, or end of content)
    const headerLevel = header.match(/^#+/)?.[0].length || 2;
    const nextHeaderPattern = new RegExp(`^#{1,${headerLevel}}\\s`, 'm');
    const remainingContent = content.slice(contentStart + 1);
    const nextHeaderMatch = remainingContent.match(nextHeaderPattern);

    let sectionContent;
    if (nextHeaderMatch) {
      sectionContent = remainingContent.slice(0, nextHeaderMatch.index);
    } else {
      // Check for horizontal rule as section delimiter
      const hrIndex = remainingContent.indexOf('\n---\n');
      sectionContent = hrIndex !== -1
        ? remainingContent.slice(0, hrIndex)
        : remainingContent;
    }

    // Clean up the content - remove anchor comments and clean whitespace
    const cleaned = stripAnchorComments(sectionContent.trim());
    if (cleaned) {
      return cleaned;
    }
  }

  return null;
}

/**
 * Strip HTML anchor comments from content
 *
 * @param {string} content - Content with potential anchor comments
 * @returns {string} - Cleaned content
 */
function stripAnchorComments(content) {
  if (!content) return '';

  return content
    // Remove opening anchor comments
    .replace(/<!--\s*anchor:\s*[^\s]+\s*-->\n?/g, '')
    // Remove closing anchor comments
    .replace(/<!--\s*\/anchor:\s*[^\s]+\s*-->\n?/g, '')
    // Remove any remaining HTML comments
    .replace(/<!--[\s\S]*?-->\n?/g, '')
    // Clean up multiple blank lines
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

/**
 * Extract clean content from anchor section (remove headers, clean formatting)
 *
 * @param {string} anchorContent - Raw anchor content
 * @returns {string} - Cleaned content
 */
function extractContentFromAnchor(anchorContent) {
  // Remove the first heading line
  const lines = anchorContent.split('\n');
  const contentLines = lines.filter((line, index) => {
    // Skip first heading
    if (index === 0 && /^##?\s/.test(line)) return false;
    // Skip empty lines at start
    if (index < 3 && line.trim() === '') return false;
    return true;
  });

  return contentLines.join('\n').trim();
}

// ───────────────────────────────────────────────────────────────
// ANCHOR EXTRACTION
// ───────────────────────────────────────────────────────────────

/**
 * Extract a specific anchor section by ID
 *
 * Supports both exact anchor IDs and canonical mappings.
 * For example, both "decisions-015" and "decisions" will match.
 *
 * @param {string} content - Full markdown content
 * @param {string} anchorId - Section identifier (e.g., "decisions", "files", "summary")
 * @returns {string|null} - Section content or null if not found
 *
 * @example
 * const decisions = extractAnchor(content, 'decisions');
 * // Returns: "- PKCE over implicit flow for security\n- Refresh tokens in httpOnly cookies..."
 */
function extractAnchor(content, anchorId) {
  if (!content || !anchorId) {
    return null;
  }

  const normalizedId = anchorId.toLowerCase().trim();

  // Try direct anchor match first
  const directPattern = new RegExp(
    `<!-- anchor: ([^\\s]*${escapeRegex(normalizedId)}[^\\s]*) -->([\\s\\S]*?)<!-- \\/anchor: \\1 -->`,
    'i'
  );
  const directMatch = content.match(directPattern);

  if (directMatch) {
    return cleanAnchorContent(directMatch[2]);
  }

  // Try canonical mapping
  const canonicalId = ANCHOR_MAPPINGS[normalizedId] || normalizedId;

  // Search for any anchor containing the canonical ID
  const canonicalPattern = new RegExp(
    `<!-- anchor: ([^\\s]*${escapeRegex(canonicalId)}[^\\s]*) -->([\\s\\S]*?)<!-- \\/anchor: \\1 -->`,
    'i'
  );
  const canonicalMatch = content.match(canonicalPattern);

  if (canonicalMatch) {
    return cleanAnchorContent(canonicalMatch[2]);
  }

  // Fallback: try header-based extraction
  const headerMappings = {
    'summary': ['## Overview', '## Summary', '## 1. OVERVIEW'],
    'decisions': ['## Key Decisions', '## Decisions', '## 3. DECISIONS'],
    'files': ['## Files Modified', '## Changed Files', '## Key Files'],
    'implementation': ['## Implementation Details', '## Detailed Changes', '## 2. DETAILED CHANGES'],
    'conversation': ['## Conversation', '## 4. CONVERSATION', '## Conversation Flow']
  };

  const headers = headerMappings[canonicalId];
  if (headers) {
    return extractSectionByHeader(content, headers);
  }

  return null;
}

/**
 * Clean anchor content - remove headers, trim whitespace
 *
 * @param {string} content - Raw anchor content
 * @returns {string} - Cleaned content
 */
function cleanAnchorContent(content) {
  if (!content) return '';

  // Remove leading/trailing whitespace
  let cleaned = content.trim();

  // Remove the first heading if present (it's usually the section title)
  cleaned = cleaned.replace(/^##?\s+[^\n]+\n+/, '');

  return cleaned.trim();
}

/**
 * Escape special regex characters in a string
 *
 * @param {string} str - String to escape
 * @returns {string} - Escaped string
 */
function escapeRegex(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * Get list of available anchors in a memory file
 *
 * Returns all anchors found in the content, with their canonical IDs
 * and human-readable titles.
 *
 * @param {string} content - Full markdown content
 * @returns {Array<{id: string, title: string, canonical: string}>} - List of anchors
 *
 * @example
 * const anchors = listAnchors(content);
 * // [
 * //   { id: 'summary-011-semantic-memory', title: 'Overview', canonical: 'summary' },
 * //   { id: 'decision-opus-4.5-verification-011', title: 'Decision 1', canonical: 'decisions' }
 * // ]
 */
function listAnchors(content) {
  if (!content || typeof content !== 'string') {
    return [];
  }

  const anchors = [];
  const anchorPattern = /<!-- anchor: ([^\s]+) -->([\s\S]*?)<!-- \/anchor: \1 -->/g;
  let match;

  while ((match = anchorPattern.exec(content)) !== null) {
    const anchorId = match[1];
    const anchorContent = match[2].trim();

    // Extract title from first heading
    const titleMatch = anchorContent.match(/^##?\s+(.+?)(?:\n|$)/m);
    let title = titleMatch ? titleMatch[1].trim() : anchorId;

    // Clean up title (remove numbering like "1. ", "Decision 1:", etc.)
    title = title.replace(/^\d+\.\s*/, '').replace(/^(FEATURE|DISCOVERY|DECISION):\s*/i, '');

    // Determine canonical ID
    const canonical = getCanonicalAnchorId(anchorId, title);

    anchors.push({
      id: anchorId,
      title: title,
      canonical: canonical
    });
  }

  return anchors;
}

/**
 * Get canonical anchor ID from full anchor ID or title
 *
 * @param {string} anchorId - Full anchor ID
 * @param {string} title - Section title
 * @returns {string} - Canonical ID
 */
function getCanonicalAnchorId(anchorId, title) {
  const idLower = anchorId.toLowerCase();
  const titleLower = (title || '').toLowerCase();

  // Check ID patterns
  if (idLower.includes('summary') || idLower.includes('overview')) return 'summary';
  if (idLower.includes('decision')) return 'decisions';
  if (idLower.includes('files') || idLower.includes('modified')) return 'files';
  if (idLower.includes('implementation') || idLower.includes('detailed-changes')) return 'implementation';
  if (idLower.includes('discovery')) return 'discovery';
  if (idLower.includes('session-history') || idLower.includes('conversation')) return 'conversation';
  if (idLower.includes('guide')) return 'guide';
  if (idLower.includes('architecture')) return 'architecture';

  // Check title patterns
  if (titleLower.includes('overview') || titleLower.includes('summary')) return 'summary';
  if (titleLower.includes('decision')) return 'decisions';
  if (titleLower.includes('file')) return 'files';

  // Default: slugify the first part of the ID
  const slug = anchorId.split('-')[0].toLowerCase();
  return slug || 'unknown';
}

// ───────────────────────────────────────────────────────────────
// PREVIEW FORMATTING
// ───────────────────────────────────────────────────────────────

/**
 * Format preview display for a memory file
 *
 * Creates a structured preview with metadata, summary, key decisions,
 * and files modified sections.
 *
 * @param {Object} memory - Memory object with metadata
 * @param {string} memory.filePath - Full file path
 * @param {string} memory.title - Memory title
 * @param {number} memory.similarity - Similarity score (0-100)
 * @param {string} memory.specFolder - Spec folder name
 * @param {Date|string} memory.date - Creation date
 * @param {number} memory.size - File size in bytes
 * @param {string[]} memory.tags - Topic tags
 * @param {Object} sections - Parsed sections from parseMemorySections()
 * @param {Object} [options] - Formatting options
 * @param {number} [options.width=80] - Terminal width
 * @param {boolean} [options.color=false] - Enable ANSI colors
 * @returns {string} - Formatted preview string
 *
 * @example
 * const preview = formatPreview(
 *   { filePath: '...', title: 'OAuth implementation', similarity: 92, ... },
 *   { summary: '...', keyDecisions: '...', filesModified: '...' }
 * );
 * console.log(preview);
 */
function formatPreview(memory, sections, options = {}) {
  const width = options.width || 80;
  const useColor = options.color && supportsColor();

  const lines = [];

  // ─── Header ───────────────────────────────────────────────────
  const title = memory.title || extractTitleFromPath(memory.filePath);
  lines.push(`Preview: ${title}`);
  lines.push('='.repeat(Math.min(title.length + 9, width)));
  lines.push('');

  // ─── Metadata ─────────────────────────────────────────────────
  lines.push(`File: ${memory.filePath}`);

  const metadataParts = [];
  if (memory.similarity !== undefined) {
    const scoreStr = `${Math.round(memory.similarity)}% match`;
    metadataParts.push(useColor ? colorizeScore(scoreStr, memory.similarity) : `Score: ${scoreStr}`);
  }
  if (memory.date) {
    metadataParts.push(`Created: ${formatDate(memory.date)}`);
  }
  if (memory.size) {
    metadataParts.push(`Size: ${formatSize(memory.size)}`);
  }

  if (metadataParts.length > 0) {
    lines.push(metadataParts.join('  |  '));
  }
  lines.push('');

  // ─── Tags ─────────────────────────────────────────────────────
  if (memory.tags && memory.tags.length > 0) {
    const tagsLine = formatTags(memory.tags, width - 6);
    lines.push(`Tags: ${tagsLine}`);
    lines.push('');
  }

  // ─── Summary Section ──────────────────────────────────────────
  if (sections.summary) {
    lines.push('Summary');
    lines.push('-'.repeat(7));
    lines.push(truncateToLines(sections.summary, 3, width));
    lines.push('');
  }

  // ─── Key Decisions Section ────────────────────────────────────
  if (sections.keyDecisions) {
    lines.push('Key Decisions');
    lines.push('-'.repeat(13));
    lines.push(formatDecisions(sections.keyDecisions, width));
    lines.push('');
  }

  // ─── Files Modified Section ───────────────────────────────────
  if (sections.filesModified) {
    lines.push('Files Modified');
    lines.push('-'.repeat(14));
    lines.push(formatFilesList(sections.filesModified, width));
    lines.push('');
  }

  // ─── Available Anchors ────────────────────────────────────────
  if (sections.anchors && sections.anchors.length > 0) {
    const uniqueCanonicals = [...new Set(sections.anchors.map(a => getCanonicalAnchorId(a.id, a.title)))];
    if (uniqueCanonicals.length > 0) {
      lines.push(`Sections: ${uniqueCanonicals.join(', ')}`);
      lines.push('');
    }
  }

  // ─── Action Bar ───────────────────────────────────────────────
  lines.push('-'.repeat(width > 69 ? 69 : width));
  lines.push('Actions: [o]pen file  |  [e]xtract section  |  [l]oad  |  [b]ack');
  lines.push('Enter selection: _');

  return lines.join('\n');
}

// ───────────────────────────────────────────────────────────────
// HELPER FUNCTIONS
// ───────────────────────────────────────────────────────────────

/**
 * Extract title from file path
 *
 * @param {string} filePath - File path
 * @returns {string} - Extracted title
 */
function extractTitleFromPath(filePath) {
  if (!filePath) return 'Unknown';

  const filename = path.basename(filePath, '.md');
  // Format: DD-MM-YY_HH-MM__topic-name
  const match = filename.match(/__(.+)$/);
  if (match) {
    return match[1].replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
  }

  return filename.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

/**
 * Format date for display
 *
 * @param {Date|string} date - Date to format
 * @returns {string} - Formatted date string
 */
function formatDate(date) {
  if (!date) return 'Unknown';

  const d = date instanceof Date ? date : new Date(date);
  if (isNaN(d.getTime())) return 'Unknown';

  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return `${months[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`;
}

/**
 * Format file size for display
 *
 * @param {number} bytes - Size in bytes
 * @returns {string} - Formatted size string
 */
function formatSize(bytes) {
  if (!bytes || bytes < 0) return '0 B';

  const units = ['B', 'KB', 'MB', 'GB'];
  let size = bytes;
  let unitIndex = 0;

  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }

  return `${size.toFixed(1)} ${units[unitIndex]}`;
}

/**
 * Format tags with overflow handling
 *
 * @param {string[]} tags - Array of tags
 * @param {number} maxWidth - Maximum width
 * @returns {string} - Formatted tags string
 */
function formatTags(tags, maxWidth) {
  if (!tags || tags.length === 0) return '';

  const tagStr = tags.join(', ');
  if (tagStr.length <= maxWidth) {
    return tagStr;
  }

  // Truncate and add "+N more"
  let result = '';
  let count = 0;

  for (const tag of tags) {
    const addition = count === 0 ? tag : `, ${tag}`;
    const remaining = tags.length - count - 1;
    const moreStr = ` +${remaining} more`;

    if ((result + addition + moreStr).length > maxWidth && count > 0) {
      return result + moreStr;
    }

    result += addition;
    count++;
  }

  return result;
}

/**
 * Truncate text to a maximum number of lines
 *
 * @param {string} text - Text to truncate
 * @param {number} maxLines - Maximum lines
 * @param {number} width - Line width
 * @returns {string} - Truncated text
 */
function truncateToLines(text, maxLines, width) {
  if (!text) return '';

  // Clean the text first - remove markdown artifacts
  const cleanedText = text
    // Remove bold markers on their own line (like **Key Outcomes**:)
    .replace(/^\*\*[^*]+\*\*:\s*$/gm, '')
    // Remove lines that are just formatting
    .replace(/^[-=]{3,}\s*$/gm, '')
    // Clean up multiple blank lines
    .replace(/\n{3,}/g, '\n\n')
    .trim();

  // Get meaningful lines only
  const allLines = cleanedText.split('\n').filter(line => {
    const trimmed = line.trim();
    // Skip empty lines, header markers, and formatting-only lines
    return trimmed.length > 0 &&
           !trimmed.match(/^[-=]{3,}$/) &&
           !trimmed.match(/^\*\*[^*]+\*\*:\s*$/);
  });

  const lines = allLines.slice(0, maxLines);
  const truncated = lines.map(line => {
    if (line.length > width) {
      // Truncate at word boundary
      const truncPoint = line.lastIndexOf(' ', width - 3);
      return truncPoint > width / 2
        ? line.slice(0, truncPoint) + '...'
        : line.slice(0, width - 3) + '...';
    }
    return line;
  });

  return truncated.join('\n');
}

/**
 * Format decisions as bullet list
 *
 * Extracts key decision points from the decisions content.
 * Looks for decision titles, selected options, and rationale.
 *
 * @param {string} content - Decisions content
 * @param {number} width - Line width
 * @returns {string} - Formatted decisions
 */
function formatDecisions(content, width) {
  if (!content) return '';

  const bullets = [];

  // Strategy 1: Look for decision titles (### Decision N: Title)
  const decisionTitlePattern = /###\s*Decision\s*\d*:?\s*(.+)/gi;
  let match;
  while ((match = decisionTitlePattern.exec(content)) !== null) {
    const title = match[1].trim();
    if (title.length > 3) {
      bullets.push(`- ${title}`);
    }
  }

  // Strategy 2: Look for **Selected**: value
  const selectedPattern = /\*\*Selected\*\*:\s*(.+)/gi;
  while ((match = selectedPattern.exec(content)) !== null) {
    const selected = match[1].trim();
    if (selected.length > 3 && selected !== 'N/A') {
      bullets.push(`- Selected: ${selected}`);
    }
  }

  // Strategy 3: Look for bullet points that seem like decisions
  const lines = content.split('\n');
  for (const line of lines) {
    const trimmed = line.trim();

    // Skip headers and empty lines
    if (!trimmed || /^#{1,4}\s/.test(trimmed)) continue;
    // Skip formatting lines
    if (/^[-=]{3,}$/.test(trimmed)) continue;
    // Skip label lines
    if (/^\*\*[^*]+\*\*:/.test(trimmed)) continue;

    // Bullet points that look like decisions
    if (/^[-*]\s/.test(trimmed)) {
      const bulletContent = trimmed.slice(2).trim();
      // Look for decision-like content (has "because", "over", "instead", etc.)
      if (bulletContent.length > 10 &&
          /\b(because|over|instead|for|due to|rather than)\b/i.test(bulletContent)) {
        bullets.push(`- ${bulletContent}`);
      }
    }
  }

  // Deduplicate bullets (keep order)
  const seen = new Set();
  const uniqueBullets = bullets.filter(b => {
    const normalized = b.toLowerCase();
    if (seen.has(normalized)) return false;
    seen.add(normalized);
    return true;
  });

  // If we found no decisions, try to extract any bullet points
  if (uniqueBullets.length === 0) {
    for (const line of lines) {
      const trimmed = line.trim();
      if (/^[-*]\s/.test(trimmed)) {
        const bulletContent = trimmed.slice(2).trim();
        if (bulletContent.length > 10) {
          uniqueBullets.push(`- ${bulletContent}`);
        }
      }
    }
  }

  // Limit to 5 decisions for preview
  const limited = uniqueBullets.slice(0, 5);
  return limited.map(b => {
    if (b.length > width - 2) {
      return b.slice(0, width - 5) + '...';
    }
    return b;
  }).join('\n');
}

/**
 * Format files list with indentation
 *
 * @param {string} content - Files content
 * @param {number} width - Line width
 * @returns {string} - Formatted files list
 */
function formatFilesList(content, width) {
  if (!content) return '';

  const lines = content.split('\n');
  const files = [];

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed) continue;

    // Extract file paths (look for common patterns)
    const fileMatch = trimmed.match(/[`|]?([^\s`|]+\.(js|ts|md|json|sh|css|html|py|jsx|tsx))[`|]?/);
    if (fileMatch) {
      files.push(`  ${fileMatch[1]}`);
    } else if (trimmed.startsWith('-') || trimmed.startsWith('*')) {
      // Bullet point
      files.push(`  ${trimmed.slice(1).trim()}`);
    } else if (/^[a-z]/i.test(trimmed) && trimmed.includes('/')) {
      // Looks like a path
      files.push(`  ${trimmed}`);
    }
  }

  // Limit to 8 files for preview
  const limited = files.slice(0, 8);
  if (files.length > 8) {
    limited.push(`  ... and ${files.length - 8} more`);
  }

  return limited.join('\n');
}

/**
 * Check if terminal supports color
 *
 * @returns {boolean} - True if color is supported
 */
function supportsColor() {
  if (process.env.NO_COLOR) return false;
  if (process.env.FORCE_COLOR) return true;
  if (!process.stdout.isTTY) return false;

  const term = process.env.TERM || '';
  return term !== 'dumb' &&
         (term.includes('color') ||
          term.includes('256') ||
          term.includes('xterm'));
}

/**
 * Apply color to score based on value
 *
 * @param {string} text - Text to colorize
 * @param {number} score - Score value (0-100)
 * @returns {string} - Colorized text
 */
function colorizeScore(text, score) {
  const RESET = '\x1b[0m';
  const GREEN = '\x1b[32m';
  const YELLOW = '\x1b[33m';
  const RED = '\x1b[31m';

  if (score >= 80) return `${GREEN}${text}${RESET}`;
  if (score >= 50) return `${YELLOW}${text}${RESET}`;
  return `${RED}${text}${RESET}`;
}

// ───────────────────────────────────────────────────────────────
// FILE OPERATIONS
// ───────────────────────────────────────────────────────────────

/**
 * Read and parse a memory file
 *
 * @param {string} filePath - Path to memory file
 * @returns {Object} - Object with content, sections, and metadata
 */
function readMemoryFile(filePath) {
  if (!filePath || !fs.existsSync(filePath)) {
    return {
      error: 'File not found',
      content: null,
      sections: null
    };
  }

  try {
    const content = fs.readFileSync(filePath, 'utf-8');
    const stats = fs.statSync(filePath);
    const sections = parseMemorySections(content);

    return {
      content,
      sections,
      size: stats.size,
      date: stats.mtime
    };
  } catch (error) {
    return {
      error: error.message,
      content: null,
      sections: null
    };
  }
}

/**
 * Extract a specific section from a memory file
 *
 * Convenience function that combines reading and anchor extraction.
 *
 * @param {string} filePath - Path to memory file
 * @param {string} anchorId - Anchor ID to extract
 * @returns {Object} - Object with section content or error
 */
function extractSectionFromFile(filePath, anchorId) {
  const result = readMemoryFile(filePath);

  if (result.error) {
    return { error: result.error, content: null };
  }

  const sectionContent = extractAnchor(result.content, anchorId);

  if (!sectionContent) {
    return {
      error: `Anchor "${anchorId}" not found`,
      content: null,
      availableAnchors: listAnchors(result.content)
    };
  }

  return {
    content: sectionContent,
    anchorId: anchorId
  };
}

// ───────────────────────────────────────────────────────────────
// EXPORTS
// ───────────────────────────────────────────────────────────────

module.exports = {
  // Core functions
  parseMemorySections,
  extractAnchor,
  listAnchors,
  formatPreview,

  // File operations
  readMemoryFile,
  extractSectionFromFile,

  // Utilities (exported for testing)
  extractSectionByHeader,
  stripAnchorComments,
  extractTitleFromPath,
  formatDate,
  formatSize,
  formatTags,
  truncateToLines,
  formatDecisions,
  formatFilesList,
  supportsColor,
  colorizeScore,
  getCanonicalAnchorId,

  // Constants
  ANCHOR_MAPPINGS
};

// ───────────────────────────────────────────────────────────────
// CLI TESTING INTERFACE
// ───────────────────────────────────────────────────────────────

if (require.main === module) {
  console.log('Preview Handler Test Suite\n');
  console.log('='.repeat(50));

  // Test 1: Parse sections from sample content
  const sampleContent = `# SESSION SUMMARY

## 1. OVERVIEW

<!-- anchor: summary-test-001 -->
Test summary content here.
<!-- /anchor: summary-test-001 -->

---

## 3. DECISIONS

<!-- anchor: decision-test-001 -->
### Decision 1: Test Decision

**Context**: Testing context here.

#### Options Considered
- Option A
- Option B

#### Chosen Approach
Selected Option A because reasons.
<!-- /anchor: decision-test-001 -->

---

## Files Modified

- src/auth/oauth-callback.js
- src/middleware/token-refresh.js
`;

  console.log('\nTest 1: parseMemorySections()');
  const sections = parseMemorySections(sampleContent);
  console.log('Summary:', sections.summary ? 'Found' : 'Not found');
  console.log('Key Decisions:', sections.keyDecisions ? 'Found' : 'Not found');
  console.log('Files Modified:', sections.filesModified ? 'Found' : 'Not found');
  console.log('Anchors found:', sections.anchors.length);

  console.log('\nTest 2: extractAnchor()');
  const decisionsContent = extractAnchor(sampleContent, 'decisions');
  console.log('Decisions anchor:', decisionsContent ? 'Extracted' : 'Not found');

  console.log('\nTest 3: listAnchors()');
  const anchors = listAnchors(sampleContent);
  console.log('Anchors:', anchors.map(a => `${a.id} (${a.canonical})`).join(', '));

  console.log('\nTest 4: formatPreview()');
  const preview = formatPreview(
    {
      filePath: 'specs/049-auth-system/memory/05-12-25_14-30__oauth-implementation.md',
      title: 'OAuth callback flow implementation',
      similarity: 92,
      date: new Date('2025-12-05T14:30:00'),
      size: 2457,
      tags: ['oauth', 'jwt', 'pkce', 'authentication', 'callback']
    },
    sections
  );
  console.log(preview);

  console.log('\n' + '='.repeat(50));
  console.log('Tests complete');
}
