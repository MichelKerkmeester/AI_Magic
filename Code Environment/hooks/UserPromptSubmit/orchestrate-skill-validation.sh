#!/bin/bash

# ───────────────────────────────────────────────────────────────
# PARALLEL SKILL ORCHESTRATION HOOK
# ───────────────────────────────────────────────────────────────
# Pre-UserPromptSubmit hook that calculates task complexity and
# dispatches parallel agents for skill validation when justified
#
# PERFORMANCE TARGET: <50ms for complex tasks (vs ~120ms sequential)
# COMPLEXITY THRESHOLD: ≥35% triggers parallel dispatch
#
# EXECUTION ORDER: UserPromptSubmit hook (runs BEFORE user prompt processing)
#   Runs AFTER validate-skill-activation.sh (alphabetical order)
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
# ───────────────────────────────────────────────────────────────

# Source output helpers (completely silent on success)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
source "$SCRIPT_DIR/../lib/output-helpers.sh" || exit 0
source "$SCRIPT_DIR/../lib/shared-state.sh" 2>/dev/null || true

# Performance timing START
START_TIME=$(date +%s%N)

# Check dependencies (silent on success)
check_dependency "jq" "brew install jq (macOS) or apt install jq (Linux)" || exit 0

# Check for Python (optional - fallback to bash arithmetic if not available)
PYTHON_AVAILABLE=false
if command -v python3 >/dev/null 2>&1; then
  PYTHON_AVAILABLE=true
fi

# Helper function for floating point math (uses Python if available, else awk fallback)
calc_float() {
  local expr="$1"
  if [ "$PYTHON_AVAILABLE" = true ]; then
    python3 -c "print($expr)"
  else
    # awk fallback for systems without Python
    # Convert Python functions to awk-compatible operations:
    # - round(x, n) -> sprintf("%.nf", x)
    # - min(a, b) -> (a < b ? a : b)
    # For simplicity, we handle specific patterns used in this script
    local awk_expr

    # Handle round(x / y, 4) pattern -> x / y with 4 decimal precision
    if echo "$expr" | grep -qE 'round\([^,]+,\s*[0-9]+\)'; then
      # Extract the inner expression and precision
      awk_expr=$(echo "$expr" | sed -E 's/round\(([^,]+),\s*([0-9]+)\)/\1/g')
      awk "BEGIN { printf \"%.4f\", $awk_expr }"
    # Handle min(x, 1.0) pattern
    elif echo "$expr" | grep -qE 'min\([^,]+,\s*[0-9.]+\)'; then
      awk_expr=$(echo "$expr" | sed -E 's/min\(([^,]+),\s*([0-9.]+)\)/(\1 < \2 ? \1 : \2)/g')
      awk "BEGIN { printf \"%.4f\", $awk_expr }"
    else
      # Simple arithmetic
      awk "BEGIN { printf \"%.2f\", $expr }" 2>/dev/null || echo "0"
    fi
  fi
}

# Read JSON input from stdin
INPUT=$(cat)

# Extract the prompt from JSON (silent on error)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# If no prompt found, allow it
if [ -z "$PROMPT" ]; then
  exit 0
fi

# Configuration (needed early for override detection)
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../.." && pwd))

# ───────────────────────────────────────────────────────────────
# OVERRIDE DETECTION
# ───────────────────────────────────────────────────────────────
# Allow users to bypass dispatch requirement with explicit phrases
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# Check for override phrases
if echo "$PROMPT_LOWER" | grep -qE "(proceed anyway|skip dispatch|handle directly|override dispatch|do it sequentially)"; then
  # Clear pending dispatch state
  write_hook_state "pending_dispatch" "" 2>/dev/null || true

  # Log override
  {
    echo "─────────────────────────────────────────────────────────────"
    echo "DISPATCH OVERRIDE DETECTED - $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "User explicitly requested to proceed without parallel dispatch"
    echo "─────────────────────────────────────────────────────────────"
  } >> "$PROJECT_ROOT/.claude/hooks/logs/orchestrator.log" 2>/dev/null || true

  # Allow override
  exit 0
