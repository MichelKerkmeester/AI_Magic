# Notion - MCP Knowledge

Technical reference for Notion MCP server capabilities and integration for workspace, database, and content management operations.

**Purpose:** Document Notion-specific features, supported operations, API specifications, and technical constraints. Conversation flows and thinking methodology are in Interactive Intelligence and SYNC Thinking Framework respectively.

---

## 📋 TABLE OF CONTENTS

1. [🔌 SERVER OVERVIEW](#1-server-overview)
2. [🛠️ CORE CAPABILITIES](#2-core-capabilities)
3. [📊 FORMAT SUPPORT](#3-format-support)
4. [🗄️ DATABASE & PAGE OPERATIONS](#4-database-page-operations)
5. [🔍 SEARCH & COLLABORATION](#5-search-collaboration)
6. [⚠️ LIMITATIONS](#6-limitations)
7. [🏎️ QUICK REFERENCE](#7-quick-reference)

---

<a id="1-server-overview"></a>

## 1. 🔌 SERVER OVERVIEW

### MCP Server Details

The Notion MCP Server (`@makenotion/notion-mcp-server`) provides native integration with Notion's API v1 for workspace, database, and content management operations.

**Key Information:**
- **Repository:** https://github.com/makenotion/notion-mcp-server
- **NPM Package:** `@makenotion/notion-mcp-server`
- **Authentication:** Integration token (Bearer ntn_****)
- **Setup:** https://www.notion.so/profile/integrations
- **Node:** Latest LTS required

**Deployment:** NPM with NOTION_TOKEN environment variable (recommended) or Docker containerized deployment.

### System Architecture

**Operation Sequence:**
1. **Connection Check** (ALWAYS FIRST) - Verify MCP server is active
2. **User Request** - Receive and parse user intent
3. **Intent Recognition** - Determine operation type needed
4. **Operation Selection** - Choose between Database/Page/Search operations
5. **API Call** - Execute using official Notion API tools
6. **Feedback & Confirmation** - Return results to user

**API Routing:**
- **Workspace Operations:** Requires integration token with proper workspace access
- **Content Operations:** Requires explicit page/database sharing with the integration

### Connection Verification

Connection verification must be the **first action before all operations** (ALWAYS FIRST). Use the `API_get_self` tool to test connectivity and authentication.

**Status Messages:**
- ✅ **Connected:** "Notion MCP Connected - All APIs available"
- ❌ **Disconnected:** "Notion MCP Not Connected - Setup required"
- ⚠️ **Auth Failed:** "Authentication Issue - Token invalid or expired"
- ⚠️ **Not Shared:** "Access Issue - Content not shared with integration"

**Connection Protocol:**
1. Check MCP server status
2. Run test query (`API_get_self`)
3. Verify integration token authentication
4. Check workspace access and content sharing
5. Proceed with operations only if all checks pass

**Connection States & Actions:**
- **Connected:** All systems operational → Proceed with operations
- **Disconnected:** No MCP access → Restart Claude Desktop / Check config
- **Auth Failed:** Token issue → Regenerate integration token
- **Not Shared:** Content not accessible → Share page/database with integration in Notion

---

<a id="2-core-capabilities"></a>

## 2. 🛠️ CORE CAPABILITIES

### Available Operations

**Note:** Thinking methodology and conversation flows are defined in Notion - SYNC Thinking Framework and Notion - Interactive Intelligence.

```yaml
workspace_operations:
  user_management:
    tools: [API_get_user, API_get_users, API_get_self]
    requires: "Integration token"
  
  search_operations:
    tools: [API_post_search]
    requires: "Integration token"
  
  database_system:
    tools: [API_create_a_database, API_post_database_query]
    requires: "Integration token"

page_operations:
  page_management:
    tools: [API_post_page, API_patch_page, API_retrieve_a_page]
    requires: "Page sharing"
  
  content_operations:
    tools: [API_get_block_children, API_patch_block_children]
    requires: "Page sharing"
  
  collaboration:
    tools: [API_create_a_comment]
    requires: "Page sharing"
```

### What You CAN Do ✅

**Workspace and Content Operations:**
- Create databases with any property types
- Build page hierarchies programmatically
- Manage content with rich text blocks
- Search across entire workspace
- Handle comments and collaboration
- Query databases with complex filters

**Content Management:**
- Create pages with nested structures
- Add all block types (paragraph, heading, list, code, etc.)
- Manage database properties and relations
- Handle relationships between databases
- Organize hierarchical content
- Execute complex queries with filters and sorts

### What You CANNOT Do ❌

**Permission Restrictions:**
- Cannot access content not shared with the integration
- Cannot access private pages without explicit permission
- Cannot access other workspaces or archived content
- All restrictions enforced at API-level

**Media Upload Limitation:**
- Direct file upload is not supported by Notion API
- **Workaround:** Use external URLs for images and files
- Recommended services: Cloudinary, Amazon S3, Imgur

**Other Restrictions:**
- Cannot work without MCP connection verification
- Integration must be created and pages/databases shared
- Rate limits: 3 requests per second (Notion API limit)
- Cannot access other workspaces or modify locked properties

---

<a id="3-format-support"></a>

## 3. 📊 FORMAT SUPPORT

### Property Types

```yaml
property_types:
  text:
    - title: "Page/database title (required)"
    - rich_text: "Multi-line formatted text"
    - email: "Email address validation"
    - phone_number: "Phone number field"
    - url: "Web link validation"
  
  numeric:
    - number: "Numeric values with formatting (price, quantity, rating)"
    - formula: "Calculated values from other properties"
  
  date_time:
    - date: "Date and optional time values with ranges"
  
  selection:
    - select: "Single choice from predefined options"
    - multi_select: "Multiple choices from options"
    - checkbox: "Boolean toggle field"
  
  media:
    - files: "File attachment URLs (no direct upload)"
  
  relationships:
    - relation: "Link to database items (bi-directional)"
    - rollup: "Aggregate data from relations"
  
  people:
    - people: "User references from workspace"
```

### Block Types

```yaml
block_types:
  text:
    - paragraph, heading_1, heading_2, heading_3
    - quote, callout (with icon and color)
  
  lists:
    - bulleted_list_item, numbered_list_item
    - to_do (checkable)
  
  interactive:
    - toggle (collapsible content)
  
  code:
    - code (syntax-highlighted, language selection)
  
  media:
    - image, video, file, embed (URL only)
  
  structural:
    - divider, table
```

### Rich Text Formatting

```yaml
annotations:
  - bold, italic, strikethrough, underline, code, color

colors:
  text: [default, gray, brown, orange, yellow, green, blue, purple, pink, red]
  background: [gray_background, brown_background, etc.]

links:
  - url: "Inline hyperlinks"
  - mention: "User mentions with @"
  - page: "Internal page references"
  
equation:
  - support: "KaTeX mathematical equations"
```

---

<a id="4-database-page-operations"></a>

## 4. 🗄️ DATABASE & PAGE OPERATIONS

### Database Management

```yaml
API_create_a_database:
  description: "Create new database via native API"
  parameters:
    parent: "{ page_id: string }"
    title: "[{ text: { content: string } }]"
    properties: "Property definitions object"
  performance: "2-8 seconds depending on size"
  pre_check: "Connection verified ✓"

API_post_database_query:
  description: "Query database with filters via native API"
  parameters:
    database_id: "Database UUID"
    filter: "Filter conditions (optional)"
    sorts: "Sort configuration (optional)"
    page_size: "Results per page, max 100 (optional)"
  performance: "<1-4 seconds depending on size"
  pre_check: "Connection verified ✓"
```

### Property Configuration Patterns

```yaml
task_management:
  Status: {type: "select", options: ["To Do", "In Progress", "Done"]}
  Priority: {type: "select", options: ["High", "Medium", "Low"]}
  Assignee: {type: "people"}
  Due: {type: "date"}

content_calendar:
  Title: {type: "title"}
  PublishDate: {type: "date"}
  Author: {type: "people"}
  Category: {type: "multi_select"}
  Status: {type: "select"}

crm_contacts:
  Name: {type: "title"}
  Email: {type: "email"}
  Phone: {type: "phone_number"}
  Company: {type: "relation"}
  LastContact: {type: "date"}
```

### Database Filtering

```yaml
filter_operators:
  text: [equals, does_not_equal, contains, does_not_contain, starts_with, ends_with, is_empty, is_not_empty]
  number: [equals, does_not_equal, greater_than, less_than, greater_than_or_equal_to, less_than_or_equal_to, is_empty, is_not_empty]
  date: [equals, before, after, on_or_before, on_or_after, is_empty, is_not_empty, past_week, past_month, past_year, next_week, next_month, next_year]
  select: [equals, does_not_equal, is_empty, is_not_empty]
  relation: [contains, does_not_contain, is_empty, is_not_empty]
```

### Complex Query Example

```yaml
compound_filter:
  filter:
    and:
      - {property: 'Status', select: {equals: 'In Progress'}}
      - {property: 'Priority', select: {equals: 'High'}}

nested_filter:
  filter:
    or:
      - and:
          - {property: 'Status', select: {equals: 'Done'}}
          - {property: 'Due', date: {past_week: {}}}
      - {property: 'Priority', select: {equals: 'High'}}

sorted_results:
  sorts:
    - {property: 'Priority', direction: 'ascending'}
    - {property: 'Due', direction: 'ascending'}
```

### Database Views

```yaml
view_types:
  table: "Spreadsheet-style grid for data analysis"
  board: "Kanban boards for workflow management"
  timeline: "Gantt-style for project planning"
  calendar: "Month/week view for event planning"
  list: "Simplified vertical list"
  gallery: "Card-based visual grid"

note: "Views configured in Notion UI, not via API"
```

### Relation and Rollup

```yaml
relation_properties:
  type: "relation"
  database_id: "target_database_id"
  relationship: "one_to_many or many_to_many"
  synced_property: "optional_two_way_sync"
  behavior: "bi-directional with auto-reverse relation"

rollup_properties:
  type: "rollup"
  relation: "relation_property_name"
  rollup_property: "property_to_aggregate"
  functions: [show_original, count, sum, average, min, max, range, percent_empty, percent_not_empty]
```

### Page Management

```yaml
API_post_page:
  description: "Create new page via native API"
  parameters:
    parent: "{ page_id: string } or { database_id: string }"
    properties: "Page properties (title for pages, db fields for db pages)"
    children: "Initial content blocks (optional)"
  performance: "1-8 seconds depending on content"
  pre_check: "Connection verified ✓"

API_patch_page:
  description: "Update page properties via native API"
  parameters:
    page_id: "Page UUID"
    properties: "Properties to update (optional)"
    archived: "Archive/unarchive page (optional)"
    icon: "Page icon - emoji or external URL (optional)"
    cover: "Cover image - external URL (optional)"
  performance: "<1 second"
  pre_check: "Connection verified ✓"

API_retrieve_a_page:
  description: "Get page details via native API"
  parameters:
    page_id: "Page UUID"
  performance: "<1 second"
  pre_check: "Connection verified ✓"
```

### Content Operations

```yaml
API_get_block_children:
  description: "Get blocks within page/block via native API"
  parameters:
    block_id: "Page or block UUID"
    page_size: "Results per page, max 100 (optional)"
    start_cursor: "Pagination cursor (optional)"
  performance: "<1 second"
  pre_check: "Connection verified ✓"

API_patch_block_children:
  description: "Append blocks to page/block via native API"
  parameters:
    block_id: "Parent page or block UUID"
    children: "Array of block objects to append"
  performance: "1-8 seconds depending on content"
  pre_check: "Connection verified ✓"
```

### Common Block Structures

```yaml
documentation_page:
  - heading_1: "Page title"
  - paragraph: "Introduction"
  - heading_2: "Section 1"
  - bulleted_list_item: "Key points"
  - code: "Code examples"

meeting_notes:
  - heading_1: "Meeting Title"
  - paragraph: "Date, attendees, purpose"
  - heading_2: "Agenda Items"
  - to_do: "Action items"
  - callout: "Important decisions"

project_spec:
  - heading_1: "Project Name"
  - callout: "Project overview"
  - heading_2: "Requirements"
  - numbered_list_item: "Requirements list"
  - table: "Technologies and versions"
```

### Page Hierarchy

```yaml
hierarchy:
  depth: "Unlimited nesting levels"
  structure: "Parent → Child → Grandchild → ..."
  
organization_patterns:
  workspace_root:
    level_1: "Main areas (Projects, Docs, Resources)"
    level_2: "Categories within areas"
    level_3: "Individual items or pages"
    level_4: "Sub-pages and details"

database_pages:
  behavior: "Database pages are regular pages with properties"
  children: "Can contain content blocks like any page"
  templates: "Can have templates for new database items (UI only)"
```

### Icons and Covers

```yaml
icons:
  emoji: "{ emoji: '📘' }"
  external: "{ external: { url: 'https://...' } }"

covers:
  external: "{ external: { url: 'https://...' } }"
  recommended_size: "1500x600 pixels"

note: "Direct file upload not supported - use external URLs"
```

---

<a id="5-search-collaboration"></a>

## 5. 🔍 SEARCH & COLLABORATION

### Search Operations

```yaml
API_post_search:
  description: "Search workspace content via native API"
  parameters:
    query: "Search term (empty for all)"
    filter: "{ property: 'object', value: 'page' or 'database' }"
    sort: "{ direction: 'ascending/descending', timestamp: 'last_edited_time' }"
    page_size: "Results per page, max 100"
  performance: "<1-3 seconds depending on size"
  pre_check: "Connection verified ✓"
```

### Search Capabilities

```yaml
scope:
  - "All pages shared with integration"
  - "All databases shared with integration"
  - "Searches titles and page content"
  - "Results ranked by relevance"

filtering:
  by_type:
    pages_only: "{ property: 'object', value: 'page' }"
    databases_only: "{ property: 'object', value: 'database' }"
  
  by_time:
    most_recent: "{ timestamp: 'last_edited_time', direction: 'descending' }"
    oldest_first: "{ timestamp: 'last_edited_time', direction: 'ascending' }"

pagination:
  - "Up to 100 results per query"
  - "Use start_cursor for next page"

limitations:
  - "Only searches content shared with integration"
  - "Cannot search archived pages"
  - "Search is case-insensitive"
```

### Search Patterns

```yaml
find_page_by_title:
  query: "exact page title"
  filter: "{ property: 'object', value: 'page' }"

find_database:
  query: "database name"
  filter: "{ property: 'object', value: 'database' }"

keyword_search:
  query: "keyword or phrase"
  filter: "none (search all)"

recent_changes:
  query: ""  # empty for all
  sort: "{ timestamp: 'last_edited_time', direction: 'descending' }"
```

### Comment Operations

```yaml
API_create_a_comment:
  description: "Add comment to page via native API"
  parameters:
    parent: "{ page_id: string }"
    rich_text: "[{ text: { content: string } }]"
  performance: "<1 second"
  pre_check: "Connection verified ✓"
```

### Comment Features

```yaml
threading:
  - "Comments create discussion threads"
  - "Thread replies supported"
  - "Mentioned users get notified"

mentions:
  format: "@username"
  behavior: "User receives notification"
  requirement: "User must have page access"

rich_text:
  - "Bold, italic, code, links"
  - "Hyperlinks to external resources"
  - "Inline code snippets"

resolution:
  - "Threads can be resolved/unresolved (UI only)"
  - "Resolved threads collapsed by default"
```

### User Operations

```yaml
API_get_user:
  description: "Get user details"
  parameters: {user_id: "User UUID"}
  performance: "<1 second"

API_get_users:
  description: "List workspace users"
  parameters: {page_size: "max 100", start_cursor: "pagination"}
  performance: "<1 second"

API_get_self:
  description: "Get bot user info (connection check)"
  parameters: {}
  performance: "<1 second"
```

### User Types

```yaml
person:
  description: "Human workspace members"
  properties: [Name, Avatar, Email, Permissions]
  usage: "Assignees, collaborators, mentions"

bot:
  description: "Integration users (like this MCP)"
  properties: [Name, Owner, Permissions]
  usage: "API operations, automated tasks"

permissions:
  workspace_level: "Full, editor, commenter, reader"
  page_level: "Inherit or custom"
  inheritance: "Children inherit parent permissions"
```

---

<a id="6-limitations"></a>

## 6. ⚠️ LIMITATIONS

### Critical Limitations

```yaml
permission_model:
  restriction: "ABSOLUTE - Respects Notion's permissions"
  enforcement: "API-level permission checks"
  
  problem_scenarios:
    - "Content not shared with integration"
    - "Private pages without explicit access"
    - "Other workspaces (cannot access)"
    - "Archived content (unless specifically requested)"
  
  solution: "Share pages/databases with integration"
  
  sharing_methods:
    workspace_level: "Integration settings → Access tab"
    page_level: "Page menu → Connections → Add integration"
  
  verification: "API_get_self to check bot permissions"

media_handling:
  problem: "Cannot upload files directly to Notion"
  solution: "Use external hosting services with URL references"
  
  recommended_services:
    - cloudinary: "25GB free, API, general use"
    - amazon_s3: "5GB free, API, scale operations"
    - imgur: "Unlimited free, API, quick hosting"
  
  workaround:
    - "Use external URL in image blocks"
    - "Use external URL in file blocks"
    - "Use external URL for page covers"

connection_requirements:
  dependencies:
    - "MCP server must be connected"
    - "Integration token must be valid"
    - "Test query must pass (API_get_self)"
    - "Content must be shared with integration"
    - "Rate limits must be respected"
  
  enforcement: "Cannot proceed without these"

rate_limiting:
  per_second: 3  # average
  safe_operating: 2.5
  warning_threshold: 2.8
  enforcement: "Automatic throttling by Notion"
  handling: "Exponential backoff on rate limit errors"

workspace_isolation:
  restriction: "Single workspace per integration"
  cannot_access: ["Other workspaces", "Personal pages outside workspace", "Guest pages (unless shared)"]
  enforcement: "Token scoped to one workspace"

api_limitations:
  - view_configuration: "Cannot create/modify database views via API (configure in UI)"
  - template_creation: "Cannot create templates via API (create in UI)"
  - permission_management: "Cannot modify permissions via API (manage in UI)"
  - workspace_settings: "Cannot access/modify workspace settings"
```

### Error Handling

```yaml
common_errors:
  connection_lost:
    cause: "MCP server crashed or network issue"
    solution: "Restart Claude Desktop / Check network"
  
  invalid_token:
    cause: "Token expired, revoked, or incorrect"
    solution: "Regenerate integration token"
  
  not_shared:
    cause: "Page/database not shared with integration"
    solution: "Share content with integration"
  
  rate_limited:
    cause: "Too many requests in short period"
    solution: "Wait and retry with exponential backoff"
  
  parent_not_found:
    cause: "Invalid parent page/database ID"
    solution: "Verify parent exists and is accessible"
  
  invalid_property:
    cause: "Property type mismatch or invalid value"
    solution: "Check property schema and value format"
  
  archived_page:
    cause: "Attempting to modify archived page"
    solution: "Unarchive page first"

error_recovery_protocol:
  REPAIR_sequence:
    R: "Recognize: Identify error type from API response"
    E: "Evaluate: Assess impact and recovery options"
    P: "Plan: Choose best recovery strategy"
    A: "Apply: Execute recovery action"
    I: "Inspect: Verify recovery successful"
    R: "Report: Communicate status to user"
```

### Performance Characteristics

```yaml
performance:
  engine: "Notion REST API v1"
  characteristics:
    - "Integration token authentication"
    - "Rate limited (3/second)"
    - "Paginated responses (100 max)"
    - "Native operations only"
  
  benchmarks:
    connection_check: "<1 second"
    database_create: "2-3 seconds"
    page_create: "1-2 seconds"
    query_database: "<1 second (small), 2-4 seconds (large)"
    search: "<1 second (small), 2-3 seconds (large)"
    block_append: "1-2 seconds (few), 4-8 seconds (many)"
    comment_create: "<1 second"
```

---

<a id="7-quick-reference"></a>

## 7. 🏎️ QUICK REFERENCE

### MCP Tools Summary

**Key tools:**

```yaml
connection_and_users:
  API_get_self: "Connection check, get bot user info"
  API_get_user: "Get user details [user_id]"
  API_get_users: "List workspace users [page_size, start_cursor]"

search:
  API_post_search: "Search workspace [query, filter, sort]"

pages:
  API_post_page: "Create new page [parent, properties, children]"
  API_patch_page: "Update page [page_id, properties, archived]"
  API_retrieve_a_page: "Get page details [page_id]"

databases:
  API_create_a_database: "Create new database [parent, title, properties]"
  API_post_database_query: "Query database [database_id, filter, sorts]"

blocks:
  API_get_block_children: "Get blocks in page/block [block_id, page_size]"
  API_patch_block_children: "Append blocks [block_id, children]"

comments:
  API_create_a_comment: "Add comment [parent, rich_text]"
```

### Integration References

```yaml
official_documentation:
  notion_mcp_github: "https://github.com/makenotion/notion-mcp-server"
  npm_package: "https://www.npmjs.com/package/@makenotion/notion-mcp-server"
  notion_api_docs: "https://developers.notion.com/reference/intro"
  integration_setup: "https://www.notion.so/profile/integrations"

related_documents:
  thinking_framework:
    file: "Notion - SYNC Thinking Framework"
    purpose: "Methodology and cognitive framework"
    key_concepts: ["Survey", "Yield", "Navigate", "Create"]
  
  interactive_intelligence:
    file: "Notion - Interactive Intelligence"
    purpose: "Conversation flows and interaction patterns"
    includes: ["Conversation Architecture", "Response Templates", "REPAIR protocol"]
```

### Decision Tree

```
Request received
    ↓
Verify MCP connection → Failed → Apply REPAIR
    ↓ Success
Check permissions → Not shared → Share with integration
    ↓ Shared
Need database? → Yes → Database operations
    ↓ No
Need pages? → Yes → Page operations
    ↓ No
Need search? → Yes → Search operations
    ↓ No
Ask for clarification
```

### Capability Check

```python
can_do = {
    'connection_required': True,  # ALWAYS
    'databases': True,
    'pages': True,
    'blocks': True,
    'search': True,
    'comments': True,
    'users': True,
    'relations': True,
    'rich_text': True,
    'file_upload': False,  # URLs only
    'native_operations': True  # ALWAYS
}
```

### Pre-Operation Protocol

```markdown
Every Operation Requires:

1. Connection verification ✓
2. Test query successful (API_get_self) ✓
3. Content shared with integration ✓
4. Native approach confirmed ✓
5. Rate limits respected ✓
6. Ready to execute ✓
```

### Critical Rules Summary

```markdown
THE FIVE ABSOLUTES:

1. Connection verified before EVERY operation
2. Native APIs ONLY - no custom code
3. Test query must pass before proceeding
4. Content must be shared with integration
5. REPAIR protocol for all errors
```

### Quick Command Reference

```yaml
common_operations:
  create_database:
    command: "API_create_a_database"
    required: "[parent, title, properties]"
    example: "Create task database in Projects page"
  
  query_data:
    command: "API_post_database_query"
    required: "[database_id]"
    optional: "[filter, sorts, page_size]"
    example: "Get all In Progress tasks"
  
  create_page:
    command: "API_post_page"
    required: "[parent, properties]"
    optional: "[children]"
    example: "Create meeting notes with initial content"
  
  add_content:
    command: "API_patch_block_children"
    required: "[block_id, children]"
    example: "Add paragraphs and headings to page"
  
  search_workspace:
    command: "API_post_search"
    optional: "[query, filter, sort]"
    example: "Find all pages about API documentation"
  
  add_comment:
    command: "API_create_a_comment"
    required: "[parent, rich_text]"
    example: "Comment on project review page"
```

### Notion MCP Integration

```yaml
notion_integration:
  workflow:
    1: "Verify Notion MCP connection"
    2: "Receives natural language request"
    3: "Identifies operation type (database, page, content)"
    4: "Routes to appropriate Notion MCP operations"
    5: "Applies smart defaults based on use case"
    6: "Executes operation with progress tracking"
    7: "Returns organized workspace with next steps"
  
  use_case_routing:
    - knowledge_management: "Notion (wikis, docs, knowledge bases)"
    - documentation: "Notion (specs, guides, references)"
    - content_calendar: "Notion (publishing, content planning)"
    - databases: "Notion (structured data, properties, relations)"
    - hierarchical_content: "Notion (nested pages, wikis)"
    - team_collaboration: "Notion (docs, comments, sharing)"
```

---

*This document focuses exclusively on Notion MCP server capabilities and technical specifications. For thinking methodology and cognitive framework, see Notion - SYNC Thinking Framework. For conversation flows and error handling (REPAIR protocol), see Notion - Interactive Intelligence.*
