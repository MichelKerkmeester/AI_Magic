/**
 * Unit Tests for Trigger Matcher
 *
 * Tests exact string matching for proactive memory surfacing.
 * Covers cache loading, phrase matching, word boundaries, and performance.
 *
 * @module tests/trigger-matcher.test
 */

'use strict';

const path = require('path');
const fs = require('fs');
const os = require('os');

const libPath = path.join(__dirname, '..', 'lib');
const triggerMatcher = require(path.join(libPath, 'trigger-matcher.js'));
const vectorIndex = require(path.join(libPath, 'vector-index.js'));
const embeddings = require(path.join(libPath, 'embeddings.js'));

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

function createTestEmbedding(seed = 0.1) {
  const embedding = new Float32Array(384);
  for (let i = 0; i < 384; i++) {
    embedding[i] = Math.sin(seed * (i + 1)) * 0.5;
  }
  const mag = Math.sqrt(embedding.reduce((s, v) => s + v * v, 0));
  for (let i = 0; i < 384; i++) {
    embedding[i] /= mag;
  }
  return embedding;
}

// ───────────────────────────────────────────────────────────────
// TEST DATABASE
// ───────────────────────────────────────────────────────────────

const TEST_DB_PATH = path.join(os.tmpdir(), `test-trigger-${Date.now()}.sqlite`);

// ───────────────────────────────────────────────────────────────
// TESTS
// ───────────────────────────────────────────────────────────────

