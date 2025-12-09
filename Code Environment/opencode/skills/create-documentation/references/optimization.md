# Optimization - C7Score Metrics and Transformation Patterns

Comprehensive reference for C7Score metrics, scoring weights, and 16 transformation patterns for converting documentation into AI-friendly question-answering format.

---

## 1. 📖 INTRODUCTION & PURPOSE

### What Is Optimization?

Optimization transforms documentation from reference-style to question-answering format, making it highly AI-friendly through systematic application of 16 proven transformation patterns.

**Core Purpose**:
- **AI-friendliness** - Convert API docs to usage examples
- **Question coverage** - Answer 15-20 common developer questions
- **Code completeness** - Runnable, standalone examples with imports
- **Metadata removal** - Strip non-instructional content

**Progressive Disclosure Context**:
```
Level 1: SKILL.md metadata (name + description)
         └─ Always in context (~100 words)
            ↓
Level 2: SKILL.md body
         └─ When skill triggers (<5k words)
            ↓
Level 3: Reference files (this document)
         └─ Loaded as needed for pattern details
```

This reference file provides Level 3 deep-dive technical guidance on C7Score metrics and transformation patterns.

### Core Principle

**"Answer questions, don't document APIs"** - Developers ask "How do I...?", not "What is the signature of...?". Optimize for the questions that matter.

---

## 2. 📊 C7SCORE METRICS

**Total score**: 0-100 (weighted average across 5 metrics)

| Metric | Weight | Purpose | Target |
|--------|--------|---------|--------|
| **Question-Snippet Matching** | 80% | How well docs answer developer questions | 15-20 questions answered |
| **LLM Evaluation** | 10% | AI assistant friendliness | Clear, concise, actionable |
| **Formatting** | 5% | Consistent code blocks and structure | Valid syntax, language tags |
| **Metadata Removal** | 2.5% | Remove non-instructional content | No licenses, citations, trees |
| **Initialization** | 2.5% | Combine imports with usage | No import-only snippets |

**Scoring rubric**:
- **90-100**: Excellent - Comprehensive, question-focused, AI-friendly
- **80-89**: Good - Minor gaps or formatting issues
- **70-79**: Acceptable - Needs more examples or has duplicates
- **60-69**: Fair - Significant gaps in coverage
- **<60**: Poor - Major restructuring required

**Optimization priority**: Focus 80% effort on question-snippet matching, 20% on other metrics.

---

## 3. 🔍 ANALYSIS WORKFLOW

**Step 1: Audit Current State**
- Count question-answering snippets vs API-only snippets
- Identify import-only snippets (no usage)
- Find metadata snippets (licenses, citations, directory trees)
- Detect duplicates or very similar content

**Step 2: Generate Questions** (15-20 common developer questions)
- How do I install and set up [library]?
- How do I [main feature]?
- How do I handle errors?
- How do I configure [common setting]?
- How do I integrate with [use case]?

**Step 3: Map Questions to Snippets**
- Which questions are well-answered?
- Which have weak or missing answers?
- Which snippets don't answer important questions?

**Step 4: Apply Transformation Patterns** (see below)

---

## 4. 🔄 TRANSFORMATION PATTERNS

### Pattern 1: API Reference → Usage Example

**Impact**: +15-20 points (high)
**Effort**: Medium

**Before**:
```
Client.authenticate(api_key: str) -> bool
Parameters: api_key (str)
Returns: bool
```

**After**:
```
Authenticating Your Client
```python
from library import Client

client = Client(api_key="your_key")
if client.authenticate():
    print("Authenticated!")
```
```

### Pattern 2: Import-Only → Complete Setup

**Impact**: +10-15 points (high)
**Effort**: Low

**Before**:
```python
from library import Client, Query
```

**After**:
```
Quick Start
```python
# Install: pip install library
from library import Client

client = Client(api_key="key")
response = client.query("SELECT * FROM data")
for row in response:
    print(row)
```
```

### Pattern 3: Multiple Small → One Comprehensive

**Impact**: +10 points (medium)
**Effort**: Medium

**Before** (3 separate snippets):
```python
client = Client()
client.connect()
client.query("SELECT *")
```

**After** (1 complete workflow):
```python
from library import Client

# Initialize and connect
client = Client(api_key="key", region="us-west-2")
client.connect()

# Execute query
result = client.query("SELECT * FROM users")
for row in result:
    print(row)

# Close connection
client.close()
```

### Pattern 4: Remove Metadata

**Impact**: +5 points (low)
**Effort**: Low

**Delete entirely**:
- Project directory structures
- License text (link to LICENSE file instead)
- Academic citations
- Contributor lists (move to CONTRIBUTORS.md)

### Pattern 5: Add Error Handling

**Impact**: +8-12 points (medium)
**Effort**: Medium

**Enhance existing examples**:
```python
try:
    client.connect()
    results = client.query("SELECT *")
except TimeoutError:
    print("Query timed out")
except AuthError:
    print("Check API key")
finally:
    client.close()
```

### Pattern 6: Combine Installation + First Usage

**Impact**: +10 points (high)
**Effort**: Low

**Never show installation alone** - always include immediate usage:
```python
# Install: pip install library
from library import Client

# First request
client = Client(api_key="key")
result = client.get_data()
print(result)
```

### Pattern 7: Add Configuration Examples

**Impact**: +6-10 points (medium)
**Effort**: Low

**Show common config scenarios**:
```python
# Development config
client = Client(
    api_key="dev_key",
    environment="staging",
    debug=True
)

# Production config
client = Client(
    api_key="prod_key",
    environment="production",
    timeout=30,
    retries=3
)
```

