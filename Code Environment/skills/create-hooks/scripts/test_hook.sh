#!/bin/bash

# ───────────────────────────────────────────────────────────────
# HOOK TESTING HARNESS
# ───────────────────────────────────────────────────────────────
# Tests hook with sample JSON payloads and captures output
#
# Usage: ./test_hook.sh <hook-file> <payload-json-file>
# ───────────────────────────────────────────────────────────────

if [ $# -ne 2 ]; then
  echo "Usage: $0 <hook-file> <payload-json-file>" >&2
  exit 1
fi

HOOK_FILE="$1"
PAYLOAD_FILE="$2"

if [ ! -f "$HOOK_FILE" ]; then
  echo "❌ Error: Hook file not found: $HOOK_FILE" >&2
  exit 1
fi

if [ ! -f "$PAYLOAD_FILE" ]; then
  echo "❌ Error: Payload file not found: $PAYLOAD_FILE" >&2
  exit 1
fi

# Validate JSON payload
if ! jq empty "$PAYLOAD_FILE" 2>/dev/null; then
  echo "❌ Error: Invalid JSON in payload file" >&2
  exit 1
fi

echo "──────────────────────────────────────────────────────"
echo "Testing Hook: $(basename "$HOOK_FILE")"
echo "Payload: $(basename "$PAYLOAD_FILE")"
echo "──────────────────────────────────────────────────────"
echo ""
echo "Payload Contents:"
jq '.' "$PAYLOAD_FILE"
echo ""
echo "──────────────────────────────────────────────────────"
echo "Hook Output:"
echo "──────────────────────────────────────────────────────"
echo ""

# Run hook with payload
START_TIME=$(date +%s%N)
cat "$PAYLOAD_FILE" | bash "$HOOK_FILE"
EXIT_CODE=$?
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

echo ""
echo "──────────────────────────────────────────────────────"
echo "Test Results:"
echo "──────────────────────────────────────────────────────"
echo "Exit Code: $EXIT_CODE"
echo "Duration: ${DURATION}ms"

case $EXIT_CODE in
  0)
    echo "Status: ✅ Success (EXIT_ALLOW)"
    ;;
  1)
    echo "Status: ⚠️  Warning (EXIT_BLOCK)"
    ;;
  2)
    echo "Status: ❌ Error (EXIT_ERROR)"
    ;;
  *)
    echo "Status: ❓ Non-standard exit code"
    ;;
esac

echo "──────────────────────────────────────────────────────"

exit $EXIT_CODE
