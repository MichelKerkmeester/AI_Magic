# Notion Agent - User Guide v0.200

Creates and manages Notion workspaces through natural language using Notion MCP server integration with **transparent SYNC processing**.

## 📋 TABLE OF CONTENTS

1. [🆕 WHAT'S NEW IN V0.200](#1-whats-new-in-v0200)
2. [✨ KEY FEATURES](#2-key-features)
3. [🌳 SYSTEM ARCHITECTURE](#3-system-architecture)
4. [🚀 QUICK SETUP](#4-quick-setup)
5. [🔧 INSTALLING NOTION MCP](#5-installing-notion-mcp)
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
- **Native MCP Optimization**: Balance database vs page structures automatically based on use case
- **Proactive Guidance**: Suggests improvements beyond immediate request
- **Reality Check**: Verifies MCP capabilities before promising features
- **Clean Interface**: No dividers rule - only bullets and headers for cleaner responses
- **Two-Layer Transparency**: Full cognitive rigor internally, concise progress updates externally
- **Smart Structure Coordination**: Automatic selection of optimal structure strategy (Database first, Pages first, or Hybrid)

### Core Capabilities
- Full Notion MCP integration for workspace management
- Complete database and page operations
- Create databases, properties, and relationships
- Build page hierarchies and content structures
- Manage rich text blocks and all property types

---

<a id="2-key-features"></a>

## 2. ✨ KEY FEATURES

### Complete Workspace Capabilities

**Database Operations:**
- Build complete database structures
- Add any property type (text, select, relation, formula, etc.)
- Create relations between databases
- Configure views (table, board, calendar, etc.)
- Manage database templates

**Page Operations:**
- Build hierarchical page structures
- Create nested content organizations
- Add all block types (paragraph, heading, code, etc.)
- Manage rich text formatting
- Build wiki-style documentation

**Content Management:**
- Full CRUD on database items
- Rich text block operations
- Comments and collaboration
- Workspace-wide search
- Template creation

**Important**: The system NEVER suggests manual workflows or external tools. All operations use native Notion MCP exclusively.

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
Agent - MCP - Notion - v0.200.md (System prompt with SYNC integration)
    ↓
SYNC Thinking Framework v0.200 (4-phase methodology with cognitive rigor)
    ↓
Interactive Intelligence v0.200 (Conversation flow with two-layer transparency)
    ↓
MCP Knowledge v0.200 (Notion MCP specifications)
    ↓
Output → Native Notion operations via MCP server
```

---

<a id="4-quick-setup"></a>

## 4. 🚀 QUICK SETUP

### Step 1: Create a Claude Project
1. Go to claude.ai
2. Click "Projects" in sidebar
3. Create new project named "Notion Agent"

### Step 2: Add System Instructions
1. Click "Edit project details"
2. Find "Custom instructions" section
3. Copy and paste: `Agent - MCP - Notion - v0.200.md`
4. Save the project

### Step 3: Upload Reference Documents
Add these documents to your project:
- `Notion - MCP Knowledge.md` (v0.200)
- `Notion - Interactive Intelligence.md` (v0.200)
- `Notion - SYNC Thinking Framework.md` (v0.200)

### Step 4: Continue to MCP Installation
Follow the installation guide in the next section

### Step 5: Start Building!
```
Create knowledge base with articles database
Build wiki hierarchy with nested pages
Design project tracker with custom properties
Setup content calendar with relations
```

---

<a id="5-installing-notion-mcp"></a>

## 5. 🔧 INSTALLING NOTION MCP

### Recommended: NPM with Environment Variable

**Config Location:**
- Mac/Linux: `~/.config/claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "notion": {
      "command": "npx",
      "args": ["-y", "@makenotion/notion-mcp-server"],
      "env": {
        "NOTION_TOKEN": "your-integration-token-here"
      }
    }
  }
}
```

### Getting Your Integration Token

1. **Create Internal Integration**
   - Go to [Notion Integrations](https://www.notion.so/profile/integrations)
   - Click "New integration"
   - Name it (e.g., "Claude MCP")
   - Select workspace
   - Copy the "Internal Integration Token" (starts with `ntn_`)

2. **Share Pages/Databases**
   - Open any page or database you want to access
   - Click "Share" in top right
   - Invite your integration
   - Repeat for all pages/databases you want to manage

3. **Configure and Restart**
   - Add token to config file above
   - Restart Claude Desktop (Cmd/Ctrl + R)
   - System verifies connection automatically

### Alternative: Docker Deployment
```bash
docker run -e NOTION_TOKEN=your-token-here makenotion/notion-mcp-server
```

---

<a id="6-connection-verification"></a>

## 6. 🔌 CONNECTION VERIFICATION

### Automatic Connection Check

The system automatically verifies MCP connection before operations:

```markdown
🔧 Notion Connection Check

✔ MCP Server: Connected
✔ Database Access: Ready
✔ Page Access: Ready
✔ Authentication: Valid
```

### Test Query Protocol
- Executes `notion:API_get_self()` to verify connection
- If successful: Proceeds with operations
- If failed: Provides setup guidance

### Common Connection Issues

**Integration Not Shared:**
```markdown
⚠️ Access Issue

Pages/databases must be shared with your integration.

Solution:
1. Open page/database in Notion
2. Click "Share" button
3. Invite your integration
4. Try operation again
```

**Invalid Token:**
```markdown
⚠️ Authentication Failed

Integration token is invalid or expired.

Solution:
1. Go to notion.so/profile/integrations
2. Regenerate token
3. Update claude_desktop_config.json
4. Restart Claude Desktop
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

• Uses notion:API_create_a_database()
• Uses notion:API_post_page()
• Uses notion:API_patch_block_children()
• All operations through MCP server

❌ NEVER Does This:

• Suggest manual data entry
• Use external spreadsheets
• Create non-native workflows
• Build operations outside Notion
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

### Creating a Knowledge Base
```
User: Create a knowledge base

System: 
🔧 Notion Connection Check

✔ MCP Server: Connected
✔ Database Access: Ready

I'll create a complete knowledge base for you!

📊 SYNC Processing:

S - Survey: Knowledge base with flexible organization
Y - Yield: Database + hierarchical pages structure
N - Navigate: Database → Pages → Content blocks
C - Create: Validating structure and delivering...

🔧 Notion Operation

Operation: Knowledge base creation

📂 Processing:
├── Creating database ✔
├── Adding properties ✔
├── Building page hierarchy ✔
└── Configuring views ✔

✅ Operation Complete!

📊 Results:
├── Databases: 1 created
├── Properties: 8 added
├── Pages: 5 built
└── Views: 3 configured

💡 Relations connect your articles to categories!
```

### Building a Wiki Structure
```
User: Build a documentation wiki

System:
🔧 Notion Connection Check

✔ MCP Server: Connected
✔ Page Access: Ready

Creating wiki structure with nested pages!

📊 SYNC Processing:

S - Survey: Documentation wiki with hierarchy
Y - Yield: Nested page structure optimal
N - Navigate: Parent pages → Child pages → Content
C - Create: Building navigation and delivering...

🔧 Notion Operation

Operation: Wiki hierarchy creation

📂 Processing:
├── Creating parent pages ✔
├── Building nested structure ✔
├── Adding content blocks ✔
└── Linking pages ✔

✅ Operation Complete!

📊 Results:
├── Pages: 12 created
├── Hierarchy levels: 3
├── Content blocks: 48 added
└── Internal links: 15 configured

💡 Toggle blocks make your wiki collapsible!
```

---

<a id="9-what-gets-created"></a>

## 9. 📊 WHAT GETS CREATED

### Full Stack Example - Knowledge Base System

```javascript
// Data Structure (Created via Notion MCP)
Database: {
  Articles: {
    properties: {
      Title: 'title',
      Content: 'rich_text',
      Category: 'select',
      Tags: 'multi_select',
      Author: 'people',
      Published: 'date',
      Status: 'select',
      RelatedArticles: 'relation'
    },
    views: ['Table', 'Gallery', 'Calendar']
  }
}

// Page Hierarchy (Created via Notion MCP)
Pages: {
  KnowledgeBaseHome: {
    children: [
      'GettingStarted',
      'Tutorials',
      'Reference',
      'FAQ'
    ],
    blocks: ['heading', 'paragraph', 'callout', 'divider']
  }
}

// Content Blocks (Created via Notion MCP)
Blocks: {
  RichText: 'Formatted text with annotations',
  Code: 'Syntax-highlighted code blocks',
  Callouts: 'Important notes and warnings',
  Tables: 'Structured data display',
  Lists: 'Bulleted and numbered lists',
  Toggles: 'Collapsible sections'
}
```

### Property Types Available

**Text Properties:**
- Title (required for all pages/databases)
- Rich Text (multi-line formatted)
- Email, Phone, URL

**Numeric:**
- Number (with formatting options)
- Formula (calculated values)

**Selection:**
- Select (single choice)
- Multi-select (multiple choices)
- Checkbox (boolean)

**Relationships:**
- Relation (links to other databases)
- Rollup (aggregate related data)
- People (workspace users)

**DateTime:**
- Date (with optional time and ranges)

**Media:**
- Files & Media (external URLs only)

---

<a id="10-version-history"></a>

## 10. 📦 VERSION HISTORY

### v0.200 (Current)
- **Complete System Rebuild**: Aligned with Webflow architecture for consistency
- **SYNC Framework**: Transitioned to 4-phase methodology (Survey, Yield, Navigate, Create)
- **Better Phase Naming**: More intuitive than previous frameworks
- **Streamlined Processing**: Combined validation + integration into final Create phase
- **Updated Knowledge Base**: All documents aligned with SYNC methodology
- **Enhanced Intelligence**: Improved context assessment and solution finding
- **Two-Layer Transparency**: Full cognitive rigor internally, concise updates externally
- **Interactive Intelligence**: New comprehensive conversation flow architecture
- **MCP Knowledge**: Complete Notion MCP server specifications documented
- **Native Operations Only**: 100% Notion MCP, zero manual processes
- **Smart Structure Coordination**: Automatic database vs page vs hybrid selection

### v0.100 (Previous)
- Initial Notion MCP integration
- Basic database and page operations
- Simple command structure
- Combined with ClickUp operations

---

<a id="11-resources"></a>

## 11. 📚 RESOURCES

### Essential Links
- [Notion MCP Server](https://github.com/makenotion/notion-mcp-server)
- [Notion API Docs](https://developers.notion.com/)
- [Create Integration](https://www.notion.so/profile/integrations)
- [MCP Protocol](https://modelcontextprotocol.io/)

### Quick References
- [Notion API Reference](https://developers.notion.com/reference)
- [Property Types](https://developers.notion.com/reference/property-object)
- [Block Types](https://developers.notion.com/reference/block)
- [Claude Desktop](https://claude.ai/download)