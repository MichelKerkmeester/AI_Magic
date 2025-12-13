/**
 * Integration Tests for Hook Surfacing (Trigger Phrase Matching)
 *
 * Tests trigger phrase matching performance and cache behavior
 * with real memory files. Validates <50ms hook execution target.
 *
 * @module tests/integration/hook-surfacing.integration.test
 * @version 10.0.0
 */

'use strict';

const path = require('path');
const fs = require('fs');
const os = require('os');

const libPath = path.join(__dirname, '..', '..', 'lib');
const triggerMatcher = require(path.join(libPath, 'trigger-matcher.js'));
const vectorIndex = require(path.join(libPath, 'vector-index.js'));

// ───────────────────────────────────────────────────────────────
// TEST UTILITIES
// ───────────────────────────────────────────────────────────────

let testsPassed = 0;
let testsFailed = 0;

function assert(condition, message) {
  if (condition) {
    testsPassed++;
    console.log(`  [PASS] ${message}`);
  } else {
    testsFailed++;
    console.log(`  [FAIL] ${message}`);
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
// TEST DATABASE SETUP
// ───────────────────────────────────────────────────────────────

const TEST_DB_PATH = path.join(os.tmpdir(), `integration-hook-${Date.now()}.sqlite`);

// Sample memory data with various trigger phrases
const TEST_MEMORIES = [
  {
    specFolder: 'app-config',
    filePath: '/config/database-setup.md',
    title: 'Database Configuration',
    triggerPhrases: ['database configuration', 'connection pool', 'postgres setup', 'mysql config'],
    importanceWeight: 0.9,
    seedValue: 0.1
  },
  {
    specFolder: 'app-config',
    filePath: '/config/caching-strategy.md',
    title: 'Caching Strategy',
    triggerPhrases: ['caching strategy', 'redis cache', 'cache invalidation', 'ttl settings'],
    importanceWeight: 0.8,
    seedValue: 0.2
  },
  {
    specFolder: 'api-design',
    filePath: '/api/rate-limiting.md',
    title: 'Rate Limiting Guidelines',
    triggerPhrases: ['rate limiting', 'api throttling', 'request limits', 'rate limiter'],
    importanceWeight: 0.85,
    seedValue: 0.3
  },
  {
    specFolder: 'api-design',
    filePath: '/api/pagination.md',
    title: 'Pagination Patterns',
    triggerPhrases: ['pagination', 'cursor pagination', 'offset pagination', 'page size'],
    importanceWeight: 0.7,
    seedValue: 0.4
  },
  {
    specFolder: 'security',
    filePath: '/security/input-validation.md',
    title: 'Input Validation',
    triggerPhrases: ['input validation', 'sanitization', 'sql injection', 'xss prevention'],
    importanceWeight: 0.95,
    seedValue: 0.5
  },
  {
    specFolder: 'security',
    filePath: '/security/encryption.md',
    title: 'Encryption Standards',
    triggerPhrases: ['encryption', 'aes encryption', 'data at rest', 'data in transit'],
    importanceWeight: 0.9,
    seedValue: 0.6
  },
  {
    specFolder: 'testing',
    filePath: '/testing/integration-tests.md',
    title: 'Integration Testing Guide',
    triggerPhrases: ['integration testing', 'test fixtures', 'test database', 'mock services'],
    importanceWeight: 0.75,
    seedValue: 0.7
  },
  {
    specFolder: 'testing',
    filePath: '/testing/unit-tests.md',
    title: 'Unit Testing Best Practices',
    triggerPhrases: ['unit testing', 'test coverage', 'mocking', 'test isolation'],
    importanceWeight: 0.8,
    seedValue: 0.8
  }
];

// Performance threshold in milliseconds (NFR-P03)
const PERFORMANCE_THRESHOLD_MS = 50;

// ───────────────────────────────────────────────────────────────
// TESTS
// ───────────────────────────────────────────────────────────────

async function testTriggerMatchingPerformanceUnder50ms() {
  console.log('Test: trigger phrase matching < 50ms');

  // Test with various prompt lengths
  const prompts = [
    'How do I configure the database?',
    'I need help with caching strategy and redis cache configuration',
    'What are the best practices for rate limiting in our API? Also need info about pagination.',
    'Tell me about input validation and encryption for security compliance. ' +
      'Also need database configuration and caching strategy details.',
    // Long prompt test
    'I am working on a comprehensive update to our system that involves ' +
      'database configuration, caching strategy, rate limiting, pagination, ' +
      'input validation, encryption, integration testing, and unit testing. ' +
      'Please provide guidance on all these topics.'
  ];

  let allUnderThreshold = true;

  for (let i = 0; i < prompts.length; i++) {
    const prompt = prompts[i];
    const start = Date.now();
    const result = triggerMatcher.matchTriggerPhrasesWithStats(prompt);
    const elapsed = Date.now() - start;

    if (elapsed >= PERFORMANCE_THRESHOLD_MS) {
      allUnderThreshold = false;
      console.log(`    Prompt ${i + 1}: ${elapsed}ms (EXCEEDED ${PERFORMANCE_THRESHOLD_MS}ms threshold)`);
    } else {
      console.log(`    Prompt ${i + 1}: ${elapsed}ms - ${result.stats.matchCount} matches`);
    }
  }

  assert(allUnderThreshold, `All prompts matched in < ${PERFORMANCE_THRESHOLD_MS}ms`);

  console.log('[PASS] testTriggerMatchingPerformanceUnder50ms');
}

async function testCacheLoadingPerformance() {
  console.log('Test: cache loading performance');

  // Clear cache to force reload
  triggerMatcher.clearCache();

  const start = Date.now();
  const cache = triggerMatcher.loadTriggerCache();
  const elapsed = Date.now() - start;

  assert(elapsed < 100, `Cache loaded in < 100ms (got ${elapsed}ms)`);
  assert(cache.length > 0, `Cache has entries (got ${cache.length})`);

  console.log('[PASS] testCacheLoadingPerformance');
}

async function testCacheBehaviorTTL() {
  console.log('Test: cache TTL behavior');

  // Ensure cache is loaded
  triggerMatcher.clearCache();
  triggerMatcher.loadTriggerCache();

  const stats1 = triggerMatcher.getCacheStats();
  const timestamp1 = stats1.timestamp;

  // Wait a short time and reload - cache should NOT refresh (still within TTL)
  await new Promise(resolve => setTimeout(resolve, 10));
  triggerMatcher.loadTriggerCache();

  const stats2 = triggerMatcher.getCacheStats();
  const timestamp2 = stats2.timestamp;

  assert(timestamp1 === timestamp2, 'Cache not refreshed within TTL');

  console.log('[PASS] testCacheBehaviorTTL');
}

async function testCacheClearBehavior() {
  console.log('Test: cache clear behavior');

  // Ensure cache is loaded
  triggerMatcher.loadTriggerCache();
  const statsBefore = triggerMatcher.getCacheStats();
  assert(statsBefore.size > 0, 'Cache has entries before clear');

  // Clear cache
  triggerMatcher.clearCache();
  const statsAfter = triggerMatcher.getCacheStats();

  assert(statsAfter.size === 0, 'Cache size is 0 after clear');
  assert(statsAfter.timestamp === 0, 'Cache timestamp is 0 after clear');

  // Reload should work
  triggerMatcher.loadTriggerCache();
  const statsReload = triggerMatcher.getCacheStats();
  assert(statsReload.size > 0, 'Cache reloaded successfully');

  console.log('[PASS] testCacheClearBehavior');
}

async function testMatchingWithRealMemoryFiles() {
  console.log('Test: matching with real memory files');

  // Test single phrase match
  const result1 = triggerMatcher.matchTriggerPhrases('How do I set up database configuration?');
  assert(result1.length > 0, 'Found matches for "database configuration"');
  assert(result1[0].title === 'Database Configuration', 'Correct memory matched');
  assert(result1[0].matchedPhrases.includes('database configuration'), 'Phrase correctly identified');

  // Test multiple phrase match
  const result2 = triggerMatcher.matchTriggerPhrases('Need help with rate limiting and pagination');
  assert(result2.length >= 2, 'Found multiple matches');

  // Test cross-folder matching
  const folders = new Set(result2.map(r => r.specFolder));
  assert(folders.size >= 1, 'Results from spec folders');

  console.log('[PASS] testMatchingWithRealMemoryFiles');
}

async function testMatchingReturnsCorrectMetadata() {
  console.log('Test: matching returns correct metadata');

  const result = triggerMatcher.matchTriggerPhrases('input validation for security');

  assert(result.length > 0, 'Found matches');

  const match = result[0];
  assert(match.memoryId !== undefined, 'Result has memoryId');
  assert(match.specFolder !== undefined, 'Result has specFolder');
  assert(match.filePath !== undefined, 'Result has filePath');
  assert(match.title !== undefined, 'Result has title');
  assert(match.importanceWeight !== undefined, 'Result has importanceWeight');
  assert(Array.isArray(match.matchedPhrases), 'Result has matchedPhrases array');

  console.log('[PASS] testMatchingReturnsCorrectMetadata');
}

async function testMatchingSortsByRelevance() {
  console.log('Test: matching sorts by relevance');

  // Query that matches multiple memories with different phrase counts
  const result = triggerMatcher.matchTriggerPhrases(
    'database configuration connection pool postgres setup'
  );

  assert(result.length > 0, 'Found matches');

  // First result should have more matched phrases
  if (result.length >= 2) {
    assert(
      result[0].matchedPhrases.length >= result[1].matchedPhrases.length,
      'Results sorted by phrase count'
    );
  }

  console.log('[PASS] testMatchingSortsByRelevance');
}

async function testMatchingStatsAccuracy() {
  console.log('Test: matching stats accuracy');

  const prompt = 'caching strategy redis cache';
  const { matches, stats } = triggerMatcher.matchTriggerPhrasesWithStats(prompt);

  assert(stats.promptLength === prompt.length, 'Correct prompt length');
  assert(stats.cacheSize > 0, 'Cache size reported');
  assert(stats.matchCount === matches.length, 'Match count matches');
  assert(typeof stats.matchTimeMs === 'number', 'Match time reported');
  assert(stats.matchTimeMs < PERFORMANCE_THRESHOLD_MS, `Match time < ${PERFORMANCE_THRESHOLD_MS}ms`);

  // Total matched phrases should equal sum across all matches
  const expectedTotal = matches.reduce((sum, m) => sum + m.matchedPhrases.length, 0);
  assert(stats.totalMatchedPhrases === expectedTotal, 'Total matched phrases accurate');

  console.log('[PASS] testMatchingStatsAccuracy');
}

async function testBulkMatchingPerformance() {
  console.log('Test: bulk matching performance (100 iterations)');

  const prompts = [
    'database configuration',
    'caching strategy',
    'rate limiting',
    'input validation',
    'encryption standards'
  ];

  const iterations = 100;
  const start = Date.now();

  for (let i = 0; i < iterations; i++) {
    const prompt = prompts[i % prompts.length];
    triggerMatcher.matchTriggerPhrases(prompt);
  }

  const elapsed = Date.now() - start;
  const avgTime = elapsed / iterations;

  assert(avgTime < 5, `Average match time < 5ms (got ${avgTime.toFixed(2)}ms)`);
  console.log(`  Average time per match: ${avgTime.toFixed(2)}ms`);

  console.log('[PASS] testBulkMatchingPerformance');
}

async function testGetAllPhrasesFromRealData() {
  console.log('Test: getAllPhrases with real data');

  const phrases = triggerMatcher.getAllPhrases();

  assert(Array.isArray(phrases), 'Returns array');
  assert(phrases.length >= 20, `Expected ~32 phrases from 8 memories (got ${phrases.length})`);

  // Check for expected phrases
  const expectedPhrases = ['database configuration', 'caching strategy', 'rate limiting', 'encryption'];
  for (const expected of expectedPhrases) {
    assert(phrases.includes(expected), `Contains "${expected}"`);
  }

  console.log('[PASS] testGetAllPhrasesFromRealData');
}

async function testGetMemoriesByPhraseFromRealData() {
  console.log('Test: getMemoriesByPhrase with real data');

  const memories = triggerMatcher.getMemoriesByPhrase('rate limiting');

  assert(memories.length === 1, `Found exactly 1 memory for "rate limiting" (got ${memories.length})`);
  assert(memories[0].title === 'Rate Limiting Guidelines', 'Correct memory returned');

  console.log('[PASS] testGetMemoriesByPhraseFromRealData');
}

// ───────────────────────────────────────────────────────────────
// CHK084: HOOK-INT-002 - Hook respects max 3 memories limit
// ───────────────────────────────────────────────────────────────

async function testHookMaxThreeMemoriesLimit() {
  console.log('Test: HOOK-INT-002 - Hook respects max 3 memories limit');

  // Create a prompt that matches many memories
  const broadPrompt = `I need help with database configuration, caching strategy,
    rate limiting, pagination, input validation, encryption,
    integration testing, and unit testing.`;

  const result = triggerMatcher.matchTriggerPhrases(broadPrompt, 3);

  assert(Array.isArray(result), 'Returns array');
  assert(result.length <= 3, `Respects max 3 limit (got ${result.length})`);

  // Verify results are sorted by relevance (most matched phrases first)
  if (result.length >= 2) {
    assert(
      result[0].matchedPhrases.length >= result[1].matchedPhrases.length,
      'Results sorted by matched phrase count'
    );
  }

  console.log(`  Matched: ${result.length} memories (max allowed: 3)`);
  console.log('[PASS] testHookMaxThreeMemoriesLimit (CHK084)');
}

async function testHookMaxLimitWithMultipleMatches() {
  console.log('Test: Hook max limit with many matching phrases');

  // Prompt that should match ALL test memories
  const maxMatchPrompt = `database configuration connection pool caching strategy redis cache
    rate limiting api throttling pagination cursor input validation sanitization
    encryption aes integration testing test fixtures unit testing test coverage`;

  // Request only 2 results
  const result = triggerMatcher.matchTriggerPhrases(maxMatchPrompt, 2);

  assert(result.length <= 2, `Respects custom limit of 2 (got ${result.length})`);

  // The results should be the most relevant ones
  if (result.length === 2) {
    console.log(`  Top 2: "${result[0].title}" (${result[0].matchedPhrases.length} phrases), "${result[1].title}" (${result[1].matchedPhrases.length} phrases)`);
  }

  console.log('[PASS] testHookMaxLimitWithMultipleMatches');
}

// ───────────────────────────────────────────────────────────────
// CHK088: HOOK-INT-007 - Hook handles database unavailability
// ───────────────────────────────────────────────────────────────

async function testHookDatabaseUnavailabilityHandling() {
  console.log('Test: HOOK-INT-007 - Hook handles database unavailability');

  // Clear the trigger cache to force reload from DB
  triggerMatcher.clearCache();

  // Close the database
  vectorIndex.closeDb();

  let errorHandled = false;
  let resultOrError = null;

  try {
    // Attempt to match triggers with no database
    resultOrError = triggerMatcher.matchTriggerPhrases('database configuration');
  } catch (error) {
    errorHandled = true;
    resultOrError = error;
  }

  // The hook should either:
  // 1. Return empty array (graceful degradation)
  // 2. Throw a handled error

  const gracefulDegradation = Array.isArray(resultOrError) && resultOrError.length === 0;
  const handledException = errorHandled;

  assert(
    gracefulDegradation || handledException,
    `Hook handles DB unavailability (graceful: ${gracefulDegradation}, exception: ${handledException})`
  );

  if (gracefulDegradation) {
    console.log('  Result: Graceful degradation - returned empty array');
  } else if (handledException) {
    console.log(`  Result: Handled exception - ${resultOrError.message}`);
  }

  // Reopen database and restore test data
  vectorIndex.initializeDb(TEST_DB_PATH);

  // Re-index test memories
  for (const memory of TEST_MEMORIES) {
    const embedding = createTestEmbedding(memory.seedValue);
    vectorIndex.indexMemory({
      specFolder: memory.specFolder,
      filePath: memory.filePath,
      title: memory.title,
      triggerPhrases: memory.triggerPhrases,
      importanceWeight: memory.importanceWeight,
      embedding
    });
  }

  // Clear and reload cache
  triggerMatcher.clearCache();
  triggerMatcher.loadTriggerCache();

  console.log('[PASS] testHookDatabaseUnavailabilityHandling (CHK088)');
}

async function testHookRecoversAfterDbReconnect() {
  console.log('Test: Hook recovers after database reconnect');

  // Normal query should work after recovery
  const result = triggerMatcher.matchTriggerPhrases('database configuration');

  assert(result.length > 0, 'Hook works after DB recovery');
  assert(result[0].title === 'Database Configuration', 'Returns correct memory');

  console.log('[PASS] testHookRecoversAfterDbReconnect');
}

// ───────────────────────────────────────────────────────────────
// MAIN
// ───────────────────────────────────────────────────────────────

async function runTests() {
  console.log('\n=== Hook Surfacing Integration Tests ===\n');

  // Setup
  console.log('0. Setup - Initializing test database and indexing memories\n');

  if (fs.existsSync(TEST_DB_PATH)) {
    fs.unlinkSync(TEST_DB_PATH);
  }

  vectorIndex.initializeDb(TEST_DB_PATH);

  // Index test memories
  for (const memory of TEST_MEMORIES) {
    const embedding = createTestEmbedding(memory.seedValue);
    vectorIndex.indexMemory({
      specFolder: memory.specFolder,
      filePath: memory.filePath,
      title: memory.title,
      triggerPhrases: memory.triggerPhrases,
      importanceWeight: memory.importanceWeight,
      embedding
    });
    console.log(`  - Indexed: ${memory.title} (${memory.triggerPhrases.length} trigger phrases)`);
  }

  console.log(`\n  Total memories indexed: ${vectorIndex.getMemoryCount()}`);

  // Clear any existing cache
  triggerMatcher.clearCache();

  console.log('\n--- Running Tests ---\n');

  // Run tests
  await testCacheLoadingPerformance();
  await testCacheBehaviorTTL();
  await testCacheClearBehavior();
  await testMatchingWithRealMemoryFiles();
  await testMatchingReturnsCorrectMetadata();
  await testMatchingSortsByRelevance();
  await testMatchingStatsAccuracy();
  await testTriggerMatchingPerformanceUnder50ms();
  await testBulkMatchingPerformance();
  await testGetAllPhrasesFromRealData();
  await testGetMemoriesByPhraseFromRealData();

  // CHK084: HOOK-INT-002 - Hook respects max 3 memories limit
  await testHookMaxThreeMemoriesLimit();
  await testHookMaxLimitWithMultipleMatches();

  // CHK088: HOOK-INT-007 - Hook handles database unavailability
  // Note: Run these tests last as they close/reopen the database
  await testHookDatabaseUnavailabilityHandling();
  await testHookRecoversAfterDbReconnect();

  // Cleanup
  console.log('\n--- Cleanup ---\n');
  triggerMatcher.clearCache();
  vectorIndex.closeDb();

  if (fs.existsSync(TEST_DB_PATH)) {
    fs.unlinkSync(TEST_DB_PATH);
    if (fs.existsSync(TEST_DB_PATH + '-wal')) fs.unlinkSync(TEST_DB_PATH + '-wal');
    if (fs.existsSync(TEST_DB_PATH + '-shm')) fs.unlinkSync(TEST_DB_PATH + '-shm');
  }

  console.log('  Test database cleaned up');
  console.log('  Trigger cache cleared');

  // Summary
  console.log('\n=== Summary ===');
  console.log(`Passed: ${testsPassed}`);
  console.log(`Failed: ${testsFailed}`);

  if (testsFailed > 0) {
    process.exit(1);
  }
}

// Run tests
runTests().catch(err => {
  console.error('Test error:', err);
  triggerMatcher.clearCache();
  vectorIndex.closeDb();
  process.exit(1);
});
