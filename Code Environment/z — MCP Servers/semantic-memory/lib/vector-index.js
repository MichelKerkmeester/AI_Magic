/**
 * Vector Index Module - sqlite-vec based vector storage
 *
 * Provides persistent vector storage for memory embeddings using
 * sqlite-vec extension. Supports cross-spec-folder search with
 * synchronized rowid linkage between metadata and vectors.
 *
 * @module vector-index
 * @version 10.0.0
 */

'use strict';

const Database = require('better-sqlite3');
const sqliteVec = require('sqlite-vec');
const path = require('path');
const os = require('os');
const fs = require('fs');

// ───────────────────────────────────────────────────────────────
// CONFIGURATION
// ───────────────────────────────────────────────────────────────

const EMBEDDING_DIM = 768;
// Project-local database - works for both Claude Code and Opencode
const DEFAULT_DB_PATH = path.join(process.cwd(), '.opencode', 'memory', 'memory-index.sqlite');
const DB_PERMISSIONS = 0o600; // Owner read/write only

// ───────────────────────────────────────────────────────────────
// DATABASE SINGLETON
// ───────────────────────────────────────────────────────────────

let db = null;
let dbPath = DEFAULT_DB_PATH;
let sqliteVecAvailable = true; // Track if sqlite-vec is available (NFR-R01)
let shuttingDown = false;

/**
 * Initialize or get database connection
 * Creates schema on first use
 *
 * @param {string} [customPath] - Override default database path (for testing)
 * @returns {Object} better-sqlite3 database instance
 */
function initializeDb(customPath = null) {
  if (db && !customPath) {
    return db;
  }

  const targetPath = customPath || dbPath;

  // Ensure directory exists
  const dir = path.dirname(targetPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
  }

  // Open database
  db = new Database(targetPath);

  // Load sqlite-vec extension with graceful degradation (NFR-R01, CHK123)
  try {
    sqliteVec.load(db);
    sqliteVecAvailable = true;
  } catch (vecError) {
    sqliteVecAvailable = false;
    console.warn(`[vector-index] sqlite-vec extension not available: ${vecError.message}`);
    console.warn('[vector-index] Falling back to anchor-only mode (no vector search)');
    console.warn('[vector-index] Install sqlite-vec: brew install sqlite-vec (macOS)');
  }

  // Enable WAL mode for concurrent access (FR-010b)
  db.pragma('journal_mode = WAL');

  // Create schema if needed
  createSchema(db);

  // Set file permissions (T021)
  if (!customPath) {
    try {
      fs.chmodSync(targetPath, DB_PERMISSIONS);
    } catch (err) {
      console.warn(`[vector-index] Could not set permissions on ${targetPath}: ${err.message}`);
    }
  }

  dbPath = targetPath;
  return db;
}

/**
 * Create database schema
 * @param {Object} database - better-sqlite3 instance
 */
function createSchema(database) {
  // Check if tables exist
  const tableExists = database.prepare(`
    SELECT name FROM sqlite_master
    WHERE type='table' AND name='memory_index'
  `).get();

  if (tableExists) {
    return; // Schema already exists
  }

  // Create memory_index table (metadata only)
  database.exec(`
    CREATE TABLE memory_index (
      id INTEGER PRIMARY KEY,
      spec_folder TEXT NOT NULL,
      file_path TEXT NOT NULL,
      anchor_id TEXT,
      title TEXT,
      trigger_phrases TEXT,
      importance_weight REAL DEFAULT 0.5,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      embedding_model TEXT,
      embedding_generated_at TEXT,
      embedding_status TEXT DEFAULT 'pending' CHECK(embedding_status IN ('pending', 'success', 'failed', 'retry')),
      retry_count INTEGER DEFAULT 0,
      last_retry_at TEXT,
      failure_reason TEXT,
      UNIQUE(spec_folder, file_path, anchor_id)
    )
  `);

  // Create vec_memories virtual table (only if sqlite-vec is available)
  if (sqliteVecAvailable) {
    database.exec(`
      CREATE VIRTUAL TABLE vec_memories USING vec0(
        embedding FLOAT[${EMBEDDING_DIM}]
      )
    `);
  }

  // Create indexes
  database.exec(`
    CREATE INDEX idx_spec_folder ON memory_index(spec_folder);
    CREATE INDEX idx_created_at ON memory_index(created_at);
    CREATE INDEX idx_importance ON memory_index(importance_weight DESC);
    CREATE INDEX idx_embedding_status ON memory_index(embedding_status);
    CREATE INDEX idx_retry_eligible ON memory_index(embedding_status, retry_count, last_retry_at)
  `);

  console.warn('[vector-index] Schema created successfully');
}

