# Threadbase

A cross-platform suite for browsing, searching, and resuming your Claude Code conversation history. Runs as a native desktop app, a VS Code extension, an IntelliJ plugin, and a Go CLI tool — all reading the same local JSONL files that Claude Code writes to `~/.claude/`.

---

## Applications

| App | Platform | Repo |
|---|---|---|
| Electron desktop app | macOS / Windows / Linux | [threadbase-electron](https://github.com/RonenMars/threadbase-electron) |
| VS Code extension | VS Code | [threadbase-vscode](https://github.com/RonenMars/threadbase-vscode) |
| IntelliJ plugin | JetBrains IDEs | [threadbase-intellij](https://github.com/RonenMars/threadbase-intellij) |
| Go CLI (`cch`) | Terminal | [threadbase-cli](https://github.com/RonenMars/threadbase-cli) *(deprecated — replaced by streamer)* |

### Shared Packages

| Package | Description | Status |
|---|---|---|
| [`@threadbase/scanner`](./scanner/) | Scan, parse, search, and filter Claude Code conversation history | v0.1.0 |
| [`@threadbase/streamer`](./streamer/) | PTY session management, WebSocket streaming, REST API server | WIP |

### Landing Page

- [threadbase-landing-page-v2](https://github.com/RonenMars/threadbase-landing-page-v2) — Current Next.js 15 marketing landing page

---

## Feature Highlights

All platforms share the same core: JSONL scanning, FlexSearch / Lucene full-text indexing, profile management, and conversation export. Platform-specific features build on top.

### Shared Across All Platforms

- Full-text search across all conversations
- Multi-profile support (multiple `CLAUDE_CONFIG_DIR` paths)
- Conversation export: Markdown, plain text, JSON
- Tool result cards: Edit diffs, Bash output, Read/Write/Glob/Grep, Task agent cards
- Sort options: recency, oldest, most messages, fewest messages, alphabetical
- Date range filter: today, 7 days, 30 days, all time

### Desktop App (threadbase-electron)

- Embedded Claude Code terminal (xterm.js + node-pty, up to N concurrent instances)
- Git worktrees panel with creation UI
- Multi-profile dashboard with per-profile stats
- Live chat indicators (Typing..., Awaiting Reply, Live)
- Virtualized conversation list + conversation viewer
- Context menus on conversation items (Copy ID, Resume in Terminal, Resume in New Window, Open Project)
- Speed search overlay for instant list filtering

### VS Code Extension

- Native VS Code TreeView with live file watcher badges
- QuickPick search command
- Workspace-scoped conversation filtering
- Task tool cards (TodoWrite, TodoRead, Task agent)

### IntelliJ Plugin

- Native Swing tree with IDE speed search
- JCEF-powered React conversation viewer
- In-IDE terminal resume (`Ctrl+Shift+H`)
- Git branch badges on conversation items
- Message-level navigation with keyboard shortcuts
- Token and model metadata per message

### CLI (`cch`)

- `cch list` / `cch search` / `cch show` / `cch resume`
- `--sort`, `--since` / `--after` date filter flags
- `--json` output for pipeline use (`cch list --json | jq ...`)
- `cch profiles add/edit/delete/list` for profile management
- Git branch column in list output

---

## Quick Start

### Desktop App

```bash
git clone https://github.com/RonenMars/threadbase-electron
cd threadbase-electron
pnpm install
pnpm run dev         # development
pnpm run package     # build DMG
```

### VS Code Extension

```bash
git clone https://github.com/RonenMars/threadbase-vscode
cd threadbase-vscode
npm install
npm run build
# Press F5 in VS Code to launch Extension Development Host
```

### IntelliJ Plugin

```bash
git clone https://github.com/RonenMars/threadbase-intellij
cd threadbase-intellij
./gradlew runIde     # launches a sandboxed IDE with the plugin loaded
```

### CLI

```bash
git clone https://github.com/RonenMars/threadbase-cli
cd threadbase-cli
go build -o cch ./cmd/cch
./cch list
./cch search "auth refresh"
./cch list --sort messages-desc --since 7d --json | jq '.[].title'
```

---

## Architecture

All platforms enforce the same layered boundary: **pure domain logic → platform adapter → UI**.

```
Domain (platform-agnostic)
├── JSONL scanner + LRU cache
├── FlexSearch / Lucene index
├── Export formatters (MD / plain / JSON)
├── Profile manager
└── Filter / sort pipeline

Platform Adapter
├── Electron IPC bridge
├── VS Code TreeDataProvider + WebviewPanel
├── IntelliJ ProjectService + JCEF bridge
└── Cobra commands (Go)

UI
├── React 18 (Electron renderer + VS Code webview)
├── Swing tree + JCEF webview (IntelliJ)
└── Text / JSON output (CLI)
```

The TypeScript domain layer (`src/core/` in Electron and VS Code) has zero Electron and zero VS Code imports — it runs identically in both runtimes and is tested with plain Vitest. The Kotlin port in the IntelliJ plugin maintains the same domain boundary with zero IDE imports enforced by the project structure.

### Tech Stack Summary

| Layer | Desktop | VS Code | IntelliJ | CLI |
|---|---|---|---|---|
| Language | TypeScript | TypeScript | Kotlin 2.x | Go 1.26 |
| Search | FlexSearch 0.7 | FlexSearch 0.7 | Lucene 9.x | — |
| UI | React 18 + Tailwind | React 18 (webview) + native TreeView | Swing + React 18 (JCEF) | Text / JSON |
| Terminal | xterm.js + node-pty | — | IntelliJ Terminal API | — |
| Build | electron-vite | esbuild | Gradle 8.x | `go build` |
| Tests | Vitest + Playwright | Vitest | JUnit 5 + BasePlatformTestCase | — |

---

## Roadmap

### Milestone 2 (Planned): Multi-Assistant Support

Extend all four platforms to index sessions from other AI coding tools alongside Claude Code. A provider abstraction layer will let each app scan, parse, and display sessions from any supported tool.

**Planned providers (in priority order):**

| Provider | Storage | Priority |
|---|---|---|
| OpenAI Codex CLI | `~/.codex/sessions/**/*.jsonl` | Tier 1 |
| Continue.dev | `~/.continue/sessions/<uuid>.json` | Tier 1 |
| OpenCode | `~/.local/share/opencode/.../sessions.db` | Tier 2 |
| Amazon Q Developer CLI | `~/.local/share/amazon-q/data.sqlite3` | Tier 2 |
| Aider | `./.aider.chat.history.md` | Tier 3 |
| Cline | VS Code globalStorage JSON | Tier 3 |

See [multi-assistant-support.md](./multi-assistant-support.md) for the full provider interface design and per-app implementation plan.

---

## Repositories

| Repo | Description |
|---|---|
| [threadbase-electron](https://github.com/RonenMars/threadbase-electron) | Electron desktop app |
| [threadbase-vscode](https://github.com/RonenMars/threadbase-vscode) | VS Code extension |
| [threadbase-intellij](https://github.com/RonenMars/threadbase-intellij) | IntelliJ plugin |
| [threadbase-cli](https://github.com/RonenMars/threadbase-cli) | Go CLI (`cch`) — *deprecated, replaced by `@threadbase/streamer`* |
| [threadbase-scanner](./scanner/) | `@threadbase/scanner` — scan, parse, search, filter |
| [threadbase-streamer](./streamer/) | `@threadbase/streamer` — PTY management, streaming, REST server (WIP) |
| [threadbase-landing-page-v2](https://github.com/RonenMars/threadbase-landing-page-v2) | Next.js 15 marketing landing page |

## Docs

- [feature-comparison.md](./feature-comparison.md) — Cross-platform feature matrix
- [multi-assistant-support.md](./multi-assistant-support.md) — Milestone 2 provider architecture plan
- [IMPLEMENTATION-GUIDELINES.md](./IMPLEMENTATION-GUIDELINES.md) — Developer workflow reference
- [docs/article-writing-guide.md](./docs/article-writing-guide.md) — Guide for writing about Threadbase

---

## License

MIT — not affiliated with Anthropic. Claude Code is a product of Anthropic.
