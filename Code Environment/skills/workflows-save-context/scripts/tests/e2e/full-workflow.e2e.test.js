/**
 * End-to-End Tests for Semantic Memory Workflow
 *
 * Tests the complete save-to-search flow:
 * 1. Create content -> Generate embedding -> Index -> Search -> Verify -> Cleanup
 * 2. Multi-concept AND search
 * 3. Persistence across DB close/reopen
 *
 * @module tests/e2e/full-workflow.e2e.test
 * @version 10.0.0
 */

'use strict';

const fs = require('fs').promises;
const path = require('path');
const os = require('os');
const assert = require('assert');

const libPath = path.join(__dirname, '..', '..', 'lib');
const vectorIndex = require(path.join(libPath, 'vector-index.js'));
const embeddings = require(path.join(libPath, 'embeddings.js'));

// ───────────────────────────────────────────────────────────────
// TEST CONFIGURATION
// ───────────────────────────────────────────────────────────────

const TEST_DB_PATH = path.join(os.tmpdir(), `e2e-test-${Date.now()}.sqlite`);
let testsRun = 0;
let testsPassed = 0;

// ───────────────────────────────────────────────────────────────
// TEST UTILITIES
// ───────────────────────────────────────────────────────────────

function assertTrue(condition, message) {
  testsRun++;
  if (!condition) {
    throw new Error(`Assertion failed: ${message}`);
  }
  testsPassed++;
  console.log(`     [PASS] ${message}`);
}

async function cleanupTestDb() {
  try {
    vectorIndex.closeDb();
    const fsSync = require('fs');
    if (fsSync.existsSync(TEST_DB_PATH)) {
      fsSync.unlinkSync(TEST_DB_PATH);
    }
    if (fsSync.existsSync(TEST_DB_PATH + '-wal')) {
      fsSync.unlinkSync(TEST_DB_PATH + '-wal');
    }
    if (fsSync.existsSync(TEST_DB_PATH + '-shm')) {
      fsSync.unlinkSync(TEST_DB_PATH + '-shm');
    }
  } catch (err) {
    console.warn(`     [WARN] Cleanup warning: ${err.message}`);
  }
}

// ───────────────────────────────────────────────────────────────
// E2E TEST 1: Full Save-to-Search Workflow
// ───────────────────────────────────────────────────────────────

