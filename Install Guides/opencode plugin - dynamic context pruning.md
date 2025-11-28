# OpenCode Dynamic Context Pruning Plugin Installation Guide

A comprehensive guide to installing, configuring, and using the Dynamic Context Pruning (DCP) plugin for optimizing token usage in OpenCode sessions.

---

## 🤖 AI-First Install Guide

**Copy and paste this prompt to your AI assistant to get installation help:**

```
I want to install the OpenCode Dynamic Context Pruning plugin from https://github.com/Tarquinen/opencode-dynamic-context-pruning

Please help me:
1. Check if I have OpenCode CLI and Node.js installed
2. Add the plugin @tarquinen/opencode-dcp@0.3.19 to my opencode.json configuration
3. Restart OpenCode to auto-install the plugin
4. Configure the plugin settings for my use case (I want: [maximum savings / conservative / balanced])
5. Verify the plugin is working and show me how to monitor token savings

My project is located at: [your project path]

Guide me through each step with the exact configuration I need.
```

**What the AI will do:**
- Verify OpenCode and Node.js are properly installed
- Update your `opencode.json` to include the DCP plugin
- Explain the difference between Deduplication (free) and AI Analysis (uses tokens)
- Configure settings based on your preference (aggressive/conservative/balanced)
- Show you how to enable debug mode to see pruning activity
- Test the plugin with manual pruning
- Explain how to monitor token savings over time

**Expected setup time:** 2-5 minutes

---

## Table of Contents

