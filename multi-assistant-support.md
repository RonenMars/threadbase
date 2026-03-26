# Multi-Assistant Support Plan

> Written 2026-03-16. Based on research into 7 AI coding assistant tools beyond Claude Code.
> Goal: adapt the threadbase suite (Electron, VS Code, IntelliJ, CLI) to browse, search, and resume sessions from multiple AI coding assistants.

---

## Research Summary: Where Each Tool Stores History

| Tool | Storage Path | Format | Resume Command | Priority |
|---|---|---|---|---|
| **Claude Code** ✅ | `~/.claude/projects/*/*.jsonl` | JSONL | `claude --resume <id>` | Current |
| **OpenAI Codex CLI** | `~/.codex/sessions/YYYY/MM/DD/rollout-<ts>-<uuid>.jsonl` | JSONL (tagged lines) | `codex resume [id]` | **Tier 1** |
| **Continue.dev** | `~/.continue/sessions/<uuid>.json` + `sessions.json` index | JSON | Extension sidebar | **Tier 1** |
| **OpenCode** | `~/.local/share/opencode/<project-hash>/sessions.db` | SQLite (Drizzle) | TUI session list | **Tier 2** |
| **Amazon Q Developer CLI** | `~/.local/share/amazon-q/data.sqlite3` | SQLite (keyed by CWD) | `q chat --resume` | **Tier 2** |
| **Cline** | `~/Library/.../globalStorage/saoudrizwan.claude-dev/tasks/<id>/` | JSON per task | VS Code sidebar | **Tier 3** |
| **Cursor** | `~/Library/.../Cursor/User/workspaceStorage/<hash>/state.vscdb` | SQLite (VS Code format, reverse-engineered) | IDE only | **Tier 3** |
| **Aider** | `./.aider.chat.history.md` (per project CWD) | Markdown append-only | `--restore-chat-history` flag | **Tier 3** |

**Tier rationale:**
- **Tier 1**: Format closest to Claude Code (JSONL/JSON), has structured fields, CLI resume exists
- **Tier 2**: SQLite-based, well-documented schema, CLI resume exists
- **Tier 3**: IDE-only, reverse-engineered, or unstructured format — lower ROI

---

## Architecture: The Provider Pattern

All 4 apps need a **provider abstraction** that decouples the "where data lives + how it's parsed" from the "how data is displayed + searched."

### Unified Session Model (language-agnostic)

Every provider maps its data to this common model:

```
ProviderSession {
  id: string           // provider-specific session/rollout ID
  provider: string     // "claude" | "codex" | "continue" | "opencode" | "amazonq" | "cline"
  projectPath: string  // working directory when session was created
  title: string        // first user message or auto-title
  messageCount: int
  lastModified: timestamp
  model: string        // model name/ID if available
  gitBranch: string?   // from .git/HEAD relative to projectPath
  messages: Message[]  // loaded on demand
}

Message {
  role: "user" | "assistant" | "tool"
  content: string
  toolUse: ToolUse[]?
  toolResult: ToolResult[]?
  inputTokens: int?
  outputTokens: int?
  model: string?
}
```

### Provider Interface

**TypeScript (Electron + VS Code):**
```typescript
interface AssistantProvider {
  id: string                     // "codex" | "continue" | etc.
  displayName: string            // "OpenAI Codex CLI"
  defaultPaths: string[]         // candidate paths to scan
  isAvailable(): Promise<boolean>
  scanSessions(paths: string[]): Promise<ProviderSession[]>
  loadSession(session: ProviderSession): Promise<ProviderSession>
  resumeCommand(session: ProviderSession): string | null
}
```

**Kotlin (IntelliJ):** same pattern as a Kotlin interface
**Go (CLI):** same pattern as a Go interface

---

## Per-App Implementation Plan

### App 1: claude-search (Electron)

**Milestone 2: Multi-Assistant Support**

#### Phase 1: Provider Abstraction + Codex Provider
**Goal:** Establish the provider pattern with the first non-Claude provider.

**Tasks:**
- Extract `ClaudeProvider` from existing scanner/indexer into `src/main/providers/claude.ts` implementing `AssistantProvider`
- Create `src/main/providers/registry.ts`: loads all enabled providers, merges sessions from all into a unified list
- Create `src/main/providers/codex.ts`:
  - Scans `~/.codex/sessions/**/*.jsonl`
  - Parses JSONL lines by `type` field: `session_meta` → session header, `event_msg` (UserMessage) + `response_item` → messages, `TokenCount` → token metadata
  - `resumeCommand`: `codex resume <session-id>`
