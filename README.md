# Oh My Agents

Deep, iterative codebase analysis that generates structured config files for agentic coding tools — replacing shallow `/init` commands with thorough, human-reviewed configuration.

**Supported tools:** Claude Code · GitHub Copilot · Gemini CLI

## What it does

Oh My Agents walks your entire codebase in chunks, extracts architecture, conventions, and constraints, then assembles config files that make your coding agent actually understand your project.

**Outputs generated:**

| Format                  | File(s)                                                                      | Tool                   |
| ----------------------- | ---------------------------------------------------------------------------- | ---------------------- |
| CLAUDE.md               | Root + nested per-component                                                  | Claude Code            |
| GEMINI.md               | Root + nested per-component                                                  | Gemini CLI             |
| AGENTS.md               | Root + nested per-component                                                  | GitHub Copilot         |
| copilot-instructions.md | `.github/copilot-instructions.md` + `.github/instructions/*.instructions.md` | GitHub Copilot         |
| MEMORY.md               | Routing map at project root                                                  | All (platform-neutral) |
| COMPONENT.md            | Per-component memory files                                                   | All (platform-neutral) |

All formats receive the same analysis. The same 10 agent directives (override behaviors) are injected into every format, tuned to each platform's capabilities.

## Quick start

```bash
# Clone the repo
git clone https://github.com/your-org/oh-my-agents.git
cd oh-my-agents

# Install into your project
./install.sh /path/to/your/project
```

The installer detects which agentic tools your project uses and copies the right files. Then:

| Tool            | How to run                                                  |
| --------------- | ----------------------------------------------------------- |
| **Claude Code** | `/oh-my-agents` (custom command)                            |
| **Copilot**     | Select `@oh-my-agents` in Copilot Chat, then type `go`      |
| **Gemini CLI**  | Reference `.gemini/prompts/oh-my-agents.md` in your session |

The agent will guide you interactively — asking which formats to generate, presenting the chunk map for approval, and walking through each chunk for review.

## Manual installation

If you prefer not to use the installer:

### Claude Code

```bash
# Copy the command
mkdir -p your-project/.claude/commands
cp src/claude-code/oh-my-agents.md your-project/.claude/commands/

# Copy the specs and templates it references
mkdir -p your-project/.oh-my-agents/{spec,templates/output,templates/shared}
cp spec/core-workflow.md spec/overrides.md your-project/.oh-my-agents/spec/
cp templates/output/*.md your-project/.oh-my-agents/templates/output/
cp templates/shared/*.md your-project/.oh-my-agents/templates/shared/
```

### GitHub Copilot

```bash
mkdir -p your-project/.github/agents
cp src/copilot/oh-my-agents.agent.md your-project/.github/agents/
```

The Copilot agent is self-contained — no spec/template files needed.

### Gemini CLI

```bash
mkdir -p your-project/.gemini/prompts
cp src/gemini/oh-my-agents.md your-project/.gemini/prompts/
```

The Gemini prompt is self-contained.

## How it works

### 1. Codebase chunking (4-stage cascade)

The tool breaks your codebase into analyzable chunks:

1. **Monorepo workspace detection** — reads workspace configs (pnpm-workspace.yaml, lerna.json, Cargo.toml workspaces, etc.)
2. **Package manifest detection** — finds package.json, Cargo.toml, pyproject.toml, go.mod in subdirectories
3. **Structural domain folder detection** — identifies domain boundaries by **structural signals** (5+ files, entry point, internal subdirectories, co-located tests, low coupling, exports consumed by other chunks), not hard-coded directory names
4. **LLM-assisted boundary refinement** — proposes remaining splits for user approval

### 2. Per-chunk analysis

For each chunk, the tool extracts:

- Tech stack and framework versions
- Build/test/lint commands
- Architecture patterns and conventions
- Key abstractions and naming conventions
- Known pitfalls and constraints
- Testing patterns and requirements
- Import conventions and path aliases
- Environment and deployment setup
- Cross-cutting concerns (logging, auth, error handling)

