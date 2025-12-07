# Trigger Configuration Reference

> Configuration for save-context trigger phrases and auto-save intervals.

---

## 1. 📖 OVERVIEW

The save-context workflow can be triggered through explicit phrases or automated intervals. This reference details the configuration options for both trigger detection and auto-save behavior.

---

## 2. 🎯 TRIGGER PHRASES

The following phrases activate save-context (case-insensitive):

| Primary Phrase | Alternatives |
|----------------|--------------|
| "save context" | "save conversation" |
| "document this" | "preserve context" |
| "save session" | "save this discussion" |

### Detection Logic

```javascript
const TRIGGER_PHRASES = [
  'save context',
  'save conversation',
  'document this',
  'preserve context',
  'save session',
  'save this discussion'
];

function detectTrigger(userMessage) {
  const normalized = userMessage.toLowerCase();
  return TRIGGER_PHRASES.some(phrase => normalized.includes(phrase));
}
```

---

## 3. ⚙️ AUTO-SAVE CONFIGURATION

### Message Interval

| Setting | Default | Description |
|---------|---------|-------------|
| `autoSaveInterval` | 20 | Messages between auto-saves |
| `minMessageThreshold` | 5 | Minimum messages before first save |

### Enabling/Disabling

Auto-save can be controlled via environment variable:

```bash
# Disable auto-save prompts (for hooks/CI)
AUTO_SAVE_MODE=true

# Enable interactive prompts (default)
AUTO_SAVE_MODE=false
```

---

## 4. 🔗 HOOK INTEGRATION

When using hooks, trigger detection occurs in `UserPromptSubmit`:

```bash
# Check for trigger phrase in user message
if echo "$USER_MESSAGE" | grep -qi -E "(save context|save conversation|document this)"; then
  # Execute save-context workflow
  node .opencode/skills/workflows-save-context/scripts/generate-context.js
fi
```

### Customization

To add custom trigger phrases, modify the detection logic in your hook:

```bash
CUSTOM_TRIGGERS="my custom phrase|another trigger"
if echo "$USER_MESSAGE" | grep -qi -E "($CUSTOM_TRIGGERS)"; then
  # Custom trigger detected
fi
```

---

*Related: [SKILL.md](../SKILL.md) | [generate-context.js](../scripts/generate-context.js)*
