#!/bin/bash

# ───────────────────────────────────────────────────────────────
# DETECT-SCOPE-GROWTH.SH - Mid-Conversation Scope Detection
# ───────────────────────────────────────────────────────────────
# PostToolUse hook that monitors for scope expansion during
# implementation. Warns (advisory, not blocking) when scope
# grows significantly beyond initial estimate.
#
# Version: 2.0.0
# Created: 2025-11-25
# Updated: 2025-11-29
# Spec: specs/002-speckit/008-validation-enforcement/
#
# TRIGGERS: After Edit/Write tool completions in spec folders
# OUTPUT: Advisory warning when scope grows >50%
# BLOCKING: No - advisory only
#
# INTEGRATION: Uses file-scope-tracking.sh for state management
# ───────────────────────────────────────────────────────────────

set -euo pipefail

# Performance: Early exit if not relevant tool
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$HOOKS_DIR")"
PROJECT_ROOT="${PROJECT_ROOT%/.claude}"
LOG_FILE="$HOOKS_DIR/logs/detect-scope-growth.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

# Logging helper
log_event() {
  local level="$1"
  local message="$2"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [$level] $message" >> "$LOG_FILE" 2>/dev/null || true
}

# Read tool input from stdin
INPUT=$(cat)

# Extract tool name and file path (support multiple JSON payload shapes)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // .toolName // .name // ""' 2>/dev/null)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // .tool_input.path // .tool_input.notebook_path // .parameters.file_path // .parameters.notebook_path // ""' 2>/dev/null)

# Only process after Edit/Write operations
if [[ ! "$TOOL_NAME" =~ ^(Edit|Write|NotebookEdit)$ ]]; then
  log_event "DEBUG" "Skipping tool: $TOOL_NAME"
  exit 0
fi

# Convert absolute path to relative for consistent matching
REL_FILE_PATH="${FILE_PATH#$PROJECT_ROOT/}"

# Only care about .md files in specs folders
if [[ ! "$REL_FILE_PATH" =~ ^specs/[0-9]+-[^/]+/.*\.md$ ]]; then
  log_event "DEBUG" "Skipping non-spec file: $FILE_PATH (rel: $REL_FILE_PATH)"
  exit 0
fi

log_event "INFO" "Processing $TOOL_NAME on $FILE_PATH"

# Source required libraries
if [ -f "$HOOKS_DIR/lib/shared-state.sh" ]; then
  source "$HOOKS_DIR/lib/shared-state.sh"
else
  log_event "ERROR" "shared-state.sh not found"
  exit 0
fi

if [ -f "$HOOKS_DIR/lib/file-scope-tracking.sh" ]; then
  source "$HOOKS_DIR/lib/file-scope-tracking.sh"
else
  log_event "ERROR" "file-scope-tracking.sh not found"
  exit 0
fi

# Read scope definition (set by enforce-spec-folder.sh)
scope_def=$(read_hook_state "scope_definition" 7200 2>/dev/null) || scope_def=""

# If no scope definition exists, initialize it from the current file's spec folder
if [ -z "$scope_def" ]; then
  # Extract spec folder from file path (e.g., specs/009-feature)
  # Use REL_FILE_PATH for consistent matching (handles both absolute and relative paths)
  if [[ "$REL_FILE_PATH" =~ ^(specs/[0-9]+-[^/]+)/ ]]; then
    SPEC_FOLDER="${BASH_REMATCH[1]}"
    log_event "INFO" "Auto-initializing scope for $SPEC_FOLDER"
    initialize_scope_definition "$SPEC_FOLDER" "" 2>/dev/null || true
    scope_def=$(read_hook_state "scope_definition" 7200 2>/dev/null) || scope_def=""
  fi
fi

# If still no scope definition, exit (nothing to track)
if [ -z "$scope_def" ]; then
  log_event "DEBUG" "No scope definition found, exiting"
  exit 0
fi

# Extract spec folder from scope definition
spec_folder=$(echo "$scope_def" | jq -r '.spec_folder // ""' 2>/dev/null)