fi

# Additional configuration paths
SKILL_RULES="$PROJECT_ROOT/.claude/configs/skill-rules.json"
SKILL_RECOMMENDATIONS_LOG="$PROJECT_ROOT/.claude/hooks/logs/skill-recommendations.log"
ORCHESTRATOR_LOG="$PROJECT_ROOT/.claude/hooks/logs/orchestrator.log"

# Ensure log directory exists
mkdir -p "$(dirname "$ORCHESTRATOR_LOG")" 2>/dev/null

# ───────────────────────────────────────────────────────────────
# 1. COMPLEXITY SCORING (5-DIMENSION ALGORITHM)
# ───────────────────────────────────────────────────────────────
# Based on parallel agents skill complexity scoring algorithm
#
# Dimensions (weights):
# - Domain count (35%): Number of functional domains (code, docs, git, test, devops)
# - File count (25%): Estimated files modified
# - LOC estimate (15%): Estimated lines of code
# - Parallel opportunity (20%): Can tasks run in parallel?
# - Task type (5%): Implementation complexity
#
# Thresholds:
# - <25%: Direct execution (sequential)
# - 25-34%: Collaborative (ask user)
# - ≥35%: Auto-dispatch parallel agents

calculate_complexity_score() {
  local prompt="$1"
  local prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

  # Dimension 1: Domain count (0-6 domains)
  # Domains: code, analysis, docs, git, testing, devops
  local domain_count=0

  # Code domain indicators (REFINED - removed generic verbs and standalone 'api' that over-matches docs)
  if echo "$prompt_lower" | grep -qE "(implement|code|refactor|function|class|component|backend|frontend|fix|bug|debug|error|issue|problem|resolve|patch|hotfix|optimize|improve|enhance|script|module|service|handler|controller|model|util|helper|endpoint|route)"; then
    ((domain_count++))
  fi

  # Analysis domain indicators (REFINED - removed verbs that overlap with other domains)
  if echo "$prompt_lower" | grep -qE "(analyze|investigate|explore|examine|audit|inspect|trace|profile|benchmark|diagnose|troubleshoot|discover|locate|scan)"; then
    ((domain_count++))
  fi

  # Docs domain indicators (REFINED - removed changelog duplicate, kept in git domain)
  if echo "$prompt_lower" | grep -qE "(document|readme|guide|tutorial|api.*doc|comment|explain|release.*notes|specification|spec.*doc|jsdoc|typedoc|markdown|wiki)"; then
    ((domain_count++))
  fi

  # Git domain indicators (EXPANDED)
  if echo "$prompt_lower" | grep -qE "(git|commit|branch|merge|pull.*request|migration|version|pr\b|tag|release|changelog|rebase|cherry.*pick)"; then
    ((domain_count++))
  fi

  # Testing domain indicators (EXPANDED)
  if echo "$prompt_lower" | grep -qE "(test|unittest|integration.*test|e2e|coverage|spec\b|assert|mock|stub|fixture|snapshot|playwright|jest|vitest|bats|pytest)"; then
    ((domain_count++))
  fi

  # DevOps domain indicators (EXPANDED)
  if echo "$prompt_lower" | grep -qE "(deploy|ci|cd|docker|build|pipeline|infrastructure|kubernetes|k8s|helm|terraform|ansible|aws|gcp|azure|nginx|ssl|certificate|monitoring|logging|metrics)"; then
    ((domain_count++))
  fi

  # Calculate domain score (35% weight, normalized to 0-1, now 6 domains)
  local domain_score=$(calc_float "round(${domain_count} / 6.0, 4)")
  local domain_weighted=$(calc_float "round(${domain_score} * 35, 2)")

  # Dimension 2: File count estimate (0-20 files)
  # Heuristic based on keywords
  local file_count=1

  # Multiple file indicators
  if echo "$prompt_lower" | grep -qE "(all|every|multiple|across|throughout)"; then
    file_count=$((file_count + 5))
  fi

  if echo "$prompt_lower" | grep -qE "(refactor|update|modify|change)"; then
    file_count=$((file_count + 3))
  fi

  if echo "$prompt_lower" | grep -qE "(system|architecture|structure)"; then
    file_count=$((file_count + 5))
  fi

  # Cap at 20
  if [ $file_count -gt 20 ]; then
    file_count=20
  fi

  # Calculate file score (25% weight, normalized to 0-1)
  local file_score=$(calc_float "round(${file_count} / 20.0, 4)")
  local file_weighted=$(calc_float "round(${file_score} * 25, 2)")

  # Dimension 3: LOC estimate (0-1000 LOC)
  # Rough heuristic based on task type
  local loc_estimate=50

  if echo "$prompt_lower" | grep -qE "(implement|create|build)"; then
    loc_estimate=200
  fi

  if echo "$prompt_lower" | grep -qE "(refactor|redesign)"; then
    loc_estimate=300
  fi

  if echo "$prompt_lower" | grep -qE "(system|architecture)"; then
    loc_estimate=500
  fi

  # Calculate LOC score (15% weight, normalized to 0-1)
  local loc_score=$(calc_float "round(min(${loc_estimate} / 1000.0, 1.0), 4)")
  local loc_weighted=$(calc_float "round(${loc_score} * 15, 2)")

  # Dimension 4: Parallel opportunity (0-1)
  # Can tasks run in parallel? (high if multiple independent domains)
  # BUT sequential dependency keywords override this to 0
  local parallel_opportunity=0.0
  local has_sequential_deps=false

  # Check for sequential dependency patterns (IMPROVED - context-aware)
  # Only match sequential indicators with action context, not just "then" anywhere
  # This prevents false positives like "something other than" or "larger than"
  if echo "$prompt_lower" | grep -qE "(^|[[:space:]])(first|start by|begin with)[[:space:]].*[[:space:]]then[[:space:]]"; then
    has_sequential_deps=true
    parallel_opportunity=0.0
  elif echo "$prompt_lower" | grep -qE "[[:space:]]after[[:space:]].*(complete|finish|done|succeed|pass)"; then
    has_sequential_deps=true
    parallel_opportunity=0.0
  elif echo "$prompt_lower" | grep -qE "[[:space:]]once[[:space:]].*(done|complete|finish|succeed)"; then
    has_sequential_deps=true
    parallel_opportunity=0.0
  elif echo "$prompt_lower" | grep -qE "[[:space:]]when[[:space:]].*(complete|finish|done|pass)"; then
    has_sequential_deps=true
    parallel_opportunity=0.0
  elif echo "$prompt_lower" | grep -qE "[[:space:]]followed[[:space:]]by[[:space:]]"; then
    has_sequential_deps=true
    parallel_opportunity=0.0
  elif echo "$prompt_lower" | grep -qE ",[[:space:]]*(and[[:space:]]+)?then[[:space:]]"; then
    has_sequential_deps=true
    parallel_opportunity=0.0
  elif [ $domain_count -ge 3 ]; then
    parallel_opportunity=1.0
  elif [ $domain_count -eq 2 ]; then
    parallel_opportunity=0.6
  fi

  local parallel_weighted=$(calc_float "round(${parallel_opportunity} * 20, 2)")

  # Dimension 5: Task type complexity (0-1)
  # Implementation complexity score
  local task_complexity=0.5

  if echo "$prompt_lower" | grep -qE "(fix|bugfix|patch)"; then
    task_complexity=0.3
  elif echo "$prompt_lower" | grep -qE "(refactor|redesign|migrate)"; then
    task_complexity=1.0
  elif echo "$prompt_lower" | grep -qE "(implement|create|build)"; then
    task_complexity=0.8
  fi

  local task_weighted=$(calc_float "round(${task_complexity} * 5, 2)")

  # Total complexity score (0-100%)
  local total_score=$(calc_float "round(${domain_weighted} + ${file_weighted} + ${loc_weighted} + ${parallel_weighted} + ${task_weighted}, 2)")

  # Log complexity breakdown to orchestrator log
  {
    echo "─────────────────────────────────────────────────────────────"
    echo "COMPLEXITY ANALYSIS - $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "─────────────────────────────────────────────────────────────"
    echo "Domain count: ${domain_count}/6 → ${domain_weighted}%"
    echo "File count: ${file_count}/20 → ${file_weighted}%"
    echo "LOC estimate: ${loc_estimate}/1000 → ${loc_weighted}%"
    echo "Parallel opportunity: ${parallel_opportunity} → ${parallel_weighted}%"
    echo "Task complexity: ${task_complexity} → ${task_weighted}%"
    echo "─────────────────────────────────────────────────────────────"
    echo "TOTAL COMPLEXITY: ${total_score}%"
    echo "─────────────────────────────────────────────────────────────"
  } >> "$ORCHESTRATOR_LOG"

  # Return score and domain count
  echo "${total_score}|${domain_count}"
}

