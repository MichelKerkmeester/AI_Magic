---
description: Generate comprehensive research documentation for deep technical investigation spanning multiple domains.
---

## Command Purpose: Comprehensive Technical Research

**WHAT IT DOES**: Creates structured documentation for comprehensive technical research—in-depth investigations that span multiple technical areas, integration points, or technologies before committing to implementation.

**WHY IT EXISTS**: Complex features require thorough understanding across multiple domains before implementation. Research documents provide authoritative reference material that guides architecture decisions, implementation approaches, and team alignment.

**WHEN TO USE**: When facing complex technical challenges requiring investigation across 3+ domains: API integrations, data model design, security architecture, performance optimization strategies, or multi-system coordination.

**KEY PRINCIPLE**: Depth and comprehensiveness. Unlike time-boxed spikes, research documents are meant to be thorough and serve as lasting reference material. The goal is to understand deeply and document completely—not to answer a single question quickly.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

The text the user typed after `/speckit.research` in the triggering message **is** the research topic or feature to investigate. Use it as the basis for generating research documentation.

Given that research topic, do this:

1. **Parse Input**:
   - Extract research topic/feature from $ARGUMENTS
   - If empty: ERROR "No research topic provided. Please specify what feature or topic you want to investigate."
   - Identify specific technical domains mentioned
   - Extract any constraints or focus areas mentioned

2. **Setup**:
   - Run `.opencode/speckit/scripts/check-prerequisites.sh --json` from repo root
   - Parse JSON for FEATURE_DIR and AVAILABLE_DOCS
   - Generate short research name from topic (2-4 words, kebab-case)
   - Assign research number: Find highest RESEARCH-### in FEATURE_DIR, increment by 1 (default: RESEARCH-001)
   - Create research file: `FEATURE_DIR/research-[###]-[short-name].md`

3. **Load Template**:
   - Load `.opencode/speckit/templates/research_template.md` as structure reference

4. **Generate Research Document** using template structure:

   a. **Metadata Section (§1)**:
      ```markdown
      # Feature Research: [TOPIC] - Comprehensive Technical Investigation

      Complete research documentation providing in-depth technical analysis, architecture patterns, and implementation guidance.

      ---

      ## 1. METADATA

      - **Research ID**: RESEARCH-[###]
      - **Feature/Spec**: [Link to related spec.md or feature name]
      - **Status**: In Progress
      - **Date Started**: [TODAY - YYYY-MM-DD]
      - **Date Completed**: [Leave blank]
      - **Researcher(s)**: [Extract from context or placeholder]
      - **Reviewers**: [Placeholder]
      - **Last Updated**: [TODAY - YYYY-MM-DD]
      ```

   b. **Investigation Report (§2)**:
      - Request Summary: Extract from input
      - Current Behavior: Analyze existing state if applicable
      - Key Findings: Placeholder for 3-5 findings
      - Recommendations: Primary recommendation + alternatives

   c. **Executive Overview (§3)**:
      - Executive Summary: High-level summary placeholder
      - Architecture Diagram: ASCII diagram placeholder
      - Quick Reference Guide: When to use/not use
      - Research Sources: Empty table for documentation sources

   d. **Core Architecture (§4)**:
      - System Components: Generate 2-3 component templates
      - Data Flow: Flow diagram placeholder
      - Integration Points: External/internal systems
      - Dependencies: Dependency table

   e. **Technical Specifications (§5)**:
      - API Documentation: Endpoint/method templates
      - Attribute Reference: Attribute table
      - Event Contracts: Event templates
      - State Management: State structure and transitions

   f. **Constraints & Limitations (§6)**:
      - Platform Limitations: Placeholder
      - Security Restrictions: Placeholder
      - Performance Boundaries: Placeholder
      - Browser Compatibility: Compatibility matrix
      - Rate Limiting: Rate limit handling

   g. **Integration Patterns (§7)**:
      - Third-Party Service Integration: Service templates
      - Authentication Handling: Auth method placeholder
      - Error Management: Error categories table
      - Retry Strategies: Retry configuration

   h. **Implementation Guide (§8)**:
      - Markup Requirements: HTML structure
      - JavaScript Implementation: Init, core logic, handlers, cleanup
      - CSS Specifications: Required styles, responsive, dark mode
      - Configuration Options: Options table

   i. **Code Examples & Snippets (§9)**:
      - Initialization Patterns: Basic and advanced
      - Helper Functions: Function templates
      - API Usage Examples: Common use cases
      - Edge Case Handling: Edge case solutions

   j. **Testing & Debugging (§10)**:
      - Test Strategies: Unit, integration, E2E
      - Debugging Approaches: Common issues, tools
      - E2E Test Examples: Test templates
      - Diagnostic Tools: Debug mode code

   k. **Performance Optimization (§11)**:
      - Optimization Tactics: Tactic templates
      - Benchmarks: Benchmark table
      - Rate Limiting Implementation: Code placeholder
      - Caching Strategies: Cache levels

   l. **Security Considerations (§12)**:
      - Validation Approach: Input validation
      - Data Protection: Sensitive data handling
      - Spam Prevention: Prevention mechanisms
      - Authentication & Authorization: Auth flow

   m. **Future-Proofing & Maintenance (§13)**:
      - Upgrade Paths: Version migration table
      - Compatibility Matrix: Feature/platform compatibility
      - Decision Trees: Decision placeholders
      - SPA Support: SPA compatibility

   n. **API Reference (§14)**:
      - Attributes Table: Complete attribute reference
      - JavaScript API: Method documentation
      - Events Reference: Events table
      - Cleanup Methods: Cleanup documentation

   o. **Troubleshooting Guide (§15)**:
      - Common Issues: Issue templates with symptoms/causes/solutions
      - Error Messages: Error code table
      - Solutions & Workarounds: Workaround templates

   p. **Acknowledgements (§16)**:
      - Research Contributors: Placeholder
      - Resources & References: Placeholder
      - External Tools & Libraries Used: Placeholder

   q. **Appendix**:
      - Glossary: Term definitions
      - Related Research: Links to related docs
      - Change Log Detail: Detailed history if needed

   r. **Changelog & Updates**:
      - Version History: Version table
      - Recent Updates: Update list