- Add provider badge (`[codex]`, `[claude]`) to conversation list items
- Add provider filter to `FilterPanel` (multi-select checkboxes, persisted to settings)
- Settings page: "Enabled Providers" list with path overrides per provider

**Success Criteria:**
- Codex sessions appear alongside Claude sessions in the list
- Provider badge distinguishes them visually
- Provider filter works correctly
- Claude behavior unchanged when Codex is disabled or not installed

#### Phase 2: Continue.dev + OpenCode Providers
**Goal:** Add the two next-priority providers.

**Continue.dev tasks (`src/main/providers/continue.ts`):**
- Scan `~/.continue/sessions/sessions.json` index for session metadata
- Load individual `~/.continue/sessions/<uuid>.json` for full message content
- Map `ChatHistoryItem[]` → `Message[]` (role/content/contextItems)
- No CLI resume — show "Open in IDE" notification

**OpenCode tasks (`src/main/providers/opencode.ts`):**
- Locate `~/.local/share/opencode/<project-hash>/sessions.db` (or macOS equivalent via `$XDG_DATA_HOME`)
- Use `better-sqlite3` (already available in Electron) to query:
  - `SELECT * FROM session ORDER BY time_created DESC`
  - `SELECT * FROM message WHERE session_id = ?`
  - `SELECT * FROM part WHERE message_id IN (...)`
- Reconstruct message content from `part.data` discriminated union
- `resumeCommand`: none (TUI only) — stub with "open OpenCode in this directory"

**Success Criteria:**
- Continue and OpenCode sessions indexed and searchable
- SQLite reader isolated so it fails gracefully if `sessions.db` absent

#### Phase 3: Amazon Q Developer + Aider Providers (Optional)
**Goal:** Cover the Tier 2/3 tools for completeness.

**Amazon Q tasks (`src/main/providers/amazonq.ts`):**
- Query `~/.local/share/amazon-q/data.sqlite3` → `conversations` table
- Key is the CWD path; value is JSON `ConversationState`
- Deserialize `history: HistoryEntry[]` into messages
- `resumeCommand`: `q chat --resume` (starts new session in same CWD context)

**Aider tasks (`src/main/providers/aider.ts`):**
- Walk workspace paths looking for `.aider.chat.history.md` files
- Parse markdown: split on `# aider chat started at <datetime>` headers → sessions
- Within each session, split on `> ` prefix → user messages; remainder → assistant
- No structured token counts or model info (show as "Aider session" with message count only)
- Explicitly limited: Aider history is per-project-directory, no global index

**Success Criteria:**
- Q sessions and Aider transcripts browsable in the app
- Aider parser handles append-only multi-session files correctly

---

### App 2: vscode-claude-code-manager (VS Code Extension)

**Milestone 2: Multi-Assistant Support**

#### Phase 1: Provider Abstraction + Codex Provider
**Tasks:**
- Extract provider interface to `src/core/providers/provider.ts` (matches the TypeScript interface above)
- Extract `ClaudeProvider` to `src/core/providers/claude.ts`
- Add `src/core/providers/codex.ts` (same logic as Electron, since both run on Node.js)
- `HistoryService` gains `enabledProviders: string[]` state (persisted to `globalState`)
- `ConversationTreeProvider` groups by provider if multiple providers active
- Add `claudeHistory.configureProviders` command: QuickPick multi-select to enable/disable providers
- Provider badge on `TreeItem` description (e.g. `[codex]`)

#### Phase 2: Continue.dev + OpenCode
- Same provider implementations as Electron (shared logic in `src/core/providers/`)
- Continue.dev: no resume button (IDE-internal)
- OpenCode: SQLite read via `better-sqlite3` in extension host (Node.js process)

#### Phase 3: Amazon Q + Aider
- Same as Electron

**Cross-phase constraint:** The VS Code extension bundles with esbuild. `better-sqlite3` is a native module and requires `.node` binary inclusion. Consider using `sql.js` (WASM) instead for the extension host to avoid native module packaging complexity.

---

### App 3: intellij-claude-code-manager (IntelliJ Plugin)

**Milestone 3: Multi-Assistant Support**

#### Phase 1: Provider Abstraction + Codex Provider
**Tasks:**
- Add `AssistantProvider` interface in `core/providers/AssistantProvider.kt`
- Extract `ClaudeProvider` from existing `ConversationScanner.kt`
- Add `CodexProvider.kt`:
  - Scan `~/.codex/sessions/**/*.jsonl` using existing JSONL parser (similar line format)
  - Map `type: "event_msg"` UserMessage → user turn, `type: "response_item"` → assistant turn
  - Resume: `TerminalManager.send("codex resume ${session.id}")`
