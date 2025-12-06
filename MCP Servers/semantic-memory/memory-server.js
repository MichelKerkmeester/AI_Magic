#!/usr/bin/env node

/**
 * Memory MCP Server (Standalone)
 *
 * Exposes semantic memory operations as MCP tools for Claude Code integration.
 * Provides memory_search and memory_load tools for accessing saved conversation context.
 *
 * Tools:
 * - memory_search: Semantic search across all memories
 * - memory_load: Load specific memory by spec folder and anchor ID
 *
 * @version 10.0.0
 * @module semantic-memory/memory-server
 */

'use strict';

const path = require('path');
const fs = require('fs');

// Server directory (standalone)
const SERVER_DIR = __dirname;
const NODE_MODULES = path.join(SERVER_DIR, 'node_modules');
const LIB_DIR = path.join(SERVER_DIR, 'lib');

// Add node_modules to module resolution
module.paths.unshift(NODE_MODULES);

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const {
  ListToolsRequestSchema,
  CallToolRequestSchema
} = require('@modelcontextprotocol/sdk/types.js');

// Load lib modules from local lib directory
const vectorIndex = require(path.join(LIB_DIR, 'vector-index.js'));
const embeddings = require(path.join(LIB_DIR, 'embeddings.js'));
const triggerMatcher = require(path.join(LIB_DIR, 'trigger-matcher.js'));

// ───────────────────────────────────────────────────────────────
// SERVER INITIALIZATION
// ───────────────────────────────────────────────────────────────

const server = new Server(
  {
    name: 'memory-server',
    version: '10.0.0'
  },
  {
    capabilities: {
      tools: {}
    }
  }
);

// ───────────────────────────────────────────────────────────────
// TOOL DEFINITIONS
// ───────────────────────────────────────────────────────────────

/**
 * List available tools
 */
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: 'memory_search',
      description: 'Search conversation memories semantically using vector similarity. Returns ranked results with similarity scores.',
      inputSchema: {
        type: 'object',
        properties: {
          query: {
            type: 'string',
            description: 'Natural language search query'
          },
          concepts: {
            type: 'array',
            items: { type: 'string' },
            description: 'Multiple concepts for AND search (requires 2-5 concepts). Results must match ALL concepts.'
          },
          specFolder: {
            type: 'string',
            description: 'Limit search to a specific spec folder (e.g., "011-semantic-memory-upgrade")'
          },
          limit: {
            type: 'number',
            default: 10,
            description: 'Maximum number of results to return'
          }
        },
        required: ['query']
      }
    },
    {
      name: 'memory_load',
      description: 'Load a specific memory section by spec folder and optional anchor ID. Returns the full content of the memory file or section.',
      inputSchema: {
        type: 'object',
        properties: {
          specFolder: {
            type: 'string',
            description: 'Spec folder identifier (e.g., "011-semantic-memory-upgrade")'
          },
          anchorId: {
            type: 'string',
            description: 'Optional anchor identifier for loading a specific section'
          },
          memoryId: {
            type: 'number',
            description: 'Optional memory ID from search results for direct access'
          }
        },
        required: ['specFolder']
      }
    },
    {
      name: 'memory_match_triggers',
      description: 'Fast trigger phrase matching (<50ms) without embeddings. Use this for quick keyword-based memory lookup before falling back to semantic search. Ideal for proactive memory surfacing in environments without hooks.',
      inputSchema: {
        type: 'object',
        properties: {
          prompt: {
            type: 'string',
            description: 'User prompt or text to match against trigger phrases'
          },
          limit: {
            type: 'number',
            default: 3,
            description: 'Maximum number of matching memories to return (default: 3)'
          }
        },
        required: ['prompt']
      }
    }
  ]
}));

// ───────────────────────────────────────────────────────────────
// TOOL HANDLERS
// ───────────────────────────────────────────────────────────────

/**
 * Handle tool calls
 */
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    // Initialize database
    vectorIndex.initializeDb();

    switch (name) {
      case 'memory_search':
        return await handleMemorySearch(args);

      case 'memory_load':
        return await handleMemoryLoad(args);

      case 'memory_match_triggers':
        return await handleMemoryMatchTriggers(args);

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [
        {
          type: 'text',
          text: `Error: ${error.message}`
        }
      ],
      isError: true
    };
  }
});

// ───────────────────────────────────────────────────────────────
// SEARCH HANDLER
// ───────────────────────────────────────────────────────────────

/**
 * Handle memory_search tool
 */
async function handleMemorySearch(args) {
  const { query, concepts, specFolder, limit = 10 } = args;

  if (!query || typeof query !== 'string') {
    throw new Error('query is required and must be a string');
  }

  // Multi-concept search
  if (concepts && Array.isArray(concepts) && concepts.length >= 2) {
    if (concepts.length > 5) {
      throw new Error('Maximum 5 concepts allowed');
    }

    // Generate embeddings for all concepts
    const conceptEmbeddings = [];
    for (const concept of concepts) {
      const emb = await embeddings.generateEmbedding(concept);
      if (!emb) {
        throw new Error(`Failed to generate embedding for concept: ${concept}`);
      }
      conceptEmbeddings.push(emb);
    }

    const results = vectorIndex.multiConceptSearch(conceptEmbeddings, {
      minSimilarity: 0.5,
      limit,
      specFolder
    });

    return formatSearchResults(results, 'multi-concept');
  }

  // Single query search
  const queryEmbedding = await embeddings.generateEmbedding(query);
  if (!queryEmbedding) {
    throw new Error('Failed to generate embedding for query');
  }

  const results = vectorIndex.vectorSearch(queryEmbedding, {
    limit,
    specFolder
  });

  return formatSearchResults(results, 'vector');
}

