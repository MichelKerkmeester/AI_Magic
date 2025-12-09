/**
 * Unit Tests for Trigger Extractor
 *
 * Tests TF-IDF + N-gram hybrid algorithm for trigger phrase extraction.
 * Covers preprocessing, tokenization, n-gram extraction, scoring, and deduplication.
 *
 * @module tests/trigger-extractor.test
 */

'use strict';

const path = require('path');
const libPath = path.join(__dirname, '..', 'lib');
const triggerExtractor = require(path.join(libPath, 'trigger-extractor.js'));

// ───────────────────────────────────────────────────────────────
// TEST UTILITIES
// ───────────────────────────────────────────────────────────────

let testsPassed = 0;
let testsFailed = 0;

function assert(condition, message) {
  if (condition) {
    testsPassed++;
    console.log(`  ✓ ${message}`);
  } else {
    testsFailed++;
    console.log(`  ✗ ${message}`);
  }
}

function assertArrayContains(arr, item, message) {
  assert(arr.includes(item), message);
}

function assertArrayNotContains(arr, item, message) {
  assert(!arr.includes(item), message);
}

// ───────────────────────────────────────────────────────────────
// TEST DATA
// ───────────────────────────────────────────────────────────────

const SAMPLE_MARKDOWN = `
# Semantic Memory Upgrade

This document describes the semantic memory upgrade for the conversation
context system. The upgrade adds vector embeddings and semantic search
capabilities to improve memory retrieval.

## Key Features

- **Vector Embeddings**: Generate 384-dimensional vectors using MiniLM
- **Semantic Search**: Find memories by meaning, not just keywords
- **Trigger Phrases**: Extract important phrases for proactive surfacing
- **Multi-concept Search**: Search across multiple concepts simultaneously

## Implementation

The implementation uses sqlite-vec for vector storage and Hugging Face
Transformers for local embedding generation. No external API calls required.

\`\`\`javascript
const embedding = await generateEmbedding(text);
vectorIndex.indexMemory({ embedding });
\`\`\`

The vector database stores embeddings alongside metadata for efficient retrieval.
`;

const SAMPLE_SHORT = 'Too short for extraction.';

const SAMPLE_TECH_HEAVY = `
This function creates a variable and returns the result.
The file contains a class with a method that takes a parameter.
The code uses import and export statements for module handling.
`;

// ───────────────────────────────────────────────────────────────
// TESTS
// ───────────────────────────────────────────────────────────────

