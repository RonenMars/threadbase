# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working in the Threadbase umbrella repository root.

## Project

Threadbase — a local-first control plane for AI coding agents. This root repo is a lightweight umbrella project: documentation hub, governance files, and links to component repositories. Product code lives in separate repos (see [`docs/repositories.md`](docs/repositories.md)).

## Repository Structure

This is an **umbrella repository**, not an implementation monorepo. Component apps and packages are separate Git repositories:

### Apps
- [`threadbase-electron`](https://github.com/RonenMars/threadbase-electron) — Electron desktop app (macOS/Windows/Linux)
- [`threadbase-vscode`](https://github.com/RonenMars/threadbase-vscode) — VS Code extension
- [`threadbase-intellij`](https://github.com/RonenMars/threadbase-intellij) — IntelliJ/JetBrains plugin (Kotlin)
- [`threadbase-mobile`](https://github.com/RonenMars/threadbase-mobile) — Mobile app

### Shared Packages
- [`threadbase-scanner`](https://github.com/RonenMars/threadbase-scanner) — `@threadbase/scanner` — scan, parse, search, filter JSONL conversations
- [`threadbase-streamer`](https://github.com/RonenMars/threadbase-streamer) — `@threadbase/streamer` — PTY session management, WebSocket streaming, REST API
- [`threadbase-core`](https://github.com/RonenMars/threadbase-core) — `@threadbase/core` — multi-assistant provider abstraction, typed tool results
- [`threadbase-ui`](https://github.com/RonenMars/threadbase-ui) — `@threadbase/ui` — shared React rendering components

### Deprecated
- [`threadbase-cli`](https://github.com/RonenMars/threadbase-cli) — Go CLI (replaced by `threadbase-streamer`)

### Other
- `docs/` — Documentation hub
- `archive/` — Historical docs from pre-umbrella refresh

## Working on Component Repos

1. Clone the relevant component repository directly
2. Read its own CLAUDE.md (if present) for package-specific commands and conventions
3. Work on a branch, commit, and push within that repository

## Key Documentation

| File | Purpose |
|---|---|
| `README.md` | Suite overview, quick start, architecture |
| `docs/repositories.md` | Full repository map and links to component repos |
| `docs/feature-comparison.md` | Cross-platform feature matrix |
| `docs/provider-research.md` | Milestone 2 provider architecture plan |
| `docs/marketing/article-writing-guide.md` | Guide for writing about Threadbase |
| `archive/2026-07-pre-umbrella-refresh/IMPLEMENTATION-GUIDELINES.md` | Archived developer workflow notes |

## Conventions

- **Conventional commits** — `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:` with scope (e.g. `feat(scanner): ...`)
- **Architecture boundary** — all platforms enforce: pure domain logic → platform adapter → UI
- **No cross-repo imports in the umbrella root** — shared code lives in component packages; apps depend on these as npm packages or local references