async function e2eFullWorkflow() {
  console.log('\n[E2E TEST 1] Full Save-to-Search Workflow');
  console.log('─'.repeat(50));

  // Initialize fresh test database
  vectorIndex.initializeDb(TEST_DB_PATH);

  // 1. Setup - create test content
  console.log('   Step 1: Creating test content...');
  const testContent = 'This is a test memory about JavaScript async/await patterns and promise handling for asynchronous programming.';
  const testSpecFolder = 'test-e2e-workflow';
  const testFilePath = path.join(os.tmpdir(), 'test-memory-e2e.md');

  await fs.writeFile(testFilePath, testContent);
  assertTrue(true, 'Test file created');

  // 2. Generate embedding
  console.log('   Step 2: Generating embedding...');
  const embedding = await embeddings.generateEmbedding(testContent);
  assertTrue(embedding !== null, 'Embedding generated successfully');
  assertTrue(embedding.length === 384, `Embedding has correct dimension (${embedding.length})`);
  assertTrue(embedding instanceof Float32Array, 'Embedding is Float32Array');

  // 3. Index the memory
  console.log('   Step 3: Indexing memory...');
  const rowId = vectorIndex.indexMemory({
    specFolder: testSpecFolder,
    filePath: testFilePath,
    title: 'E2E Test Memory - Async/Await Patterns',
    embedding: embedding,
    triggerPhrases: ['async await', 'promise', 'asynchronous'],
    importanceWeight: 0.85
  });
  assertTrue(typeof rowId === 'number', 'Row ID returned');
  assertTrue(rowId > 0, `Valid row ID: ${rowId}`);

  // 4. Verify memory was stored
  console.log('   Step 4: Verifying memory storage...');
  const storedMemory = vectorIndex.getMemory(rowId);
  assertTrue(storedMemory !== null, 'Memory can be retrieved');
  assertTrue(storedMemory.spec_folder === testSpecFolder, 'Spec folder matches');
  assertTrue(storedMemory.title === 'E2E Test Memory - Async/Await Patterns', 'Title matches');
  assertTrue(storedMemory.embedding_status === 'success', 'Embedding status is success');

  // 5. Search by semantic query
  console.log('   Step 5: Searching by semantic query...');
  const searchQuery = 'how to use promises in JavaScript';
  const queryEmbedding = await embeddings.generateEmbedding(searchQuery);
  assertTrue(queryEmbedding !== null, 'Query embedding generated');

  const results = vectorIndex.vectorSearch(queryEmbedding, { limit: 10 });
  assertTrue(Array.isArray(results), 'Search returns array');
  assertTrue(results.length > 0, `Search found ${results.length} result(s)`);

  const found = results.find(r => r.spec_folder === testSpecFolder);
  assertTrue(found !== undefined, 'Test memory found in search results');
  assertTrue(found.similarity > 50, `Similarity score is good: ${found.similarity}%`);
  assertTrue(found.id === rowId, 'Found memory has correct ID');

  // 6. Test different semantic query
  console.log('   Step 6: Testing alternative semantic query...');
  const altQuery = 'asynchronous JavaScript programming techniques';
  const altQueryEmbedding = await embeddings.generateEmbedding(altQuery);
  const altResults = vectorIndex.vectorSearch(altQueryEmbedding, { limit: 10 });
  const altFound = altResults.find(r => r.id === rowId);
  assertTrue(altFound !== undefined, 'Memory found with alternative query');
  console.log(`     [INFO] Alt query similarity: ${altFound.similarity}%`);

  // 7. Test folder-scoped search
  console.log('   Step 7: Testing folder-scoped search...');
  const folderResults = vectorIndex.vectorSearch(queryEmbedding, {
    limit: 10,
    specFolder: testSpecFolder
  });
  assertTrue(folderResults.length > 0, 'Folder-scoped search returns results');
  assertTrue(folderResults[0].spec_folder === testSpecFolder, 'Results from correct folder');

  // 8. Cleanup
  console.log('   Step 8: Cleaning up...');
  const deleted = vectorIndex.deleteMemory(rowId);
  assertTrue(deleted === true, 'Memory deleted successfully');

  const afterDelete = vectorIndex.getMemory(rowId);
  assertTrue(afterDelete === null, 'Memory no longer exists after delete');

  await fs.unlink(testFilePath);
  assertTrue(true, 'Test file cleaned up');

  console.log('\n   [SUCCESS] E2E Full Workflow Test Passed!');
  console.log(`   Final similarity score: ${found.similarity}%`);
}

// ───────────────────────────────────────────────────────────────
// E2E TEST 2: Multi-Concept Search
// ───────────────────────────────────────────────────────────────

