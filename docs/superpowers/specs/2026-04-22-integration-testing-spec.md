# Spec: Integration & Contract Testing

**Date:** 2026-04-22
**Design:** [2026-04-22-integration-testing-design.md](./2026-04-22-integration-testing-design.md)
**Status:** Draft — awaiting approval

---

## 1. Shared Fixtures

### Location

`scanner/__fixtures__/` (existing directory, already has 5 JSONL files).

### New fixtures to add

| File | Purpose |
|---|---|
| `contract-basic.jsonl` | Minimal 3-message conversation (user → assistant → user). Has sessionId, projectPath, gitBranch, sessionName. Used by all contract tests. |
| `contract-tool-use.jsonl` | Conversation with Edit, Bash, Read tool use blocks and tool results. Validates tool card rendering data flows through. |
| `contract-subagent.jsonl` | Parent conversation that spawned a subagent. Has `parentConversationId` and teammate metadata. |

These fixtures are deterministic — fixed UUIDs, timestamps, and content. They are not copies of real conversations.

### Fixture requirements

Each fixture must contain:
- Valid JSONL lines with `type`, `uuid`, `timestamp`, `sessionId`, `message` fields
- At least one `user` and one `assistant` message
- A `cwd` field pointing to a fake but realistic path (e.g., `/home/test/project`)
- Consistent `sessionId` and `slug` (sessionName) across all lines in the file

---

## 2. Contract Schemas

### Location

`streamer/contracts/`

### Schema files

| File | Describes | Validated against |
|---|---|---|
| `shared.schema.json` | Fields present in every consumer's response: `id`, `projectPath`, `messageCount` | Both mobile and desktop response objects |
| `mobile.schema.json` | Mobile-expected shapes for all endpoints (see below) | Streamer's adapted responses |
| `desktop.schema.json` | Electron-expected shapes (Transport interface return types) | Streamer's adapted responses |

### Schema format

JSON Schema Draft 2020-12, validated with `ajv` (added as a devDependency to streamer).

### Mobile schemas (in `mobile.schema.json`)

Derived from `mobile/types/api.ts`. The schema file contains named definitions for each endpoint response:

**`GET /api/conversations`** — `ConversationPage`:
```json
{
  "conversations": [{
    "id": "string",
    "title": "string",
    "sessionName": "string (optional)",
    "projectPath": "string",
    "branch": "string (optional)",
    "messageCount": "integer",
    "lastActivity": "string (ISO datetime)"
  }],
  "hasMore": "boolean",
  "offset": "integer",
  "total": "integer"
}
```

**`GET /api/conversations/:id`** — `{ meta, messages }` wrapper:
```json
{
  "meta": {
    "id": "string",
    "profile_id": "string (optional)",
    "project_name": "string",
    "project_path": "string",
    "file_path": "string",
    "last_updated_at": "string (ISO datetime)",
    "message_count": "integer"
  },
  "messages": [{
    "role": "string (user|assistant)",
    "timestamp": "string",
    "text": "string",
    "tool_calls": "array",
    "content": [{
      "type": "string (tool_use|tool_result)",
      "...": "varies by type"
    }]
  }]
}
```

**`GET /api/info`** — `ServerInfo`:
```json
{
  "version": "string",
  "machineName": "string",
  "platform": "string",
  "activeSessions": "integer"
}
```

**`GET /api/search`** — same shape as `GET /api/conversations` (wrapped in `ConversationPage`).

**`GET /api/sessions`** — array of `Session`:
```json
[{
  "id": "string",
  "status": "string (running|waiting_input|completed|failed|idle)",
  "projectPath": "string",
  "projectName": "string",
  "branch": "string (optional)",
  "lastOutput": "string",
  "elapsedMs": "number",
  "startedAt": "string (ISO datetime)",
  "source": "string (managed|discovered, optional)"
}]
```

### Desktop schemas (in `desktop.schema.json`)

Derived from `electron/src/shared/types.ts`. The Transport interface returns:

**`listConversations` / `search`** — `SearchResult[]`:
```json
[{
  "id": "string",
  "projectName": "string",
  "projectPath": "string",
  "sessionId": "string",
  "sessionName": "string",
  "preview": "string",
  "timestamp": "string",
  "messageCount": "integer",
  "score": "number",
  "lastMessageSender": "string (user|assistant)",
  "account": "string"
}]
```

