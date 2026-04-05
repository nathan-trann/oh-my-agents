# Oh My Agents: Core Workflow Spec

This is the platform-neutral specification that ALL platform prompts (Claude Code, GitHub Copilot, Gemini CLI) must implement. The analysis logic is identical across platforms — only output formatting differs.

---

## Phase 1: Tool Selection

Present the user with a multi-select prompt. They choose which agent config formats to generate. Multiple selections are encouraged.

### Target Mapping

| Selection                | Root Output File                  | Nested Output File                       | Location                          |
| ------------------------ | --------------------------------- | ---------------------------------------- | --------------------------------- |
| Claude Code              | `CLAUDE.md`                       | `CLAUDE.md` in subdirectories            | Project root + domain directories |
| Gemini CLI / Antigravity | `GEMINI.md`                       | `GEMINI.md` in subdirectories            | Project root + domain directories |
| GitHub Copilot (Agent)   | `AGENTS.md`                       | `AGENTS.md` in subdirectories            | Project root + domain directories |
| GitHub Copilot (Repo)    | `.github/copilot-instructions.md` | `.github/instructions/*.instructions.md` | `.github/` directory              |

### Additional Outputs (always generated)

| File                   | Location                     | Purpose                                        |
| ---------------------- | ---------------------------- | ---------------------------------------------- |
| `MEMORY.md`            | Project root                 | Routing map — where code lives and why         |
| Component memory files | Inside component directories | Per-component entry points, flows, constraints |

### Prompt Template

```
Which agent tools do you want to generate config files for?
Select all that apply:

  [ ] Claude Code        → CLAUDE.md
  [ ] Gemini CLI         → GEMINI.md
  [ ] GitHub Copilot     → AGENTS.md + .github/copilot-instructions.md

All selections also generate:
  - MEMORY.md (routing map)
  - Component memory files (per significant component)
```

### Conventions Source

After format selection, ask whether the team has an existing coding conventions
or standards document:

- **Yes** — ask for the file path(s), read the document immediately
- **No** — conventions will be derived from codebase analysis

If a conventions document is provided, it becomes the **authoritative source**
for the Standards/Coding Standards sections in all generated configs. Codebase
analysis may supplement it with observed patterns not covered by the document,
but must never contradict it.

Common locations to suggest:

- `CONTRIBUTING.md`, `STYLE_GUIDE.md`, `docs/conventions.md`, `docs/coding-standards.md`
- `.editorconfig`, `biome.json`, `eslint.config.*`, `prettier.config.*`, `rustfmt.toml`
- ADR directories (`docs/adr/`, `docs/decisions/`)

---

## Phase 2: Codebase Chunking

The agent divides the codebase into logical chunks using a four-stage cascade. Each stage refines the previous stage's output. The agent runs all stages, then presents the final chunk map to the user for validation.

### Stage 1: Monorepo Workspace Detection

Search for workspace configuration files at the project root:

| Config File                                   | Tool      | What It Tells You                            |
| --------------------------------------------- | --------- | -------------------------------------------- |
| `package.json` → `workspaces` field           | npm/yarn  | List of workspace package paths              |
| `pnpm-workspace.yaml`                         | pnpm      | Workspace package globs                      |
| `nx.json` + `workspace.json` / `project.json` | Nx        | Project graph with dependencies              |
| `turbo.json`                                  | Turborepo | Pipeline config (implies workspace packages) |
| `lerna.json`                                  | Lerna     | Package locations                            |
| `Cargo.toml` → `[workspace]`                  | Rust      | Member crate paths                           |
| `go.work`                                     | Go        | Module paths                                 |
| `settings.gradle` / `settings.gradle.kts`     | Gradle    | Included sub-projects                        |
| `pom.xml` → `<modules>`                       | Maven     | Sub-module paths                             |

If workspace config is found, each workspace package becomes a chunk. Proceed to Stage 2 for packages that are themselves large enough to subdivide.

### Stage 2: Package Manifest Detection

Within each chunk (or at the root if no workspace was found), look for package manifests that indicate independent modules:

- `package.json` (without being a workspace root)
- `go.mod`
- `Cargo.toml` (without `[workspace]`)
- `pyproject.toml` / `setup.py` / `setup.cfg`
- `pom.xml` (leaf module)
- `build.gradle` / `build.gradle.kts`
- `*.csproj` / `*.sln`
- `mix.exs`
- `Gemfile`

Each directory containing a manifest becomes a chunk candidate.

### Stage 3: Directory Depth Heuristics

For areas not covered by Stages 1–2, apply structural heuristics:

1. **Top-level source directories:** If `src/`, `app/`, `lib/`, `pkg/`, `internal/`, or `cmd/` exist, examine their immediate children as chunk candidates.