# ───────────────────────────────────────────────────────────────
# 2. PARALLEL DISPATCH DECISION
# ───────────────────────────────────────────────────────────────

make_dispatch_decision() {
  local complexity_score="$1"
  local domain_count="$2"

  # Log decision
  {
    echo "DECISION THRESHOLD CHECK:"
    echo "  Complexity: ${complexity_score}% (threshold: ≥35%)"
    echo "  Domains: ${domain_count} (threshold: ≥2)"
  } >> "$ORCHESTRATOR_LOG"

  # Check thresholds (use Python if available, else awk/bash)
  local score_check
  if [ "$PYTHON_AVAILABLE" = true ]; then
    score_check=$(python3 -c "print('true' if ${complexity_score} >= 35 else 'false')")
  else
    # Use awk for floating point comparison
    score_check=$(awk "BEGIN { print (${complexity_score} >= 35) ? \"true\" : \"false\" }")
  fi

  if [[ "$score_check" == "true" ]] && [ "$domain_count" -ge 2 ]; then
    echo "DISPATCH"
  else
    echo "SEQUENTIAL"
  fi
}

# ───────────────────────────────────────────────────────────────
# 2.5. COLLABORATIVE ZONE HANDLING (25-34%)
# ───────────────────────────────────────────────────────────────
# For tasks in the 25-34% complexity range with ≥2 domains, log the
# collaborative decision point. In future, this will integrate with
# AskUserQuestion tool for interactive prompts.

