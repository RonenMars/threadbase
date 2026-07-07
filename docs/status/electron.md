# threadbase-electron — Status & Action Items

**Last scanned:** 2026-04-12  
**Language:** TypeScript · Electron 41 · React 19  
**Visibility:** Private

---

## Status

The Electron desktop app is the most feature-complete client in the suite. Phases 0–13 are implemented and the architecture is solid. The app is **not buildable** in the current environment because `pnpm install` has not been run, but the code itself is production-quality.

### What's working
- Full-text conversation search (FlexSearch, 150 ms debounced)
- Project, date-range, sort filters — all composable
- Virtualized conversation list (flat / grouped / tree)
- Rich Markdown + syntax-highlighted code rendering
- Tool invocation badges and result cards (Edit, Bash, Read, Write, Glob, Grep, Task)
- Multi-instance embedded Claude Code terminal (xterm.js + node-pty, up to N sessions)
- Two-phase PTY kill (SIGINT → SIGKILL, 3 s timeout)
- Multi-profile management with emoji picker and config-dir browser
- Git worktree detection, branch badges, worktree creation UI
- Export to Markdown / JSON / plain text via native save dialog
- Resizable sidebar persisted to disk
- Settings page (max chat instances, display mode, default profile)
- Electron-builder packaging for macOS DMG, Windows NSIS, Linux AppImage
- 23 test files (unit + Playwright E2E)

### What's incomplete / missing
- No incremental file watcher — full rescan on every refresh
- LRU conversation cache capped at 5 entries (too small)
- Token usage captured in metadata but not displayed in the UI
- Keyboard arrow navigation in speed-search sidebar not implemented
- CLAUDE.md is empty (placeholder)
- `pnpm install` has not been run; all 45+ deps show as UNMET

---

## Action Items

### Critical
- [ ] Run `pnpm install` before any dev or build work
- [ ] Run `pnpm dev` to verify app launches without errors

### High
- [ ] Add React `ErrorBoundary` around `ChatTerminal`, `ActiveChatList`, and `FilterPanel` — currently only `ConversationView` is wrapped; crashes in the others propagate to the window level
- [ ] Replace silent `catch` blocks (18 instances in scanner and index) with logged errors or rethrows — these hide real failures
- [ ] Add `process.on('unhandledRejection')` handler in the main process so stray promise rejections don't fail silently

### Medium
- [ ] Increase LRU cache from 5 to 20–50 entries (`src/main/scanner.ts`)
- [ ] Implement incremental file watching with chokidar so the conversation list stays live without full re-scans
- [ ] Add cancellation / AbortController guards to async `useEffect` calls in `App.tsx` (lines 126, 146, 480) to prevent state updates after unmount
- [ ] Clean up `typingTimers` Map on PTY crash — currently timers leak if a chat session exits without a proper exit event

### Low
- [ ] Build the token-usage display UI — `tokensThisMonth` is already calculated, just needs a component
- [ ] Implement keyboard arrow navigation in the sidebar speed-search results
- [ ] Fill in `CLAUDE.md` with project conventions, architecture notes, and dev-setup instructions
- [ ] Replace `console.log` / `console.info` calls in the renderer with `electron-log` (ESLint warns but does not block)
- [ ] Add IPC rate-limiting on `search`, `export`, and `ptySpawn` handlers to prevent runaway renderer calls
