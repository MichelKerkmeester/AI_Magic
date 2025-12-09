#!/usr/bin/env node

/**
 * List Failed Embeddings CLI
 *
 * Lists all permanently failed embeddings in the memory index.
 *
 * Usage: node list-failed-embeddings.js [--json]
 *
 * @module cli/list-failed-embeddings
 * @version 10.0.0
 */

'use strict';

const retryManager = require('./lib/retry-manager');
const vectorIndex = require('./lib/vector-index');

// ───────────────────────────────────────────────────────────────
// MAIN
// ───────────────────────────────────────────────────────────────

async function main() {
  const args = process.argv.slice(2);
  const jsonOutput = args.includes('--json');

  try {
    // Initialize database
    vectorIndex.initializeDb();

    // Get stats
    const stats = retryManager.getRetryStats();

    // Get failed embeddings
    const failed = retryManager.getFailedEmbeddings();

    if (jsonOutput) {
      // JSON output for programmatic use
      console.log(JSON.stringify({
        stats,
        failed: failed.map(f => ({
          id: f.id,
          specFolder: f.spec_folder,
          filePath: f.file_path,
          title: f.title,
          retryCount: f.retry_count,
          failureReason: f.failure_reason,
          updatedAt: f.updated_at
        }))
      }, null, 2));
    } else {
      // Human-readable output
      console.log('\n=== Embedding Status ===\n');
      console.log(`Success:  ${stats.success}`);
      console.log(`Pending:  ${stats.pending}`);
      console.log(`Retry:    ${stats.retry}`);
      console.log(`Failed:   ${stats.failed}`);
      console.log(`Total:    ${stats.total}`);

      if (failed.length === 0) {
        console.log('\n✓ No failed embeddings.\n');
      } else {
        console.log(`\n=== Failed Embeddings (${failed.length}) ===\n`);

        for (const f of failed) {
          console.log(`ID: ${f.id}`);
          console.log(`  Spec:   ${f.spec_folder}`);
          console.log(`  File:   ${f.file_path}`);
          console.log(`  Title:  ${f.title || '(none)'}`);
          console.log(`  Retries: ${f.retry_count}`);
          console.log(`  Reason: ${f.failure_reason || '(unknown)'}`);
          console.log(`  Updated: ${f.updated_at}`);
          console.log();
        }

        console.log('To reset and retry, run:');
        console.log('  node scripts/retry-embeddings.js --reset <id>\n');
      }
    }

  } catch (error) {
    if (jsonOutput) {
      console.log(JSON.stringify({ error: error.message }));
    } else {
      console.error('Error:', error.message);
    }
    process.exit(1);
  }
}

main();
