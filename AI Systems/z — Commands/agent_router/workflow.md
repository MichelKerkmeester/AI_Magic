---
description: Execute AGENTS.md-compliant workflows - Supports :auto and :confirm modes
argument-hint: "<request> [:auto|:confirm]"
allowed-tools: Read, Write, Edit, Glob, Grep, Task, AskUserQuestion
---

# 🚨 MANDATORY FIRST ACTION - DO NOT SKIP

**BEFORE READING ANYTHING ELSE IN THIS FILE, CHECK `$ARGUMENTS`:**

```
IF $ARGUMENTS is empty, undefined, or contains only whitespace (ignoring mode flags):
    → STOP IMMEDIATELY
    → Use AskUserQuestion tool with this exact question:
        question: "What request would you like to route?"
        options:
          - label: "Describe my request"
            description: "I'll provide a request to process through AGENTS.md routing"
    → WAIT for user response
    → Use their response as the request
    → Only THEN continue with this workflow

IF $ARGUMENTS contains a request:
    → Continue reading this file
```

**CRITICAL RULES:**
- **DO NOT** infer requests from context, screenshots, or conversation history
- **DO NOT** assume what the user wants based on open files or recent activity
- **DO NOT** proceed past this point without an explicit request from the user
- The request MUST come from `$ARGUMENTS` or user's answer to the question above

---

# Agent Router

Execute AGENTS.md-compliant workflows with automatic compliance enforcement and intelligent routing.

---

## Purpose

Enable users to execute AGENTS.md-compliant workflows through an automated slash command that transforms free-form requests into structured inputs, handles interactive mode selection, and enforces routing compliance. The command locates and reads AGENTS.md, follows internal routing to Knowledge Base documents, and processes requests according to agent-specific guidelines.

---

## Contract

**Inputs:** `$ARGUMENTS` — Request with optional parameters (path, context, scope)
**Outputs:** Executed request per AGENTS.md + `STATUS=<OK|FAIL|CANCELLED>`

## User Input

```text
$ARGUMENTS
```

---

## Instructions

### Phase 1: Mode Detection & Input Parsing

#### Step 1.1: Parse Mode Suffix

Detect execution mode from command invocation:

| Pattern                           | Mode        | Behavior                                 |
| --------------------------------- | ----------- | ---------------------------------------- |
| `/agent_router:workflow:auto`        | AUTONOMOUS  | Execute all steps without approval gates |
| `/agent_router:workflow:confirm`     | INTERACTIVE | Pause at each step for user approval     |
| `/agent_router:workflow` (no suffix) | PROMPT      | Ask user to choose mode                  |

#### Step 1.2: Mode Selection (when no suffix detected)

If no `:auto` or `:confirm` suffix is present, use AskUserQuestion:

**Question**: "How would you like to execute this workflow?"

| Option | Mode        | Description                                                                                    |
| ------ | ----------- | ---------------------------------------------------------------------------------------------- |
| **A**  | Autonomous  | Execute all steps without approval gates. Best for straightforward tasks with clear AGENTS.md. |
| **B**  | Interactive | Pause at each step for approval. Best for complex tasks or unfamiliar agents.                  |

**Wait for user response before proceeding.**

#### Step 1.3: Transform Raw Input

Parse the raw text from `$ARGUMENTS` and transform into structured user_inputs fields.

**Field Extraction Rules**:

| Field             | Pattern Detection                                            | Default If Empty                                           |
| ----------------- | ------------------------------------------------------------ | ---------------------------------------------------------- |
| `agents_location` | "path:", "agent:", explicit paths (starting with `.` or `/`) | Search order: ./AGENTS.md → ../AGENTS.md → ../../AGENTS.md |
| `context`         | "context:", "using:", "with:", "constraints:"                | Infer from request and AGENTS.md routing                   |
| `request`         | Primary task description (REQUIRED)                          | ERROR if completely empty                                  |
| `analysis_scope`  | "scope:", "files:", "reference:", file paths/globs           | AGENTS.md and Knowledge Base only                          |

**Transformation Process**:

