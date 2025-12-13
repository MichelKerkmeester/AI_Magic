# Trigger Configuration - Keywords & Auto-Save Settings

> Complete configuration guide for memory trigger phrases, auto-save intervals, and the fast trigger matching system.

---

## 1. 📖 OVERVIEW

**Core Principle:** Trigger detection must be fast (<50ms) and reliable, using optimized phrase matching to surface relevant memories without impacting conversation flow.

The memory workflow supports two activation mechanisms:
1. **Explicit Triggers** - User phrases that directly invoke memory operations
2. **Automatic Triggers** - Interval-based auto-save for continuous context preservation

This reference covers trigger phrase configuration, the MCP-based matching system, auto-save tuning, and best practices for custom trigger design.

### Key Components

| Component | Purpose | Performance Target |
|-----------|---------|-------------------|
| Trigger Phrases | Explicit memory activation | <50ms detection |
| Auto-Save | Interval-based preservation | Every 20 messages |
| MCP Tool | Fast phrase matching | <50ms response |
| Custom Config | Project-specific triggers | Configurable |

---

## 2. 🎯 TRIGGER PHRASES

The following phrases activate memory operations (case-insensitive matching):

### Primary Triggers

| Category | Primary Phrase | Alternatives |
|----------|----------------|--------------|
| **Save** | "save context" | "save conversation", "save session" |
| **Document** | "document this" | "preserve context", "save this discussion" |
| **Remember** | "remember this" | "store this", "keep this context" |
| **Checkpoint** | "checkpoint" | "save checkpoint", "create checkpoint" |

### Detection Logic

```javascript
const TRIGGER_PHRASES = [
  // Save category
  'save context',
  'save conversation',
  'save session',
  'save this discussion',
  
  // Document category
  'document this',
  'preserve context',
  
  // Remember category
  'remember this',
  'store this',
  'keep this context',
  
  // Checkpoint category
  'checkpoint',
  'save checkpoint',
  'create checkpoint'
];

function detectTrigger(userMessage) {
  const normalized = userMessage.toLowerCase();
  return TRIGGER_PHRASES.some(phrase => normalized.includes(phrase));
}
```

### MCP Tool Integration

The `memory_match_triggers` MCP tool provides fast trigger phrase matching without requiring embeddings:

```typescript
// Fast trigger matching (<50ms) - no embeddings required
const result = await mcp__semantic_memory__memory_match_triggers({
  prompt: "I want to save context for this session",
  limit: 3  // Maximum matching memories to return
});

// Returns matching memories based on trigger phrases
// Ideal for proactive memory surfacing during conversation
```

**Usage Scenarios:**
- Quick keyword-based memory lookup before semantic search
- Proactive memory surfacing during conversation
- Fallback when semantic search is unavailable

---

## 3. ⚙️ AUTO-SAVE CONFIGURATION

### Message Interval Settings

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| `autoSaveInterval` | 20 | 10-50 | Messages between auto-saves |
| `minMessageThreshold` | 5 | 3-10 | Minimum messages before first save |
| `maxContextSize` | 8000 | 4000-16000 | Maximum tokens per save |

### Environment Variables

```bash
# Auto-save mode control
AUTO_SAVE_MODE=true          # Enable automatic saves (default)
AUTO_SAVE_MODE=false         # Disable for CI/testing

# Interval tuning
AUTO_SAVE_INTERVAL=20        # Messages between saves
MIN_MESSAGE_THRESHOLD=5      # Minimum before first save

# Debug mode
MEMORY_DEBUG=true            # Enable verbose logging
```

### Auto-Save Flow

```
Message Count Check
       ↓
[count >= interval?]──No──→ Continue conversation
       │
      Yes
       ↓
[Significant changes?]──No──→ Skip save, reset counter
       │
      Yes
       ↓
Generate context summary
       ↓
Save to memory system
       ↓
Reset message counter
```

### Significance Detection

Auto-save only triggers when significant context exists:

```javascript
function hasSignificantChanges(messages) {
  // Check for decision-making keywords
  const decisionKeywords = ['decided', 'chose', 'implemented', 'fixed', 'resolved'];
  
  // Check for code changes
  const hasCodeBlocks = messages.some(m => m.includes('```'));
  
  // Check for file modifications
  const hasFileOps = messages.some(m => 
    m.includes('Created:') || m.includes('Modified:') || m.includes('Deleted:')
  );
  
  return decisionKeywords.some(k => 
    messages.join(' ').toLowerCase().includes(k)
  ) || hasCodeBlocks || hasFileOps;
}
```

---

## 4. 🔧 CUSTOMIZATION

### Adding Custom Triggers

Create or modify `config.jsonc` in your project root:

```jsonc
{
  "memory": {
    "triggers": {
      // Add custom trigger phrases
      "custom": [
        "my custom phrase",
        "another trigger",
        "project-specific term"
      ],
      
      // Disable default triggers (optional)
      "disableDefaults": false,
      
      // Case sensitivity (default: false)
      "caseSensitive": false
    }
  }
}
```

### Custom Trigger Function

```javascript
// Extended detection with custom triggers
const CUSTOM_TRIGGERS = [
  'my custom phrase',
  'another trigger',
  'project-specific term'
];

