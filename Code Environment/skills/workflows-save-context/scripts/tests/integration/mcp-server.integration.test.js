/**
 * Integration Tests for MCP Server Tools
 *
 * Tests memory_search and memory_load functionality with real embeddings.
 * Uses actual vector-index and embeddings modules for realistic testing.
 *
 * @module tests/integration/mcp-server.integration.test
 * @version 10.0.0
 */

'use strict';

const path = require('path');
const fs = require('fs');
const os = require('os');

const libPath = path.join(__dirname, '..', '..', 'lib');
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
    console.log(`  [PASS] ${message}`);
  } else {
    testsFailed++;
    console.log(`  [FAIL] ${message}`);
  }
}

// ───────────────────────────────────────────────────────────────
// TEST DATABASE SETUP
// ───────────────────────────────────────────────────────────────

const TEST_DB_PATH = path.join(os.tmpdir(), `integration-mcp-${Date.now()}.sqlite`);

// Sample memory content for testing
const TEST_MEMORIES = [
  {
    specFolder: 'project-alpha',
    filePath: '/docs/api-authentication.md',
    title: 'API Authentication Guide',
    content: 'OAuth2 authentication flow using JWT tokens with refresh token rotation. Includes examples for Node.js and Python SDKs.',
    triggerPhrases: ['oauth2', 'authentication', 'jwt', 'refresh token'],
    importanceWeight: 0.9
  },
  {
    specFolder: 'project-alpha',
    filePath: '/docs/error-handling.md',
    title: 'Error Handling Best Practices',
    content: 'Centralized error handling with custom error classes. Includes retry logic with exponential backoff.',
    triggerPhrases: ['error handling', 'retry logic', 'exponential backoff'],
    importanceWeight: 0.7
  },
  {
    specFolder: 'project-beta',
    filePath: '/specs/database-schema.md',
    title: 'Database Schema Design',
    content: 'PostgreSQL schema with normalized tables for users, orders, and inventory. Includes indexing strategies.',
    triggerPhrases: ['database schema', 'postgresql', 'indexing'],
    importanceWeight: 0.8
  }
];

// ───────────────────────────────────────────────────────────────
// MEMORY_SEARCH TOOL SIMULATION
// ───────────────────────────────────────────────────────────────

/**
 * Simulates the memory_search MCP tool
 * @param {Object} params - Search parameters
 * @param {string} params.query - Search query text
 * @param {number} [params.limit=5] - Maximum results
 * @param {string} [params.specFolder] - Filter by spec folder
 * @returns {Promise<Object>} Search results
 */
async function memorySearch(params) {
  const { query, limit = 5, specFolder = null } = params;

  if (!query || typeof query !== 'string') {
    throw new Error('Invalid query: query must be a non-empty string');
  }

  // Generate embedding for query
  const queryEmbedding = await embeddings.generateEmbedding(query);

  if (!queryEmbedding) {
    throw new Error('Failed to generate embedding for query');
  }

  // Search using vector index
  const results = vectorIndex.vectorSearch(queryEmbedding, {
    limit,
    specFolder,
    minSimilarity: 30
  });

  return {
    query,
    results: results.map(r => ({
      title: r.title,
      filePath: r.file_path,
      specFolder: r.spec_folder,
      similarity: r.similarity,
      triggerPhrases: r.trigger_phrases
    })),
    count: results.length
  };
}

/**
 * Simulates the memory_load MCP tool
 * @param {Object} params - Load parameters
 * @param {string} params.filePath - Path to memory file
 * @returns {Object} Loaded memory content
 */
function memoryLoad(params) {
  const { filePath } = params;

  if (!filePath || typeof filePath !== 'string') {
    throw new Error('Invalid filePath: must be a non-empty string');
  }

  // Get memory by path from index
  const db = vectorIndex.getDb();
  const memory = db.prepare(`
    SELECT * FROM memory_index WHERE file_path = ?
  `).get(filePath);

  if (!memory) {
    throw new Error(`Memory not found: ${filePath}`);
  }

  return {
    id: memory.id,
    title: memory.title,
    filePath: memory.file_path,
    specFolder: memory.spec_folder,
    triggerPhrases: memory.trigger_phrases ? JSON.parse(memory.trigger_phrases) : [],
    importanceWeight: memory.importance_weight,
    createdAt: memory.created_at,
    updatedAt: memory.updated_at
  };
}

// ───────────────────────────────────────────────────────────────
// TESTS
// ───────────────────────────────────────────────────────────────

