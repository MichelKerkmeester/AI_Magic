#!/usr/bin/env node

/**
 * Index All - Batch Memory Indexer
 *
 * Rebuilds the semantic memory index from source files.
 * Uses model singleton pattern for efficient batch processing.
 *
 * PERFORMANCE: Loads MiniLM model ONCE and reuses for all files.
 * - Old approach: 100 files = 100 process spawns = 100 model loads (~10GB total)
 * - New approach: 100 files = 1 process = 1 model load (~100MB total)
 *
 * Usage:
 *   node index-all.js <manifest-file>   - Index files listed in manifest
 *   node index-all.js --scan            - Auto-scan specs/memory directories
 *   node index-all.js --help            - Show help
 *
 * @module cli/index-all
 * @version 10.0.0
 */

'use strict';

const fs = require('fs').promises;
const fsSync = require('fs');
const path = require('path');

// Import our modules (model singleton persists across all files!)
const embeddings = require('./lib/embeddings');
const vectorIndex = require('./lib/vector-index');
const { extractTriggerPhrases } = require('./lib/trigger-extractor');

// ───────────────────────────────────────────────────────────────
// CONFIGURATION
// ───────────────────────────────────────────────────────────────

const CONFIG = {
  SPEC_PATTERN: 'specs/*/memory',
  MEMORY_EXTENSION: '.md',
  BATCH_SIZE: 50,
  PROGRESS_INTERVAL: 10
};

// ───────────────────────────────────────────────────────────────
// FILE DISCOVERY
// ───────────────────────────────────────────────────────────────

/**
 * Scan for memory files in specs directories (recursive)
 *
 * Supports nested structures like:
 *   specs/001-foo/memory/
 *   specs/001-foo/002-bar/memory/
 *   specs/001-foo/002-bar/003-baz/memory/
 *
 * @param {string} baseDir - Base directory to scan
 * @returns {string[]} - Array of file paths
 */
async function scanForMemoryFiles(baseDir) {
  const files = [];
  const specsDir = path.join(baseDir, 'specs');

  if (!fsSync.existsSync(specsDir)) {
    console.log(`[index-all] No specs directory found at: ${specsDir}`);
    return files;
  }

  /**
   * Recursively scan directory for memory folders
   * @param {string} dir - Directory to scan
   * @param {number} depth - Current depth (max 5 to prevent infinite loops)
   */
  async function scanDirectory(dir, depth = 0) {
    if (depth > 5) return; // Safety limit for recursion depth

    try {
      const entries = await fs.readdir(dir, { withFileTypes: true });

      for (const entry of entries) {
        if (!entry.isDirectory()) continue;

        const entryPath = path.join(dir, entry.name);

        // Check if this is a memory directory
        if (entry.name === 'memory') {
          try {
            const memoryFiles = await fs.readdir(entryPath);
            for (const file of memoryFiles) {
              if (file.endsWith(CONFIG.MEMORY_EXTENSION)) {
                files.push(path.join(entryPath, file));
              }
            }
          } catch (err) {
            console.warn(`[index-all] Could not read ${entryPath}: ${err.message}`);
          }
        } else if (!entry.name.startsWith('.') && entry.name !== 'node_modules') {
          // Recurse into subdirectories (skip hidden dirs and node_modules)
          await scanDirectory(entryPath, depth + 1);
        }
      }
    } catch (err) {
      console.warn(`[index-all] Could not scan ${dir}: ${err.message}`);
    }
  }

  await scanDirectory(specsDir);
  return files;
}

/**
 * Read manifest file (one path per line)
 * @param {string} manifestPath - Path to manifest file
 * @returns {string[]} - Array of file paths
 */
async function readManifest(manifestPath) {
  const content = await fs.readFile(manifestPath, 'utf-8');
  return content
    .trim()
    .split('\n')
    .filter(line => line.length > 0 && !line.startsWith('#'));
}

// ───────────────────────────────────────────────────────────────
// FILE PROCESSING
// ───────────────────────────────────────────────────────────────

/**
 * Extract spec folder name from file path
 * @param {string} filePath - Full file path
 * @returns {string} - Spec folder name
 */
function extractSpecFolder(filePath) {
  // Path pattern: .../specs/<spec-folder>/memory/<file>.md
  const parts = filePath.split(path.sep);
  const memoryIndex = parts.indexOf('memory');

  if (memoryIndex > 0) {
    return parts[memoryIndex - 1];
  }

  // Fallback: use parent directory name
  return path.basename(path.dirname(path.dirname(filePath)));
}

/**
 * Extract title from memory content
 * @param {string} content - File content
 * @returns {string} - Extracted title
 */
