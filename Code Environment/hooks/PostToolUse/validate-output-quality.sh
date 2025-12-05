#!/bin/bash

# ───────────────────────────────────────────────────────────────
# VALIDATE-OUTPUT-QUALITY.SH - Fluff/Ambiguity Detection Hook
# ───────────────────────────────────────────────────────────────
# PostToolUse hook that analyzes Task tool outputs for quality
# issues: fluff phrases, ambiguous language, and lazy lists.
#
# Version: 1.0.0
# Created: 2025-12-03
# Based on: Expert Protocol v2.4 research
#
# TRIGGERS: After Task tool completions
# OUTPUT: Advisory warnings via systemMessage (non-blocking)
# BLOCKING: No - informational only
#
# PERFORMANCE TARGET: <100ms (pattern matching only)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
# ───────────────────────────────────────────────────────────────

set -euo pipefail

# ───────────────────────────────────────────────────────────────
# CONFIGURATION
# ───────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/output-quality.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Source output helpers if available
if [ -f "$HOOKS_DIR/lib/output-helpers.sh" ]; then
  source "$HOOKS_DIR/lib/output-helpers.sh"
fi

# ───────────────────────────────────────────────────────────────
# LOGGING HELPER
# ───────────────────────────────────────────────────────────────

log_event() {
  local level="$1"
  local message="$2"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [$level] $message" >> "$LOG_FILE" 2>/dev/null || true
}

# ───────────────────────────────────────────────────────────────
# CROSS-PLATFORM TIMING
# ───────────────────────────────────────────────────────────────

_get_nano_time() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo $(($(date +%s) * 1000000000))
  else
    date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000))
  fi
}

START_TIME=$(_get_nano_time)

# ───────────────────────────────────────────────────────────────
# EARLY EXIT: READ AND VALIDATE INPUT
# ───────────────────────────────────────────────────────────────

# Read JSON input from stdin
INPUT=$(cat)

# Check for jq dependency (silent)
if ! command -v jq >/dev/null 2>&1; then
  log_event "ERROR" "jq not found, skipping output quality check"
  exit 0
fi

# Extract tool name (support multiple payload shapes)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // .toolName // .name // ""' 2>/dev/null)

# Only process Task tool outputs
if [[ "$TOOL_NAME" != "Task" ]]; then
  exit 0
fi

log_event "INFO" "Checking Task tool output quality"

# Extract the tool output/result for analysis
# Task tool typically returns result in tool_result or output field
TOOL_OUTPUT=$(echo "$INPUT" | jq -r '.tool_result // .output // .result // ""' 2>/dev/null)

if [ -z "$TOOL_OUTPUT" ] || [ "$TOOL_OUTPUT" = "null" ]; then
  log_event "DEBUG" "No output content to analyze"
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# PATTERN DEFINITIONS
# ───────────────────────────────────────────────────────────────

# Fluff patterns (filler phrases that add no value)
FLUFF_PATTERNS=(
  "It's worth noting"
  "It's important to"
  "As we all know"
  "In today's fast-paced"
  "Basically,"
  "At the end of the day"
  "It goes without saying"
)

# Ambiguity patterns (hedging language)
AMBIGUITY_PATTERNS=(
  "might work"
  "could possibly"
  "may or may not"
  "it depends"
  "perhaps"
  "maybe"
)

# ───────────────────────────────────────────────────────────────
# PATTERN DETECTION FUNCTIONS
# ───────────────────────────────────────────────────────────────

