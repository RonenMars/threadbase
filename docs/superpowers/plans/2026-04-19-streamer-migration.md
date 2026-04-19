# Plan: Migrate from `cch` to `threadbase-streamer`

**Context:** The Go `cch serve` binary has been replaced by `@threadbase/streamer` (TypeScript). The LaunchAgent still runs the old Go binary. Mobile is now stable (RunAtLoad/KeepAlive enabled), but the migration to the TS streamer has four API compatibility issues to resolve.

---

## What mobile uses

| Endpoint | Used by | Notes |
|---|---|---|
| `GET /api/conversations` | History screen (list) | Works with both; field names differ |
| `GET /api/conversations/:id` | Conversation detail | Old Go format required; new TS format different |
| `POST /api/sessions/resume` | "Resume Session" button | Missing `projectPath` in mobile request |
| `GET /api/info` | Connection check (Settings) | Field name mismatch: `hostname` vs `machineName` |
| `WebSocket /ws` | Sessions screen | Already compatible |

---

## Issue 1: List endpoint — field name mapping

**`cch` returns:**
```json
{ "conversations": [{ "id", "title", "projectPath", "branch", "messageCount", "lastActivity" }], "hasMore", "offset", "total" }
```

**Streamer returns** (`ConversationMeta` from `@threadbase/scanner`):
```json
{ "conversations": [{ "id", "projectName", "projectPath", "gitBranch", "timestamp", ... }], "hasMore", "offset", "total" }
```

**Fix (in `streamer/src/server.ts` `handleListConversations`):** Map scanner fields to the mobile-expected names before returning.

```typescript
const adapted = (result.conversations as ConversationMeta[]).map((c) => ({
  id: c.id,
  title: c.projectName,
  projectPath: c.projectPath,
  branch: c.gitBranch ?? undefined,
  messageCount: c.messageCount,
  lastActivity: c.timestamp,
}));
json(res, 200, { conversations: adapted, hasMore: ..., offset, total: result.total });
```

---

## Issue 2: Detail endpoint — response shape

**`cch` returns:**
```json
{
  "meta": { "id", "project_name", "project_path", "last_updated_at", "message_count", "profile_id", "file_path", ... },
  "messages": [{ "role", "timestamp", "text", "tool_calls": ["Bash"], "content": [{ "type": "tool_use", "id", "name", "input" }] }]
}
```

**Streamer** (`getConversation` from scanner) returns a `Conversation` object directly:
```json
{
  "id", "filePath", "projectPath", "projectName", "sessionId",
  "messages": [{ "role", "text", "timestamp", "metadata": { "toolUseBlocks": [...], "toolResults": [...] } }]
}
```

Mobile's `adaptDetail` (in `useConversations.ts:132`) is hard-wired to the `{ meta, messages }` Go format.

**Fix options (pick one):**

**A. Wrap in streamer** — adapt the scanner's `Conversation` to the old Go shape before sending. Keeps mobile untouched.
```typescript
// in handleGetConversation
json(res, 200, {
  meta: {
    id: conversation.id,
    profile_id: conversation.account,
    project_name: conversation.projectName,
    project_path: conversation.projectPath,
    file_path: conversation.filePath,
    last_updated_at: conversation.timestamp,
    message_count: conversation.messageCount,
  },
  messages: conversation.messages.map((m) => ({
    role: m.role,
    timestamp: m.timestamp,
    text: m.text,
    tool_calls: m.metadata?.toolUses ?? [],
    content: [
      ...(m.metadata?.toolUseBlocks ?? []).map((b) => ({
        type: "tool_use", id: b.id, name: b.name, input: b.input,
      })),
      ...(m.metadata?.toolResults ?? []).map((r) => ({
        type: "tool_result", tool_use_id: r.toolUseId,
        content: JSON.stringify(r.content), is_error: r.isError ?? false,
      })),
    ],
  })),
});
```