**`getConversation`** — `Conversation`:
```json
{
  "id": "string",
  "filePath": "string",
  "projectPath": "string",
  "projectName": "string",
  "sessionId": "string",
  "sessionName": "string",
  "messages": [{ "type": "string", "content": "string", "timestamp": "string" }],
  "fullText": "string",
  "timestamp": "string",
  "messageCount": "integer",
  "account": "string"
}
```

**`getActiveSessions`** — `ActiveSession[]`:
```json
[{
  "id": "string",
  "instanceId": "string",
  "projectPath": "string",
  "projectName": "string",
  "status": "string",
  "lastOutput": "string",
  "elapsedMs": "number",
  "promptCount": "number",
  "startedAt": "string (ISO datetime)"
}]
```

---

## 3. Contract Tests

### Location

`streamer/__tests__/contracts/`

### Test files

| File | What it tests |
|---|---|
| `mobile-contracts.test.ts` | All mobile endpoint response shapes against `mobile.schema.json` |
| `desktop-contracts.test.ts` | All desktop endpoint response shapes against `desktop.schema.json` |
| `shared-contracts.test.ts` | Cross-consumer field guarantees against `shared.schema.json` |

### How they work

1. **Setup:** Create a `StreamerServer` instance that scans `scanner/__fixtures__/` instead of `~/.claude`. This requires making the scan directory configurable — either via a constructor option or by mocking the homedir.

2. **Per endpoint:** Make a real `fetch()` call to the running server, parse the JSON response, validate it against the schema with `ajv`.

3. **Failure message:** On schema mismatch, the test reports exactly which fields are missing, extra, or wrong-typed — not just "schema validation failed".

### Configuring scan directory

Add a `scanDir` option to `StreamerServer` config (or to the `scan()` call). In production this defaults to `~/.claude/projects`. In tests, it points to `../../scanner/__fixtures__/`.

This is the only production code change required.

---

## 4. HTTP E2E Tests

### Location

`streamer/__tests__/e2e/`

### Test file

`api-e2e.test.ts`

### What it covers

A single test suite that starts a real `StreamerServer` on a random port with fixture data, then exercises the full request/response cycle:

| Test case | Endpoint | Validates |
|---|---|---|
| List conversations | `GET /api/conversations?limit=3` | Returns fixture conversations, pagination fields correct |
| List with project filter | `GET /api/conversations?project=test` | Filters work against fixture data |
| Get conversation detail | `GET /api/conversations/:id` | Returns `{ meta, messages }` with tool use blocks from fixture |
| Search | `GET /api/search?q=hello` | Returns results matching fixture content |
| Server info | `GET /api/info` | Returns `machineName`, `platform`, `activeSessions` |
| Session list (empty) | `GET /api/sessions` | Returns empty array (no PTY sessions in test) |
| Resume without projectPath | `POST /api/sessions/resume` | Looks up projectPath from fixture conversation |
| Auth rejection | `GET /api/conversations` (no token) | Returns 401 |
| CORS headers | `OPTIONS /api/conversations` | Returns correct `Access-Control-*` headers |

Each response is also validated against the contract schemas (Tier 1), so E2E and contract tests share the same source of truth.

### Resume test note

The resume endpoint spawns a PTY. For the E2E test, mock `PTYManager.start()` to return a fake session without actually spawning `claude`. The test validates that:
- Missing `projectPath` triggers a conversation lookup
- The response contains a valid session object
- The session appears in subsequent `GET /api/sessions`

---

## 5. Schema Update Scripts

### Location

Scripts in `streamer/package.json`.

### Commands

```bash
npm run update-schema --mobile     # Regenerate mobile.schema.json
npm run update-schema --desktop    # Regenerate desktop.schema.json
npm run update-schema --shared     # Regenerate shared.schema.json
npm run update-schema              # Regenerate all three
```

### How they work

1. Start a `StreamerServer` with fixture data on a random port
2. Hit each endpoint relevant to the target consumer
3. Extract the JSON Schema from the actual response structure (using a helper like `json-schema-generator` or a custom function that walks the response and produces a schema)
4. Write the result to the corresponding `contracts/*.schema.json` file
5. Shut down the server

### Workflow