async function runTests() {
  console.log('\n=== Trigger Matcher Tests ===\n');

  // Cleanup any existing test DB
  if (fs.existsSync(TEST_DB_PATH)) {
    fs.unlinkSync(TEST_DB_PATH);
  }

  // Initialize test database
  vectorIndex.initializeDb(TEST_DB_PATH);

  // Test 1: Module exports
  console.log('1. Module Exports');
  assert(typeof triggerMatcher.matchTriggerPhrases === 'function', 'matchTriggerPhrases exported');
  assert(typeof triggerMatcher.matchTriggerPhrasesWithStats === 'function', 'matchTriggerPhrasesWithStats exported');
  assert(typeof triggerMatcher.loadTriggerCache === 'function', 'loadTriggerCache exported');
  assert(typeof triggerMatcher.clearCache === 'function', 'clearCache exported');
  assert(typeof triggerMatcher.getCacheStats === 'function', 'getCacheStats exported');
  assert(typeof triggerMatcher.CONFIG === 'object', 'CONFIG exported');

  // Test 2: Configuration
  console.log('\n2. Configuration');
  assert(triggerMatcher.CONFIG.CACHE_TTL_MS === 60000, 'Cache TTL is 60 seconds');
  assert(triggerMatcher.CONFIG.DEFAULT_LIMIT === 3, 'Default limit is 3');
  assert(triggerMatcher.CONFIG.WARN_THRESHOLD_MS === 30, 'Warn threshold is 30ms');

  // Test 3: Regex escaping
  console.log('\n3. Regex Escaping');
  assert(triggerMatcher.escapeRegex('test') === 'test', 'Simple string unchanged');
  assert(triggerMatcher.escapeRegex('test.js') === 'test\\.js', 'Dot escaped');
  assert(triggerMatcher.escapeRegex('a*b') === 'a\\*b', 'Asterisk escaped');
  assert(triggerMatcher.escapeRegex('(foo)') === '\\(foo\\)', 'Parens escaped');
  assert(triggerMatcher.escapeRegex('[a-z]') === '\\[a-z\\]', 'Brackets escaped');

  // Test 4: Word boundary matching
  console.log('\n4. Word Boundary Matching');
  assert(triggerMatcher.matchPhraseWithBoundary('hello world', 'hello'), 'Matches at start');
  assert(triggerMatcher.matchPhraseWithBoundary('hello world', 'world'), 'Matches at end');
  assert(triggerMatcher.matchPhraseWithBoundary('say hello there', 'hello'), 'Matches in middle');
  assert(!triggerMatcher.matchPhraseWithBoundary('helloworld', 'hello'), 'No match without boundary');
  assert(!triggerMatcher.matchPhraseWithBoundary('othello', 'hello'), 'No match within word');
  assert(triggerMatcher.matchPhraseWithBoundary('HELLO world', 'hello'), 'Case insensitive');

  // Test 5: Multi-word phrase matching
  console.log('\n5. Multi-word Phrase Matching');
  assert(triggerMatcher.matchPhraseWithBoundary('the semantic memory system', 'semantic memory'), 'Multi-word match');
  assert(!triggerMatcher.matchPhraseWithBoundary('semantic x memory', 'semantic memory'), 'No match with word between');

  // Test 6: Empty cache handling
  console.log('\n6. Empty Cache Handling');
  triggerMatcher.clearCache();
  const emptyResult = triggerMatcher.matchTriggerPhrases('test query');
  assert(Array.isArray(emptyResult), 'Returns array');
  assert(emptyResult.length === 0, 'Empty result for empty cache');

  // Test 7: Add test data
  console.log('\n7. Adding Test Data');
  const embedding1 = createTestEmbedding(0.1);
  const id1 = vectorIndex.indexMemory({
    specFolder: 'test-spec-1',
    filePath: '/test/memory1.md',
    title: 'Semantic Memory Test',
    embedding: embedding1,
    triggerPhrases: ['semantic memory', 'vector search', 'embedding generation'],
    importanceWeight: 0.9
  });
  assert(id1 > 0, `Memory 1 created with id ${id1}`);

  const embedding2 = createTestEmbedding(0.2);
  const id2 = vectorIndex.indexMemory({
    specFolder: 'test-spec-2',
    filePath: '/test/memory2.md',
    title: 'Database Testing',
    embedding: embedding2,
    triggerPhrases: ['database testing', 'sqlite operations', 'vector search'],
    importanceWeight: 0.7
  });
  assert(id2 > 0, `Memory 2 created with id ${id2}`);

  const embedding3 = createTestEmbedding(0.3);
  const id3 = vectorIndex.indexMemory({
    specFolder: 'test-spec-3',
    filePath: '/test/memory3.md',
    title: 'API Integration',
    embedding: embedding3,
    triggerPhrases: ['api integration', 'rest endpoints'],
    importanceWeight: 0.5
  });
  assert(id3 > 0, `Memory 3 created with id ${id3}`);

  // Test 8: Cache loading
  console.log('\n8. Cache Loading');
  triggerMatcher.clearCache();
  const cache = triggerMatcher.loadTriggerCache();
  assert(Array.isArray(cache), 'Cache is array');
  assert(cache.length >= 8, `Cache has at least 8 entries (got ${cache.length})`);
  const stats = triggerMatcher.getCacheStats();
  assert(stats.size >= 8, 'Cache stats show correct size');
  assert(stats.timestamp > 0, 'Cache timestamp set');

  // Test 9: Simple phrase matching
  console.log('\n9. Simple Phrase Matching');
  const matches1 = triggerMatcher.matchTriggerPhrases('Help me with semantic memory');
  assert(matches1.length >= 1, `At least 1 match for "semantic memory" (got ${matches1.length})`);
  assert(matches1[0].matchedPhrases.includes('semantic memory'), 'Matched phrase present');

  // Test 10: Multiple phrase matching
  console.log('\n10. Multiple Phrase Matching');
  const matches2 = triggerMatcher.matchTriggerPhrases('I need vector search for my semantic memory system');
  assert(matches2.length >= 1, 'At least 1 match');
  const topMatch = matches2[0];
  assert(topMatch.matchedPhrases.length >= 2, `Top match has multiple phrases (got ${topMatch.matchedPhrases.length})`);

  // Test 11: Cross-memory phrase matching
  console.log('\n11. Cross-Memory Matching');
  const matches3 = triggerMatcher.matchTriggerPhrases('vector search');
  // Both memory1 and memory2 have "vector search"
  assert(matches3.length >= 2, `At least 2 matches for shared phrase (got ${matches3.length})`);

  // Test 12: No match scenario
  console.log('\n12. No Match Scenario');
  const noMatches = triggerMatcher.matchTriggerPhrases('completely unrelated query about cooking');
  assert(noMatches.length === 0, 'No matches for unrelated query');

  // Test 13: Null/empty input
  console.log('\n13. Null/Empty Input');
  assert(triggerMatcher.matchTriggerPhrases(null).length === 0, 'Null returns empty');
  assert(triggerMatcher.matchTriggerPhrases(undefined).length === 0, 'Undefined returns empty');
  assert(triggerMatcher.matchTriggerPhrases('').length === 0, 'Empty string returns empty');

  // Test 14: Limit parameter
  console.log('\n14. Limit Parameter');
  const limited = triggerMatcher.matchTriggerPhrases('vector search semantic memory api integration', 1);
  assert(limited.length <= 1, 'Respects limit of 1');

  const unlimited = triggerMatcher.matchTriggerPhrases('vector search semantic memory api integration', 10);
  assert(unlimited.length <= 3, 'Returns max available');

  // Test 15: Importance weight sorting
  console.log('\n15. Importance Weight Sorting');
  // If matches have same phrase count, should sort by importance
  const importanceSorted = triggerMatcher.matchTriggerPhrases('vector search');
  if (importanceSorted.length >= 2) {
    const first = importanceSorted[0];
    const second = importanceSorted[1];
    // If same phrase count, first should have higher importance
    if (first.matchedPhrases.length === second.matchedPhrases.length) {
      assert(first.importanceWeight >= second.importanceWeight, 'Sorted by importance weight');
    } else {
      assert(first.matchedPhrases.length >= second.matchedPhrases.length, 'Sorted by phrase count first');
    }
  } else {
    assert(true, 'Not enough matches to test sorting');
  }

  // Test 16: With stats
  console.log('\n16. Matching with Stats');
  const withStats = triggerMatcher.matchTriggerPhrasesWithStats('semantic memory');
  assert(Array.isArray(withStats.matches), 'Has matches array');
  assert(typeof withStats.stats === 'object', 'Has stats object');
  assert(typeof withStats.stats.promptLength === 'number', 'Stats has promptLength');
  assert(typeof withStats.stats.cacheSize === 'number', 'Stats has cacheSize');
  assert(typeof withStats.stats.matchCount === 'number', 'Stats has matchCount');
  assert(typeof withStats.stats.matchTimeMs === 'number', 'Stats has matchTimeMs');

  // Test 17: Get all phrases
  console.log('\n17. Get All Phrases');
  const allPhrases = triggerMatcher.getAllPhrases();
  assert(Array.isArray(allPhrases), 'Returns array');
  assert(allPhrases.length >= 7, `Has expected phrases (got ${allPhrases.length})`);
  assert(allPhrases.includes('semantic memory'), 'Contains "semantic memory"');
  assert(allPhrases.includes('vector search'), 'Contains "vector search"');

  // Test 18: Get memories by phrase
  console.log('\n18. Get Memories by Phrase');
  const memsByPhrase = triggerMatcher.getMemoriesByPhrase('vector search');
  assert(memsByPhrase.length >= 2, `Multiple memories for "vector search" (got ${memsByPhrase.length})`);
  assert(memsByPhrase.every(m => m.memoryId && m.specFolder), 'All have required fields');

  // Test 19: Performance test
  console.log('\n19. Performance Test');
  const longPrompt = 'semantic memory '.repeat(100); // Long prompt
  const perfStart = Date.now();
  for (let i = 0; i < 100; i++) {
    triggerMatcher.matchTriggerPhrases(longPrompt);
  }
  const perfTime = Date.now() - perfStart;
  const avgTime = perfTime / 100;
  assert(avgTime < 50, `Average match time <50ms (got ${avgTime.toFixed(2)}ms)`);

  // Test 20: Cache TTL simulation
  console.log('\n20. Cache TTL');
  const statsBeforeRefresh = triggerMatcher.getCacheStats();
  const originalTimestamp = statsBeforeRefresh.timestamp;
  // Cache should not refresh immediately
  triggerMatcher.loadTriggerCache();
  const statsAfterLoad = triggerMatcher.getCacheStats();
  assert(statsAfterLoad.timestamp === originalTimestamp, 'Cache not refreshed when still valid');

  // Test 21: Case insensitivity
  console.log('\n21. Case Insensitivity');
  const upperMatch = triggerMatcher.matchTriggerPhrases('SEMANTIC MEMORY');
  const lowerMatch = triggerMatcher.matchTriggerPhrases('semantic memory');
  assert(upperMatch.length === lowerMatch.length, 'Same results for upper/lower case');

  // Test 22: Partial word protection
  console.log('\n22. Partial Word Protection');
  const partialMatch = triggerMatcher.matchTriggerPhrases('semanticmemory'); // No space
  assert(partialMatch.length === 0, 'No match for concatenated words');

  // Cleanup
  console.log('\n23. Cleanup');
  vectorIndex.closeDb();
  if (fs.existsSync(TEST_DB_PATH)) {
    fs.unlinkSync(TEST_DB_PATH);
    if (fs.existsSync(TEST_DB_PATH + '-wal')) fs.unlinkSync(TEST_DB_PATH + '-wal');
    if (fs.existsSync(TEST_DB_PATH + '-shm')) fs.unlinkSync(TEST_DB_PATH + '-shm');
  }
  assert(!fs.existsSync(TEST_DB_PATH), 'Test database cleaned up');

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

runTests().catch(err => {
  console.error('Test error:', err);
  vectorIndex.closeDb();
  process.exit(1);
});
