/**
 * Embeddings Module - Local vector embedding generation
 *
 * Uses @huggingface/transformers with all-MiniLM-L6-v2 for
 * 384-dimensional sentence embeddings. Runs entirely locally
 * with no external API calls.
 *
 * @module embeddings
 * @version 10.0.0
 */

'use strict';

// ───────────────────────────────────────────────────────────────
// CONFIGURATION
// ───────────────────────────────────────────────────────────────

const MODEL_NAME = 'Xenova/all-MiniLM-L6-v2';
const EMBEDDING_DIM = 384;
const MAX_TEXT_LENGTH = 2000;

// ───────────────────────────────────────────────────────────────
// SINGLETON MODEL INSTANCE
// ───────────────────────────────────────────────────────────────

let extractor = null;
let modelLoadTime = null;
let loadingPromise = null;  // Track loading state to prevent race conditions

/**
 * Get or create the embedding pipeline (singleton pattern)
 * First call downloads/loads model, subsequent calls return cached instance.
 * Prevents race conditions with multiple simultaneous model load requests.
 *
 * @returns {Promise<Object>} Feature extraction pipeline
 */
async function getModel() {
  // If already loaded, return immediately
  if (extractor) {
    return extractor;
  }

  // If currently loading, wait for that to complete
  if (loadingPromise) {
    return loadingPromise;
  }

  // Start loading and store the promise
  loadingPromise = (async () => {
    const startTime = Date.now();
    try {
      const { pipeline } = await import('@huggingface/transformers');
      extractor = await pipeline('feature-extraction', MODEL_NAME, {
        quantized: true
      });
      modelLoadTime = Date.now() - startTime;
      console.log(`[embeddings] Model loaded in ${modelLoadTime}ms`);
      return extractor;
    } catch (error) {
      loadingPromise = null;  // Reset on failure so retry is possible
      throw new Error(`Failed to load embedding model: ${error.message}`);
    }
  })();

  return loadingPromise;
}

// ───────────────────────────────────────────────────────────────
// EMBEDDING GENERATION
// ───────────────────────────────────────────────────────────────

/**
 * Generate a 384-dimensional embedding vector for text
 *
 * @param {string} text - Text to embed (truncated at 2000 chars)
 * @returns {Promise<Float32Array>} Normalized 384-dim embedding vector
 * @throws {Error} If embedding generation fails
 *
 * @example
 * const embedding = await generateEmbedding('Hello world');
 * console.log(embedding.length); // 384
 */
async function generateEmbedding(text) {
  // Handle empty/null text (T011)
  if (!text || typeof text !== 'string') {
    console.warn('[embeddings] Empty or invalid text provided, skipping embedding');
    return null;
  }

  const trimmedText = text.trim();
  if (trimmedText.length === 0) {
    console.warn('[embeddings] Empty text after trimming, skipping embedding');
    return null;
  }

  // Truncate at MAX_TEXT_LENGTH (T008)
  let inputText = trimmedText;
  if (inputText.length > MAX_TEXT_LENGTH) {
    inputText = inputText.substring(0, MAX_TEXT_LENGTH);
    console.warn(`[embeddings] Text truncated from ${trimmedText.length} to ${MAX_TEXT_LENGTH} chars`);
  }

  const start = Date.now();

  try {
    const model = await getModel();

    // Generate embedding with mean pooling and normalization
    const output = await model(inputText, {
      pooling: 'mean',
      normalize: true
    });

    // Convert to Float32Array (optimize by avoiding unnecessary copy)
    const embedding = output.data instanceof Float32Array
      ? output.data
      : new Float32Array(output.data);

    const inferenceTime = Date.now() - start;

    // Performance logging (T010)
    if (inferenceTime > 500) {
      console.warn(`[embeddings] Slow inference: ${inferenceTime}ms (target <500ms)`);
    }

    return embedding;

  } catch (error) {
    console.warn(`[embeddings] Generation failed: ${error.message}`);
    throw error;
  }
}

/**
 * Get embedding dimension (for validation)
 * @returns {number} Embedding dimension (384)
 */
function getEmbeddingDimension() {
  return EMBEDDING_DIM;
}

/**
 * Get model name
 * @returns {string} Model identifier
 */
function getModelName() {
  return MODEL_NAME;
}

/**
 * Check if model is loaded
 * @returns {boolean} True if model is cached
 */
function isModelLoaded() {
  return extractor !== null;
}

/**
 * Get model load time (if loaded)
 * @returns {number|null} Load time in ms or null
 */
function getModelLoadTime() {
  return modelLoadTime;
}

/**
 * Pre-warm the embedding model (call on server startup)
 * @returns {Promise<boolean>} true if model loaded successfully
 */
async function preWarmModel() {
  try {
    console.log('[embeddings] Pre-warming model...');
    await getModel();
    console.log('[embeddings] Model pre-warmed successfully');
    return true;
  } catch (error) {
    console.error(`[embeddings] Pre-warm failed: ${error.message}`);
    return false;
  }
}

// ───────────────────────────────────────────────────────────────
// MODULE EXPORTS
// ───────────────────────────────────────────────────────────────

module.exports = {
  generateEmbedding,
  getEmbeddingDimension,
  getModelName,
  isModelLoaded,
  getModelLoadTime,
  preWarmModel,

  // Constants for external use
  EMBEDDING_DIM,
  MAX_TEXT_LENGTH,
  MODEL_NAME
};