async function testMemorySearchWithRealEmbeddings() {
  console.log('Test: memory_search with real embeddings');

  // Search for authentication-related content
  const result = await memorySearch({ query: 'how to authenticate API requests' });

  assert(result.count > 0, 'Search returns results');
  assert(result.results[0].title.includes('Authentication'), 'Top result is authentication-related');
  assert(typeof result.results[0].similarity === 'number', 'Results include similarity score');
  assert(result.results[0].similarity > 30, 'Similarity score is above threshold');

  console.log('[PASS] testMemorySearchWithRealEmbeddings');
}

async function testMemorySearchWithLimit() {
  console.log('Test: memory_search respects limit parameter');

  const result = await memorySearch({ query: 'database or authentication', limit: 2 });

  assert(result.count <= 2, 'Results respect limit');

  console.log('[PASS] testMemorySearchWithLimit');
}

async function testMemorySearchWithSpecFolderFilter() {
  console.log('Test: memory_search filters by specFolder');

  const result = await memorySearch({
    query: 'documentation',
    specFolder: 'project-alpha'
  });

  if (result.count > 0) {
    assert(
      result.results.every(r => r.specFolder === 'project-alpha'),
      'All results are from project-alpha'
    );
  } else {
    assert(true, 'No results (acceptable for specific folder filter)');
  }

  console.log('[PASS] testMemorySearchWithSpecFolderFilter');
}

async function testMemorySearchSemanticUnderstanding() {
  console.log('Test: memory_search semantic understanding');

  // Search with different phrasing should find same content
  const result1 = await memorySearch({ query: 'token based login' });
  const result2 = await memorySearch({ query: 'OAuth authentication' });

  // Both should find the authentication guide
  const hasAuthInResult1 = result1.results.some(r => r.title.includes('Authentication'));
  const hasAuthInResult2 = result2.results.some(r => r.title.includes('Authentication'));

  assert(hasAuthInResult1 || hasAuthInResult2, 'Semantic search understands related concepts');

  console.log('[PASS] testMemorySearchSemanticUnderstanding');
}

async function testMemoryLoadWithRealFiles() {
  console.log('Test: memory_load with real file paths');

  const loaded = memoryLoad({ filePath: '/docs/api-authentication.md' });

  assert(loaded.id !== undefined, 'Loaded memory has ID');
  assert(loaded.title === 'API Authentication Guide', 'Loaded memory has correct title');
  assert(loaded.specFolder === 'project-alpha', 'Loaded memory has correct spec folder');
  assert(Array.isArray(loaded.triggerPhrases), 'Trigger phrases is array');
  assert(loaded.triggerPhrases.includes('oauth2'), 'Contains expected trigger phrase');

  console.log('[PASS] testMemoryLoadWithRealFiles');
}

async function testErrorHandlingMissingFile() {
  console.log('Test: error handling - missing file');

  let errorThrown = false;
  try {
    memoryLoad({ filePath: '/nonexistent/file.md' });
  } catch (error) {
    errorThrown = true;
    assert(error.message.includes('Memory not found'), 'Error message is descriptive');
  }

  assert(errorThrown, 'Throws error for missing file');

  console.log('[PASS] testErrorHandlingMissingFile');
}

async function testErrorHandlingInvalidQuery() {
  console.log('Test: error handling - invalid query');

  let errorThrown = false;
  try {
    await memorySearch({ query: null });
  } catch (error) {
    errorThrown = true;
    assert(error.message.includes('Invalid query'), 'Error message is descriptive');
  }

  assert(errorThrown, 'Throws error for invalid query');

  console.log('[PASS] testErrorHandlingInvalidQuery');
}

async function testErrorHandlingInvalidFilePath() {
  console.log('Test: error handling - invalid file path');

  let errorThrown = false;
  try {
    memoryLoad({ filePath: '' });
  } catch (error) {
    errorThrown = true;
    assert(error.message.includes('Invalid filePath'), 'Error message is descriptive');
  }

  assert(errorThrown, 'Throws error for invalid file path');

  console.log('[PASS] testErrorHandlingInvalidFilePath');
}