/**
 * Format search results for MCP response
 */
function formatSearchResults(results, searchType) {
  if (!results || results.length === 0) {
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            searchType,
            count: 0,
            results: [],
            message: 'No matching memories found'
          }, null, 2)
        }
      ]
    };
  }

  const formatted = results.map(r => ({
    id: r.id,
    specFolder: r.spec_folder,
    filePath: r.file_path,
    title: r.title,
    similarity: r.similarity || r.averageSimilarity,
    triggerPhrases: r.trigger_phrases ? JSON.parse(r.trigger_phrases) : [],
    createdAt: r.created_at
  }));

  return {
    content: [
      {
        type: 'text',
        text: JSON.stringify({
          searchType,
          count: formatted.length,
          results: formatted
        }, null, 2)
      }
    ]
  };
}

// ───────────────────────────────────────────────────────────────
// TRIGGER MATCHING HANDLER
// ───────────────────────────────────────────────────────────────

/**
 * Handle memory_match_triggers tool - fast phrase matching without embeddings
 */
async function handleMemoryMatchTriggers(args) {
  const { prompt, limit = 3 } = args;

  if (!prompt || typeof prompt !== 'string') {
    throw new Error('prompt is required and must be a string');
  }

  const results = triggerMatcher.matchTriggerPhrases(prompt, limit);

  if (!results || results.length === 0) {
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            matchType: 'trigger-phrase',
            count: 0,
            results: [],
            message: 'No matching trigger phrases found'
          }, null, 2)
        }
      ]
    };
  }

  const formatted = results.map(r => ({
    memoryId: r.memoryId,
    specFolder: r.specFolder,
    filePath: r.filePath,
    title: r.title,
    matchedPhrases: r.matchedPhrases,
    importanceWeight: r.importanceWeight
  }));

  return {
    content: [
      {
        type: 'text',
        text: JSON.stringify({
          matchType: 'trigger-phrase',
          count: formatted.length,
          results: formatted
        }, null, 2)
      }
    ]
  };
}

// ───────────────────────────────────────────────────────────────
// LOAD HANDLER
// ───────────────────────────────────────────────────────────────

/**
 * Handle memory_load tool
 */
async function handleMemoryLoad(args) {
  const { specFolder, anchorId, memoryId } = args;

  if (!specFolder && !memoryId) {
    throw new Error('Either specFolder or memoryId is required');
  }

  let memory;

  // Load by memory ID
  if (memoryId) {
    memory = vectorIndex.getMemory(memoryId);
    if (!memory) {
      throw new Error(`Memory not found: ${memoryId}`);
    }
  } else {
    // Find by spec folder
    const db = vectorIndex.getDb();
    memory = db.prepare(`
      SELECT * FROM memory_index
      WHERE spec_folder = ?
      ORDER BY created_at DESC
      LIMIT 1
    `).get(specFolder);

    if (!memory) {
      throw new Error(`No memory found for spec folder: ${specFolder}`);
    }
  }

  // Read the file content
  const filePath = memory.file_path;

  if (!fs.existsSync(filePath)) {
    throw new Error(`Memory file not found: ${filePath}`);
  }

  let content = fs.readFileSync(filePath, 'utf-8');

  // Extract specific anchor section if requested
  if (anchorId) {
    content = extractAnchorSection(content, anchorId);
    if (!content) {
      throw new Error(`Anchor not found: ${anchorId}`);
    }
  }

  return {
    content: [
      {
        type: 'text',
        text: JSON.stringify({
          id: memory.id,
          specFolder: memory.spec_folder,
          filePath: memory.file_path,
          title: memory.title,
          anchor: anchorId || null,
          content: content
        }, null, 2)
      }
    ]
  };
}

/**
 * Extract a specific anchor section from content
 */
function extractAnchorSection(content, anchorId) {
  // Look for anchor markers in the content
  // Format: <!-- ANCHOR:anchor-id --> ... <!-- /ANCHOR:anchor-id -->
  const anchorPattern = new RegExp(
    `<!-- ANCHOR:${escapeRegex(anchorId)} -->([\\s\\S]*?)<!-- /ANCHOR:${escapeRegex(anchorId)} -->`,
    'i'
  );

  const match = content.match(anchorPattern);
  if (match) {
    return match[1].trim();
  }

  // Alternative format: # Section with anchor
  // Look for section headers with the anchor ID
  const headerPattern = new RegExp(
    `^(#{1,6})\\s+.*?\\{#${escapeRegex(anchorId)}\\}\\s*$([\\s\\S]*?)(?=^#{1,6}\\s|$)`,
    'im'
  );

  const headerMatch = content.match(headerPattern);
  if (headerMatch) {
    return headerMatch[2].trim();
  }

  return null;
}

/**
 * Escape special regex characters
 */
function escapeRegex(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// ───────────────────────────────────────────────────────────────
// GRACEFUL SHUTDOWN
// ───────────────────────────────────────────────────────────────

process.on('SIGTERM', () => {
  console.error('[memory-server] Received SIGTERM, shutting down...');
  vectorIndex.closeDb();
  process.exit(0);
});

process.on('SIGINT', () => {
  console.error('[memory-server] Received SIGINT, shutting down...');
  vectorIndex.closeDb();
  process.exit(0);
});

// ───────────────────────────────────────────────────────────────
// MAIN
// ───────────────────────────────────────────────────────────────

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('[memory-server] Memory MCP server running on stdio');
}

main().catch(err => {
  console.error('[memory-server] Fatal error:', err);
  process.exit(1);
});
