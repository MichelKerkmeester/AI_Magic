#!/bin/bash

# ───────────────────────────────────────────────────────────────
# FIND RELATED SPEC - Spec Folder Search Tool
# ───────────────────────────────────────────────────────────────
# Standalone script to search for related spec folders by keywords.
# Used by AI agents before creating new specs to check for existing work.
#
# Usage:
#   find-related-spec.sh "keyword1 keyword2"
#
# Output:
#   List of matching specs with status and excerpt
#
# Exit Codes:
#   0 - Matches found
#   1 - No matches or error
# ───────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../.." && pwd))
SPECS_DIR="$PROJECT_ROOT/specs"

# Source exit codes for consistent exit code usage
source "$SCRIPT_DIR/../lib/exit-codes.sh" 2>/dev/null || {
  EXIT_ALLOW=0
  EXIT_BLOCK=1
  EXIT_ERROR=2
}

# ───────────────────────────────────────────────────────────────
# USAGE & VALIDATION
# ───────────────────────────────────────────────────────────────

if [ $# -eq 0 ]; then
  echo "Usage: $(basename "$0") <keywords>"
  echo ""
  echo "Examples:"
  echo "  $(basename "$0") \"markdown optimizer\""
  echo "  $(basename "$0") \"hero animation\""
  echo "  $(basename "$0") auth"
  echo ""
  echo "Searches spec folder names and titles for keyword matches."
  echo "Returns top 5 results ranked by relevance."
  exit ${EXIT_BLOCK:-1}
fi

if [ ! -d "$SPECS_DIR" ]; then
  echo "Error: Specs directory not found: $SPECS_DIR"
  exit ${EXIT_ERROR:-1}
fi

QUERY="$*"

# ───────────────────────────────────────────────────────────────
# HELPER FUNCTIONS
# ───────────────────────────────────────────────────────────────

get_spec_status() {
  local spec_folder="$1"
  local spec_file="$spec_folder/spec.md"

  if [ ! -f "$spec_file" ]; then
    echo "active"
    return
  fi

  # Extract from YAML frontmatter
  local status=$(awk '/^---$/,/^---$/ {if (/^status:/) {print $2; exit}}' "$spec_file" 2>/dev/null)

  # Default to "active" if missing
  echo "${status:-active}"
}

get_spec_excerpt() {
  local spec_folder="$1"
  local spec_file="$spec_folder/spec.md"

  if [ ! -f "$spec_file" ]; then
    echo "(No spec.md found)"
    return
  fi

  # Get first line after H1 title (usually the description)
  local excerpt=$(head -20 "$spec_file" | grep -A 2 '^# ' | tail -1 | sed 's/^[[:space:]]*//' | head -c 100)

  if [ -z "$excerpt" ]; then
    # Fallback: get first non-empty line after title
    excerpt=$(head -20 "$spec_file" | awk '/^# /,/^$/ {if (!/^#/ && !/^---/ && NF>0) {print; exit}}' | head -c 100)
  fi

  echo "${excerpt:-(No description)}"
}

# ───────────────────────────────────────────────────────────────
# SEARCH LOGIC
# ───────────────────────────────────────────────────────────────

# Convert query to lowercase for case-insensitive matching
QUERY_LOWER=$(echo "$QUERY" | tr '[:upper:]' '[:lower:]')

# Array to store results: "score:folder"
RESULTS=()

# Search folder names (highest score = 10)
for folder in "$SPECS_DIR"/[0-9]*-*/; do
  [ ! -d "$folder" ] && continue

  # Remove trailing slash
  folder="${folder%/}"

  name=$(basename "$folder")
  name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')

  # Skip pure numeric folders
  [[ "$name" =~ ^[0-9]+$ ]] && continue

  # Check if query matches folder name
  if echo "$name_lower" | grep -qiF "$QUERY_LOWER"; then
    RESULTS+=("10:$folder")
    continue  # Already matched, skip further checks for this folder
  fi

  # Check spec.md title if folder name didn't match
  spec_file="$folder/spec.md"
  if [ -f "$spec_file" ]; then
    # Get H1 title
    title=$(head -5 "$spec_file" | grep -E '^# ' | head -1 | sed 's/^# //' | tr '[:upper:]' '[:lower:]')

    if [ -n "$title" ] && echo "$title" | grep -qiF "$QUERY_LOWER"; then
      RESULTS+=("5:$folder")
      continue  # Matched title, skip content search
    fi
  fi

  # Only search content if we have <5 results so far
  if [ ${#RESULTS[@]} -lt 5 ] && [ -f "$spec_file" ]; then
    # Search first 50 lines of content
    if head -50 "$spec_file" | grep -qiF "$QUERY_LOWER"; then
      RESULTS+=("1:$folder")
    fi
  fi
done

# ───────────────────────────────────────────────────────────────
# RANK & OUTPUT
# ───────────────────────────────────────────────────────────────

if [ ${#RESULTS[@]} -eq 0 ]; then
  echo "No related specs found for: $QUERY"
  echo ""
  echo "Suggestions:"
  echo "  • Try different keywords (e.g., \"auth\" instead of \"authentication\")"
  echo "  • Check folder names: ls specs/ | grep -i \"keyword\""
  echo "  • This may be a new feature - create a new spec folder"
  exit ${EXIT_BLOCK:-1}
fi

# Sort by score (descending), limit to 5
SORTED=$(printf '%s\n' "${RESULTS[@]}" | sort -t: -k1 -rn | head -5)

# Display results
echo "Related specs found for: $QUERY"
echo "──────────────────────────────────────────────────────────────"
echo ""

while IFS=':' read -r score folder; do
  name=$(basename "$folder")
  status=$(get_spec_status "$folder")
  excerpt=$(get_spec_excerpt "$folder")

  # Format status with visual indicator
  status_display=""
  case "$status" in
    active) status_display="✓ ACTIVE" ;;
    draft) status_display="◐ DRAFT" ;;
    paused) status_display="⏸  PAUSED" ;;
    complete) status_display="✓ COMPLETE" ;;
    archived) status_display="📦 ARCHIVED" ;;
    *) status_display="$status" ;;
  esac

  echo "$name"
  echo "  Status: $status_display"
  echo "  Path: $folder"
  echo "  Description: $excerpt"
  echo ""
done <<< "$SORTED"

echo "──────────────────────────────────────────────────────────────"
RESULT_COUNT=$(echo "$SORTED" | wc -l | tr -d ' ')
echo "Found $RESULT_COUNT related spec(s)"
echo ""
echo "Guidelines: .claude/knowledge/conversation_documentation.md Section 7"

exit ${EXIT_ALLOW:-0}
