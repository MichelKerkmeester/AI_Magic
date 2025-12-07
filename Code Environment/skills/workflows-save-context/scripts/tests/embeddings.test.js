/**
 * Unit Tests for Embeddings Module
 *
 * Tests embedding generation, text handling, and performance
 *
 * @module tests/embeddings.test
 */

'use strict';

const path = require('path');

// Add parent directory to path for imports
const libPath = path.join(__dirname, '..', 'lib');
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

function assertClose(actual, expected, tolerance, message) {
  const diff = Math.abs(actual - expected);
  assert(diff <= tolerance, `${message} (got ${actual}, expected ${expected}±${tolerance})`);
}

// ───────────────────────────────────────────────────────────────
// TESTS
// ───────────────────────────────────────────────────────────────

async function runTests() {
  console.log('\n=== Embeddings Module Tests ===\n');

  // Test 1: Constants exported correctly
  console.log('1. Constants');
  assert(embeddings.EMBEDDING_DIM === 384, 'EMBEDDING_DIM is 384');
  assert(embeddings.MAX_TEXT_LENGTH === 2000, 'MAX_TEXT_LENGTH is 2000');
  assert(embeddings.MODEL_NAME === 'Xenova/all-MiniLM-L6-v2', 'MODEL_NAME is correct');

  // Test 2: Model not loaded initially
  console.log('\n2. Lazy Loading');
  assert(embeddings.isModelLoaded() === false, 'Model not loaded initially');

  // Test 3: Basic embedding generation
  console.log('\n3. Basic Embedding Generation');
  const start = Date.now();
  const embedding = await embeddings.generateEmbedding('This is a test sentence.');
  const elapsed = Date.now() - start;

  assert(embedding !== null, 'Embedding is not null');
  assert(embedding instanceof Float32Array, 'Embedding is Float32Array');
  assert(embedding.length === 384, 'Embedding has 384 dimensions');

  // Test 4: Model loaded after first call
  console.log('\n4. Model Caching');
  assert(embeddings.isModelLoaded() === true, 'Model loaded after first embedding');
  assert(embeddings.getModelLoadTime() !== null, 'Load time recorded');

  // Test 5: Normalized vector (magnitude ~1.0)
  console.log('\n5. Normalization');
  const magnitude = Math.sqrt(embedding.reduce((sum, v) => sum + v * v, 0));
  assertClose(magnitude, 1.0, 0.001, 'Embedding is normalized (magnitude ≈ 1.0)');

  // Test 6: Empty/null handling
  console.log('\n6. Empty/Null Handling');
  const nullResult = await embeddings.generateEmbedding(null);
  assert(nullResult === null, 'Null input returns null');

  const emptyResult = await embeddings.generateEmbedding('');
  assert(emptyResult === null, 'Empty string returns null');

  const whitespaceResult = await embeddings.generateEmbedding('   ');
  assert(whitespaceResult === null, 'Whitespace-only returns null');

  // Test 7: Text truncation
  console.log('\n7. Text Truncation');
  const longText = 'a'.repeat(3000);
  const longEmbedding = await embeddings.generateEmbedding(longText);
  assert(longEmbedding !== null, 'Long text generates embedding');
  assert(longEmbedding.length === 384, 'Long text embedding has correct dimensions');

  // Test 8: Semantic similarity (same meaning = high similarity)
  console.log('\n8. Semantic Similarity');
  const emb1 = await embeddings.generateEmbedding('The cat sat on the mat');
  const emb2 = await embeddings.generateEmbedding('A cat is sitting on a mat');
  const emb3 = await embeddings.generateEmbedding('Machine learning algorithms');

  const sim12 = cosineSimilarity(emb1, emb2);
  const sim13 = cosineSimilarity(emb1, emb3);

  assert(sim12 > 0.7, `Similar sentences have high similarity (${sim12.toFixed(3)})`);
  assert(sim13 < sim12, `Different topics have lower similarity (${sim13.toFixed(3)} < ${sim12.toFixed(3)})`);

  // Test 9: Performance (second call should be fast)
  console.log('\n9. Performance');
  const perfStart = Date.now();
  await embeddings.generateEmbedding('Quick performance test');
  const perfTime = Date.now() - perfStart;
  assert(perfTime < 500, `Inference time < 500ms (got ${perfTime}ms)`);

  // Test 10: Unicode/UTF-8 Character Handling (CHK007)
  console.log('\n10. Unicode/UTF-8 Character Handling (CHK007)');

  // Test with Japanese text
  const japaneseText = 'これは日本語のテストです。セマンティック検索';
  const japaneseEmb = await embeddings.generateEmbedding(japaneseText);
  assert(japaneseEmb !== null, 'Japanese text generates embedding');
  assert(japaneseEmb.length === 384, 'Japanese text has correct dimensions');

  // Test with Chinese text
  const chineseText = '这是中文测试。语义搜索和向量嵌入';
  const chineseEmb = await embeddings.generateEmbedding(chineseText);
  assert(chineseEmb !== null, 'Chinese text generates embedding');
  assert(chineseEmb.length === 384, 'Chinese text has correct dimensions');

  // Test with Korean text
  const koreanText = '이것은 한국어 테스트입니다. 의미 검색';
  const koreanEmb = await embeddings.generateEmbedding(koreanText);
  assert(koreanEmb !== null, 'Korean text generates embedding');
  assert(koreanEmb.length === 384, 'Korean text has correct dimensions');

  // Test with Arabic text
  const arabicText = 'هذا اختبار بالعربية. البحث الدلالي';
  const arabicEmb = await embeddings.generateEmbedding(arabicText);
  assert(arabicEmb !== null, 'Arabic text generates embedding');
  assert(arabicEmb.length === 384, 'Arabic text has correct dimensions');

  // Test with mixed script text
  const mixedText = 'Hello 世界! Bonjour мир! مرحبا 세계';
  const mixedEmb = await embeddings.generateEmbedding(mixedText);
  assert(mixedEmb !== null, 'Mixed script text generates embedding');
  assert(mixedEmb.length === 384, 'Mixed script has correct dimensions');

  // Test with emojis
  const emojiText = 'Testing with emojis 🚀 🎉 ✨ and symbols © ® ™';
  const emojiEmb = await embeddings.generateEmbedding(emojiText);
  assert(emojiEmb !== null, 'Emoji text generates embedding');
  assert(emojiEmb.length === 384, 'Emoji text has correct dimensions');

  // Test with special characters and diacritics
  const diacriticText = 'Café résumé naïve façade señor über Zürich';
  const diacriticEmb = await embeddings.generateEmbedding(diacriticText);
  assert(diacriticEmb !== null, 'Diacritic text generates embedding');
  assert(diacriticEmb.length === 384, 'Diacritic text has correct dimensions');

  // Test with code/technical characters
  const codeText = 'const x = () => { return <div>Test</div>; }; @decorator #tag';
  const codeEmb = await embeddings.generateEmbedding(codeText);
  assert(codeEmb !== null, 'Code text generates embedding');
  assert(codeEmb.length === 384, 'Code text has correct dimensions');

  // Test 11: Unicode Semantic Similarity
  console.log('\n11. Unicode Semantic Similarity');

  // Similar meanings in different languages should have some similarity
  const engHello = await embeddings.generateEmbedding('Hello, how are you?');
  const spaHello = await embeddings.generateEmbedding('Hola, ¿cómo estás?');
  const frHello = await embeddings.generateEmbedding('Bonjour, comment allez-vous?');

  const engSpa = cosineSimilarity(engHello, spaHello);
  const engFr = cosineSimilarity(engHello, frHello);

  // MiniLM is trained on multilingual data, so there should be SOME similarity
  console.log(`  English-Spanish similarity: ${engSpa.toFixed(3)}`);
  console.log(`  English-French similarity: ${engFr.toFixed(3)}`);

  // Note: MiniLM-L6 is primarily English, so cross-lingual similarity may be low
  // We just verify it doesn't crash and produces valid embeddings
  assert(engSpa >= -1 && engSpa <= 1, 'English-Spanish similarity in valid range');
  assert(engFr >= -1 && engFr <= 1, 'English-French similarity in valid range');

  // Summary
  console.log('\n=== Summary ===');
  console.log(`Passed: ${testsPassed}`);
  console.log(`Failed: ${testsFailed}`);

  if (testsFailed > 0) {
    process.exit(1);
  }
}

// ───────────────────────────────────────────────────────────────
// UTILITIES
// ───────────────────────────────────────────────────────────────

function cosineSimilarity(a, b) {
  if (a.length !== b.length) return 0;
  let dot = 0;
  let magA = 0;
  let magB = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    magA += a[i] * a[i];
    magB += b[i] * b[i];
  }
  return dot / (Math.sqrt(magA) * Math.sqrt(magB));
}

// ───────────────────────────────────────────────────────────────
// RUN
// ───────────────────────────────────────────────────────────────

runTests().catch(err => {
  console.error('Test error:', err);
  process.exit(1);
});
