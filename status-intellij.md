# threadbase-intellij — Status & Action Items

**Last scanned:** 2026-04-12  
**Language:** Kotlin 2.3 · IntelliJ Platform Gradle Plugin 2.13 · React 18 (JCEF webview)  
**Visibility:** Private

---

## Status

The IntelliJ plugin is the most complete and best-tested of the suite. All 13 planned phases are implemented. The Gradle build **passes** (`./gradlew build`), the plugin ZIP artifact is produced, and all automated tests pass. The main gaps are 6 ignored UI test stubs, a simplified search engine, and missing lazy-loading for large conversations.

### What's working
- Gradle build passing; plugin ZIP at `build/distributions/claude-history-intellij-1.0.0.zip`
- GitHub Actions CI pipeline (build + test + verifyPlugin)
- Swing tree panel with async tree model, speed search, git branch badges
- JCEF webview rendering React conversation viewer with 8+ tool cards, syntax highlighting
- Fallback plain-text panel when JCEF is unavailable
- Kotlin ↔ JS bridge (JBCefJSQuery) for copy, export, open-external, continue-chat
- Multi-profile support with `ProfileManager`; profile pre-warming on IDE startup
- Full-text search (in-memory substring index) across project, preview, session ID, account, model
- Sort options, date-range filter, project filter
- Terminal integration: `claude --resume <uuid>` with `CLAUDE_CONFIG_DIR` injection; clipboard fallback
- Export (Markdown / JSON / text) via native `FileSaverDescriptor`
- Context menu: open, resume, export, copy session ID
- Settings persistence via `PersistentStateComponent` (sort, date range, last query, default profile)
- Conversation editor provider (opens sessions in editor tabs)
- Message navigation toolbar, token counts, model + stop-reason display
- Git branch detection by walking up to `.git/HEAD`
- Task/TodoWrite tool card rendering
- 16 test files; core layer fully covered; integration tests pass

### What's incomplete / missing
- 6 test stubs marked `@Ignore` in `ConversationWebViewPanelTest`, `DisposalTest`, `FallbackPanelTest`
- Search engine is naive substring matching — `PLAYBOOK.md` references Lucene 9.x but it was never implemented
- No pagination or lazy-loading in the React webview — large conversations (100+ messages) load all at once
- No user-facing notifications for JSONL parse failures, profile load errors, or terminal creation failures
- Tree expansion state and last-opened conversation are not persisted across IDE restarts
- No second-level caching of parsed conversation full text (every open re-reads JSONL)

---

## Action Items

### High
- [ ] Implement the 6 ignored test stubs:
  - `ConversationWebViewPanelTest`: `copyMessage`, `openExternal`, `continueChat` handler tests, theme-injection assertion
  - `DisposalTest`: verify `Disposer.isDisposed(browser)` after panel dispose
  - `FallbackPanelTest`: mock `JBCefApp.isSupported() = false` and verify fallback panel renders
- [ ] Decide on search strategy: either remove the Lucene reference from `PLAYBOOK.md` or implement a real Lucene 9.x index — the current mismatch between docs and code is confusing
- [ ] Add `NotificationGroupManager` alerts for JSONL parse failures, profile deserialization errors, and terminal creation failures so users know when something went wrong

### Medium
- [ ] Implement pagination or virtual scrolling in the React webview for conversations with 100+ messages — currently all messages load at once and will OOM on large sessions
- [ ] Add a second-level cache in `HistoryService` for parsed conversation full text so repeated opens of the same conversation don't re-read JSONL
- [ ] Extend `HistorySettings` to persist tree expansion state and last-opened conversation ID
- [ ] Add `--verbose` / debug-mode logging path through `HistoryService` and `ConversationScanner` so parse-error counts are visible when needed
- [ ] Validate `TerminalManager.buildResumeCommand()` against the real `claude --resume` CLI — it's mocked in tests but never smoke-tested against the actual binary

### Low
- [ ] Document the trade-off decision: why in-memory index vs. persistent Lucene index (startup speed vs. no warm cache benefit across restarts)
- [ ] Add CSS variable injection for light/dark theme switching in the webview — theme detection exists but the bridge call to inject data-theme attribute is in the ignored test
- [ ] Implement incremental JSONL re-scanning (delta based on file mtime) instead of full re-scan on every IDE startup
- [ ] Persist tree expansion state (which project folders are open) to `HistorySettings` so the tree reopens in the same state after IDE restart
