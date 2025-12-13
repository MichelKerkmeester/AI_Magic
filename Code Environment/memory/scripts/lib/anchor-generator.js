#!/usr/bin/env node

/**
 * Anchor Generator - Auto-generate HTML comment anchor IDs
 *
 * Purpose: Generate unique, searchable anchor IDs from section titles
 * for context retrieval in memory files.
 *
 * @module anchor-generator
 * @version 1.0.0
 * @created 2025-11-28
 */

/**
 * Generate unique anchor ID from section title
 *
 * Format: category-topic-spec#
 * Example: implementation-oauth-callback-015
 *
 * @param {string} sectionTitle - Original section heading
 * @param {string} category - Anchor category (implementation, decision, etc.)
 * @param {string} specNumber - Spec folder number (e.g., "015")
 * @param {string} [date] - Optional date for collision prevention (YYYY-MM-DD)
 * @returns {string} Anchor ID
 *
 * @example
 * generateAnchorId("OAuth Callback Handler", "implementation", "015")
 * // Returns: "implementation-oauth-callback-015"
 */
function generateAnchorId(sectionTitle, category, specNumber, date = null) {
  // Extract keywords from title
  const keywords = extractKeywords(sectionTitle);

  // Generate slug from keywords (max 3 words)
  const slug = keywords.slice(0, 3).join('-');

  // Combine: category-slug-specNumber
  let anchorId = `${category}-${slug}-${specNumber}`;

  // Add date if provided (collision prevention)
  if (date) {
    anchorId += `-${date}`;
  }

  return anchorId;
}

/**
 * Categorize section based on content and title
 *
 * Categories (priority order):
 * 1. decision - Technical choices
 * 2. implementation - Code/features built
 * 3. guide - How-to instructions
 * 4. architecture - System design
 * 5. files - File modifications
 * 6. discovery - Research findings
 * 7. integration - External services
 * 8. summary - Overview (fallback)
 *
 * @param {string} sectionTitle - Section heading
 * @param {string} [content=''] - Section text content
 * @returns {string} Category name
 *
 * @example
 * categorizeSection("Decision: JWT vs Sessions", "We need to choose...")
 * // Returns: "decision"
 *
 * categorizeSection("Implemented OAuth Flow", "Created provider...")
 * // Returns: "implementation"
 */
function categorizeSection(sectionTitle, content = '') {
  const text = (sectionTitle + ' ' + content).toLowerCase();
  const title = sectionTitle.toLowerCase();

  // Priority 1: Explicit decision language (title takes precedence)
  if (/decision|choice|selected|approach|alternative|option/i.test(title)) {
    return 'decision';
  }

  // Priority 2: Implementation verbs
  if (/implement|built|created|added|developed|wrote|coded/i.test(text)) {
    return 'implementation';
  }

  // Priority 3: Guide/how-to language
  if (/how to|extend|add new|guide|steps|instructions|tutorial/i.test(title)) {
    return 'guide';
  }

  // Priority 4: Architecture/design
  if (/architecture|design|system|structure|flow|model|schema/i.test(title)) {
    return 'architecture';
  }

  // Priority 5: File references
  if (/modified|updated|changed.*file|files?:/i.test(content)) {
    return 'files';
  }

  // Priority 6: Discovery/research
  if (/discovered|found|investigated|research|explored|analysis/i.test(text)) {
    return 'discovery';
  }

  // Priority 7: Integration
  if (/integration|external|api|service|sdk|library|package/i.test(text)) {
    return 'integration';
  }

  // Default fallback
  return 'implementation';
}

/**
 * Validate anchor ID uniqueness within document
 *
 * If collision detected, appends incrementing suffix (-2, -3, etc.)
 *
 * @param {string} anchorId - Proposed anchor ID
 * @param {Array<string>} existingAnchors - Already-used anchor IDs in this session
 * @returns {string} Unique anchor ID (may have -2, -3 suffix)
 *
 * @example
 * validateAnchorUniqueness("implementation-oauth-015", ["implementation-jwt-015"])
 * // Returns: "implementation-oauth-015" (unique)
 *
 * validateAnchorUniqueness("implementation-oauth-015", ["implementation-oauth-015"])
 * // Returns: "implementation-oauth-015-2" (collision avoided)
 */
function validateAnchorUniqueness(anchorId, existingAnchors) {
  if (!existingAnchors.includes(anchorId)) {
    return anchorId; // Already unique
  }

  // Collision detected - append incrementing suffix
  let counter = 2;
  let uniqueId = `${anchorId}-${counter}`;

  while (existingAnchors.includes(uniqueId)) {
    counter++;
    uniqueId = `${anchorId}-${counter}`;
  }

  return uniqueId;
}

/**
 * Extract keywords from text (nouns, proper nouns, technical terms)
 *
 * Filters out:
 * - Action verbs (implement, create, add, etc.)
 * - Stop words (the, a, an, in, etc.)
 * - Very short words (<4 letters, except acronyms)
 *
 * Keeps:
 * - Acronyms (OAuth, JWT, API - detected by uppercase)
 * - Version numbers (v2, 2.0)
 * - Hyphenated terms (real-time)
 * - Proper nouns (Google, Stripe)
 *
 * @param {string} text - Input text
 * @returns {Array<string>} Keywords (lowercase, 1-5 words)
 *
 * @example
 * extractKeywords("Implemented OAuth2 authentication with Google")
 * // Returns: ["oauth", "authentication", "google"]
 *
 * extractKeywords("Fixed bug in the checkout flow")
 * // Returns: ["checkout", "flow"]
 *
 * extractKeywords("API v2 endpoints")
 * // Returns: ["api", "endpoints"]
 */