function detectCustomTrigger(userMessage, customPhrases = CUSTOM_TRIGGERS) {
  const normalized = userMessage.toLowerCase();
  
  // Check default triggers first
  if (TRIGGER_PHRASES.some(phrase => normalized.includes(phrase))) {
    return { matched: true, source: 'default' };
  }
  
  // Check custom triggers
  if (customPhrases.some(phrase => normalized.includes(phrase))) {
    return { matched: true, source: 'custom' };
  }
  
  return { matched: false, source: null };
}
```

### Per-Project Configuration

Override defaults in your spec folder's memory settings:

```markdown
<!-- specs/001-feature/memory/config.md -->
# Memory Configuration

## Custom Triggers
- "feature complete"
- "milestone reached"
- "ready for review"

## Auto-Save Override
- Interval: 15 messages (more frequent for complex work)
- Threshold: 3 messages (lower for rapid iteration)
```

---

## 5. 📊 PERFORMANCE TARGETS

### Trigger Matching Performance

| Operation | Target | Acceptable | Degraded |
|-----------|--------|------------|----------|
| Phrase detection | <10ms | <50ms | >100ms |
| MCP tool call | <50ms | <100ms | >200ms |
| Custom trigger check | <20ms | <50ms | >100ms |

### Optimization Strategies

```javascript
// Pre-compile regex for frequently-used triggers
const COMPILED_TRIGGERS = TRIGGER_PHRASES.map(phrase => ({
  phrase,
  regex: new RegExp(phrase.replace(/\s+/g, '\\s+'), 'i')
}));

function optimizedDetection(userMessage) {
  // Use pre-compiled regex for faster matching
  return COMPILED_TRIGGERS.find(t => t.regex.test(userMessage));
}
```

### Memory Usage Guidelines

| Scenario | Recommended Interval | Rationale |
|----------|---------------------|-----------|
| Complex debugging | 10-15 messages | Capture detailed context |
| Feature development | 20 messages (default) | Balanced preservation |
| Quick fixes | 30-50 messages | Reduce overhead |
| Research/exploration | 15 messages | Preserve findings |

---

## 6. ✅ BEST PRACTICES

### Good vs Bad Trigger Phrases

| Category | Good Example | Bad Example | Reason |
|----------|--------------|-------------|--------|
| Specificity | "save this debug context" | "save" | Too generic causes false positives |
| Clarity | "checkpoint: auth complete" | "done" | Clear intent vs ambiguous |
| Action-oriented | "remember the API decision" | "this is important" | Explicit action vs vague |
| Scoped | "document the fix for #123" | "document" | Context-aware vs generic |

### Trigger Phrase Design Guidelines

1. **Be Specific** - Use action verbs with context
   - ✅ "save context for the auth refactor"
   - ❌ "save this"

2. **Avoid Common Words** - Prevent false positives
   - ✅ "checkpoint session"
   - ❌ "save" (too common)

3. **Include Context Type** - Help categorization
   - ✅ "document decision: chose JWT over sessions"
   - ❌ "document this"

4. **Use Consistent Patterns** - Establish team conventions
   - ✅ "memory: [type] - [description]"
   - ❌ Ad-hoc phrases per person

### Auto-Save Tuning Recommendations

```markdown
## When to Increase Frequency (lower interval)
- Complex multi-file refactoring
- Debugging sessions with many iterations
- Research with valuable discoveries
- Architecture decisions in progress

## When to Decrease Frequency (higher interval)
- Simple, repetitive tasks
- Well-understood changes
- CI/CD pipeline runs
- Batch file operations
```

### Integration Checklist

Before deploying custom triggers:

- [ ] Test trigger phrases don't conflict with common conversation
- [ ] Verify MCP tool response times meet <50ms target
- [ ] Configure appropriate auto-save interval for task type
- [ ] Document custom triggers in project README
- [ ] Test in CI environment with AUTO_SAVE_MODE=false

---

*Related: [SKILL.md](../SKILL.md) | [generate-context.js](../scripts/generate-context.js) | [Semantic Memory MCP](../../mcp-semantic-memory/SKILL.md)*