show_collaborative_prompt() {
  local complexity_score="$1"
  local domain_count="$2"
  local prompt="$3"

  # Estimate times (rough heuristics based on complexity score)
  # Formula: sequential time ≈ (complexity_score / 100) * 30 minutes
  # Parallel time ≈ 60% of sequential time
  local seq_time=$(calc_float "int(${complexity_score} * 0.3)")
  local par_time=$(calc_float "int(${seq_time} * 0.6)")

  # Log to orchestrator log
  {
    echo "───────────────────────────────────────────────────────────────"
    echo "COLLABORATIVE ZONE DETECTED"
    echo "───────────────────────────────────────────────────────────────"
    echo "Complexity: ${complexity_score}% (threshold: 25-34%)"
    echo "Domains: ${domain_count}"
    echo "Estimated times: Sequential ~${seq_time}min, Parallel ~${par_time}min"
    echo "───────────────────────────────────────────────────────────────"
  } >> "$ORCHESTRATOR_LOG"

  # Output collaborative zone prompt to stderr (visible to Claude)
  {
    echo ""
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│ 🤝 COLLABORATIVE DECISION ZONE                             │"
    echo "├─────────────────────────────────────────────────────────────┤"
    echo "│ Task complexity: ${complexity_score}% (moderate - 25-34%)       │"
    echo "│ Domains detected: ${domain_count}                              │"
    echo "│                                                             │"
    echo "│ This task could benefit from either approach:              │"
    echo "│ A) Sequential execution (~${seq_time} min) - Step-by-step   │"
    echo "│ B) Parallel sub-agents (~${par_time} min) - Concurrent       │"
    echo "│                                                             │"
    echo "│ Consider asking user which approach they prefer.           │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""
  } >&2

  return 0
}

