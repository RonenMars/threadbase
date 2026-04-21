# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working in the Threadbase monorepo root.

## Project

Threadbase — a cross-platform suite for browsing, searching, and resuming Claude Code conversation history. This root repo aggregates all apps and shared packages as Git submodules.

## Repository Structure

This is a **submodule-based monorepo**. Each directory is its own Git repo:

### Apps
- `electron/` — Electron desktop app (macOS/Windows/Linux)
- `vscode/` — VS Code extension
- `intellij/` — IntelliJ/JetBrains plugin (Kotlin)
- `cli/` — Go CLI (deprecated, replaced by streamer)
- `mobile/` — Mobile app

### Shared Packages
- `scanner/` — `@threadbase/scanner` — scan, parse, search, filter JSONL conversations
- `streamer/` — `@threadbase/streamer` — PTY session management, WebSocket streaming, REST API
- `core/` — `@threadbase/core` — multi-assistant provider abstraction, typed tool results
- `ui/` — `@threadbase/ui` — shared React rendering components

### Other
- `wiki/` — Project wiki
- `landing-page-v2/` — Next.js marketing site (external repo, not a submodule here)
- `docs/` — Article writing guides and documentation

## Submodule Workflow

```bash
# Clone with all submodules
git clone --recurse-submodules git@github.com:RonenMars/threadbase.git

# Fetch submodules after a plain clone
git submodule update --init --recursive

# Pull latest across all submodules
git pull --recurse-submodules
git submodule update --remote --merge
```

When working on a specific app or package, `cd` into that directory — it has its own git history, branches, and (where applicable) its own CLAUDE.md.

## Key Documentation

| File | Purpose |
|---|---|
| `README.md` | Suite overview, quick start, architecture |
| `IMPLEMENTATION-GUIDELINES.md` | Developer workflow, commit policy, tool recommendations |
| `feature-comparison.md` | Cross-platform feature matrix |
| `multi-assistant-support.md` | Milestone 2 provider architecture plan |
| `docs/article-writing-guide.md` | Guide for writing about Threadbase |

## Conventions

- **Conventional commits** — `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:` with scope (e.g. `feat(scanner): ...`)
- **Architecture boundary** — all platforms enforce: pure domain logic → platform adapter → UI
- **Submodule refs** — update submodule refs in this root repo after pushing changes to a submodule (`git add <submodule> && git commit`)
- **No cross-submodule imports** — shared code lives in `scanner/`, `core/`, `ui/`, or `streamer/`; apps depend on these as npm packages or local references

## Working on a Submodule

1. `cd` into the submodule directory
2. Read its own CLAUDE.md (if present) for package-specific commands and conventions
3. Work on a branch, commit, push within that submodule
4. Come back to root and commit the updated submodule ref