2. **Domain folder detection:** Identify directories that represent bounded contexts using **structural signals first, names second**:

   **Structural signals (primary — detect domains regardless of name):**
   A directory is a domain candidate if it exhibits 2+ of these structural indicators:
   - Has 5+ source files (not just config/assets)
   - Contains an entry point file (index.ts, main.py, mod.rs, **init**.py, app.ts, etc.)
   - Has internal subdirectories suggesting layered organization (e.g., `models/`, `services/`, `handlers/`, `types/`, `utils/`, or any subdivision)
   - Contains its own test files or a co-located test directory
   - Has imports primarily from shared/common code rather than from sibling directories (low coupling to peers)
   - Exports types, functions, or classes consumed by other directories

   **Name signals (supplementary — boost confidence for already-detected candidates):**
   Common domain folder names include: `auth/`, `billing/`, `users/`, `api/`, `core/`, `shared/`, `common/`, `infrastructure/`, `domain/`, `features/`, `modules/`, `services/`, `handlers/`, `controllers/`, `routes/`. But do NOT limit detection to these names — any directory matching the structural signals above is a domain candidate regardless of its name (e.g., `checkout-flow/`, `notification-engine/`, `report-builder/`).

3. **Test/doc separation:** `tests/`, `test/`, `spec/`, `__tests__/`, `docs/`, `scripts/` are NOT chunks — they are noted as cross-cutting directories.
4. **Size threshold:** A directory with fewer than 5 files is not a standalone chunk — merge it with its parent.

### Stage 4: LLM-Assisted Boundary Refinement

The agent reviews the chunk map from Stages 1–3 and refines it:

