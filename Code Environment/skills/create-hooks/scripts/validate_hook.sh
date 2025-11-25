#!/bin/bash

# ───────────────────────────────────────────────────────────────
# HOOK VALIDATION SCRIPT
# ───────────────────────────────────────────────────────────────
# Validates hook syntax, structure, and bash 3.2+ compatibility
#
# Usage: ./validate_hook.sh <path-to-hook>
# Exit: 0 = valid, 1 = invalid
# ───────────────────────────────────────────────────────────────

if [ $# -ne 1 ]; then
  echo "Usage: $0 <path-to-hook>" >&2
  exit 1
fi

HOOK_FILE="$1"

if [ ! -f "$HOOK_FILE" ]; then
  echo "❌ Error: File not found: $HOOK_FILE" >&2
  exit 1
fi

VALIDATION_PASSED=true

echo "──────────────────────────────────────────────────────"
echo "Validating Hook: $(basename "$HOOK_FILE")"
echo "──────────────────────────────────────────────────────"
echo ""

# Check 1: Executable permission
if [ ! -x "$HOOK_FILE" ]; then
  echo "⚠️  Warning: Hook not executable (chmod +x required)"
  VALIDATION_PASSED=false
fi

# Check 2: Shebang
if ! head -1 "$HOOK_FILE" | grep -q '^#!/bin/bash'; then
  echo "❌ Error: Missing or incorrect shebang (must be #!/bin/bash)"
  VALIDATION_PASSED=false
fi

# Check 3: Bash syntax
echo "🔍 Checking bash syntax..."
if ! bash -n "$HOOK_FILE" 2>/dev/null; then
  echo "❌ Error: Bash syntax errors detected"
  bash -n "$HOOK_FILE"
  VALIDATION_PASSED=false
else
  echo "✅ Bash syntax valid"
fi

# Check 4: Exit code usage
if ! grep -q 'exit.*EXIT_ALLOW\|exit.*EXIT_BLOCK\|exit.*EXIT_ERROR\|exit 0\|exit 1\|exit 2' "$HOOK_FILE"; then
  echo "⚠️  Warning: No standard exit codes found (EXIT_ALLOW/EXIT_BLOCK/EXIT_ERROR or 0/1/2)"
fi

# Check 5: JSON parsing
if ! grep -q 'jq' "$HOOK_FILE"; then
  echo "⚠️  Warning: No jq usage found (JSON parsing may be missing)"
fi

# Check 6: Bash 3.2+ incompatibilities
echo "🔍 Checking bash 3.2+ compatibility..."
if grep -q 'declare -A\|mapfile\|readarray' "$HOOK_FILE"; then
  echo "❌ Error: Bash 4+ features detected (incompatible with macOS bash 3.2)"
  echo "   Found: $(grep -o 'declare -A\|mapfile\|readarray' "$HOOK_FILE" | head -1)"
  VALIDATION_PASSED=false
else
  echo "✅ Bash 3.2+ compatible"
fi

# Check 7: Input sanitization
if ! grep -q 'tr -cd\|realpath\|sanitize' "$HOOK_FILE"; then
  echo "⚠️  Warning: No input sanitization detected (security risk)"
fi

echo ""
echo "──────────────────────────────────────────────────────"

if [ "$VALIDATION_PASSED" = true ]; then
  echo "✅ Validation passed: $(basename "$HOOK_FILE")"
  exit 0
else
  echo "❌ Validation failed: $(basename "$HOOK_FILE")"
  exit 1
fi