1. [What is Dynamic Context Pruning?](#1-what-is-dynamic-context-pruning)
2. [Prerequisites](#2-prerequisites)
3. [Installation](#3-installation)
4. [Configuration](#4-configuration)
5. [Verifying Installation](#5-verifying-installation)
6. [Using Context Pruning](#6-using-context-pruning)
7. [Pruning Strategies Overview](#7-pruning-strategies-overview)
8. [Practical Examples](#8-practical-examples)
9. [Troubleshooting](#9-troubleshooting)
10. [Additional Resources](#10-additional-resources)

---

## 1. What is Dynamic Context Pruning?

Dynamic Context Pruning (DCP) is an OpenCode plugin that automatically optimizes token usage by intelligently removing obsolete tool outputs from conversation history. It keeps your sessions efficient by pruning irrelevant context while preserving important information.

### Key Features

- **Automatic Token Optimization**: Reduces token usage without manual intervention
- **Two Pruning Strategies**: Deduplication (free) and AI Analysis (uses LLM)
- **Non-Destructive**: Original session data remains intact
- **Smart Preservation**: Protects critical tools like Task and TodoWrite
- **Configurable**: Fine-tune behavior per project or globally
- **Zero-Cost Deduplication**: Removes duplicate tool calls without LLM costs

### How It Saves Tokens

| Before DCP | After DCP | Savings |
|------------|-----------|---------|
| Multiple identical file reads | Single read + placeholders | 60-80% |
| Repeated tool outputs | Deduplicated results | 40-60% |
| Obsolete context | Relevant context only | 30-50% |
| Long conversations | Optimized history | 25-45% |

### What Gets Pruned

- **Duplicate tool calls** with identical outputs
- **Obsolete file reads** superseded by edits
- **Redundant search results** no longer relevant
- **Stale context** not used in recent conversation

### What's Protected

- **Task tool** outputs (sub-agent results)
- **TodoWrite/TodoRead** (task tracking)
- **context_pruning** tool itself
- Recent tool calls (configurable threshold)
- User-specified protected tools

---

## 2. Prerequisites

Before installing Dynamic Context Pruning, ensure you have:

### Required

- **OpenCode CLI** installed and working
  ```bash
  # Verify OpenCode installation
  opencode --version
  ```

- **Node.js** (v16+) and npm
  ```bash
  node --version  # Should be 16.x or higher
  npm --version
  ```

- **OpenCode project** initialized
  ```bash
  # Your project should have opencode.json
  ls opencode.json
  ```

### Optional but Recommended

- **Git** for version control
- **Understanding of token costs** for your LLM provider
- **Existing OpenCode usage** to benefit from optimization

---

## 3. Installation

### Step 1: Add Plugin to Configuration

Add the DCP plugin to your `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "@tarquinen/opencode-dcp@0.3.19"
  ]
}
```

If you already have plugins, add it to the existing array:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "opencode-skills",
    "@tarquinen/opencode-dcp@0.3.19"
  ]
}
```

### Step 2: Restart OpenCode

```bash
# If OpenCode is running, exit first
# Then start fresh session
opencode

# Plugin will auto-install on first run
```

### Step 3: Verify Installation

The plugin will:
1. Download automatically from npm
2. Create configuration file on first run
3. Activate immediately
4. Show in plugin list

```bash
# Check installed plugins
# In OpenCode session:
> List installed plugins

# Expected output should include:
# - @tarquinen/opencode-dcp@0.3.19
```

### Installation Locations

- **Global config**: `~/.config/opencode/dcp.jsonc`
- **Project config**: `.opencode/dcp.jsonc` (takes precedence)
- **Plugin files**: `node_modules/@tarquinen/opencode-dcp/`

---

## 4. Configuration

### Configuration Hierarchy

Settings cascade in this order (later overrides earlier):
1. **Plugin defaults**
2. **Global config** (`~/.config/opencode/dcp.jsonc`)
3. **Project config** (`.opencode/dcp.jsonc`)

### Auto-Generated Configuration

On first run, DCP creates `~/.config/opencode/dcp.jsonc` (or `.opencode/dcp.jsonc`):

```jsonc
{
  // Enable/disable the plugin
  "enabled": true,

  // Enable debug logging
  "debug": false,

  // Model to use for AI analysis (defaults to session model)
  "model": null,

  // Pruning strategies
  "strategies": {
    // Auto-pruning when AI is idle
    "onIdle": {
      "deduplication": true,  // Remove duplicates (free)
      "aiAnalysis": true      // AI semantic analysis (costs tokens)
    },

    // Pruning when AI calls context_pruning tool
    "onTool": {
      "deduplication": true,  // Remove duplicates (free)
      "aiAnalysis": false     // Disabled by default for manual calls
    }
  },

  // Tools that are never pruned
  "protectedTools": [
    "task",           // Sub-agent outputs
    "todowrite",      // Task tracking
    "todoread",       // Task reading
    "context_pruning" // This tool itself
  ],

  // Minimum messages before pruning
  "minMessagesBeforePruning": 10,

  // Maximum age of tool outputs to keep (in messages)
  "maxToolAge": 50
}
```

### Common Configuration Adjustments

#### Aggressive Token Savings (Recommended for Long Sessions)

```jsonc
{
  "enabled": true,
  "strategies": {
    "onIdle": {
      "deduplication": true,
      "aiAnalysis": true  // Enable for best results
    }
  },
  "minMessagesBeforePruning": 5,  // Prune more frequently
  "maxToolAge": 30  // More aggressive culling
}
```

#### Conservative (Preserve More Context)

```jsonc
{
  "enabled": true,
  "strategies": {
    "onIdle": {
      "deduplication": true,
      "aiAnalysis": false  // Only free deduplication
    }
  },
  "minMessagesBeforePruning": 20,  // Wait longer
  "maxToolAge": 100  // Keep more history
}
```

#### Project-Specific Configuration

Create `.opencode/dcp.jsonc` in your project:

```jsonc
{
  "enabled": true,
  "debug": true,  // Enable for this project only
  "protectedTools": [
    "task",
    "todowrite",
    "todoread",
    "context_pruning",
    "read"  // Add custom protected tool
  ]
}
```

### Protected Tools

Add tools you never want pruned:

```jsonc
{
  "protectedTools": [
    "task",
    "todowrite",
    "todoread",
    "context_pruning",
    "grep",         // Keep search results
    "webfetch",     // Keep web content
    "bash"          // Keep command outputs
  ]
}
```

---

## 5. Verifying Installation

### Check 1: Plugin List

```bash
# Start OpenCode
opencode

# List plugins
> What plugins are installed?

# Expected: Should mention @tarquinen/opencode-dcp
```

### Check 2: Configuration File

```bash
# Check global config
cat ~/.config/opencode/dcp.jsonc

# Check project config (if exists)
cat .opencode/dcp.jsonc
```

Expected: Valid JSON with configuration options

### Check 3: Debug Mode Test

Enable debug mode temporarily:

```jsonc
{
  "enabled": true,
  "debug": true  // Enable logging
}
```

Restart OpenCode and look for DCP log messages:
```
[DCP] Plugin initialized
[DCP] Deduplication: found X duplicates
[DCP] AI Analysis: pruned Y tool outputs
```

### Check 4: Manual Pruning Test

```bash
# In OpenCode session
> Use context_pruning tool to optimize current conversation

# Expected: Should show pruning summary
```

---

## 6. Using Context Pruning

### Automatic Operation (Default)

DCP works automatically in the background:

1. **During Idle Time**: Prunes when AI is waiting for input
   - Deduplication runs first (free)
   - AI analysis runs if enabled (costs tokens)

2. **Preserves Recent Context**: Only prunes older tool outputs

3. **Non-Destructive**: Original session files remain intact

**You don't need to do anything** - it just works!

### Manual Triggering

You can manually trigger pruning:

```
Use context_pruning tool to clean up conversation history
```

Or more specifically:

```
Run context pruning with AI analysis to optimize tokens
```

### Monitoring Token Savings

Enable debug mode to see pruning activity:

```jsonc
{
  "debug": true
}
```

Look for messages like:
```
[DCP] Deduplication removed 15 duplicate tool outputs
[DCP] AI Analysis pruned 8 obsolete contexts
[DCP] Token savings: ~4,200 tokens
```

---

## 7. Pruning Strategies Overview

### Strategy 1: Deduplication (Zero Cost)

**How it works**:
- Identifies identical tool calls with same inputs
- Keeps first occurrence, replaces rest with placeholders
- **No LLM cost** - pure algorithm

**Example**:
```
Read file.js (output: 500 tokens)
Read file.js (output: 500 tokens) ← Replaced with placeholder
Read file.js (output: 500 tokens) ← Replaced with placeholder

Savings: 1,000 tokens
```

**Best for**:
- Repeated file reads
- Multiple identical searches
- Duplicate command outputs
- Long conversation sessions

### Strategy 2: AI Analysis (Uses Tokens)

**How it works**:
- Uses LLM to semantically understand context
- Identifies obsolete tool outputs
- Asks AI: "Is this tool output still relevant?"
- Prunes outputs marked as irrelevant

**Example**:
```
Read old-api.js (now deleted)        ← Pruned
Read new-api.js (current version)    ← Kept
Search for "TODO" (now completed)    ← Pruned
Search for "BUG" (still relevant)    ← Kept
```

**Best for**:
- Long development sessions
- Code refactoring workflows
- Iterative problem-solving
- Complex multi-step tasks

**Cost consideration**:
- Uses tokens for analysis
- Saves more tokens than it costs (typically 10:1 ratio)
- Can be disabled if token budget is tight

### Strategy Recommendations

| Use Case | Deduplication | AI Analysis |
|----------|---------------|-------------|
| Short sessions (<20 messages) | ✅ Yes | ❌ No (unnecessary) |
| Medium sessions (20-100 messages) | ✅ Yes | ⚠️ Optional |
| Long sessions (>100 messages) | ✅ Yes | ✅ Yes (recommended) |
| Token budget tight | ✅ Yes | ❌ No |
| Maximum optimization | ✅ Yes | ✅ Yes |

---

## 8. Practical Examples

### Example 1: Iterative File Editing

**Scenario**: Editing the same file multiple times

**Without DCP**:
```
Message 10: Read utils.js (1,200 tokens)
Message 15: Read utils.js (1,200 tokens)
Message 20: Read utils.js (1,200 tokens)
Message 25: Read utils.js (1,200 tokens)

Total: 4,800 tokens in context
```

**With DCP**:
```
Message 10: Read utils.js (1,200 tokens)  ← Kept
Message 15: [Duplicate read, see Message 10]  ← Pruned
Message 20: [Duplicate read, see Message 10]  ← Pruned
Message 25: [Duplicate read, see Message 10]  ← Pruned

Total: 1,200 tokens + small placeholders
Savings: 3,600 tokens (75%)
```

### Example 2: Code Refactoring Session

**Scenario**: Refactoring old code to new patterns

**Without DCP**:
```
All old file reads remain in context
All exploratory searches stay active
All obsolete tool outputs consume tokens

Total: ~15,000 tokens
```

**With DCP** (AI Analysis enabled):
```
Old file reads: Pruned (code replaced)
Exploratory searches: Pruned (decisions made)
Obsolete outputs: Pruned (no longer relevant)
Current context: Preserved

Total: ~6,000 tokens
Savings: 9,000 tokens (60%)
```

### Example 3: Long Debugging Session

**Scenario**: Tracking down complex bug over 150 messages

**Configuration**:
```jsonc
{
  "enabled": true,
  "strategies": {
    "onIdle": {
      "deduplication": true,
      "aiAnalysis": true
    }
  },
  "minMessagesBeforePruning": 10,
  "maxToolAge": 40
}
```

**Results**:
- Automatic pruning every ~15 messages
- Keeps recent debugging context (last 40 messages worth)
- Removes duplicate log reads
- Prunes superseded file versions
- **Estimated savings**: 40-60% tokens over session

---

## 9. Troubleshooting

### Plugin Not Loading

**Problem**: DCP plugin doesn't appear in installed plugins

**Solutions**:
1. Check `opencode.json` syntax
   ```bash
   python3 -m json.tool < opencode.json
   ```

2. Verify plugin name is correct
   ```json
   "@tarquinen/opencode-dcp@0.3.19"  // ✅ Correct
   "@tarquinen/opencode-dcp"         // ⚠️ May get latest (could break)
   "opencode-dcp"                    // ❌ Wrong package name
   ```

3. Clear npm cache and reinstall
   ```bash
   npm cache clean --force
   rm -rf node_modules
   opencode  # Will reinstall plugins
   ```

4. Check npm registry access
   ```bash
   npm info @tarquinen/opencode-dcp
   ```

### Pruning Not Working

**Problem**: No pruning activity observed

**Solutions**:
1. Enable debug mode
   ```jsonc
   {
     "enabled": true,
     "debug": true
   }
   ```

2. Check if pruning threshold reached
   ```jsonc
   {
     "minMessagesBeforePruning": 10  // Needs 10+ messages
   }
   ```

3. Verify plugin is enabled
   ```jsonc
   {
     "enabled": true  // Must be true
   }
   ```

4. Trigger manual pruning
   ```
   Use context_pruning tool
   ```

### Too Aggressive Pruning

**Problem**: Important context being pruned too soon

**Solutions**:
1. Increase `maxToolAge`
   ```jsonc
   {
     "maxToolAge": 100  // Keep more history
   }
   ```

2. Add to protected tools
   ```jsonc
   {
     "protectedTools": [
       "task",
       "todowrite",
       "read",  // Add tool you want to protect
       "grep"
     ]
   }
   ```

3. Disable AI analysis
   ```jsonc
   {
     "strategies": {
       "onIdle": {
         "deduplication": true,
         "aiAnalysis": false  // Only dedupe, no AI pruning
       }
     }
   }
   ```

4. Increase pruning threshold
   ```jsonc
   {
     "minMessagesBeforePruning": 25  // Wait longer before pruning
   }
   ```

### Configuration Not Loading

**Problem**: Changes to config file not taking effect

**Solutions**:
1. Restart OpenCode completely
   ```bash
   # Exit current session
   # Start fresh
   opencode
   ```

2. Check JSON syntax
   ```bash
   cat .opencode/dcp.jsonc | python3 -m json.tool
   ```

3. Verify config file location
   ```bash
   # Global config
   ls -la ~/.config/opencode/dcp.jsonc

   # Project config (takes precedence)
   ls -la .opencode/dcp.jsonc
   ```

4. Remove comments if using JSON parser that doesn't support JSONC
   ```json
   {
     "enabled": true
   }
   ```

### High Token Costs from AI Analysis

**Problem**: AI analysis using too many tokens

**Solutions**:
1. Disable AI analysis, keep deduplication
   ```jsonc
   {
     "strategies": {
       "onIdle": {
         "deduplication": true,
         "aiAnalysis": false  // Disable to save costs
       }
     }
   }
   ```

2. Use cheaper model for analysis
   ```jsonc
   {
     "model": "gpt-3.5-turbo"  // Specify cheaper model
   }
   ```

3. Increase pruning interval
   ```jsonc
   {
     "minMessagesBeforePruning": 30  // Prune less often
   }
   ```

---

## 10. Additional Resources

### Documentation

- **GitHub Repository**: https://github.com/Tarquinen/opencode-dynamic-context-pruning
- **npm Package**: https://www.npmjs.com/package/@tarquinen/opencode-dcp
- **OpenCode Plugins**: https://opencode.ai/plugins

### Configuration Examples

#### Maximum Savings Configuration
```jsonc
{
  "enabled": true,
  "debug": false,
  "strategies": {
    "onIdle": {
      "deduplication": true,
      "aiAnalysis": true
    }
  },
  "minMessagesBeforePruning": 5,
  "maxToolAge": 25,
  "protectedTools": ["task", "todowrite", "todoread", "context_pruning"]
}
```

#### Conservative Configuration
```jsonc
{
  "enabled": true,
  "debug": false,
  "strategies": {
    "onIdle": {
      "deduplication": true,
      "aiAnalysis": false
    }
  },
  "minMessagesBeforePruning": 25,
  "maxToolAge": 100,
  "protectedTools": [
    "task", "todowrite", "todoread", "context_pruning",
    "read", "grep", "webfetch"
  ]
}
```

#### Debugging Configuration
```jsonc
{
  "enabled": true,
  "debug": true,  // Enable detailed logging
  "strategies": {
    "onIdle": {
      "deduplication": true,
      "aiAnalysis": true
    }
  },
  "minMessagesBeforePruning": 5,  // Prune frequently for testing
  "maxToolAge": 20
}
```

### Helper Commands

```bash
# View current configuration
cat ~/.config/opencode/dcp.jsonc

# View project configuration
cat .opencode/dcp.jsonc

# Check plugin version
npm list @tarquinen/opencode-dcp

# Update plugin
npm update @tarquinen/opencode-dcp

# View OpenCode logs
tail -f ~/.opencode/logs/*.log

# Test configuration syntax
python3 -m json.tool < .opencode/dcp.jsonc
```

### Best Practices

1. **Start with defaults** - Let DCP auto-optimize first
2. **Enable debug mode** during initial setup to understand behavior
3. **Use deduplication always** - It's free and effective
4. **Enable AI analysis for long sessions** (>50 messages)
5. **Protect critical tools** - Add to `protectedTools` if needed
6. **Monitor token usage** - Compare sessions with/without DCP
7. **Tune per project** - Different projects may need different settings

### Integration with Other Plugins

DCP works seamlessly with:

- **opencode-skills**: Prunes skill execution history
- **MCP servers**: Optimizes MCP tool call history
- **Custom plugins**: Respects tool protection rules

### Performance Considerations

| Session Length | Deduplication Savings | AI Analysis Savings | Recommendation |
|----------------|----------------------|---------------------|----------------|
| <20 messages | 10-20% | 5-10% | Dedupe only |
| 20-50 messages | 20-40% | 10-20% | Consider AI analysis |
| 50-100 messages | 30-50% | 15-30% | Enable AI analysis |
| >100 messages | 40-60% | 20-40% | Strongly recommend AI |

---

## Quick Reference

### Essential Commands

```bash
# Install
# Add to opencode.json:
{
  "plugin": ["@tarquinen/opencode-dcp@0.3.19"]
}

# Restart OpenCode
opencode

# Manual pruning
> Use context_pruning tool

# Check configuration
cat .opencode/dcp.jsonc
```

### Configuration Quick Edit

```bash
# Edit global config
nano ~/.config/opencode/dcp.jsonc

# Edit project config
nano .opencode/dcp.jsonc

# Validate JSON
python3 -m json.tool < .opencode/dcp.jsonc
```

### Common Configurations

**Aggressive (maximum savings)**:
```jsonc
{"enabled": true, "strategies": {"onIdle": {"deduplication": true, "aiAnalysis": true}}, "minMessagesBeforePruning": 5, "maxToolAge": 25}
```

**Conservative (preserve more)**:
```jsonc
{"enabled": true, "strategies": {"onIdle": {"deduplication": true, "aiAnalysis": false}}, "minMessagesBeforePruning": 25, "maxToolAge": 100}
```

**Debugging**:
```jsonc
{"enabled": true, "debug": true}
```

---

**Installation Complete!** 🎉

You now have Dynamic Context Pruning installed and configured. The plugin will automatically optimize your OpenCode sessions, reducing token usage while preserving important context.

Start a new OpenCode session and watch your token usage decrease as DCP works its magic in the background!