# ───────────────────────────────────────────────────────────────
# 3. SKILL SELECTION BY DOMAIN
# ───────────────────────────────────────────────────────────────
# Maps detected domains to actual skills that exist in .claude/skills/

get_skills_for_domain() {
  local domain="$1"
  case "$domain" in
    "code")
      echo "workflows-code,mcp-semantic-search"
      ;;
    "analysis"|"explore")
      echo "mcp-semantic-search,workflows-code"
      ;;
    "docs"|"documentation")
      echo "create-documentation,workflows-conversation"
      ;;
    "git")
      echo "workflows-git,workflows-save-context"
      ;;
    "testing"|"test")
      echo "workflows-code,mcp-semantic-search"
      ;;
    "devops")
      echo "mcp-code-mode,cli-gemini"
      ;;
    *)
      echo "workflows-code"
      ;;
  esac
}

# ───────────────────────────────────────────────────────────────
# 4. PARALLEL AGENT DISPATCH
# ───────────────────────────────────────────────────────────────
# Detects domains from prompt and outputs structured dispatch instructions
# that Claude can act upon using the Task tool.

dispatch_parallel_agents() {
  local prompt="$1"
  local prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')
  local detected_domains=""

  # Detect which domains are present (SYNCED with calculate_complexity_score)
  # Code domain (REFINED - removed generic verbs and standalone 'api' that over-matches docs)
  if echo "$prompt_lower" | grep -qE "(implement|code|refactor|function|class|component|backend|frontend|fix|bug|debug|error|issue|problem|resolve|patch|hotfix|optimize|improve|enhance|script|module|service|handler|controller|model|util|helper|endpoint|route)"; then
    detected_domains="${detected_domains}code,"
  fi
  # Analysis domain (REFINED - removed verbs that overlap with other domains)
  if echo "$prompt_lower" | grep -qE "(analyze|investigate|explore|examine|audit|inspect|trace|profile|benchmark|diagnose|troubleshoot|discover|locate|scan)"; then
    detected_domains="${detected_domains}analysis,"
  fi
  # Docs domain (REFINED - removed changelog duplicate, kept in git domain)
  if echo "$prompt_lower" | grep -qE "(document|readme|guide|tutorial|api.*doc|comment|explain|release.*notes|specification|spec.*doc|jsdoc|typedoc|markdown|wiki)"; then
    detected_domains="${detected_domains}docs,"
  fi
  # Git domain (keeps changelog as primary owner)
  if echo "$prompt_lower" | grep -qE "(git|commit|branch|merge|pull.*request|migration|version|pr\b|tag|release|changelog|rebase|cherry.*pick)"; then
    detected_domains="${detected_domains}git,"
  fi
  # Testing domain (EXPANDED)
  if echo "$prompt_lower" | grep -qE "(test|unittest|integration.*test|e2e|coverage|spec\b|assert|mock|stub|fixture|snapshot|playwright|jest|vitest|bats|pytest)"; then
    detected_domains="${detected_domains}testing,"
  fi
  # DevOps domain (EXPANDED)
  if echo "$prompt_lower" | grep -qE "(deploy|ci|cd|docker|build|pipeline|infrastructure|kubernetes|k8s|helm|terraform|ansible|aws|gcp|azure|nginx|ssl|certificate|monitoring|logging|metrics)"; then
    detected_domains="${detected_domains}devops,"
  fi

  # Remove trailing comma
  detected_domains="${detected_domains%,}"

  # If no domains detected, default to code
  if [[ -z "$detected_domains" ]]; then
    detected_domains="code"
  fi

  # Log dispatch details
  {
    echo "─────────────────────────────────────────────────────────────"
    echo "PARALLEL DISPATCH - $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "─────────────────────────────────────────────────────────────"
    echo "Detected domains: $detected_domains"
  } >> "$ORCHESTRATOR_LOG"

  # Build agent specifications for each domain
  local agent_count=0
  local agent_list=""

  IFS=',' read -ra DOMAINS <<< "$detected_domains"
  for domain in "${DOMAINS[@]}"; do
    if [[ -n "$domain" ]]; then
      local skills=$(get_skills_for_domain "$domain")
      agent_count=$((agent_count + 1))

      {
        echo "Agent ${agent_count}: ${domain}"
        echo "  Skills: ${skills}"
      } >> "$ORCHESTRATOR_LOG"

      agent_list="${agent_list}${domain}:${skills}|"
    fi
  done

  {
    echo ""
    echo "Total agents: ${agent_count}"
    echo "─────────────────────────────────────────────────────────────"
  } >> "$ORCHESTRATOR_LOG"

  # Return agent count and agent list for use in output
  echo "${agent_count}|${detected_domains}|${agent_list}"
}