### Pattern 8: Demonstrate OAuth/Auth Patterns

**Impact**: +8-12 points (high for auth-heavy libs)
**Effort**: High

**Complete auth flow**:
```python
# OAuth flow
client = Client(client_id="id", client_secret="secret")
auth_url = client.get_auth_url("callback_url")
# User visits auth_url
tokens = client.exchange_code(auth_code)
client.connect()
```

### Pattern 9: Show Batch/Bulk Operations

**Impact**: +6-8 points (medium)
**Effort**: Medium

**Performance-optimized patterns**:
```python
# Batch insert for better performance
users = [
    {"name": "Alice", "email": "alice@ex.com"},
    {"name": "Bob", "email": "bob@ex.com"}
]
result = client.batch_insert("users", users)
print(f"Inserted {result.count} users")
```

### Pattern 10: Add Testing Examples

**Impact**: +5-8 points (low-medium)
**Effort**: Medium

**Show how to test code using library**:
```python
import unittest
from library import Client

class TestClient(unittest.TestCase):
    def test_connection(self):
        client = Client(api_key="test_key")
        self.assertTrue(client.connect())
```

### Pattern 11: Provide Advanced Use Cases

**Impact**: +8-15 points (high)
**Effort**: High

**Complex real-world scenarios**:
```python
# Advanced: Streaming large datasets
client = Client(api_key="key")
for chunk in client.query_stream("SELECT * FROM large_table"):
    process(chunk)
    # Process incrementally, avoid memory issues
```

### Pattern 12: Add Integration Examples

**Impact**: +8-12 points (medium-high)
**Effort**: Medium

**Show integration with popular tools**:
```python
# Integration with pandas
import pandas as pd
from library import Client

client = Client(api_key="key")
data = client.query("SELECT * FROM users")
df = pd.DataFrame(data)
print(df.head())
```

### Pattern 13: Clarify Common Pitfalls

**Impact**: +5-8 points (medium)
**Effort**: Low

**Prevent common mistakes**:
```python
# Correct: Close connection in finally
try:
    client.connect()
    data = client.query("SELECT *")
finally:
    client.close()

# Wrong: Connection leak if error occurs
client.connect()
data = client.query("SELECT *")
client.close()
```

### Pattern 14: Add Output Examples

**Impact**: +5 points (low)
**Effort**: Low

**Show expected results**:
```python
response = client.get_user(123)
print(response)
# Output: {'id': 123, 'name': 'Alice', 'email': 'alice@example.com'}
```

### Pattern 15: Consolidate Duplicates

**Impact**: +5-10 points (medium)
**Effort**: Low

**Merge similar examples** - if 3 examples show nearly identical patterns, keep 1 comprehensive version.

### Pattern 16: Fix Formatting

**Impact**: +3-5 points (low)
**Effort**: Low

**Ensure all code blocks**:
- Have language tags: ` ```python ` not ` ``` `
- Are syntactically valid
- Include necessary imports
- Use consistent naming conventions

---

## 5. 📖 README OPTIMIZATION STRATEGY

**High Priority Sections**:
1. **Quick Start** - Installation + first usage (Pattern 2, Pattern 6)
2. **Common Use Cases** - Each major feature with complete example (Pattern 1, Pattern 3)
3. **Error Handling** - Realistic error scenarios (Pattern 5)
4. **Configuration** - Common config examples (Pattern 7)

**Medium Priority**:
5. **Advanced Features** - Complex use cases (Pattern 11)
6. **Integration Examples** - Popular tool integrations (Pattern 12)
7. **Testing** - How to test code using library (Pattern 10)

**Low Priority**:
8. **API Reference** - Keep but ensure each method has usage example

**Remove/Minimize**:
- Installation-only snippets (always combine with usage)
- Long feature lists (convert to example-driven)
- Project governance (move to CONTRIBUTING.md)
- Licensing text (link to LICENSE)
- Directory trees (unless essential)
- Academic citations

---

## 6. ✅ QUALITY CHECKLIST

Before finalizing, verify each snippet:

- ✅ **Runnable standalone** - Copy-paste works with minimal setup
- ✅ **Answers a question** - Clearly addresses "how do I..."
- ✅ **Unique content** - No duplication
- ✅ **Proper format** - Title, description, code with language tag
- ✅ **Practical focus** - Real-world usage, not just theory
- ✅ **Complete imports** - All necessary imports included
- ✅ **No metadata** - No licenses, citations, directory trees
- ✅ **Valid syntax** - Code would actually run

**Question coverage matrix** (aim for 15-20):
- [ ] Installation and setup
- [ ] Basic initialization
- [ ] Authentication methods
- [ ] Primary use cases (3-5)
- [ ] Configuration options
- [ ] Error handling
- [ ] Advanced features
- [ ] Integration examples
- [ ] Testing approaches

---

## 7. 🔁 ITERATION PROCESS

1. Run c7score to get baseline
2. Identify lowest-scoring metric
3. Apply targeted patterns for that metric
4. Re-run c7score
5. Repeat until target score reached (typically 85+)

**Metric-specific improvements**:
- **Low question-snippet** (< 60/80): Add Patterns 1, 2, 3, 11
- **Low formatting** (< 4/5): Apply Pattern 16
- **High metadata** (> 0): Apply Pattern 4
- **High initialization** (> 0): Apply Pattern 6
- **Low LLM eval**: Apply Patterns 5, 13, 14

---

## REFERENCES

- Structure rules: [core_standards.md](./core_standards.md)
- Execution workflows: [workflows.md](./workflows.md)
- Quality scoring: [validation.md](./validation.md)
- Quick commands: [quick_reference.md](./quick_reference.md)