function runTests() {
  console.log('\n=== Trigger Extractor Tests ===\n');

  // Test 1: Module exports
  console.log('1. Module Exports');
  assert(typeof triggerExtractor.extractTriggerPhrases === 'function', 'extractTriggerPhrases exported');
  assert(typeof triggerExtractor.extractTriggerPhrasesWithStats === 'function', 'extractTriggerPhrasesWithStats exported');
  assert(typeof triggerExtractor.removeMarkdown === 'function', 'removeMarkdown exported');
  assert(typeof triggerExtractor.tokenize === 'function', 'tokenize exported');
  assert(typeof triggerExtractor.filterStopWords === 'function', 'filterStopWords exported');
  assert(typeof triggerExtractor.CONFIG === 'object', 'CONFIG exported');

  // Test 2: Stop word sets
  console.log('\n2. Stop Word Sets');
  assert(triggerExtractor.STOP_WORDS_ENGLISH instanceof Set, 'STOP_WORDS_ENGLISH is a Set');
  assert(triggerExtractor.STOP_WORDS_TECH instanceof Set, 'STOP_WORDS_TECH is a Set');
  assert(triggerExtractor.STOP_WORDS_ARTIFACTS instanceof Set, 'STOP_WORDS_ARTIFACTS is a Set');
  assert(triggerExtractor.STOP_WORDS_ENGLISH.has('the'), 'English stops contain "the"');
  assert(triggerExtractor.STOP_WORDS_TECH.has('function'), 'Tech stops contain "function"');
  assert(triggerExtractor.STOP_WORDS_ARTIFACTS.has('summary'), 'Artifact stops contain "summary"');

  // Test 3: Markdown removal
  console.log('\n3. Markdown Removal');
  const mdInput = '# Header\n**bold** and `code` with [link](url)';
  const cleaned = triggerExtractor.removeMarkdown(mdInput);
  assert(!cleaned.includes('#'), 'Headers removed');
  assert(!cleaned.includes('**'), 'Bold markers removed');
  assert(!cleaned.includes('`'), 'Inline code removed');
  assert(!cleaned.includes('['), 'Links removed');
  assert(cleaned.includes('Header'), 'Header text preserved');
  assert(cleaned.includes('bold'), 'Bold text preserved');
  assert(cleaned.includes('link'), 'Link text preserved');

  // Test 4: Code block removal
  console.log('\n4. Code Block Removal');
  const codeInput = 'Text before ```javascript\nconst x = 1;\n``` Text after';
  const codeRemoved = triggerExtractor.removeMarkdown(codeInput);
  assert(!codeRemoved.includes('const x'), 'Code block content removed');
  assert(codeRemoved.includes('Text before'), 'Text before preserved');
  assert(codeRemoved.includes('Text after'), 'Text after preserved');

  // Test 5: Tokenization
  console.log('\n5. Tokenization');
  const tokens = triggerExtractor.tokenize('Hello World, this is a TEST! Numbers: 123');
  assert(Array.isArray(tokens), 'Returns array');
  assert(tokens.includes('hello'), 'Lowercase conversion');
  assert(tokens.includes('world'), 'Contains word "world"');
  assert(tokens.includes('test'), 'Contains word "test"');
  assert(!tokens.includes('123'), 'Numbers filtered');
  assert(!tokens.includes('is'), 'Short words filtered (< min length)');

  // Test 6: Stop word filtering
  console.log('\n6. Stop Word Filtering');
  const rawTokens = ['the', 'semantic', 'memory', 'is', 'great', 'for', 'search'];
  const filtered = triggerExtractor.filterStopWords(rawTokens);
  assert(!filtered.includes('the'), '"the" filtered');
  assert(!filtered.includes('is'), '"is" filtered');
  assert(!filtered.includes('for'), '"for" filtered');
  assert(filtered.includes('semantic'), '"semantic" preserved');
  assert(filtered.includes('memory'), '"memory" preserved');
  assert(filtered.includes('great'), '"great" preserved');
  assert(filtered.includes('search'), '"search" preserved');

  // Test 7: N-gram extraction
  console.log('\n7. N-gram Extraction');
  const ngramTokens = ['semantic', 'memory', 'upgrade', 'semantic', 'memory'];
  const unigrams = triggerExtractor.extractNgrams(ngramTokens, 1);
  const bigrams = triggerExtractor.extractNgrams(ngramTokens, 2);
  const trigrams = triggerExtractor.extractNgrams(ngramTokens, 3);

  assert(unigrams.get('semantic') === 2, 'Unigram "semantic" count is 2');
  assert(unigrams.get('memory') === 2, 'Unigram "memory" count is 2');
  assert(unigrams.get('upgrade') === 1, 'Unigram "upgrade" count is 1');
  assert(bigrams.get('semantic memory') === 2, 'Bigram "semantic memory" count is 2');
  assert(trigrams.get('semantic memory upgrade') === 1, 'Trigram count is 1');

  // Test 8: Empty/null input handling
  console.log('\n8. Empty/Null Input Handling');
  assert(triggerExtractor.extractTriggerPhrases(null).length === 0, 'Null returns empty array');
  assert(triggerExtractor.extractTriggerPhrases(undefined).length === 0, 'Undefined returns empty array');
  assert(triggerExtractor.extractTriggerPhrases('').length === 0, 'Empty string returns empty array');
  assert(triggerExtractor.extractTriggerPhrases(SAMPLE_SHORT).length === 0, 'Short text returns empty array');

  // Test 9: Main extraction from sample
  console.log('\n9. Main Extraction');
  const phrases = triggerExtractor.extractTriggerPhrases(SAMPLE_MARKDOWN);
  assert(Array.isArray(phrases), 'Returns array');
  assert(phrases.length >= 5, `At least 5 phrases extracted (got ${phrases.length})`);
  assert(phrases.length <= 15, `At most 15 phrases (got ${phrases.length})`);
  assert(phrases.every(p => typeof p === 'string'), 'All phrases are strings');
  assert(phrases.every(p => p === p.toLowerCase()), 'All phrases are lowercase');

  // Test 10: Expected phrases from sample
  console.log('\n10. Expected Phrases');
  const phrasesLower = phrases.map(p => p.toLowerCase());
  // These should appear based on frequency in the sample
  const hasSemanticRelated = phrasesLower.some(p => p.includes('semantic'));
  const hasMemoryRelated = phrasesLower.some(p => p.includes('memory'));
  const hasVectorRelated = phrasesLower.some(p => p.includes('vector') || p.includes('embedding'));
  assert(hasSemanticRelated, 'Contains semantic-related phrase');
  assert(hasMemoryRelated, 'Contains memory-related phrase');
  assert(hasVectorRelated, 'Contains vector/embedding-related phrase');

  // Test 11: Tech stop word filtering
  console.log('\n11. Tech Stop Word Filtering');
  const techPhrases = triggerExtractor.extractTriggerPhrases(SAMPLE_TECH_HEAVY);
  // Should filter out phrases that are entirely tech stop words
  const hasPureFunction = techPhrases.some(p => p === 'function');
  const hasPureVariable = techPhrases.some(p => p === 'variable');
  assert(!hasPureFunction, '"function" alone is filtered');
  assert(!hasPureVariable, '"variable" alone is filtered');

  // Test 12: Deduplication
  console.log('\n12. Deduplication');
  const candidates = [
    { phrase: 'semantic memory upgrade', score: 0.9 },
    { phrase: 'semantic memory', score: 0.8 },
    { phrase: 'memory', score: 0.7 },
    { phrase: 'vector search', score: 0.6 }
  ];
  const deduped = triggerExtractor.deduplicateSubstrings(candidates);
  assert(deduped.length < candidates.length, 'Deduplication reduces count');
  // Higher scoring superset should take precedence
  const hasUpgrade = deduped.some(c => c.phrase === 'semantic memory upgrade');
  assert(hasUpgrade, 'Higher-scoring phrase preserved');

  // Test 13: Scoring with length bonus
  console.log('\n13. Scoring with Length Bonus');
  const ngrams = [
    { phrase: 'test', count: 5 },
    { phrase: 'testing', count: 3 }
  ];
  const scored1 = triggerExtractor.scoreNgrams(ngrams, 1.0, 100);
  const scored2 = triggerExtractor.scoreNgrams(ngrams, 1.5, 100);

  assert(scored1[0].score === 1.0, 'Max count gets score 1.0 with bonus 1.0');
  assert(scored2[0].score === 1.5, 'Max count gets score 1.5 with bonus 1.5');
  assert(scored1[0].score < scored2[0].score, 'Length bonus increases score');

  // Test 14: With stats
  console.log('\n14. Extraction with Stats');
  const result = triggerExtractor.extractTriggerPhrasesWithStats(SAMPLE_MARKDOWN);
  assert(Array.isArray(result.phrases), 'Has phrases array');
  assert(typeof result.stats === 'object', 'Has stats object');
  assert(typeof result.stats.inputLength === 'number', 'Stats has inputLength');
  assert(typeof result.stats.tokenCount === 'number', 'Stats has tokenCount');
  assert(typeof result.stats.phraseCount === 'number', 'Stats has phraseCount');
  assert(typeof result.stats.extractionTimeMs === 'number', 'Stats has extractionTimeMs');

  // Test 15: Performance
  console.log('\n15. Performance Test');
  const longText = SAMPLE_MARKDOWN.repeat(20); // ~20KB
  const perfStart = Date.now();
  triggerExtractor.extractTriggerPhrases(longText);
  const perfTime = Date.now() - perfStart;
  assert(perfTime < 100, `Extraction <100ms (got ${perfTime}ms)`);

  // Test 16: N-gram count filtering
  console.log('\n16. N-gram Count Filtering');
  const countNgrams = triggerExtractor.countNgrams(['a', 'b', 'c', 'd', 'e'], 1);
  // Single occurrences should be filtered (MIN_FREQUENCY = 2)
  assert(countNgrams.length === 0, 'Single-occurrence ngrams filtered');

  const countNgrams2 = triggerExtractor.countNgrams(['a', 'a', 'b', 'b', 'c'], 1);
  assert(countNgrams2.length === 2, 'Only repeated ngrams kept');

  // Summary
  console.log('\n=== Summary ===');
  console.log(`Passed: ${testsPassed}`);
  console.log(`Failed: ${testsFailed}`);

  if (testsFailed > 0) {
    process.exit(1);
  }
}

// ───────────────────────────────────────────────────────────────
// RUN
// ───────────────────────────────────────────────────────────────

runTests();