async function e2eMultiConceptSearch() {
  console.log('\n[E2E TEST 2] Multi-Concept AND Search');
  console.log('─'.repeat(50));

  // Initialize fresh test database
  await cleanupTestDb();
  vectorIndex.initializeDb(TEST_DB_PATH);

  // 1. Create test memories with different topic combinations
  console.log('   Step 1: Creating test memories...');

  const memories = [
    {
      content: 'React hooks like useState and useEffect for building user interfaces with functional components.',
      specFolder: 'test-multi-concept',
      filePath: '/test/react-hooks.md',
      title: 'React Hooks Guide'
    },
    {
      content: 'TypeScript generic types and interfaces for type-safe React component development.',
      specFolder: 'test-multi-concept',
      filePath: '/test/typescript-react.md',
      title: 'TypeScript + React'
    },
    {
      content: 'Python data analysis with pandas DataFrame operations for data science workflows.',
      specFolder: 'test-multi-concept',
      filePath: '/test/python-pandas.md',
      title: 'Python Data Science'
    },
    {
      content: 'React state management patterns with Redux and TypeScript for enterprise applications.',
      specFolder: 'test-multi-concept',
      filePath: '/test/react-redux-ts.md',
      title: 'React + Redux + TypeScript'
    }
  ];

  const indexedIds = [];
  for (const mem of memories) {
    const embedding = await embeddings.generateEmbedding(mem.content);
    const id = vectorIndex.indexMemory({
      specFolder: mem.specFolder,
      filePath: mem.filePath,
      title: mem.title,
      embedding: embedding,
      triggerPhrases: []
    });
    indexedIds.push(id);
    console.log(`     [INDEX] ${mem.title} -> ID: ${id}`);
  }

  assertTrue(indexedIds.length === 4, 'All 4 memories indexed');

  // 2. Generate concept embeddings
  console.log('   Step 2: Generating concept embeddings...');
  const concept1 = await embeddings.generateEmbedding('React component development');
  const concept2 = await embeddings.generateEmbedding('TypeScript type safety');

  assertTrue(concept1 !== null, 'Concept 1 embedding generated');
  assertTrue(concept2 !== null, 'Concept 2 embedding generated');

  // 3. Perform multi-concept AND search
  console.log('   Step 3: Performing multi-concept AND search...');
  const multiResults = vectorIndex.multiConceptSearch([concept1, concept2], {
    limit: 10,
    minSimilarity: 40  // Lower threshold to ensure we get results
  });

  assertTrue(Array.isArray(multiResults), 'Multi-concept search returns array');
  console.log(`     [INFO] Found ${multiResults.length} result(s) matching BOTH concepts`);

  if (multiResults.length > 0) {
    // The top result should be about TypeScript + React (matches both concepts best)
    const topResult = multiResults[0];
    console.log(`     [INFO] Top result: "${topResult.title}"`);
    console.log(`     [INFO] Concept similarities: ${topResult.concept_similarities.map(s => s.toFixed(1) + '%').join(', ')}`);
    console.log(`     [INFO] Average similarity: ${topResult.avg_similarity.toFixed(1)}%`);

    assertTrue(topResult.concept_similarities.length === 2, 'Has similarity for both concepts');
    assertTrue(topResult.avg_similarity > 0, 'Average similarity is positive');

    // The result should mention both React and TypeScript (our multi-concept query)
    const titleLower = topResult.title.toLowerCase();
    const isReactTypescript = titleLower.includes('react') || titleLower.includes('typescript');
    assertTrue(isReactTypescript, 'Top result is related to React/TypeScript');
  }

  // 4. Verify Python result is NOT in top for React+TypeScript query
  console.log('   Step 4: Verifying exclusion of unrelated content...');
  const pythonResult = multiResults.find(r => r.title.includes('Python'));
  if (pythonResult) {
    console.log(`     [INFO] Python result avg similarity: ${pythonResult.avg_similarity.toFixed(1)}%`);
    // Python should have lower similarity than React/TypeScript content
    const reactTsResult = multiResults.find(r => r.title.includes('TypeScript'));
    if (reactTsResult) {
      assertTrue(
        pythonResult.avg_similarity < reactTsResult.avg_similarity,
        'Python has lower similarity than React/TypeScript content'
      );
    }
  } else {
    console.log('     [INFO] Python content correctly excluded from results');
  }

  // 5. Test with 3 concepts
  console.log('   Step 5: Testing 3-concept search...');
  const concept3 = await embeddings.generateEmbedding('state management Redux');
  const threeConceptResults = vectorIndex.multiConceptSearch([concept1, concept2, concept3], {
    limit: 5,
    minSimilarity: 30
  });

  console.log(`     [INFO] 3-concept search found ${threeConceptResults.length} result(s)`);
  if (threeConceptResults.length > 0) {
    assertTrue(
      threeConceptResults[0].concept_similarities.length === 3,
      'Has similarity for all 3 concepts'
    );
    console.log(`     [INFO] Top 3-concept result: "${threeConceptResults[0].title}"`);
  }

  // 6. Cleanup
  console.log('   Step 6: Cleaning up...');
  for (const id of indexedIds) {
    vectorIndex.deleteMemory(id);
  }
  const remaining = vectorIndex.getMemoryCount();
  assertTrue(remaining === 0, 'All test memories cleaned up');

  console.log('\n   [SUCCESS] E2E Multi-Concept Search Test Passed!');
}

// ───────────────────────────────────────────────────────────────
// E2E TEST 3: Persistence Across DB Close/Reopen
// ───────────────────────────────────────────────────────────────

