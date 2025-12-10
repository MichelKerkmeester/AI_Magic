/**
 * Haiku Preprocessor Module
 *
 * Optional preprocessing layer using Claude Haiku for:
 * - Content summarization (before embedding)
 * - Query expansion (before search)
 * - Trigger phrase extraction
 *
 * DISABLED BY DEFAULT - Requires ANTHROPIC_API_KEY environment variable.
 * Falls back gracefully when API unavailable.
 *
 * @module haiku-preprocessor
 * @version 1.0.0
 */

'use strict';

// ───────────────────────────────────────────────────────────────
// CONFIGURATION
// ───────────────────────────────────────────────────────────────

const HAIKU_MODEL = process.env.MEMORY_HAIKU_MODEL || 'claude-3-haiku-20240307';
const HAIKU_ENABLED = process.env.MEMORY_HAIKU_ENABLED === 'true';
const TIMEOUT_MS = parseInt(process.env.MEMORY_HAIKU_TIMEOUT || '2000', 10);

let anthropicClient = null;
let totalCost = 0;
let callCount = 0;

// Haiku pricing (per 1M tokens) as of Dec 2024
const HAIKU_COST = {
  input: 0.25,   // $0.25 per 1M input tokens
  output: 1.25   // $1.25 per 1M output tokens
};

// ───────────────────────────────────────────────────────────────
// INITIALIZATION
// ───────────────────────────────────────────────────────────────

/**
 * Get or create Anthropic client
 * Returns null if API key not available or Haiku is disabled
 */
function getClient() {
  // Check if explicitly disabled
  if (!HAIKU_ENABLED) {
    return null;
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    // Only warn once
    if (!getClient._warnedNoKey) {
      console.warn('[haiku] No ANTHROPIC_API_KEY set, Haiku preprocessing disabled');
      console.warn('[haiku] Set MEMORY_HAIKU_ENABLED=true and ANTHROPIC_API_KEY to enable');
      getClient._warnedNoKey = true;
    }
    return null;
  }

  if (!anthropicClient) {
    try {
      const Anthropic = require('@anthropic-ai/sdk');
      anthropicClient = new Anthropic({ apiKey });
      console.warn('[haiku] Anthropic client initialized');
    } catch (e) {
      console.warn('[haiku] Failed to initialize Anthropic client:', e.message);
      console.warn('[haiku] Run: npm install @anthropic-ai/sdk');
      return null;
    }
  }

  return anthropicClient;
}

/**
 * Track API usage cost
 * @param {Object} usage - Usage object from API response
 */
function trackCost(usage) {
  if (!usage) return;

  const inputTokens = usage.input_tokens || 0;
  const outputTokens = usage.output_tokens || 0;
  const cost = (inputTokens * HAIKU_COST.input + outputTokens * HAIKU_COST.output) / 1_000_000;

  totalCost += cost;
  callCount++;

  // Log cost periodically
  if (callCount % 10 === 0) {
    console.warn(`[haiku] Session cost: $${totalCost.toFixed(6)} (${callCount} calls)`);
  }
}

// ───────────────────────────────────────────────────────────────
// SUMMARIZATION (For Indexing)
// ───────────────────────────────────────────────────────────────

/**
 * Summarize content for embedding
 *
 * Creates a focused summary that captures key:
 * - Decisions made
 * - Technologies discussed
 * - Problems solved
 * - Outcomes achieved
 *
 * @param {string} content - Full memory content
 * @param {Object} options - Options
 * @param {number} options.maxTokens - Max output tokens (default: 150)
 * @returns {Promise<string>} Summarized content or original if Haiku unavailable
 */
async function summarizeForEmbedding(content, options = {}) {
  const client = getClient();
  if (!client) {
    return content;
  }

  const { maxTokens = 150 } = options;

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);

    const response = await client.messages.create({
      model: HAIKU_MODEL,
      max_tokens: maxTokens,
      messages: [{
        role: 'user',
        content: `Summarize this conversation context in 2-3 sentences, focusing on:
- Key decisions made
- Technologies or approaches discussed
- Problems solved or outcomes achieved

Content:
${content.substring(0, 4000)}

Summary:`
      }]
    }, { signal: controller.signal });

    clearTimeout(timeout);
    trackCost(response.usage);

    const summary = response.content[0]?.text?.trim();
    if (summary && summary.length > 20) {
      console.warn(`[haiku] Summarized ${content.length} chars -> ${summary.length} chars`);
      return summary;
    }

    return content;

  } catch (error) {
    if (error.name === 'AbortError') {
      console.warn('[haiku] Summarization timed out, using original content');
    } else {
      console.warn('[haiku] Summarization failed:', error.message);
    }
    return content;
  }
}

