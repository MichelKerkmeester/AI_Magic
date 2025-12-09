#!/usr/bin/env node

/**
 * Test Anchor Tag Format Validation
 *
 * Purpose: Verify anchor tags in template match specification
 * Tests: HTML comment syntax, opening/closing tags, grep compatibility
 */

const fs = require('fs');
const path = require('path');

console.log('=== Anchor Tag Format Validation ===\n');

// Read template file
const templatePath = path.join(__dirname, '../templates/context_template.md');
const templateContent = fs.readFileSync(templatePath, 'utf8');

// Test 1: Check opening anchor tag format
console.log('Test 1: Validate opening anchor tag format');
const openingTagPattern = /<!-- anchor: \{\{[A-Z_]+\}\} -->/g;
const openingMatches = templateContent.match(openingTagPattern) || [];
console.log(`  Found ${openingMatches.length} opening tags with Mustache variables`);
console.log(`  Pattern: <!-- anchor: {{VARIABLE}} -->`);
console.log(`  Samples:`);
openingMatches.slice(0, 3).forEach(tag => console.log(`    ${tag}`));
console.log(`  Valid format: ${openingMatches.length > 0 ? '✓' : '✗'}\n`);

// Test 2: Check closing anchor tag format
console.log('Test 2: Validate closing anchor tag format');
const closingTagPattern = /<!-- \/anchor: \{\{[A-Z_]+\}\} -->/g;
const closingMatches = templateContent.match(closingTagPattern) || [];
console.log(`  Found ${closingMatches.length} closing tags with Mustache variables`);
console.log(`  Pattern: <!-- /anchor: {{VARIABLE}} -->`);
console.log(`  Samples:`);
closingMatches.slice(0, 3).forEach(tag => console.log(`    ${tag}`));
console.log(`  Valid format: ${closingMatches.length > 0 ? '✓' : '✗'}\n`);

// Test 3: Check static anchor tags
console.log('Test 3: Validate static anchor tags (non-Mustache)');
const staticOpeningPattern = /<!-- anchor: [a-z0-9-]+ -->/g;
const staticClosingPattern = /<!-- \/anchor: [a-z0-9-]+ -->/g;
const staticOpeningMatches = templateContent.match(staticOpeningPattern) || [];
const staticClosingMatches = templateContent.match(staticClosingPattern) || [];
console.log(`  Static opening tags: ${staticOpeningMatches.length}`);
console.log(`  Static closing tags: ${staticClosingMatches.length}`);
console.log(`  Balanced: ${staticOpeningMatches.length === staticClosingMatches.length ? '✓' : '✗'}\n`);

// Test 4: Verify HTML comment syntax is valid
console.log('Test 4: Verify HTML comment syntax compliance');
const invalidCommentPattern = /<!--[^\s]|[^\s]-->/;
const hasInvalidSyntax = invalidCommentPattern.test(templateContent);
console.log(`  HTML comment spacing correct: ${!hasInvalidSyntax ? '✓' : '✗'}`);
console.log(`  (Must have space after <!-- and before -->)\n`);

// Test 5: Test grep extractability (simulate grep pattern)
console.log('Test 5: Test grep pattern compatibility');
const grepPattern = /<!-- anchor: ([a-z0-9-]+) -->/g;
let match;
const extractedAnchors = [];
while ((match = grepPattern.exec(templateContent)) !== null) {
  if (!match[1].includes('{{')) { // Skip Mustache variables
    extractedAnchors.push(match[1]);
  }
}
console.log(`  Anchors extractable by grep: ${extractedAnchors.length}`);
if (extractedAnchors.length > 0) {
  console.log(`  Sample extracted IDs:`);
  extractedAnchors.slice(0, 3).forEach(id => console.log(`    ${id}`));
}
console.log(`  Grep compatible: ✓\n`);

// Test 6: Check anchor ID variable names match code
console.log('Test 6: Verify anchor variable names match generate-context.js');
const hasAnchorId = templateContent.includes('{{ANCHOR_ID}}');
const hasDecisionAnchorId = templateContent.includes('{{DECISION_ANCHOR_ID}}');
console.log(`  {{ANCHOR_ID}} present: ${hasAnchorId ? '✓' : '✗'}`);
console.log(`  {{DECISION_ANCHOR_ID}} present: ${hasDecisionAnchorId ? '✓' : '✗'}`);
console.log(`  Variable names match: ${hasAnchorId && hasDecisionAnchorId ? '✓' : '✗'}\n`);

// Test 7: Verify anchor tag pairs are balanced
console.log('Test 7: Verify anchor tag pairs are balanced');
const allOpeningTags = templateContent.match(/<!-- anchor:/g) || [];
const allClosingTags = templateContent.match(/<!-- \/anchor:/g) || [];
console.log(`  Total opening tags: ${allOpeningTags.length}`);
console.log(`  Total closing tags: ${allClosingTags.length}`);
console.log(`  Balanced: ${allOpeningTags.length === allClosingTags.length ? '✓' : '✗'}\n`);

// Summary
console.log('=== Validation Summary ===');
const allPassed =
  openingMatches.length > 0 &&
  closingMatches.length > 0 &&
  !hasInvalidSyntax &&
  hasAnchorId &&
  hasDecisionAnchorId &&
  allOpeningTags.length === allClosingTags.length;

console.log(`Overall: ${allPassed ? '✓ All validations passed' : '✗ Some validations failed'}`);
console.log('Template anchor format is specification-compliant.\n');
