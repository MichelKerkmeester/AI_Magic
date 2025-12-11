#!/bin/bash

# ───────────────────────────────────────────────────────────────
# SKILL KEYWORD GENERATOR (Haiku AI-Enhanced)
# ───────────────────────────────────────────────────────────────
# Generates improved keywords for skills using Claude Haiku API.
# Merges AI-generated keywords with existing ones (no overwrites).
#
# Prerequisites:
#   - ANTHROPIC_API_KEY environment variable set
#   - curl available
#   - jq available
#
# Usage:
#   ./generate-skill-keywords.sh [options] [skill-name]
#
# Options:
#   --dry-run      Show what would change without modifying files
#   --skill NAME   Process only the specified skill
#   --all          Process all skills (default)
#   --backup       Create backup before modification (default: true)
#   --no-backup    Skip backup creation
#   --verbose      Show detailed output
#   --help         Show this help
#
# Examples:
#   ./generate-skill-keywords.sh --dry-run
#   ./generate-skill-keywords.sh --skill workflows-code
#   ./generate-skill-keywords.sh --all --verbose
# ───────────────────────────────────────────────────────────────

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." 2>/dev/null && pwd)"
SKILL_RULES="$PROJECT_ROOT/.claude/configs/skill-rules.json"
BACKUP_DIR="$PROJECT_ROOT/.claude/configs/backups"

# Default options
DRY_RUN=false
SINGLE_SKILL=""
CREATE_BACKUP=true
VERBOSE=false

# Haiku API configuration
HAIKU_MODEL="${HAIKU_MODEL:-claude-3-haiku-20240307}"
HAIKU_TIMEOUT=10

# ───────────────────────────────────────────────────────────────
# HELPERS
# ───────────────────────────────────────────────────────────────

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

log_verbose() {
  if [ "$VERBOSE" = true ]; then
    echo -e "${BLUE}[DEBUG]${NC} $1"
  fi
}

show_help() {
  head -50 "$0" | grep -E "^#" | sed 's/^# *//'
  exit 0
}

# ───────────────────────────────────────────────────────────────
# ARGUMENT PARSING
# ───────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --skill)
      SINGLE_SKILL="$2"
      shift 2
      ;;
    --all)
      SINGLE_SKILL=""
      shift
      ;;
    --backup)
      CREATE_BACKUP=true
      shift
      ;;
    --no-backup)
      CREATE_BACKUP=false
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --help|-h)
      show_help
      ;;
    *)
      # Positional argument treated as skill name
      SINGLE_SKILL="$1"
      shift
      ;;
  esac
done

# ───────────────────────────────────────────────────────────────
# PREREQUISITES CHECK
# ───────────────────────────────────────────────────────────────

