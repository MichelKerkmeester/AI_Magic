#!/bin/bash

# ───────────────────────────────────────────────────────────────
# MANUAL SAVE-CONTEXT HELPER
# ───────────────────────────────────────────────────────────────
# Standalone script for saving conversation context WITHOUT hooks
#
# Version: 1.0.0
# Created: 2025-11-28
#
# USAGE:
#   bash save-context-manual.sh [spec-folder] [description]
#
# EXAMPLES:
#   bash save-context-manual.sh 001-skills-and-hooks "Bug fix session"
#   bash save-context-manual.sh 008-cli-devtools-routing
#   bash save-context-manual.sh  # Auto-detect most recent folder
#
# PURPOSE:
#   Provides easy manual invocation of save-context when hooks are
#   not available or when you want explicit control over saving.
#
# REQUIREMENTS:
#   - Node.js installed
#   - jq installed (for JSON creation)
#   - Run from project root
# ───────────────────────────────────────────────────────────────

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

# Parse arguments
SPEC_FOLDER="${1:-}"
DESCRIPTION="${2:-Manual save-context invocation}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Help message
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  cat << 'HELP'
MANUAL SAVE-CONTEXT HELPER

Save conversation context to spec folder without requiring hooks.

USAGE:
  bash save-context-manual.sh [spec-folder] [description]

ARGUMENTS:
  spec-folder   Optional. Top-level spec folder (e.g., "001-skills-and-hooks")
                If omitted, uses most recent folder
  description   Optional. Brief description of session
                Default: "Manual save-context invocation"

EXAMPLES:
  # Save to specific folder
  bash save-context-manual.sh 001-skills-and-hooks "Bug fix session"

  # Save to most recent folder
  bash save-context-manual.sh

  # Save with custom description
  bash save-context-manual.sh 008-cli-devtools-routing "Anchor implementation"

OUTPUT:
  Creates memory file in specs/###-folder/memory/ with V9 anchors

REQUIREMENTS:
  - Node.js (for script execution)
  - jq (for JSON creation)
  - Run from project root

HELP
  exit 0
fi

# Check dependencies
if ! command -v node &> /dev/null; then
  echo "❌ Error: Node.js not found"
  echo "Install from https://nodejs.org/"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "❌ Error: jq not found"
  echo "Install: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
fi

# Auto-detect spec folder if not provided
if [ -z "$SPEC_FOLDER" ]; then
  echo "🔍 Auto-detecting most recent spec folder..."
  SPEC_FOLDER=$(find "$PROJECT_ROOT/specs" -maxdepth 1 -type d -name "[0-9][0-9][0-9]-*" 2>/dev/null | \
    grep -viE '/(z_|.*archive.*|.*old.*|.*\.archived.*)$' | \
    sort -r | head -1 | xargs basename)

  if [ -z "$SPEC_FOLDER" ]; then
    echo "❌ Error: No spec folder found"
    echo "Create one: mkdir -p specs/###-feature-name/"
    exit 1
  fi

  echo "   ✓ Using: $SPEC_FOLDER"
fi

# Create minimal JSON data
echo "📝 Creating context data..."
TEMP_JSON=$(mktemp "/tmp/save-context-manual-XXXXXX.json")
trap 'rm -f "$TEMP_JSON"' EXIT

# Create JSON with jq for proper escaping
jq -n \
  --arg spec "$SPEC_FOLDER" \
  --arg desc "$DESCRIPTION" \
  --arg ts "$TIMESTAMP" \
  '{
    SPEC_FOLDER: $spec,
    recent_context: [{
      request: "Manual save-context invocation",
      completed: $desc,
      learning: "Context saved manually without hooks",
      duration: "N/A",
      date: $ts
    }],
    observations: [{
      type: "discovery",
      title: "Manual context save",
      narrative: $desc,
      timestamp: $ts,
      files: [],
      facts: ["Standalone execution", "No hooks required"]
    }],
    user_prompts: [{
      prompt: ("Manual save: " + $desc),
      timestamp: $ts
    }]
  }' > "$TEMP_JSON"

echo "   ✓ Created JSON data"

# Execute save-context script
echo "💾 Saving context to $SPEC_FOLDER/memory/..."
cd "$PROJECT_ROOT"

node "$SCRIPT_DIR/generate-context.js" "$TEMP_JSON" "$SPEC_FOLDER"
EXIT_CODE=$?

# Clean up
rm -f "$TEMP_JSON"

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo "✅ SUCCESS: Context saved without hooks"
  echo "Location: specs/$SPEC_FOLDER/memory/"
else
  echo ""
  echo "❌ FAILED: Exit code $EXIT_CODE"
  exit $EXIT_CODE
fi
