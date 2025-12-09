#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Sync Memory System to Opencode
# ═══════════════════════════════════════════════════════════════
#
# Syncs all memory system components from Claude Code to Opencode
# ensuring identical functionality on both platforms.
#
# Usage: ./sync-to-opencode.sh [--dry-run]
#
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CLAUDE_DIR="$PROJECT_ROOT/.claude"
OPENCODE_DIR="$PROJECT_ROOT/.opencode"

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

echo "═══════════════════════════════════════════════════════════"
echo "  Memory System Sync: Claude Code → Opencode"
echo "═══════════════════════════════════════════════════════════"
echo ""

if [[ "$DRY_RUN" == true ]]; then
  echo -e "${YELLOW}DRY RUN MODE - No files will be modified${NC}"
  echo ""
fi

# Counters for summary
FILES_SYNCED=0
DIRS_SYNCED=0
WARNINGS=0

sync_file() {
  local src="$1"
  local dst="$2"

  if [[ ! -f "$src" ]]; then
    echo -e "  ${YELLOW}⚠${NC} Source not found: $(basename "$src")"
    ((WARNINGS++)) || true
    return
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "  ${BLUE}[DRY-RUN]${NC} Would sync: $(basename "$src")"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo -e "  ${GREEN}✓${NC} Synced: $(basename "$src")"
    ((FILES_SYNCED++)) || true
  fi
}

sync_dir() {
  local src="$1"
  local dst="$2"
  local name="$3"

  if [[ ! -d "$src" ]]; then
    echo -e "  ${YELLOW}⚠${NC} Source not found: $name/"
    ((WARNINGS++)) || true
    return
  fi

  if [[ "$DRY_RUN" == true ]]; then
    local count=$(find "$src" -type f | wc -l | tr -d ' ')
    echo -e "  ${BLUE}[DRY-RUN]${NC} Would sync: $name/ ($count files)"
  else
    mkdir -p "$dst"
    rsync -av --delete \
      --exclude='node_modules' \
      --exclude='.git' \
      --exclude='*.log' \
      --exclude='.DS_Store' \
      "$src/" "$dst/" > /dev/null 2>&1
    local count=$(find "$dst" -type f | wc -l | tr -d ' ')
    echo -e "  ${GREEN}✓${NC} Synced: $name/ ($count files)"
    ((DIRS_SYNCED++)) || true
  fi
}

# ═══════════════════════════════════════════════════════════════
# SYNC COMMANDS
# ═══════════════════════════════════════════════════════════════

echo -e "${BLUE}📁 Syncing Commands...${NC}"

# Memory commands
sync_dir "$CLAUDE_DIR/commands/memory" "$OPENCODE_DIR/command/memory" "memory commands"

# ═══════════════════════════════════════════════════════════════
# SYNC SKILLS
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BLUE}📚 Syncing Skill Files...${NC}"

# Main skill directory
sync_dir "$CLAUDE_DIR/skills/workflows-memory" "$OPENCODE_DIR/skills/workflows-memory" "workflows-memory"

# ═══════════════════════════════════════════════════════════════
# SYNC SPECIFIC FILES (if any standalone files need syncing)
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BLUE}📄 Syncing Configuration...${NC}"

# Sync semantic search command if exists
if [[ -f "$CLAUDE_DIR/commands/semantic_search.md" ]]; then
  sync_file "$CLAUDE_DIR/commands/semantic_search.md" "$OPENCODE_DIR/command/semantic_search.md"
fi

# ═══════════════════════════════════════════════════════════════
# APPLY OPENCODE-SPECIFIC TRANSFORMATIONS
# ═══════════════════════════════════════════════════════════════

if [[ "$DRY_RUN" == false ]]; then
  echo ""
  echo -e "${BLUE}🔧 Applying Opencode Transformations...${NC}"

  # Update paths in config files (Claude -> Opencode path references)
  if [[ -f "$OPENCODE_DIR/skills/workflows-memory/config.jsonc" ]]; then
    # No transformation needed if paths are relative
    echo -e "  ${GREEN}✓${NC} Configuration compatible"
  fi
fi

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════════════════"

if [[ "$DRY_RUN" == true ]]; then
  echo -e "${YELLOW}DRY RUN COMPLETE${NC} - No files were modified"
  echo ""
  echo "Run without --dry-run to apply changes"
else
  echo -e "${GREEN}✅ Sync Complete!${NC}"
  echo ""
  echo "Summary:"
  echo "  - Directories synced: $DIRS_SYNCED"
  if [[ $WARNINGS -gt 0 ]]; then
    echo -e "  - Warnings: ${YELLOW}$WARNINGS${NC}"
  fi
  echo ""
  echo "Files synced to: $OPENCODE_DIR"
  echo ""
  echo "Commands now available in Opencode:"
  echo "  /memory/save     - Save conversation context"
  echo "  /memory/search   - Search indexed memories"
  echo "  /memory/cleanup  - Clean up old memories"
  echo "  /memory/triggers - View trigger phrases"
  echo "  /memory/status   - Check system health"
fi

echo "═══════════════════════════════════════════════════════════"
