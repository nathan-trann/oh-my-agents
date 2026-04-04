# .github/copilot-instructions.md Output Template

This template defines the structure for generated `.github/copilot-instructions.md` files. This is the repo-wide GitHub Copilot instruction file — flat markdown, no YAML frontmatter. Applied to all Copilot requests in the repo context.

---

## Root copilot-instructions.md Structure

```markdown
# Project Overview

{{PROJECT_PHILOSOPHY}}

{{TECH_STACK_SUMMARY}}

## Key Directories

{{DIRECTORY_MAP}}

## Commands

{{BUILD_COMMAND}}
{{TEST_COMMAND}}
{{DEV_COMMAND}}
{{LINT_COMMAND}}

## Coding Standards

{{CODING_CONVENTIONS}}

## Routing Guide

For detailed feature-to-directory mapping, see `MEMORY.md` in the project root.

{{BRIEF_ROUTING_SUMMARY}}

## Common Workflows

{{COMMON_WORKFLOWS}}

## Important Notes

{{GOTCHAS_AND_WARNINGS}}

## Agent Directives

### Pre-Work

1. **CLEAN BEFORE REFACTORING:** Dead code wastes context tokens. Before any structural refactor on a file >300 LOC, first remove unused code. Commit cleanup separately.
2. **PHASED EXECUTION:** Break multi-file refactors into phases of no more than 5 files. Verify between phases.

### Code Quality

3. **QUALITY OVER MINIMUM VIABLE:** Do not default to the simplest solution. If architecture is flawed or patterns are inconsistent, propose and implement structural fixes.
4. **FORCED VERIFICATION:** After every file modification, run the project's type-checker and linter before reporting complete. Fix all errors.

### Context Management

5. **PARALLEL TASK SPLITTING:** For tasks touching >5 independent files, break into sub-tasks of 5-8 files each.
6. **CONTEXT FRESHNESS:** After extended conversations, always re-read a file before editing it.
7. **CHUNKED FILE READING:** For files over 500 lines, read in sequential chunks. Never assume a single read captured the complete file.
8. **RESULT TRUNCATION AWARENESS:** If any search returns suspiciously few results, re-run with narrower scope.

### Edit Safety

9. **EDIT INTEGRITY:** Re-read files before and after editing. Verify changes applied correctly.
10. **COMPREHENSIVE RENAME SEARCH:** When renaming, search separately for: direct calls, type references, string literals, dynamic imports, re-exports, barrel file entries, and test mocks.
```

---

## Path-Specific Instructions

For chunks with domain-specific rules, optionally generate path-scoped instruction files in `.github/instructions/`:

```markdown
---
applyTo: '{{CHUNK_GLOB_PATTERN}}'
---

# {{CHUNK_NAME}} Guidelines

{{CHUNK_PURPOSE}}

## Domain Rules

{{DOMAIN_SPECIFIC_RULES}}

## Entry Points

{{ENTRY_POINTS}}

## Notes

{{CHUNK_SPECIFIC_GOTCHAS}}
```

### Example

```markdown
---
applyTo: 'src/auth/**'
---

# Auth Service Guidelines

Authentication and authorization service using JWT tokens.

## Domain Rules

- All routes require authentication except /health and /auth/login
- JWT tokens expire after 24 hours
- Use bcrypt for password hashing (min 12 rounds)
- Never log tokens or credentials

## Entry Points

- `src/auth/index.ts` — Service initialization
- `src/auth/middleware.ts` — Auth middleware for route protection
```

---

## Template Variables

Same as other output templates — see `templates/output/claude-md.md` for the full variable reference.

| Variable             | Source     | Description                                      |
| -------------------- | ---------- | ------------------------------------------------ |
| `CHUNK_GLOB_PATTERN` | Chunk path | Glob pattern for `applyTo` (e.g., `src/auth/**`) |

---

## GitHub Copilot Integration Notes

- `.github/copilot-instructions.md` is auto-discovered — no activation needed
- Applied to ALL Copilot requests in the repository
- Listed as reference in Chat responses when used
- Path-specific instructions in `.github/instructions/` use `applyTo` globs
- Keep concise — quality degrades beyond ~1,000 lines
