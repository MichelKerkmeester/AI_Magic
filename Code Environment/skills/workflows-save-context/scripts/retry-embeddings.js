#!/usr/bin/env node

/**
 * Retry Embeddings CLI
 *
 * Manually retry failed or pending embeddings.
 *
 * Usage:
 *   node retry-embeddings.js              # Process retry queue (up to 10)
 *   node retry-embeddings.js --all        # Process entire queue
 *   node retry-embeddings.js --reset <id> # Reset a failed embedding for retry
 *   node retry-embeddings.js --id <id>    # Retry specific embedding
 *
 * @module cli/retry-embeddings
 * @version 10.0.0
 */

'use strict';

const retryManager = require('./lib/retry-manager');
const vectorIndex = require('./lib/vector-index');
const fs = require('fs/promises');

// ───────────────────────────────────────────────────────────────
// MAIN
// ───────────────────────────────────────────────────────────────

async function main() {
  const args = process.argv.slice(2);

  try {
    // Initialize database
    vectorIndex.initializeDb();

    // Parse arguments
    if (args.includes('--help') || args.includes('-h')) {
      showHelp();
      return;
    }

    if (args.includes('--reset')) {
      const idIndex = args.indexOf('--reset') + 1;
      const id = parseInt(args[idIndex], 10);
      if (isNaN(id)) {
        console.error('Error: --reset requires a numeric ID');
        process.exit(1);
      }
      await resetEmbedding(id);
      return;
    }

    if (args.includes('--id')) {
      const idIndex = args.indexOf('--id') + 1;
      const id = parseInt(args[idIndex], 10);
      if (isNaN(id)) {
        console.error('Error: --id requires a numeric ID');
        process.exit(1);
      }
      await retrySpecific(id);
      return;
    }

    // Process queue
    const limit = args.includes('--all') ? 1000 : 10;
    await processQueue(limit);

  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

// ───────────────────────────────────────────────────────────────
// COMMANDS
// ───────────────────────────────────────────────────────────────

function showHelp() {
  console.log(`
Retry Embeddings CLI

Usage:
  node retry-embeddings.js              Process retry queue (up to 10)
  node retry-embeddings.js --all        Process entire queue
  node retry-embeddings.js --reset <id> Reset a failed embedding for retry
  node retry-embeddings.js --id <id>    Retry specific embedding
  node retry-embeddings.js --help       Show this help

Examples:
  node retry-embeddings.js
  node retry-embeddings.js --reset 42
  node retry-embeddings.js --id 15
`);
}

async function resetEmbedding(id) {
  console.log(`\nResetting embedding #${id}...`);

  const success = retryManager.resetForRetry(id);

  if (success) {
    console.log(`✓ Embedding #${id} reset for retry.`);
    console.log('  Run this script again to process the retry queue.\n');
  } else {
    console.log(`✗ Could not reset #${id}. Is it marked as failed?\n`);
  }
}

async function retrySpecific(id) {
  console.log(`\nRetrying embedding #${id}...`);

  const memory = vectorIndex.getMemory(id);
  if (!memory) {
    console.log(`✗ Memory #${id} not found.\n`);
    return;
  }

  // Load content from file
  let content = null;
  try {
    content = await fs.readFile(memory.file_path, 'utf-8');
  } catch (err) {
    console.log(`✗ Could not read file: ${memory.file_path}`);
    console.log(`  Error: ${err.message}\n`);
    return;
  }

  const result = await retryManager.retryEmbedding(id, content);

  if (result.success) {
    console.log(`✓ Embedding #${id} succeeded (${result.dimensions} dimensions)`);
  } else {
    console.log(`✗ Embedding #${id} failed: ${result.error}`);
    if (result.permanent) {
      console.log('  This failure is permanent (max retries exceeded).');
    }
  }
  console.log();
}

async function processQueue(limit) {
  console.log('\n=== Processing Retry Queue ===\n');

  const stats = retryManager.getRetryStats();
  console.log(`Queue size: ${stats.queueSize} (${stats.pending} pending, ${stats.retry} retry)`);

  if (stats.queueSize === 0) {
    console.log('✓ No embeddings to retry.\n');
    return;
  }

  console.log(`Processing up to ${limit} items...\n`);

  const results = await retryManager.processRetryQueue(limit);

  console.log('=== Results ===\n');
  console.log(`Processed: ${results.processed}`);
  console.log(`Succeeded: ${results.succeeded}`);
  console.log(`Failed:    ${results.failed}`);

  if (results.details.length > 0) {
    console.log('\nDetails:');
    for (const detail of results.details) {
      const status = detail.success ? '✓' : '✗';
      const info = detail.success
        ? `${detail.dimensions} dimensions`
        : detail.error;
      console.log(`  ${status} #${detail.id}: ${info}`);
    }
  }

  // Show remaining queue
  const newStats = retryManager.getRetryStats();
  if (newStats.queueSize > 0) {
    console.log(`\nRemaining in queue: ${newStats.queueSize}`);
  }

  console.log();
}

// ───────────────────────────────────────────────────────────────
// RUN
// ───────────────────────────────────────────────────────────────

main();
