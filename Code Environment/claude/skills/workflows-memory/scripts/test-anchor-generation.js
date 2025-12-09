#!/usr/bin/env node

/**
 * Test Anchor Generation Integration
 *
 * Purpose: Verify anchor IDs are correctly generated for observations and decisions
 * Tests: Observation anchors, decision anchors, uniqueness handling
 */

const {
  generateAnchorId,
  categorizeSection,
  validateAnchorUniqueness,
  extractSpecNumber
} = require('./lib/anchor-generator');

console.log('=== Anchor Generation Integration Test ===\n');

// Test 1: Observation anchor generation
console.log('Test 1: Generate anchor for OAuth implementation observation');
const obs1Title = 'Implemented OAuth2 authentication flow';
const obs1Content = 'Created OAuth provider integration with callback handling';
const category1 = categorizeSection(obs1Title, obs1Content);
const anchor1 = generateAnchorId(obs1Title, category1, '049');
console.log(`  Title: "${obs1Title}"`);
console.log(`  Category: ${category1}`);
console.log(`  Anchor ID: ${anchor1}`);
console.log(`  Expected: implementation-oauth2-authentication-flow-049`);
console.log(`  Match: ${anchor1 === 'implementation-oauth2-authentication-flow-049' ? '✓' : '✗'}\n`);

// Test 2: Decision anchor generation
console.log('Test 2: Generate anchor for JWT vs Sessions decision');
const dec1Title = 'Decision: JWT vs Sessions for auth';
const dec1Content = 'We need to choose between JWT tokens and server sessions';
const category2 = categorizeSection(dec1Title, dec1Content);
const anchor2 = generateAnchorId(dec1Title, category2, '049');
console.log(`  Title: "${dec1Title}"`);
console.log(`  Category: ${category2}`);
console.log(`  Anchor ID: ${anchor2}`);
console.log(`  Expected category: decision`);
console.log(`  Category match: ${category2 === 'decision' ? '✓' : '✗'}\n`);

// Test 3: Uniqueness handling
console.log('Test 3: Handle duplicate anchor IDs');
const usedAnchors = ['implementation-oauth-049'];
const duplicateAnchor = 'implementation-oauth-049';
const uniqueAnchor = validateAnchorUniqueness(duplicateAnchor, usedAnchors);
console.log(`  Original: ${duplicateAnchor}`);
console.log(`  After uniqueness check: ${uniqueAnchor}`);
console.log(`  Expected: implementation-oauth-049-2`);
console.log(`  Match: ${uniqueAnchor === 'implementation-oauth-049-2' ? '✓' : '✗'}\n`);

// Test 4: Spec number extraction
console.log('Test 4: Extract spec number from folder name');
const specFolder = '049-anchor-context-retrieval';
const specNum = extractSpecNumber(specFolder);
console.log(`  Folder: ${specFolder}`);
console.log(`  Spec number: ${specNum}`);
console.log(`  Expected: 049`);
console.log(`  Match: ${specNum === '049' ? '✓' : '✗'}\n`);

// Test 5: Multiple observations with uniqueness tracking
console.log('Test 5: Generate multiple observation anchors with tracking');
const observations = [
  { title: 'Implemented OAuth callback handler', content: 'Added route handler' },
  { title: 'Created OAuth provider config', content: 'Config file setup' },
  { title: 'Built OAuth token refresh', content: 'Token refresh logic' }
];

const usedIds = [];
const generatedAnchors = observations.map((obs, idx) => {
  const cat = categorizeSection(obs.title, obs.content);
  let anchorId = generateAnchorId(obs.title, cat, '049');
  anchorId = validateAnchorUniqueness(anchorId, usedIds);
  usedIds.push(anchorId);
  return { title: obs.title, anchor: anchorId };
});

generatedAnchors.forEach((item, idx) => {
  console.log(`  ${idx + 1}. ${item.title}`);
  console.log(`     Anchor: ${item.anchor}`);
});

const allUnique = generatedAnchors.length === new Set(generatedAnchors.map(a => a.anchor)).size;
console.log(`  All unique: ${allUnique ? '✓' : '✗'}\n`);

// Summary
console.log('=== Test Summary ===');
console.log('All tests completed. Check for ✓ marks above.');
console.log('Integration ready for Phase 1 testing.\n');
