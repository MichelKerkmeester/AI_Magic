# OpenCode Skills Plugin Installation Guide

A comprehensive guide to installing, configuring, and using the OpenCode Skills plugin system.

---

## 🤖 AI-First Install Guide

**Copy and paste this prompt to your AI assistant to get installation help:**

```
I want to set up the OpenCode Skills plugin system in my project.

Please help me:
1. Check if I have the required prerequisites (OpenCode CLI, Git, Node.js)
2. Create the necessary directory structure (.claude/skills, .claude/hooks, .claude/configs)
3. Configure opencode.json to enable skills and hooks
4. Create a basic skill-rules.json configuration file
5. Verify the installation is working correctly

My project is located at: [your project path]

Guide me through each step and show me what commands to run.
```

**What the AI will do:**
- Verify your prerequisites are met
- Create the `.claude/` directory structure
- Set up `opencode.json` with skills and hooks enabled
- Create a starter `skill-rules.json` configuration
- Test that skills are loading correctly
- Provide next steps for adding specific skills

---

## Table of Contents

1. [What Are OpenCode Skills?](#1-what-are-opencode-skills)
2. [Prerequisites](#2-prerequisites)
3. [Installation](#3-installation)
4. [Configuration](#4-configuration)
5. [Verifying Installation](#5-verifying-installation)
6. [Using Skills](#6-using-skills)
7. [Available Skills Overview](#7-available-skills-overview)
8. [Creating Custom Skills](#8-creating-custom-skills)
9. [Troubleshooting](#9-troubleshooting)
10. [Additional Resources](#10-additional-resources)

---

## 1. What Are OpenCode Skills?

OpenCode Skills are specialized AI workflows that extend Claude Code's capabilities for specific domains and tasks. Think of them as plugins that provide:

- **Structured Workflows**: Step-by-step guidance for complex multi-phase tasks
- **Quality Enforcement**: Automatic checks and best practices
- **Tool Integration**: Seamless connection to external services (MCP servers, CLI tools)
- **Context Management**: Smart resource loading and documentation
- **Reusable Patterns**: Proven implementations for common development tasks

### Skill vs Hook vs Knowledge

| Type | Purpose | Execution | Examples |
|------|---------|-----------|----------|
| **Skill** | Multi-step workflow orchestration | AI-invoked when needed | `workflows-code`, `create-documentation` |
| **Hook** | Automated quality checks | System-triggered (before/after operations) | `enforce-spec-folder`, `validate-bash` |
| **Knowledge** | Reference documentation | AI-referenced during responses | Code standards, MCP patterns |

---

## 2. Prerequisites

Before installing the Skills plugin system, ensure you have:

### Required

- **OpenCode CLI** installed and working
  ```bash
  # Verify OpenCode installation
  which opencode
  ```

- **Git repository** initialized in your project
  ```bash
  git init
  ```

- **Node.js** (v16+) for some automation scripts
  ```bash
  node --version
  npm --version
  ```

### Optional but Recommended

- **Python 3.8+** for documentation validation scripts
- **Bash 4.0+** for hook system
- **MCP servers** configured (for MCP integration skills)

---

## 3. Installation

### Option A: Clone Example Skills Structure

The easiest way to get started is to clone an existing Skills structure:

```bash
# Create .claude directory in your project root
mkdir -p .claude

# Create skills directory
mkdir -p .claude/skills

# Create supporting directories
mkdir -p .claude/hooks
mkdir -p .claude/configs
mkdir -p .claude/prompts
```

### Option B: Copy from Reference Repository

If you have access to a reference OpenCode project with Skills:

```bash
# From your reference project
cp -r /path/to/reference/.claude/skills /path/to/your/project/.claude/
cp -r /path/to/reference/.claude/hooks /path/to/your/project/.claude/
cp /path/to/reference/.claude/configs/skill-rules.json /path/to/your/project/.claude/configs/
```

### File Structure

Your project should now have:

```
your-project/
├── .claude/
│   ├── skills/              # Skill definitions
│   │   ├── workflows-code/
│   │   ├── workflows-git/
│   │   ├── create-documentation/
│   │   └── ...
│   ├── hooks/              # Automation hooks
│   │   ├── UserPromptSubmit/
│   │   ├── PreToolUse/
│   │   └── PostToolUse/
│   ├── configs/            # Configuration files
│   │   └── skill-rules.json
│   └── prompts/            # Custom prompts
└── opencode.json           # OpenCode configuration
```

---

## 4. Configuration

### Step 1: Configure opencode.json

Create or update `opencode.json` in your project root:

```json
{
  "version": "1.0.0",
  "skills": {
    "enabled": true,
    "directory": ".claude/skills"
  },
  "hooks": {
    "enabled": true,
    "directory": ".claude/hooks"
  }
}
```

### Step 2: Configure skill-rules.json

This file defines skill activation patterns and priorities. Create `.claude/configs/skill-rules.json`:

```json
{
  "skills": {
    "workflows-code": {
      "type": "workflow",
      "enforcement": "strict",
      "priority": "high",
      "description": "Development workflow orchestration (implementation, debugging, verification)",
      "promptTriggers": {
        "keywords": ["implement", "debug", "fix", "verify", "animation", "async"],
        "intentPatterns": [
          "implement.*feature",
          "fix.*bug",
          "debug.*issue"
        ]
      },
      "fileTriggers": {
        "pathPatterns": ["src/**/*.js", "src/**/*.css"],
        "contentPatterns": ["addEventListener", "async", "fetch"]
      }
    },
    "create-documentation": {
      "type": "documentation",
      "enforcement": "suggest",
      "priority": "medium",
      "description": "Documentation creation and validation",
      "promptTriggers": {
        "keywords": ["document", "readme", "markdown", "docs"],
        "intentPatterns": ["create.*doc", "write.*guide"]
      }
    }
  }
}
```

### Step 3: Install Minimum Required Skills

At minimum, install these core skills:

1. **workflows-conversation** - Mandatory for all file modifications
2. **workflows-code** - Development workflow orchestration
3. **create-documentation** - Documentation creation

Download skill templates from the OpenCode Skills repository or copy from a reference project.

---

## 5. Verifying Installation

### Check 1: Directory Structure

Verify the skills directory exists:

```bash
ls -la .claude/skills/
```

Expected output:
```
workflows-code/
workflows-git/
create-documentation/
...
```

### Check 2: Validate Skill Files

Each skill should have a `SKILL.md` file with proper frontmatter:

```bash
head -20 .claude/skills/workflows-code/SKILL.md
```

Expected output should show YAML frontmatter:
```yaml
---
name: workflows-code
description: Development workflow orchestration
allowed-tools: [Read, Write, Edit, Bash]
version: 2.0.0
---
```

### Check 3: Test Skill Activation

Start an OpenCode session and test skill activation:

```bash
opencode
```

In the chat, type:
```
I need to implement a new feature with async functionality
```

Expected: OpenCode should suggest or activate the `workflows-code` skill.

### Check 4: View Skills README

```bash
cat .claude/skills/README.md
```

This file documents all installed skills and their capabilities.

---

## 6. Using Skills

### Explicit Skill Invocation

You can explicitly request a skill in your prompt:

```
Use the workflows-code skill to implement form validation
```

### Automatic Skill Activation

Skills activate automatically based on:

1. **Keywords** in your prompt
   ```
   "implement authentication" → workflows-code activates
   ```

2. **File patterns** you're working with
   ```
   Working on src/components/Form.js → workflows-code activates
   ```

3. **Intent patterns** detected
   ```
   "debug console error" → workflows-code Phase 2 (Debugging)
   ```

### Skill-Specific Usage

#### workflows-code (Development)

```
I need to implement async form submission with validation
```

This activates Phase 1 (Implementation) with:
- Condition-based waiting patterns
- Defense-in-depth validation
- Performance optimization patterns

#### create-documentation

```
Create documentation for the authentication module
```

This activates documentation workflows with:
- Structure validation
- C7Score quality analysis
- Markdown optimization

#### workflows-git

```
Create a clean commit for this feature
```

This activates git workflows with:
- Conventional commit format
- Clean commit guidance
- PR creation assistance

---

## 7. Available Skills Overview

### Workflow Orchestrators (4 skills)

| Skill | Purpose | Use When |
|-------|---------|----------|
| **workflows-code** | Development lifecycle | Implementing, debugging, verifying frontend code |
| **workflows-git** | Git operations | Commits, PRs, worktrees, branch management |
| **workflows-conversation** | Documentation | ANY file modifications (mandatory) |
| **create-parallel-sub-agents** | Complex tasks | Multi-domain tasks requiring orchestration |

### Documentation Specialists (2 skills)

| Skill | Purpose | Use When |
|-------|---------|----------|
| **create-documentation** | Document creation | Writing/validating markdown, skills, guides |
| **create-flowchart** | Visual workflows | Creating ASCII flowcharts for processes |

### CLI Tool Wrappers (2 skills)

| Skill | Purpose | Use When |
|-------|---------|----------|
| **cli-codex** | OpenAI Codex integration | Alternative AI perspective, code review |
| **cli-gemini** | Google Gemini integration | Web research, current information |

### MCP Integration (2 skills)

| Skill | Purpose | Use When |
|-------|---------|----------|
| **mcp-code-mode** | MCP tool orchestration | Calling ANY MCP tools (mandatory) |
| **mcp-semantic-search** | Intent-based code search | Finding code by what it does |

### Hook Creation (1 skill)

| Skill | Purpose | Use When |
|-------|---------|----------|
| **create-hooks** | Hook development | Creating custom automation workflows |

**Total**: 12 skills across 6 categories

---

## 8. Creating Custom Skills

### Quick Start

```bash
# Option 1: Use create-documentation skill
opencode
> Use create-documentation skill to create a new skill called "my-workflow"

# Option 2: Manual creation
mkdir -p .claude/skills/my-workflow
cd .claude/skills/my-workflow
```

### Create SKILL.md

Every skill needs a `SKILL.md` file with proper frontmatter:

```markdown
---
name: my-workflow
description: Brief one-line description of what this skill does
allowed-tools: [Read, Write, Bash, Grep]
version: 1.0.0
---

# My Workflow - Comprehensive Name

One-sentence tagline explaining the skill.

---

## 1. 🎯 WHEN TO USE

### Primary Use Cases

**Use when**:
- Scenario 1 with context
- Scenario 2 with context

### When NOT to Use

**Do not use for**:
- Anti-pattern with rationale

---

## 2. 🗂️ REFERENCES

### Core Framework & Workflows
| Document | Purpose | Key Insight |
|----------|---------|-------------|
| **My Workflow - Main Process** | Core capability | Key differentiator |

---

## 3. 🛠️ HOW IT WORKS

### Workflow Overview

Process description...

**Process Flow**:
```
STEP 1: Action
   └─ Output
   ↓
STEP 2: Action
   └─ Output
```

---

## 4. 📖 RULES

### ✅ ALWAYS Rules

1. **ALWAYS do X**
   - Why this matters

### ❌ NEVER Rules

1. **NEVER do Y**
   - Why problematic

### ⚠️ ESCALATE IF

1. **ESCALATE IF uncertain about Z**
   - What to ask

---

## 5. 🎓 SUCCESS CRITERIA

### Completion Checklist

**Task complete when**:
- ✅ Criterion 1
- ✅ Criterion 2

---

## 6. 🔗 INTEGRATION POINTS

### Related Skills

**other-skill**: How they integrate
```

### Add to skill-rules.json

Register your skill in `.claude/configs/skill-rules.json`:

```json
{
  "skills": {
    "my-workflow": {
      "type": "workflow",
      "enforcement": "suggest",
      "priority": "medium",
      "description": "My custom workflow for X",
      "promptTriggers": {
        "keywords": ["keyword1", "keyword2"],
        "intentPatterns": ["implement.*X"]
      }
    }
  }
}
```

### Test Your Skill

```bash
opencode
> Use my-workflow skill to do X
```

---

## 9. Troubleshooting

### Skill Not Activating

**Problem**: Skill doesn't activate when expected

**Solutions**:
1. Check `skill-rules.json` for correct keywords/patterns
2. Verify `SKILL.md` frontmatter is valid YAML
3. Ensure skill directory name matches `name` field in frontmatter
4. Check OpenCode logs for errors

```bash
# View logs
tail -f ~/.opencode/logs/opencode.log
```

### Invalid Skill Configuration

**Problem**: Error about invalid skill configuration

**Solutions**:
1. Validate YAML frontmatter syntax
2. Ensure `allowed-tools` uses array format: `[Tool1, Tool2]`
3. Check for typos in skill name (must be kebab-case)
4. Verify description doesn't use angle brackets `<>`

### Skill Files Not Found

**Problem**: OpenCode can't find skill files

**Solutions**:
1. Verify `.claude/skills/` directory exists
2. Check `opencode.json` has correct `skills.directory` path
3. Ensure `SKILL.md` filename is exact (case-sensitive)
4. Check file permissions

```bash
# Fix permissions
chmod -R 755 .claude/skills/
```

### Hook Conflicts

**Problem**: Hooks interfere with skill execution

**Solutions**:
1. Check `.claude/hooks/logs/` for error messages
2. Disable problematic hooks temporarily
3. Review hook execution order in hook directories
4. Validate hook scripts are executable

```bash
# Make hooks executable
chmod +x .claude/hooks/**/*.sh
```

---

## 10. Additional Resources

### Documentation

- **Skills README**: `.claude/skills/README.md` - Complete skills documentation
- **Hooks System**: `.claude/hooks/README.md` - Hook system documentation
- **AGENTS.md**: Project root - AI collaboration guidelines

### Skill Templates

- **SKILL.md Template**: `.claude/skills/create-documentation/assets/skill_md_template.md`
- **Asset Template**: `.claude/skills/create-documentation/assets/skill_asset_template.md`
- **Reference Template**: `.claude/skills/create-documentation/assets/skill_reference_template.md`

### Example Skills

Study these well-documented skills as examples:

- **workflows-code**: `.claude/skills/workflows-code/` - Complex multi-phase orchestrator
- **cli-gemini**: `.claude/skills/cli-gemini/` - Simple CLI wrapper
- **create-documentation**: `.claude/skills/create-documentation/` - Documentation specialist

### Validation Tools

```bash
# Validate skill structure
python3 .claude/skills/create-documentation/scripts/package_skill.py \
  .claude/skills/my-skill

# Validate documentation quality
python3 .claude/skills/create-documentation/scripts/analyze_docs.py \
  .claude/skills/my-skill/SKILL.md
```

### Helper Scripts

```bash
# View skill recommendations log
tail -50 .claude/hooks/logs/skill-recommendations.log

# Check skill activation history
grep "SKILL ACTIVATED" ~/.opencode/logs/opencode.log
```

### Getting Help

1. **OpenCode Docs**: https://opencode.ai/docs
2. **GitHub Issues**: https://github.com/sst/opencode/issues
3. **Skills README**: `.claude/skills/README.md` in your project

---

## Quick Reference

### Essential Commands

```bash
# List installed skills
ls -la .claude/skills/

# View skill documentation
cat .claude/skills/[skill-name]/SKILL.md

# Test skill activation
opencode
> Use [skill-name] to [task]

# Validate skill configuration
python3 scripts/package_skill.py .claude/skills/[skill-name]

# View skill logs
tail -f .claude/hooks/logs/skill-recommendations.log
```

### File Locations

- **Skills**: `.claude/skills/[skill-name]/`
- **Config**: `.claude/configs/skill-rules.json`
- **Hooks**: `.claude/hooks/[HookType]/`
- **Logs**: `.claude/hooks/logs/`
- **OpenCode Config**: `opencode.json`

### Common Patterns

**Explicit Skill Use**:
```
Use workflows-code skill to implement authentication
```

**Check Installed Skills**:
```
What skills are installed?
```

**Create New Skill**:
```
Use create-documentation to create a new skill called "api-client"
```

---

**Installation Complete!** 🎉

You now have the OpenCode Skills plugin system installed and configured. Start using skills by requesting them in your OpenCode sessions or letting them activate automatically based on your work patterns.

For more information, refer to `.claude/skills/README.md` in your project.