if [ -z "$spec_folder" ] || [ ! -d "$spec_folder" ]; then
  log_event "WARN" "Invalid spec folder: $spec_folder"
  exit 0
fi

# Read or initialize baseline file count
baseline_state=$(read_hook_state "scope_baseline" 7200 2>/dev/null) || baseline_state=""

if [ -z "$baseline_state" ]; then
  # First time tracking - establish baseline
  baseline_files=$(find "$spec_folder" -maxdepth 2 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

  # Infer documentation level from existing files
  # NEW LEVEL STRUCTURE (Progressive Enhancement):
  #   Level 1 (Baseline):     spec.md + plan.md + tasks.md
  #   Level 2 (Verification): Level 1 + checklist.md
  #   Level 3 (Full):         Level 2 + decision-record.md + optional research-spike.md
  doc_level=1

  # Check for Level 3: Has decision-record (Full documentation)
  if [ -f "$spec_folder/decision-record.md" ] || ls "$spec_folder"/decision-record-*.md 1>/dev/null 2>&1; then
    doc_level=3
  # Check for Level 2: Has checklist (Verification level)
  elif [ -f "$spec_folder/checklist.md" ]; then
    doc_level=2
  fi
  # Default: Level 1 (Baseline)

  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)

  # Use jq for safe JSON construction (prevents injection if spec_folder contains special chars)
  baseline_state=$(jq -n \
    --arg folder "$spec_folder" \
    --argjson count "$baseline_files" \
    --argjson level "$doc_level" \
    --arg ts "$timestamp" \
    '{spec_folder: $folder, files_count: $count, level: $level, timestamp: $ts}' 2>/dev/null)

  write_hook_state "scope_baseline" "$baseline_state" 2>/dev/null || true
  log_event "INFO" "Baseline established: $baseline_files files, level $doc_level"
  exit 0  # Don't warn on first detection
fi

# Extract baseline values
baseline_files=$(echo "$baseline_state" | jq -r '.files_count // 0' 2>/dev/null) || baseline_files=0
baseline_level=$(echo "$baseline_state" | jq -r '.level // 2' 2>/dev/null) || baseline_level=2

# Skip if invalid baseline
if [ "$baseline_files" -eq 0 ]; then
  log_event "WARN" "Invalid baseline (0 files)"
  exit 0
fi

# Count current files in spec folder
current_files=$(find "$spec_folder" -maxdepth 2 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

# Calculate growth percentage
if [ "$current_files" -gt "$baseline_files" ]; then
  growth_ratio=$((current_files * 100 / baseline_files))

  log_event "INFO" "Growth check: $baseline_files -> $current_files files ($growth_ratio%)"

  # Detect significant scope growth (>150% = 50% growth)
  # Also check we haven't already warned (avoid spam)
  if [ "$growth_ratio" -gt 150 ]; then
    # Check if we already warned about this growth
    if ! has_hook_state "growth_warning_shown" 600 2>/dev/null; then
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "⚠️  SCOPE GROWTH DETECTED (Advisory)"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "Spec folder: $spec_folder"
      echo "Initial files: $baseline_files"
      echo "Current files: $current_files"
      echo "Growth: +$((growth_ratio - 100))%"
      echo ""
      echo "Consider upgrading documentation level:"
      if [ "$baseline_level" -eq 1 ]; then
        echo "  • Upgrade to Level 2: Add checklist.md for verification"
      fi
      if [ "$baseline_level" -le 2 ]; then
        echo "  • Upgrade to Level 3: Add decision-record.md for architectural decisions"
        echo "  • Optional: Add research-spike.md for investigation work"
      fi
      echo ""
      echo "This is advisory only - continue if scope growth is expected."
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""

      # Mark that we've shown the warning (expires in 10 minutes)
      write_hook_state "growth_warning_shown" "{\"shown\":true,\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" 2>/dev/null || true

      log_event "WARN" "Growth warning displayed: +$((growth_ratio - 100))%"
    else
      log_event "DEBUG" "Growth detected but warning already shown recently"
    fi
  fi
fi

exit 0