When a legitimate format change is made (e.g., adding a field to the list endpoint):
1. Run the relevant contract tests — they fail
2. Review the diff to confirm the change is intentional
3. Run `npm run update-schema --mobile` to accept the new shape
4. Re-run tests — they pass
5. Commit the updated schema file alongside the code change

---

## 6. Live Format Drift Detection (Tier 2B)

### Location

`scanner/scripts/capture-live.sh` and supporting TypeScript in `scanner/scripts/validate-live.ts`.

### Manual script: `npm run capture-live`

```bash
# In scanner/package.json
"capture-live": "bash scripts/capture-live.sh"
```

The script:
1. Runs `claude --print "what is 1+1"` (single-turn, minimal tokens)
2. Waits for the process to exit
3. Finds the most recent `.jsonl` file in `~/.claude/projects/` (by mtime)
4. Copies it to `scanner/__fixtures__/baseline-live.jsonl`
5. Runs `npx tsx scripts/validate-live.ts` which:
   - Parses the captured file with `parseMeta()` and `parseConversation()`
   - Compares the field names and types against the previous baseline
   - Reports additions, removals, and type changes
   - Exits 0 if no breaking changes, 1 if breaking changes detected

### Update baseline: `npm run update-baseline`

```bash
# In scanner/package.json
"update-baseline": "cp scanner/__fixtures__/baseline-live.jsonl scanner/__fixtures__/baseline-live.prev.jsonl && bash scripts/capture-live.sh"
```

Saves the previous baseline as `.prev.jsonl` and captures a fresh one.

### Weekly CI job

Runs `npm run capture-live` on a schedule. If the script exits 1 (breaking change detected), the CI job opens a GitHub issue with the diff.

**Requirement:** The CI runner must have `claude` CLI installed and an API key configured. This can run on a self-hosted runner or a scheduled GitHub Action with the Anthropic API key in secrets.

---

## 7. New Dependencies

| Package | Where | Purpose |
|---|---|---|
| `ajv` | streamer (devDependency) | JSON Schema validation in contract tests |
| `ajv-formats` | streamer (devDependency) | Format validation (date-time, uri, etc.) |

No new production dependencies.

---

## 8. Production Code Changes

Only one change to production code:

**`streamer/src/server.ts`** — Make the scan directory configurable:

```typescript
// In StreamerServer constructor config
interface ServerConfig {
  // ... existing fields ...
  scanDir?: string  // Override scan directory (default: ~/.claude/projects)
}
```

The `handleListConversations`, `handleGetConversation`, and `handleSearch` methods pass this directory to the `scan()` / `getConversation()` calls.

---

## 9. npm Scripts Summary

### streamer/package.json

```json
{
  "test:contracts": "vitest run __tests__/contracts/",
  "test:e2e": "vitest run __tests__/e2e/",
  "update-schema": "tsx scripts/update-schema.ts",
  "update-schema:mobile": "tsx scripts/update-schema.ts --mobile",
  "update-schema:desktop": "tsx scripts/update-schema.ts --desktop",
  "update-schema:shared": "tsx scripts/update-schema.ts --shared"
}
```

### scanner/package.json

```json
{
  "capture-live": "bash scripts/capture-live.sh",
  "update-baseline": "bash scripts/update-baseline.sh"
}
```

---

## 10. File Tree (new files only)

```
scanner/
  __fixtures__/
    contract-basic.jsonl          (new)
    contract-tool-use.jsonl       (new)
    contract-subagent.jsonl       (new)
    baseline-live.jsonl           (new, generated)
  scripts/
    capture-live.sh               (new)
    update-baseline.sh            (new)
    validate-live.ts              (new)

streamer/
  contracts/
    shared.schema.json            (new, generated)
    mobile.schema.json            (new, generated)
    desktop.schema.json           (new, generated)
  scripts/
    update-schema.ts              (new)
  __tests__/
    contracts/
      mobile-contracts.test.ts    (new)
      desktop-contracts.test.ts   (new)
      shared-contracts.test.ts    (new)
    e2e/
      api-e2e.test.ts             (new)
```

---

## 11. What's NOT in scope

- Mobile app E2E tests running against real streamer (follow-up)
- Electron transport tests against real streamer (follow-up when electron migrates off `cch`)
- VS Code / IntelliJ tests (they use scanner directly, no HTTP boundary)
- `@threadbase/ui` component tests
- WebSocket contract tests (mobile's WS usage is already compatible)
- PTY integration tests (would need real `claude` binary)
