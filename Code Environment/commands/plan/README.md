# Plan Commands Overview

Comprehensive planning commands using **hybrid orchestrator + explorer** architectures via OpenCode Copilot.

---

## Available Commands

| Command | Orchestrator | Explorers | Best For |
|---------|--------------|-----------|----------|
| `/plan:with_claude` | Claude | Claude agents | General purpose, proven quality |
| `/plan:with_gpt` | **GPT** | **Sonnet agents** | GPT planning + fast exploration |
| `/plan:with_gemini` | **Gemini 3.0 pro** | **Sonnet agents** | Web research + multimodal + fast exploration |

---

## Quick Decision Guide

### Strategy Selection

**Use `/plan:with_claude` when:**
- Default choice for most planning tasks
- Want proven Claude quality throughout
- Single-model consistency preferred
- No need for alternative perspectives

**Use `/plan:with_gpt` when:**
- Want **GPT's planning and synthesis perspective**
- Need **fast, cost-effective exploration** (Sonnet)
- Comparing different AI planning approaches
- GPT may excel at specific code understanding tasks
- Have Copilot configured for GPT access

**Use `/plan:with_gemini` when:**
- Want **Gemini's planning perspective**
- Implementing **newer technologies** (web research helps)
- Need **current best practices** via Google Search
- **Multimodal understanding** might provide insights
- Need **fast, cost-effective exploration** (Sonnet)
- Comparing different AI planning approaches
- Have Copilot configured for Gemini access

---

## Architecture Comparison (v3.0 Hybrid)

### with_claude (Claude throughout)

```
Orchestrator: Claude
   ↓ spawns 4 parallel agents via Task tool
Explorers: Claude agents × 4 (Architecture, Feature, Dependency, Test)
   ↓ return findings (hypotheses, file paths, patterns)
Verification: Claude reads files, verifies hypotheses
   ↓
Plan Creation: Claude synthesizes plan.md
```

**Characteristics:**
- Single-model consistency
- Proven exploration quality
- Fast parallel agent spawning
- 35-75 seconds typical duration
- Straightforward architecture

---

### with_gpt (Hybrid: GPT orchestrator + Sonnet explorers)

```
Orchestrator: GPT via Copilot
   ↓ spawns 4 Sonnet agents in parallel via Task tool
Explorers: Sonnet agents × 4 (Architecture, Feature, Dependency, Test)
   ↓ return findings (hypotheses, file paths, patterns)
   ↓ FALLBACK if Sonnet unavailable:
   ├─ Try GPT agents
   ├─ Try other available models
   └─ GPT self-exploration (inline)
Verification: GPT reads files, verifies hypotheses
   ↓
Plan Creation: GPT synthesizes plan.md with GPT perspective
```

**Characteristics:**
- **Hybrid architecture**: GPT planning + Sonnet exploration
- **GPT orchestration**: Task understanding, verification, synthesis
- **Sonnet exploration**: Fast, cost-effective parallel discovery
- **Intelligent fallback**: Adapts to available models
- **Cost optimized**: Expensive GPT for high-value, cheap Sonnet for exploration
- 40-85 seconds typical duration

**Benefits:**
- GPT's unique planning and synthesis perspective
- Fast parallel exploration (Sonnet)
- Best of both models' strengths
- Graceful degradation if Sonnet unavailable

---

### with_gemini (Hybrid: Gemini orchestrator + Sonnet explorers)

```
Orchestrator: Gemini 3.0 pro via Copilot
   ↓ spawns 4 Sonnet agents in parallel via Task tool
   ↓ (+ optional web research in Phase 1)
Explorers: Sonnet agents × 4 (Architecture, Feature, Dependency, Test)
   ↓ return findings (hypotheses, file paths, patterns)
   ↓ FALLBACK if Sonnet unavailable:
   ├─ Try Gemini agents
   ├─ Try other available models
   └─ Gemini self-exploration (inline + web research)
Verification: Gemini reads files, verifies hypotheses (+ web cross-reference)
   ↓
Plan Creation: Gemini synthesizes plan.md with current best practices
```

**Characteristics:**
- **Hybrid architecture**: Gemini planning + Sonnet exploration
- **Gemini orchestration**: Task understanding, verification, synthesis, **web research**
- **Sonnet exploration**: Fast, cost-effective parallel discovery
- **Web research**: Google Search for current practices (if enabled)
- **Multimodal**: Enhanced understanding capabilities
- **Intelligent fallback**: Adapts to available models
- **Cost optimized**: Expensive Gemini for high-value, cheap Sonnet for exploration
- 45-90 seconds typical duration (may be longer with web research)