// ───────────────────────────────────────────────────────────────
// QUERY EXPANSION (For Search)
// ───────────────────────────────────────────────────────────────

/**
 * Expand query with synonyms and related terms
 *
 * Helps improve search recall by adding:
 * - Synonyms
 * - Related technical terms
 * - Common variations
 *
 * @param {string} query - Original search query
 * @param {Object} options - Options
 * @param {number} options.maxTokens - Max output tokens (default: 50)
 * @returns {Promise<string>} Expanded query or original if Haiku unavailable
 */
async function expandQuery(query, options = {}) {
  const client = getClient();
  if (!client) {
    return query;
  }

  // Skip expansion for very short or simple queries
  if (!query || query.length < 5 || query.split(/\s+/).length < 2) {
    return query;
  }

  const { maxTokens = 50 } = options;

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);

    const response = await client.messages.create({
      model: HAIKU_MODEL,
      max_tokens: maxTokens,
      messages: [{
        role: 'user',
        content: `Expand this search query with synonyms and related technical terms for better semantic search. Return ONLY the expanded query, no explanation.

Query: "${query}"

Expanded:`
      }]
    }, { signal: controller.signal });

    clearTimeout(timeout);
    trackCost(response.usage);

    const expanded = response.content[0]?.text?.trim();
    if (expanded && expanded.length > query.length) {
      console.warn(`[haiku] Expanded query: "${query}" -> "${expanded}"`);
      return expanded;
    }

    return query;

  } catch (error) {
    if (error.name === 'AbortError') {
      console.warn('[haiku] Query expansion timed out, using original');
    } else {
      console.warn('[haiku] Query expansion failed:', error.message);
    }
    return query;
  }
}

// ───────────────────────────────────────────────────────────────
// TRIGGER PHRASE EXTRACTION
// ───────────────────────────────────────────────────────────────

/**
 * Extract trigger phrases from content
 *
 * Identifies key terms that should trigger this memory in search.
 *
 * @param {string} content - Memory content
 * @returns {Promise<string[]>} Array of trigger phrases (empty if Haiku unavailable)
 */
async function extractTriggerPhrases(content) {
  const client = getClient();
  if (!client) {
    return [];
  }

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);

    const response = await client.messages.create({
      model: HAIKU_MODEL,
      max_tokens: 100,
      messages: [{
        role: 'user',
        content: `Extract 5-10 key search terms from this content that someone might use to find it. Return only the terms, comma-separated, no explanation.

Content:
${content.substring(0, 2000)}

Terms:`
      }]
    }, { signal: controller.signal });

    clearTimeout(timeout);
    trackCost(response.usage);

    const text = response.content[0]?.text?.trim();
    if (text) {
      const phrases = text
        .split(',')
        .map(t => t.trim().toLowerCase())
        .filter(t => t.length > 2 && t.length < 50);

      console.warn(`[haiku] Extracted ${phrases.length} trigger phrases`);
      return phrases.slice(0, 10); // Cap at 10
    }

    return [];

  } catch (error) {
    console.warn('[haiku] Trigger extraction failed:', error.message);
    return [];
  }
}

// ───────────────────────────────────────────────────────────────
// UTILITIES
// ───────────────────────────────────────────────────────────────

/**
 * Check if Haiku is available and enabled
 * @returns {boolean}
 */
function isAvailable() {
  return HAIKU_ENABLED && !!process.env.ANTHROPIC_API_KEY;
}

/**
 * Check if Haiku is explicitly enabled
 * @returns {boolean}
 */
function isEnabled() {
  return HAIKU_ENABLED;
}

/**
 * Get total cost incurred this session
 * @returns {number} Cost in USD
 */
function getTotalCost() {
  return totalCost;
}

/**
 * Get total API call count
 * @returns {number}
 */
function getCallCount() {
  return callCount;
}

/**
 * Reset cost and call counters
 */
function resetCounters() {
  totalCost = 0;
  callCount = 0;
}

/**
 * Get status information
 * @returns {Object} Status object
 */
function getStatus() {
  return {
    enabled: HAIKU_ENABLED,
    available: isAvailable(),
    model: HAIKU_MODEL,
    timeoutMs: TIMEOUT_MS,
    totalCost,
    callCount
  };
}

// ───────────────────────────────────────────────────────────────
// MODULE EXPORTS
// ───────────────────────────────────────────────────────────────

module.exports = {
  // Core functions
  summarizeForEmbedding,
  expandQuery,
  extractTriggerPhrases,

  // Status functions
  isAvailable,
  isEnabled,
  getTotalCost,
  getCallCount,
  resetCounters,
  getStatus,

  // Constants
  HAIKU_MODEL,
  TIMEOUT_MS
};
