#!/usr/bin/env node
/**
 * Semantic Search CLI - Vector search interface for load-related-context.sh
 *
 * Provides CLI access to semantic vector search functionality.
 * Called by the shell script to perform embedding generation and vector search.
 *
 * @module semantic-search
 * @version 10.0.0
 *
 * Usage:
 *   node semantic-search.js --query "authentication flow" --spec-folder "049-anchor"
 *   node semantic-search.js --multi "oauth jwt security" --spec-folder "049-anchor"
 *
 * Phase 5 - Tasks T047, T048
 */

'use strict';

const path = require('path');

// ───────────────────────────────────────────────────────────────
// CONFIGURATION
// ───────────────────────────────────────────────────────────────

const DEFAULT_LIMIT = 10;
const DEFAULT_MIN_SIMILARITY = 50;

// ───────────────────────────────────────────────────────────────
// ARGUMENT PARSING
// ───────────────────────────────────────────────────────────────

function parseArgs(args) {
  const parsed = {
    query: null,
    multi: null,
    specFolder: null,
    limit: DEFAULT_LIMIT,
    minSimilarity: DEFAULT_MIN_SIMILARITY
  };

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--query':
      case '-q':
        parsed.query = args[++i];
        break;
      case '--multi':
      case '-m':
        parsed.multi = args[++i];
        break;
      case '--spec-folder':
      case '-s':
        parsed.specFolder = args[++i];
        break;
      case '--limit':
      case '-l':
        parsed.limit = parseInt(args[++i], 10) || DEFAULT_LIMIT;
        break;
      case '--min-similarity':
        parsed.minSimilarity = parseInt(args[++i], 10) || DEFAULT_MIN_SIMILARITY;
        break;
      case '--help':
      case '-h':
        showHelp();
        process.exit(0);
    }
  }

  return parsed;
}

function showHelp() {
  console.log(`
Semantic Search CLI - Vector search for memory files

Usage:
  semantic-search.js --query <query> --spec-folder <folder>
  semantic-search.js --multi <concepts> --spec-folder <folder>

Options:
  --query, -q         Single query for vector search (T047)
  --multi, -m         Space-separated concepts for AND search (T048)
  --spec-folder, -s   Spec folder to filter results
  --limit, -l         Maximum results (default: 10)
  --min-similarity    Minimum similarity score 0-100 (default: 50)
  --help, -h          Show this help

Examples:
  semantic-search.js --query "authentication flow" --spec-folder "049-anchor"
  semantic-search.js --multi "oauth jwt security" --spec-folder "049-anchor"
`);
}

// ───────────────────────────────────────────────────────────────
// RESULT FORMATTING
// ───────────────────────────────────────────────────────────────

function formatVectorResults(results) {
  if (!results || results.length === 0) {
    console.log('No results found matching your query.');
    return;
  }

  console.log(`\n Found ${results.length} matching memories:\n`);
  console.log('Rank  Similarity  Spec Folder                    Anchor/Title');
  console.log('----  ----------  -----------------------------  ---------------------------');

  results.forEach((result, index) => {
    const rank = String(index + 1).padStart(4);
    const similarity = `${result.similarity.toFixed(1)}%`.padStart(10);
    const folder = (result.spec_folder || '').substring(0, 29).padEnd(29);
    const anchor = result.anchor_id || result.title || path.basename(result.file_path);

    console.log(`${rank}  ${similarity}  ${folder}  ${anchor}`);
  });

  console.log('\nUse "extract <anchor-id>" to load a specific section.');
}

function formatMultiResults(results, conceptCount) {
  if (!results || results.length === 0) {
    console.log('No results found matching ALL concepts.');
    return;
  }

  console.log(`\n Found ${results.length} memories matching all ${conceptCount} concepts:\n`);
  console.log('Rank  Avg Score   Concept Scores          Anchor/Title');
  console.log('----  ---------   ----------------------  ---------------------------');

  results.forEach((result, index) => {
    const rank = String(index + 1).padStart(4);
    const avgScore = `${result.avg_similarity.toFixed(1)}%`.padStart(9);
    const conceptScores = result.concept_similarities
      .map(s => `${s.toFixed(0)}%`)
      .join(' ')
      .padEnd(22);
    const anchor = result.anchor_id || result.title || path.basename(result.file_path);

    console.log(`${rank}  ${avgScore}   ${conceptScores}  ${anchor}`);
  });

  console.log('\nUse "extract <anchor-id>" to load a specific section.');
}

// ───────────────────────────────────────────────────────────────
// MAIN SEARCH FUNCTIONS
// ───────────────────────────────────────────────────────────────

async function performVectorSearch(query, options) {
  const { generateEmbedding } = require('./lib/embeddings');
  const { vectorSearch } = require('./lib/vector-index');

  console.log(`Generating embedding for: "${query}"...`);

  const embedding = await generateEmbedding(query);

  if (!embedding) {
    console.error('Failed to generate embedding for query');
    process.exit(1);
  }

  console.log('Searching vector index...');

  const results = vectorSearch(embedding, {
    limit: options.limit,
    specFolder: options.specFolder,
    minSimilarity: options.minSimilarity
  });

  formatVectorResults(results);
  return results;
}

async function performMultiConceptSearch(conceptsString, options) {
  const { generateEmbedding } = require('./lib/embeddings');
  const { multiConceptSearch } = require('./lib/vector-index');

  // Parse space-separated concepts
  const concepts = conceptsString.trim().split(/\s+/);

  if (concepts.length < 2) {
    console.error('Error: Multi-concept search requires at least 2 concepts');
    console.error('Usage: --multi "concept1 concept2 [concept3...]"');
    process.exit(1);
  }

  if (concepts.length > 5) {
    console.error('Error: Multi-concept search supports maximum 5 concepts');
    process.exit(1);
  }

  console.log(`Generating embeddings for ${concepts.length} concepts: ${concepts.join(', ')}...`);

  // Generate embeddings for all concepts
  const embeddings = [];
  for (const concept of concepts) {
    const embedding = await generateEmbedding(concept);
    if (!embedding) {
      console.error(`Failed to generate embedding for concept: "${concept}"`);
      process.exit(1);
    }
    embeddings.push(embedding);
  }

  console.log('Searching for memories matching ALL concepts...');

  const results = multiConceptSearch(embeddings, {
    limit: options.limit,
    specFolder: options.specFolder,
    minSimilarity: options.minSimilarity
  });

  formatMultiResults(results, concepts.length);
  return results;
}

// ───────────────────────────────────────────────────────────────
// MAIN ENTRY POINT
// ───────────────────────────────────────────────────────────────

async function main() {
  const args = parseArgs(process.argv.slice(2));

  // Validate arguments
  if (!args.query && !args.multi) {
    console.error('Error: Either --query or --multi is required');
    showHelp();
    process.exit(1);
  }

  if (args.query && args.multi) {
    console.error('Error: Cannot use both --query and --multi');
    process.exit(1);
  }

  try {
    if (args.query) {
      // Single vector search (T047)
      await performVectorSearch(args.query, {
        limit: args.limit,
        specFolder: args.specFolder,
        minSimilarity: args.minSimilarity
      });
    } else if (args.multi) {
      // Multi-concept AND search (T048)
      await performMultiConceptSearch(args.multi, {
        limit: args.limit,
        specFolder: args.specFolder,
        minSimilarity: args.minSimilarity
      });
    }
  } catch (error) {
    console.error(`Search failed: ${error.message}`);
    if (process.env.DEBUG) {
      console.error(error.stack);
    }
    process.exit(1);
  }
}

main();
