/**
 * Integration Tests for Cross-Folder Search
 *
 * Tests search functionality across multiple spec folders,
 * validates spec_folder values in results, and tests folder filtering.
 *
 * @module tests/integration/cross-folder.integration.test
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

const TEST_DB_PATH = path.join(os.tmpdir(), `integration-cross-folder-${Date.now()}.sqlite`);

// Test memories distributed across multiple spec folders
// All memories have related content to test cross-folder search
const TEST_MEMORIES = [
  // Spec folder: frontend
  {
    specFolder: 'frontend',
    filePath: '/frontend/react-components.md',
    title: 'React Component Architecture',
    content: 'React component patterns including hooks, state management, and component composition.',
    triggerPhrases: ['react components', 'hooks', 'state management'],
    importanceWeight: 0.9
  },
  {
    specFolder: 'frontend',
    filePath: '/frontend/styling-guide.md',
    title: 'CSS Styling Guide',
    content: 'CSS-in-JS solutions, Tailwind CSS usage, and responsive design patterns.',
    triggerPhrases: ['css styling', 'tailwind', 'responsive design'],
    importanceWeight: 0.7
  },
  // Spec folder: backend
  {
    specFolder: 'backend',
    filePath: '/backend/api-design.md',
    title: 'REST API Design',
    content: 'RESTful API design patterns, endpoint conventions, and response formatting.',
    triggerPhrases: ['rest api', 'api design', 'endpoints'],
    importanceWeight: 0.85
  },
  {
    specFolder: 'backend',
    filePath: '/backend/database-patterns.md',
    title: 'Database Patterns',
    content: 'Database design patterns, query optimization, and ORM best practices.',
    triggerPhrases: ['database patterns', 'query optimization', 'orm'],
    importanceWeight: 0.8
  },
  // Spec folder: devops
  {
    specFolder: 'devops',
    filePath: '/devops/deployment.md',
    title: 'Deployment Pipeline',
    content: 'CI/CD pipeline configuration, Docker deployment, and Kubernetes orchestration.',
    triggerPhrases: ['deployment', 'ci/cd', 'docker', 'kubernetes'],
    importanceWeight: 0.9
  },
  {
    specFolder: 'devops',
    filePath: '/devops/monitoring.md',
    title: 'Monitoring Setup',
    content: 'Application monitoring with Prometheus, Grafana dashboards, and alerting rules.',
    triggerPhrases: ['monitoring', 'prometheus', 'grafana', 'alerting'],
    importanceWeight: 0.75
  },
  // Spec folder: shared (common patterns across domains)
  {
    specFolder: 'shared',
    filePath: '/shared/error-handling.md',
    title: 'Error Handling Patterns',
    content: 'Consistent error handling across frontend and backend, error types, and logging.',
    triggerPhrases: ['error handling', 'logging', 'error types'],
    importanceWeight: 0.95
  },
  {
    specFolder: 'shared',
    filePath: '/shared/authentication.md',
    title: 'Authentication Flow',
    content: 'OAuth2 authentication flow used across all services and frontend applications.',
    triggerPhrases: ['authentication', 'oauth2', 'jwt tokens'],
    importanceWeight: 0.9
  }
];

// ───────────────────────────────────────────────────────────────
// TESTS
// ───────────────────────────────────────────────────────────────

async function testSearchAcrossMultipleSpecFolders() {
  console.log('Test: search across multiple spec folders');

  // Generic query that should match memories across folders
  const queryEmbedding = await embeddings.generateEmbedding('development patterns and best practices');
  const results = vectorIndex.vectorSearch(queryEmbedding, { limit: 10 });

  // Collect unique spec folders in results
  const specFolders = new Set(results.map(r => r.spec_folder));

  assert(results.length > 0, 'Search returns results');
  assert(specFolders.size >= 2, `Results from multiple spec folders (got ${specFolders.size})`);

  console.log(`  Found ${results.length} results from folders: ${[...specFolders].join(', ')}`);

  console.log('[PASS] testSearchAcrossMultipleSpecFolders');
}

async function testResultsIncludeCorrectSpecFolderValues() {
  console.log('Test: results include correct spec_folder values');

  const queryEmbedding = await embeddings.generateEmbedding('API design and database');
  const results = vectorIndex.vectorSearch(queryEmbedding, { limit: 10 });

  // Verify spec_folder is present and valid
  const validFolders = ['frontend', 'backend', 'devops', 'shared'];

  for (const result of results) {
    assert(result.spec_folder !== undefined, `Result has spec_folder: ${result.title}`);
    assert(validFolders.includes(result.spec_folder), `Valid spec_folder: ${result.spec_folder}`);
  }

  console.log('[PASS] testResultsIncludeCorrectSpecFolderValues');
}

async function testFilteringBySingleSpecFolder() {
  console.log('Test: filtering by single spec folder');

  const queryEmbedding = await embeddings.generateEmbedding('development patterns');

  // Search only in frontend folder
  const frontendResults = vectorIndex.vectorSearch(queryEmbedding, {
    limit: 10,
    specFolder: 'frontend'
  });

  // All results should be from frontend
  const allFromFrontend = frontendResults.every(r => r.spec_folder === 'frontend');
  assert(allFromFrontend, 'All results from frontend folder');
  assert(frontendResults.length <= 2, `Max 2 frontend memories exist (got ${frontendResults.length})`);

  console.log('[PASS] testFilteringBySingleSpecFolder');
}

async function testFilteringByDifferentFolders() {
  console.log('Test: filtering by different folders');

  const queryEmbedding = await embeddings.generateEmbedding('configuration and setup');

  // Search in backend
  const backendResults = vectorIndex.vectorSearch(queryEmbedding, {
    limit: 10,
    specFolder: 'backend'
  });

  // Search in devops
  const devopsResults = vectorIndex.vectorSearch(queryEmbedding, {
    limit: 10,
    specFolder: 'devops'
  });

  // Results should be disjoint
  const backendIds = new Set(backendResults.map(r => r.id));
  const devopsIds = new Set(devopsResults.map(r => r.id));

  let overlap = false;
  for (const id of devopsIds) {
    if (backendIds.has(id)) {
      overlap = true;
      break;
    }
  }

  assert(!overlap, 'Different folder filters produce disjoint results');
  assert(
    backendResults.every(r => r.spec_folder === 'backend'),
    'Backend filter returns only backend results'
  );
  assert(
    devopsResults.every(r => r.spec_folder === 'devops'),
    'Devops filter returns only devops results'
  );

  console.log('[PASS] testFilteringByDifferentFolders');
}

async function testFilteringByNonexistentFolder() {
  console.log('Test: filtering by nonexistent folder');

  const queryEmbedding = await embeddings.generateEmbedding('any query');
  const results = vectorIndex.vectorSearch(queryEmbedding, {
    limit: 10,
    specFolder: 'nonexistent-folder'
  });

  assert(results.length === 0, 'Returns empty array for nonexistent folder');

  console.log('[PASS] testFilteringByNonexistentFolder');
}

async function testGetMemoriesByFolder() {
  console.log('Test: getMemoriesByFolder returns correct memories');

  const frontendMemories = vectorIndex.getMemoriesByFolder('frontend');
  const backendMemories = vectorIndex.getMemoriesByFolder('backend');
  const devopsMemories = vectorIndex.getMemoriesByFolder('devops');
  const sharedMemories = vectorIndex.getMemoriesByFolder('shared');

  assert(frontendMemories.length === 2, `Frontend has 2 memories (got ${frontendMemories.length})`);
  assert(backendMemories.length === 2, `Backend has 2 memories (got ${backendMemories.length})`);
  assert(devopsMemories.length === 2, `Devops has 2 memories (got ${devopsMemories.length})`);
  assert(sharedMemories.length === 2, `Shared has 2 memories (got ${sharedMemories.length})`);

  console.log('[PASS] testGetMemoriesByFolder');
}

async function testCrossFolderSemanticSearch() {
  console.log('Test: cross-folder semantic search');

  // Query about error handling should find shared memory
  const errorQuery = await embeddings.generateEmbedding('how to handle errors in the application');
  const errorResults = vectorIndex.vectorSearch(errorQuery, { limit: 5 });

  const hasSharedResult = errorResults.some(r => r.spec_folder === 'shared');
  assert(hasSharedResult, 'Error handling query finds shared folder memory');

  // Query about deployment should find devops memory
  const deployQuery = await embeddings.generateEmbedding('deploying to kubernetes cluster');
  const deployResults = vectorIndex.vectorSearch(deployQuery, { limit: 5 });

  const hasDevopsResult = deployResults.some(r => r.spec_folder === 'devops');
  assert(hasDevopsResult, 'Deployment query finds devops folder memory');

  console.log('[PASS] testCrossFolderSemanticSearch');
}

async function testFolderDistributionInResults() {
  console.log('Test: folder distribution in results');

  // Broad query that should hit all folders
  const broadQuery = await embeddings.generateEmbedding(
    'software development architecture deployment monitoring'
  );
  const results = vectorIndex.vectorSearch(broadQuery, { limit: 8 });

  // Count results per folder
  const folderCounts = {};
  for (const result of results) {
    folderCounts[result.spec_folder] = (folderCounts[result.spec_folder] || 0) + 1;
  }

  console.log(`  Distribution: ${JSON.stringify(folderCounts)}`);

  const foldersWithResults = Object.keys(folderCounts).length;
  assert(foldersWithResults >= 3, `Results from at least 3 folders (got ${foldersWithResults})`);

  console.log('[PASS] testFolderDistributionInResults');
}

async function testMultiConceptSearchAcrossFolders() {
  console.log('Test: multi-concept search across folders');

  const concept1 = await embeddings.generateEmbedding('frontend react components');
  const concept2 = await embeddings.generateEmbedding('backend api design');

  const results = vectorIndex.multiConceptSearch([concept1, concept2], {
    limit: 5,
    minSimilarity: 20
  });

  assert(Array.isArray(results), 'Returns array');

  if (results.length > 0) {
    // Check that results have per-concept similarities
    assert(results[0].concept_similarities !== undefined, 'Has per-concept similarities');
    assert(results[0].concept_similarities.length === 2, 'Has 2 concept similarities');

    // Verify spec_folder is present
    assert(results[0].spec_folder !== undefined, 'Result has spec_folder');
  }

  console.log('[PASS] testMultiConceptSearchAcrossFolders');
}

async function testSpecFolderConsistency() {
  console.log('Test: spec_folder consistency between index and search');

  // Get all memories
  const allMemories = [
    ...vectorIndex.getMemoriesByFolder('frontend'),
    ...vectorIndex.getMemoriesByFolder('backend'),
    ...vectorIndex.getMemoriesByFolder('devops'),
    ...vectorIndex.getMemoriesByFolder('shared')
  ];

  // For each memory, verify it can be found by search and has correct spec_folder
  let allConsistent = true;
  for (const memory of allMemories) {
    const queryEmbedding = await embeddings.generateEmbedding(memory.title);
    const results = vectorIndex.vectorSearch(queryEmbedding, {
      limit: 1,
      specFolder: memory.spec_folder
    });

    if (results.length === 0 || results[0].id !== memory.id) {
      // Memory not found as expected
      allConsistent = false;
      console.log(`  Inconsistency for: ${memory.title}`);
    }
  }

  assert(allConsistent, 'All memories consistent between index and search');

  console.log('[PASS] testSpecFolderConsistency');
}

async function testCrossFolderSearchPerformance() {
  console.log('Test: cross-folder search performance');

  const query = await embeddings.generateEmbedding('generic development query');

  // Time unfiltered search
  const startUnfiltered = Date.now();
  for (let i = 0; i < 50; i++) {
    vectorIndex.vectorSearch(query, { limit: 10 });
  }
  const unfilteredTime = Date.now() - startUnfiltered;
  const avgUnfiltered = unfilteredTime / 50;

  // Time filtered search
  const startFiltered = Date.now();
  for (let i = 0; i < 50; i++) {
    vectorIndex.vectorSearch(query, { limit: 10, specFolder: 'backend' });
  }
  const filteredTime = Date.now() - startFiltered;
  const avgFiltered = filteredTime / 50;

  assert(avgUnfiltered < 10, `Unfiltered search < 10ms (got ${avgUnfiltered.toFixed(2)}ms)`);
  assert(avgFiltered < 10, `Filtered search < 10ms (got ${avgFiltered.toFixed(2)}ms)`);

  console.log(`  Unfiltered: ${avgUnfiltered.toFixed(2)}ms, Filtered: ${avgFiltered.toFixed(2)}ms`);

  console.log('[PASS] testCrossFolderSearchPerformance');
}

// ───────────────────────────────────────────────────────────────
// MAIN
// ───────────────────────────────────────────────────────────────

async function runTests() {
  console.log('\n=== Cross-Folder Search Integration Tests ===\n');

  // Setup
  console.log('0. Setup - Initializing test database and indexing memories across folders\n');

  if (fs.existsSync(TEST_DB_PATH)) {
    fs.unlinkSync(TEST_DB_PATH);
  }

  vectorIndex.initializeDb(TEST_DB_PATH);

  // Index test memories
  const folderCounts = {};
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

    folderCounts[memory.specFolder] = (folderCounts[memory.specFolder] || 0) + 1;
    console.log(`  - [${memory.specFolder}] ${memory.title}`);
  }

  console.log(`\n  Total memories indexed: ${vectorIndex.getMemoryCount()}`);
  console.log(`  Folders: ${JSON.stringify(folderCounts)}\n`);

  // Run tests
  console.log('--- Running Tests ---\n');

  await testSearchAcrossMultipleSpecFolders();
  await testResultsIncludeCorrectSpecFolderValues();
  await testFilteringBySingleSpecFolder();
  await testFilteringByDifferentFolders();
  await testFilteringByNonexistentFolder();
  await testGetMemoriesByFolder();
  await testCrossFolderSemanticSearch();
  await testFolderDistributionInResults();
  await testMultiConceptSearchAcrossFolders();
  await testSpecFolderConsistency();
  await testCrossFolderSearchPerformance();

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
