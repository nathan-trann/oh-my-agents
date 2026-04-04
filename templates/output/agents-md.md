# AGENTS.md Output Template

This template defines the structure for generated AGENTS.md files (GitHub Copilot agent format). Uses YAML frontmatter + markdown body. Supports per-directory variants.

---

## Root AGENTS.md Structure

```markdown
---
name: project-agent
description: >
  {{PROJECT_DESCRIPTION_ONE_LINE}}
---

# Project Context

{{PROJECT_PHILOSOPHY}}

## About This Project

{{TECH_STACK_SUMMARY}}

## Key Directories

{{DIRECTORY_MAP}}

## Commands

\`\`\`bash
{{BUILD_COMMAND}}
{{TEST_COMMAND}}
{{DEV_COMMAND}}
{{LINT_COMMAND}}
\`\`\`

## Standards

{{CODING_CONVENTIONS}}

## Routing

For detailed feature-to-directory mapping and domain rules, see `MEMORY.md`.

{{BRIEF_ROUTING_SUMMARY}}

## Workflows

{{COMMON_WORKFLOWS}}

## Notes

{{GOTCHAS_AND_WARNINGS}}

## Agent Directives

To produce production-grade code, adhere to these operational rules:

### Pre-Work

1. **CLEAN BEFORE REFACTORING:** Dead code wastes context tokens. Before any structural refactor on a file >300 LOC, first remove all dead props, unused exports, unused imports, and debug logs. Commit this cleanup separately before starting the real work.
2. **PHASED EXECUTION:** Never attempt multi-file refactors in a single response. Break work into explicit phases. Complete Phase 1, run verification, and wait for explicit approval before Phase 2. Each phase must touch no more than 5 files.

### Code Quality

3. **QUALITY OVER MINIMUM VIABLE:** Do not default to the simplest or minimum-viable solution. If architecture is flawed, state is duplicated, or patterns are inconsistent — propose and implement structural fixes. Ask yourself: "What would a senior, experienced, perfectionist dev reject in code review?" Fix all of it.
4. **FORCED VERIFICATION:** After every file modification, run the project's type-checker (`{{TYPE_CHECK_COMMAND}}`) and linter (`{{LINT_COMMAND}}`) before reporting the task as complete. Fix ALL resulting errors. If no type-checker or linter is configured, state that explicitly instead of claiming success.

### Context Management

5. **PARALLEL TASK SPLITTING:** For tasks touching >5 independent files, break the work into parallel sub-tasks of 5-8 files each. Process each group independently to prevent context degradation.
6. **CONTEXT FRESHNESS:** After extended conversations, always re-read a file before editing it. Do not rely on memory of file contents from earlier in the conversation.
7. **CHUNKED FILE READING:** For files over 500 lines, read in sequential chunks rather than attempting a single read. File read operations have size limits — content past the limit is silently truncated. Never assume a single read captured the complete file.
8. **RESULT TRUNCATION AWARENESS:** Search and command results may be silently truncated when they exceed size limits. If any search returns suspiciously few results, re-run it with narrower scope (single directory, stricter glob). State when you suspect truncation occurred.

### Edit Safety

9. **EDIT INTEGRITY:** Before every file edit, re-read the file to ensure your context is current. After editing, read it again to confirm the change applied correctly. Edit operations can fail silently when file contents don't match expectations.
10. **COMPREHENSIVE RENAME SEARCH:** Search tools use text matching, not code analysis. When renaming or changing any function, type, or variable, search separately for: direct calls, type references, string literals, dynamic imports, re-exports, barrel file entries, and test mocks. A single search will miss references.
```

---

## Nested AGENTS.md Structure

Per-directory AGENTS.md files for chunks with domain-specific rules:

```markdown
---
name: { { CHUNK_SLUG } }
description: >
  {{CHUNK_PURPOSE}}
---

# {{CHUNK_NAME}}

## Structure

{{INTERNAL_STRUCTURE}}

## Entry Points

{{ENTRY_POINTS}}

## Domain Rules

{{DOMAIN_SPECIFIC_RULES}}

## Commands

\`\`\`bash
{{CHUNK_SPECIFIC_COMMANDS}}
\`\`\`

## Notes

{{CHUNK_SPECIFIC_GOTCHAS}}
```

---

## Template Variables

| Variable                       | Source       | Description                                       |
| ------------------------------ | ------------ | ------------------------------------------------- |
| `PROJECT_DESCRIPTION_ONE_LINE` | LLM analysis | Short description for YAML `description` field    |
| `CHUNK_SLUG`                   | Chunk label  | Lowercase, hyphenated slug (e.g., `auth-service`) |

All other variables are shared — see `templates/output/claude-md.md` for the full variable reference.

---

## GitHub Copilot Integration Notes

- Root `AGENTS.md` is auto-discovered by Copilot when placed in the project root
- Nearest `AGENTS.md` in directory tree takes precedence for files in that directory
- YAML frontmatter `name` must be unique and lowercase-with-hyphens
- `description` is used by Copilot to understand the agent's purpose
