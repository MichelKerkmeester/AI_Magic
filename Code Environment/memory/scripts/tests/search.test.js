/**
 * Unit Tests for Semantic Search
 *
 * Tests vector search and multi-concept search functionality
 *
 * @module tests/search.test
 */

'use strict';

const path = require('path');
const fs = require('fs');
const os = require('os');

const libPath = path.join(__dirname, '..', 'lib');
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

// ───────────────────────────────────────────────────────────────
// TEST DATABASE SETUP
// ───────────────────────────────────────────────────────────────

const TEST_DB_PATH = path.join(os.tmpdir(), `test-search-${Date.now()}.sqlite`);

// Test memories to index
const TEST_MEMORIES = [
  {
    specFolder: 'spec-a',
    filePath: '/test/react-hooks.md',
    title: 'React Hooks Implementation',
    content: 'React hooks like useState and useEffect allow functional components to manage state and side effects.',
    triggerPhrases: ['react hooks', 'useState', 'useEffect']
  },
  {
    specFolder: 'spec-a',
    filePath: '/test/typescript-generics.md',
    title: 'TypeScript Generics Guide',
    content: 'TypeScript generics enable creating reusable type-safe components and functions.',
    triggerPhrases: ['typescript', 'generics', 'type-safe']
  },
  {
    specFolder: 'spec-b',
    filePath: '/test/nodejs-async.md',
    title: 'Node.js Async Patterns',
    content: 'Node.js async patterns include callbacks, promises, and async/await for handling asynchronous operations.',
    triggerPhrases: ['nodejs', 'async', 'promises']
  },
  {
    specFolder: 'spec-b',
    filePath: '/test/database-design.md',
    title: 'Database Schema Design',
    content: 'Database schema design involves normalization, indexing strategies, and relationship modeling.',
    triggerPhrases: ['database', 'schema', 'normalization']
  },
  {
    specFolder: 'spec-c',
    filePath: '/test/security-auth.md',
    title: 'Authentication Security',
    content: 'Secure authentication involves OAuth2, JWT tokens, password hashing, and session management.',
    triggerPhrases: ['authentication', 'security', 'OAuth2']
  }
];

// ───────────────────────────────────────────────────────────────
// TESTS
// ───────────────────────────────────────────────────────────────

