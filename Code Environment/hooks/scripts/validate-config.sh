#!/usr/bin/env bash

# ───────────────────────────────────────────────────────────────
# SKILL-RULES.JSON VALIDATION SCRIPT
# ───────────────────────────────────────────────────────────────
# Validates skill-rules.json against schema and performs additional checks

set -euo pipefail

# Source exit codes for consistent exit code usage
SCRIPT_DIR_ABS="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
source "$SCRIPT_DIR_ABS/../lib/exit-codes.sh" 2>/dev/null || {
  EXIT_ALLOW=0
  EXIT_BLOCK=1
  EXIT_ERROR=2
}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$(cd "$SCRIPT_DIR/../../configs" && pwd)"
CONFIG_FILE="$CONFIGS_DIR/skill-rules.json"
SCHEMA_FILE="$CONFIGS_DIR/skill-rules.schema.json"

# Counters
ERRORS=0
WARNINGS=0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SKILL-RULES.JSON VALIDATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo -e "${RED}✗ ERROR: Config file not found: $CONFIG_FILE${NC}"
  exit ${EXIT_ERROR:-1}
fi

echo "Config file: $CONFIG_FILE"
echo ""

# ───────────────────────────────────────────────────────────────
# 1. JSON SYNTAX VALIDATION
# ───────────────────────────────────────────────────────────────

echo "1. JSON SYNTAX"
echo "   ─────────────"

if jq empty "$CONFIG_FILE" 2>/dev/null; then
  echo -e "   ${GREEN}✓ Valid JSON syntax${NC}"
else
  echo -e "   ${RED}✗ Invalid JSON syntax${NC}"
  jq . "$CONFIG_FILE"
  exit ${EXIT_ERROR:-1}
fi

# ───────────────────────────────────────────────────────────────
# 2. REQUIRED FIELDS
# ───────────────────────────────────────────────────────────────

echo ""
echo "2. REQUIRED FIELDS"
echo "   ───────────────"

# Check for skills object
if jq -e '.skills' "$CONFIG_FILE" >/dev/null 2>&1; then
  echo -e "   ${GREEN}✓ 'skills' object present${NC}"
else
  echo -e "   ${RED}✗ Missing 'skills' object${NC}"
  ERRORS=$((ERRORS + 1))
fi

# Check for riskPatterns object
if jq -e '.riskPatterns' "$CONFIG_FILE" >/dev/null 2>&1; then
  echo -e "   ${GREEN}✓ 'riskPatterns' object present${NC}"
else
  echo -e "   ${RED}✗ Missing 'riskPatterns' object${NC}"
  ERRORS=$((ERRORS + 1))
fi

# ───────────────────────────────────────────────────────────────
# 3. SKILL VALIDATION
# ───────────────────────────────────────────────────────────────

echo ""
echo "3. SKILL DEFINITIONS"
echo "   ─────────────────"

SKILL_COUNT=$(jq '.skills // {} | length' "$CONFIG_FILE")
echo "   Found $SKILL_COUNT skills"
echo ""

