#!/usr/bin/env node

/**
 * Verify Index - Validate Memory Index Integrity
 *
 * Checks the semantic memory index for:
 * - Missing embeddings
 * - Orphaned entries (files no longer exist)
 * - Schema integrity
 * - Statistics
 *
 * Usage:
 *   node verify-index.js           # Run full verification
 *   node verify-index.js --fix     # Fix orphaned entries
 *   node verify-index.js --json    # Output as JSON
 *
 * @module cli/verify-index
 * @version 10.0.0
 */

'use strict';

const fs = require('fs');
const path = require('path');
const vectorIndex = require('./lib/vector-index');
const retryManager = require('./lib/retry-manager');

// ───────────────────────────────────────────────────────────────
// VERIFICATION CHECKS
// ───────────────────────────────────────────────────────────────

/**
 * Get all memories from the index
 * @returns {Array} - All memory records
 */
function getAllMemories() {
  const db = vectorIndex.getDb();
  return db.prepare('SELECT * FROM memory_index ORDER BY created_at DESC').all();
}

/**
 * Check for orphaned entries (files that no longer exist)
 * @param {Array} memories - Memory records
 * @returns {Array} - Orphaned entries
 */
function findOrphanedEntries(memories) {
  return memories.filter(m => !fs.existsSync(m.file_path));
}

/**
 * Check for missing embeddings
 * @param {Array} memories - Memory records
 * @returns {Object} - Missing embedding stats
 */
function checkEmbeddings(memories) {
  const db = vectorIndex.getDb();

  const successCount = memories.filter(m => m.embedding_status === 'success').length;
  const pendingCount = memories.filter(m => m.embedding_status === 'pending').length;
  const retryCount = memories.filter(m => m.embedding_status === 'retry').length;
  const failedCount = memories.filter(m => m.embedding_status === 'failed').length;

  // Verify vec_memories table has matching entries
  const vecCount = db.prepare('SELECT COUNT(*) as count FROM vec_memories').get().count;

  return {
    total: memories.length,
    success: successCount,
    pending: pendingCount,
    retry: retryCount,
    failed: failedCount,
    vecTableCount: vecCount,
    synced: vecCount === successCount
  };
}

/**
 * Check spec folder distribution
 * @param {Array} memories - Memory records
 * @returns {Object} - Spec folder counts
 */
function getSpecFolderStats(memories) {
  const stats = {};
  for (const m of memories) {
    stats[m.spec_folder] = (stats[m.spec_folder] || 0) + 1;
  }
  return stats;
}

/**
 * Check trigger phrase coverage
 * @param {Array} memories - Memory records
 * @returns {Object} - Trigger phrase stats
 */
function checkTriggerPhrases(memories) {
  let withPhrases = 0;
  let totalPhrases = 0;

  for (const m of memories) {
    if (m.trigger_phrases && m.trigger_phrases !== '[]') {
      withPhrases++;
      try {
        const phrases = JSON.parse(m.trigger_phrases);
        totalPhrases += phrases.length;
      } catch {
        // Invalid JSON
      }
    }
  }

  return {
    memoriesWithPhrases: withPhrases,
    memoriesWithoutPhrases: memories.length - withPhrases,
    totalPhrases,
    avgPhrasesPerMemory: memories.length > 0 ? (totalPhrases / memories.length).toFixed(1) : 0
  };
}

/**
 * Remove orphaned entries from the index
 * @param {Array} orphaned - Orphaned entries to remove
 * @returns {number} - Count of removed entries
 */
function removeOrphanedEntries(orphaned) {
  let removed = 0;
  for (const entry of orphaned) {
    try {
      vectorIndex.deleteMemory(entry.id);
      removed++;
    } catch (err) {
      console.warn(`  Warning: Could not remove entry ${entry.id}: ${err.message}`);
    }
  }
  return removed;
}

// ───────────────────────────────────────────────────────────────
// MAIN
// ───────────────────────────────────────────────────────────────

async function main() {
  const args = process.argv.slice(2);
  const doFix = args.includes('--fix');
  const jsonOutput = args.includes('--json');

  try {
    // Initialize database
    vectorIndex.initializeDb();

    // Run verification
    const memories = getAllMemories();
    const orphaned = findOrphanedEntries(memories);
    const embeddingStats = checkEmbeddings(memories);
    const specStats = getSpecFolderStats(memories);
    const triggerStats = checkTriggerPhrases(memories);
    const retryStats = retryManager.getRetryStats();

    // Determine health status
    const issues = [];

    if (orphaned.length > 0) {
      issues.push(`${orphaned.length} orphaned entries (missing files)`);
    }

    if (!embeddingStats.synced) {
      issues.push('Vector table out of sync with memory index');
    }

    if (embeddingStats.failed > 0) {
      issues.push(`${embeddingStats.failed} permanently failed embeddings`);
    }

    if (embeddingStats.pending > 0) {
      issues.push(`${embeddingStats.pending} pending embeddings`);
    }

    const healthy = issues.length === 0;

    // Build report
    const report = {
      healthy,
      issues,
      stats: {
        totalMemories: memories.length,
        embeddings: embeddingStats,
        specFolders: specStats,
        triggerPhrases: triggerStats,
        retryQueue: retryStats
      },
      orphaned: orphaned.map(o => ({
        id: o.id,
        specFolder: o.spec_folder,
        filePath: o.file_path
      }))
    };

    if (jsonOutput) {
      console.log(JSON.stringify(report, null, 2));
    } else {
      // Human-readable output
      console.log('\n=== Memory Index Verification ===\n');

      // Health status
      const statusIcon = healthy ? '✓' : '✗';
      console.log(`Status: ${statusIcon} ${healthy ? 'HEALTHY' : 'ISSUES FOUND'}`);

      if (issues.length > 0) {
        console.log('\nIssues:');
        for (const issue of issues) {
          console.log(`  - ${issue}`);
        }
      }

      // Stats
      console.log('\n--- Statistics ---');
      console.log(`Total memories: ${memories.length}`);
      console.log(`Spec folders:   ${Object.keys(specStats).length}`);

      console.log('\n--- Embeddings ---');
      console.log(`Success: ${embeddingStats.success}`);
      console.log(`Pending: ${embeddingStats.pending}`);
      console.log(`Retry:   ${embeddingStats.retry}`);
      console.log(`Failed:  ${embeddingStats.failed}`);
      console.log(`Vec sync: ${embeddingStats.synced ? 'OK' : 'OUT OF SYNC'}`);

      console.log('\n--- Trigger Phrases ---');
      console.log(`With phrases:    ${triggerStats.memoriesWithPhrases}`);
      console.log(`Without phrases: ${triggerStats.memoriesWithoutPhrases}`);
      console.log(`Total phrases:   ${triggerStats.totalPhrases}`);
      console.log(`Average/memory:  ${triggerStats.avgPhrasesPerMemory}`);

      if (orphaned.length > 0) {
        console.log(`\n--- Orphaned Entries (${orphaned.length}) ---`);
        for (const o of orphaned.slice(0, 10)) {
          console.log(`  ID ${o.id}: ${o.spec_folder} - ${path.basename(o.file_path)}`);
        }
        if (orphaned.length > 10) {
          console.log(`  ... and ${orphaned.length - 10} more`);
        }

        if (doFix) {
          console.log('\n--- Fixing Orphaned Entries ---');
          const removed = removeOrphanedEntries(orphaned);
          console.log(`Removed ${removed} orphaned entries.`);
        } else {
          console.log('\nRun with --fix to remove orphaned entries.');
        }
      }

      console.log();
    }

    process.exit(healthy ? 0 : 1);

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
