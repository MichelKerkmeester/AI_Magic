#!/usr/bin/env node
/**
 * Migration Script: all-MiniLM-L6-v2 (384-dim) → nomic-embed-text-v1.5 (768-dim)
 *
 * This script:
 * 1. Backs up the current database
 * 2. Drops and recreates vec_memories table with 768 dimensions
 * 3. Re-embeds all memories with the new model using document prefix
 * 4. Updates embedding_model field
 *
 * IMPORTANT: Run this AFTER updating embeddings.js and vector-index.js
 *
 * Usage:
 *   node migrate-to-nomic.js           # Full migration
 *   node migrate-to-nomic.js --dry-run # Preview only, no changes
 *   node migrate-to-nomic.js --help    # Show help
 *
 * @version 1.0.0
 */

'use strict';

const fs = require('fs');
const path = require('path');

// ───────────────────────────────────────────────────────────────
// CONFIGURATION
// ───────────────────────────────────────────────────────────────

const NEW_MODEL = 'nomic-ai/nomic-embed-text-v1.5';
const NEW_DIM = 768;

// ───────────────────────────────────────────────────────────────
// HELP
// ───────────────────────────────────────────────────────────────

if (process.argv.includes('--help') || process.argv.includes('-h')) {
  console.log(`
Migration Script: Upgrade to nomic-embed-text-v1.5

This script migrates your memory index from all-MiniLM-L6-v2 (384-dim)
to nomic-embed-text-v1.5 (768-dim) for better semantic search quality.

Usage:
  node migrate-to-nomic.js           Full migration
  node migrate-to-nomic.js --dry-run Preview only, no changes
  node migrate-to-nomic.js --help    Show this help

What happens:
  1. Creates backup of current database
  2. Drops and recreates vec_memories table (384 → 768 dims)
  3. Re-embeds all memory files with new model
  4. Updates embedding_model field in metadata

Requirements:
  - Node.js 18+
  - @huggingface/transformers package
  - sqlite-vec extension

Time estimate: ~30 seconds per memory file
`);
  process.exit(0);
}

// ───────────────────────────────────────────────────────────────
// MIGRATION
// ───────────────────────────────────────────────────────────────

