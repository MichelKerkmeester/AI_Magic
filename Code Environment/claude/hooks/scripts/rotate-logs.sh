#!/usr/bin/env bash

# ───────────────────────────────────────────────────────────────
# LOG ROTATION SCRIPT
# ───────────────────────────────────────────────────────────────
# Rotates hook log files when they exceed threshold
# Keeps last 1000 lines, archives remainder with gzip compression

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOGS_DIR="$HOOKS_DIR/logs"
ARCHIVE_DIR="$LOGS_DIR/archive"
THRESHOLD=10000  # Rotate when file exceeds this many lines
KEEP_LINES=1000  # Keep this many recent lines

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create archive directory if it doesn't exist
mkdir -p "$ARCHIVE_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "LOG ROTATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ROTATED_COUNT=0

# Find all .log files in logs directory
for log_file in "$LOGS_DIR"/*.log; do
  # Skip if no log files found
  if [ ! -f "$log_file" ]; then
    continue
  fi

  filename=$(basename "$log_file")
  line_count=$(wc -l < "$log_file")

  echo -n "Checking $filename ($line_count lines)... "

  # Check if rotation needed
  if [ "$line_count" -gt "$THRESHOLD" ]; then
    echo -e "${YELLOW}ROTATING${NC}"

    # Calculate lines to archive
    lines_to_archive=$((line_count - KEEP_LINES))

    # Create timestamp for archive file
    timestamp=$(date +%Y%m%d_%H%M%S)
    archive_name="${filename%.log}_${timestamp}.log"

    # Extract lines to archive
    head -n "$lines_to_archive" "$log_file" > "$ARCHIVE_DIR/$archive_name"

    # Compress archived file
    gzip "$ARCHIVE_DIR/$archive_name"

    # Keep only recent lines in original file
    tail -n "$KEEP_LINES" "$log_file" > "$log_file.tmp"
    mv "$log_file.tmp" "$log_file"

    # Calculate archive size
    archive_size=$(du -h "$ARCHIVE_DIR/${archive_name}.gz" | cut -f1)

    echo "  ✓ Archived $lines_to_archive lines → $archive_size"
    echo "  ✓ Kept $KEEP_LINES recent lines in $filename"

    ROTATED_COUNT=$((ROTATED_COUNT + 1))
  else
    echo -e "${GREEN}OK${NC}"
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$ROTATED_COUNT" -eq 0 ]; then
  echo "✓ No rotation needed"
else
  echo -e "✓ Rotated ${GREEN}$ROTATED_COUNT${NC} log file(s)"
  echo ""
  echo "Archive location: $ARCHIVE_DIR"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
