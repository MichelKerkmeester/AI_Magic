# ClickUp - MCP Knowledge

Technical reference for ClickUp MCP server capabilities and integration for task management, project tracking, and agile workflow operations.

**Purpose:** Document ClickUp-specific features, supported operations, API specifications, and technical constraints. Conversation flows and thinking methodology are in Interactive Intelligence and SYNC Thinking Framework respectively.

---

## 📋 TABLE OF CONTENTS

1. [🔌 SERVER OVERVIEW](#1-server-overview)
2. [🛠️ CORE CAPABILITIES](#2-core-capabilities)
3. [📊 FORMAT SUPPORT](#3-format-support)
4. [✅ TASK & WORKSPACE OPERATIONS](#4-task-workspace-operations)
5. [⏱️ TIME TRACKING & COLLABORATION](#5-time-tracking-collaboration)
6. [⚠️ LIMITATIONS](#6-limitations)
7. [🏎️ QUICK REFERENCE](#7-quick-reference)

---

<a id="1-server-overview"></a>

## 1. 🔌 SERVER OVERVIEW

### MCP Server Details

The ClickUp MCP Server (`@taazkareem/clickup-mcp-server`) provides native Model Context Protocol integration for task management and project tracking operations.

**Key Information:**
- **Repository:** https://github.com/taazkareem/clickup-mcp-server
- **NPM Package:** `@taazkareem/clickup-mcp-server`
- **Authentication:** API Key (environment variable)
- **APIs:** Task, Hierarchy, Time Tracking, Collaboration (native)

### System Architecture

**Operation Sequence:**
1. **Connection Check** (ALWAYS FIRST) - Verify MCP server is active
2. **User Request** - Receive and parse user intent
3. **Intent Recognition** - Determine operation type needed
4. **Operation Selection** - Choose between Hierarchy/Task/Tracking operations
5. **MCP Call** - Execute using official ClickUp MCP tools
6. **Feedback & Confirmation** - Return results to user

**MCP Routing:**
- **Hierarchy Operations:** Requires API key with workspace access
- **Task Operations:** Requires API key with task management permissions
- **Time Tracking:** Requires API key with time tracking scope
- **Collaboration:** Requires API key with collaboration access

### Connection Verification

Connection verification must be the **first action before all operations** (ALWAYS FIRST). Use the `get_workspace_hierarchy` operation to test connectivity and authentication.

**Status Messages:**
- ✅ **Connected:** "ClickUp MCP Connected - All operations available"
- ❌ **Disconnected:** "ClickUp MCP Not Connected - Setup required"
- ⚠️ **Auth Failed:** "Authentication Issue - API key invalid or expired"
- ⚠️ **Access Denied:** "Permission Issue - Insufficient workspace access"

**Connection Protocol:**
1. Check MCP server status
2. Run test query (`get_workspace_hierarchy`)
3. Verify API key authentication
4. Check workspace access permissions
5. Proceed with operations only if all checks pass

**Connection States & Actions:**
- **Connected:** All systems operational → Proceed with operations
- **Disconnected:** No MCP access → Restart Claude Desktop / Check config
- **Auth Failed:** API key issue → Regenerate API key in ClickUp settings
- **Access Denied:** Permission issue → Verify workspace access rights

### Installation & Setup

**Quick Setup:**
1. Install: `npm install -g @taazkareem/clickup-mcp-server`
2. Generate API key in ClickUp Settings → Apps
3. Configure in MCP client with `CLICKUP_API_KEY` environment variable
4. Verify connection using `get_workspace_hierarchy` tool

---

<a id="2-core-capabilities"></a>

## 2. 🛠️ CORE CAPABILITIES

### Available Operations

**Note:** SYNC thinking methodology and conversation flows are defined in SYNC Thinking Framework and Interactive Intelligence.

```yaml
task_operations:
  tools: [create_task, update_task, create_bulk_tasks, get_workspace_tasks]
  requires: "API key"
  
hierarchy_operations:
  tools: [create_list, create_folder, create_list_in_folder, update_list, delete_list, get_workspace_hierarchy]
  requires: "API key"
  
time_tracking_operations:
  tools: [start_time_tracking, stop_time_tracking, add_time_entry, get_task_time_entries, get_current_time_entry]
  requires: "API key"
  
collaboration_operations:
  tools: [create_task_comment, get_task_comments, attach_task_file, add_tag_to_task, remove_tag_from_task, get_space_tags]
  requires: "API key"
  
document_operations:
  tools: [create_document, create_document_page, update_document_page, list_documents]
  requires: "API key"
```

### What You CAN Do ✅

**Task Operations:**
- Create individual tasks with full configuration
- Update existing task properties
- Create multiple tasks efficiently via bulk operations
- Search and filter tasks across workspace
- Manage priorities, statuses, and assignments
- Configure custom fields at list level

**Hierarchy Operations:**
- Create folders for project grouping
- Create lists within spaces or folders
- Build hierarchical structures (Space → Folder → List)
- Manage list configurations and settings
- Retrieve complete workspace structure
- Update and delete organizational elements

**Time Tracking Operations:**
- Start/stop timers on specific tasks
- Add manual time entries retroactively
- Retrieve time logs for tasks and reporting
- Track billable hours and descriptions
- Monitor currently running timers

**Collaboration Operations:**
- Add comments to tasks for discussions
- Attach files via URL or base64 encoding
- Manage tags for categorization
- Assign tasks to team members
- Retrieve space-level tag collections

### What You CANNOT Do ❌

**File Upload Limitation:**
- Direct upload supported via base64 (10MB limit)
- **Alternative:** Use external URLs for larger files
- Recommended services: Cloudinary, Amazon S3, Imgur

**Connection Requirements:**
- Cannot work without MCP connection verification
- Connection check must ALWAYS be performed first
- All operations require active MCP session

**Other Restrictions:**
- Valid ClickUp API key required
- Workspace access permissions needed
- Respect ClickUp API rate limits
- Cannot modify locked or archived items

---

<a id="3-format-support"></a>

## 3. 📊 FORMAT SUPPORT

### Custom Field Types

```yaml
field_types:
  drop_down:
    type: "Single selection dropdown"
    value: "option_id (UUID)"
  
  short_text:
    type: "Text input (single line)"
    value: "String (max 255 chars)"
  
  number:
    type: "Numeric value"
    value: "Number"
  
  checkbox:
    type: "Boolean toggle"
    value: "Boolean"
  
  date:
    type: "Date/timestamp"
    value: "Unix timestamp (milliseconds)"
  
  user:
    type: "User assignment"
    value: "user_id (number)"
  
  url:
    type: "Web link"
    value: "Valid URL string"

usage_notes:
  - "Custom fields configured at list level"
  - "All tasks in list inherit same fields"
  - "field_id must exist before use"
  - "Batch operations fully support custom fields"
```

### Priority & Status Values

```yaml
priority:
  1: "Urgent (highest)"
  2: "High"
  3: "Normal (default)"
  4: "Low"

status:
  type: "String (case-sensitive)"
  scope: "List-specific"
  common: ["open", "in progress", "review", "blocked", "done", "closed"]
  note: "Exact names vary by list configuration"

assignees:
  type: "Array of user IDs"
  format: "[183, 456, 789]"
  multiple: true
```

### Date & Time Formats

```yaml
due_dates:
  formats:
    - "Natural language: 'tomorrow', 'next Friday'"
    - "ISO 8601: '2025-01-15T14:30:00Z'"

time_entries:
  start: "Natural language or Unix timestamp"
  duration: "'Xh Ym' or 'Xm' format"
  examples:
    - "Start: '9am today', Duration: '2h 30m'"
    - "Start: '1234567890000', Duration: '150m'"
```

### File Attachments

```yaml
url_upload:
  parameter: "file_url"
  format: "Valid HTTP/HTTPS URL"
  auth: "Optional auth_header for protected URLs"

base64_upload:
  parameter: "file_data"
  format: "Base64 encoded string"
  required: "file_name parameter"
  limit: "10MB"

supported_types:
  - "Images: JPEG, PNG, GIF, WebP"
  - "Documents: PDF, DOCX, XLSX, PPTX"
  - "Archives: ZIP, RAR"
  - "Code files: All text formats"
```

---

<a id="4-task-workspace-operations"></a>

## 4. ✅ TASK & WORKSPACE OPERATIONS

### Create Task

```yaml
operation: "create_task"
purpose: "Create single task with full configuration"

required:
  name: "Task title"
  list_id_or_name: "listId (UUID) or listName (with spaceName)"

optional:
  description: "Task description (Markdown supported)"
  assignees: "Array of user IDs"
  priority: "1-4 (1=urgent, 4=low)"
  due_date: "Natural language or timestamp"
  status: "List-specific status string"
  tags: "Array of tag names"
  custom_fields: "Array of field objects"

example:
  name: "Implement login feature"
  listId: "abc123xyz"
  description: "Add OAuth authentication"
  assignees: [183]
  priority: 2
  due_date: "tomorrow 5pm"
  tags: ["feature", "security"]
```

### Update Task

```yaml
operation: "update_task"
purpose: "Modify existing task properties"

task_identification:
  - "taskId: UUID or custom ID (e.g., 'DEV-123')"
  - "taskName + listName combination"

updatable_fields:
  - name, description, status, priority
  - due_date, assignees, custom_fields

update_behavior:
  - "Only specified fields updated"
  - "Omitted fields remain unchanged"
  - "assignees array replaces (not appends)"
```

### Bulk Task Creation

```yaml
operation: "create_bulk_tasks"
purpose: "Create multiple tasks efficiently"

required:
  list_identifier: "listId or listName"
  tasks: "Array of task objects"

batch_options:
  batch_size: "Tasks per batch (default: 10)"
  concurrency: "Parallel operations (default: 3)"
  continue_on_error: "Continue if one fails (default: true)"

performance:
  recommended_batch: 10
  max_concurrent: 5
  rate_limit_aware: true
```

### Workspace Hierarchy

```yaml
get_workspace_hierarchy:
  purpose: "Retrieve complete workspace structure"
  parameters: "None"
  
  structure:
    spaces:
      - folders:
          - lists:
              - task_count
      - lists: "Folderless lists"
  
  use_cases:
    - "Navigation and discovery"
    - "Validating IDs before operations"
    - "Building UI representations"
  
  caching: "Cache hierarchy for session"
```

### Create List & Folder

```yaml
create_list:
  purpose: "Create new list in space"
  required:
    name: "List name"
    space_identifier: "spaceId or spaceName"
  optional:
    content: "List description"
    status: "Default status"
    priority: "Default priority"

create_folder:
  purpose: "Organize lists within space"
  required:
    name: "Folder name"
    space_identifier: "spaceId or spaceName"
  optional:
    override_statuses: "Use custom statuses (boolean)"

create_list_in_folder:
  purpose: "Add list to existing folder"
  required:
    name: "List name"
    folder_identifier: "folderId or folderName + spaceName"
```

### List Management

```yaml
update_list:
  parameters: [list_identifier, name, content, status]

delete_list:
  warning: "PERMANENT - Cannot be undone"
  parameters: [list_identifier]
  impact:
    - "All tasks moved to trash"
    - "Custom fields configuration lost"
    - "Time entries preserved in history"
```

### Tag Management

```yaml
get_space_tags:
  purpose: "List available tags in space"
  parameters: "spaceId or spaceName"

add_tag_to_task:
  parameters: [taskId, tagName]
  note: "Tag must exist in space first"

remove_tag_from_task:
  parameters: [taskId, tagName]

best_practices:
  - "Create tags at space level first"
  - "Use consistent naming conventions"
  - "Case-sensitive matching"
```

---

<a id="5-time-tracking-collaboration"></a>

## 5. ⏱️ TIME TRACKING & COLLABORATION

### Time Tracking Operations

```yaml
start_time_tracking:
  purpose: "Begin timer on task"
  constraint: "Only one active timer per user"
  required: "taskId or taskName"
  optional: [description, billable, tags]

stop_time_tracking:
  purpose: "Stop currently running timer"
  optional: [description, tags]
  response: "Completed time entry with duration"

add_time_entry:
  purpose: "Add time entry without timer"
  required: [taskId, start, duration]
  duration_formats: ["'Xh Ym'", "'Xm'"]
  optional: [description, billable, tags]

get_task_time_entries:
  purpose: "Retrieve all time entries for task"
  parameters: [taskId, start_date, end_date]

get_current_time_entry:
  purpose: "Get currently running timer"
  parameters: "None"
  returns: "Active time entry or null"
```

### Document Operations

```yaml
create_document:
  required:
    name: "Document name"
    parent:
      id: "Parent container ID"
      type: "4=space, 5=folder, 6=list"
  optional: [visibility, create_page]

create_document_page:
  required: [document_id, name]
  optional: [content, parent_page_id, sub_title]

update_document_page:
  parameters:
    document_id: "Document ID"
    page_id: "Page ID"
    name: "New title"
    content: "New content"
    content_edit_mode: "'replace' | 'append' | 'prepend'"
    content_format: "'text/md' | 'text/plain'"

list_documents:
  parameters:
    parent_id: "Container ID"
    parent_type: "'SPACE' | 'FOLDER' | 'LIST'"
    archived: "Include archived (boolean)"
```

### Comments & Attachments

```yaml
create_task_comment:
  required: [taskId, commentText]
  optional: [notify_all, assignee]

get_task_comments:
  parameters: [taskId, start, start_id]

attach_task_file:
  required: "taskId"
  methods:
    url_upload: [file_url, auth_header]
    data_upload: [file_data, file_name]
  size_limit: "10MB for base64"
```

---

<a id="6-limitations"></a>

## 6. ⚠️ LIMITATIONS

### Critical Limitations

```yaml
custom_script_generation:
  restriction: "NOT APPLICABLE"
  note: "MCP operations only - no custom scripts"
  native_alternatives:
    - "Native MCP task management"
    - "Native MCP workspace structure"
    - "Native MCP timers and entries"

file_handling:
  direct_upload:
    supported: true
    method: "Base64 encoding"
    limit: "10MB"
  url_upload:
    supported: true
    method: "External URL reference"

connection_requirements:
  dependencies:
    - "MCP server must be connected"
    - "API key must be valid"
    - "Test query must pass (get_workspace_hierarchy)"
    - "Workspace access permissions required"
  enforcement: "Cannot proceed without these (ALWAYS FIRST)"

rate_limiting:
  api_calls: "100 per minute (typical)"
  bulk_operations: "10 tasks per batch (recommended)"
  concurrent_operations: "3 parallel (recommended)"
  enforcement: "Automatic throttling and retry"

custom_field_limitations:
  problem: "Cannot create custom fields via MCP"
  solution: "Create in ClickUp UI first, then reference by ID"

deletion_operations:
  list_deletion:
    permanent: true
    no_undo: true
    recommendation: "Archive instead of delete when possible"
```

### Search & Filtering

```yaml
workspace_search:
  scope: "Current workspace only"
  cross_workspace: false
  filter_combinations: "AND logic (all filters must match)"
  pagination: "Required for large result sets"

tag_operations:
  tag_creation: "Not supported via MCP"
  tag_usage: "Must exist in space first"
  tag_matching: "Case-sensitive"

status_filtering:
  list_specific: true
  custom_statuses: "Exact name matching required"
```

### Performance Considerations

```yaml
bulk_operations:
  recommended: "10-50 tasks"
  concurrent: "Max 3-5 recommended"
  performance:
    small: "< 10 items: 2-5s"
    medium: "10-50 items: 5-15s"
    large: "> 50 items: 15-30s"

hierarchy_operations:
  small_workspace: "1-2s"
  medium_workspace: "2-3s"
  large_workspace: "3-5s"
  recommendation: "Cache and reuse"

search_operations:
  simple_search: "< 2s"
  complex_filters: "2-4s"
  large_result_set: "4-8s"
  optimization: "Use specific filters"
```

### Data Consistency

```yaml
real_time_updates:
  task_changes: "Reflect immediately"
  workspace_structure: "May have brief delay"
  time_entries: "Immediate recording"

data_preservation:
  deleted_tasks: "Moved to trash, recoverable"
  deleted_lists: "Permanent deletion"
  time_entries: "Preserved even if task deleted"
  custom_fields: "Lost if list deleted"
```

---

<a id="7-quick-reference"></a>

## 7. 🏎️ QUICK REFERENCE

### MCP Operations Summary

**Key operations (45+ tools total):**

```yaml
connection_and_hierarchy:
  get_workspace_hierarchy: "Connection check, retrieve structure"
  create_folder: "Create organizational folder [name, spaceId]"
  create_list: "Create list in space [name, spaceId]"
  create_list_in_folder: "Create list in folder [name, folderId]"

task_operations:
  create_task: "Create single task [name, listId, assignees, priority]"
  update_task: "Update task properties [taskId, field_updates]"
  create_bulk_tasks: "Create multiple tasks [listId, tasks_array]"
  get_workspace_tasks: "Search and filter tasks [filters]"

time_tracking:
  start_time_tracking: "Start timer [taskId, description]"
  stop_time_tracking: "Stop active timer"
  add_time_entry: "Manual time logging [taskId, start, duration]"
  get_task_time_entries: "Retrieve time logs [taskId]"

collaboration:
  create_task_comment: "Add comment [taskId, commentText]"
  attach_task_file: "File attachment [taskId, file_url/file_data]"
  add_tag_to_task: "Add tag [taskId, tagName]"
  get_space_tags: "List space tags [spaceId]"

documents:
  create_document: "Document creation [name, parent]"
  create_document_page: "Page creation [document_id, name]"
  update_document_page: "Page updates [document_id, page_id, content]"
```

### Integration References

```yaml
official_documentation:
  clickup_mcp_github: "https://github.com/taazkareem/clickup-mcp-server"
  npm_package: "https://www.npmjs.com/package/@taazkareem/clickup-mcp-server"
  clickup_api_docs: "https://clickup.com/api"

related_documents:
  sync_thinking_framework:
    file: "ClickUp - SYNC Thinking Framework"
    purpose: "4-phase methodology (Survey → Yield → Navigate → Create)"
    key_concepts: ["Survey", "Yield", "Navigate", "Create"]
  
  interactive_intelligence:
    file: "ClickUp - Interactive Intelligence"
    purpose: "Conversation flows and interaction patterns"
    includes: ["Conversation Architecture", "Response Templates", "REPAIR protocol"]
```

### Decision Tree

```
Request received
    ↓
Verify MCP connection (ALWAYS FIRST) → Failed → Apply REPAIR
    ↓ Success
Check operation type:
    ↓
Task management? → Yes → Task Operations
    ↓ No
Workspace structure? → Yes → Hierarchy Operations
    ↓ No
Time tracking? → Yes → Time Tracking Operations
    ↓ No
Collaboration? → Yes → Collaboration Operations
    ↓ No
Ask for clarification
```

### Capability Check

```python
can_do = {
    'connection_required': True,  # ALWAYS FIRST
    'task_create': True,
    'task_update': True,
    'bulk_tasks': True,
    'folders': True,
    'lists': True,
    'time_tracking': True,
    'comments': True,
    'tags': True,
    'custom_fields': True,  # Must pre-exist
    'file_attachments': True,
    'direct_upload': True,  # Base64, 10MB limit
    'url_upload': True,
    'custom_scripts': False,  # N/A
    'native_operations': True  # ALWAYS
}
```

### Pre-Operation Protocol

```markdown
Every Operation Requires:

1. Connection verification ✓ (ALWAYS FIRST)
2. Test query successful ✓ (get_workspace_hierarchy)
3. Native approach confirmed ✓ (MCP operations only)
4. Workspace access verified ✓
5. APIs identified ✓
6. Ready to execute ✓
```

### Critical Rules Summary

```markdown
THE FIVE ABSOLUTES:

1. Connection verified before EVERY operation (ALWAYS FIRST)
2. Native MCP operations ONLY - no custom scripts (N/A)
3. Test query must pass before proceeding
4. API key must be valid and have proper permissions
5. REPAIR protocol for all errors
```

### Performance Characteristics

```yaml
benchmarks:
  connection_check: "1-3 seconds"
  task_create: "< 1 second"
  bulk_10_tasks: "2-5 seconds"
  bulk_50_tasks: "5-15 seconds"
  folder_create: "< 1 second"
  list_create: "< 1 second"
  time_tracking_start: "< 1 second"
  comment_create: "< 1 second"

characteristics:
  - "API key authentication"
  - "Rate limited (100/min typical)"
  - "Native MCP operations"
```

---

*This document focuses exclusively on ClickUp MCP server capabilities and technical specifications. For SYNC thinking methodology (Survey → Yield → Navigate → Create), see ClickUp - SYNC Thinking Framework. For conversation flows and error handling (REPAIR protocol), see ClickUp - Interactive Intelligence.*