**B. Update mobile adapter** — add format detection to `adaptDetail`:
```typescript
function adaptDetail(raw: RawConversationDetail | Conversation): ConversationDetail {
  if ("meta" in raw) {
    // old Go format — existing logic unchanged
  } else {
    // new scanner format
  }
}
```

**Recommendation: Option A** — one place to fix, mobile stays stable.

---

## Issue 3: Resume endpoint — missing `projectPath`

**Mobile sends:**
```json
{ "conversationId": "abc-123" }
```

**Streamer requires** (both fields, returns 400 otherwise):
```json
{ "conversationId": "abc-123", "projectPath": "/Users/ronen/..." }
```

**Fix (in `streamer/src/server.ts` `handleResume`):** Look up `projectPath` from the conversation when not provided:
```typescript
const { conversationId, projectPath: explicitPath } = body;
if (!conversationId) { json(res, 400, { error: "Missing conversationId" }); return; }

let projectPath = explicitPath;
if (!projectPath) {
  const conv = await getConversation(conversationId);
  if (!conv) { json(res, 404, { error: "Conversation not found" }); return; }
  projectPath = conv.projectPath;
}
```

---

## Issue 4: Info endpoint — field names

**Mobile's `ServerInfo` type expects:**
```typescript
{ version: string; machineName: string; platform: string; activeSessions: number }
```

**Streamer returns:**
```typescript
{ version: "0.1.0"; hostname: string; platform: string }  // no activeSessions, uses "hostname" not "machineName"
```

**Fix (in `handleInfo`):**
```typescript
json(res, 200, {
  version: "0.1.0",
  machineName: hostname(),
  platform: process.platform,
  activeSessions: this.sessionStore.list().filter((s) => s.status === "running").length,
});
```

---

## Issue 5: API key

**`cch`** reads from `~/.threadbase/server.yaml` → `api_key: tb_123`.

**Streamer** calls `loadOrCreateApiKey()` — reads from `~/.threadbase/api-key` or generates a random one.

**Fix:** Pass `--api-key tb_123` in the LaunchAgent, OR update `loadOrCreateApiKey()` to also check `~/.threadbase/server.yaml` as a fallback.

**Recommendation:** Just pass it in the plist. Explicit is better.

---

## Implementation steps

### Step 1 — Apply streamer fixes
In `streamer/src/server.ts`:
1. Fix `handleListConversations` (Issue 1)
2. Fix `handleGetConversation` (Issue 2, Option A)
3. Fix `handleResume` (Issue 3)
4. Fix `handleInfo` (Issue 4)

### Step 2 — Build and install
```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/streamer
npm run build
# link the CLI binary
sudo ln -sf "$(pwd)/dist/cli.js" /usr/local/bin/threadbase-streamer
chmod +x dist/cli.js
```

### Step 3 — Update LaunchAgent
Edit `dotfiles/LaunchAgents/com.ronen.threadbase.plist`:
- Replace `cch serve --port 8766 --verbose` with `threadbase-streamer serve --port 8766 --api-key tb_123 --verbose`
- Update PATH to include node binary location

### Step 4 — Reload and smoke test
```bash
launchctl unload ~/Library/LaunchAgents/com.ronen.threadbase.plist
launchctl load ~/Library/LaunchAgents/com.ronen.threadbase.plist
curl -H "Authorization: Bearer tb_123" http://localhost:8766/api/conversations?limit=3
curl -H "Authorization: Bearer tb_123" http://localhost:8766/api/info
```

### Step 5 — Commit changes
- `streamer/src/server.ts` — the four compatibility fixes
- `dotfiles/LaunchAgents/com.ronen.threadbase.plist` — updated binary + args

---

## Test checklist
- [ ] History screen loads conversations
- [ ] Conversation detail opens and shows messages with tool cards
- [ ] "Resume Session" button works (starts a PTY session)
- [ ] Settings screen shows correct server info (`machineName`, not `hostname`)
- [ ] Service survives a restart (`RunAtLoad: true`, `KeepAlive: true`)