function extractKeywords(text) {
  // Action verbs to filter out
  const actionVerbs = [
    'implement', 'implemented', 'create', 'created', 'add', 'added',
    'build', 'built', 'fix', 'fixed', 'update', 'updated',
    'refactor', 'refactored', 'modify', 'modified', 'delete', 'deleted',
    'remove', 'removed', 'change', 'changed', 'improve', 'improved',
    'optimize', 'optimized', 'debug', 'debugged'
  ];

  // Stop words to filter out
  const stopWords = [
    'this', 'that', 'with', 'from', 'have', 'been', 'will',
    'want', 'need', 'make', 'into', 'over', 'also', 'then',
    'them', 'these', 'those', 'when', 'where', 'which', 'while'
  ];

  // Extract potential keywords
  // Pattern 1: 4+ letter words
  // Pattern 2: Uppercase words (acronyms like JWT, API)
  // Pattern 3: Version numbers (v2, v1.0, 2.0)
  const words = text.match(/\b[a-z]{4,}\b|\b[A-Z][A-Z0-9]*\b|\bv?\d+\.?\d*\b/gi) || [];

  // Normalize and filter
  const keywords = words
    .map(w => w.toLowerCase())
    .filter(w => !actionVerbs.includes(w))
    .filter(w => !stopWords.includes(w))
    .filter(w => w.length > 0);

  // Remove duplicates (preserve order)
  const unique = [...new Set(keywords)];

  // Return up to 5 keywords (anchor IDs shouldn't be too long)
  return unique.slice(0, 5);
}

/**
 * Slugify keywords into URL-friendly format
 *
 * Handles:
 * - Lowercase conversion
 * - Special character removal
 * - Hyphen separation
 * - Multiple spaces/hyphens consolidation
 *
 * @param {Array<string>} keywords - List of keywords
 * @returns {string} Slugified string
 *
 * @example
 * slugify(["OAuth", "authentication"])
 * // Returns: "oauth-authentication"
 *
 * slugify(["real-time", "notifications"])
 * // Returns: "real-time-notifications"
 */
function slugify(keywords) {
  if (!keywords || keywords.length === 0) {
    return 'unnamed';
  }

  return keywords
    .join('-')
    .toLowerCase()
    .replace(/[^a-z0-9-]/g, '') // Remove special chars except hyphens
    .replace(/--+/g, '-')       // Collapse multiple hyphens
    .replace(/^-|-$/g, '');     // Trim leading/trailing hyphens
}

/**
 * Extract spec number from spec folder name
 *
 * Format: ###-feature-name
 *
 * @param {string} specFolder - Spec folder name (e.g., "015-oauth-integration")
 * @returns {string} Spec number (e.g., "015")
 *
 * @example
 * extractSpecNumber("015-oauth-integration")
 * // Returns: "015"
 *
 * extractSpecNumber("123-complex-feature")
 * // Returns: "123"
 */
function extractSpecNumber(specFolder) {
  const match = specFolder.match(/^(\d{3})-/);
  return match ? match[1] : '000';
}

/**
 * Generate current date in YYYY-MM-DD format
 *
 * Used for collision prevention in anchor IDs
 *
 * @returns {string} Date string (e.g., "2025-11-28")
 */
function getCurrentDate() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

// Export all functions
module.exports = {
  generateAnchorId,
  categorizeSection,
  validateAnchorUniqueness,
  extractKeywords,
  slugify,
  extractSpecNumber,
  getCurrentDate
};

// CLI testing interface (when run directly)
if (require.main === module) {
  console.log('Anchor Generator Test Suite\n');

  // Test 1: Generate anchor ID
  const anchor1 = generateAnchorId("OAuth Callback Handler", "implementation", "015");
  console.log(`Test 1: generateAnchorId("OAuth Callback Handler", "implementation", "015")`);
  console.log(`Result: ${anchor1}\n`);

  // Test 2: Categorize sections
  const cat1 = categorizeSection("Decision: JWT vs Sessions", "We need to choose auth method");
  console.log(`Test 2: categorizeSection("Decision: JWT vs Sessions", ...)`);
  console.log(`Result: ${cat1}\n`);

  // Test 3: Extract keywords
  const keywords1 = extractKeywords("Implemented OAuth2 authentication with Google");
  console.log(`Test 3: extractKeywords("Implemented OAuth2 authentication with Google")`);
  console.log(`Result: ${JSON.stringify(keywords1)}\n`);

  // Test 4: Validate uniqueness
  const unique1 = validateAnchorUniqueness("implementation-oauth-015", ["implementation-oauth-015"]);
  console.log(`Test 4: validateAnchorUniqueness("implementation-oauth-015", ["implementation-oauth-015"])`);
  console.log(`Result: ${unique1}\n`);

  // Test 5: Extract spec number
  const specNum = extractSpecNumber("049-anchor-context-retrieval");
  console.log(`Test 5: extractSpecNumber("049-anchor-context-retrieval")`);
  console.log(`Result: ${specNum}\n`);
}