detect_fluff() {
  local content="$1"
  local found=()

  for pattern in "${FLUFF_PATTERNS[@]}"; do
    if echo "$content" | grep -qi "$pattern" 2>/dev/null; then
      found+=("$pattern")
    fi
  done

  # Handle empty array safely with set -u
  if [ ${#found[@]} -gt 0 ]; then
    echo "${found[@]}"
  fi
}

detect_ambiguity() {
  local content="$1"
  local count=0
  local found=()

  for pattern in "${AMBIGUITY_PATTERNS[@]}"; do
    if echo "$content" | grep -qi "$pattern" 2>/dev/null; then
      found+=("$pattern")
      ((count++)) || true
    fi
  done

  # Only warn if more than 2 ambiguous phrases
  # Handle empty array safely with set -u
  if [ "$count" -gt 2 ] && [ ${#found[@]} -gt 0 ]; then
    echo "${found[@]}"
  fi
}

detect_lazy_lists() {
  local content="$1"
  local short_items=0

  # Count bullet points with less than 10 words
  # Match lines starting with -, *, or bullet character
  while IFS= read -r line; do
    # Check if line is a bullet point
    if echo "$line" | grep -qE '^\s*[-*•]\s+' 2>/dev/null; then
      # Count words in the line
      word_count=$(echo "$line" | wc -w | tr -d ' ')
      if [ "$word_count" -lt 10 ]; then
        ((short_items++)) || true
      fi
    fi
  done <<< "$content"

  # Warn if more than 5 short bullet items
  if [ "$short_items" -gt 5 ]; then
    echo "$short_items"
  fi
}

# ───────────────────────────────────────────────────────────────
# RUN DETECTION
# ───────────────────────────────────────────────────────────────

WARNINGS=()

# Check for fluff patterns
FLUFF_FOUND=$(detect_fluff "$TOOL_OUTPUT")
if [ -n "$FLUFF_FOUND" ]; then
  WARNINGS+=("Fluff detected: $FLUFF_FOUND")
  log_event "WARN" "Fluff patterns found: $FLUFF_FOUND"
fi

# Check for excessive ambiguity
AMBIGUITY_FOUND=$(detect_ambiguity "$TOOL_OUTPUT")
if [ -n "$AMBIGUITY_FOUND" ]; then
  WARNINGS+=("Excessive hedging (>2): $AMBIGUITY_FOUND")
  log_event "WARN" "Ambiguity patterns found: $AMBIGUITY_FOUND"
fi

# Check for lazy lists
LAZY_LIST_COUNT=$(detect_lazy_lists "$TOOL_OUTPUT")
if [ -n "$LAZY_LIST_COUNT" ]; then
  WARNINGS+=("Lazy list detected: $LAZY_LIST_COUNT short bullet points (<10 words each)")
  log_event "WARN" "Lazy list detected: $LAZY_LIST_COUNT short items"
fi

# ───────────────────────────────────────────────────────────────
# OUTPUT WARNINGS
# ───────────────────────────────────────────────────────────────

if [ ${#WARNINGS[@]} -gt 0 ]; then
  # Prepare warning message
  WARNING_COUNT=${#WARNINGS[@]}

  # Log full details
  {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] OUTPUT QUALITY CHECK"
    echo "═══════════════════════════════════════════════════════════════"
    echo "Tool: $TOOL_NAME"
    echo "Warnings: $WARNING_COUNT"
    echo ""
    for warning in "${WARNINGS[@]}"; do
      echo "  - $warning"
    done
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
  } >> "$LOG_FILE"

  # Build systemMessage with condensed warning
  WARNING_SUMMARY=""
  for warning in "${WARNINGS[@]}"; do
    if [ -n "$WARNING_SUMMARY" ]; then
      WARNING_SUMMARY="$WARNING_SUMMARY; $warning"
    else
      WARNING_SUMMARY="$warning"
    fi
  done

  # Output systemMessage JSON for Claude Code visibility
  jq -n --arg msg "OUTPUT QUALITY: $WARNING_COUNT issue(s) - $WARNING_SUMMARY" '{systemMessage: $msg}'

  log_event "INFO" "Quality warnings emitted: $WARNING_COUNT"
else
  log_event "INFO" "No quality issues detected"
fi

# ───────────────────────────────────────────────────────────────
# PERFORMANCE LOGGING
# ───────────────────────────────────────────────────────────────

END_TIME=$(_get_nano_time)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] validate-output-quality.sh ${DURATION}ms" >> "$HOOKS_DIR/logs/performance.log" 2>/dev/null || true

# Always exit 0 (non-blocking, advisory only)
exit 0
