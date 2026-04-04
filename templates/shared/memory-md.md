# MEMORY.md Output Template

This template defines the structure for generated MEMORY.md files. MEMORY.md is the routing map — it tells agents where code lives and why. This file is **platform-neutral**: identical output regardless of which agent generated it.

---

## MEMORY.md Structure

```markdown
# Routing Map

This file maps features to their locations, documents domain boundaries,
and captures cross-cutting constraints. Used by AI agents to make
correct code placement decisions.

## Feature → Directory Map

| Feature | Directory | Description |
| ------- | --------- | ----------- |

{{#each approved_chunks}}
| {{name}} | `{{path}}` | {{purpose}} |
{{/each}}

## Domain Boundaries

{{#each approved_chunks_with_rules}}

### {{name}} (`{{path}}`)

{{#each domain_rules}}

- {{this}}
  {{/each}}

{{/each}}

## Cross-Cutting Concerns

### Shared Code

{{#each shared_directories}}

- `{{path}}` — {{description}}
  {{/each}}

### Testing

{{test_directory_structure}}
{{test_conventions}}

### Configuration

{{#each config_directories}}

- `{{path}}` — {{description}}
  {{/each}}

### Scripts

{{#each script_directories}}

- `{{path}}` — {{description}}
  {{/each}}

## Dependency Graph

{{#each approved_chunks}}

### {{name}}

- **Depends on:** {{dependencies}}
- **Depended on by:** {{dependents}}
  {{/each}}

## Component Memory Files

{{#if component_memory_files}}
The following components have dedicated memory files with detailed
entry points, data flows, and constraints:

| Component | Memory File | Location |
| --------- | ----------- | -------- |

{{#each component_memory_files}}
| {{name}} | `{{file_path}}` | {{parent_chunk}} |
{{/each}}
{{/if}}
```

---

## Template Variables

| Variable                     | Source                | Description                                         |
| ---------------------------- | --------------------- | --------------------------------------------------- |
| `approved_chunks`            | Core workflow Phase 3 | All approved chunks from the interactive loop       |
| `approved_chunks_with_rules` | Core workflow Phase 3 | Chunks that have domain-specific rules              |
| `shared_directories`         | Core workflow Phase 2 | Directories identified as cross-cutting shared code |
| `test_directory_structure`   | Analysis              | How test directories are organized                  |
| `test_conventions`           | Analysis              | Testing conventions (framework, patterns)           |
| `config_directories`         | Analysis              | Configuration file locations                        |
| `script_directories`         | Analysis              | Script/tooling locations                            |
| `dependencies`               | Chunk analysis        | What other chunks this chunk depends on             |
| `dependents`                 | Chunk analysis        | What chunks depend on this chunk                    |
| `component_memory_files`     | Phase 5               | Components with their own memory files              |

---

## Rules

1. **Platform-neutral:** This file is identical regardless of which agent tool generated it.
2. **Single source of truth:** All routing decisions reference this file. Config files point here for detailed routing.
3. **Chunk parity:** Every approved chunk from the interactive loop must appear in the Feature → Directory Map.
4. **No instructions:** MEMORY.md contains facts about the codebase, not behavioral instructions for the agent. Instructions go in the config files (CLAUDE.md, GEMINI.md, AGENTS.md).