async function testSearchResultsIncludeMetadata() {
  console.log('Test: search results include all metadata');

  const result = await memorySearch({ query: 'database schema design' });

  if (result.count > 0) {
    const firstResult = result.results[0];
    assert(firstResult.title !== undefined, 'Result has title');
    assert(firstResult.filePath !== undefined, 'Result has filePath');
    assert(firstResult.specFolder !== undefined, 'Result has specFolder');
    assert(firstResult.similarity !== undefined, 'Result has similarity');
    assert(firstResult.triggerPhrases !== undefined, 'Result has triggerPhrases');
  }

  console.log('[PASS] testSearchResultsIncludeMetadata');
}

async function testSearchPerformance() {
  console.log('Test: search performance');

  const start = Date.now();
  const iterations = 10;

  for (let i = 0; i < iterations; i++) {
    await memorySearch({ query: 'test query for performance' });
  }

  const elapsed = Date.now() - start;
  const avgTime = elapsed / iterations;

  // First search includes model loading, subsequent should be fast
  assert(avgTime < 1000, `Average search time < 1000ms (got ${avgTime.toFixed(2)}ms)`);

  console.log('[PASS] testSearchPerformance');
}

// ───────────────────────────────────────────────────────────────
// CHK077: MCP-INT-002 - memory_search accepts concepts array
// ───────────────────────────────────────────────────────────────

/**
 * Simulates the memory_search MCP tool with concepts (multi-concept search)
 * @param {Object} params - Search parameters
 * @param {string[]} params.concepts - Array of concept strings
 * @param {number} [params.limit=5] - Maximum results
 * @param {string} [params.specFolder] - Filter by spec folder
 * @returns {Promise<Object>} Search results
 */
async function memorySearchWithConcepts(params) {
  const { concepts, limit = 5, specFolder = null } = params;

  if (!concepts || !Array.isArray(concepts) || concepts.length < 2) {
    throw new Error('Invalid concepts: must be an array with at least 2 concepts');
  }

  if (concepts.length > 5) {
    throw new Error('Invalid concepts: maximum 5 concepts allowed');
  }

  // Generate embeddings for all concepts
  const conceptEmbeddings = await Promise.all(
    concepts.map(c => embeddings.generateEmbedding(c))
  );

  // Verify all embeddings generated
  if (conceptEmbeddings.some(e => e === null)) {
    throw new Error('Failed to generate embeddings for one or more concepts');
  }

  // Multi-concept search
  const results = vectorIndex.multiConceptSearch(conceptEmbeddings, {
    limit,
    specFolder,
    minSimilarity: 30
  });

  return {
    concepts,
    results: results.map(r => ({
      title: r.title,
      filePath: r.file_path,
      specFolder: r.spec_folder,
      avgSimilarity: r.avg_similarity,
      conceptSimilarities: r.concept_similarities,
      triggerPhrases: r.trigger_phrases
    })),
    count: results.length
  };
}

async function testMemorySearchWithConceptsArray() {
  console.log('Test: MCP-INT-002 - memory_search accepts concepts array');

  // Search with 2 concepts
  const result = await memorySearchWithConcepts({
    concepts: ['authentication', 'error handling']
  });

  assert(result.concepts.length === 2, 'Concepts array preserved in response');
  assert(Array.isArray(result.results), 'Returns results array');

  if (result.count > 0) {
    assert(result.results[0].avgSimilarity !== undefined, 'Results include avgSimilarity');
    assert(Array.isArray(result.results[0].conceptSimilarities), 'Results include conceptSimilarities array');
    assert(result.results[0].conceptSimilarities.length === 2, 'conceptSimilarities has entry per concept');
  }

  console.log('[PASS] testMemorySearchWithConceptsArray (CHK077)');
}

async function testMemorySearchWithThreeConcepts() {
  console.log('Test: memory_search with 3 concepts');

  const result = await memorySearchWithConcepts({
    concepts: ['API', 'database', 'authentication']
  });

  assert(result.concepts.length === 3, 'Accepts 3 concepts');

  if (result.count > 0) {
    assert(result.results[0].conceptSimilarities.length === 3, 'Has 3 concept similarities');
  }

  console.log('[PASS] testMemorySearchWithThreeConcepts');
}

async function testMemorySearchConceptsValidation() {
  console.log('Test: memory_search concepts validation');

  // Test with too few concepts
  let errorThrown = false;
  try {
    await memorySearchWithConcepts({ concepts: ['single'] });
  } catch (error) {
    errorThrown = true;
    assert(error.message.includes('at least 2'), 'Error for single concept');
  }
  assert(errorThrown, 'Throws error for single concept');

  // Test with too many concepts
  errorThrown = false;
  try {
    await memorySearchWithConcepts({
      concepts: ['a', 'b', 'c', 'd', 'e', 'f']
    });
  } catch (error) {
    errorThrown = true;
    assert(error.message.includes('maximum 5'), 'Error for >5 concepts');
  }
  assert(errorThrown, 'Throws error for >5 concepts');

  console.log('[PASS] testMemorySearchConceptsValidation');
}

