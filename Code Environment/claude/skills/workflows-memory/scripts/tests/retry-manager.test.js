/**
 * Unit Tests for Retry Manager
 *
 * Tests retry queue, backoff logic, and status transitions
 *
 * @module tests/retry-manager.test
 */

'use strict';

const path = require('path');
const fs = require('fs');
const os = require('os');

const libPath = path.join(__dirname, '..', 'lib');
const vectorIndex = require(path.join(libPath, 'vector-index.js'));
const retryManager = require(path.join(libPath, 'retry-manager.js'));
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

const TEST_DB_PATH = path.join(os.tmpdir(), `test-retry-${Date.now()}.sqlite`);

// ───────────────────────────────────────────────────────────────
// TESTS
// ───────────────────────────────────────────────────────────────

async function runTests() {
  console.log('\n=== Retry Manager Tests ===\n');

  // Cleanup
  if (fs.existsSync(TEST_DB_PATH)) {
    fs.unlinkSync(TEST_DB_PATH);
  }

  // Initialize database
  vectorIndex.initializeDb(TEST_DB_PATH);

  // Test 1: Constants
  console.log('1. Constants');
  assert(retryManager.MAX_RETRIES === 3, 'MAX_RETRIES is 3');
  assert(retryManager.BACKOFF_DELAYS.length === 3, 'Three backoff delays');
  assert(retryManager.BACKOFF_DELAYS[0] === 60000, 'First delay is 1 minute');
  assert(retryManager.BACKOFF_DELAYS[1] === 300000, 'Second delay is 5 minutes');
  assert(retryManager.BACKOFF_DELAYS[2] === 900000, 'Third delay is 15 minutes');

  // Test 2: Initial retry stats (empty)
  console.log('\n2. Initial Stats');
  const initialStats = retryManager.getRetryStats();
  assert(initialStats.total === 0, 'No memories initially');
  assert(initialStats.queueSize === 0, 'Queue is empty');

  // Test 3: Create a successful memory
  console.log('\n3. Create Successful Memory');
  const embedding1 = createTestEmbedding(0.1);
  const id1 = vectorIndex.indexMemory({
    specFolder: 'test-spec',
    filePath: '/test/success.md',
    title: 'Success Test',
    embedding: embedding1
  });

  const stats1 = retryManager.getRetryStats();
  assert(stats1.success === 1, 'One successful memory');
  assert(stats1.queueSize === 0, 'Queue still empty');

  // Test 4: Create a pending memory (manually set status)
  console.log('\n4. Create Pending Memory');
  const db = vectorIndex.getDb();
  const now = new Date().toISOString();

  db.prepare(`
    INSERT INTO memory_index (spec_folder, file_path, title, created_at, updated_at, embedding_status)
    VALUES (?, ?, ?, ?, ?, 'pending')
  `).run('test-spec', '/test/pending.md', 'Pending Test', now, now);

  const stats2 = retryManager.getRetryStats();
  assert(stats2.pending === 1, 'One pending memory');
  assert(stats2.queueSize === 1, 'One item in queue');

  // Test 5: Get retry queue
  console.log('\n5. Get Retry Queue');
  const queue1 = retryManager.getRetryQueue(10);
  assert(queue1.length === 1, 'One item in retry queue');
  assert(queue1[0].embedding_status === 'pending', 'Item is pending');

  // Test 6: Create a retry memory with backoff elapsed
  console.log('\n6. Create Retry Memory with Backoff');
  // retry_count=0 means first retry (1 min backoff), so 2 minutes ago is enough
  const oldTime = new Date(Date.now() - 120000).toISOString(); // 2 minutes ago

  db.prepare(`
    INSERT INTO memory_index (spec_folder, file_path, title, created_at, updated_at,
                              embedding_status, retry_count, last_retry_at, failure_reason)
    VALUES (?, ?, ?, ?, ?, 'retry', 0, ?, 'Test failure')
  `).run('test-spec', '/test/retry.md', 'Retry Test', now, now, oldTime);

  const queue2 = retryManager.getRetryQueue(10);
  assert(queue2.length >= 1, 'At least one item in retry queue');
  const hasRetryItem = queue2.some(q => q.file_path === '/test/retry.md');
  assert(hasRetryItem, 'Retry item with elapsed backoff is in queue');

  // Test 7: Retry with backoff not elapsed
  console.log('\n7. Backoff Not Elapsed');
  const recentTime = new Date().toISOString(); // Now

  db.prepare(`
    INSERT INTO memory_index (spec_folder, file_path, title, created_at, updated_at,
                              embedding_status, retry_count, last_retry_at, failure_reason)
    VALUES (?, ?, ?, ?, ?, 'retry', 1, ?, 'Test failure')
  `).run('test-spec', '/test/recent-retry.md', 'Recent Retry', now, now, recentTime);

  const queue3 = retryManager.getRetryQueue(10);
  const hasRecentItem = queue3.some(q => q.file_path === '/test/recent-retry.md');
  assert(!hasRecentItem, 'Recent retry excluded by backoff');

  // Test 8: Get failed embeddings (empty initially)
  console.log('\n8. Get Failed Embeddings');
  const failed1 = retryManager.getFailedEmbeddings();
  assert(failed1.length === 0, 'No failed embeddings initially');

  // Test 9: Mark as failed
  console.log('\n9. Mark as Failed');
  const pendingId = queue1[0].id;
  retryManager.markAsFailed(pendingId, 'Test permanent failure');

  const failed2 = retryManager.getFailedEmbeddings();
  assert(failed2.length === 1, 'One failed embedding');
  assert(failed2[0].failure_reason === 'Test permanent failure', 'Failure reason recorded');

  // Test 10: Reset for retry
  console.log('\n10. Reset for Retry');
  const resetResult = retryManager.resetForRetry(pendingId);
  assert(resetResult === true, 'Reset successful');

  const resetMemory = vectorIndex.getMemory(pendingId);
  assert(resetMemory.embedding_status === 'retry', 'Status changed to retry');
  assert(resetMemory.retry_count === 0, 'Retry count reset to 0');

  // Test 11: Stats after operations
  console.log('\n11. Final Stats');
  const finalStats = retryManager.getRetryStats();
  assert(finalStats.success === 1, 'One success');
  assert(finalStats.retry >= 2, 'Multiple retries');
  assert(finalStats.failed === 0, 'No failed (was reset)');

  // Test 12: Retry embedding (with content)
  console.log('\n12. Retry Embedding');
  const testContent = 'This is test content for embedding generation.';
  const retryResult = await retryManager.retryEmbedding(pendingId, testContent);

  assert(retryResult.success === true, 'Retry succeeded');
  assert(retryResult.dimensions === 384, 'Correct dimensions');

  const retriedMemory = vectorIndex.getMemory(pendingId);
  assert(retriedMemory.embedding_status === 'success', 'Status is now success');

  // Cleanup
  vectorIndex.closeDb();

  console.log('\n13. Cleanup');
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