### 3. Interactive review

Every chunk's findings are presented to you for review:

- **Accept** — findings look correct, include them
- **Revise** — edit or add to the findings
- **Skip** — exclude this chunk

For each format, you see a preview of what the final config fragment will look like.

### 4. Output assembly

Findings are assembled into config files. Root configs are capped at ~150 instructions — domain-specific rules go in nested configs placed alongside the code they govern.

## The 10 agent directives

Every output format includes these directives, which override common failure modes in agentic coding tools:

| #   | Directive                   | What it prevents                                                   |
| --- | --------------------------- | ------------------------------------------------------------------ |
| 1   | Step 0 dead code cleanup    | Agents add code without removing what it replaces                  |
| 2   | Phased execution (≤5 files) | Agents try to change everything at once                            |
| 3   | Senior dev override         | Agents over-engineer or add unnecessary abstractions               |
| 4   | Forced verification         | Agents skip tests, linting, type-checking after changes            |
| 5   | Sub-agent swarming          | Agents work serially when parallel sub-agents would be faster      |
| 6   | Context decay awareness     | Agents forget earlier instructions in long sessions                |
| 7   | File read budget            | Agents read too little or too much before acting                   |
| 8   | Tool result blindness       | Agents assume tool calls succeeded without checking output         |
| 9   | Edit integrity              | Agents accidentally delete unrelated code when editing             |
| 10  | No semantic search          | Agents use semantic search when exact text search is more reliable |

CLAUDE.md gets exact thresholds (167K token window, 2K line limit, etc.). Other formats use generic framing since their context windows and capabilities vary.

## Cross-platform parity

All platforms get the same analysis depth. Differences are only in format:

- **CLAUDE.md / GEMINI.md** — WHAT/WHY/HOW structure, Markdown with instruction groups
- **AGENTS.md** — YAML frontmatter (`name`, `description`) + Markdown body
- **copilot-instructions.md** — Flat Markdown; path-specific rules use `.github/instructions/*.instructions.md` with `applyTo` globs
- **MEMORY.md** — Platform-neutral routing map (feature → directory → config file)
- **COMPONENT.md** — Platform-neutral per-component memory (entry points, data flow, dependencies, constraints)

## Project structure

```
oh-my-agents/
├── spec/
│   ├── core-workflow.md       # Platform-neutral 5-phase analysis workflow
│   └── overrides.md           # 10 universal agent directives
├── src/
│   ├── claude-code/
│   │   └── oh-my-agents.md    # Claude Code custom command
│   ├── copilot/
│   │   └── oh-my-agents.agent.md   # Copilot agent (@oh-my-agents)
│   └── gemini/
│       └── oh-my-agents.md    # Gemini CLI prompt
├── templates/
│   ├── output/                # Output format templates (CLAUDE.md, GEMINI.md, etc.)
│   └── shared/                # Platform-neutral templates (MEMORY.md, COMPONENT.md)
├── docs/
│   └── reference/             # Background research and reference materials
├── install.sh                 # Interactive installer
└── README.md
```

## Design decisions

**Why prompts, not a CLI?** The product IS the prompts. Each agentic tool has its own invocation mechanism (commands, prompt files, agent files). A runtime CLI would add complexity without adding value — the LLM does the analysis work.

**Why self-contained Copilot/Gemini prompts?** Claude Code can reference external files via `Read`. Copilot and Gemini cannot reliably reference files outside their prompt. So the Copilot agent and Gemini prompt inline all necessary logic and templates.

**Why structural domain detection over name matching?** Hard-coded directory names (`auth/`, `billing/`, `api/`) miss arbitrary domain names like `centre-pay/` or `workers-sdk/`. Structural signals (file count, entry points, internal structure, coupling) detect any domain boundary regardless of naming.

**Why all 10 overrides in every format?** These address universal failure modes in LLM-based coding agents, not Claude-specific bugs. Every agent benefits from phased execution, verification, and context management.

## License

MIT