- `HistoryService` iterates all enabled providers, merges results
- Tree view: add provider icon/badge to `ConversationNode`
- Settings: `HistorySettings` gains `enabledProviders: List<String>` field

#### Phase 2: Continue.dev + OpenCode (SQLite)
**Tasks:**
- `ContinueProvider.kt`: read `~/.continue/sessions/` JSON files using kotlinx-serialization
- `OpenCodeProvider.kt`: query SQLite via `org.xerial:sqlite-jdbc` (add to build.gradle.kts)
  - Use `gradle-intellij-specialist` skill for dependency addition
  - Query `session`, `message`, `part` tables
- Both providers mapped to `ConversationMeta` domain model

#### Phase 3: Amazon Q + Aider
- `AmazonQProvider.kt`: same SQLite approach
- `AiderProvider.kt`: Markdown parser (regex-based, no external dependency)

---

### App 4: threadbase-cli (`cch`)

**Milestone 2: Multi-Assistant Support**

#### Phase 1: Provider Abstraction + Codex Provider
**Tasks:**
- Add `Provider` interface to `internal/domain/types.go`:
  ```go
  type Provider interface {
      ID() string
      Scan(paths []string) ([]*SessionMeta, error)
      LoadSession(meta *SessionMeta) (*Session, error)
      ResumeCommand(meta *SessionMeta) string
  }
  ```
- Extract `ClaudeProvider` from existing scanner
- Add `internal/providers/codex/codex.go`:
  - Walk `~/.codex/sessions/` tree for JSONL files
  - Parse by `type` field (same JSONL format as Claude Code, different field names)
- Add `--provider` / `-p` flag to `list`, `search`, `show`, `resume` commands:
  - `--provider all` (default when multiple installed), `--provider claude`, `--provider codex`
  - Auto-detect available providers when flag is `all`
- `cch list` shows `PROVIDER` column when multiple providers active
- `cch resume` routes to the correct resume command per provider

#### Phase 2: Continue.dev + OpenCode
**Tasks:**
- `internal/providers/continue/continue.go`: read JSON session files
- `internal/providers/opencode/opencode.go`:
  - Use `modernc.org/sqlite` (pure-Go SQLite, no CGO required) for SQLite reads
  - Add `modernc.org/sqlite` to `go.mod`

#### Phase 3: Amazon Q + Aider
- `internal/providers/amazonq/amazonq.go`: SQLite read (same driver)
- `internal/providers/aider/aider.go`: Markdown parser for `.aider.chat.history.md`

---

## Implementation Priority

Start with **Codex CLI** across all 4 apps simultaneously — it's the most structurally similar to Claude Code (JSONL format, CLI resume command) and gives the provider abstraction a real workout before tackling the SQLite tools.

```
Suggested execution order:
1. Core abstraction + Codex provider (all 4 apps in parallel)
2. Continue.dev (all 4 apps — JSON format, straightforward)
3. OpenCode + Amazon Q (all 4 apps — SQLite, shared patterns)
4. Aider + Cursor (optional, lower priority)
```

---

## Cross-Cutting Concerns

### Provider Discovery
Each app should auto-detect which providers are installed:
- Claude Code: check if `~/.claude/` exists
- Codex: check if `~/.codex/` exists or `codex` is in PATH
- OpenCode: check if `~/.local/share/opencode/` exists
- Amazon Q: check if `~/.local/share/amazon-q/data.sqlite3` exists
- Continue: check if `~/.continue/sessions/` exists
- Cline: check VS Code globalStorage path

Auto-enable detected providers on first run; show a notification ("Codex CLI detected — added to session browser").

### Native Modules (Electron + VS Code)
`better-sqlite3` requires native binaries. For VS Code extension: prefer `sql.js` (WASM) to avoid `electron-rebuild` complexity. For Electron: `better-sqlite3` works fine since electron-builder handles native module rebuilding.

### Feature Parity Expectations
Not all providers will have all features:
| Feature | Claude | Codex | Continue | OpenCode | Q | Aider |
|---|---|---|---|---|---|---|
| Full message content | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Token counts | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Tool call cards | ✅ | ✅ | Partial | ✅ | ✅ | ❌ |
| Model name | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| CLI resume | ✅ | ✅ | ❌ | ❌ | ✅ | Partial |
| Git branch | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

### Naming
The apps ("Claude Code Manager", "Claude History") should be renamed if supporting multiple tools. Suggested: **"AI Session Browser"** or keep the current name with a sub-header "now supporting multiple assistants."
