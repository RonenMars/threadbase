# Threadbase Feature Comparison

> Generated 2026-03-16. Compares the 4 functional apps across all feature categories.
> Landing pages (`claude-history-landing-page-nextjs`, `threadbase-landing-codex`) excluded — marketing sites only.

| Feature | Electron (`claude-search`) | VS Code Ext | IntelliJ Plugin | CLI (`cch`) |
|---|:---:|:---:|:---:|:---:|
| **SEARCH & INDEXING** |
| Full-text search | ✅ FlexSearch | ✅ FlexSearch | ✅ Apache Lucene | ✅ |
| Search result highlighting | ✅ (previews + viewer) | ❌ | ❌ | ❌ |
| Two-tier indexing (metadata-first) | ✅ | ❌ | ❌ | ❌ |
| Batched scanning w/ progress bar | ✅ | ❌ | ❌ | ❌ |
| Debounced search (150ms) | ✅ | ❌ (QuickPick) | ❌ | ❌ |
| JSON output mode | ❌ | ❌ | ❌ | ✅ |
| **FILTERING & SORTING** |
| Filter by project | ✅ (autocomplete) | ❌ | ❌ | ❌ |
| Filter by date range (Today/7d/30d) | ✅ | ❌ | ❌ | ❌ |
| Filter by profile | ✅ (multi-profile) | ❌ | ❌ | ❌ |
| Sort: Most Recent | ✅ | ✅ (recency) | ✅ | ❌ |
| Sort: Oldest First | ✅ | ❌ | ❌ | ❌ |
| Sort: Most/Least Messages | ✅ | ❌ | ❌ | ❌ |
| Sort: Alphabetical | ✅ | ❌ | ❌ | ❌ |
| **CONVERSATION LIST** |
| Grouped-by-project view | ✅ | ✅ (TreeView) | ✅ (TreeView) | ❌ |
| Flat view toggle | ✅ | ❌ | ❌ | ✅ |
| Virtualized rendering | ✅ (`@tanstack/virtual`) | ❌ | ❌ | ❌ |
| Result counter (X of Y) | ✅ | ❌ | ❌ | ❌ |
| Resizable sidebar | ✅ (240–800px, persists) | ❌ | ❌ | ❌ |
| Live chat badges (Live/Typing/Awaiting) | ✅ | ❌ | ❌ | ❌ |
| Git branch badges | ✅ | ✅ | ❌ | ❌ |
| Profile emoji badges | ✅ | ❌ | ❌ | ❌ |
| Last message indicator | ✅ | ❌ | ❌ | ❌ |
| **CONVERSATION VIEWER** |
| GFM Markdown rendering | ✅ (react-markdown) | ✅ | ✅ (JCEF React) | ❌ |
| Syntax-highlighted code blocks | ✅ | ✅ | ✅ | ❌ |
| Edit diff cards (unified diff) | ✅ | ✅ | ✅ | ❌ |
| Bash tool cards | ✅ | ✅ | ✅ | ❌ |
| Read/Write tool cards | ✅ | ✅ | ✅ | ❌ |
| Glob/Grep tool cards | ✅ | ✅ | ✅ | ❌ |
| Task tool cards (Create/Update) | ✅ | ❌ | ❌ | ❌ |
| Generic fallback tool cards | ✅ | ✅ | ✅ | ❌ |
| Collapsible JSON pretty-printer | ✅ | ❌ | ❌ | ❌ |
| Message navigation (prev/next/jump) | ✅ | ✅ | ❌ | ❌ |
| Virtualized message scrolling | ✅ | ❌ | ❌ | ❌ |
| Token & model metadata per message | ✅ | ✅ | ❌ | ❌ |
| Copy message to clipboard | ✅ | ✅ | ❌ | ❌ |
| Error boundary | ✅ | ❌ | ❌ | ❌ |
| JCEF fallback (plain text) | N/A | N/A | ✅ | N/A |
| **EXPORT** |
| Export to Markdown | ✅ | ✅ | ✅ | ✅ |
| Export to JSON | ✅ | ✅ | ✅ | ❌ |
| Export to Plain Text | ✅ | ✅ | ✅ | ✅ |
| Native save dialog | ✅ | ✅ | ❌ | N/A |
| **TERMINAL / CHAT** |
| Resume past conversation | ✅ (embedded) | ❌ | ✅ (IDE terminal) | ✅ |
| Embedded xterm.js terminal | ✅ | ❌ | ❌ | N/A |
| Start new chat in project | ✅ | ❌ | ❌ | ❌ |
| Multi-instance chat (N tabs) | ✅ (configurable) | ❌ | ❌ | ❌ |
| Active chat sidebar w/ indicators | ✅ | ❌ | ❌ | ❌ |
| Profile selection on chat start | ✅ | ❌ | ❌ | ❌ |
| Force-stop (SIGINT → SIGKILL) | ✅ | ❌ | ❌ | ❌ |
| **PROFILES** |
| Multi-profile scanning | ✅ | ✅ | ✅ | ✅ |
| Per-profile stats (tokens, msg count) | ✅ | ❌ | ❌ | ❌ |
| Add/edit/delete profiles via UI | ✅ | ❌ | ✅ (dialogs) | ❌ |
| Emoji picker for profiles | ✅ | ❌ | ❌ | ❌ |
| Default profile setting | ✅ | ❌ | ❌ | ❌ |
| Config-dir browser | ✅ | ❌ | ❌ | ❌ |
| **GIT / WORKTREES** |
| Git branch display | ✅ | ✅ | ❌ | ❌ |
| Dedicated worktrees panel | ✅ | ❌ | ❌ | ❌ |
| Create worktree from viewer | ✅ | ❌ | ❌ | ❌ |
| Chat in worktree | ✅ | ❌ | ❌ | ❌ |
| Navigate to root project convo | ✅ | ❌ | ❌ | ❌ |
| **SETTINGS & PERSISTENCE** |
| Persistent UI preferences | ✅ (sidebar width, sort) | ❌ | ✅ (IDE storage) | ❌ |
| Settings UI (not modal) | ✅ | ❌ | ✅ | ❌ |
| Max chat instances slider | ✅ | ❌ | ❌ | ❌ |
| **KEYBOARD / ACCESSIBILITY** |
| Cmd/Ctrl+F search focus | ✅ | ✅ (QuickPick) | ✅ (`Ctrl+Shift+H`) | ❌ |
| Escape to clear search | ✅ | ✅ | ❌ | ❌ |
| Context menu (right-click) | ❌ | ❌ | ✅ (Open/Resume/Export/Copy ID) | ❌ |
| Speed search in tree | ❌ | ❌ | ✅ | ❌ |
| Workspace/project filter | ❌ | ✅ | ❌ | ❌ |

---

## Gap Summary by App

### Electron (`claude-search`) — missing vs. others
- Workspace/project filter scoped to current open folder (VS Code — inherent to IDE context, N/A)
- Context menus on list items (IntelliJ)
- Speed search in tree (IntelliJ)

### VS Code Extension — missing vs. Electron
- Date range, project, profile filters; sort options beyond recency
- Task tool cards, collapsible JSON, virtualized scrolling
- Embedded terminal / new chat / multi-instance chat
- Worktrees panel, profile stats/management, live chat badges
- Result counter, resizable sidebar, search highlighting, settings persistence

### IntelliJ Plugin — missing vs. Electron
- All VS Code gaps above, **plus**: message navigation, token/model metadata, copy message, git badges
- **Has unique**: context menus, speed search, IDE terminal resume, JCEF fallback

### CLI (`cch`) — missing vs. Electron (UI features N/A by design)
- Additional sort/filter flags (date range, message count)
- Profile management subcommands (add/edit/delete)
- Git branch display in output
- JSON output for `show` and `list` commands
