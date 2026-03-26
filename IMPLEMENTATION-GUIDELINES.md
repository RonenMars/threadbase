# Threadbase — Implementation Guidelines

> Reference this file at the start of every implementation session. It defines how to run the roadmaps, what tools are available, and the commit/landing-page update policy.

---

## 1. Project Overview

Threadbase is a cross-platform suite for browsing AI coding session history. Read these files to orient yourself before starting work:

| File | Purpose |
|---|---|
| `README.md` | Suite overview — all apps, quick start, architecture principles |
| `feature-comparison.md` | Cross-platform feature matrix (50+ features, 4 apps, gap analysis) |
| `multi-assistant-support.md` | Multi-assistant provider architecture (Codex, Continue, OpenCode, Amazon Q, Aider) |

Each app has its own roadmap and README:

| App | Roadmap | README |
|---|---|---|
| `claude-search/` (Electron) | `.planning/ROADMAP.md` | `README.md` |
| `vscode-claude-code-manager/` | `.planning/ROADMAP.md` | `README.md` |
| `intellij-claude-code-manager/` | `.planning/ROADMAP.md` | `README.md` |
| `threadbase-cli/` | `.planning/ROADMAP.md` | `README.md` |

The landing page update plan is at `threadbase-landing-codex/PLAN.md`.

---

## 2. Running the Roadmaps (GSD Workflow)

All implementation follows the **GSD (Get Stuff Done)** workflow. Each app has a `.planning/ROADMAP.md` with phases already defined.

### Starting a Phase

```
/gsd:progress          # check where things stand across all phases
/gsd:plan-phase        # plan the next phase (spawns researcher + plan checker)
/gsd:execute-phase     # execute a planned phase (spawns executor + verifier)
```

### Typical Phase Lifecycle

```
/gsd:plan-phase   →   review PLAN.md   →   /gsd:execute-phase   →   test   →   push
```

### Per-App Context

When starting work on a specific app, open a fresh Claude Code session inside that app's directory. Each app is its own git repository.

```bash
cd claude-search/                    # Electron desktop app
cd vscode-claude-code-manager/       # VS Code extension
cd intellij-claude-code-manager/     # IntelliJ plugin
cd threadbase-cli/                   # Go CLI
```

### GSD Settings (current)

| Setting | Value |
|---|---|
| Model Profile | Balanced (Opus for planning, Sonnet for execution) |
| Plan Researcher | On |
| Plan Checker | On |
| Execution Verifier | On |
| Auto-Advance | On |
| Nyquist Validation | Off |
| Git Branching | None (commit to current branch) |

Change settings any time with `/gsd:settings`.

---

## 3. Available Tools in This Claude Code Instance

### GSD Skills (workflow orchestration)

| Skill | Use for |
|---|---|
| `/gsd:progress` | Check current phase state and route to next action |
| `/gsd:plan-phase` | Create a detailed PLAN.md with researcher + plan checker agents |
| `/gsd:execute-phase` | Execute all tasks in a phase with atomic commits and verifier |
| `/gsd:settings` | Configure model profile, workflow toggles, branching strategy |
| `/gsd:debug` | Systematic debugging with persistent state across context resets |
| `/gsd:quick` | Execute a quick task with GSD guarantees, skipping optional agents |
| `/gsd:add-phase` | Add a new phase to the current milestone roadmap |
| `/gsd:map-codebase` | Analyze codebase with parallel mapper agents |

### Superpowers Skills (code quality)

| Skill | Use for |
|---|---|
| `/superpowers:brainstorming` | Before any creative feature work |
| `/superpowers:writing-plans` | After brainstorming, before implementation |
| `/superpowers:dispatching-parallel-agents` | 2+ independent tasks (e.g. implement same feature across 4 apps) |
| `/superpowers:subagent-driven-development` | Executing plans with independent tasks in current session |
| `/superpowers:verification-before-completion` | Before claiming work done or creating PRs |
| `/superpowers:systematic-debugging` | Any bug or unexpected behavior before proposing fixes |

### MCP Servers

| MCP | Use for |
|---|---|
| **context7** | Live documentation lookup for any library (Next.js, React, Tailwind, Kotlin, Go, Gradle, etc.) — use before implementing features that depend on versioned APIs |
| **serena** | Semantic code analysis — `find_symbol`, `get_symbols_overview`, `find_referencing_symbols`, `replace_symbol_body` — use instead of reading entire files |
| **jetbrains** | IntelliJ IDE integration — inspect plugin state, run Gradle tasks, check IDE logs — use for IntelliJ plugin work |
| **Vercel** | Deploy landing page, check build logs, get runtime logs — use for `threadbase-landing-codex/` work |

### Specialist Skills

| Skill | Use for |
|---|---|
| `/gradle-intellij-specialist` | IntelliJ Platform Gradle Plugin 2.x DSL — `intellijPlatform {}` blocks, `bundledPlugin()`, `testFramework`, `signPlugin`, `publishPlugin`, `verifyPlugin` |
| `/react-typescript` | React + TypeScript patterns — props typing, event handlers, hooks |
| `/superpowers:test-driven-development` | TDD workflow for any feature or bugfix |

### Recommended Tool Combinations by App

**Electron (`claude-search`)**
- serena for code analysis + context7 for electron/react/flexsearch docs
- `dispatching-parallel-agents` when phases are independent

