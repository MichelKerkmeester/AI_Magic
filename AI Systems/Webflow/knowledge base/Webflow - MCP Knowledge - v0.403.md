# Webflow - MCP Knowledge

Technical reference for Webflow MCP server capabilities and integration for Designer and Data API operations.

**Purpose:** Document Webflow-specific features, supported operations, API specifications, and technical constraints. Conversation flows and thinking methodology are in Interactive Intelligence and SYNC Thinking Framework respectively.

---

## 📋 TABLE OF CONTENTS

1. [🔌 SERVER OVERVIEW](#1-server-overview)
2. [🛠️ CORE CAPABILITIES](#2-core-capabilities)
3. [📊 FORMAT SUPPORT](#3-format-support)
4. [🎨 DESIGNER API OPERATIONS](#4-designer-api-operations)
5. [📈 DATA API OPERATIONS](#5-data-api-operations)
6. [🚀 PUBLISHING WORKFLOWS](#6-publishing-workflows)
7. [⚠️ LIMITATIONS](#7-limitations)
8. [🏎️ QUICK REFERENCE](#8-quick-reference)

---

<a id="1-server-overview"></a>

## 1. 🔌 SERVER OVERVIEW

### MCP Server Details

The Webflow MCP Server provides native integration with both Designer API and Data API for visual design and content management operations. It supports OAuth 2.0 (recommended) and API token-based authentication.

**Key Information:**
- **Repository:** https://github.com/webflow/mcp-server
- **NPM Package:** https://www.npmjs.com/package/webflow-mcp-server
- **Protocol:** Model Context Protocol (MCP)
- **Node Requirement:** Node.js 22.3.0 or higher
- **APIs:** Designer API (native) and Data API (native)

**Authentication Methods:**
- **Remote (Recommended):** OAuth 2.0 via mcp-remote package at https://mcp.webflow.com/sse
- **Local (Alternative):** Direct connection with WEBFLOW_TOKEN environment variable

**Important:** This server executes **ZERO custom code**. All operations use native Webflow API endpoints exclusively. Custom JavaScript, CSS, or HTML generation is absolutely forbidden (0% custom code generation). The Designer API requires the MCP Bridge App companion application.

### System Architecture

The Webflow MCP workflow follows a strict sequence to ensure proper connectivity and API access:

**Operation Sequence:**
1. **Connection Check** (ALWAYS FIRST) - Verify MCP server is active
2. **User Request** - Receive and parse user intent
3. **Intent Recognition** - Determine operation type needed
4. **API Selection** - Choose between Designer/Data API
5. **Native Operation** (NO custom code) - Execute using official Webflow API
6. **Feedback & Confirmation** - Return results to user

**Deployment Architecture:**

*Remote Deployment (Recommended):*
- OAuth via mcp-remote package
- No API token management required
- Multi-site authorization support
- Secure token-based access
- Connection: https://mcp.webflow.com/sse

*Local Deployment (Alternative):*
- Direct with API token in WEBFLOW_TOKEN
- Manual bridge app creation required
- Workspace admin permissions needed
- API token in environment variables

**API Routing:**
- **Designer API:** Requires MCP Bridge App companion for visual elements, styles, and components
- **Data API:** Requires OAuth (remote) or API token (local) for collections, content, and publishing

### Core Principle

**ABSOLUTE RULE:** Only native Webflow API calls are allowed. Custom code generation of any kind is strictly forbidden with 0% tolerance.

**✅ Allowed Operations:**
- Native Webflow API calls exclusively
- `webflow:collections_create()` - Collection operations
- `webflow:components_create()` - Component management
- `webflow:pages_update_static_content()` - Page updates
- All official Webflow API endpoints

**❌ Forbidden Operations:**
- Custom JavaScript generation (0%)
- Custom CSS creation (0%)
- HTML template generation (0%)
- Any custom code whatsoever

This policy has **ABSOLUTE enforcement with no exceptions**.

### Connection Verification

**Reference:** Connection verification logic is in Interactive Intelligence. SYNC methodology phases in SYNC Thinking Framework.

Connection verification must be the **first action before all operations**. Use the `sites_list` tool to test connectivity and authentication.

**Status Messages:**
- ✅ **Connected:** "Webflow MCP Connected - All APIs available"
- ❌ **Disconnected:** "Webflow MCP Not Connected - Setup required"
- ⚠️ **Auth Failed:** "Authentication Issue - Re-authorization needed"
- ⚠️ **App Missing:** "Companion App Required - Launch MCP Bridge App"

**Connection Protocol:**
1. Check MCP server status
2. Run test query (`sites_list`)
3. Verify OAuth authentication
4. Check companion app status (if Designer API needed)
5. Proceed with operations only if all checks pass

**Example Implementation:**
```javascript
async function verifyConnection() {
    try {
        await webflow:sites_list();
        return { 
            connected: true, 
            apis: 'ready'
        };
    } catch (error) {
        // Apply REPAIR protocol
        return { connected: false, error: error };
    }
}
```

**Connection States & Actions:**
- **Connected:** All systems operational → Proceed with operations
- **Disconnected:** No MCP access → Restart Claude Desktop
- **Auth Failed:** OAuth issue → Re-authorize Webflow connection
- **App Missing:** Designer API unavailable → Launch MCP Bridge App

---

<a id="2-core-capabilities"></a>

## 2. 🛠️ CORE CAPABILITIES

### Available Operations

**Note:** SYNC thinking methodology (Survey → Yield → Navigate → Create) and conversation flows are defined in SYNC Thinking Framework and Interactive Intelligence.

```yaml
designer_api_operations:
  element_management:
    tools:
      - createElement
      - modifyElement
      - deleteElement
      - moveElement
    method: "Native API only"
    requires: "MCP Bridge App"
  
  style_operations:
    tools:
      - createClass
      - applyClass
      - modifyStyles
      - createBreakpoint
    method: "Native API only"
    requires: "MCP Bridge App"
  
  component_system:
    tools:
      - createComponent
      - registerComponent
      - createInstance
      - updateComponent
    method: "Native API only"
    requires: "MCP Bridge App"

data_api_operations:
  collection_management:
    tools:
      - createCollection
      - modifyCollection
      - deleteCollection
      - listCollections
    method: "Native API only"
    requires: "OAuth only"
  
  content_operations:
    tools:
      - createItem
      - updateItem
      - deleteItem
      - bulkCreate
      - bulkUpdate
    method: "Native API only"
    requires: "OAuth only"
  
  publishing:
    tools:
      - publishItem
      - publishCollection
      - publishSite
      - schedulePublish
    method: "Native API only"
    requires: "OAuth only"
```

### What You CAN Do ✅

**Designer API Operations (Native API Only):**

Visual design operations using native Webflow APIs:
- Create elements using native API calls
- Apply styles through Designer API
- Build components with Webflow's component system
- Manage variables via native operations
- Control breakpoints programmatically
- Design pages using API methods

All Designer API operations require the MCP Bridge App companion application.

**Data API Operations (Native API Only):**

Content and structural operations using native APIs:
- Create collections with custom field types
- Add any field type to collections
- Manage content items (full CRUD operations)
- Handle publishing workflows
- Optimize SEO at scale
- Manage relationships between collections

**IMPORTANT:** All operations use native API calls only. Custom code generation is **NEVER** allowed (0% tolerance).

### What You CANNOT Do ❌

**Custom Code Restriction (ABSOLUTE):**
- ❌ Custom JavaScript generation (0%)
- ❌ Custom CSS creation (0%)
- ❌ HTML template generation (0%)
- ❌ Any code whatsoever
- **Enforcement:** Zero tolerance policy

**Media Upload Limitation:**
- Direct upload is not supported
- **Workaround:** Use external URLs only
- Recommended services: Cloudinary, Amazon S3, Imgur

**Connection Requirements:**
- Cannot work without MCP connection verification
- Connection check must ALWAYS be performed first
- All operations require active MCP session

**Companion App Requirement:**
- Designer API requires MCP Bridge App
- App must be running for Designer API operations
- Applies to all visual design operations

**Authorization:**
- Owner/admin access required
- OAuth with proper scope needed
- Test query must pass before operations

**Rate Limits:**
- Maximum: 60 calls per minute
- Safe operating zone: 50 calls per minute
- Warning threshold: 55 calls per minute
- Cooldown period: 60 seconds after limit

**Access Control:**
- Only public or authorized resources accessible
- Cannot modify locked elements
- Cannot access private assets
- Respects Webflow's protected components

---

<a id="3-format-support"></a>

## 3. 📊 FORMAT SUPPORT

### Field Types Available

```yaml
field_types:
  text_fields:
    PlainText:
      description: "Single line text"
      use_case: "Titles, names, short text"
      native: true
    
    RichText:
      description: "Formatted content with HTML"
      use_case: "Articles, descriptions, formatted content"
      native: true
    
    Email:
      description: "Email address validation"
      use_case: "Contact information"
      native: true
    
    Phone:
      description: "Phone number field"
      use_case: "Contact information"
      native: true
  
  numeric_fields:
    Number:
      description: "Numeric values"
      use_case: "Prices, quantities, ratings"
      native: true
  
  date_time:
    Date:
      description: "Date and time values"
      use_case: "Publishing dates, events, deadlines"
      native: true
  
  links:
    Link:
      description: "URL field"
      use_case: "External links, references"
      native: true
  
  media:
    Image:
      description: "Image URL reference"
      use_case: "Media content (URL only - no direct upload)"
      native: true
      limitation: "External URL required"
    
    File:
      description: "File URL reference"
      use_case: "Documents, downloads (URL only)"
      native: true
      limitation: "External URL required"
  
  relationships:
    Reference:
      description: "Link to single item"
      use_case: "One-to-one relationships"
      native: true
    
    MultiReference:
      description: "Multiple item links"
      use_case: "Categories, tags, many-to-many"
      native: true
  
  selection:
    Option:
      description: "Single choice dropdown"
      use_case: "Status, type, category"
      native: true
    
    Switch:
      description: "Boolean toggle"
      use_case: "Featured, active, published flags"
      native: true
  
  design:
    Color:
      description: "Color value picker"
      use_case: "Theming, styling"
      native: true
```

---

<a id="4-designer-api-operations"></a>

## 4. 🎨 DESIGNER API OPERATIONS

### Native Element Management

```yaml
createElement:
  description: "Add element via native API"
  parameters:
    type:
      type: string
      required: true
      options: ["div", "section", "heading", "paragraph", "image", "link"]
    
    parent:
      type: string
      required: true
      description: "Parent element ID"
    
    position:
      type: integer
      optional: true
      description: "Position in parent"
  
  performance: "1-2 seconds"
  method: "Native API"
  requires: "MCP Bridge App"

modifyElement:
  description: "Change element via native API"
  parameters:
    id:
      type: string
      required: true
      description: "Element ID"
    
    properties:
      type: object
      required: true
      description: "Properties to modify"
  
  performance: "< 1 second"
  method: "Native API"
  requires: "MCP Bridge App"

deleteElement:
  description: "Remove element via native API"
  parameters:
    id:
      type: string
      required: true
      description: "Element ID"
  
  performance: "< 1 second"
  method: "Native API"
  requires: "MCP Bridge App"

moveElement:
  description: "Reposition element via native API"
  parameters:
    id:
      type: string
      required: true
      description: "Element ID"
    
    parent:
      type: string
      required: true
      description: "New parent ID"
    
    position:
      type: integer
      optional: true
      description: "Position in new parent"
  
  performance: "< 1 second"
  method: "Native API"
  requires: "MCP Bridge App"
```

### Native Style Operations

```yaml
createClass:
  description: "Create new style class via native API"
  parameters:
    name:
      type: string
      required: true
      description: "Class name"
    
    properties:
      type: object
      required: true
      description: "Style properties"
  
  performance: "< 1 second"
  method: "Native API"
  requires: "MCP Bridge App"

applyClass:
  description: "Apply class to element via native API"
  parameters:
    element:
      type: string
      required: true
      description: "Element ID"
    
    class:
      type: string
      required: true
      description: "Class name"
  
  performance: "< 1 second"
  method: "Native API"
  requires: "MCP Bridge App"

modifyStyles:
  description: "Update styles via native API"
  parameters:
    class:
      type: string
      required: true
      description: "Class name"
    
    properties:
      type: object
      required: true
      description: "Style changes"
  
  performance: "< 1 second"
  method: "Native API"
  requires: "MCP Bridge App"

createBreakpoint:
  description: "Add responsive breakpoint via native API"
  parameters:
    breakpoint:
      type: string
      required: true
      options: ["desktop", "tablet", "mobile-landscape", "mobile-portrait"]
    
    styles:
      type: object
      required: true
      description: "Breakpoint-specific styles"
  
  performance: "1-2 seconds"
  method: "Native API"
  requires: "MCP Bridge App"
```

### Native Component System

```yaml
createComponent:
  description: "Build component via native API"
  parameters:
    elements:
      type: array
      required: true
      description: "Element structure"
    
    name:
      type: string
      required: true
      description: "Component name"
  
  performance: "5-10 seconds"
  method: "Native API"
  requires: "MCP Bridge App"

registerComponent:
  description: "Register component natively"
  parameters:
    component:
      type: string
      required: true
      description: "Component ID"
  
  performance: "1-2 seconds"
  method: "Native API"
  requires: "MCP Bridge App"

createInstance:
  description: "Instantiate component via native API"
  parameters:
    component:
      type: string
      required: true
      description: "Component ID"
    
    parent:
      type: string
      required: true
      description: "Parent element ID"
  
  performance: "1-2 seconds"
  method: "Native API"
  requires: "MCP Bridge App"

updateComponent:
  description: "Modify component via native API"
  parameters:
    id:
      type: string
      required: true
      description: "Component ID"
    
    changes:
      type: object
      required: true
      description: "Component modifications"
  
  performance: "2-3 seconds"
  method: "Native API"
  requires: "MCP Bridge App"
```

### Requirements

```yaml
designer_api_requirements:
  connection:
    status: "MCP verified first"
    test: "sites_list must succeed"
  
  companion_app:
    required: true
    name: "MCP Bridge App"
    state: "Must be open in Designer"
  
  sync:
    type: "Real-time"
    requirement: "Connection maintained during operations"
  
  permissions:
    level: "Write access to project"
    scope: "Owner or admin"
  
  method:
    type: "Native API calls only"
    custom_code: "NEVER (0%)"
```

---

<a id="5-data-api-operations"></a>

## 5. 📈 DATA API OPERATIONS

### Collection Management

```yaml
createCollection:
  description: "Create new collection via native API"
  parameters:
    name:
      type: string
      required: true
      description: "Collection name"
    
    fields:
      type: array
      required: true
      description: "Field definitions"
  
  performance:
    small: "3-5 seconds"
    medium: "5-8 seconds"
    large: "8-12 seconds"
  pre_check: "Connection verified ✓"
  method: "Native API"

modifyCollection:
  description: "Update collection structure via native API"
  parameters:
    id:
      type: string
      required: true
      description: "Collection ID"
    
    changes:
      type: object
      required: true
      description: "Structure modifications"
  
  performance:
    small: "2-3 seconds"
    medium: "3-5 seconds"
    large: "5-8 seconds"
  pre_check: "Connection verified ✓"
  method: "Native API"

deleteCollection:
  description: "Remove collection via native API"
  parameters:
    id:
      type: string
      required: true
      description: "Collection ID"
  
  performance:
    small: "1-2 seconds"
    medium: "2-3 seconds"
    large: "3-5 seconds"
  pre_check: "Connection verified ✓"
  method: "Native API"

listCollections:
  description: "Get all collections"
  parameters:
    site_id:
      type: string
      optional: true
      description: "Filter by site"
  
  performance: "< 1 second"
  pre_check: "Connection verified ✓"
  method: "Native API"
```

### Content Operations

```yaml
createItem:
  description: "Add content item via native API"
  parameters:
    collection:
      type: string
      required: true
      description: "Collection ID"
    
    data:
      type: object
      required: true
      description: "Item field values"
  
  performance:
    small: "2-3 seconds"
    medium: "3-5 seconds"
    large: "5-8 seconds"
  method: "Native API"

updateItem:
  description: "Modify content item via native API"
  parameters:
    id:
      type: string
      required: true
      description: "Item ID"
    
    changes:
      type: object
      required: true
      description: "Field updates"
  
  performance:
    small: "1-2 seconds"
    medium: "2-3 seconds"
    large: "3-5 seconds"
  method: "Native API"

deleteItem:
  description: "Remove content item via native API"
  parameters:
    id:
      type: string
      required: true
      description: "Item ID"
  
  performance: "< 1 second"
  method: "Native API"

bulkCreate:
  description: "Add multiple items via native API"
  parameters:
    items:
      type: array
      required: true
      description: "Array of item data"
  
  performance: "1-2 seconds per item"
  method: "Native API"
  rate_limit: "Respect 60/minute limit"

bulkUpdate:
  description: "Update multiple items via native API"
  parameters:
    items:
      type: array
      required: true
      description: "Array of item updates"
  
  performance: "1 second per item"
  method: "Native API"
  rate_limit: "Respect 60/minute limit"
```

### Operation Prerequisites

```yaml
before_any_data_operation:
  checklist:
    - "MCP connection verified ✓"
    - "Test query successful (sites_list) ✓"
    - "Authentication valid ✓"
    - "Collection exists ✓"
    - "Fields configured ✓"
    - "Using native API calls ✓"
    - "No custom code ✓"
  
  enforcement: "ALL must pass before proceeding"
```

---

<a id="6-publishing-workflows"></a>

## 6. 🚀 PUBLISHING WORKFLOWS

### Publishing States

```yaml
publishing_states:
  draft:
    description: "Work in progress"
    visibility: "Designers only"
    connection_required: true
  
  staged:
    description: "Ready for review"
    visibility: "Internal team"
    connection_required: true
  
  published:
    description: "Live content"
    visibility: "Public"
    connection_required: true
```

### Publishing Operations

```yaml
publishItem:
  description: "Publish single item via native API"
  scope: "Single item"
  performance:
    small: "3-5 seconds"
    medium: "5-8 seconds"
    large: "8-12 seconds"
  pre_check: "Connection verified ✓"
  method: "Native API"

publishCollection:
  description: "Publish all collection items via native API"
  scope: "Entire collection"
  performance:
    small: "5-10 seconds"
    medium: "10-20 seconds"
    large: "20-40 seconds"
  pre_check: "Connection verified ✓"
  method: "Native API"

publishSite:
  description: "Publish entire site via native API"
  scope: "Full site"
  performance:
    small: "10-30 seconds"
    medium: "30-60 seconds"
    large: "60-120 seconds"
  pre_check: "Connection verified ✓"
  method: "Native API"

schedulePublish:
  description: "Schedule future publish via native API"
  scope: "Items with timestamp"
  performance: "2-3 seconds"
  pre_check: "Connection verified ✓"
  method: "Native API"
```

### Publishing Patterns

```yaml
patterns:
  standard_workflow:
    sequence: "Connection Check → Development → Staging → Production"
    method: "Native operations only"
  
  content_workflow:
    sequence: "Draft → Review → Live"
    method: "Native API calls"
  
  testing_workflow:
    sequence: "A/B Testing → Analysis → Deploy"
    method: "Via native API"

publishing_protocol:
  checklist:
    - "Connection verified ✓"
    - "Content validated ✓"
    - "SEO fields complete ✓"
    - "Relationships set ✓"
    - "Using native publish API ✓"
    - "No custom scripts ✓"
  
  enforcement: "ALL must pass before publishing"
```

---

<a id="7-limitations"></a>

## 7. ⚠️ LIMITATIONS

### Critical Limitations

```yaml
custom_code_generation:
  restriction: "ABSOLUTE"
  enforcement: "0% custom code generation"
  
  problem_scenarios:
    - "User requests custom JavaScript"
    - "User requests custom CSS"
    - "User requests HTML templates"
    - "User requests any code generation"
  
  solution: "Use native Webflow APIs exclusively"
  
  native_alternatives:
    designer_api: "All visual elements"
    data_api: "All content operations"
    interactions: "Webflow's built-in system"
    components: "Native component system"
  
  custom_code_generated: "0% (NEVER)"

static_page_content:
  limitation: "CRITICAL - pages_update_static_content restriction"
  restriction: "Only supports localized secondary locales"
  cannot_update: "Static content in default locale"
  result: "Errors when attempting default locale updates"
  workaround: "Use for secondary locales only"
  source: "Official Webflow MCP documentation"
  
node_version:
  requirement: "Node.js 22.3.0 or higher"
  restriction: "Earlier versions not supported"
  check_command: "node -v"
  troubleshooting: "See Node.js compatibility guidance"

image_handling:
  problem: "Cannot upload images directly to Webflow"
  solution: "Use external hosting services with URL references"
  
  recommended_services:
    cloudinary:
      free_tier: "25GB"
      api: true
      best_for: "General use"
    
    amazon_s3:
      free_tier: "5GB"
      api: true
      best_for: "Scale operations"
    
    imgur:
      free_tier: "Unlimited"
      api: true
      best_for: "Quick hosting"
    
    asset_manager:
      free_tier: "Manual"
      api: false
      best_for: "Small batches"

connection_requirements:
  dependencies:
    - "MCP server must be connected"
    - "OAuth must be authorized"
    - "Test query must pass (sites_list)"
    - "Companion app required for Designer API"
    - "Rate limits must be respected"
  
  enforcement: "Cannot proceed without these"

rate_limiting:
  limits:
    per_minute: 60
    safe_operating: 50
    warning_threshold: 55
    cooldown_period: 60  # seconds
    requires_connection: true
  
  enforcement: "Automatic throttling applied"

access_requirements:
  node_version:
    requirement: "Node.js 22.3.0 or higher"
    check: "node -v"
    troubleshooting: "https://developers.webflow.com/data/docs/ai-tools#nodejs-compatibility"
  
  connection:
    requirement: "Must verify first"
    protocol: "Connection check ALWAYS first"
  
  authentication:
    remote:
      type: "OAuth 2.0"
      method: "Via mcp-remote package"
      url: "https://mcp.webflow.com/sse"
      scope: "Site-level authorization during OAuth flow"
    
    local:
      type: "API Token"
      method: "Environment variable WEBFLOW_TOKEN"
      scope: "Token permissions determine access"
  
  companion_app:
    requirement: "Required for Designer API"
    name: "MCP Bridge App"
    installation: "Automatic via OAuth (remote) or manual publish (local)"
    location: "Designer → Apps panel (press E)"
  
  network:
    requirement: "Stable connection required"
    real_time: "Maintained during operations"
  
  custom_code:
    allowed: "NEVER (0%)"
    enforcement: "Absolute restriction"
```

---

<a id="8-quick-reference"></a>

## 8. 🏎️ QUICK REFERENCE

### MCP Tools Summary

**Complete tool list:** See [GitHub repository tools directory](https://github.com/webflow/mcp-server/tree/main/src/tools) for all available tools and parameters.

**Key tools:**

```yaml
tools:
  sites_list:
    purpose: "Connection check, list sites"
    parameters: []
    category: "Connection verification"
  
  collections_create:
    purpose: "Create collection"
    key_params: [name, fields]
    category: "Data API"
  
  collections_items_create_item_live:
    purpose: "Add content item"
    key_params: [collection_id, data]
    category: "Data API"
  
  components_create:
    purpose: "Build component"
    key_params: [site_id, structure]
    category: "Designer API"
    requires: "MCP Bridge App"
  
  pages_update_static_content:
    purpose: "Update page content"
    key_params: [page_id, nodes]
    category: "Designer API"
    requires: "MCP Bridge App"
  
  sites_publish:
    purpose: "Publish site"
    key_params: [site_id, domains]
    category: "Data API"
  
  get_designer_app_connection_info:
    purpose: "Get local bridge app connection URL"
    parameters: []
    category: "Local setup (if using local deployment)"
    note: "Returns http://localhost:<port> for bridge app"

tool_categories:
  based_on_repository:
    - "aiChat.ts - AI chat operations"
    - "cms.ts - CMS/collections operations"
    - "components.ts - Component management (Data API)"
    - "deAsset.ts - Designer asset operations"
    - "deComponents.ts - Designer component operations"
    - "deElement.ts - Designer element operations"
    - "dePages.ts - Designer page operations"
    - "deStyle.ts - Designer style operations"
    - "deVariable.ts - Designer variable operations"
    - "pages.ts - Page operations (Data API)"
    - "scripts.ts - Custom code/script operations"
    - "sites.ts - Site-level operations"
    - "rules.ts - Rules and automation"
    - "localDeMCPConnection.ts - Local bridge connection"
```

### Integration References

```yaml
official_documentation:
  webflow_mcp_docs:
    url: "https://developers.webflow.com/data/docs/ai-tools"
    description: "Official Webflow MCP installation and setup guide"
  
  npm_package:
    url: "https://www.npmjs.com/package/webflow-mcp-server"
    description: "NPM package documentation and installation"
  
  github_repository:
    url: "https://github.com/webflow/mcp-server"
    tools_directory: "https://github.com/webflow/mcp-server/tree/main/src/tools"
    description: "Open-source MCP server implementation"
  
  webflow_api_docs:
    designer_api: "https://developers.webflow.com/designer/reference/introduction"
    data_api: "https://developers.webflow.com/data/reference"
  
  llms_txt:
    url: "https://developers.webflow.com/llms.txt"
    description: "LLM-optimized documentation"
    note: "Add to AI clients for enhanced context"

related_documents:
  sync_thinking_framework:
    file: "Webflow - SYNC Thinking Framework"
    purpose: "4-phase methodology (Survey → Yield → Navigate → Create)"
    sections:
      - "Section 2: SYNC Principles (4 phases)"
      - "Section 3: Cognitive Rigor Framework"
      - "Section 4: The SYNC Methodology"
      - "Section 6: RICCE-SYNC Integration"
    key_concepts:
      - "Survey: Context assessment and API identification"
      - "Yield: Native pattern selection and optimization"
      - "Navigate: Sequential API operations"
      - "Create: Quality validation + integration delivery"
  
  interactive_intelligence:
    file: "Webflow - Interactive Intelligence"
    purpose: "Conversation flows and interaction patterns"
    sections:
      - "Section 1: Conversation Architecture"
      - "Section 2: Response Templates"
      - "Section 5: Error Recovery (REPAIR protocol)"
    integration: "Works with SYNC framework for complete workflow"
  
  error_handling:
    file: "Webflow - SYNC Thinking Framework"
    section: "Section 8: Quality Assurance"
    note: "Quality gates and validation procedures"
    includes:
      - "Connection diagnostics"
      - "REPAIR protocol application"
      - "Recovery workflows"
    note: "Document may not exist yet - placeholder for future"
```

### Decision Tree

```
Request received
    ↓
Verify MCP connection → Failed → Apply REPAIR
    ↓ Success
Check for custom code → Requested → Use native APIs instead
    ↓ None
Needs visual elements? → Yes → Designer API (check app)
    ↓ No
Needs data structure? → Yes → Data API
    ↓ No
Content management? → Yes → Data API
    ↓ No
Ask for clarification
```

### Capability Check

```python
can_do = {
    'connection_required': True,  # ALWAYS
    'collections': True,
    'fields': True,
    'elements': True,    # with app
    'styles': True,      # with app
    'components': True,  # with app
    'content': True,
    'publishing': True,
    'image_upload': False,  # URLs only
    'custom_code': False,   # NEVER
    'native_operations': True  # ALWAYS
}
```

### Pre-Operation Protocol

```markdown
Every Operation Requires:

1. Connection verification ✓
2. Test query successful ✓
3. Native approach confirmed ✓
4. No custom code ✓
5. APIs identified ✓
6. Ready to execute ✓
```

### Critical Rules Summary

```markdown
THE FIVE ABSOLUTES:

1. Connection verified before EVERY operation
2. Native APIs ONLY - zero custom code (0%)
3. Test query must pass before proceeding
4. Companion app required for Designer API
5. REPAIR protocol for all errors
```

### Performance Characteristics

```yaml
performance:
  engine: "Webflow REST APIs"
  characteristics:
    - "OAuth 2.0 authentication"
    - "Rate limited (60/min)"
    - "Real-time sync with companion app"
    - "Native operations only"
  
  benchmarks:
    connection_check: "1-2 seconds"
    collection_create: "3-5 seconds"
    content_operations: "2-3 seconds"
    component_create: "5-10 seconds"
    publishing: "3-5 seconds (item) to 10-30 seconds (site)"
```

---

*This document focuses exclusively on Webflow MCP server capabilities and technical specifications. For SYNC thinking methodology (Survey → Yield → Navigate → Create), see Webflow - SYNC Thinking Framework. For conversation flows and error handling (REPAIR protocol), see Webflow - Interactive Intelligence.*
