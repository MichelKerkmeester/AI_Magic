/**
 * Unit Tests for Vector Index Module
 *
 * Tests sqlite-vec storage, synchronized rowid, CRUD operations
 *
 * @module tests/vector-index.test
 */

'use strict';

const path = require('path');
const fs = require('fs');
const os = require('os');

const libPath = path.join(__dirname, '..', 'lib');
const vectorIndex = require(path.join(libPath, 'vector-index.js'));

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
  const embedding = new Float32Array(768);
  for (let i = 0; i < 768; i++) {
    embedding[i] = Math.sin(seed * (i + 1)) * 0.5;
  }
  // Normalize
  const mag = Math.sqrt(embedding.reduce((s, v) => s + v * v, 0));
  for (let i = 0; i < 768; i++) {
    embedding[i] /= mag;
  }
  return embedding;
}

// ───────────────────────────────────────────────────────────────
// TEST DATABASE SETUP
// ───────────────────────────────────────────────────────────────

const TEST_DB_PATH = path.join(os.tmpdir(), `test-vector-index-${Date.now()}.sqlite`);

// ───────────────────────────────────────────────────────────────
// TESTS
// ───────────────────────────────────────────────────────────────

async function runTests() {
  console.log('\n=== Vector Index Module Tests ===\n');

  // Cleanup any existing test DB
  if (fs.existsSync(TEST_DB_PATH)) {
    fs.unlinkSync(TEST_DB_PATH);
  }

  // Test 1: Constants
  console.log('1. Constants');
  assert(vectorIndex.EMBEDDING_DIM === 768, 'EMBEDDING_DIM is 768');
  assert(vectorIndex.DEFAULT_DB_PATH.includes('.claude'), 'Default path includes .claude');

  // Test 2: Database initialization
  console.log('\n2. Database Initialization');
  const db = vectorIndex.initializeDb(TEST_DB_PATH);
  assert(db !== null, 'Database initialized');
  assert(fs.existsSync(TEST_DB_PATH), 'Database file created');

  // Verify WAL mode
  const walMode = db.pragma('journal_mode', { simple: true });
  assert(walMode === 'wal', 'WAL mode enabled');

  // Test 3: Schema verification
  console.log('\n3. Schema Verification');
  const tables = db.prepare(`
    SELECT name FROM sqlite_master WHERE type='table' ORDER BY name
  `).all().map(r => r.name);

  assert(tables.includes('memory_index'), 'memory_index table exists');
  assert(tables.includes('vec_memories'), 'vec_memories table exists');

  // Test 4: Index memory
  console.log('\n4. Index Memory');
  const embedding1 = createTestEmbedding(0.1);
  const id1 = vectorIndex.indexMemory({
    specFolder: 'test-spec',
    filePath: '/test/memory1.md',
    anchorId: 'section-1',
    title: 'Test Memory 1',
    triggerPhrases: ['test phrase', 'memory test'],
    importanceWeight: 0.8,
    embedding: embedding1
  });

  assert(typeof id1 === 'number', 'Returns numeric ID');
  assert(id1 > 0, 'ID is positive');

  // Test 5: Get memory
  console.log('\n5. Get Memory');
  const memory1 = vectorIndex.getMemory(id1);
  assert(memory1 !== null, 'Memory retrieved');
  assert(memory1.spec_folder === 'test-spec', 'Spec folder correct');
  assert(memory1.title === 'Test Memory 1', 'Title correct');
  assert(Array.isArray(memory1.trigger_phrases), 'Trigger phrases parsed as array');
  assert(memory1.trigger_phrases.length === 2, 'Two trigger phrases');
  assert(memory1.embedding_status === 'success', 'Embedding status is success');

  // Test 6: Verify synchronized rowid
  console.log('\n6. Rowid Synchronization');
  const vecRow = db.prepare('SELECT rowid FROM vec_memories WHERE rowid = ?').get(id1);
  assert(vecRow !== undefined, 'Vector exists with same rowid');
  assert(vecRow.rowid === id1, 'Rowids match');

  // Test 7: Upsert (update existing)
  console.log('\n7. Upsert Behavior');
  const embedding2 = createTestEmbedding(0.2);
  const id1Updated = vectorIndex.indexMemory({
    specFolder: 'test-spec',
    filePath: '/test/memory1.md',
    anchorId: 'section-1',
    title: 'Updated Memory 1',
    triggerPhrases: ['updated phrase'],
    importanceWeight: 0.9,
    embedding: embedding2
  });

  assert(id1Updated === id1, 'Same ID returned for upsert');
  const updated = vectorIndex.getMemory(id1);
  assert(updated.title === 'Updated Memory 1', 'Title updated');

  // Test 8: Multiple memories
  console.log('\n8. Multiple Memories');
  const embedding3 = createTestEmbedding(0.3);
  const id2 = vectorIndex.indexMemory({
    specFolder: 'test-spec',
    filePath: '/test/memory2.md',
    title: 'Test Memory 2',
    embedding: embedding3
  });

  const id3 = vectorIndex.indexMemory({
    specFolder: 'other-spec',
    filePath: '/other/memory.md',
    title: 'Other Spec Memory',
    embedding: createTestEmbedding(0.4)
  });

  assert(id2 !== id1, 'Different IDs for different memories');
  assert(id3 !== id2, 'Third memory has unique ID');

  const count = vectorIndex.getMemoryCount();
  assert(count === 3, `Total count is 3 (got ${count})`);

  // Test 9: Get by folder
  console.log('\n9. Get By Folder');
  const testSpecMemories = vectorIndex.getMemoriesByFolder('test-spec');
  assert(testSpecMemories.length === 2, 'Two memories in test-spec folder');

  const otherSpecMemories = vectorIndex.getMemoriesByFolder('other-spec');
  assert(otherSpecMemories.length === 1, 'One memory in other-spec folder');

  // Test 10: Delete memory
  console.log('\n10. Delete Memory');
  const deleted = vectorIndex.deleteMemory(id3);
  assert(deleted === true, 'Delete returns true');

  const deletedMemory = vectorIndex.getMemory(id3);
  assert(deletedMemory === null, 'Memory no longer exists');

  const deletedVec = db.prepare('SELECT rowid FROM vec_memories WHERE rowid = ?').get(id3);
  assert(deletedVec === undefined, 'Vector also deleted');

  // Test 11: Delete by path
  console.log('\n11. Delete By Path');
  const deletedByPath = vectorIndex.deleteMemoryByPath('test-spec', '/test/memory2.md');
  assert(deletedByPath === true, 'Delete by path returns true');

  const remaining = vectorIndex.getMemoryCount();
  assert(remaining === 1, `One memory remaining (got ${remaining})`);

  // Test 12: Verify integrity
  console.log('\n12. Verify Integrity');
  const integrity = vectorIndex.verifyIntegrity();
  assert(integrity.isConsistent === true, 'Database is consistent');
  assert(integrity.orphanedVectors === 0, 'No orphaned vectors');
  assert(integrity.missingVectors === 0, 'No missing vectors');

  // Test 13: Status counts
  console.log('\n13. Status Counts');
  const counts = vectorIndex.getStatusCounts();
  assert(counts.success >= 1, 'At least one success');
  assert(counts.pending === 0, 'No pending');
  assert(counts.failed === 0, 'No failed');

  // Cleanup
  vectorIndex.closeDb();

  // Test 14: File cleanup
  console.log('\n14. Cleanup');
  if (fs.existsSync(TEST_DB_PATH)) {
    fs.unlinkSync(TEST_DB_PATH);
    // Also remove WAL and SHM files
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
