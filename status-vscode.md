# threadbase-vscode — Status & Action Items

**Last scanned:** 2026-04-12  
**Language:** TypeScript · VS Code Extension API 1.85+ · React 19 (webview)  
**Visibility:** Private

---

## Status

The VS Code extension covers Stages 0–5 and is approximately **70% complete**. The core search, browsing, and export pipeline is solid. Stages 6–9 (profile management UI, git worktree UI, chat terminal, settings panel) are deferred. The extension **cannot be built or tested** in the current environment because `npm install` has never been run and all 19 dependencies are UNMET.

### What's working
- Full-text search with FlexSearch across conversation content
- TreeView sidebar grouped by project (with path compaction)
- Multi-profile support; provider registry with `Promise.allSettled` (failed providers don't abort scan)
- Project + date-range filters; sort options (recent, oldest, most-messages, alpha)
- Rich conversation viewer in a JCEF webview — 8+ tool cards, syntax highlighting, search highlighting
- Message navigation (prev/next, jump-to index), copy to clipboard
- Export (Markdown / JSON / text) via native save dialog
- Live file watcher detecting active conversations (5 s active / 35 s expiry)
- Settings persistence: sort, filter, date range, search query survive reload
- Multi-assistant support: Claude + Codex CLI providers
- Session resume via VS Code terminal (`claude --resume <uuid>`)
- Subagent navigation, team thread badges
- Monorepo with platform-agnostic `packages/threadbase-core/` shared package
- CSP nonce on webview scripts (XSS protection)
- 14 test files covering core scanner, indexer, filters, profiles, providers

### What's incomplete / missing
- Profile management UI — users must edit `profiles.json` by hand (Stage 6)
- Git worktree detection and branch badges (Stage 7)
- Chat terminal (xterm.js + node-pty) (Stage 8)
- Active chat session list (Stage 8)
- Settings panel (Stage 9)
- `npm install` not run; build outputs (`out/`) do not exist

---

## Action Items

### Critical
- [ ] Run `npm install` in the repo root to restore all 19 UNMET dependencies
- [ ] Run `npm run build` to generate `out/` directory and verify build succeeds

### High
- [ ] Move inline `require('path')` and `require('os')` calls in `extension.ts` (lines 92–94) and `HistoryService.ts` (lines 107–114) to top-level imports
- [ ] Replace `console.error` in all error paths with `outputChannel.appendLine(...)` so users can see diagnostics in the VS Code Output panel
- [ ] Add exhaustive type check on `onDidReceiveMessage` dispatch — new message types will silently no-op if not handled
- [ ] Replace `ConversationPanel.panels` static `Map` with explicit lifecycle tracking; consider `WeakMap` or guaranteed disposal validation to prevent memory leaks

### Medium
- [ ] Add integration tests for `TreeProvider` and `ConversationPanel` — these are currently untested
- [ ] Add React component tests for the webview UI (currently zero webview tests)
- [ ] Add pre-commit hooks (lint + format + test) to prevent regressions
- [ ] Add JSDoc comments to public classes and methods (`HistoryService`, `ConversationPanel`, `AssistantProvider`, etc.)
- [ ] Remove `@tanstack/react-virtual` from `package.json` — it is imported but never used

### Low
- [ ] Implement profile management UI (Stage 6) so users don't have to manually edit `profiles.json`
- [ ] Implement git branch badge detection (Stage 7) — `worktree-parser.ts` already exists but is not integrated
- [ ] Evaluate replacing `@uiw/react-json-view@^2.0.0-alpha.41` (pre-release alpha) with a stable alternative
- [ ] Add accessibility (ARIA) labels to custom webview components