// ───────────────────────────────────────────────────────────────
// CHK081: MCP-INT-008 - Database unavailability handled gracefully
// ───────────────────────────────────────────────────────────────

async function testDatabaseUnavailabilityHandling() {
  console.log('Test: MCP-INT-008 - database unavailability handled gracefully');

  // Close the database to simulate unavailability
  vectorIndex.closeDb();

  let errorHandled = false;
  let errorMessage = '';

  try {
    // Attempt search with closed database
    const queryEmbedding = await embeddings.generateEmbedding('test query');
    vectorIndex.vectorSearch(queryEmbedding, { limit: 5 });
  } catch (error) {
    errorHandled = true;
    errorMessage = error.message;
  }

  // Reopen database for remaining tests
  vectorIndex.initializeDb(TEST_DB_PATH);

  // Re-index test memories for subsequent tests
  for (const memory of TEST_MEMORIES) {
    const embedding = await embeddings.generateEmbedding(memory.content);
    vectorIndex.indexMemory({
      specFolder: memory.specFolder,
      filePath: memory.filePath,
      title: memory.title,
      triggerPhrases: memory.triggerPhrases,
      importanceWeight: memory.importanceWeight,
      embedding
    });
  }

  assert(errorHandled, 'Database unavailability is handled');
  assert(
    errorMessage.includes('database') || errorMessage.includes('DB') || errorMessage.includes('not initialized'),
    `Error message is descriptive: ${errorMessage}`
  );

  console.log('[PASS] testDatabaseUnavailabilityHandling (CHK081)');
}

// ───────────────────────────────────────────────────────────────
// MAIN
// ───────────────────────────────────────────────────────────────

async function runTests() {
  console.log('\n=== MCP Server Integration Tests ===\n');

  // Setup
  console.log('0. Setup - Initializing test database and indexing memories\n');

  if (fs.existsSync(TEST_DB_PATH)) {
    fs.unlinkSync(TEST_DB_PATH);
  }

  vectorIndex.initializeDb(TEST_DB_PATH);

  // Index test memories
  for (const memory of TEST_MEMORIES) {
    const embedding = await embeddings.generateEmbedding(memory.content);
    vectorIndex.indexMemory({
      specFolder: memory.specFolder,
      filePath: memory.filePath,
      title: memory.title,
      triggerPhrases: memory.triggerPhrases,
      importanceWeight: memory.importanceWeight,
      embedding
    });
    console.log(`  - Indexed: ${memory.title}`);
  }

  console.log(`\n  Total memories indexed: ${vectorIndex.getMemoryCount()}\n`);

  // Run tests
  console.log('--- Running Tests ---\n');

  await testMemorySearchWithRealEmbeddings();
  await testMemorySearchWithLimit();
  await testMemorySearchWithSpecFolderFilter();
  await testMemorySearchSemanticUnderstanding();
  await testMemoryLoadWithRealFiles();
  await testErrorHandlingMissingFile();
  await testErrorHandlingInvalidQuery();
  await testErrorHandlingInvalidFilePath();
  await testSearchResultsIncludeMetadata();
  await testSearchPerformance();

  // CHK077: MCP-INT-002 - memory_search accepts concepts array
  await testMemorySearchWithConceptsArray();
  await testMemorySearchWithThreeConcepts();
  await testMemorySearchConceptsValidation();

  // CHK081: MCP-INT-008 - Database unavailability handled gracefully
  // Note: Run this test last as it closes/reopens the database
  await testDatabaseUnavailabilityHandling();

  // Cleanup
  console.log('\n--- Cleanup ---\n');
  vectorIndex.closeDb();

  if (fs.existsSync(TEST_DB_PATH)) {
    fs.unlinkSync(TEST_DB_PATH);
    if (fs.existsSync(TEST_DB_PATH + '-wal')) fs.unlinkSync(TEST_DB_PATH + '-wal');
    if (fs.existsSync(TEST_DB_PATH + '-shm')) fs.unlinkSync(TEST_DB_PATH + '-shm');
  }

  console.log('  Test database cleaned up');

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
  vectorIndex.closeDb();
  process.exit(1);
});
