# Component Memory Output Template

This template defines the structure for per-component memory files. These are placed inside the component's directory and provide detailed context for agents working on that specific component. **Platform-neutral:** identical output regardless of which agent generated it.

---

## Component Memory Structure

File is named `COMPONENT.md` and placed in the component's root directory.

```markdown
# Component: {{COMPONENT_NAME}}

{{COMPONENT_PURPOSE}}

## Entry Point

- **Main file:** `{{ENTRY_POINT_FILE}}`
- **Initialization:** {{HOW_IT_STARTS}}
- **Public API:** {{KEY_EXPORTS}}

## Data Flow

{{DATA_FLOW_DESCRIPTION}}
```

{{DATA_FLOW_DIAGRAM}}

```

## Key Steps

{{#each key_steps}}
{{@index}}. **{{name}}:** {{description}}
   - File: `{{file}}`
   {{#if constraints}}
   - Constraints: {{constraints}}
   {{/if}}
{{/each}}

## Internal Structure

| Directory/File | Purpose |
|---------------|---------|
{{#each internal_files}}
| `{{path}}` | {{purpose}} |
{{/each}}

## Dependencies

- **Internal (this project):** {{internal_dependencies}}
- **External (packages):** {{external_dependencies}}

## Constraints

{{#each constraints}}
- {{this}}
{{/each}}

## Testing

- **Test location:** `{{test_directory}}`
- **Test framework:** {{test_framework}}
- **Key fixtures:** {{key_fixtures}}
- **How to run:** `{{test_command}}`

## Notes

{{COMPONENT_GOTCHAS}}
```

---

## Template Variables

| Variable                | Source              | Description                                       |
| ----------------------- | ------------------- | ------------------------------------------------- |
| `COMPONENT_NAME`        | Component detection | Descriptive name                                  |
| `COMPONENT_PURPOSE`     | Analysis            | One-sentence purpose                              |
| `ENTRY_POINT_FILE`      | Analysis            | Main file path (relative to component root)       |
| `HOW_IT_STARTS`         | Analysis            | How execution begins                              |
| `KEY_EXPORTS`           | Analysis            | What this component exposes                       |
| `DATA_FLOW_DESCRIPTION` | Analysis            | Narrative of how data moves through the component |
| `DATA_FLOW_DIAGRAM`     | Analysis            | ASCII/text diagram of the flow                    |
| `key_steps`             | Analysis            | Ordered list of major processing steps            |
| `internal_files`        | Analysis            | Key files/dirs within the component               |
| `internal_dependencies` | Analysis            | Other project chunks this depends on              |
| `external_dependencies` | Analysis            | npm/pip/cargo packages used                       |
| `constraints`           | Analysis            | Rules specific to this component                  |
| `test_directory`        | Analysis            | Where tests live                                  |
| `test_framework`        | Analysis            | Testing framework used                            |
| `key_fixtures`          | Analysis            | Important test fixtures or mocks                  |
| `test_command`          | Analysis            | Command to run this component's tests             |
| `COMPONENT_GOTCHAS`     | Analysis            | Warnings and edge cases                           |

---

## Significance Criteria

A component gets its own memory file when it meets 3+ of:

- Has >10 files
- Has a clear entry point (index file, main module)
- Exports a public API consumed by other chunks
- Has its own test directory or test files
- Has domain-specific constraints or rules
- Contains complex business logic flow (>3 steps)

---

## Rules

1. **Platform-neutral:** Identical regardless of which agent tool generated it.
2. **Cross-referenced:** Every component memory file is listed in MEMORY.md's "Component Memory Files" table.
3. **Self-contained:** The file must make sense on its own — an agent reading only this file should understand how to work on the component.
4. **Placed in-directory:** The file lives inside the component's directory, not in a central docs folder.