function extractTitle(content) {
  // Try to find H1 header
  const h1Match = content.match(/^#\s+(.+)$/m);
  if (h1Match) {
    return h1Match[1].trim();
  }

  // Try to find title in frontmatter
  const titleMatch = content.match(/^title:\s*["']?(.+?)["']?\s*$/m);
  if (titleMatch) {
    return titleMatch[1].trim();
  }

  // Fallback: first non-empty line
  const lines = content.split('\n').filter(l => l.trim().length > 0);
  if (lines.length > 0) {
    return lines[0].slice(0, 100).trim();
  }

  return 'Untitled Memory';
}

/**
 * Calculate importance weight from content
 * @param {string} content - File content
 * @returns {number} - Weight between 0.0 and 1.0
 */
function calculateImportance(content) {
  const length = content.length;

  // Length-based heuristic
  if (length > 10000) return 0.9;
  if (length > 5000) return 0.8;
  if (length > 2000) return 0.7;
  if (length > 1000) return 0.6;
  if (length > 500) return 0.5;
  return 0.4;
}

/**
 * Process a single file
 * @param {string} filePath - Path to memory file
 * @returns {Object} - Result with success status
 */
async function processFile(filePath) {
  try {
    const content = await fs.readFile(filePath, 'utf-8');
    const specFolder = extractSpecFolder(filePath);
    const title = extractTitle(content);
    const importanceWeight = calculateImportance(content);
    const triggerPhrases = extractTriggerPhrases(content);

    // Generate embedding (model already loaded, reused!)
    const embedding = await embeddings.generateEmbedding(content);

    if (!embedding) {
      return {
        success: false,
        error: 'Empty content or embedding generation failed'
      };
    }

    // Index in sqlite-vec
    const memoryId = vectorIndex.indexMemory({
      specFolder,
      filePath,
      anchorId: null,
      title,
      embedding,
      triggerPhrases,
      importanceWeight
    });

    return {
      success: true,
      memoryId,
      specFolder,
      title
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

// ───────────────────────────────────────────────────────────────
// CLEANUP HANDLER
// ───────────────────────────────────────────────────────────────

/**
 * Cleanup handler to properly close database before exit
 * Prevents "mutex lock failed" error from better-sqlite3
 */
function cleanup() {
  try {
    vectorIndex.closeDb();
  } catch (err) {
    // Ignore cleanup errors
  }
}

// Register cleanup handlers
process.on('exit', cleanup);
process.on('SIGINT', () => { cleanup(); process.exit(130); });
process.on('SIGTERM', () => { cleanup(); process.exit(143); });

// ───────────────────────────────────────────────────────────────
// MAIN
// ───────────────────────────────────────────────────────────────

function showHelp() {
  console.log(`
Index All - Batch Memory Indexer

Usage:
  node index-all.js <manifest-file>   Index files listed in manifest
  node index-all.js --scan            Auto-scan specs/*/memory directories
  node index-all.js --scan <dir>      Scan from specific directory
  node index-all.js --help            Show this help

Examples:
  node index-all.js manifest.txt
  node index-all.js --scan
  node index-all.js --scan /path/to/project

The manifest file should contain one file path per line.
Lines starting with # are treated as comments.
`);
}

async function main() {
  const args = process.argv.slice(2);

  if (args.includes('--help') || args.includes('-h')) {
    showHelp();
    return;
  }

  let files = [];

  if (args.includes('--scan')) {
    const scanIndex = args.indexOf('--scan');
    const baseDir = args[scanIndex + 1] || process.cwd();
    console.log(`\n[index-all] Scanning for memory files in: ${baseDir}`);
    files = await scanForMemoryFiles(baseDir);
  } else if (args.length > 0) {
    const manifestPath = args[0];
    console.log(`\n[index-all] Reading manifest: ${manifestPath}`);
    files = await readManifest(manifestPath);
  } else {
    console.error('Error: Please provide a manifest file or use --scan');
    console.error('Run with --help for usage information');
    process.exit(1);
  }

  if (files.length === 0) {
    console.log('[index-all] No files to process.');
    return;
  }

  console.log(`[index-all] Found ${files.length} files to index.`);

  // Initialize database
  vectorIndex.initializeDb();

  // Pre-warm the model
  console.log('[index-all] Loading embedding model (one-time)...');
  const loadStart = Date.now();
  await embeddings.generateEmbedding('warmup');
  console.log(`[index-all] Model loaded in ${Date.now() - loadStart}ms\n`);

  // Process files
  let successCount = 0;
  let errorCount = 0;
  const errors = [];
  const startTime = Date.now();

  for (let i = 0; i < files.length; i++) {
    const filePath = files[i];
    const specFolder = extractSpecFolder(filePath);
    const fileName = path.basename(filePath);

    // Progress indicator
    const progress = `[${i + 1}/${files.length}]`;
    process.stdout.write(`${progress} Indexing: ${specFolder}/${fileName}...`);

    const result = await processFile(filePath);

    if (result.success) {
      console.log(` OK (ID: ${result.memoryId})`);
      successCount++;
    } else {
      console.log(` FAILED: ${result.error}`);
      errorCount++;
      errors.push({ file: filePath, error: result.error });
    }

    // Progress update every N files
    if ((i + 1) % CONFIG.PROGRESS_INTERVAL === 0) {
      const elapsed = (Date.now() - startTime) / 1000;
      const rate = (i + 1) / elapsed;
      const remaining = Math.round((files.length - i - 1) / rate);
      console.log(`    [Progress: ${successCount} success, ${errorCount} failed, ~${remaining}s remaining]`);
    }
  }

  // Summary
  const totalTime = ((Date.now() - startTime) / 1000).toFixed(1);
  console.log('\n[index-all] === Summary ===');
  console.log(`[index-all] Processed: ${files.length} files`);
  console.log(`[index-all] Success:   ${successCount}`);
  console.log(`[index-all] Errors:    ${errorCount}`);
  console.log(`[index-all] Time:      ${totalTime}s`);

  if (errors.length > 0) {
    console.log('\n[index-all] Failed files:');
    for (const e of errors) {
      console.log(`  - ${e.file}: ${e.error}`);
    }
  }

  // Get final stats
  const stats = vectorIndex.getStats();
  console.log(`\n[index-all] Index contains ${stats.total} memories (${stats.success} with embeddings)`);

  // Clean up before exit
  cleanup();
  process.exit(errorCount > 0 ? 1 : 0);
}

// ───────────────────────────────────────────────────────────────
// RUN
// ───────────────────────────────────────────────────────────────

main().catch(err => {
  console.error('[index-all] Fatal error:', err);
  cleanup();
  process.exit(1);
});
