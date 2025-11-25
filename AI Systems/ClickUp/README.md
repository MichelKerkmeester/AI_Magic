# ClickUp Agent - User Guide v0.200

Creates and manages ClickUp workspaces through natural language using ClickUp MCP server integration with **transparent SYNC processing**.

## 📋 TABLE OF CONTENTS

1. [🆕 WHAT'S NEW IN V0.200](#1-whats-new-in-v0200)
2. [✨ KEY FEATURES](#2-key-features)
3. [🌳 SYSTEM ARCHITECTURE](#3-system-architecture)
4. [🚀 QUICK SETUP](#4-quick-setup)
5. [🔧 INSTALLING CLICKUP MCP](#5-installing-clickup-mcp)
6. [🔌 CONNECTION VERIFICATION](#6-connection-verification)
7. [🧠 HOW IT WORKS](#7-how-it-works)
8. [💬 EXAMPLE INTERACTIONS](#8-example-interactions)
9. [📊 WHAT GETS CREATED](#9-what-gets-created)
10. [📦 VERSION HISTORY](#10-version-history)
11. [📚 RESOURCES](#11-resources)

---

<a id="1-whats-new-in-v0200"></a>

## 1. 🆕 WHAT'S NEW IN V0.200

### Complete System Overhaul
- **SYNC Framework**: Superior 4-phase methodology (Survey → Yield → Navigate → Create) with clearer phase naming
- **Streamlined Processing**: Consolidated validation + integration into final Create phase for efficiency
- **Enhanced Clarity**: More intuitive phase names that better describe actual operations

### Enhanced System Intelligence
- **Intelligent Context Assessment**: Extracts user intent from minimal information and suggests optimal native approaches
- **Native MCP Optimization**: Balance hierarchy vs flat structures automatically based on use case
- **Proactive Guidance**: Suggests improvements beyond immediate request
- **Reality Check**: Verifies MCP capabilities before promising features
- **Clean Interface**: No dividers rule - only bullets and headers for cleaner responses
- **Two-Layer Transparency**: Full cognitive rigor internally, concise progress updates externally
- **Smart Structure Coordination**: Automatic selection of optimal structure strategy (Hierarchy first, Flat, or Hybrid)

### Core Capabilities
- Full ClickUp MCP integration for workspace management
- Complete hierarchy and task operations
- Create folders, lists, and organizational structures
- Build tasks with priorities, assignments, and custom fields
- Manage time tracking, comments, and collaboration features

---

<a id="2-key-features"></a>

## 2. ✨ KEY FEATURES

### Complete Workspace Capabilities

**Hierarchy Operations:**
- Build complete folder and list structures
- Create organizational hierarchies (Space → Folder → List)
- Manage workspace organization
- Configure list settings and defaults
- Update and delete organizational elements

**Task Operations:**
- Create single or bulk tasks efficiently
- Update task properties and assignments
- Manage priorities (1-4: Urgent to Low)
- Configure custom fields at list level
- Search and filter tasks across workspace
- Handle task dependencies and relationships

**Time Tracking:**
- Start/stop timers on specific tasks
- Add manual time entries retroactively
- Track billable hours with descriptions
- Retrieve time logs for tasks and reporting
- Monitor currently running timers
- Generate time-based analytics

**Collaboration:**
- Add comments to tasks
- Attach files via URL or base64
- Manage tags for categorization
- Assign tasks to team members
- Configure team permissions
- Handle workspace-wide communication

**Important**: The system NEVER suggests manual workflows or spreadsheet exports. All operations use native ClickUp MCP exclusively.

### System Features
- **Connection First**: Always verifies MCP connection
- **SYNC Processing**: Transparent 4-phase methodology
- **Interactive Mode**: Single comprehensive questions
- **Clear Feedback**: Visual progress for every operation

---

<a id="3-system-architecture"></a>

## 3. 🌳 SYSTEM ARCHITECTURE

```
AGENTS.md → Entry point with intelligent routing logic
    ↓
Agent - MCP - ClickUp - v0.200.md (System prompt with SYNC integration)
    ↓
SYNC Thinking Framework v0.200 (4-phase methodology with cognitive rigor)
    ↓
Interactive Intelligence v0.200 (Conversation flow with two-layer transparency)
    ↓
MCP Knowledge v0.200 (ClickUp MCP specifications)
    ↓
Output → Native ClickUp operations via MCP server
```

---

<a id="4-quick-setup"></a>

## 4. 🚀 QUICK SETUP

### Step 1: Create a Claude Project
1. Go to claude.ai
2. Click "Projects" in sidebar
3. Create new project named "ClickUp Agent"

### Step 2: Add System Instructions
1. Click "Edit project details"
2. Find "Custom instructions" section
3. Copy and paste: `Agent - MCP - ClickUp - v0.200.md`
4. Save the project

### Step 3: Upload Reference Documents
Add these documents to your project:
- `ClickUp - MCP Knowledge.md` (v0.200)
- `ClickUp - Interactive Intelligence.md` (v0.200)
- `ClickUp - SYNC Thinking Framework.md` (v0.200)

### Step 4: Continue to MCP Installation
Follow the installation guide in the next section

### Step 5: Start Building!
```
Create sprint planning structure with backlog
Build project tracker with custom fields
Design task hierarchy with priorities
Setup time tracking for team velocity
```

---

<a id="5-installing-clickup-mcp"></a>

## 5. 🔧 INSTALLING CLICKUP MCP

### Recommended: NPM with Environment Variable

**Config Location:**
- Mac/Linux: `~/.config/claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "clickup": {
      "command": "npx",
      "args": ["-y", "@taazkareem/clickup-mcp-server"],
      "env": {
        "CLICKUP_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

### Getting Your API Key

1. **Open ClickUp Settings**
   - Click your avatar in ClickUp
   - Select "Settings"
   - Navigate to "Apps" section
   - Click "API" or "Generate API Token"

2. **Generate API Token**
   - Click "Generate" or "Create API Token"
   - Name it (e.g., "Claude MCP")
   - Copy the API key (starts with `pk_`)
   - Store securely (only shown once)

3. **Configure and Restart**
   - Add API key to config file above
   - Restart Claude Desktop (Cmd/Ctrl + R)
   - System verifies connection automatically

### Workspace Permissions

**Required Access:**
- Workspace member or admin access
- Permissions to create folders, lists, and tasks
- Time tracking enabled (if using tracking features)
- Custom fields access (if using advanced features)

**Note**: API key inherits your user permissions. Ensure you have appropriate access levels for intended operations.

---

<a id="6-connection-verification"></a>

## 6. 🔌 CONNECTION VERIFICATION

### Automatic Connection Check

The system automatically verifies MCP connection before operations:

```markdown
🔧 ClickUp Connection Check

✔ MCP Server: Connected
✔ Hierarchy Operations: Ready
✔ Task Operations: Ready
✔ Time Tracking: Ready
✔ Authentication: Valid
```

### Test Query Protocol
- Executes `clickup:get_workspace_hierarchy()` to verify connection
- If successful: Proceeds with operations
- If failed: Provides setup guidance

### Common Connection Issues

**Invalid API Key:**
```markdown
⚠️ Authentication Failed

API key is invalid or expired.

Solution:
1. Go to ClickUp Settings → Apps → API
2. Generate new API token
3. Update claude_desktop_config.json
4. Restart Claude Desktop
```

**Permission Denied:**
```markdown
⚠️ Access Issue

Insufficient permissions for requested operation.

Solution:
1. Verify you're a workspace member or admin
2. Check if space/folder/list is accessible
3. Ensure API key has correct scope
4. Contact workspace admin if needed
```

**Rate Limit Reached:**
```markdown
⚠️ Rate Limit Warning

Approaching ClickUp API rate limits.

Solution:
• Batch operations will be automatically optimized
• Wait briefly between large operations
• System handles rate limiting automatically
```

---

<a id="7-how-it-works"></a>

## 7. 🧠 HOW IT WORKS

### SYNC Processing Framework

The system uses intelligent 4-phase SYNC methodology:

```markdown
📊 SYNC Processing:

S - Survey: Understanding context and requirements
Y - Yield: Converting to optimal native approach
N - Navigate: Executing operations through native MCP
C - Create: Validating quality and delivering results

Internal: Full cognitive rigor (optimized workflow)
External: Concise progress updates only
```

### Native MCP Operations Only

```markdown
✅ CORRECT Approach:

• Uses clickup:create_folder()
• Uses clickup:create_bulk_tasks()
• Uses clickup:start_time_tracking()
• All operations through MCP server

❌ NEVER Does This:

• Suggest manual spreadsheet workflows
• Use external project management tools
• Create non-native automation
• Build operations outside ClickUp
```

### Execution Modes

The system provides intelligent execution:

```markdown
📊 Standard Mode:

• Default for all operations
• Full SYNC processing (4 phases)
• Best for complex tasks
• Shows concise progress updates
```

---

<a id="8-example-interactions"></a>

## 8. 💬 EXAMPLE INTERACTIONS

### Creating a Sprint Structure

**You say:**
```
Create Sprint 15 with user stories and time tracking
```

**Agent does:**
```markdown
🔌 Verifying ClickUp MCP Connection...
✔ Connected

📊 Processing with SYNC methodology...

**Structure Created:**
• Folder: Q1 2025 Sprints
• List: Sprint 15
• Tasks: 20 user stories with priorities
• Time Tracking: Enabled on all tasks
• Tags: Applied for categorization

✅ Complete! Ready for sprint planning.
```

### Building a Project Tracker

**You say:**
```
Setup project tracker with tasks, assignments, and custom fields
```

**Agent does:**
```markdown
🔌 Verifying ClickUp MCP Connection...
✔ Connected

📊 Processing with SYNC methodology...

**Tracker Created:**
• List: Project Tasks
• Custom Fields: Priority, Status, Due Date
• Tasks: 15 project tasks created
• Assignments: Team members assigned
• Organization: Priority-based structure

✅ Complete! Project tracking ready.
```

### Starting Time Tracking

**You say:**
```
Start tracking time on my current task
```

**Agent does:**
```markdown
🔌 Verifying ClickUp MCP Connection...
✔ Connected

📊 Processing with SYNC methodology...

**Time Tracking Started:**
• Task: Implement user authentication
• Timer: Active
• Status: Tracking time
• Description: Development work

✅ Timer running! Stop when done.
```

### Adding Bulk Tasks

**You say:**
```
Add 30 backlog items with priorities to Product Backlog list
```

**Agent does:**
```markdown
🔌 Verifying ClickUp MCP Connection...
✔ Connected

📊 Processing with SYNC methodology...

**Bulk Operation Complete:**
• Tasks Created: 30 backlog items
• Priorities: Assigned (1=Urgent, 2=High, 3=Normal, 4=Low)
• List: Product Backlog
• Method: Bulk operation (efficient)

✅ Backlog populated! Ready for prioritization.
```

---

<a id="9-what-gets-created"></a>

## 9. 📊 WHAT GETS CREATED

### Hierarchy Structures

**Folder Organization:**
```
Space: Engineering
  └─ Folder: Q1 2025 Sprints
      ├─ List: Sprint 15
      ├─ List: Sprint 16
      └─ List: Backlog
```

**List Configuration:**
- Default statuses (open, in progress, review, done)
- Custom field templates
- Task assignment defaults
- Time tracking settings

### Task Properties

**Standard Properties:**
- Name and description
- Priority (1-4 scale)
- Status (list-specific)
- Assignees (team members)
- Due dates and time estimates
- Tags for categorization

**Custom Fields:**
- Story points (number)
- Sprint number (text)
- Component (dropdown)
- Epic link (text)
- Acceptance criteria (text)

**Collaboration:**
- Comments and discussions
- File attachments (URL/base64)
- Watchers and followers
- Activity history

### Time Tracking

**Timer Features:**
- Start/stop on any task
- One active timer per user
- Automatic duration calculation
- Billable flag option

**Manual Entries:**
- Retroactive time logging
- Custom duration formats (2h 30m or 150m)
- Work descriptions
- Tags for categorization

### Output Examples

**Sprint Planning Structure:**
```markdown
✅ Sprint Structure Complete

Hierarchy:
• Folder: Q1 2025 Sprints
• List: Sprint 15 (20 tasks)
• List: Backlog (50 items)

Tasks:
• High Priority: 8 tasks
• Normal Priority: 12 tasks
• Assignees: 5 team members
• Time Tracking: Enabled

Custom Fields:
• Story Points: Configured
• Sprint Number: Set to 15
• Component: Frontend/Backend options
```

**Project Tracker:**
```markdown
✅ Project Tracker Complete

Structure:
• List: Project Tasks
• Tasks: 15 items
• Custom Fields: 5 configured

Organization:
• Status Workflow: 4 stages
• Priority-based ordering
• Team assignments complete
• Due dates configured
```

---

<a id="10-version-history"></a>

## 10. 📦 VERSION HISTORY

### v0.200 (Current)
- Complete system architecture for ClickUp
- SYNC Framework with 4-phase methodology
- Interactive Intelligence with two-layer transparency
- MCP Knowledge for ClickUp specifications
- Native MCP operations exclusively
- Connection verification system
- Hierarchy, task, and time tracking operations
- Bulk operation support
- Collaboration features

### Key Improvements
- Intelligent context assessment
- Automatic structure optimization
- Proactive guidance system
- Clean interface (no dividers)
- Smart structure coordination
- Reality checking before operations

---

<a id="11-resources"></a>

## 11. 📚 RESOURCES

### Official Links
- [ClickUp API Documentation](https://clickup.com/api)
- [ClickUp Help Center](https://help.clickup.com/)
- [ClickUp API Settings](https://app.clickup.com/settings/apps)
- [ClickUp MCP Server](https://github.com/taazkareem/clickup-mcp-server)

### MCP Resources
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Claude Desktop](https://claude.ai/download)
- [MCP Server Documentation](https://modelcontextprotocol.io/docs)