**Benefits:**
- Gemini's unique planning and multimodal perspective
- **Web research** for current best practices and documentation
- Fast parallel exploration (Sonnet)
- External knowledge augments code analysis
- Graceful degradation if Sonnet unavailable

---

## Common Features

All commands share these capabilities:

### 1. Mode Detection
- Automatic LOC estimation from task description
- Simple mode (<500 LOC) → single plan.md file
- Complex mode (≥500 LOC) → multi-file structure (future)
- Manual override: append `mode:simple` or `mode:complex`

### 2. Spec Folder Integration
- Works with spec folder system
- Respects `.spec-active` markers
- Integrates with workflows-save-context
- Compatible with `/spec_kit:implement`

### 3. Exploration Phases (8-phase workflow)
1. **Task Understanding**: Parse input, validate description (orchestrator model)
2. **Spec Folder Setup**: Determine working folder
3. **Context Loading**: Load previous session memory (if exists)
4. **Parallel Exploration**: 4 specialized explorers (model varies by command)
5. **Hypothesis Verification**: Read files, verify findings (orchestrator model)
6. **Plan Creation**: Template-based generation (orchestrator model)
7. **User Review**: Wait for confirmation
8. **Context Persistence**: Save session memory

### 4. Quality Guarantees
- All hypotheses verified by reading actual code
- File paths include line numbers
- No placeholder text in final plans
- Risk assessment documented
- Template compliance validated

### 5. Intelligent Fallback (GPT & Gemini)
- **Primary**: Sonnet agents (fast, cheap)
- **Fallback 1**: Orchestrator's model as agents
- **Fallback 2**: Other available models
- **Fallback 3**: Self-exploration (inline)
- Always produces a plan

---

## Usage Examples

### Basic Planning
```bash
# Default (Claude throughout)
/plan:with_claude Add user authentication with OAuth2

# GPT orchestrator + Sonnet explorers
/plan:with_gpt Add user authentication with OAuth2

# Gemini orchestrator + Sonnet explorers (+ web research)
/plan:with_gemini Add user authentication with OAuth2
```

### Mode Override
```bash
# Force simple mode despite LOC estimate
/plan:with_claude "Large refactor (800 LOC)" mode:simple

# Explicit complex mode (future)
/plan:with_gemini "System redesign" mode:complex
```

### Comparison Strategy
For critical features, consider running multiple commands:
```bash
# Get Claude perspective (single model)
/plan:with_claude Implement real-time collaboration

# Compare with GPT perspective (hybrid)
/plan:with_gpt Implement real-time collaboration

# Validate with Gemini (hybrid + web research)
/plan:with_gemini Implement real-time collaboration
```

Then review all three plans to identify:
- Differences in approach
- Overlooked integration points
- Alternative implementation strategies
- Current best practices (Gemini with web search)

---

## Installation Requirements

### OpenCode (with_claude)
**Requirements:**
- OpenCode CLI
- Task tool support

**Validation:**
```bash
# Should work in OpenCode environment
/plan:with_claude test task
```

### OpenCode (with_gpt)
**Requirements:**
- OpenCode CLI
- OpenCode Copilot integration enabled
- GitHub Copilot subscription (for GPT model access)
- Proper model routing configuration in OpenCode
- Ideally, access to both GPT and Claude models (for Sonnet explorers)

**Validation:**
```bash
# Verify Copilot integration and GPT model access
# Test with simple task
/plan:with_gpt test task
```

### OpenCode (with_gemini)
**Requirements:**
- OpenCode CLI
- OpenCode Copilot integration enabled
- Copilot subscription with Gemini model access
- Proper model routing configuration in OpenCode
- Ideally, access to both Gemini and Claude models (for Sonnet explorers)
- Optional: Google Search integration for web research

**Validation:**
```bash
# Verify Copilot integration and Gemini model access
# Test with simple task
/plan:with_gemini test task
```

---

## Performance Benchmarks

| Command | Orchestrator | Explorers | Typical Duration | Maximum |
|---------|--------------|-----------|-----------------|---------|
| with_claude | Claude | Claude | 35-75 seconds | 90 seconds |
| with_gpt | GPT | Sonnet | 40-85 seconds | 100 seconds |
| with_gemini | Gemini 3.0 pro | Sonnet | 45-90 seconds | 120 seconds |