check_prerequisites() {
  local missing=()
  
  # Check for required tools
  if ! command -v curl &>/dev/null; then
    missing+=("curl")
  fi
  
  if ! command -v jq &>/dev/null; then
    missing+=("jq")
  fi
  
  if [ ${#missing[@]} -gt 0 ]; then
    log_error "Missing required tools: ${missing[*]}"
    exit 1
  fi
  
  # Check for API key
  if [ -z "$ANTHROPIC_API_KEY" ]; then
    log_error "ANTHROPIC_API_KEY environment variable not set"
    echo ""
    echo "Set it with: export ANTHROPIC_API_KEY='your-api-key'"
    exit 1
  fi
  
  # Check for skill-rules.json
  if [ ! -f "$SKILL_RULES" ]; then
    log_error "skill-rules.json not found at: $SKILL_RULES"
    exit 1
  fi
  
  log_success "Prerequisites check passed"
}

# ───────────────────────────────────────────────────────────────
# BACKUP CREATION
# ───────────────────────────────────────────────────────────────

create_backup() {
  if [ "$CREATE_BACKUP" = false ]; then
    log_verbose "Backup skipped (--no-backup)"
    return
  fi
  
  mkdir -p "$BACKUP_DIR"
  local timestamp=$(date '+%Y%m%d_%H%M%S')
  local backup_file="$BACKUP_DIR/skill-rules_${timestamp}.json"
  
  cp "$SKILL_RULES" "$backup_file"
  log_success "Backup created: $backup_file"
}

# ───────────────────────────────────────────────────────────────
# HAIKU API CALL
# ───────────────────────────────────────────────────────────────

call_haiku() {
  local prompt="$1"
  
  local response=$(curl -s -X POST "https://api.anthropic.com/v1/messages" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    --max-time "$HAIKU_TIMEOUT" \
    -d '{
      "model": "'"$HAIKU_MODEL"'",
      "max_tokens": 200,
      "messages": [{"role": "user", "content": "'"$(echo "$prompt" | sed 's/"/\\"/g' | tr '\n' ' ')"'"}]
    }' 2>/dev/null)
  
  if [ -z "$response" ]; then
    log_error "No response from Haiku API"
    return 1
  fi
  
  # Check for API error
  local error=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
  if [ -n "$error" ]; then
    log_error "Haiku API error: $error"
    return 1
  fi
  
  # Extract text content
  echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null
}

# ───────────────────────────────────────────────────────────────
# KEYWORD GENERATION
# ───────────────────────────────────────────────────────────────

generate_keywords_for_skill() {
  local skill_name="$1"
  local description="$2"
  local existing_keywords="$3"
  
  log_verbose "Generating keywords for: $skill_name"
  log_verbose "Description: $description"
  log_verbose "Existing keywords: $existing_keywords"
  
  local prompt="Generate 5-10 additional keyword triggers for a skill matching system.

Skill Name: $skill_name
Description: $description
Existing Keywords: $existing_keywords

Requirements:
- Keywords should be what users might type when they need this skill
- Include common variations, synonyms, and related terms
- Include typos if commonly made
- Each keyword should be 1-3 words
- Only return NEW keywords not in the existing list
- Return ONLY a JSON array of strings, no explanation

Example output format: [\"new keyword\", \"another keyword\", \"variant\"]"

  local response=$(call_haiku "$prompt")
  
  if [ -z "$response" ]; then
    return 1
  fi
  
  # Clean response - extract just the JSON array
  local cleaned=$(echo "$response" | grep -oE '\[.*\]' | head -1)
  
  if [ -z "$cleaned" ]; then
    log_warn "Could not parse keywords from response: $response"
    return 1
  fi
  
  # Validate JSON
  if ! echo "$cleaned" | jq empty 2>/dev/null; then
    log_warn "Invalid JSON in response: $cleaned"
    return 1
  fi
  
  echo "$cleaned"
}

merge_keywords() {
  local existing="$1"
  local new="$2"
  
  # Merge arrays, remove duplicates, lowercase all
  echo "$existing $new" | jq -s '.[0] + .[1] | map(ascii_downcase) | unique | sort' 2>/dev/null
}

# ───────────────────────────────────────────────────────────────
# MAIN PROCESSING
# ───────────────────────────────────────────────────────────────

process_skill() {
  local skill_name="$1"
  
  log_info "Processing skill: $skill_name"
  
  # Get current skill data
  local description=$(jq -r ".skills[\"$skill_name\"].description // empty" "$SKILL_RULES")
  local existing_keywords=$(jq -c ".skills[\"$skill_name\"].promptTriggers.keywords // []" "$SKILL_RULES")
  
  if [ -z "$description" ]; then
    log_warn "No description found for skill: $skill_name"
    return 1
  fi
  
  # Generate new keywords
  local new_keywords=$(generate_keywords_for_skill "$skill_name" "$description" "$existing_keywords")
  
  if [ -z "$new_keywords" ]; then
    log_warn "Failed to generate keywords for: $skill_name"
    return 1
  fi
  
  log_verbose "Generated keywords: $new_keywords"
  
  # Merge keywords
  local merged=$(merge_keywords "$existing_keywords" "$new_keywords")
  local existing_count=$(echo "$existing_keywords" | jq 'length')
  local merged_count=$(echo "$merged" | jq 'length')
  local added_count=$((merged_count - existing_count))
  
  if [ "$added_count" -le 0 ]; then
    log_info "No new keywords to add for: $skill_name"
    return 0
  fi
  
  log_success "Found $added_count new keywords for: $skill_name"
  
  if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "  Existing ($existing_count): $existing_keywords"
    echo "  New ($added_count): $new_keywords"
    echo "  Merged ($merged_count): $merged"
    echo ""
    return 0
  fi
  
  # Update the skill-rules.json
  local tmp_file=$(mktemp)
  jq ".skills[\"$skill_name\"].promptTriggers.keywords = $merged" "$SKILL_RULES" > "$tmp_file"
  
  if [ $? -eq 0 ] && [ -s "$tmp_file" ]; then
    mv "$tmp_file" "$SKILL_RULES"
    log_success "Updated keywords for: $skill_name (+$added_count keywords)"
  else
    rm -f "$tmp_file"
    log_error "Failed to update skill-rules.json"
    return 1
  fi
}

process_all_skills() {
  local skills=$(jq -r '.skills | keys[]' "$SKILL_RULES")
  local total=$(echo "$skills" | wc -l | tr -d ' ')
  local processed=0
  local updated=0
  local failed=0
  
  log_info "Processing $total skills..."
  echo ""
  
  while IFS= read -r skill_name; do
    if [ -n "$skill_name" ]; then
      if process_skill "$skill_name"; then
        ((updated++)) || true
      else
        ((failed++)) || true
      fi
      ((processed++)) || true
      
      # Rate limiting - Haiku has rate limits
      sleep 0.5
    fi
  done <<< "$skills"
  
  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo "  Summary"
  echo "═══════════════════════════════════════════════════════════════"
  echo "  Total skills: $total"
  echo "  Processed: $processed"
  echo "  Updated: $updated"
  echo "  Failed: $failed"
  if [ "$DRY_RUN" = true ]; then
    echo "  Mode: DRY RUN (no changes made)"
  fi
  echo "═══════════════════════════════════════════════════════════════"
}

# ───────────────────────────────────────────────────────────────
# MAIN
# ───────────────────────────────────────────────────────────────

main() {
  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo "  Skill Keyword Generator (Haiku AI-Enhanced)"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""
  
  check_prerequisites
  
  if [ "$DRY_RUN" = true ]; then
    log_warn "DRY RUN MODE - No changes will be made"
  fi
  
  if [ "$DRY_RUN" = false ]; then
    create_backup
  fi
  
  echo ""
  
  if [ -n "$SINGLE_SKILL" ]; then
    # Process single skill
    if ! jq -e ".skills[\"$SINGLE_SKILL\"]" "$SKILL_RULES" &>/dev/null; then
      log_error "Skill not found: $SINGLE_SKILL"
      echo ""
      echo "Available skills:"
      jq -r '.skills | keys[]' "$SKILL_RULES" | sed 's/^/  - /'
      exit 1
    fi
    process_skill "$SINGLE_SKILL"
  else
    # Process all skills
    process_all_skills
  fi
}

main "$@"