# ───────────────────────────────────────────────────────────────
# 5. MAIN ORCHESTRATION LOGIC
# ───────────────────────────────────────────────────────────────

# Calculate complexity score
COMPLEXITY_RESULT=$(calculate_complexity_score "$PROMPT")
COMPLEXITY_SCORE=$(echo "$COMPLEXITY_RESULT" | cut -d'|' -f1)
DOMAIN_COUNT=$(echo "$COMPLEXITY_RESULT" | cut -d'|' -f2)

# Write complexity state for inter-hook communication
# Other hooks (like enforce-spec-folder.sh) can read this for template recommendations
COMPLEXITY_STATE=$(cat <<EOF
{"complexity_score":${COMPLEXITY_SCORE},"domain_count":${DOMAIN_COUNT},"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
EOF
)
write_hook_state "complexity" "$COMPLEXITY_STATE" 2>/dev/null || true

# Check for collaborative zone (25-34% with ≥2 domains)
if [ "$PYTHON_AVAILABLE" = true ]; then
  COLLABORATIVE_CHECK=$(python3 -c "print('true' if 25 <= ${COMPLEXITY_SCORE} < 35 and ${DOMAIN_COUNT} >= 2 else 'false')")
else
  # Use awk for the range check
  COLLABORATIVE_CHECK=$(awk "BEGIN { print (${COMPLEXITY_SCORE} >= 25 && ${COMPLEXITY_SCORE} < 35 && ${DOMAIN_COUNT} >= 2) ? \"true\" : \"false\" }")
fi

if [[ "$COLLABORATIVE_CHECK" == "true" ]]; then
  # In collaborative zone - log the decision point
  show_collaborative_prompt "$COMPLEXITY_SCORE" "$DOMAIN_COUNT" "$PROMPT"
fi

# Make dispatch decision
DECISION=$(make_dispatch_decision "$COMPLEXITY_SCORE" "$DOMAIN_COUNT")

{
  echo "DECISION: $DECISION"
  echo "─────────────────────────────────────────────────────────────"
  echo ""
} >> "$ORCHESTRATOR_LOG"

# Execute based on decision
if [[ "$DECISION" == "DISPATCH" ]]; then
  # Get dispatch information
  DISPATCH_RESULT=$(dispatch_parallel_agents "$PROMPT")
  AGENT_COUNT=$(echo "$DISPATCH_RESULT" | cut -d'|' -f1)
  DETECTED_DOMAINS=$(echo "$DISPATCH_RESULT" | cut -d'|' -f2)
  AGENT_LIST=$(echo "$DISPATCH_RESULT" | cut -d'|' -f3)

  # Calculate estimated times for visibility
  SEQ_TIME_EST=$(calc_float "int(${COMPLEXITY_SCORE} * 0.3)")
  PAR_TIME_EST=$(calc_float "int(${SEQ_TIME_EST} * 0.4)")
  SPEEDUP=$(calc_float "round(${SEQ_TIME_EST} / ${PAR_TIME_EST}, 1)" 2>/dev/null || echo "2.5")

  # ─────────────────────────────────────────────────────────────────
  # ENHANCED VISIBLE OUTPUT - DISPATCH REQUIRED ANNOUNCEMENT
  # ─────────────────────────────────────────────────────────────────
  {
    echo ""
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│ 🚀 PARALLEL AGENT DISPATCH REQUIRED                        │"
    echo "├─────────────────────────────────────────────────────────────┤"
    echo "│ Complexity Score: ${COMPLEXITY_SCORE}% (threshold: ≥35%)              │"
    echo "│ Domains Detected: ${DOMAIN_COUNT} (${DETECTED_DOMAINS})                │"
    echo "│ Recommended Agents: ${AGENT_COUNT}                                  │"
    echo "│                                                             │"
    echo "│ 📋 AGENT ASSIGNMENTS:                                      │"
  } >&2

  # Parse agent list and output specifications with details
  IFS='|' read -ra AGENTS <<< "$AGENT_LIST"
  agent_num=1
  for agent_spec in "${AGENTS[@]}"; do
    if [[ -n "$agent_spec" ]]; then
      domain=$(echo "$agent_spec" | cut -d':' -f1)
      skills=$(echo "$agent_spec" | cut -d':' -f2)
      {
        echo "│   ${agent_num}. ${domain}_agent                                       │"
        echo "│      Skills: ${skills}                    │"
      } >&2
      agent_num=$((agent_num + 1))
    fi
  done

  {
    echo "│                                                             │"
    echo "│ ⚡ Expected Performance:                                   │"
    echo "│   Sequential: ~${SEQ_TIME_EST} min                                    │"
    echo "│   Parallel:   ~${PAR_TIME_EST} min (${SPEEDUP}x faster)                │"
    echo "│                                                             │"
    echo "│ 🎯 REQUIRED ACTION:                                        │"
    echo "│   Use Task tool to dispatch sub-agents for each domain     │"
    echo "│   OR type 'proceed anyway' to override and handle directly │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""
  } >&2

  # Write pending dispatch state for PreToolUse hook enforcement
  DISPATCH_STATE=$(cat <<EOF
{"required":true,"complexity":${COMPLEXITY_SCORE},"domains":${DOMAIN_COUNT},"agents":${AGENT_COUNT},"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
EOF
)
  write_hook_state "pending_dispatch" "$DISPATCH_STATE" 2>/dev/null || true

  # Log dispatch requirement
  {
    echo "ENFORCEMENT: DISPATCH REQUIRED (exit 1)"
    echo "User must use Task tool or acknowledge override"
  } >> "$ORCHESTRATOR_LOG"

  # Performance timing END
  END_TIME=$(date +%s%N)
  DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))

  {
    echo "EXECUTION TIME: ${DURATION_MS}ms"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
  } >> "$ORCHESTRATOR_LOG"

  # ─────────────────────────────────────────────────────────────────
  # INFORMATIONAL: Display dispatch recommendation (non-blocking)
  # ─────────────────────────────────────────────────────────────────
  # Changed from exit 1 (blocking) to exit 0 (informational) on 2025-11-25
  # Agent tracking now handled by PreToolUse/announce-task-dispatch.sh
  # and PostToolUse/summarize-task-completion.sh for lifecycle visibility
  exit 0

else
  # Sequential path (no parallel dispatch needed)
  {
    echo "Using sequential validation (complexity: ${COMPLEXITY_SCORE}% below threshold)"
  } >> "$ORCHESTRATOR_LOG"

  # Clear any pending dispatch state
  write_hook_state "pending_dispatch" "" 2>/dev/null || true
fi

# Performance timing END
END_TIME=$(date +%s%N)
DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))

{
  echo "EXECUTION TIME: ${DURATION_MS}ms"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""
} >> "$ORCHESTRATOR_LOG"

# Allow for sequential/low-complexity tasks
exit 0