// ───────────────────────────────────────────────────────────────
// CORE OPERATIONS
// ───────────────────────────────────────────────────────────────

/**
 * Index a memory with its embedding (synchronized INSERT)
 *
 * @param {Object} params - Memory parameters
 * @param {string} params.specFolder - Spec folder name
 * @param {string} params.filePath - Full path to memory file
 * @param {string} [params.anchorId] - Optional anchor ID
 * @param {string} [params.title] - Memory title
 * @param {string[]} [params.triggerPhrases] - Trigger phrases array
 * @param {number} [params.importanceWeight=0.5] - Importance score 0-1
 * @param {Float32Array} params.embedding - 384-dim embedding vector
 * @returns {number} Inserted row ID
 */
function indexMemory(params) {
  const database = initializeDb();

  const {
    specFolder,
    filePath,
    anchorId = null,
    title = null,
    triggerPhrases = [],
    importanceWeight = 0.5,
    embedding
  } = params;

  if (!embedding || embedding.length !== EMBEDDING_DIM) {
    throw new Error(`Embedding must be ${EMBEDDING_DIM} dimensions`);
  }

  const now = new Date().toISOString();
  const triggersJson = JSON.stringify(triggerPhrases);
  const embeddingBuffer = Buffer.from(embedding.buffer);

  // Check for existing entry
  const existing = database.prepare(`
    SELECT id FROM memory_index
    WHERE spec_folder = ? AND file_path = ? AND (anchor_id = ? OR (anchor_id IS NULL AND ? IS NULL))
  `).get(specFolder, filePath, anchorId, anchorId);

  if (existing) {
    // Update existing entry
    return updateMemory({
      id: existing.id,
      title,
      triggerPhrases,
      importanceWeight,
      embedding
    });
  }

  // Synchronized INSERT in transaction
  const insertMemory = database.transaction(() => {
    // Determine status based on sqlite-vec availability
    const embeddingStatus = sqliteVecAvailable ? 'success' : 'pending';

    // Step 1: Insert metadata
    const result = database.prepare(`
      INSERT INTO memory_index (
        spec_folder, file_path, anchor_id, title, trigger_phrases,
        importance_weight, created_at, updated_at, embedding_model,
        embedding_generated_at, embedding_status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      specFolder, filePath, anchorId, title, triggersJson,
      importanceWeight, now, now, 'Xenova/all-MiniLM-L6-v2', now, embeddingStatus
    );

    // sqlite-vec requires BigInt for explicit rowid insertion
    const rowId = BigInt(result.lastInsertRowid);

    // Step 2: Insert embedding with synchronized rowid (only if sqlite-vec available)
    if (sqliteVecAvailable) {
      database.prepare(`
        INSERT INTO vec_memories (rowid, embedding) VALUES (?, ?)
      `).run(rowId, embeddingBuffer);
    }

    return Number(rowId);
  });

  return insertMemory();
}

/**
 * Update an existing memory entry
 *
 * @param {Object} params - Update parameters
 * @param {number} params.id - Row ID to update
 * @param {string} [params.title] - New title
 * @param {string[]} [params.triggerPhrases] - New trigger phrases
 * @param {number} [params.importanceWeight] - New importance
 * @param {Float32Array} [params.embedding] - New embedding
 * @returns {number} Updated row ID
 */
function updateMemory(params) {
  const database = initializeDb();

  const { id, title, triggerPhrases, importanceWeight, embedding } = params;

  const now = new Date().toISOString();

  const updateMemoryTx = database.transaction(() => {
    // Build dynamic update
    const updates = ['updated_at = ?'];
    const values = [now];

    if (title !== undefined) {
      updates.push('title = ?');
      values.push(title);
    }
    if (triggerPhrases !== undefined) {
      updates.push('trigger_phrases = ?');
      values.push(JSON.stringify(triggerPhrases));
    }
    if (importanceWeight !== undefined) {
      updates.push('importance_weight = ?');
      values.push(importanceWeight);
    }
    if (embedding) {
      updates.push('embedding_model = ?');
      updates.push('embedding_generated_at = ?');
      updates.push('embedding_status = ?');
      values.push('Xenova/all-MiniLM-L6-v2', now, 'success');
    }

    values.push(id);

    database.prepare(`
      UPDATE memory_index SET ${updates.join(', ')} WHERE id = ?
    `).run(...values);

    // Update embedding if provided (only if sqlite-vec available)
    if (embedding && sqliteVecAvailable) {
      const embeddingBuffer = Buffer.from(embedding.buffer);

      // Delete old vector (BigInt for vec_memories rowid)
      database.prepare('DELETE FROM vec_memories WHERE rowid = ?').run(BigInt(id));

      // Insert new vector (BigInt required for explicit rowid)
      database.prepare(`
        INSERT INTO vec_memories (rowid, embedding) VALUES (?, ?)
      `).run(BigInt(id), embeddingBuffer);
    }

    return id;
  });

  // Execute transaction (better-sqlite3 uses BEGIN IMMEDIATE by default)
  return updateMemoryTx();
}

/**
 * Delete a memory entry (synchronized DELETE)
 *
 * @param {number} id - Row ID to delete
 * @returns {boolean} True if deleted
 */
function deleteMemory(id) {
  const database = initializeDb();

  const deleteMemoryTx = database.transaction(() => {
    // Delete from vec_memories first (only if sqlite-vec available)
    if (sqliteVecAvailable) {
      database.prepare('DELETE FROM vec_memories WHERE rowid = ?').run(BigInt(id));
    }

    // Delete from memory_index
    const result = database.prepare('DELETE FROM memory_index WHERE id = ?').run(id);

    return result.changes > 0;
  });

  return deleteMemoryTx();
}

/**
 * Delete memory by spec folder and file path
 *
 * @param {string} specFolder - Spec folder name
 * @param {string} filePath - File path
 * @param {string} [anchorId] - Optional anchor ID
 * @returns {boolean} True if deleted
 */
function deleteMemoryByPath(specFolder, filePath, anchorId = null) {
  const database = initializeDb();

  const row = database.prepare(`
    SELECT id FROM memory_index
    WHERE spec_folder = ? AND file_path = ? AND (anchor_id = ? OR (anchor_id IS NULL AND ? IS NULL))
  `).get(specFolder, filePath, anchorId, anchorId);

  if (row) {
    return deleteMemory(row.id);
  }
  return false;
}

/**
 * Get memory by ID
 *
 * @param {number} id - Row ID
 * @returns {Object|null} Memory metadata or null
 */
function getMemory(id) {
  const database = initializeDb();

  const row = database.prepare('SELECT * FROM memory_index WHERE id = ?').get(id);

  if (row && row.trigger_phrases) {
    row.trigger_phrases = JSON.parse(row.trigger_phrases);
  }

  return row || null;
}

/**
 * Get all memories for a spec folder
 *
 * @param {string} specFolder - Spec folder name
 * @returns {Object[]} Array of memory metadata
 */
function getMemoriesByFolder(specFolder) {
  const database = initializeDb();

  const rows = database.prepare(`
    SELECT * FROM memory_index WHERE spec_folder = ? ORDER BY created_at DESC
  `).all(specFolder);

  return rows.map(row => {
    if (row.trigger_phrases) {
      row.trigger_phrases = JSON.parse(row.trigger_phrases);
    }
    return row;
  });
}

/**
 * Get total memory count
 *
 * @returns {number} Total number of indexed memories
 */
function getMemoryCount() {
  const database = initializeDb();
  const result = database.prepare('SELECT COUNT(*) as count FROM memory_index').get();
  return result.count;
}

/**
 * Get count by embedding status
 *
 * @returns {Object} Counts by status
 */
function getStatusCounts() {
  const database = initializeDb();

  const rows = database.prepare(`
    SELECT embedding_status, COUNT(*) as count
    FROM memory_index
    GROUP BY embedding_status
  `).all();

  const counts = { pending: 0, success: 0, failed: 0, retry: 0 };
  for (const row of rows) {
    counts[row.embedding_status] = row.count;
  }

  return counts;
}

/**
 * Get overall statistics for the memory index
 * @returns {Object} Stats including total, success, pending, etc.
 */
function getStats() {
  const counts = getStatusCounts();
  const total = counts.pending + counts.success + counts.failed + counts.retry;

  return {
    total,
    ...counts
  };
}

// ───────────────────────────────────────────────────────────────
// VECTOR SEARCH
// ───────────────────────────────────────────────────────────────

/**
 * Search memories by vector similarity
 *
 * @param {Float32Array|Buffer} queryEmbedding - Query vector (384-dim)
 * @param {Object} [options] - Search options
 * @param {number} [options.limit=10] - Maximum results
 * @param {string} [options.specFolder] - Filter by spec folder
 * @param {number} [options.minSimilarity=0] - Minimum similarity (0-100)
 * @returns {Object[]} Ranked results with similarity scores
 */
function vectorSearch(queryEmbedding, options = {}) {
  // Check if sqlite-vec is available (NFR-R01 graceful degradation)
  if (!sqliteVecAvailable) {
    console.warn('[vector-index] Vector search unavailable - sqlite-vec not loaded');
    return [];
  }

  const database = initializeDb();

  const { limit = 10, specFolder = null, minSimilarity = 0 } = options;

  // Convert to Buffer if Float32Array
  const queryBuffer = queryEmbedding instanceof Buffer
    ? queryEmbedding
    : Buffer.from(queryEmbedding.buffer);

  // Convert minSimilarity (0-100) to max distance (0-2 for cosine)
  // similarity = (1 - distance/2) * 100, so distance = 2 * (1 - similarity/100)
  const maxDistance = 2 * (1 - minSimilarity / 100);

  // Refactored to compute distance only once using subquery pattern
  const sql = `
    SELECT sub.*,
           ROUND((1 - sub.distance / 2) * 100, 2) as similarity
    FROM (
      SELECT m.*, vec_distance_cosine(v.embedding, ?) as distance
      FROM memory_index m
      JOIN vec_memories v ON m.id = v.rowid
      WHERE m.embedding_status = 'success'
      ${specFolder ? 'AND m.spec_folder = ?' : ''}
    ) sub
    WHERE sub.distance <= ?
    ORDER BY sub.distance ASC
    LIMIT ?
  `;

  const params = specFolder
    ? [queryBuffer, specFolder, maxDistance, limit]
    : [queryBuffer, maxDistance, limit];

  const rows = database.prepare(sql).all(...params);

  return rows.map(row => {
    if (row.trigger_phrases) {
      row.trigger_phrases = JSON.parse(row.trigger_phrases);
    }
    return row;
  });
}

/**
 * Multi-concept AND search - finds memories matching ALL concepts
 *
 * @param {Array<Float32Array|Buffer>} conceptEmbeddings - Array of concept vectors (2-5)
 * @param {Object} [options] - Search options
 * @param {number} [options.limit=10] - Maximum results
 * @param {string} [options.specFolder] - Filter by spec folder
 * @param {number} [options.minSimilarity=50] - Minimum similarity per concept (0-100)
 * @returns {Object[]} Results matching ALL concepts with per-concept scores
 */
function multiConceptSearch(conceptEmbeddings, options = {}) {
  // Check if sqlite-vec is available (NFR-R01 graceful degradation)
  if (!sqliteVecAvailable) {
    console.warn('[vector-index] Multi-concept search unavailable - sqlite-vec not loaded');
    return [];
  }

  const database = initializeDb();

  const concepts = conceptEmbeddings;
  if (!Array.isArray(concepts) || concepts.length < 2 || concepts.length > 5) {
    throw new Error('Multi-concept search requires 2-5 concepts');
  }

  const { limit = 10, specFolder = null, minSimilarity = 50 } = options;

  // Convert to Buffers
  const conceptBuffers = concepts.map(c =>
    c instanceof Buffer ? c : Buffer.from(c.buffer)
  );

  // Convert minSimilarity to max distance
  const maxDistance = 2 * (1 - minSimilarity / 100);

  // Build subquery with distances, then calculate similarities and averages in outer query
  const distanceExpressions = conceptBuffers.map((_, i) =>
    `vec_distance_cosine(v.embedding, ?) as dist_${i}`
  ).join(', ');

  const distanceFilters = conceptBuffers.map((_, i) =>
    `vec_distance_cosine(v.embedding, ?) <= ?`
  ).join(' AND ');

  const folderFilter = specFolder ? 'AND m.spec_folder = ?' : '';

  // Outer query expressions using the computed distances
  const similaritySelect = conceptBuffers.map((_, i) =>
    `ROUND((1 - sub.dist_${i} / 2) * 100, 2) as similarity_${i}`
  ).join(', ');

  const avgDistanceExpr = conceptBuffers.map((_, i) => `sub.dist_${i}`).join(' + ');

  // Build SQL with subquery pattern
  const sql = `
    SELECT
      sub.*,
      ${similaritySelect},
      (${avgDistanceExpr}) / ${concepts.length} as avg_distance
    FROM (
      SELECT
        m.*,
        ${distanceExpressions}
      FROM memory_index m
      JOIN vec_memories v ON m.id = v.rowid
      WHERE m.embedding_status = 'success'
        ${folderFilter}
        AND ${distanceFilters}
    ) sub
    ORDER BY avg_distance ASC
    LIMIT ?
  `;

  // Build params: distances in subquery, folder?, filters, limit
  const params = [
    ...conceptBuffers,                              // for distance expressions
    ...(specFolder ? [specFolder] : []),            // folder filter
    ...conceptBuffers.flatMap(b => [b, maxDistance]), // for distance filter conditions
    limit
  ];

  const rows = database.prepare(sql).all(...params);

  return rows.map(row => {
    if (row.trigger_phrases) {
      row.trigger_phrases = JSON.parse(row.trigger_phrases);
    }
    // Add concept_similarities array and calculate average
    row.concept_similarities = conceptBuffers.map((_, i) => row[`similarity_${i}`]);
    row.avg_similarity = row.concept_similarities.reduce((a, b) => a + b, 0) / concepts.length;
    return row;
  });
}

// ───────────────────────────────────────────────────────────────
// DATABASE UTILITIES
// ───────────────────────────────────────────────────────────────

/**
 * Close database connection safely
 */
function safeClose() {
  if (shuttingDown) return;
  shuttingDown = true;
  closeDb();
}

/**
 * Close database connection
 */
function closeDb() {
  if (db) {
    db.close();
    db = null;
  }
}

/**
 * Get database path
 * @returns {string} Current database path
 */
function getDbPath() {
  return dbPath;
}

/**
 * Get raw database instance (for advanced queries)
 * @returns {Object} better-sqlite3 instance
 */
function getDb() {
  return initializeDb();
}

/**
 * Verify database integrity
 *
 * @returns {Object} Integrity check results
 */
function verifyIntegrity() {
  if (!sqliteVecAvailable) {
    return {
      isConsistent: false,
      error: 'Vector search unavailable - sqlite-vec extension not loaded',
      totalMemories: 0,
      memoriesWithEmbeddings: 0,
      orphanedVectors: 0,
      missingVectors: 0
    };
  }

  const database = initializeDb();

  // Count mismatched rowids
  const orphanedVectors = database.prepare(`
    SELECT COUNT(*) as count FROM vec_memories v
    WHERE NOT EXISTS (SELECT 1 FROM memory_index m WHERE m.id = v.rowid)
  `).get().count;

  const missingVectors = database.prepare(`
    SELECT COUNT(*) as count FROM memory_index m
    WHERE m.embedding_status = 'success'
    AND NOT EXISTS (SELECT 1 FROM vec_memories v WHERE v.rowid = m.id)
  `).get().count;

  const totalMemories = database.prepare('SELECT COUNT(*) as count FROM memory_index').get().count;
  const totalVectors = database.prepare('SELECT COUNT(*) as count FROM vec_memories').get().count;

  return {
    totalMemories,
    totalVectors,
    orphanedVectors,
    missingVectors,
    isConsistent: orphanedVectors === 0 && missingVectors === 0
  };
}

/**
 * Verify database integrity with file existence check
 * Checks that all indexed memory files actually exist on disk.
 *
 * @param {string} basePath - Base path for resolving relative file paths
 * @returns {Object} Detailed integrity report
 */
function verifyIntegrityWithPaths(basePath) {
  const database = initializeDb();
  const entries = database.prepare('SELECT * FROM memory_index').all();

  const orphaned = [];
  const valid = [];

  for (const entry of entries) {
    // Resolve relative path against base
    const fullPath = entry.file_path.startsWith('/')
      ? entry.file_path
      : path.join(basePath, entry.file_path);

    if (fs.existsSync(fullPath)) {
      valid.push(entry);
    } else {
      orphaned.push({
        id: entry.id,
        specFolder: entry.spec_folder,
        filePath: entry.file_path,
        resolvedPath: fullPath
      });
    }
  }

  return {
    total: entries.length,
    validCount: valid.length,
    orphanedCount: orphaned.length,
    orphanedEntries: orphaned,
    isConsistent: orphaned.length === 0
  };
}

/**
 * Remove orphaned entries (missing files) from database
 * Uses transaction for atomic deletion from both tables.
 *
 * @param {string} basePath - Base path for resolving relative file paths
 * @returns {Object} Cleanup results with before/after counts
 */
function cleanupOrphans(basePath) {
  const database = initializeDb();

  // First, get integrity report
  const report = verifyIntegrityWithPaths(basePath);

  if (report.orphanedCount === 0) {
    console.warn('[vector-index] No orphaned entries found');
    return { removed: 0, before: report.total, after: report.total, message: 'No orphaned entries found' };
  }

  console.warn(`[vector-index] Found ${report.orphanedCount} orphaned entries, starting cleanup...`);

  // Cleanup in transaction
  const cleanupTx = database.transaction(() => {
    for (const orphan of report.orphanedEntries) {
      // Delete from vec_memories first (if sqlite-vec available)
      if (sqliteVecAvailable) {
        database.prepare('DELETE FROM vec_memories WHERE rowid = ?')
          .run(BigInt(orphan.id));
      }
      // Delete from memory_index
      database.prepare('DELETE FROM memory_index WHERE id = ?')
        .run(orphan.id);
    }
    return report.orphanedCount;
  });

  const removed = cleanupTx();

  console.warn(`[vector-index] Cleanup complete: removed ${removed} orphaned entries`);
  console.warn(`[vector-index] Database: ${report.total} -> ${report.total - removed} entries`);

  return {
    removed,
    before: report.total,
    after: report.total - removed,
    entries: report.orphanedEntries.map(e => e.specFolder)
  };
}

// ───────────────────────────────────────────────────────────────
// MODULE EXPORTS
// ───────────────────────────────────────────────────────────────

/**
 * Check if vector search is available (sqlite-vec loaded)
 * @returns {boolean} True if vector search is available
 */
function isVectorSearchAvailable() {
  return sqliteVecAvailable;
}

module.exports = {
  // Initialization
  initializeDb,
  closeDb,
  safeClose,
  getDb,
  getDbPath,

  // Core operations
  indexMemory,
  updateMemory,
  deleteMemory,
  deleteMemoryByPath,

  // Queries
  getMemory,
  getMemoriesByFolder,
  getMemoryCount,
  getStatusCounts,
  getStats,
  verifyIntegrity,
  verifyIntegrityWithPaths,
  cleanupOrphans,

  // Search
  vectorSearch,
  multiConceptSearch,
  isVectorSearchAvailable,

  // Constants
  EMBEDDING_DIM,
  DEFAULT_DB_PATH
};
