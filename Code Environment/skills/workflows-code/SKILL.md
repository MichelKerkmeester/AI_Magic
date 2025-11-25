---
name: workflows-code
description: Orchestrator guiding developers through implementation, debugging, and verification phases across specialized code quality skills (project)
allowed-tools: [Read, Grep, Glob, Bash]
version: 2.0.0
---

# Code Workflows - Development Orchestrator

Unified workflow guidance across 6 specialized code quality skills for frontend development.

**Core principle**: Implementation → Debugging (if needed) → Verification (MANDATORY) = reliable frontend code.

---

## 1. 🎯 CAPABILITIES OVERVIEW

This orchestrator operates in three primary phases:

### Phase 1: Implementation

Writing code with proper async handling, validation, and cache-busting.

**Use when**:
- Starting frontend development work
- Implementing forms, APIs, DOM manipulation
- Integrating external libraries or media
- JavaScript files have been modified

**See**: Section 2 (When to Use), Section 3 (How It Works), Section 4 (Rules), Section 5 (Success Criteria) below and [implementation_workflows.md](./references/implementation_workflows.md)

### Phase 2: Debugging

Fixing issues systematically using DevTools and evidence-based debugging.

**Use when**:
- Encountering console errors or unexpected behavior
- Deep call stack issues or race conditions
- Multiple debugging attempts needed
- Need root cause identification

**See**: Section 2 (When to Use), Section 3 (How It Works), Section 4 (Rules), Section 5 (Success Criteria) below and [debugging_workflows.md](./references/debugging_workflows.md)

### Phase 3: Verification (MANDATORY)

Browser testing across viewports before completion claims.

**Use when**:
- Before ANY completion claim ("works", "fixed", "done", "complete", "passing")
- After implementing or debugging frontend code
- Before claiming animations work, layouts are correct, or features are complete

**The Iron Law**: NO COMPLETION CLAIMS WITHOUT FRESH BROWSER VERIFICATION EVIDENCE

**See**: Section 2 (When to Use), Section 3 (How It Works), Section 4 (Rules), Section 5 (Success Criteria) below and [verification_workflows.md](./references/verification_workflows.md)

---

## 2. 🛠️ WHEN TO USE

### Navigation Guide

**This file (SKILL.md)**: Essential overview and navigation to specialized workflows

**Reference Files** (detailed documentation):
- [implementation_workflows.md](./references/implementation_workflows.md) - Phase 1: condition-based waiting, defense-in-depth validation, CDN versioning
- [performance_patterns.md](./references/performance_patterns.md) - Phase 1: Performance optimization (animations, assets, requests)
- [security_patterns.md](./references/security_patterns.md) - Phase 1: OWASP Top 10 security checklist (XSS, CSRF, injection prevention)
- [debugging_workflows.md](./references/debugging_workflows.md) - Phase 2: systematic debugging, root cause tracing
- [verification_workflows.md](./references/verification_workflows.md) - Phase 3: MANDATORY browser verification
- [shared_patterns.md](./references/shared_patterns.md) - DevTools, logging, testing, error patterns
- [devtools_guide.md](./references/devtools_guide.md) - Comprehensive DevTools reference
- [quick_reference.md](./references/quick_reference.md) - One-page cheat sheet

**Assets** (code templates and checklists):
- [wait_patterns.js](./assets/wait_patterns.js) - Production-ready waiting code
- [validation_patterns.js](./assets/validation_patterns.js) - Validation templates
- [debugging_checklist.md](./assets/debugging_checklist.md) - Debugging workflow checklist
- [verification_checklist.md](./assets/verification_checklist.md) - Browser testing checklist

**Scripts**:
- CDN versioning: Use manual workflow (see implementation_workflows.md Section 3)

### Phase 1: Implementation

**When implementing frontend code:**

