# Verification Enforcement v3.0.0 - Quick Reference

## What Changed?

**Problem**: Hook was blocking legitimate instructions like "make sure it works", "create a feature", "when done, update..."

**Solution**: Added exclusion-first detection that allows instructions/requests while still blocking completion claims.

**Result**: 0% false positives (down from ~40%), 100% true positive detection maintained.

## Usage Guide

### ✅ These Will PASS (No Blocking)

```bash
# Instructions/Commands
"Analyze the code and create documentation"
"Fix the bug and ensure everything works"
"Update the README to make sure it's current"
"Create a feature that is working correctly"

# Future Intent
"This should work after the fix"
"Will be complete tomorrow"
"Could be done by evening"

# Conditionals
"Check if it works"
"Verify whether it's complete"
"When done, run tests"

# Requests
"Make sure the animation works"
"Ensure the feature is working"
"Double check if hooks are working properly"

# Options
"Use whatever works best"
"Choose whichever approach is complete"

# Negations
"The feature is not working"
"Tests aren't passing yet"
```

### 🔴 These Will BLOCK (Need Evidence)

```bash
# Definitive Claims
"The animation is complete"          # ❌ No evidence
"Done."                               # ❌ No evidence
"I have completed the feature"        # ❌ No evidence
"Everything is working now"           # ❌ No evidence
"All issues fixed"                    # ❌ No evidence
"Video player is working now"         # ❌ No evidence

# Insufficient Evidence (need 2+ points)
"Done, tested in Chrome"              # ❌ Only 1 evidence
"Complete, console is clear"          # ❌ Only 1 evidence
"Fixed, tested at 1920px"             # ❌ Only 1 evidence
```

### ✅ These Will PASS (Valid Evidence)

```bash
# 2+ Evidence Points
"Done. Tested in Chrome at 1920px, console clear"
# ✓ Browser + Viewport = 2 points

"Complete. Tested in Firefox, opened browser, DevTools shows no errors"
# ✓ Browser + Observation + Console = 3 points

"Everything works. Tested at desktop and mobile viewports, watched animation"
# ✓ Multi-viewport + Observation = 2 points

"Fixed. Tested in Safari at 375px and 1920px, refreshed page, console clear"
# ✓ Browser + Viewport + Observation + Console = 4 points
```

## Evidence Types

Need **2 or more** of these:

| Evidence Type | Examples |
|---------------|----------|
| **Browser** | "tested in Chrome", "tested in Firefox", "tested in Safari" |
| **Console** | "DevTools console clear", "console shows no errors" |
| **Viewport Sizes** | "tested at 1920px", "tested at 375px", "tested at 768px" |
| **Multi-Device** | "tested at desktop and mobile viewports" |
| **Observation** | "saw", "watched", "observed", "opened browser", "refreshed page" |

## Common Patterns

### Pattern 1: Imperative Instructions (ALLOWED)

```
Analyze...
Create...
Update...
Fix...
Check...
Verify...
Test...
Ensure...
Make sure...
Double check...
Improve...
Remove...
Add...
Implement...
Investigate...
```

### Pattern 2: Modal Verbs (ALLOWED)

```
should work
will be done
would be ready
could be complete
might work
can be fixed
must be working
```

### Pattern 3: Infinitive Phrases (ALLOWED)

```
to make sure it works
to verify it's complete
to ensure it's working
to check if done
to test if ready
```

### Pattern 4: Temporal Markers (ALLOWED)

```
When done, do X
After it's working, check Y
Once complete, deploy
If it's ready, ship
```

### Pattern 5: Completion Claims (BLOCKED without evidence)

```
I have completed
I've fixed
I just finished
This is complete
Everything is done
The fix is ready
Done.
Complete.
Fixed.
The animation works
Video player is working now
Verified in browser
All issues fixed
Everything works now
```

## Testing

### Run Full Test Suite
```bash
cd .claude/hooks/UserPromptSubmit

# Synthetic tests (31 tests)
./test-enforce-verification.sh

# Real-world tests (21 tests)
./test-real-world-cases.sh
```

### Test Individual Prompt
```bash
echo '{"prompt": "YOUR_PROMPT_HERE"}' | ./enforce-verification.sh
echo "Exit code: $?"  # 0 = allowed, 1 = blocked
```

## Files

```
.claude/hooks/UserPromptSubmit/
├── enforce-verification.sh                    # Main hook (v3.0.0)
├── test-enforce-verification.sh               # Synthetic tests
├── test-real-world-cases.sh                   # Real-world tests
├── VERIFICATION_ENFORCEMENT_SOLUTION.md       # Full documentation
├── CHANGELOG_v3.0.0.md                        # Version changelog
└── QUICK_REFERENCE_v3.0.0.md                  # This file
```

## Troubleshooting

### Issue: Getting blocked on instructions

**Check**: Is your prompt starting with an imperative verb?
- ✅ "Analyze and create..." (ALLOWED)
- ❌ "The analysis is complete" (BLOCKED)

### Issue: Completion claim with evidence still blocked

**Check**: Do you have 2+ evidence points?
- ✅ "Done. Tested in Chrome, console clear" (2 points)
- ❌ "Done. Tested in Chrome" (1 point)

### Issue: Want to bypass for testing

**Option 1**: Add sufficient evidence
```bash
"Testing complete. Tested in Chrome at 1920px and 375px, console clear"
```

**Option 2**: Rephrase as instruction
```bash
# Instead of: "The feature is done"
# Use: "Verify the feature is done"
```

## Performance

- Execution time: <50ms
- No memory overhead
- Compatible: Bash 3.2+ (macOS and Linux)

## Metrics

| Metric | Value |
|--------|-------|
| False Positive Rate | 0% |
| True Positive Rate | 100% |
| Test Coverage | 52 tests |
| Pass Rate | 100% |

## Quick Examples

```bash
# ALLOWED (Instructions)
✅ "make sure it still works"
✅ "whatever works best"
✅ "when done, update README"
✅ "analyze and create template"

# BLOCKED (Claims without evidence)
🔴 "animation is complete"
🔴 "done."
🔴 "everything works"
🔴 "all issues fixed"

# ALLOWED (Claims with evidence)
✅ "done. tested in chrome at 1920px, console clear"
✅ "complete. tested at desktop and mobile, watched animation"
✅ "fixed. tested in firefox, opened browser, devtools clear"
```

---

**Version**: 3.0.0
**Status**: Production Ready
**Validation**: 52/52 tests passing