**Factors affecting duration:**
- Codebase size
- Number of files to explore
- Model response times via Copilot
- Web research depth (Gemini, if enabled)
- Fallback tier used (Sonnet faster than self-exploration)

---

## Troubleshooting

### Error: GPT model not accessible via Copilot
**Problem:** `with_gpt` command fails to spawn GPT orchestrator

**Solutions:**
1. Verify OpenCode Copilot integration is enabled
2. Check GitHub Copilot subscription includes GPT model access
3. Review model routing configuration in OpenCode
4. Use `/plan:with_claude` as fallback

### Error: Gemini model not accessible via Copilot
**Problem:** `with_gemini` command fails to spawn Gemini orchestrator

**Solutions:**
1. Verify OpenCode Copilot integration is enabled
2. Check Copilot subscription includes Gemini model access
3. Review model routing configuration in OpenCode
4. Use `/plan:with_claude` as fallback

### Error: Sonnet agents not spawning (GPT/Gemini commands)
**Problem:** Hybrid commands can't spawn Sonnet explorers

**Expected Behavior:** Automatic fallback to orchestrator's model
**Solutions:**
1. Command should automatically try GPT/Gemini agents
2. If that fails, tries other available models
3. If all fail, orchestrator performs self-exploration
4. Check logs to see which fallback tier was used
5. If persistent, may indicate Copilot routing issues

### Exploration timeout
**Problem:** Agents exceed timeout

**Solutions:**
1. Command automatically uses partial results
2. Gaps documented in plan
3. Manual exploration recommended for missing areas

### Task tool unavailable
**Problem:** Cannot spawn exploration agents

**Solutions:**
1. Command falls back to manual exploration
2. Use Glob/Grep directly
3. Inline planning without agents

---

## File Structure

```
.opencode/command/plan/         # OpenCode
├── README.md                   # This file
├── with_claude.md              # Claude orchestrator + Claude explorers
├── with_gpt.md                 # GPT orchestrator + Sonnet explorers (hybrid)
├── with_gemini.md              # Gemini orchestrator + Sonnet explorers (hybrid)
└── assets/
    ├── simple_mode.yaml        # Simple mode workflow
    ├── complex_mode.yaml       # Complex mode workflow (stub)
    ├── base_phases.yaml        # Shared phases 1-3, 7-8
    └── exploration.yaml        # Phases 4-5
```

---

## Future Enhancements

### Planned Features
1. **Complex Mode Implementation**
   - Multi-file plan/ directory structure
   - Manifest.json for navigation
   - Section-specific files
   - Target: Features >500 LOC

2. **Adaptive Fallback**
   - Learn which models are typically available
   - Optimize fallback order based on success rates
   - Cache model availability per session
   - Reduce fallback latency

3. **Multi-Model Synthesis**
   - Run GPT + Gemini in parallel
   - Aggregate findings from both perspectives
   - Identify consensus and conflicts
   - Best-of-all-worlds planning

4. **Enhanced Web Research Integration**
   - Configurable web research depth
   - Security advisory checking
   - Framework version compatibility checks
   - Documentation freshness validation

---

## Support

**Issues:**
- Model errors: Check Copilot configuration and subscription
- Timeout issues: May need to adjust task complexity estimation
- Agent spawning: Verify Copilot integration is working
- Sonnet unavailable: Check fallback behavior in logs

**Best Practices:**
1. Start with default (`/plan:with_claude`)
2. Use hybrid commands (GPT/Gemini) for alternative perspectives
3. Combine findings when critical decisions needed
4. Always review and edit generated plans
5. Save session memory for future reference
6. Check logs if fallback was used (may indicate Sonnet access issues)

---

**Last Updated:** 2025-11-29
**Version:** 3.0.0 (Hybrid Architecture)
**Compatibility:** OpenCode with Copilot integration

**Key Changes from v2.0:**
- **Renamed** `with_codex` to `with_gpt` for broader GPT model compatibility
- **Hybrid architecture**: GPT/Gemini orchestrators now use Sonnet explorers
- **Intelligent fallback**: Multi-tier fallback strategy for reliability
- **Cost optimization**: Expensive models for planning, cheap Sonnet for exploration
- **Web research**: Gemini can augment with Google Search (if enabled)