1. **Read the directory tree** (depth 3) for the entire project.
2. **Examine key files** in each proposed chunk: README, index/entry files, package manifests, key exports.
3. **Propose boundary adjustments:**
   - Merge chunks that are tightly coupled (importing >50% of each other's exports).
   - Split chunks that contain multiple unrelated domains.
   - Identify cross-cutting concerns (shared utilities, types, config) that should be noted but not chunked separately.
4. **Name each chunk** with a short, descriptive label (e.g., "Auth Service", "Shared UI Components", "Database Layer").

### Chunk Presentation

Present the chunk map to the user for validation BEFORE proceeding to analysis:

```
I've identified the following chunks in your codebase:

  1. Auth Service         → src/auth/ (23 files)
  2. API Gateway          → src/api/ (41 files)
  3. Database Layer       → src/db/ (15 files)
  4. Shared Utilities     → src/shared/ (8 files)
  5. Web Frontend         → apps/web/ (87 files)
  6. Worker Service       → apps/worker/ (19 files)

  Cross-cutting (noted, not chunked separately):
  - Tests: tests/ (mirrors source structure)
  - Config: config/, .env.example
  - Scripts: scripts/

Does this look right? You can:
  - Approve:  proceed with this chunk map
  - Adjust:   suggest merge/split/rename changes
  - Add:      include directories I missed
```

Wait for user confirmation before proceeding.

---

## Phase 3: Per-Chunk Analysis (Interactive Loop)

Process each chunk one at a time. For each chunk, the agent performs analysis, presents findings, and waits for user input.

### What to Extract Per Chunk

For each chunk, the agent must examine and document:

1. **Purpose:** One-sentence description of what this chunk does.
2. **Entry points:** Main files that start execution or export the public API.
3. **Key exports:** What does this chunk expose to other parts of the codebase?
4. **Internal structure:** How is the chunk organized internally (by feature, by layer, by type)?
5. **Dependencies:** What other chunks/external packages does this chunk depend on?
6. **Dependents:** What other chunks depend on this chunk?
7. **Domain rules:** Constraints specific to this chunk (e.g., "all API routes must use middleware X", "database models must extend BaseModel").
8. **Technology specifics:** Framework-specific patterns, ORMs, state management, etc.
9. **Testing approach:** How is this chunk tested? Where do tests live?
10. **Commands:** Build/test/run commands specific to this chunk (if different from root).

### How to Analyze

1. **Read the directory tree** for the chunk (full depth).
2. **Read entry point files** (index.ts, main.py, mod.rs, etc.) — identify exports and top-level structure.
3. **Read package manifest** if present — identify dependencies.
4. **Sample 3-5 representative files** — understand patterns, conventions, internal structure.
5. **Read README** if present — capture documented purpose and constraints.
6. **Check for existing config files** — note any existing CLAUDE.md, AGENTS.md, GEMINI.md, copilot-instructions.md.

### Summary Presentation

For each chunk, present findings in this format:

````
## Chunk 2 of 6: API Gateway (src/api/)

### Purpose
Express.js REST API serving as the main gateway for client applications.

### Entry Points
- `src/api/index.ts` — Server initialization, middleware chain
- `src/api/routes/index.ts` — Route registration

### Key Exports
- Route handlers: auth, users, products, orders
- Middleware: authMiddleware, rateLimiter, errorHandler

### Dependencies
- Auth Service (src/auth/) — JWT validation, session management
- Database Layer (src/db/) — All data access via repository pattern
- External: express, zod, winston

### Domain Rules
- All routes require authentication except /health and /auth/login
- Request validation uses Zod schemas co-located with route files
- Responses follow { data, error, meta } envelope pattern
- Rate limiting: 100 req/min per IP (configured in middleware)

### Testing
- Tests in tests/api/ mirror source structure
- Integration tests use supertest
- Auth mocks in tests/api/__mocks__/auth.ts

### Generated Config Fragments

Show draft config fragments for ALL selected output formats side by side,
so the user can verify parity. Each fragment shows exactly what will land
in the corresponding config file for this chunk.

**CLAUDE.md fragment:**
```markdown
# API Gateway

Express.js REST API — main gateway for client applications.

## Structure
Routes organized by domain: auth/, users/, products/, orders/

## Entry Points
- src/api/index.ts — Server init, middleware chain
- src/api/routes/index.ts — Route registration

## Domain Rules
- All routes require auth except /health and /auth/login
- Request validation via Zod schemas co-located with route files
- Response envelope: { data, error, meta }

## Commands
````

npm run test:api

```

```

**GEMINI.md fragment:**

```markdown
# API Gateway

Express.js REST API — main gateway for client applications.

## Structure

[same content as CLAUDE.md — identical analysis, identical structure]

## Domain Rules

[same rules — platform-neutral analysis]
```

**AGENTS.md fragment:**

```markdown
---
name: api-gateway
description: >
  Express.js REST API gateway — routes, middleware, validation
---

# API Gateway

[same body content]
```

**copilot-instructions — path-scoped:**

```markdown
---
applyTo: 'src/api/**'
---

# API Gateway Guidelines

[same domain rules and conventions]
```

---

Choose: [A]ccept [R]evise [S]kip

```

**Important:** The user sees fragments for ALL selected formats simultaneously.
If the user selected Claude Code + Copilot but not Gemini, only show CLAUDE.md,
AGENTS.md, and copilot-instructions fragments.

### User Interaction

- **Accept:** The analysis and all generated fragments look correct. Store findings and fragments, move to next chunk.
- **Revise:** User provides feedback (e.g., "wrong entry point", "missing rule about X", "the purpose should say Y"). Agent updates the analysis AND all fragments, then re-presents. Repeat until accepted or skipped.
- **Skip:** Move to the next chunk without storing findings for this chunk. Skipped chunks still appear in the chunk map but get no config fragment or MEMORY.md entry.

### State Accumulation

Maintain a running state object across chunks. This is the agent's internal
working memory — not shown to the user, but critical for correct assembly.

```

state = {
selected_targets: ["claude", "gemini", "copilot"], // from Phase 1
project: {
name: "",
philosophy: "",
tech_stack: "",
root_commands: { build: "", test: "", dev: "", lint: "", typecheck: "" },
conventions: []
},
approved_chunks: [
{
name: "", // e.g., "API Gateway"
path: "", // e.g., "src/api/"
purpose: "", // one-sentence description
entry_points: [], // main files
exports: [], // public API surface
dependencies: [], // other chunks this depends on
dependents: [], // chunks that depend on this
domain_rules: [], // constraints specific to this chunk
tech_specifics: "", // framework, ORM, state management details
testing: { location: "", framework: "", patterns: "" },
commands: {}, // chunk-specific commands (if different from root)
internal_structure: "", // how the chunk is organized
needs_nested_config: false, // computed from threshold rules
config_fragments: {
claude: "", // rendered CLAUDE.md fragment for this chunk
gemini: "", // rendered GEMINI.md fragment
agents: "", // rendered AGENTS.md fragment (with YAML frontmatter)
copilot: "" // rendered .instructions.md fragment (with applyTo)
}
}
],
skipped_chunks: [{ name: "", path: "" }],
routing_map_entries: [
{ feature: "", directory: "", description: "", domain_rules: [] }
],
cross_cutting: {
shared_directories: [{ path: "", description: "" }],
test_directories: [{ path: "", description: "", framework: "" }],
config_directories: [{ path: "", description: "" }],
scripts_directories: [{ path: "", description: "" }]
},
detected_components: [] // populated in Phase 5
}

````

### Nested Config Decision

After approving a chunk, evaluate whether it needs its own nested config file.
Generate a nested config when ANY of these are true:

- Chunk has >15 files
- Chunk has 2+ domain-specific rules not covered by root config
- Chunk uses a different primary framework than the project root
- Chunk has its own build/test commands distinct from root commands
- User explicitly requested chunk-level config during the Revise step

Set `needs_nested_config = true` in state. During assembly (Phase 4),
chunks with this flag get nested config files in their directory.
Chunks without it contribute only to the root config and MEMORY.md.

---

## Phase 4: Output Assembly

After all chunks are processed, assemble the final output files.

### Root Config File Assembly

For each selected target format, assemble a root-level config file:

1. **Project context section:** Combine project-level information (tech stack, architecture, key dependencies) from the overall codebase scan.
2. **Key directories section:** List all approved chunks with one-line descriptions.
3. **Commands section:** Root-level build/test/run commands.
4. **Standards section:** If the user provided a conventions document in Phase 1, use it as the authoritative source. Supplement with observed codebase patterns that don't contradict it. If no document was provided, derive conventions entirely from codebase analysis.
5. **Routing section:** Brief routing map (detailed map goes in MEMORY.md). Point to MEMORY.md for full routing.
6. **Agent overrides section:** Inject overrides from `spec/overrides.md` (all 10, adapted to the target format).

**Instruction budget:** Keep root config under 150 instructions total. If analysis produces more, move detailed content to nested configs or MEMORY.md.

### Nested Config File Rules

Generate a nested config file in a chunk's directory when ANY of these are true:

- Chunk has >15 files
- Chunk has domain-specific rules not covered by root config
- Chunk uses a different tech stack or framework than the root
- Chunk has its own build/test commands
- The user explicitly approved chunk-specific findings

Nested configs contain ONLY chunk-specific information — never repeat root-level instructions.

### MEMORY.md Assembly

Generate `MEMORY.md` at the project root with:

```markdown
# Routing Map

This file maps features to their locations, documents domain boundaries,
and captures cross-cutting constraints. Used by AI agents to make
correct code placement decisions.

## Feature → Directory Map

| Feature | Directory | Description |
|---------|-----------|-------------|
| [from approved chunks] | | |

## Domain Boundaries

[For each approved chunk with domain rules:]
### [Chunk Name] (path)
- Rule 1
- Rule 2

## Cross-Cutting Concerns

### Shared Code
[shared directories and what they contain]

### Testing
[test directory structure and conventions]

### Configuration
[config locations and patterns]

## Dependency Graph

[Which chunks depend on which — from analysis]
````

### Component Memory Assembly

For significant components (detected in Phase 3 or Phase 5), generate per-component memory files placed in the component's directory:

```markdown
# Component: [Name]

## Entry Point

[main file and how execution starts]

## Data Flow

[how data moves through this component]

## Key Steps

1. [step 1]
2. [step 2]

## Constraints

- [constraint 1]
- [constraint 2]

## Testing

[how to test this component]
```

---

## Phase 5: Component Detection (Post-MVP)

After Phase 4, optionally scan approved chunks for significant components worth their own memory file.

### Significance Criteria

A component is "significant" if it meets 3+ of:

- Has >10 files
- Has a clear entry point (index file, main module)
- Exports a public API consumed by other chunks
- Has its own test directory or test files
- Has domain-specific constraints or rules
- Contains complex business logic flow (>3 steps)

### Detection Process

1. For each approved chunk, identify components matching the criteria.
2. Present detected components to the user:

```
I identified these significant components worth their own memory file:

  1. AuthService         → src/auth/service.ts (entry point, 12 files, complex flow)
  2. OrderPipeline       → src/orders/pipeline/ (entry point, 18 files, 5-step flow)
  3. PaymentGateway      → src/payments/gateway.ts (entry point, 8 files, external API)

Generate memory files for these? [A]ll  [S]elect  [N]one
```

3. For each confirmed component, generate a memory file in its directory and add a cross-reference entry in MEMORY.md.

---

## Format Parity Rules

These rules ensure consistency regardless of which agent runs the workflow:

1. **Same analysis, different formatting.** The chunk analysis, routing map, and component memory are identical across platforms. Only the config file structure differs.
2. **MEMORY.md is always identical.** Regardless of which agent generated it, the MEMORY.md file must contain the same information.
3. **Component memory files are always identical.** Platform-neutral format.
4. **All 10 overrides in all formats.** Every output config file includes all 10 agent optimization overrides, adapted to the target format's native style and with platform-appropriate framing.
5. **Nested config threshold is consistent.** The same directories get nested configs regardless of target format.