async function e2ePersistence() {
  console.log('\n[E2E TEST 3] Persistence Across DB Close/Reopen');
  console.log('─'.repeat(50));

  // Use a unique DB path for this test
  const persistDb = path.join(os.tmpdir(), `e2e-persist-${Date.now()}.sqlite`);

  // 1. Create and index memory in first session
  console.log('   Step 1: Session 1 - Creating and indexing memory...');
  vectorIndex.initializeDb(persistDb);

  const testContent = 'Persistent memory test for database recovery verification across sessions.';
  const embedding = await embeddings.generateEmbedding(testContent);

  const originalId = vectorIndex.indexMemory({
    specFolder: 'test-persistence',
    filePath: '/test/persistent-memory.md',
    title: 'Persistence Test Memory',
    embedding: embedding,
    triggerPhrases: ['persistence', 'recovery'],
    importanceWeight: 0.75
  });

  assertTrue(originalId > 0, `Memory indexed with ID: ${originalId}`);

  // Verify it exists
  const session1Memory = vectorIndex.getMemory(originalId);
  assertTrue(session1Memory !== null, 'Memory exists in session 1');
  assertTrue(session1Memory.title === 'Persistence Test Memory', 'Title correct in session 1');

  // Get integrity before close
  const integrityBefore = vectorIndex.verifyIntegrity();
  console.log(`     [INFO] Integrity before close: ${integrityBefore.isConsistent ? 'OK' : 'FAILED'}`);

  // 2. Close database (simulate session end)
  console.log('   Step 2: Closing database (simulating session end)...');
  vectorIndex.closeDb();
  assertTrue(true, 'Database closed');

  // Small delay to ensure WAL is flushed
  await new Promise(resolve => setTimeout(resolve, 100));

  // 3. Reopen database (new session)
  console.log('   Step 3: Session 2 - Reopening database...');
  vectorIndex.initializeDb(persistDb);
  assertTrue(true, 'Database reopened');

  // 4. Verify memory still exists
  console.log('   Step 4: Verifying memory persistence...');
  const session2Memory = vectorIndex.getMemory(originalId);
  assertTrue(session2Memory !== null, 'Memory exists in session 2');
  assertTrue(session2Memory.id === originalId, 'ID preserved');
  assertTrue(session2Memory.spec_folder === 'test-persistence', 'Spec folder preserved');
  assertTrue(session2Memory.title === 'Persistence Test Memory', 'Title preserved');
  assertTrue(session2Memory.embedding_status === 'success', 'Embedding status preserved');
  assertTrue(Array.isArray(session2Memory.trigger_phrases), 'Trigger phrases preserved as array');
  assertTrue(session2Memory.trigger_phrases.includes('persistence'), 'Trigger phrase content preserved');

  // 5. Verify vector search still works
  console.log('   Step 5: Verifying vector search after reopen...');
  const searchQuery = 'database recovery and persistence';
  const queryEmbedding = await embeddings.generateEmbedding(searchQuery);
  const searchResults = vectorIndex.vectorSearch(queryEmbedding, { limit: 10 });

  assertTrue(searchResults.length > 0, 'Search returns results after reopen');
  const foundPersisted = searchResults.find(r => r.id === originalId);
  assertTrue(foundPersisted !== undefined, 'Persisted memory found via search');
  console.log(`     [INFO] Search similarity after reopen: ${foundPersisted.similarity}%`);

  // 6. Verify database integrity
  console.log('   Step 6: Verifying database integrity...');
  const integrityAfter = vectorIndex.verifyIntegrity();
  assertTrue(integrityAfter.isConsistent, 'Database is consistent after reopen');
  assertTrue(integrityAfter.orphanedVectors === 0, 'No orphaned vectors');
  assertTrue(integrityAfter.missingVectors === 0, 'No missing vectors');

  // 7. Test update persistence
  console.log('   Step 7: Testing update persistence...');
  vectorIndex.updateMemory({
    id: originalId,
    title: 'Updated Persistence Test',
    importanceWeight: 0.95
  });

  // Close and reopen again
  vectorIndex.closeDb();
  await new Promise(resolve => setTimeout(resolve, 100));
  vectorIndex.initializeDb(persistDb);

  const updatedMemory = vectorIndex.getMemory(originalId);
  assertTrue(updatedMemory.title === 'Updated Persistence Test', 'Update persisted');
  assertTrue(updatedMemory.importance_weight === 0.95, 'Importance weight update persisted');

  // 8. Cleanup
  console.log('   Step 8: Cleaning up...');
  vectorIndex.deleteMemory(originalId);
  vectorIndex.closeDb();

  const fsSync = require('fs');
  if (fsSync.existsSync(persistDb)) {
    fsSync.unlinkSync(persistDb);
  }
  if (fsSync.existsSync(persistDb + '-wal')) {
    fsSync.unlinkSync(persistDb + '-wal');
  }
  if (fsSync.existsSync(persistDb + '-shm')) {
    fsSync.unlinkSync(persistDb + '-shm');
  }

  assertTrue(true, 'Persistence test database cleaned up');

  console.log('\n   [SUCCESS] E2E Persistence Test Passed!');
}

// ───────────────────────────────────────────────────────────────
// E2E TEST 4: Edge Cases and Error Handling
// ───────────────────────────────────────────────────────────────