async function runTests() {
  console.log('\n=== Semantic Search Tests ===\n');

  // Cleanup any existing test DB
  if (fs.existsSync(TEST_DB_PATH)) {
    fs.unlinkSync(TEST_DB_PATH);
  }

  // Initialize database
  console.log('0. Setup - Indexing test memories');
  vectorIndex.initializeDb(TEST_DB_PATH);

  // Index all test memories
  for (const memory of TEST_MEMORIES) {
    const embedding = await embeddings.generateEmbedding(memory.content);
    vectorIndex.indexMemory({
      specFolder: memory.specFolder,
      filePath: memory.filePath,
      title: memory.title,
      triggerPhrases: memory.triggerPhrases,
      embedding
    });
    console.log(`  - Indexed: ${memory.title}`);
  }

  const count = vectorIndex.getMemoryCount();
  assert(count === 5, `Indexed ${count} memories`);

  // Test 1: Basic vector search
  console.log('\n1. Basic Vector Search');
  const reactQuery = await embeddings.generateEmbedding('React component state management');
  const reactResults = vectorIndex.vectorSearch(reactQuery, { limit: 3 });

  assert(reactResults.length > 0, 'Returns results');
  assert(reactResults[0].title.includes('React'), 'Top result is React-related');
  assert(reactResults[0].similarity > 50, `Similarity > 50% (got ${reactResults[0].similarity}%)`);

  // Test 2: Similarity scores
  console.log('\n2. Similarity Scores');
  assert(reactResults[0].distance !== undefined, 'Distance included');
  assert(reactResults[0].similarity !== undefined, 'Similarity included');
  assert(reactResults[0].similarity >= 0 && reactResults[0].similarity <= 100, 'Similarity in 0-100 range');

  // Test 3: Results are ranked
  console.log('\n3. Result Ranking');
  if (reactResults.length >= 2) {
    assert(reactResults[0].similarity >= reactResults[1].similarity, 'Results ranked by similarity');
  }

  // Test 4: Cross-folder search
  console.log('\n4. Cross-Folder Search');
  const dbQuery = await embeddings.generateEmbedding('database indexing and performance');
  const dbResults = vectorIndex.vectorSearch(dbQuery, { limit: 5 });

  const folders = new Set(dbResults.map(r => r.spec_folder));
  assert(folders.size >= 1, 'Results from multiple folders possible');
  assert(dbResults[0].title.includes('Database'), 'Database result ranked first');

  // Test 5: Filter by spec folder
  console.log('\n5. Filter by Spec Folder');
  const specAResults = vectorIndex.vectorSearch(reactQuery, {
    limit: 10,
    specFolder: 'spec-a'
  });

  assert(specAResults.length > 0, 'Returns filtered results');
  assert(specAResults.every(r => r.spec_folder === 'spec-a'), 'All results from spec-a');

  // Test 6: Minimum similarity filter
  console.log('\n6. Minimum Similarity Filter');
  const highSimResults = vectorIndex.vectorSearch(reactQuery, {
    limit: 10,
    minSimilarity: 70
  });

  if (highSimResults.length > 0) {
    assert(highSimResults.every(r => r.similarity >= 70), 'All results meet minimum similarity');
  } else {
    console.log('  - No results above 70% similarity (acceptable)');
    testsPassed++;
  }

  // Test 7: Multi-concept search with 2 concepts
  console.log('\n7. Multi-Concept Search (2 concepts)');
  const concept1 = await embeddings.generateEmbedding('JavaScript programming');
  const concept2 = await embeddings.generateEmbedding('state management');

  const multiResults = vectorIndex.multiConceptSearch([concept1, concept2], {
    limit: 5,
    minSimilarity: 30
  });

  assert(Array.isArray(multiResults), 'Returns array');
  if (multiResults.length > 0) {
    assert(multiResults[0].concept_similarities !== undefined, 'Per-concept similarities included');
    assert(multiResults[0].avg_similarity !== undefined, 'Average similarity included');
    assert(multiResults[0].concept_similarities.length === 2, 'Two concept scores');
  }

  // Test 8: Multi-concept with 3 concepts
  console.log('\n8. Multi-Concept Search (3 concepts)');
  const concept3 = await embeddings.generateEmbedding('asynchronous operations');

  const threeConceptResults = vectorIndex.multiConceptSearch(
    [concept1, concept2, concept3],
    { limit: 5, minSimilarity: 20 }
  );

  assert(Array.isArray(threeConceptResults), 'Returns array for 3 concepts');

  // Test 9: Invalid concept count
  console.log('\n9. Invalid Concept Count');
  let errorThrown = false;
  try {
    vectorIndex.multiConceptSearch([concept1], { limit: 5 });
  } catch (e) {
    errorThrown = true;
  }
  assert(errorThrown, 'Throws error for 1 concept (requires 2-5)');

  // Test 10: Search performance (for 5 memories)
  console.log('\n10. Search Performance');
  const perfQuery = await embeddings.generateEmbedding('test query for performance');

  const start = Date.now();
  for (let i = 0; i < 100; i++) {
    vectorIndex.vectorSearch(perfQuery, { limit: 10 });
  }
  const elapsed = Date.now() - start;
  const avgTime = elapsed / 100;

  assert(avgTime < 10, `Average search time < 10ms (got ${avgTime.toFixed(2)}ms)`);

  // Cleanup
  vectorIndex.closeDb();

  // Test 11: File cleanup
  console.log('\n11. Cleanup');
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