**Async/timing issues?** → **Condition-Based Waiting**
- DOM elements not ready
- External libraries loading asynchronously
- Race conditions, intermittent failures
- See [implementation_workflows.md](./references/implementation_workflows.md#1-🕐-condition-based-waiting)

**Validation needed?** → **Defense-in-Depth**
- Form input handling
- API calls and responses
- DOM manipulation
- User-generated content
- See [implementation_workflows.md](./references/implementation_workflows.md#2-🛡️-defense-in-depth-validation)

**After JS changes?** → **CDN Versioning**
- JavaScript files modified
- Need cache-busting
- See [implementation_workflows.md](./references/implementation_workflows.md#3-🔄-cdn-version-management)

**Performance optimization needed?** → **Performance Patterns**
- Animation performance (Motion.dev, CSS animations)
- Video player optimization (HLS.js)
- Asset optimization (images, fonts)
- Request caching and debouncing
- See [performance_patterns.md](./references/performance_patterns.md)

**Security needed?** → **Security Patterns (OWASP)**
- User input handling (XSS prevention)
- Form submission (CSRF protection)
- API calls (injection prevention)
- Access control validation
- See [security_patterns.md](./references/security_patterns.md)

### Phase 2: Debugging

**When debugging issues:**

**First debugging attempt?** → **Systematic Debugging**
- Console errors, layout bugs, animation issues
- Event handler failures
- Cross-browser inconsistencies
- See [debugging_workflows.md](./references/debugging_workflows.md#1-🔍-systematic-debugging)

**Deep call stack error?** → **Root Cause Tracing**
- Error happens deep in execution
- Event handlers fail mysteriously
- Data arrives corrupted
- Unclear where invalid data originated
- See [debugging_workflows.md](./references/debugging_workflows.md#2-🔎-root-cause-tracing)

**Performance issues?** → **Performance Debugging**
- Slow page load
- Janky animations
- Memory leaks
- High CPU usage
- See [debugging_workflows.md](./references/debugging_workflows.md#3-🔍-performance-debugging)

### Phase 3: Verification (MANDATORY)

**Use BEFORE claiming**:
- Animation is working
- Layout issue is fixed
- Feature is complete
- Video/media loads
- Form submission works
- Any statement of completion or success

**The Iron Law**: Evidence in browser before claims, always.

See [verification_workflows.md](./references/verification_workflows.md) for complete requirements.

---

## 3. ⚙️ HOW TO USE

### Development Lifecycle

Frontend development flows through 3 phases:

```
Implementation → Debugging (if issues) → Verification (MANDATORY)
```

### Phase 1: Implementation

**Implementation involves three specialized workflows:**

1. **Condition-Based Waiting** - Replace arbitrary setTimeout with condition polling
   - Wait for actual conditions, not timeouts
   - Includes timeout limits with clear errors
   - Handles: DOM ready, library loading, image/video ready, animations

2. **Defense-in-Depth Validation** - Validate at every layer data passes through
   - Layer 1: Entry point validation
   - Layer 2: Processing validation
   - Layer 3: Output validation
   - Layer 4: Safe access patterns

3. **CDN Version Management** - Update version parameters after JS changes
   - Manual version increment workflow (see Section 3)
   - Updates all HTML files referencing changed JS
   - Forces browser cache refresh

See [implementation_workflows.md](./references/implementation_workflows.md) for complete workflows.

### Phase 2: Debugging

**Systematic Debugging** uses a 4-phase framework:

1. **Root Cause Investigation**
   - Read error messages carefully
   - Reproduce consistently
   - Check recent changes
   - Gather evidence in DevTools
   - Trace data flow

2. **Pattern Analysis**
   - Find working examples
   - Compare against references
   - Identify differences
   - Understand dependencies

3. **Hypothesis and Testing**
   - Form single hypothesis
   - Test minimally (one change at a time)
   - Verify before continuing
   - Ask when unsure

4. **Implementation**
   - Document the fix
   - Implement single fix
   - Verify in browser
   - If 3+ fixes failed → question approach

**Root Cause Tracing** traces backward through call chain:

1. Observe symptom
2. Find immediate cause
3. Trace one level up
4. Keep tracing up
5. Fix at source, not symptom

See [debugging_workflows.md](./references/debugging_workflows.md) for complete workflows.

### Phase 3: Verification

**The Gate Function** - BEFORE claiming any status:

1. IDENTIFY: What command/action proves this claim?
2. OPEN: Launch actual browser
3. TEST: Execute the interaction
4. VERIFY: Does browser show expected behavior?
5. VERIFY: Multi-viewport check (mobile + desktop)
6. VERIFY: Cross-browser check (if critical)
7. RECORD: Note what you saw
8. ONLY THEN: Make the claim

**Browser Testing Matrix:**

**Minimum** (ALWAYS REQUIRED):
- Chrome Desktop (1920px)
- Mobile emulation (375px)
- DevTools Console - No errors

**Standard** (Production work):
- Chrome Desktop (1920px)
- Chrome Tablet emulation (768px)
- Chrome Mobile emulation (375px)
- DevTools console clear at all viewports

See [verification_workflows.md](./references/verification_workflows.md) for complete requirements.

**Alternative Verification: Gemini CLI** (Optional second opinion)

When you need additional validation beyond browser testing:

**When to Use:**
- Code review for security vulnerabilities
- Architecture validation before finalizing
- Performance optimization suggestions
- Cross-checking implementation approach
- Complex algorithm verification

**Example Workflow:**
1. Complete implementation (Phase 1)
2. Fix any issues found during debugging (Phase 2)
3. **Before Phase 3 browser verification**, optionally invoke `cli-gemini` skill
4. Request: "Review this code for security issues and performance"
5. Compare Gemini feedback with your analysis
6. Address any critical issues discovered
7. Proceed to Phase 3 browser verification (MANDATORY)

**Integration:** Use **after** debugging, **before** browser verification. See [cli-gemini](../cli-gemini/SKILL.md) skill for detailed usage.

**Important**: Gemini CLI is supplementary. Browser verification is MANDATORY.

---

## 4. 📋 RULES

### Phase 1: Implementation

**✅ ALWAYS:**
- Wait for actual conditions, not arbitrary timeouts
- Include timeout limits (default 5-10 seconds)
- Validate function parameters (null/undefined/type checks)
- Validate API responses before using data
- Validate DOM elements exist before manipulating
- Sanitize user input before storing or displaying
- Run CDN version updater after ANY JavaScript modification
- Use optional chaining (`?.`) for nested access
- Add `try/catch` around risky operations
- Log when operations complete successfully

**❌ NEVER:**
- Use `setTimeout` without documenting WHY
- Wait without timeout (infinite loops)
- Assume data exists without checking
- Trust external data (APIs, user input, URL params)
- Access nested properties without validation
- Use innerHTML with unsanitized data
- Use the same CDN version number after making changes
- Deploy JS without updating HTML versions
- Skip validation failures silently

**⚠️ ESCALATE IF:**
- Condition never becomes true (infinite wait)
- Validation logic becoming too complex
- Security concerns with XSS or injection attacks
- Script reports no HTML files found
- CDN version cannot be determined

See [implementation_workflows.md](./references/implementation_workflows.md) for detailed rules.

### Phase 2: Debugging

**✅ ALWAYS:**
- Open browser DevTools console BEFORE attempting fixes
- Read complete error messages and stack traces
- Test across multiple viewports via Chrome DevTools emulation (375px, 768px, 1920px minimum)
- Test on mobile viewports (320px, 768px minimum)
- Check Network tab for failed resource loads
- Add console.log statements to trace execution
- Test one change at a time
- Use browser DevTools debugger for complex issues
- Add console.trace() to find call stack
- Trace backward from symptom to source
- Fix at the source, not symptom
- Document root cause in comments

**❌ NEVER:**
- Skip console error messages
- Test only in one browser
- Ignore mobile viewport issues
- Change multiple things simultaneously
- Use `!important` without understanding why
- Proceed with 4th fix without questioning approach
- Fix only where error appears without tracing
- Add symptom fixes (null checks without understanding why)
- Skip DevTools investigation
- Leave production console.log statements

**⚠️ ESCALATE IF:**
- Bug only occurs in production
- Issue requires changing Webflow-generated code
- Cross-browser compatibility cannot be achieved
- Bug intermittent despite extensive logging
- Cannot trace backward (dead end)
- Root cause in third-party library

See [debugging_workflows.md](./references/debugging_workflows.md) for detailed rules.

### Phase 3: Verification (MANDATORY)

**✅ ALWAYS:**
- Open actual browser to verify (not just code review)
- Test in Chrome at minimum (primary browser)
- Test mobile viewport (375px minimum)
- Check DevTools console for errors
- Test interactive elements by clicking them
- Watch full animation cycle to verify timing
- Test at key responsive breakpoints (320px, 768px, 1920px)
- Note what you tested in your claim
- Record any limitations

**❌ NEVER:**
- Claim "works" without opening browser
- Say "should work" or "probably works" - test it
- Trust code review alone for visual/interactive features
- Test only at one viewport size
- Ignore console warnings as "not important"
- Skip animation timing verification
- Assume desktop testing covers mobile
- Claim "cross-browser" without testing multiple browsers
- Express satisfaction before verification ("Great!", "Perfect!", "Done!")

**⚠️ ESCALATE IF:**
- Cannot test in required browsers
- Real device testing required but unavailable
- Issue only reproduces in production
- Performance testing requires specialized tools

See [verification_workflows.md](./references/verification_workflows.md) for detailed rules.

---

## 5. 🏆 SUCCESS CRITERIA

### Phase 1: Implementation

**Implementation is successful when:**
- ✅ No arbitrary setTimeout used (or documented why needed)
- ✅ All waits have timeout limits
- ✅ All function parameters validated
- ✅ All DOM queries check for null
- ✅ All API responses validated before use
- ✅ All user input sanitized
- ✅ CDN versions updated after JS changes
- ✅ Safe defaults provided for missing data
- ✅ Clear error messages logged
- ✅ Code handles edge cases gracefully

**Quality gates:**
- Can you explain what condition is being waited for?
- What happens if API returns null?
- What happens if DOM element doesn't exist?
- Did you run the CDN version updater?
- Are all code paths tested with invalid data?

See [implementation_workflows.md](./references/implementation_workflows.md) for complete criteria.

### Phase 2: Debugging

**Debugging is successful when:**
- ✅ Root cause identified and documented
- ✅ Fix addresses cause, not symptom
- ✅ Tested across all target browsers
- ✅ Tested on mobile and desktop viewports
- ✅ No console errors introduced
- ✅ Performance not degraded
- ✅ Code comments explain WHY fix needed
- ✅ Browser-specific workarounds documented
- ✅ Single fix resolved issue (not multiple attempts)

**Quality gates:**
- Did you open DevTools console?
- Did you read complete error messages?
- Did you test in multiple browsers?
- Did you test on mobile viewports?
- Can you explain WHY the fix works?
- Did you fix the root cause or just the symptom?

See [debugging_workflows.md](./references/debugging_workflows.md) for complete criteria.

### Phase 3: Verification

**Verification is successful when:**
- ✅ Opened actual browser (not just reviewed code)
- ✅ Tested in multiple viewports (mobile + desktop minimum)
- ✅ Checked DevTools console (no errors)
- ✅ Tested interactions by actually clicking/hovering
- ✅ Watched full animation cycle (if applicable)
- ✅ Tested in multiple browsers (if claiming cross-browser)
- ✅ Documented what was tested in claim
- ✅ Can describe exactly what was seen in browser
- ✅ Noted any limitations or remaining work

**Quality gates:**
- Can you describe what you saw in browser?
- Did you test at mobile viewport?
- Is DevTools console clear?
- Did you test the actual user interaction?
- Did you verify animation timing by watching it?
- Can you confidently say it works because you saw it work?

See [verification_workflows.md](./references/verification_workflows.md) for complete criteria.

---

## 6. 🔌 INTEGRATION POINTS

### Code Quality Standards (INTEGRATED)

**Primary Reference:** [code_quality_standards.md](./references/code_quality_standards.md)

This workflow integrates three core knowledge base standards:

#### Naming Conventions
- **JavaScript:** `snake_case` for all identifiers (variables, functions, classes)
- **Constants:** `UPPER_SNAKE_CASE` (e.g., `MAX_RETRIES`, `INIT_DELAY_MS`)
- **Semantic prefixes:** `is_`, `has_`, `get_`, `set_`, `handle_`, `init_`, `load_`
- **CSS:** `kebab-case` with BEM notation

**Full reference:** [code_standards.md](../../knowledge/code_standards.md)

#### Initialization Pattern (CDN-Safe)
Every component uses standardized CDN-safe initialization:
- Guard flags prevent double initialization
- Delays ensure dependency readiness (Motion.dev, etc.)
- Webflow.push integration for proper lifecycle
- `INIT_DELAY_MS`: 0ms (no deps), 50ms (standard), 100ms+ (heavy deps)

**Full reference:** [initialization_pattern.md](../../knowledge/initialization_pattern.md)

#### Animation Strategy
- **CSS first:** Simple transitions, hover states, single-property animations
- **Motion.dev:** Complex sequences, scroll triggers, in-view, stagger
- **Mandatory:** `prefers-reduced-motion` support, `will-change` cleanup
- **Easing:** `[0.22, 1, 0.36, 1]` (ease-out), `[0.16, 1, 0.3, 1]` (expo-out)

**Full reference:** [animation_strategy.md](../../knowledge/animation_strategy.md)

**Quick Integration:** See [code_quality_standards.md Section 6](./references/code_quality_standards.md#6-integration-with-workflows-code) for phase-by-phase integration guide.

### Tool Usage Guidelines

- **Bash**: Git commands, system operations
- **Read**: Examine code files, documentation
- **Grep**: Pattern searches, finding keywords
- **Glob**: File discovery by patterns

### Additional Knowledge Base Dependencies

- `.claude/knowledge/webflow_platform_constraints.md` - Platform limitations
- `.claude/knowledge/code_standards.md` - Naming conventions and file structure

### External Tools

- **Browser DevTools** - Chrome DevTools MCP (automated testing), Chrome DevTools (manual debugging)
- **Python 3** - General scripting support
- **Git** - Version control for checking changes
- **Motion.dev** - Animation library (CDN: jsdelivr.net/npm/motion@12.15.0)

### Chrome DevTools MCP Integration

**Automated browser testing and debugging using MCP tools:**

The workflows-code skill integrates with Chrome DevTools MCP for automated testing workflows.

**Available Instances (Multi-Agent Concurrency):**
- `mcp__chrome_devtools_1__*` - Instance 1 (26 tools)
- `mcp__chrome_devtools_2__*` - Instance 2 (26 tools)

**Phase 2 (Debugging) Integration:**
- `list_console_messages` - Automated console error capture
- `list_network_requests` - Network request monitoring
- `evaluate_script` - Live JavaScript testing
- `take_snapshot` - DOM structure inspection

**Phase 3 (Verification) Integration:**
- `navigate_page` - Navigate to URL
- `take_screenshot` - Multi-viewport visual testing
- `resize_page` - Set viewport dimensions
- `list_console_messages` - Console error validation
- `performance_start_trace` / `performance_stop_trace` - Core Web Vitals measurement
- `list_network_requests` - Failed request detection

**Key Tools:**
- Navigation: `navigate_page`, `new_page`, `select_page`, `close_page`
- Interaction: `click`, `fill`, `hover`, `drag`, `press_key`, `wait_for`
- Analysis: `list_console_messages`, `list_network_requests`, `evaluate_script`
- Capture: `take_screenshot`, `take_snapshot`
- Performance: `performance_start_trace`, `performance_stop_trace`
- Emulation: `resize_page`, `emulate`

**Usage Pattern:**
```markdown
1. Navigate to page:
   [Use tool: mcp__chrome_devtools_2__navigate_page]
   - url: "https://example.com"

2. Check for errors:
   [Use tool: mcp__chrome_devtools_2__list_console_messages]
   - Filter response for type === "error"

3. Capture screenshot:
   [Use tool: mcp__chrome_devtools_2__resize_page]
   - width: 375, height: 667
   [Use tool: mcp__chrome_devtools_2__take_screenshot]
```

**See Also:**
- [debugging_workflows.md](./references/debugging_workflows.md) - Automated debugging examples
- [verification_workflows.md](./references/verification_workflows.md) - Automated verification workflows (Section 2.5)
- [shared_patterns.md](./references/shared_patterns.md) - Common automation patterns

### Hook System Integration

**post-tool-use quality hooks** - Review QUALITY CHECK output and logs:
- `.claude/hooks/logs/quality-checks.log` - Quality check results
- Use as inputs to Phase 1 investigation during debugging

See [shared_patterns.md](./references/shared_patterns.md) for common patterns across all workflows.

---

## 7. 📖 REFERENCES

### Workflow Documentation

**Implementation (Phase 1)**:
- [implementation_workflows.md](./references/implementation_workflows.md) - Complete Phase 1 workflows
  - Condition-based waiting patterns
  - Defense-in-depth validation
  - CDN version management

**Debugging (Phase 2)**:
- [debugging_workflows.md](./references/debugging_workflows.md) - Complete Phase 2 workflows
  - Systematic debugging (4-phase framework)
  - Root cause tracing techniques

**Verification (Phase 3 - MANDATORY)**:
- [verification_workflows.md](./references/verification_workflows.md) - Complete Phase 3 requirements
  - Browser testing matrix
  - The Iron Law
  - Verification checklists

**Cross-Workflow Resources**:
- [code_quality_standards.md](./references/code_quality_standards.md) - Integrated naming, initialization, animation standards
- [shared_patterns.md](./references/shared_patterns.md) - DevTools, logging, testing, error patterns
- [devtools_guide.md](./references/devtools_guide.md) - Comprehensive DevTools reference
- [quick_reference.md](./references/quick_reference.md) - One-page cheat sheet

### Code Templates

- [wait_patterns.js](./assets/wait_patterns.js) - Production-ready waiting code
- [validation_patterns.js](./assets/validation_patterns.js) - Validation class templates

### Checklists

- [debugging_checklist.md](./assets/debugging_checklist.md) - 4-phase debugging workflow
- [verification_checklist.md](./assets/verification_checklist.md) - Browser testing checklist

### Scripts

- CDN versioning: Manual workflow documented in [implementation_workflows.md Section 3](./references/implementation_workflows.md#3-🔄-cdn-version-management)

---

## 8. 🚀 QUICK START

### For Implementation

1. **Read**: This SKILL.md Section 2 (When to Use), Section 3 (How It Works), Section 4 (Rules), Section 5 (Success Criteria)
2. **Navigate**: [implementation_workflows.md](./references/implementation_workflows.md)
3. **Use Templates**: [wait_patterns.js](./assets/wait_patterns.js), [validation_patterns.js](./assets/validation_patterns.js)

### For Debugging

1. **Read**: This SKILL.md Section 2 (When to Use), Section 3 (How It Works), Section 4 (Rules), Section 5 (Success Criteria)
2. **Navigate**: [debugging_workflows.md](./references/debugging_workflows.md)
3. **Use Checklist**: [debugging_checklist.md](./assets/debugging_checklist.md)
4. **Reference**: [devtools_guide.md](./references/devtools_guide.md)

### For Verification

1. **Read**: This SKILL.md Section 2 (When to Use), Section 3 (How It Works), Section 4 (Rules), Section 5 (Success Criteria)
2. **Navigate**: [verification_workflows.md](./references/verification_workflows.md)
3. **Use Checklist**: [verification_checklist.md](./assets/verification_checklist.md)

### Quick Reference

Need fast navigation? See [quick_reference.md](./references/quick_reference.md)

---

**Remember**: This orchestrator navigates you to specialized workflows. Load reference files for detailed instructions.

**The Iron Law**: EVIDENCE BEFORE ASSERTIONS | BROWSER TESTING IS MANDATORY | NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION

---

## 9. 🧭 WHERE AM I? (Phase Detection Helper)

If you're unsure which phase you're in, use this self-assessment:

### Phase 1: Implementation

**You're here if:**
- [ ] Writing new code or modifying existing code
- [ ] Running builds and fixing compilation errors
- [ ] Implementing feature requirements
- [ ] Not yet testing or verifying

**Exit criteria:** All code written, builds successfully

### Phase 2: Debugging

**You're here if:**
- [ ] Code written but has bugs or failing tests
- [ ] Investigating root causes of failures
- [ ] Fixing logic errors or edge cases
- [ ] Not yet fully functional

**Exit criteria:** All tests passing, feature functional

### Phase 3: Verification

**You're here if:**
- [ ] All tests passing, feature appears complete
- [ ] Performing final validation in browser/environment
- [ ] Checking edge cases and user experience
- [ ] Ready to mark as complete

**Exit criteria:** Verified in real environment, ready to ship

### Troubleshooting: Phase Confusion

**"I'm fixing bugs while implementing"** → Stay in Phase 1, treat bugs as part of implementation

**"Tests pass but feature incomplete"** → Return to Phase 1, more implementation needed

**"Feature works but tests fail"** → Phase 2, debug test failures

---

## 10. 🔧 TROUBLESHOOTING

### Animation Not Working

**Symptom**: CSS animations don't play, timing issues, or jank on mobile

**Solutions**:
1. **Check DevTools** - Verify no console errors blocking execution
2. **Verify conditions** - Ensure trigger elements exist before adding animation classes
3. **Test mobile timing** - Animations may need longer durations on slower devices
4. **See**: [implementation_workflows.md](./references/implementation_workflows.md) - Condition-based waiting patterns

### Verification Failing Despite Working Code

**Symptom**: Feature works in testing but verification step finds issues

**Solutions**:
1. **Clear browser cache** - Old assets may be cached
2. **Test in clean incognito window** - Eliminates extension/cookie interference
3. **Check all viewports** - Mobile (375px), Tablet (768px), Desktop (1920px)
4. **Review console** - ANY errors = verification fails
5. **See**: [verification_workflows.md](./references/verification_workflows.md) - Complete verification matrix

### Async Code Failing Intermittently

**Symptom**: Works sometimes, fails others; timing-related bugs

**Solutions**:
1. **Add condition-based waiting** - Never use setTimeout/arbitrary delays
2. **Verify element existence** - Check DOM element ready before manipulation
3. **Add timeout limits** - Default 5-10 seconds with clear error messages
4. **See**: [wait_patterns.js](./assets/wait_patterns.js) - Production-ready waiting code

### DevTools Shows No Errors But Feature Broken

**Symptom**: No console errors, but feature doesn't work as expected

**Solutions**:
1. **Check Network tab** - Verify all resources loaded (200 status)
2. **Add console.log statements** - Trace execution flow
3. **Use breakpoints** - Step through code in Sources tab
4. **See**: [debugging_workflows.md](./references/debugging_workflows.md) - Systematic debugging approach

**Need more help?** Check reference files in `references/` directory or see Section 7 (REFERENCES)