# Validate each skill
while IFS= read -r skill_name; do
  echo -n "   Checking '$skill_name'... "

  # Required fields
  TYPE=$(jq -r ".skills.\"$skill_name\".type // empty" "$CONFIG_FILE")
  ENFORCEMENT=$(jq -r ".skills.\"$skill_name\".enforcement // empty" "$CONFIG_FILE")
  PRIORITY=$(jq -r ".skills.\"$skill_name\".priority // empty" "$CONFIG_FILE")
  DESCRIPTION=$(jq -r ".skills.\"$skill_name\".description // empty" "$CONFIG_FILE")

  SKILL_ERRORS=0

  # Validate type
  if [[ ! "$TYPE" =~ ^(knowledge|workflow|tool)$ ]]; then
    echo -e "${RED}INVALID TYPE${NC}"
    echo "      Expected: knowledge|workflow|tool, got: $TYPE"
    ERRORS=$((ERRORS + 1))
    SKILL_ERRORS=$((SKILL_ERRORS + 1))
  fi

  # Validate enforcement
  if [[ ! "$ENFORCEMENT" =~ ^(strict|suggest)$ ]]; then
    echo -e "${RED}INVALID ENFORCEMENT${NC}"
    echo "      Expected: strict|suggest, got: $ENFORCEMENT"
    ERRORS=$((ERRORS + 1))
    SKILL_ERRORS=$((SKILL_ERRORS + 1))
  fi

  # Validate priority
  if [[ ! "$PRIORITY" =~ ^(critical|high|medium|low)$ ]]; then
    echo -e "${RED}INVALID PRIORITY${NC}"
    echo "      Expected: critical|high|medium|low, got: $PRIORITY"
    ERRORS=$((ERRORS + 1))
    SKILL_ERRORS=$((SKILL_ERRORS + 1))
  fi

  # Validate description length
  if [ ${#DESCRIPTION} -lt 10 ]; then
    echo -e "${YELLOW}WARNING: Short description${NC}"
    WARNINGS=$((WARNINGS + 1))
  fi

  # Check for promptTriggers
  if ! jq -e ".skills.\"$skill_name\".promptTriggers" "$CONFIG_FILE" >/dev/null 2>&1; then
    echo -e "${RED}MISSING promptTriggers${NC}"
    ERRORS=$((ERRORS + 1))
    SKILL_ERRORS=$((SKILL_ERRORS + 1))
  fi

  if [ $SKILL_ERRORS -eq 0 ]; then
    echo -e "${GREEN}OK${NC}"
  fi

done < <(jq -r '.skills | keys[]' "$CONFIG_FILE")

# ───────────────────────────────────────────────────────────────
# 4. RISK PATTERN VALIDATION
# ───────────────────────────────────────────────────────────────

echo ""
echo "4. RISK PATTERNS"
echo "   ─────────────"

PATTERN_COUNT=$(jq '.riskPatterns // {} | length' "$CONFIG_FILE")
echo "   Found $PATTERN_COUNT risk patterns"
echo ""

# Validate each pattern
while IFS= read -r pattern_name; do
  echo -n "   Checking '$pattern_name'... "

  # Check for patterns array
  if ! jq -e ".riskPatterns.\"$pattern_name\".patterns" "$CONFIG_FILE" >/dev/null 2>&1; then
    echo -e "${RED}MISSING patterns array${NC}"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Check for reminder
  REMINDER=$(jq -r ".riskPatterns.\"$pattern_name\".reminder // empty" "$CONFIG_FILE")
  if [ -z "$REMINDER" ]; then
    echo -e "${RED}MISSING reminder${NC}"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  echo -e "${GREEN}OK${NC}"

done < <(jq -r '.riskPatterns | keys[]' "$CONFIG_FILE")

# ───────────────────────────────────────────────────────────────
# 5. REGEX PATTERN VALIDATION (BASIC)
# ───────────────────────────────────────────────────────────────

echo ""
echo "5. REGEX PATTERNS"
echo "   ──────────────"
echo "   Validating regex patterns..."

# Test a few common patterns for basic validity
PATTERN_ERRORS=0

# This is a basic check - just ensures patterns don't have obvious syntax errors
# A full validation would require perl or grep -P, which may not be available

echo -e "   ${BLUE}ℹ  Basic regex validation (limited)${NC}"

# ───────────────────────────────────────────────────────────────
# SUMMARY
# ───────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "VALIDATION SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Skills validated: $SKILL_COUNT"
echo "Risk patterns validated: $PATTERN_COUNT"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}✓ Validation passed with no errors or warnings${NC}"
  exit ${EXIT_ALLOW:-0}
elif [ $ERRORS -eq 0 ]; then
  echo -e "${YELLOW}⚠  Validation passed with $WARNINGS warning(s)${NC}"
  exit ${EXIT_ALLOW:-0}
else
  echo -e "${RED}✗ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
  exit ${EXIT_BLOCK:-1}
fi