1. **Extract explicit fields**: Scan for labeled patterns
2. **Infer implicit fields**: Extract context clues from natural language
3. **Apply defaults**: Fill remaining fields with intelligent defaults
4. **Validate required**: Ensure `request` field has substantive content

**Example Transformation**:

Raw input:
```
Create a ticket for the authentication bug. path: ./work/support-agent
Use the ticket template. files: src/auth/**
```

Transformed:
```yaml
user_inputs:
  agents_location: "./work/support-agent"
  context: "Use the ticket template"
  request: "Create a ticket for the authentication bug"
  analysis_scope: "src/auth/**"
```

#### Step 1.4: Load & Execute Workflow Prompt

Based on detected/selected mode:

- **AUTONOMOUS**: Load and execute `.opencode/command/agent_router/assets/route_auto.yaml`
- **INTERACTIVE**: Load and execute `.opencode/command/agent_router/assets/route_confirm.yaml`

### Phase 2: Workflow Execution

Execute the 7-step workflow defined in the YAML prompt. See YAML files for detailed step-by-step instructions.

---

## Workflow Overview (7 Steps)

| Step | Name                   | Purpose                                                        |
| ---- | ---------------------- | -------------------------------------------------------------- |
| 1    | Locate AGENTS.md       | Find and resolve AGENTS.md file using search order             |
| 2    | Read & Route           | Read AGENTS.md completely and follow routing to Knowledge Base |
| 3    | Acknowledge Compliance | Confirm AGENTS.md compliance in response                       |
| 4    | Parse Context          | Extract environment, state, constraints                        |
| 5    | Process Analysis Scope | Load reference materials if provided                           |
| 6    | Execute Request        | Process request per AGENTS.md + Knowledge Base guidelines      |
| 7    | Context Persistence    | Save execution context for future sessions                     |

---

## Failure Recovery

| Failure Type                | Recovery Action                                 |
| --------------------------- | ----------------------------------------------- |
| AGENTS.md not found         | STOP with clear error message and path guidance |
| Request empty               | Prompt user: "Please describe the task or goal" |
| Routing fails               | Continue with AGENTS.md only, log warning       |
| Knowledge Base docs missing | Continue with available documents               |

---

## Error Handling

| Condition               | Action                                           |
| ----------------------- | ------------------------------------------------ |
| Empty `$ARGUMENTS`      | Prompt: "Please describe the request to process" |
| Invalid AGENTS_LOCATION | Log warning, fallback to default search          |
| Context inference fails | Use AGENTS.md routing only                       |

---

## Completion Report

After workflow completion, report:

```
✅ Agent Router Workflow Finished

Mode: [AUTONOMOUS/INTERACTIVE]
AGENTS.md: [path]
Request: [summary]

Routing:
- Knowledge Base documents: [list]
- Output location: [export folder or workspace]

Next Steps:
- Review output
- Run subsequent commands as needed

STATUS=OK
```

---

## Examples

**Example 1: Simple Request (autonomous)**
```
/agent_router:workflow:auto Create a technical specification for the new API
```

**Example 2: With Explicit Path (interactive)**
```
/agent_router:workflow:confirm "Generate user documentation" path: ./agents/docs-writer
```

**Example 3: With Context**
```
/agent_router:workflow "Research and document the caching strategy" context: using Redis, following project standards
```

**Example 4: With Analysis Scope**
```
/agent_router:workflow:auto "Create support ticket" scope: ./templates/ticket.md files: src/auth/**
```

---

## Notes

- **Mode Behaviors:**
  - **Autonomous (`:auto`)**: Executes all steps without approval gates. Self-validates. Makes informed decisions.
  - **Interactive (`:confirm`)**: Pauses after each step. Presents options: Approve, Review Details, Modify, Abort.

- **Integration:**
  - Works with AGENTS.md-governed agent systems
  - Respects agent scope boundaries (folder-based isolation)
  - Integrates with export folders and spec folder systems
  - Supports context persistence via memory files

- **Identity & Scope:**
  - Agent identity is locked to the resolved AGENTS.md for the conversation
  - File operations restricted to agent folder and subfolders
  - Cannot switch agents mid-conversation without explicit restart