async function migrate() {
  const dryRun = process.argv.includes('--dry-run');

  console.log('');
  console.log('════════════════════════════════════════════════════════════════');
  console.log(dryRun
    ? '  MIGRATION DRY RUN - No changes will be made'
    : '  MIGRATION: all-MiniLM-L6-v2 → nomic-embed-text-v1.5');
  console.log('════════════════════════════════════════════════════════════════');
  console.log('');

  // Step 0: Load modules
  console.log('[0/6] Loading modules...');

  let vi, embeddings, sqliteVec, Database;
  try {
    vi = require('./lib/vector-index.js');
    embeddings = require('./lib/embeddings.js');
    Database = require('better-sqlite3');
    sqliteVec = require('sqlite-vec');
  } catch (e) {
    console.error(`    Failed to load modules: ${e.message}`);
    console.error('    Make sure you are running from the scripts/ directory');
    process.exit(1);
  }

  // Verify we're using the updated embeddings module
  const modelName = embeddings.getModelName();
  const embeddingDim = embeddings.getEmbeddingDimension();
  console.log(`    Model: ${modelName}`);
  console.log(`    Dimensions: ${embeddingDim}`);

  if (embeddingDim !== NEW_DIM) {
    console.error(`    ERROR: embeddings.js still using ${embeddingDim} dimensions`);
    console.error(`    Expected ${NEW_DIM} dimensions for ${NEW_MODEL}`);
    console.error('    Please update embeddings.js first!');
    process.exit(1);
  }

  const dbPath = vi.getDbPath();
  console.log(`    Database: ${dbPath}`);

  // Step 1: Backup
  console.log('');
  console.log('[1/6] Creating database backup...');
  const timestamp = Date.now();
  const backupPath = dbPath.replace('.sqlite', `.backup-${timestamp}.sqlite`);

  if (!dryRun) {
    try {
      fs.copyFileSync(dbPath, backupPath);
      console.log(`    ✓ Backup created: ${path.basename(backupPath)}`);
    } catch (e) {
      console.error(`    ✗ Backup failed: ${e.message}`);
      process.exit(1);
    }
  } else {
    console.log(`    Would create: ${path.basename(backupPath)}`);
  }

  // Step 2: Get all memories
  console.log('');
  console.log('[2/6] Loading memory index...');

  const db = vi.initializeDb();
  const memories = db.prepare(`
    SELECT id, file_path, spec_folder, title, anchor_id
    FROM memory_index
    ORDER BY id
  `).all();

  console.log(`    Found ${memories.length} memories to migrate`);

  if (memories.length === 0) {
    console.log('');
    console.log('    No memories to migrate. Done!');
    process.exit(0);
  }

  // Step 3: Drop and recreate vec_memories
  console.log('');
  console.log('[3/6] Recreating vector table (384 → 768 dims)...');

  if (!dryRun) {
    try {
      // Check if vec_memories exists
      const hasVecTable = db.prepare(`
        SELECT name FROM sqlite_master
        WHERE type='table' AND name='vec_memories'
      `).get();

      if (hasVecTable) {
        db.exec('DROP TABLE vec_memories');
        console.log('    ✓ Dropped old vec_memories table');
      }

      // Recreate with new dimensions
      db.exec(`
        CREATE VIRTUAL TABLE vec_memories USING vec0(
          embedding FLOAT[${NEW_DIM}]
        )
      `);
      console.log(`    ✓ Created new vec_memories table (${NEW_DIM} dimensions)`);

    } catch (e) {
      console.error(`    ✗ Failed to recreate table: ${e.message}`);
      console.error('    Restore from backup if needed');
      process.exit(1);
    }
  } else {
    console.log(`    Would drop and recreate vec_memories with FLOAT[${NEW_DIM}]`);
  }

  // Step 4: Re-embed all memories
  console.log('');
  console.log('[4/6] Re-embedding memories with nomic-embed-text-v1.5...');
  console.log(`    (This may take ${Math.ceil(memories.length * 0.5)} - ${Math.ceil(memories.length * 1)} seconds)`);
  console.log('');

  let success = 0;
  let failed = 0;
  let skipped = 0;
  const errors = [];
  const startTime = Date.now();

  for (let i = 0; i < memories.length; i++) {
    const mem = memories[i];
    const progress = `[${String(i + 1).padStart(3)}/${memories.length}]`;
    const title = (mem.title || mem.spec_folder || 'Untitled').substring(0, 40);

    // Read file content
    let content = '';
    try {
      if (mem.file_path && fs.existsSync(mem.file_path)) {
        content = fs.readFileSync(mem.file_path, 'utf-8');
      } else {
        console.log(`    ${progress} SKIP: ${title} (file not found)`);
        skipped++;
        continue;
      }
    } catch (e) {
      console.log(`    ${progress} SKIP: ${title} (${e.message})`);
      skipped++;
      continue;
    }

    if (content.trim().length === 0) {
      console.log(`    ${progress} SKIP: ${title} (empty content)`);
      skipped++;
      continue;
    }

    if (dryRun) {
      console.log(`    ${progress} Would re-embed: ${title}`);
      success++;
      continue;
    }

    try {
      // Generate new embedding with document prefix
      const embedding = await embeddings.generateDocumentEmbedding(content);

      if (!embedding) {
        throw new Error('Empty embedding returned');
      }

      if (embedding.length !== NEW_DIM) {
        throw new Error(`Wrong dimensions: ${embedding.length} (expected ${NEW_DIM})`);
      }

      // Insert into new table (BigInt for rowid)
      const embeddingBuffer = Buffer.from(embedding.buffer);
      db.prepare(`
        INSERT INTO vec_memories (rowid, embedding) VALUES (?, ?)
      `).run(BigInt(mem.id), embeddingBuffer);

      // Update metadata
      const now = new Date().toISOString();
      db.prepare(`
        UPDATE memory_index
        SET embedding_model = ?,
            embedding_generated_at = ?,
            embedding_status = 'success'
        WHERE id = ?
      `).run(NEW_MODEL, now, mem.id);

      // Progress output
      process.stdout.write(`\r    ${progress} ✓ ${title.padEnd(40)}`);
      success++;

    } catch (e) {
      errors.push({ id: mem.id, title, error: e.message });
      console.log(`\n    ${progress} ✗ ${title}: ${e.message}`);
      failed++;

      // Mark as failed in database
      db.prepare(`
        UPDATE memory_index
        SET embedding_status = 'failed',
            failure_reason = ?
        WHERE id = ?
      `).run(e.message, mem.id);
    }
  }

  const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
  console.log('\n');

  // Step 5: Verify
  console.log('[5/6] Verifying migration...');

  if (!dryRun) {
    try {
      const integrity = vi.verifyIntegrity();
      console.log(`    Total memories: ${integrity.totalMemories}`);
      console.log(`    Total vectors: ${integrity.totalVectors}`);
      console.log(`    Orphaned vectors: ${integrity.orphanedVectors}`);
      console.log(`    Missing vectors: ${integrity.missingVectors}`);
      console.log(`    Consistent: ${integrity.isConsistent ? '✓ YES' : '✗ NO'}`);
    } catch (e) {
      console.log(`    Verification error: ${e.message}`);
    }
  } else {
    console.log('    (Skipped in dry run)');
  }

  // Step 6: Summary
  console.log('');
  console.log('[6/6] Migration Summary');
  console.log('════════════════════════════════════════════════════════════════');
  console.log(`    Processed: ${memories.length} memories`);
  console.log(`    Success:   ${success}`);
  console.log(`    Failed:    ${failed}`);
  console.log(`    Skipped:   ${skipped}`);
  console.log(`    Time:      ${elapsed}s`);
  console.log('');

  if (!dryRun) {
    console.log(`    Backup:    ${path.basename(backupPath)}`);
    console.log('');
    console.log('    To rollback:');
    console.log(`    cp "${backupPath}" "${dbPath}"`);
  }

  console.log('');

  if (failed > 0) {
    console.log('    ⚠ Some memories failed to migrate:');
    for (const err of errors.slice(0, 5)) {
      console.log(`      - ID ${err.id}: ${err.error}`);
    }
    if (errors.length > 5) {
      console.log(`      ... and ${errors.length - 5} more`);
    }
    console.log('');
    console.log('    Run with --dry-run to preview without changes');
  }

  if (dryRun) {
    console.log('    This was a DRY RUN. No changes were made.');
    console.log('    Run without --dry-run to perform the actual migration.');
  } else if (failed === 0 && skipped === 0) {
    console.log('    ✓ Migration completed successfully!');
  }

  console.log('════════════════════════════════════════════════════════════════');
  console.log('');

  // Return exit code
  process.exit(failed > 0 ? 1 : 0);
}

// ───────────────────────────────────────────────────────────────
// RUN
// ───────────────────────────────────────────────────────────────

migrate().catch(e => {
  console.error('');
  console.error('Migration failed with error:');
  console.error(e);
  process.exit(1);
});