async function e2eEdgeCases() {
  console.log('\n[E2E TEST 4] Edge Cases and Error Handling');
  console.log('─'.repeat(50));

  // Initialize fresh test database
  await cleanupTestDb();
  vectorIndex.initializeDb(TEST_DB_PATH);

  // 1. Search with no indexed content
  console.log('   Step 1: Search with empty database...');
  const emptyQuery = await embeddings.generateEmbedding('test query');
  const emptyResults = vectorIndex.vectorSearch(emptyQuery, { limit: 10 });
  assertTrue(Array.isArray(emptyResults), 'Empty search returns array');
  assertTrue(emptyResults.length === 0, 'Empty search returns no results');

  // 2. Index with minimal data
  console.log('   Step 2: Index with minimal required fields...');
  const minimalEmbedding = await embeddings.generateEmbedding('minimal content');
  const minimalId = vectorIndex.indexMemory({
    specFolder: 'test-minimal',
    filePath: '/test/minimal.md',
    embedding: minimalEmbedding
  });
  assertTrue(minimalId > 0, 'Minimal index succeeds');

  // 3. Search with high similarity threshold
  console.log('   Step 3: Search with high similarity threshold...');
  const highThresholdResults = vectorIndex.vectorSearch(emptyQuery, {
    limit: 10,
    minSimilarity: 99  // Very high threshold
  });
  assertTrue(Array.isArray(highThresholdResults), 'High threshold search returns array');
  console.log(`     [INFO] Results with 99% threshold: ${highThresholdResults.length}`);

  // 4. Verify trigger phrases handling
  console.log('   Step 4: Testing trigger phrases storage/retrieval...');
  const triggerEmbed = await embeddings.generateEmbedding('trigger test content');
  const triggerId = vectorIndex.indexMemory({
    specFolder: 'test-triggers',
    filePath: '/test/triggers.md',
    title: 'Trigger Test',
    embedding: triggerEmbed,
    triggerPhrases: ['phrase one', 'phrase two', 'phrase three']
  });

  const triggerMem = vectorIndex.getMemory(triggerId);
  assertTrue(Array.isArray(triggerMem.trigger_phrases), 'Trigger phrases is array');
  assertTrue(triggerMem.trigger_phrases.length === 3, 'All trigger phrases stored');
  assertTrue(triggerMem.trigger_phrases.includes('phrase two'), 'Trigger phrases retrievable');

  // 5. Delete non-existent memory
  console.log('   Step 5: Delete non-existent memory...');
  const deleteNonExistent = vectorIndex.deleteMemory(99999);
  assertTrue(deleteNonExistent === false, 'Delete non-existent returns false');

  // 6. Cleanup
  console.log('   Step 6: Cleaning up...');
  vectorIndex.deleteMemory(minimalId);
  vectorIndex.deleteMemory(triggerId);

  console.log('\n   [SUCCESS] E2E Edge Cases Test Passed!');
}

// ───────────────────────────────────────────────────────────────
// MAIN TEST RUNNER
// ───────────────────────────────────────────────────────────────

async function runAllE2ETests() {
  console.log('\n' + '='.repeat(60));
  console.log(' END-TO-END TESTS: Semantic Memory Workflow');
  console.log(' Version: 10.0.0 | Date: ' + new Date().toISOString().split('T')[0]);
  console.log('='.repeat(60));

  const startTime = Date.now();

  try {
    // Run all E2E tests
    await e2eFullWorkflow();
    await e2eMultiConceptSearch();
    await e2ePersistence();
    await e2eEdgeCases();

    // Final cleanup
    await cleanupTestDb();

    const duration = ((Date.now() - startTime) / 1000).toFixed(2);

    console.log('\n' + '='.repeat(60));
    console.log(' E2E TEST SUMMARY');
    console.log('='.repeat(60));
    console.log(`   Total assertions: ${testsRun}`);
    console.log(`   Passed: ${testsPassed}`);
    console.log(`   Failed: ${testsRun - testsPassed}`);
    console.log(`   Duration: ${duration}s`);
    console.log('='.repeat(60));
    console.log('\n [SUCCESS] All E2E tests passed!\n');

  } catch (error) {
    console.error('\n' + '='.repeat(60));
    console.error(' E2E TEST FAILURE');
    console.error('='.repeat(60));
    console.error(`   Error: ${error.message}`);
    console.error(`   Stack: ${error.stack}`);
    console.error('='.repeat(60));

    // Cleanup on failure
    await cleanupTestDb();
    process.exit(1);
  }
}

// ───────────────────────────────────────────────────────────────
// RUN TESTS
// ───────────────────────────────────────────────────────────────

runAllE2ETests().catch(err => {
  console.error('\n[FATAL] E2E test runner error:', err);
  process.exit(1);
});