**VS Code (`vscode-claude-code-manager`)**
- serena for code analysis + context7 for VS Code API / esbuild docs
- `react-typescript` for webview component work

**IntelliJ (`intellij-claude-code-manager`)**
- `gradle-intellij-specialist` for any build.gradle.kts changes
- jetbrains MCP to inspect plugin state in live IDE
- serena for Kotlin code analysis + context7 for IntelliJ Platform API docs
- `subagent-driven-development` for multi-step Kotlin implementation

**CLI (`threadbase-cli`)**
- context7 for Go stdlib / Cobra docs
- serena for Go code analysis

**Landing Page (`threadbase-landing-codex`)**
- Vercel MCP for deploy and log inspection
- context7 for Next.js 15 / Tailwind 4 / Framer Motion docs
- `web-design-guidelines` for UI review

---

## 4. Commit Policy

### Rule: Commit every completed task. Never push until tested and approved.

```
implement task → test locally → commit → next task → ... → all tasks done → test feature → push
```

**Commit format:** [Conventional Commits](https://www.conventionalcommits.org/)

```
<type>(<scope>): <short summary>

<optional body>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

**Types:**

| Type | When |
|---|---|
| `feat` | New feature or behavior |
| `fix` | Bug fix |
| `docs` | README, comments, plans only |
| `refactor` | Restructuring without behavior change |
| `test` | Tests only |
| `chore` | Build scripts, dependencies, config |

**Scope examples:** `claude-search`, `vscode`, `intellij`, `cli`, `landing`, `core`

**Examples:**

```
feat(vscode): add sort order and date range filter to tree view
fix(intellij): prevent NPE when conversation has no git metadata
docs(cli): update README with --json flag examples
chore(electron): upgrade electron to 41.0.2
```

### Push Policy

Only push after:
1. The feature works end-to-end manually
2. All existing tests pass (`pnpm test` / `npm test` / `./gradlew test` / `go test ./...`)
3. You (the developer) have approved the behavior

```bash
git push   # only after approval
```

---

## 5. Landing Page Update Policy

### After every approved feature: update `threadbase-landing-codex/`

Every time a feature is approved and pushed across any of the apps, the landing page should reflect it. This is a marketing obligation — the landing page is how new users discover what Threadbase can do.

### What to update

Open `threadbase-landing-codex/lib/content.ts` and update the relevant section:

| New capability | Update target in `content.ts` |
|---|---|
| New feature in any app | `FEATURES` array — add or sharpen the relevant entry |
| New platform capability | `PLATFORMS` array — update that platform's `description` |
| New CLI flag or command | `QUICK_START` CLI steps + `FEATURES` CLI entry |
| Multi-assistant provider added | `ROADMAP.items` — move from roadmap to live platforms |
| Bug fixed / stability improvement | `HONEST_CONS` — remove or soften the relevant con |
| IntelliJ feature shipped | Update `PLATFORMS[intellij].badge` away from "In Progress" when core is stable |

### Marketing Formulation Guidelines

Write landing page copy in **benefit language**, not feature language:

| Feature language (avoid) | Benefit language (use) |
|---|---|
| "Added --sort flag to cch list" | "Sort sessions by recency, message count, or alphabetically from the terminal" |
| "Implemented TaskToolCard component" | "Task agent cards show AI planning context in-line with the conversation" |
| "Fixed NPE in git branch scanner" | (don't surface bug fixes — just remove the related honest con) |
| "Added JCEF bridge for message navigation" | "Jump between messages with keyboard shortcuts without leaving IntelliJ" |

### Commit landing page changes with:

```
feat(landing): update content to reflect <feature> in <app>
```

### Reference: Landing Page Update Plan

The full plan for the next round of landing page updates is in `threadbase-landing-codex/PLAN.md`. It covers:
- CLI as 4th platform
- Features grid expansion (6 → 8)
- Multi-assistant roadmap teaser section
- Honest cons refresh
- Product rename to Threadbase

---

## 6. Multi-Assistant Support (Milestone 2)

When implementing multi-assistant support, read `multi-assistant-support.md` in full first. Key points:

- Implement the `AssistantProvider` interface in TypeScript (`src/core/providers/`), Kotlin (`core/providers/`), and Go (`internal/providers/`) — same boundary as existing domain code
- **Provider priority order:** Codex CLI (Tier 1) → Continue.dev (Tier 1) → OpenCode (Tier 2) → Amazon Q (Tier 2) → Aider (Tier 3)
- SQLite access: use `better-sqlite3` in Electron, `sql.js` (WASM) in VS Code extension host, `sqlite-jdbc` in IntelliJ, `modernc.org/sqlite` in Go CLI
- Each provider ships with auto-discovery (detect if the tool is installed/has sessions)
- Provider badge + filter UI: each session shows which tool it came from

---

## 7. Session Startup Checklist

Before starting any implementation session:

- [ ] `cd` into the specific app directory (each is its own git repo)
- [ ] Read `.planning/ROADMAP.md` to confirm the current phase
- [ ] Run `/gsd:progress` to check state
- [ ] Check that dependencies are up to date (`pnpm install` / `npm install` / `./gradlew dependencies` / `go mod tidy`)
- [ ] Run existing tests to confirm a clean baseline
- [ ] For IntelliJ work: have `/gradle-intellij-specialist` and the jetbrains MCP ready
- [ ] For landing page work: have the Vercel MCP ready
