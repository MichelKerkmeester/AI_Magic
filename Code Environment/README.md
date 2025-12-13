# OpenCode Dev Environment

Local command center for your OpenCode setup: SpecKit documentation workflow, semantic memory system, skills, and commands, all wired for AI-assisted coding.

## 📋 TABLE OF CONTENTS

1. [🌐 Overview](#1-overview)
2. [🚀 Quick Setup](#2-quick-setup)
3. [🧩 MCP & Core Config](#3-mcp-core-config)
4. [🗂️ SpecKit – Your Doc Framework](#4-speckit-your-doc-framework)
5. [🧠 Memory System – Semantic Context](#5-memory-system-semantic-context)
6. [🎛️ Skills & Commands](#6-skills-commands)
7. [🔄 Example Workflows](#7-example-workflows)

---

<a id="1-overview"></a>
## 1. 🌐 Overview

This folder holds the **reusable environment** that powers your AI systems:

- **SpecKit** – your spec-driven documentation framework with templates, scripts, and enforcement rules
- **Memory system** – semantic memory with six-tier importance and hybrid search
- **Skills** – curated workflows for SpecKit, memory, code, Git, Chrome DevTools, and CLI tools
- **Commands** – ready-to-use command specs for SpecKit, memory, search, and CLI

Use this folder as the **source of truth** when wiring up new projects, adjusting your OpenCode config, or explaining your setup to another developer.

---

<a id="2-quick-setup"></a>
## 2. 🚀 Quick Setup

### 2.1 OpenCode + Root Config

- OpenCode looks for `opencode.json` at the repo root:
  - Root file (one level up) enables `opencode-skills`, sets `ctrl+x` as the leader key, and registers your MCP servers.
  - This folder also includes its own `opencode.json` and `mcp.json` you can reuse in other projects.

### 2.2 Minimal Steps

1. Open this repo in OpenCode (or link it as a workspace).
2. Ensure the MCP servers referenced in `opencode.json` / `mcp.json` exist and paths are correct.
3. Add any required API keys to your `.env` (used via `utcp_config.json`), e.g. for semantic search or Figma/Webflow.
4. Start using the commands from `command/*` (`/spec_kit:*`, `/memory:*`, `/cli:*`, `/search:*`) instead of ad‑hoc instructions.

---

<a id="3-mcp-core-config"></a>
## 3. 🧩 MCP & Core Config

### 3.1 `opencode.json` (root + template)

Your `opencode.json` files (repo root and here) define:

- **Plugin**:
  - `opencode-skills` – exposes the skills in `Code Environment/skills`
- **MCP servers**:
  - `code_mode` – Node-based code editing/inspection server configured with a shared UTCP file
  - `sequential_thinking` – MCP server for multi-step reasoning and decomposition
  - `semantic_memory` – Node-based memory server storing vectors in `.opencode/memory/database/memory-index.sqlite`
  - Optional `semantic_search` (in this folder’s `opencode.json` / `mcp.json`) – VoyageAI-compatible codebase search (keys required)

Use this folder’s `opencode.json` and `mcp.json` as **templates** when bootstrapping new codebases.

### 3.2 `utcp_config.json`

Defines how tools are orchestrated and where environment variables come from:

- Loads variables from `.env` (via `dotenv`).
- Registers **manual call templates** for:
  - `chrome_devtools_*` – `npx chrome-devtools-mcp@latest --isolated=true`
  - `figma` – `mcp-figma` with `FIGMA_PERSONAL_ACCESS_TOKEN` from `.env`
  - `webflow` – `mcp-remote https://mcp.webflow.com/sse`

Think of this file as the **bridge** between your local environment and MCP servers.

---

<a id="4-speckit-your-doc-framework"></a>
## 4. 🗂️ SpecKit – Your Doc Framework

My custom fork of the original GitHub SpecKit framework – expanded, more manageable, and fully automated through `/spec_kit:*` commands. It lives in `speckit/` and is documented in detail in `speckit/README.md`.

### 4.1 What SpecKit Provides

- **Templates** (9 total, in `speckit/templates/`):
  - `spec.md`, `plan.md`, `tasks.md` – Level 1 baseline documentation
  - `checklist.md` – QA validation (Level 2+)
  - `decision-record.md` – architectural decisions (Level 3)
  - `research.md`, `research-spike.md` – deep dives and spikes
  - `handover.md`, `debug-delegation.md` – utility templates for multi-session work and debugging
- **Scripts** (in `speckit/scripts/`):
  - `create-documentation.sh` – create feature branch + spec folder and copy templates
  - `check-prerequisites.sh` – ensure spec folder structure is valid
  - `calculate-completeness.sh` – score how complete the spec folder is
  - `recommend-level.sh` – suggest documentation level (1–3)
  - `archive-spec.sh` – archive completed specs
  - `common.sh` – shared helpers
- **Checklists & Evidence**:
  - Checklists in `speckit/checklists/` and evidence stubs in `speckit/checklist-evidence/`

### 4.2 Documentation Levels (1–3)

- **Level 1 – Baseline**: `spec + plan + tasks`
- **Level 2 – Verified**: Level 1 + `checklist`
- **Level 3 – Full**: Level 2 + `decision-record` (+ optional `research` / `research-spike`)

Your AGENTS rules and skills (`workflows-spec-kit`) treat these levels as a **progressive enhancement** model:

- Small changes → Level 1
- Medium features / QA-heavy work → Level 2
- Complex / architectural work → Level 3 or higher

### 4.3 SpecKit Commands

Commands under `command/spec_kit/` wrap the SpecKit workflow:

- `/spec_kit:complete [feature] [:auto|:confirm]` – 12-step full workflow (spec → plan → implement) with gates (input, spec folder, memory load, execution mode, etc.).
- `/spec_kit:plan [feature]` – planning-focused path.
- `/spec_kit:implement` – implementation when spec+plan already exist.
- `/spec_kit:research [topic]` – research-first path.

Use these instead of ad‑hoc “write me a spec” prompts; they enforce your **mandatory spec-folder discipline**.

---

<a id="5-memory-system-semantic-context"></a>
## 5. 🧠 Memory System – Semantic Context

The memory system combines **structured file-based notes** with **semantic search**.

### 5.1 Where It Lives

- Core files in this folder’s `memory/` directory:
  - `config.jsonc`, `filters.jsonc`, `templates/`, `scripts/`, `assets/`, and documentation (e.g. `memory/README.md`, `mcp_server.md`, `mcp_install_guide.md`)
- Semantic index:
  - `.opencode/memory/database/memory-index.sqlite` (created when the MCP server runs)

### 5.2 Workflows Memory Skill

Defined in `skills/workflows-memory/SKILL.md`:

- Six-tier importance system:
  - `constitutional`, `critical`, `important`, `normal`, `temporary`, `deprecated`
- Hybrid search:
  - SQLite FTS5 + vector search
- Smart features:
  - 90-day half-life decay for recency boosting
  - Checkpoint save/restore for context safety
  - Confidence-based promotion (e.g. promote to constitutional at high confidence)
  - Auto-triggers on keywords or every N messages

It writes detailed context files to:

- `specs/###-feature/memory/{timestamp}__topic.md`

### 5.3 Memory Commands

Command specs under `command/memory/` define how you interact with the system:

- `/memory/save [spec-folder]` – save the current conversation to the right spec folder with semantic indexing and smart folder detection.
- `/memory/status` – health dashboard via `memory_stats` (counts by tier/status, DB size, last writes).
- `/memory/search "query"` – semantic search across memories (with options like `recent`, `rebuild`, `verify`, `retry`, `resume`).
- `/memory/cleanup` – interactive pruning of old/unused memories.
- `/memory/checkpoint`, `/memory/triggers` – advanced configuration and checkpoint flows.

These commands ensure you **never lose important context**, even across long or multi-session work.

---

<a id="6-skills-commands"></a>
## 6. 🎛️ Skills & Commands

### 6.1 Skills (`skills/`)

**Skills** are reusable capabilities / knowledge items:

- `workflows-spec-kit` – spec folder + template enforcement
- `workflows-memory` – semantic context preservation and search
- `workflows-code` – code-level operations
- `workflows-git` – Git helpers
- `workflows-chrome-devtools` – browser automation via Chrome DevTools MCP
- `mcp-code-mode` – `code_mode` MCP server integration
- `mcp-semantic-search` – codebase semantic search
- `cli-codex`, `cli-gemini` – CLI tool integrations
- `create-documentation` – spec folder generation

Each skill has its own `SKILL.md` with:

- When to use it
- How it routes work
- Which MCP tools or scripts it depends on

### 6.2 Commands (`command/`)

**Commands** are entry points that invoke skills:

- `spec_kit/` – `/spec_kit:complete`, `/spec_kit:plan`, `/spec_kit:implement`, `/spec_kit:research`
- `memory/` – `/memory:save`, `/memory:status`, `/memory:search`, `/memory:cleanup`
- `search/` – codebase and semantic search triggers
- `cli/` – `/cli:codex`, `/cli:gemini` and variants
- `prompt/` – prompt refinement helpers

Use these commands inside OpenCode or your chat interface to **stay within your own guardrails** instead of improvising each time.

---

<a id="7-example-workflows"></a>
## 7. 🔄 Example Workflows

### 7.1 New Feature with Full Documentation

1. Run `/spec_kit:complete Add OAuth login :confirm`.
2. Choose or create a spec folder when asked.
3. Let SpecKit copy the right templates and create the spec/plan/tasks.
4. Use `/memory/save` at key milestones to preserve decisions.
5. When done, archive the spec with `archive-spec.sh` if appropriate.

### 7.2 Quick Change with Baseline Docs + Memory

1. Run `/spec_kit:plan Fix password reset email`.
2. Keep documentation at Level 1 (spec + plan + tasks).
3. Use `/memory/save` once when you complete the fix.

### 7.3 Parallel AI Support with Codex/Gemini

1. Use `/cli:codex` or `/cli:gemini` from `command/cli/` to get a second AI perspective on a code problem.
2. Keep the main conversation and memory/workflows inside your OpenCode agent.
3. Save the outcome back into the relevant spec folder with `/memory/save`.

---

This folder is the **reference point** for your OpenCode setup.  
When in doubt, start here, then drill into `speckit/`, `memory/`, `skills/`, or `command/` as needed.