5. **Generate Companion Guidance** (optional):
   - If feature context available (spec.md, plan.md), extract relevant sections
   - Identify related decisions that might inform research
   - Suggest specific focus areas based on feature requirements

6. **Report Completion**:
   ```markdown
   ## Research Document Created

   **Research Details:**
   - Research ID: RESEARCH-[###]
   - Topic: [Research topic]
   - File Path: [Full path to research document]

   **Structure Generated (17 Sections):**
   - Metadata, Investigation Report, Executive Overview
   - Core Architecture, Technical Specifications
   - Constraints & Limitations, Integration Patterns
   - Implementation Guide, Code Examples
   - Testing & Debugging, Performance Optimization
   - Security Considerations, Future-Proofing
   - API Reference, Troubleshooting Guide
   - Acknowledgements, Appendix, Changelog

   **Next Steps:**
   1. Review the generated research document structure
   2. Prioritize sections based on investigation needs
   3. Fill in sections as research progresses
   4. Update findings and recommendations
   5. Consider time-boxed spikes for specific questions:
      - Run `/speckit.research-spike` for focused experiments
   6. Create ADR if major decisions emerge:
      - Run `/speckit.decision` with research findings
   ```

## Key Rules

- **Comprehensive Coverage**: Fill all relevant sections (mark N/A for irrelevant ones)
- **Evidence-Based**: All findings backed by evidence (code, docs, benchmarks)
- **Progressive Disclosure**: Fill sections incrementally as research progresses
- **Cross-Reference**: Link to related spikes, specs, and ADRs
- **Living Document**: Update as understanding evolves
- **Status Updates**: Update status as research progresses (In Progress -> Completed -> Archived)

## Template Compliance

All generated research documents MUST include sections from research_template.md:
- § 1: Metadata
- § 2: Investigation Report
- § 3: Executive Overview
- § 4: Core Architecture
- § 5: Technical Specifications
- § 6: Constraints & Limitations
- § 7: Integration Patterns
- § 8: Implementation Guide
- § 9: Code Examples & Snippets
- §10: Testing & Debugging
- §11: Performance Optimization
- §12: Security Considerations
- §13: Future-Proofing & Maintenance
- §14: API Reference
- §15: Troubleshooting Guide
- §16: Acknowledgements
- Appendix & Changelog

## Examples

**Example 1: Multi-Integration Feature**
```
/speckit.research "Webflow CMS integration with external payment gateway and email service"

-> Generates comprehensive research covering:
   - Webflow API architecture
   - Payment gateway integration patterns
   - Email service webhooks
   - Data flow across all systems
-> Sections prioritized: Integration Patterns, Security, Error Management
```

**Example 2: Complex Architecture**
```
/speckit.research "Real-time collaboration system with conflict resolution"

-> Generates research covering:
   - WebSocket architecture
   - Operational transformation algorithms
   - State synchronization patterns
   - Offline support strategies
-> Sections prioritized: Core Architecture, State Management, Performance
```

**Example 3: Performance-Critical Feature**
```
/speckit.research "Video streaming optimization for mobile browsers"

-> Generates research covering:
   - Adaptive bitrate streaming
   - Browser codec support
   - Memory management strategies
   - Network condition handling
-> Sections prioritized: Performance, Browser Compatibility, Constraints
```

## Related Commands

**Before research:**
- **Create spec**: If feature not yet specified, run `/speckit.specify` first

**During research:**
- **Time-boxed spike**: For specific questions, run `/speckit.research-spike`
- **Record decisions**: For architectural choices, run `/speckit.decision`

**After research:**
- **Update plan**: If research changes approach, update plan.md
- **Generate tasks**: When ready to implement, run `/speckit.tasks`
