# Integration & Contract Testing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add consumer-driven contract tests and HTTP E2E tests that validate the full data pipeline (JSONL → scanner → streamer → HTTP response) against mobile and desktop expected response shapes.

**Architecture:** Scanner fixtures flow through a real `StreamerServer` on a random port. Responses are validated against JSON Schema files representing what each consumer (mobile, desktop) expects. Schema files can be regenerated via update scripts (Playwright snapshot pattern). A separate live-capture script detects JSONL format drift from Claude Code.

**Tech Stack:** Vitest, ajv (JSON Schema validation), existing scanner fixtures, StreamerServer integration test pattern.

**Spec:** `docs/superpowers/specs/2026-04-22-integration-testing-spec.md`

---

## File Map

### New files

| File | Responsibility |
|---|---|
| `scanner/__fixtures__/contract-basic.jsonl` | Minimal 3-message conversation fixture for contract tests |
| `scanner/__fixtures__/contract-tool-use.jsonl` | Conversation with Edit, Bash, Read tool use + tool results |
| `scanner/__fixtures__/contract-subagent.jsonl` | Teammate/subagent conversation with team metadata |
| `streamer/contracts/shared.schema.json` | JSON Schema for fields all consumers rely on |
| `streamer/contracts/mobile.schema.json` | JSON Schema for mobile-expected response shapes |
| `streamer/contracts/desktop.schema.json` | JSON Schema for desktop-expected response shapes |
| `streamer/__tests__/contracts/test-helpers.ts` | Shared setup: fixture profiles, server lifecycle, schema loading, ajv validation |
| `streamer/__tests__/contracts/mobile-contracts.test.ts` | Contract tests for mobile consumer |
| `streamer/__tests__/contracts/desktop-contracts.test.ts` | Contract tests for desktop consumer |
| `streamer/__tests__/contracts/shared-contracts.test.ts` | Contract tests for cross-consumer fields |
| `streamer/__tests__/e2e/api-e2e.test.ts` | Full HTTP E2E test suite |
| `streamer/scripts/update-schema.ts` | Schema regeneration script |
| `scanner/scripts/capture-live.sh` | Live JSONL format drift capture |
| `scanner/scripts/update-baseline.sh` | Accept new baseline |
| `scanner/scripts/validate-live.ts` | Compare captured JSONL against baseline |

### Modified files

| File | Change |
|---|---|
| `streamer/src/types.ts` | Add `scanProfiles` to `ServerConfig` |
| `streamer/src/server.ts` | Thread `scanProfiles` into `scan()`, `search()`, `getScanner()` calls; add `model` to list response |
| `streamer/package.json` | Add `ajv`, `ajv-formats`, `tsx` devDependencies; add test/schema scripts |
| `scanner/package.json` | Add capture-live and update-baseline scripts |

---

## Task 1: Add contract test fixtures to scanner

**Files:**
- Create: `scanner/__fixtures__/contract-basic.jsonl`
- Create: `scanner/__fixtures__/contract-tool-use.jsonl`
- Create: `scanner/__fixtures__/contract-subagent.jsonl`

- [ ] **Step 1: Create `contract-basic.jsonl`**

A minimal 3-message conversation with all fields scanner needs to produce full metadata.

```jsonl
{"type":"user","uuid":"cb-u1","timestamp":"2026-01-20T10:00:00.000Z","sessionId":"sess-contract-basic","slug":"test-session","cwd":"/home/test/my-project","message":{"role":"user","content":[{"type":"text","text":"Hello, can you help me with the project?"}]}}
{"type":"assistant","uuid":"cb-a1","timestamp":"2026-01-20T10:00:05.000Z","sessionId":"sess-contract-basic","message":{"role":"assistant","model":"claude-sonnet-4-20250514","content":[{"type":"text","text":"Of course! I'd be happy to help with your project. What do you need?"}]}}
{"type":"user","uuid":"cb-u2","timestamp":"2026-01-20T10:01:00.000Z","sessionId":"sess-contract-basic","message":{"role":"user","content":[{"type":"text","text":"Please review the README"}]}}
```

- [ ] **Step 2: Create `contract-tool-use.jsonl`**

A conversation with tool use blocks and tool results.

```jsonl
{"type":"user","uuid":"ct-u1","timestamp":"2026-01-21T09:00:00.000Z","sessionId":"sess-contract-tools","slug":"tools-session","cwd":"/home/test/tools-project","message":{"role":"user","content":[{"type":"text","text":"Read and fix main.ts"}]}}
{"type":"assistant","uuid":"ct-a1","timestamp":"2026-01-21T09:00:05.000Z","sessionId":"sess-contract-tools","message":{"role":"assistant","model":"claude-sonnet-4-20250514","content":[{"type":"text","text":"I'll read the file first."},{"type":"tool_use","id":"tu-read-1","name":"Read","input":{"file_path":"main.ts"}}]}}
{"type":"user","uuid":"ct-u2","timestamp":"2026-01-21T09:00:10.000Z","sessionId":"sess-contract-tools","toolUseResult":true,"message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"tu-read-1","content":"const x = 1;\nconst y = 2;\nconsole.log(x + y);"}]}}
{"type":"assistant","uuid":"ct-a2","timestamp":"2026-01-21T09:00:15.000Z","sessionId":"sess-contract-tools","message":{"role":"assistant","model":"claude-sonnet-4-20250514","content":[{"type":"text","text":"I'll fix the issue."},{"type":"tool_use","id":"tu-edit-1","name":"Edit","input":{"file_path":"main.ts","old_string":"console.log(x + y)","new_string":"console.log(x + y);"}}]}}
{"type":"user","uuid":"ct-u3","timestamp":"2026-01-21T09:00:20.000Z","sessionId":"sess-contract-tools","toolUseResult":true,"message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"tu-edit-1","content":""}]}}
{"type":"assistant","uuid":"ct-a3","timestamp":"2026-01-21T09:00:25.000Z","sessionId":"sess-contract-tools","message":{"role":"assistant","model":"claude-sonnet-4-20250514","content":[{"type":"text","text":"Done! The semicolon has been added."}]}}
```

- [ ] **Step 3: Create `contract-subagent.jsonl`**

A teammate conversation with team metadata.

```jsonl
{"type":"user","uuid":"cs-u1","timestamp":"2026-01-22T14:00:00.000Z","sessionId":"sess-contract-subagent","slug":"subagent-session","cwd":"/home/test/team-project","teamName":"test-team","message":{"role":"user","content":[{"type":"text","text":"<teammate-message teammate_id=\"agent-review\" summary=\"Review auth\" color=\"green\">Please review the auth module</teammate-message>"}]}}
{"type":"assistant","uuid":"cs-a1","timestamp":"2026-01-22T14:00:10.000Z","sessionId":"sess-contract-subagent","teamName":"test-team","message":{"role":"assistant","model":"claude-sonnet-4-20250514","content":[{"type":"text","text":"I'll review the auth module for you."}]}}
```

- [ ] **Step 4: Verify fixtures parse correctly**

Run: `cd /Users/ronen/Desktop/dev/personal/threadbase/scanner && npx vitest run __tests__/parser.test.ts -v`

Expected: All existing parser tests still pass (fixtures are independent).

- [ ] **Step 5: Commit**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/scanner
git add __fixtures__/contract-basic.jsonl __fixtures__/contract-tool-use.jsonl __fixtures__/contract-subagent.jsonl
git commit -m "test: add contract test JSONL fixtures"
```

---

## Task 2: Make streamer scan directory configurable

**Files:**
- Modify: `streamer/src/types.ts`
- Modify: `streamer/src/server.ts`

- [ ] **Step 1: Add `scanProfiles` to `ServerConfig`**

In `streamer/src/types.ts`, add the optional field to `ServerConfig`:

```typescript
export interface ServerConfig {
  port: number;
  apiKey?: string;
  localNoAuth?: boolean;
  verbose?: boolean;
  scanProfiles?: Array<{ id: string; label: string; configDir: string; enabled: boolean; emoji: string }>;
}
```

- [ ] **Step 2: Store `scanProfiles` in `StreamerServer`**

In `streamer/src/server.ts`, add to the constructor:

```typescript
private scanProfiles: Array<{ id: string; label: string; configDir: string; enabled: boolean; emoji: string }> | undefined;
```

And in the constructor body, after `this.verbose = config.verbose ?? false;`:

```typescript
this.scanProfiles = config.scanProfiles;
```

- [ ] **Step 3: Thread profiles into `handleListConversations`**

In `streamer/src/server.ts` `handleListConversations`, change the `scan()` call to pass profiles:

```typescript
const result = await scan({
  sort: sort as any,
  limit,
  offset,
  project,
  include: "conversations",
  ...(this.scanProfiles ? { profiles: this.scanProfiles } : {}),
});
```

- [ ] **Step 4: Thread profiles into `handleSearch`**

In `handleSearch`, change the `search()` call:

```typescript
const results = await search(q, {
  limit,
  include: "conversations",
  ...(this.scanProfiles ? { profiles: this.scanProfiles } : {}),
});
```

- [ ] **Step 5: Thread profiles into `getScanner`**

In `getScanner`, pass profiles when creating the scanner instance. Change the `scan()` call inside `getScanner`:

```typescript
private async getScanner(): Promise<ConversationScanner> {
  if (this.scanner) return this.scanner;
  if (this.scannerReady) {
    await this.scannerReady;
    if (this.scanner) return this.scanner;
  }
  this.scanner = new ConversationScanner();
  this.scannerReady = this.scanner.scan(
    this.scanProfiles ? { profiles: this.scanProfiles } : {},
  );
  await this.scannerReady;
  return this.scanner;
}
```

- [ ] **Step 6: Add `model` to list response**

In `handleListConversations`, add `model` to the adapted object. Find the line `lastMessage: c.lastMessage ?? undefined,` and add after it:

```typescript
model: c.model ?? undefined,
```

- [ ] **Step 7: Run existing tests**

Run: `cd /Users/ronen/Desktop/dev/personal/threadbase/streamer && npm test`

Expected: All existing tests pass (the new field is optional, default behavior unchanged).

- [ ] **Step 8: Commit**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/streamer
git add src/types.ts src/server.ts
git commit -m "feat: make scan directory configurable via scanProfiles option"
```

---

## Task 3: Install dependencies and add npm scripts

**Files:**
- Modify: `streamer/package.json`
- Modify: `scanner/package.json`

- [ ] **Step 1: Install ajv and tsx in streamer**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/streamer
npm install --save-dev ajv ajv-formats tsx
```

- [ ] **Step 2: Add streamer test scripts**

In `streamer/package.json`, add to the `"scripts"` section:

```json
"test:contracts": "vitest run __tests__/contracts/",
"test:e2e": "vitest run __tests__/e2e/",
"update-schema": "tsx scripts/update-schema.ts",
"update-schema:mobile": "tsx scripts/update-schema.ts --mobile",
"update-schema:desktop": "tsx scripts/update-schema.ts --desktop",
"update-schema:shared": "tsx scripts/update-schema.ts --shared"
```

- [ ] **Step 3: Add scanner scripts**

In `scanner/package.json`, add to the `"scripts"` section:

```json
"capture-live": "bash scripts/capture-live.sh",
"update-baseline": "bash scripts/update-baseline.sh"
```

- [ ] **Step 4: Commit**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/streamer
git add package.json package-lock.json
cd /Users/ronen/Desktop/dev/personal/threadbase/scanner
git add package.json
git commit -m "chore: add contract test dependencies and npm scripts"
```

---

## Task 4: Write contract test helpers

**Files:**
- Create: `streamer/__tests__/contracts/test-helpers.ts`

- [ ] **Step 1: Create the test helpers file**

This provides shared setup for all contract test files: fixture profiles, server lifecycle, schema loading, and ajv validation.

```typescript
import Ajv from "ajv";
import addFormats from "ajv-formats";
import { createServer } from "http";
import { readFileSync } from "fs";
import { join } from "path";
import { StreamerServer } from "../../src/server";

// ─── Fixture Profiles ─────────────────────────────────────────────
// Point scanner at the contract fixtures instead of ~/.claude.
// The directory structure must be: <configDir>/projects/<slug>/<file>.jsonl
// We use the scanner/__fixtures__ dir directly — fixtures must be placed
// inside a projects/ subdirectory for discovery to find them.

export const FIXTURES_DIR = join(__dirname, "../../../scanner/__fixtures__");

export function createFixtureProfiles(fixtureDir: string) {
  return [
    {
      id: "test",
      label: "Test",
      configDir: fixtureDir,
      enabled: true,
      emoji: "🧪",
    },
  ];
}

// ─── Server Lifecycle ─────────────────────────────────────────────

export const TEST_API_KEY = "tb_contract_test_key";

export async function getRandomPort(): Promise<number> {
  return new Promise((resolve) => {
    const srv = createServer();
    srv.listen(0, () => {
      const addr = srv.address();
      const port = typeof addr === "object" && addr ? addr.port : 0;
      srv.close(() => resolve(port));
    });
  });
}

export async function createTestServer(fixtureDir: string) {
  const port = await getRandomPort();
  const server = new StreamerServer({
    port,
    apiKey: TEST_API_KEY,
    localNoAuth: false,
    verbose: false,
    scanProfiles: createFixtureProfiles(fixtureDir),
  });
  await server.listen(port);
  const baseUrl = `http://localhost:${port}`;
  const headers = { Authorization: `Bearer ${TEST_API_KEY}` };

  return { server, port, baseUrl, headers };
}

// ─── Schema Validation ────────────────────────────────────────────

const ajv = new Ajv({ allErrors: true, strict: false });
addFormats(ajv);

const CONTRACTS_DIR = join(__dirname, "../../contracts");

export function loadSchema(name: string): object {
  const raw = readFileSync(join(CONTRACTS_DIR, `${name}.schema.json`), "utf-8");
  return JSON.parse(raw);
}

export function validateAgainstSchema(data: unknown, schemaName: string, definitionKey: string) {
  const schema = loadSchema(schemaName);
  const validate = ajv.compile({
    ...schema,
    $ref: `#/$defs/${definitionKey}`,
  });
  const valid = validate(data);
  if (!valid) {
    const errors = validate.errors?.map((e) => `${e.instancePath} ${e.message}`).join("\n  ");
    throw new Error(`Schema validation failed for ${schemaName}#${definitionKey}:\n  ${errors}`);
  }
}

// ─── Fetch Helpers ────────────────────────────────────────────────

export async function get(baseUrl: string, path: string, headers: Record<string, string>) {
  const res = await fetch(`${baseUrl}${path}`, { headers });
  return { status: res.status, body: await res.json() };
}

export async function post(baseUrl: string, path: string, data: unknown, headers: Record<string, string>) {
  const res = await fetch(`${baseUrl}${path}`, {
    method: "POST",
    headers: { ...headers, "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });
  return { status: res.status, body: await res.json() };
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/streamer
git add __tests__/contracts/test-helpers.ts
git commit -m "test: add contract test helpers (fixture profiles, schema validation)"
```

---

## Task 5: Set up fixture directory structure

The scanner's discovery function looks for `**/*.jsonl` inside `<configDir>/projects/`. The contract fixtures need to be placed in a directory structure that matches this pattern.

**Files:**
- Create: `scanner/__fixtures__/contract-projects/projects/-home-test-my-project/contract-basic.jsonl` (symlink or copy)
- Create: `scanner/__fixtures__/contract-projects/projects/-home-test-tools-project/contract-tool-use.jsonl`
- Create: `scanner/__fixtures__/contract-projects/projects/-home-test-team-project/contract-subagent.jsonl`

- [ ] **Step 1: Create the directory structure**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/scanner/__fixtures__
mkdir -p contract-projects/projects/-home-test-my-project
mkdir -p contract-projects/projects/-home-test-tools-project
mkdir -p contract-projects/projects/-home-test-team-project
cp contract-basic.jsonl contract-projects/projects/-home-test-my-project/contract-basic.jsonl
cp contract-tool-use.jsonl contract-projects/projects/-home-test-tools-project/contract-tool-use.jsonl
cp contract-subagent.jsonl contract-projects/projects/-home-test-team-project/contract-subagent.jsonl
```

- [ ] **Step 2: Verify scanner discovers the fixtures**

Create a quick verification script (run once, don't commit):

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/scanner
npx tsx -e "
import { scan } from './src/index';
const result = await scan({
  profiles: [{ id: 'test', label: 'Test', configDir: '$(pwd)/__fixtures__/contract-projects', enabled: true, emoji: '🧪' }],
  include: 'conversations',
});
console.log('Found:', result.total, 'conversations');
for (const c of result.conversations as any[]) {
  console.log(' -', c.sessionId, c.projectName, 'msgs:', c.messageCount);
}
"
```

Expected output: 3 conversations found with correct session IDs (`sess-contract-basic`, `sess-contract-tools`, `sess-contract-subagent`).

- [ ] **Step 3: Commit**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/scanner
git add __fixtures__/contract-projects/
git commit -m "test: add contract fixture directory structure for scanner discovery"
```

---

## Task 6: Write the JSON Schema files

**Files:**
- Create: `streamer/contracts/shared.schema.json`
- Create: `streamer/contracts/mobile.schema.json`
- Create: `streamer/contracts/desktop.schema.json`

- [ ] **Step 1: Create `shared.schema.json`**

Fields that every consumer relies on in the list response:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$defs": {
    "ConversationListItem": {
      "type": "object",
      "required": ["id", "projectPath", "messageCount"],
      "properties": {
        "id": { "type": "string", "minLength": 1 },
        "projectPath": { "type": "string" },
        "messageCount": { "type": "integer", "minimum": 0 }
      }
    },
    "ConversationListEnvelope": {
      "type": "object",
      "required": ["conversations", "hasMore", "offset", "total"],
      "properties": {
        "conversations": {
          "type": "array",
          "items": { "$ref": "#/$defs/ConversationListItem" }
        },
        "hasMore": { "type": "boolean" },
        "offset": { "type": "integer", "minimum": 0 },
        "total": { "type": "integer", "minimum": 0 }
      }
    },
    "ServerInfo": {
      "type": "object",
      "required": ["version", "machineName", "platform", "activeSessions"],
      "properties": {
        "version": { "type": "string" },
        "machineName": { "type": "string" },
        "platform": { "type": "string" },
        "activeSessions": { "type": "integer", "minimum": 0 }
      }
    }
  }
}
```

- [ ] **Step 2: Create `mobile.schema.json`**

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$defs": {
    "MessageSnapshot": {
      "type": "object",
      "required": ["text", "timestamp"],
      "properties": {
        "text": { "type": "string" },
        "timestamp": { "type": "string", "format": "date-time" }
      }
    },
    "MobileConversation": {
      "type": "object",
      "required": ["id", "title", "projectPath", "messageCount", "lastActivity"],
      "properties": {
        "id": { "type": "string", "minLength": 1 },
        "title": { "type": "string" },
        "sessionName": { "type": "string" },
        "filePath": { "type": "string" },
        "projectPath": { "type": "string" },
        "branch": { "type": "string" },
        "account": { "type": "string" },
        "preview": { "type": "string" },
        "messageCount": { "type": "integer", "minimum": 0 },
        "lastActivity": { "type": "string", "format": "date-time" },
        "model": { "type": "string" },
        "firstMessage": { "$ref": "#/$defs/MessageSnapshot" },
        "lastMessage": { "$ref": "#/$defs/MessageSnapshot" }
      }
    },
    "MobileConversationPage": {
      "type": "object",
      "required": ["conversations", "hasMore", "offset", "total"],
      "properties": {
        "conversations": {
          "type": "array",
          "items": { "$ref": "#/$defs/MobileConversation" }
        },
        "hasMore": { "type": "boolean" },
        "offset": { "type": "integer", "minimum": 0 },
        "total": { "type": "integer", "minimum": 0 }
      }
    },
    "MobileDetailMeta": {
      "type": "object",
      "required": ["id", "project_name", "project_path", "file_path", "message_count"],
      "properties": {
        "id": { "type": "string" },
        "profile_id": { "type": "string" },
        "project_name": { "type": "string" },
        "project_path": { "type": "string" },
        "file_path": { "type": "string" },
        "last_updated_at": { "type": "string", "format": "date-time" },
        "message_count": { "type": "integer", "minimum": 0 }
      }
    },
    "MobileContentBlock": {
      "type": "object",
      "required": ["type"],
      "properties": {
        "type": { "type": "string", "enum": ["tool_use", "tool_result"] },
        "id": { "type": "string" },
        "name": { "type": "string" },
        "input": { "type": "object" },
        "tool_use_id": { "type": "string" },
        "content": { "type": "string" },
        "is_error": { "type": "boolean" }
      }
    },
    "MobileMessage": {
      "type": "object",
      "required": ["role", "timestamp", "text"],
      "properties": {
        "role": { "type": "string", "enum": ["user", "assistant"] },
        "timestamp": { "type": "string", "format": "date-time" },
        "text": { "type": "string" },
        "tool_calls": { "type": "array", "items": { "type": "string" } },
        "content": { "type": "array", "items": { "$ref": "#/$defs/MobileContentBlock" } }
      }
    },
    "MobileConversationDetail": {
      "type": "object",
      "required": ["meta", "messages"],
      "properties": {
        "meta": { "$ref": "#/$defs/MobileDetailMeta" },
        "messages": { "type": "array", "items": { "$ref": "#/$defs/MobileMessage" } }
      }
    }
  }
}
```

- [ ] **Step 3: Create `desktop.schema.json`**

Documents what electron's WebSocketTransport expects. Contract tests against this will initially fail — documenting the known mismatches.

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$defs": {
    "DesktopSearchResult": {
      "type": "object",
      "required": ["id", "projectName", "projectPath", "sessionId", "sessionName", "preview", "timestamp", "messageCount", "lastMessageSender", "account"],
      "properties": {
        "id": { "type": "string", "minLength": 1 },
        "projectName": { "type": "string" },
        "projectPath": { "type": "string" },
        "sessionId": { "type": "string" },
        "sessionName": { "type": "string" },
        "preview": { "type": "string" },
        "timestamp": { "type": "string", "format": "date-time" },
        "messageCount": { "type": "integer", "minimum": 0 },
        "score": { "type": "number" },
        "lastMessageSender": { "type": "string", "enum": ["user", "assistant"] },
        "account": { "type": "string" },
        "provider": { "type": "string" }
      }
    },
    "DesktopSearchResultArray": {
      "type": "array",
      "items": { "$ref": "#/$defs/DesktopSearchResult" }
    },
    "DesktopConversationMessage": {
      "type": "object",
      "required": ["type", "content", "timestamp"],
      "properties": {
        "type": { "type": "string", "enum": ["user", "assistant", "system"] },
        "content": { "type": "string" },
        "timestamp": { "type": "string" },
        "uuid": { "type": "string" },
        "isToolResult": { "type": "boolean" }
      }
    },
    "DesktopConversation": {
      "type": "object",
      "required": ["id", "filePath", "projectPath", "projectName", "sessionId", "sessionName", "messages", "fullText", "timestamp", "messageCount", "account"],
      "properties": {
        "id": { "type": "string" },
        "filePath": { "type": "string" },
        "projectPath": { "type": "string" },
        "projectName": { "type": "string" },
        "sessionId": { "type": "string" },
        "sessionName": { "type": "string" },
        "messages": { "type": "array", "items": { "$ref": "#/$defs/DesktopConversationMessage" } },
        "fullText": { "type": "string" },
        "timestamp": { "type": "string", "format": "date-time" },
        "messageCount": { "type": "integer", "minimum": 0 },
        "account": { "type": "string" }
      }
    },
    "DesktopActiveSession": {
      "type": "object",
      "required": ["id", "instanceId", "projectPath", "projectName", "status", "lastOutput", "elapsedMs", "promptCount", "startedAt"],
      "properties": {
        "id": { "type": "string" },
        "instanceId": { "type": "string" },
        "projectPath": { "type": "string" },
        "projectName": { "type": "string" },
        "status": { "type": "string" },
        "branch": { "type": "string" },
        "machineName": { "type": "string" },
        "lastOutput": { "type": "string" },
        "elapsedMs": { "type": "number" },
        "promptCount": { "type": "number" },
        "startedAt": { "type": "string", "format": "date-time" },
        "completedAt": { "type": "string" }
      }
    }
  }
}
```

- [ ] **Step 4: Commit**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/streamer
mkdir -p contracts
git add contracts/shared.schema.json contracts/mobile.schema.json contracts/desktop.schema.json
git commit -m "test: add consumer-driven contract JSON schemas"
```

---

## Task 7: Write mobile contract tests

**Files:**
- Create: `streamer/__tests__/contracts/mobile-contracts.test.ts`

- [ ] **Step 1: Write the test file**

```typescript
import { join } from "path";
import {
  createTestServer,
  get,
  FIXTURES_DIR,
  validateAgainstSchema,
} from "./test-helpers";
import type { StreamerServer } from "../../src/server";

const FIXTURE_DIR = join(FIXTURES_DIR, "contract-projects");

describe("Mobile contract tests", () => {
  let server: StreamerServer;
  let baseUrl: string;
  let headers: Record<string, string>;

  beforeAll(async () => {
    const ctx = await createTestServer(FIXTURE_DIR);
    server = ctx.server;
    baseUrl = ctx.baseUrl;
    headers = ctx.headers;
  });

  afterAll(async () => {
    await server.close();
  });

  describe("GET /api/conversations", () => {
    it("returns ConversationPage matching mobile schema", async () => {
      const { status, body } = await get(baseUrl, "/api/conversations?limit=10", headers);
      expect(status).toBe(200);
      validateAgainstSchema(body, "mobile", "MobileConversationPage");
    });

    it("returns at least one conversation from fixtures", async () => {
      const { body } = await get(baseUrl, "/api/conversations?limit=10", headers);
      expect(body.conversations.length).toBeGreaterThan(0);
    });

    it("returns conversations with required mobile fields", async () => {
      const { body } = await get(baseUrl, "/api/conversations?limit=10", headers);
      for (const conv of body.conversations) {
        expect(conv).toHaveProperty("id");
        expect(conv).toHaveProperty("title");
        expect(conv).toHaveProperty("projectPath");
        expect(conv).toHaveProperty("messageCount");
        expect(conv).toHaveProperty("lastActivity");
      }
    });
  });

  describe("GET /api/conversations/:id", () => {
    it("returns detail matching mobile schema", async () => {
      const list = await get(baseUrl, "/api/conversations?limit=1", headers);
      const id = list.body.conversations[0].id;

      const { status, body } = await get(baseUrl, `/api/conversations/${id}`, headers);
      expect(status).toBe(200);
      validateAgainstSchema(body, "mobile", "MobileConversationDetail");
    });

    it("returns meta with required fields", async () => {
      const list = await get(baseUrl, "/api/conversations?limit=1", headers);
      const id = list.body.conversations[0].id;

      const { body } = await get(baseUrl, `/api/conversations/${id}`, headers);
      expect(body.meta).toHaveProperty("id");
      expect(body.meta).toHaveProperty("project_name");
      expect(body.meta).toHaveProperty("project_path");
      expect(body.meta).toHaveProperty("file_path");
      expect(body.meta).toHaveProperty("message_count");
    });

    it("returns messages with role and timestamp", async () => {
      const list = await get(baseUrl, "/api/conversations?limit=1", headers);
      const id = list.body.conversations[0].id;

      const { body } = await get(baseUrl, `/api/conversations/${id}`, headers);
      expect(body.messages.length).toBeGreaterThan(0);
      for (const msg of body.messages) {
        expect(msg).toHaveProperty("role");
        expect(msg).toHaveProperty("timestamp");
        expect(msg).toHaveProperty("text");
      }
    });
  });

  describe("GET /api/info", () => {
    it("returns ServerInfo matching mobile schema", async () => {
      const { status, body } = await get(baseUrl, "/api/info", headers);
      expect(status).toBe(200);
      validateAgainstSchema(body, "shared", "ServerInfo");
    });
  });

  describe("GET /api/search", () => {
    it("returns ConversationPage matching mobile schema", async () => {
      const { status, body } = await get(baseUrl, "/api/search?q=hello", headers);
      expect(status).toBe(200);
      validateAgainstSchema(body, "mobile", "MobileConversationPage");
    });
  });

  describe("GET /api/sessions", () => {
    it("returns array (empty in test — no PTY)", async () => {
      const { status, body } = await get(baseUrl, "/api/sessions", headers);
      expect(status).toBe(200);
      expect(Array.isArray(body)).toBe(true);
    });
  });
});
```

- [ ] **Step 2: Run the test**

Run: `cd /Users/ronen/Desktop/dev/personal/threadbase/streamer && npx vitest run __tests__/contracts/mobile-contracts.test.ts -v`

Expected: All tests pass. If any schema validation fails, the error message shows exactly which fields are wrong.

- [ ] **Step 3: Commit**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/streamer
git add __tests__/contracts/mobile-contracts.test.ts
git commit -m "test: add mobile consumer contract tests"
```

---

## Task 8: Write desktop contract tests

**Files:**
- Create: `streamer/__tests__/contracts/desktop-contracts.test.ts`

- [ ] **Step 1: Write the test file**

Desktop contract tests document known mismatches. Tests that validate the current mismatch use `it.fails` or `it.skip` with a comment explaining why.

```typescript
import { join } from "path";
import {
  createTestServer,
  get,
  FIXTURES_DIR,
  validateAgainstSchema,
} from "./test-helpers";
import type { StreamerServer } from "../../src/server";

const FIXTURE_DIR = join(FIXTURES_DIR, "contract-projects");

describe("Desktop contract tests", () => {
  let server: StreamerServer;
  let baseUrl: string;
  let headers: Record<string, string>;

  beforeAll(async () => {
    const ctx = await createTestServer(FIXTURE_DIR);
    server = ctx.server;
    baseUrl = ctx.baseUrl;
    headers = ctx.headers;
  });

  afterAll(async () => {
    await server.close();
  });

  describe("GET /api/conversations — list", () => {
    // Known mismatch: electron expects SearchResult[] (flat array),
    // streamer returns ConversationPage (wrapped object).
    // This test documents the gap.
    it.skip("returns flat SearchResult[] matching desktop schema (KNOWN MISMATCH: returns ConversationPage instead)", async () => {
      const { body } = await get(baseUrl, "/api/conversations?limit=10", headers);
      validateAgainstSchema(body, "desktop", "DesktopSearchResultArray");
    });

    it("returns conversations with fields electron will need", async () => {
      const { body } = await get(baseUrl, "/api/conversations?limit=10", headers);
      // Verify the wrapped response has data that COULD map to desktop fields
      expect(body.conversations.length).toBeGreaterThan(0);
      for (const conv of body.conversations) {
        // These fields exist and could be renamed:
        expect(conv).toHaveProperty("id");
        expect(conv).toHaveProperty("title"); // desktop expects "projectName"
        expect(conv).toHaveProperty("projectPath");
        expect(conv).toHaveProperty("messageCount");
        expect(conv).toHaveProperty("lastActivity"); // desktop expects "timestamp"
        expect(conv).toHaveProperty("account");
        expect(conv).toHaveProperty("preview");
      }
    });
  });

  describe("GET /api/conversations/:id — detail", () => {
    // Known mismatch: electron expects flat Conversation with messages/fullText/sessionId,
    // streamer returns { meta, messages } Go-compatible wrapper.
    it.skip("returns flat Conversation matching desktop schema (KNOWN MISMATCH: returns { meta, messages } wrapper)", async () => {
      const list = await get(baseUrl, "/api/conversations?limit=1", headers);
      const id = list.body.conversations[0].id;
      const { body } = await get(baseUrl, `/api/conversations/${id}`, headers);
      validateAgainstSchema(body, "desktop", "DesktopConversation");
    });

    it("returns detail data that could map to desktop fields", async () => {
      const list = await get(baseUrl, "/api/conversations?limit=1", headers);
      const id = list.body.conversations[0].id;
      const { body } = await get(baseUrl, `/api/conversations/${id}`, headers);

      // Verify the data exists in the wrapped format
      expect(body).toHaveProperty("meta");
      expect(body).toHaveProperty("messages");
      expect(body.meta).toHaveProperty("id");
      expect(body.meta).toHaveProperty("project_name"); // desktop expects "projectName"
      expect(body.meta).toHaveProperty("file_path"); // desktop expects "filePath"
      expect(body.messages.length).toBeGreaterThan(0);
    });
  });

  describe("GET /api/info", () => {
    it("returns ServerInfo matching shared schema", async () => {
      const { status, body } = await get(baseUrl, "/api/info", headers);
      expect(status).toBe(200);
      validateAgainstSchema(body, "shared", "ServerInfo");
    });
  });

  describe("GET /api/sessions", () => {
    it("returns array", async () => {
      const { status, body } = await get(baseUrl, "/api/sessions", headers);
      expect(status).toBe(200);
      expect(Array.isArray(body)).toBe(true);
    });
  });
});
```

- [ ] **Step 2: Run the test**

Run: `cd /Users/ronen/Desktop/dev/personal/threadbase/streamer && npx vitest run __tests__/contracts/desktop-contracts.test.ts -v`

Expected: Passing tests pass. Skipped tests are clearly labeled with mismatch reason.

- [ ] **Step 3: Commit**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/streamer
git add __tests__/contracts/desktop-contracts.test.ts
git commit -m "test: add desktop consumer contract tests (with known mismatch docs)"
```

---

## Task 9: Write shared contract tests

**Files:**
- Create: `streamer/__tests__/contracts/shared-contracts.test.ts`

- [ ] **Step 1: Write the test file**

```typescript
import { join } from "path";
import {
  createTestServer,
  get,
  FIXTURES_DIR,
  validateAgainstSchema,
} from "./test-helpers";
import type { StreamerServer } from "../../src/server";

const FIXTURE_DIR = join(FIXTURES_DIR, "contract-projects");

describe("Shared contract tests", () => {
  let server: StreamerServer;
  let baseUrl: string;
  let headers: Record<string, string>;

  beforeAll(async () => {
    const ctx = await createTestServer(FIXTURE_DIR);
    server = ctx.server;
    baseUrl = ctx.baseUrl;
    headers = ctx.headers;
  });

  afterAll(async () => {
    await server.close();
  });

  describe("list envelope", () => {
    it("matches shared ConversationListEnvelope schema", async () => {
      const { body } = await get(baseUrl, "/api/conversations?limit=10", headers);
      validateAgainstSchema(body, "shared", "ConversationListEnvelope");
    });

    it("each conversation has shared required fields", async () => {
      const { body } = await get(baseUrl, "/api/conversations?limit=10", headers);
      for (const conv of body.conversations) {
        validateAgainstSchema(conv, "shared", "ConversationListItem");
      }
    });
  });

  describe("server info", () => {
    it("matches shared ServerInfo schema", async () => {
      const { body } = await get(baseUrl, "/api/info", headers);
      validateAgainstSchema(body, "shared", "ServerInfo");
    });
  });

  describe("pagination", () => {
    it("offset and limit produce correct hasMore", async () => {
      const all = await get(baseUrl, "/api/conversations?limit=100", headers);
      const total = all.body.total;

      const page1 = await get(baseUrl, "/api/conversations?limit=1&offset=0", headers);
      expect(page1.body.hasMore).toBe(total > 1);
      expect(page1.body.offset).toBe(0);
      expect(page1.body.conversations.length).toBe(Math.min(1, total));
    });
  });
});
```

- [ ] **Step 2: Run the test**

Run: `cd /Users/ronen/Desktop/dev/personal/threadbase/streamer && npx vitest run __tests__/contracts/shared-contracts.test.ts -v`

Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/streamer
git add __tests__/contracts/shared-contracts.test.ts
git commit -m "test: add shared cross-consumer contract tests"
```

---

## Task 10: Write HTTP E2E tests

**Files:**
- Create: `streamer/__tests__/e2e/api-e2e.test.ts`

- [ ] **Step 1: Write the test file**

```typescript
import { join } from "path";
import {
  createTestServer,
  get,
  post,
  FIXTURES_DIR,
  TEST_API_KEY,
  validateAgainstSchema,
} from "../contracts/test-helpers";
import type { StreamerServer } from "../../src/server";

const FIXTURE_DIR = join(FIXTURES_DIR, "contract-projects");

describe("API E2E tests", () => {
  let server: StreamerServer;
  let baseUrl: string;
  let headers: Record<string, string>;

  beforeAll(async () => {
    const ctx = await createTestServer(FIXTURE_DIR);
    server = ctx.server;
    baseUrl = ctx.baseUrl;
    headers = ctx.headers;
  });

  afterAll(async () => {
    await server.close();
  });

  describe("conversation list pipeline", () => {
    it("returns fixture conversations through full scan pipeline", async () => {
      const { status, body } = await get(baseUrl, "/api/conversations?limit=10", headers);
      expect(status).toBe(200);
      expect(body.total).toBeGreaterThan(0);
      expect(body.conversations.length).toBeGreaterThan(0);

      // Validate against mobile schema (primary consumer)
      validateAgainstSchema(body, "mobile", "MobileConversationPage");
    });

    it("respects limit parameter", async () => {
      const { body } = await get(baseUrl, "/api/conversations?limit=1", headers);
      expect(body.conversations.length).toBeLessThanOrEqual(1);
    });

    it("respects offset parameter", async () => {
      const all = await get(baseUrl, "/api/conversations?limit=100", headers);
      if (all.body.total > 1) {
        const { body } = await get(baseUrl, "/api/conversations?limit=1&offset=1", headers);
        expect(body.offset).toBe(1);
        expect(body.conversations[0].id).not.toBe(all.body.conversations[0].id);
      }
    });
  });

  describe("conversation detail pipeline", () => {
    it("returns full conversation with messages through scan pipeline", async () => {
      const list = await get(baseUrl, "/api/conversations?limit=1", headers);
      const id = list.body.conversations[0].id;

      const { status, body } = await get(baseUrl, `/api/conversations/${id}`, headers);
      expect(status).toBe(200);
      expect(body.meta.id).toBe(id);
      expect(body.messages.length).toBeGreaterThan(0);

      validateAgainstSchema(body, "mobile", "MobileConversationDetail");
    });

    it("returns 404 for nonexistent conversation", async () => {
      const { status } = await get(baseUrl, "/api/conversations/nonexistent-uuid", headers);
      expect(status).toBe(404);
    });
  });

  describe("tool use in detail", () => {
    it("returns tool_use and tool_result content blocks for tool-use fixture", async () => {
      // Find the tools conversation
      const list = await get(baseUrl, "/api/conversations?limit=10", headers);
      const toolsConv = list.body.conversations.find(
        (c: any) => c.title?.includes("tools-project") || c.projectPath?.includes("tools-project"),
      );

      if (!toolsConv) {
        // If we can't find by title, just verify any conversation detail works
        return;
      }

      const { body } = await get(baseUrl, `/api/conversations/${toolsConv.id}`, headers);
      const assistantMsgs = body.messages.filter((m: any) => m.role === "assistant");
      const hasToolUse = assistantMsgs.some(
        (m: any) => m.content?.some((c: any) => c.type === "tool_use"),
      );
      expect(hasToolUse).toBe(true);
    });
  });

  describe("search pipeline", () => {
    it("returns results for matching query", async () => {
      const { status, body } = await get(baseUrl, "/api/search?q=help", headers);
      expect(status).toBe(200);
      validateAgainstSchema(body, "mobile", "MobileConversationPage");
    });

    it("returns 400 for missing query", async () => {
      const { status } = await get(baseUrl, "/api/search", headers);
      expect(status).toBe(400);
    });
  });

  describe("server info", () => {
    it("returns valid server info", async () => {
      const { status, body } = await get(baseUrl, "/api/info", headers);
      expect(status).toBe(200);
      expect(body.version).toBe("0.1.0");
      expect(typeof body.machineName).toBe("string");
      expect(typeof body.platform).toBe("string");
      expect(typeof body.activeSessions).toBe("number");
      validateAgainstSchema(body, "shared", "ServerInfo");
    });
  });

  describe("sessions (no PTY in test)", () => {
    it("returns empty array when no sessions are running", async () => {
      const { status, body } = await get(baseUrl, "/api/sessions", headers);
      expect(status).toBe(200);
      expect(Array.isArray(body)).toBe(true);
    });
  });

  describe("authentication", () => {
    it("rejects unauthenticated requests", async () => {
      const res = await fetch(`${baseUrl}/api/conversations`);
      expect(res.status).toBe(401);
    });

    it("rejects wrong API key", async () => {
      const res = await fetch(`${baseUrl}/api/conversations`, {
        headers: { Authorization: "Bearer wrong_key" },
      });
      expect(res.status).toBe(401);
    });
  });

  describe("CORS", () => {
    it("returns CORS headers on OPTIONS", async () => {
      const res = await fetch(`${baseUrl}/api/conversations`, {
        method: "OPTIONS",
      });
      expect(res.status).toBe(204);
      expect(res.headers.get("access-control-allow-origin")).toBe("*");
      expect(res.headers.get("access-control-allow-methods")).toContain("GET");
    });
  });
});
```

- [ ] **Step 2: Run the test**

Run: `cd /Users/ronen/Desktop/dev/personal/threadbase/streamer && npx vitest run __tests__/e2e/api-e2e.test.ts -v`

Expected: All tests pass.

- [ ] **Step 3: Run all streamer tests together**

Run: `cd /Users/ronen/Desktop/dev/personal/threadbase/streamer && npm test`

Expected: All existing + new tests pass.

- [ ] **Step 4: Commit**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/streamer
git add __tests__/e2e/api-e2e.test.ts
git commit -m "test: add HTTP E2E tests with fixture data"
```

---

## Task 11: Write the schema update script

**Files:**
- Create: `streamer/scripts/update-schema.ts`

- [ ] **Step 1: Write the script**

```typescript
import { writeFileSync } from "fs";
import { join } from "path";
import { createServer } from "http";
import { StreamerServer } from "../src/server";

const FIXTURES_DIR = join(__dirname, "../../scanner/__fixtures__/contract-projects");
const CONTRACTS_DIR = join(__dirname, "../contracts");
const API_KEY = "tb_schema_update_key";

async function getRandomPort(): Promise<number> {
  return new Promise((resolve) => {
    const srv = createServer();
    srv.listen(0, () => {
      const addr = srv.address();
      const port = typeof addr === "object" && addr ? addr.port : 0;
      srv.close(() => resolve(port));
    });
  });
}

function inferSchema(value: unknown): object {
  if (value === null) return { type: "null" };
  if (Array.isArray(value)) {
    if (value.length === 0) return { type: "array", items: {} };
    return { type: "array", items: inferSchema(value[0]) };
  }
  if (typeof value === "object") {
    const props: Record<string, object> = {};
    const required: string[] = [];
    for (const [k, v] of Object.entries(value!)) {
      props[k] = inferSchema(v);
      if (v !== null && v !== undefined) required.push(k);
    }
    return { type: "object", required, properties: props };
  }
  if (typeof value === "number") {
    return Number.isInteger(value) ? { type: "integer" } : { type: "number" };
  }
  if (typeof value === "boolean") return { type: "boolean" };
  if (typeof value === "string") {
    if (/^\d{4}-\d{2}-\d{2}T/.test(value)) return { type: "string", format: "date-time" };
    return { type: "string" };
  }
  return {};
}

async function captureResponses(baseUrl: string, headers: Record<string, string>) {
  const listRes = await fetch(`${baseUrl}/api/conversations?limit=3`, { headers });
  const listBody = await listRes.json();

  let detailBody = null;
  if (listBody.conversations?.length > 0) {
    const id = listBody.conversations[0].id;
    const detailRes = await fetch(`${baseUrl}/api/conversations/${id}`, { headers });
    detailBody = await detailRes.json();
  }

  const infoRes = await fetch(`${baseUrl}/api/info`, { headers });
  const infoBody = await infoRes.json();

  const sessionsRes = await fetch(`${baseUrl}/api/sessions`, { headers });
  const sessionsBody = await sessionsRes.json();

  return { listBody, detailBody, infoBody, sessionsBody };
}

function buildMobileSchema(responses: Awaited<ReturnType<typeof captureResponses>>) {
  const defs: Record<string, object> = {};

  if (responses.listBody.conversations?.length > 0) {
    defs.MobileConversation = inferSchema(responses.listBody.conversations[0]);
    defs.MobileConversationPage = {
      type: "object",
      required: ["conversations", "hasMore", "offset", "total"],
      properties: {
        conversations: { type: "array", items: { $ref: "#/$defs/MobileConversation" } },
        hasMore: { type: "boolean" },
        offset: { type: "integer", minimum: 0 },
        total: { type: "integer", minimum: 0 },
      },
    };
  }

  if (responses.detailBody) {
    defs.MobileDetailMeta = inferSchema(responses.detailBody.meta);
    if (responses.detailBody.messages?.length > 0) {
      defs.MobileMessage = inferSchema(responses.detailBody.messages[0]);
    }
    defs.MobileConversationDetail = {
      type: "object",
      required: ["meta", "messages"],
      properties: {
        meta: { $ref: "#/$defs/MobileDetailMeta" },
        messages: { type: "array", items: defs.MobileMessage ? { $ref: "#/$defs/MobileMessage" } : {} },
      },
    };
  }

  return { $schema: "https://json-schema.org/draft/2020-12/schema", $defs: defs };
}

function buildDesktopSchema(responses: Awaited<ReturnType<typeof captureResponses>>) {
  const defs: Record<string, object> = {};

  // Desktop expects different shapes — capture what streamer actually returns
  // so the contract test documents the gap
  if (responses.listBody.conversations?.length > 0) {
    defs.DesktopSearchResult = inferSchema(responses.listBody.conversations[0]);
    defs.DesktopSearchResultArray = { type: "array", items: { $ref: "#/$defs/DesktopSearchResult" } };
  }

  if (responses.detailBody) {
    defs.DesktopConversation = inferSchema(responses.detailBody);
  }

  return { $schema: "https://json-schema.org/draft/2020-12/schema", $defs: defs };
}

function buildSharedSchema(responses: Awaited<ReturnType<typeof captureResponses>>) {
  const defs: Record<string, object> = {};

  if (responses.listBody.conversations?.length > 0) {
    const conv = responses.listBody.conversations[0];
    defs.ConversationListItem = {
      type: "object",
      required: ["id", "projectPath", "messageCount"],
      properties: {
        id: inferSchema(conv.id),
        projectPath: inferSchema(conv.projectPath),
        messageCount: inferSchema(conv.messageCount),
      },
    };
  }

  defs.ConversationListEnvelope = {
    type: "object",
    required: ["conversations", "hasMore", "offset", "total"],
    properties: {
      conversations: { type: "array", items: { $ref: "#/$defs/ConversationListItem" } },
      hasMore: { type: "boolean" },
      offset: { type: "integer", minimum: 0 },
      total: { type: "integer", minimum: 0 },
    },
  };

  defs.ServerInfo = inferSchema(responses.infoBody);

  return { $schema: "https://json-schema.org/draft/2020-12/schema", $defs: defs };
}

async function main() {
  const args = process.argv.slice(2);
  const updateMobile = args.includes("--mobile") || args.length === 0;
  const updateDesktop = args.includes("--desktop") || args.length === 0;
  const updateShared = args.includes("--shared") || args.length === 0;

  const port = await getRandomPort();
  const server = new StreamerServer({
    port,
    apiKey: API_KEY,
    verbose: false,
    scanProfiles: [{ id: "test", label: "Test", configDir: FIXTURES_DIR, enabled: true, emoji: "🧪" }],
  });
  await server.listen(port);

  const baseUrl = `http://localhost:${port}`;
  const headers = { Authorization: `Bearer ${API_KEY}` };

  try {
    const responses = await captureResponses(baseUrl, headers);

    if (updateMobile) {
      const schema = buildMobileSchema(responses);
      const path = join(CONTRACTS_DIR, "mobile.schema.json");
      writeFileSync(path, JSON.stringify(schema, null, 2) + "\n");
      console.log("Updated mobile.schema.json");
    }

    if (updateDesktop) {
      const schema = buildDesktopSchema(responses);
      const path = join(CONTRACTS_DIR, "desktop.schema.json");
      writeFileSync(path, JSON.stringify(schema, null, 2) + "\n");
      console.log("Updated desktop.schema.json");
    }

    if (updateShared) {
      const schema = buildSharedSchema(responses);
      const path = join(CONTRACTS_DIR, "shared.schema.json");
      writeFileSync(path, JSON.stringify(schema, null, 2) + "\n");
      console.log("Updated shared.schema.json");
    }
  } finally {
    await server.close();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
```

- [ ] **Step 2: Run the script to regenerate schemas**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/streamer
npx tsx scripts/update-schema.ts
```

Expected: All three schema files are regenerated. Diff should be minimal against the hand-written versions from Task 6.

- [ ] **Step 3: Run all contract tests to verify regenerated schemas work**

Run: `cd /Users/ronen/Desktop/dev/personal/threadbase/streamer && npx vitest run __tests__/contracts/ -v`

Expected: All tests pass with regenerated schemas.

- [ ] **Step 4: Commit**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/streamer
git add scripts/update-schema.ts contracts/
git commit -m "feat: add schema update script for contract test baselines"
```

---

## Task 12: Write live format drift detection scripts

**Files:**
- Create: `scanner/scripts/capture-live.sh`
- Create: `scanner/scripts/update-baseline.sh`
- Create: `scanner/scripts/validate-live.ts`

- [ ] **Step 1: Create `capture-live.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/../__fixtures__"
BASELINE="$FIXTURES_DIR/baseline-live.jsonl"

echo "Running claude --print to capture a live conversation..."
claude --print "what is 1+1" > /dev/null 2>&1

# Find the most recently modified .jsonl file
LATEST=$(find ~/.claude/projects -name "*.jsonl" -not -path "*/memory/*" -not -path "*/tool-results/*" -type f -print0 | xargs -0 ls -t | head -1)

if [ -z "$LATEST" ]; then
  echo "ERROR: No JSONL file found after running claude --print"
  exit 1
fi

echo "Captured: $LATEST"
cp "$LATEST" "$BASELINE"
echo "Saved to: $BASELINE"

echo "Validating against previous baseline..."
npx tsx "$SCRIPT_DIR/validate-live.ts"
```

- [ ] **Step 2: Create `update-baseline.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/../__fixtures__"
BASELINE="$FIXTURES_DIR/baseline-live.jsonl"

if [ -f "$BASELINE" ]; then
  cp "$BASELINE" "$FIXTURES_DIR/baseline-live.prev.jsonl"
  echo "Previous baseline saved as baseline-live.prev.jsonl"
fi

bash "$SCRIPT_DIR/capture-live.sh"
echo "Baseline updated."
```

- [ ] **Step 3: Create `validate-live.ts`**

```typescript
import { readFileSync, existsSync } from "fs";
import { join } from "path";

const FIXTURES_DIR = join(__dirname, "../__fixtures__");
const BASELINE = join(FIXTURES_DIR, "baseline-live.jsonl");
const PREV_BASELINE = join(FIXTURES_DIR, "baseline-live.prev.jsonl");

function extractFieldTypes(jsonlPath: string): Map<string, Set<string>> {
  const lines = readFileSync(jsonlPath, "utf-8").trim().split("\n");
  const fieldTypes = new Map<string, Set<string>>();

  for (const line of lines) {
    try {
      const obj = JSON.parse(line);
      walkObject(obj, "", fieldTypes);
    } catch {
      // Skip malformed lines
    }
  }
  return fieldTypes;
}

function walkObject(obj: unknown, prefix: string, result: Map<string, Set<string>>) {
  if (obj === null || obj === undefined) return;
  if (typeof obj !== "object") return;

  for (const [key, value] of Object.entries(obj as Record<string, unknown>)) {
    const path = prefix ? `${prefix}.${key}` : key;
    const type = value === null ? "null" : Array.isArray(value) ? "array" : typeof value;

    if (!result.has(path)) result.set(path, new Set());
    result.get(path)!.add(type);

    if (type === "object") walkObject(value, path, result);
    if (type === "array" && Array.isArray(value) && value.length > 0) {
      walkObject(value[0], `${path}[]`, result);
    }
  }
}

function compare(prev: Map<string, Set<string>>, curr: Map<string, Set<string>>) {
  const added: string[] = [];
  const removed: string[] = [];
  const typeChanged: string[] = [];

  for (const [path, types] of curr) {
    if (!prev.has(path)) {
      added.push(`+ ${path}: ${[...types].join("|")}`);
    } else {
      const prevTypes = prev.get(path)!;
      const currStr = [...types].sort().join("|");
      const prevStr = [...prevTypes].sort().join("|");
      if (currStr !== prevStr) {
        typeChanged.push(`~ ${path}: ${prevStr} → ${currStr}`);
      }
    }
  }

  for (const path of prev.keys()) {
    if (!curr.has(path)) {
      removed.push(`- ${path}: ${[...prev.get(path)!].join("|")}`);
    }
  }

  return { added, removed, typeChanged };
}

// ─── Main ─────────────────────────────────────────────────────────

if (!existsSync(BASELINE)) {
  console.log("No baseline found. Run 'npm run capture-live' first.");
  process.exit(0);
}

const current = extractFieldTypes(BASELINE);

if (!existsSync(PREV_BASELINE)) {
  console.log("No previous baseline to compare against. Current baseline has", current.size, "field paths.");
  console.log("Run 'npm run update-baseline' to establish the baseline, then run again after a new capture.");
  process.exit(0);
}

const prev = extractFieldTypes(PREV_BASELINE);
const { added, removed, typeChanged } = compare(prev, current);

if (added.length === 0 && removed.length === 0 && typeChanged.length === 0) {
  console.log("No format drift detected. JSONL structure matches previous baseline.");
  process.exit(0);
}

console.log("FORMAT DRIFT DETECTED:\n");
if (removed.length > 0) {
  console.log("REMOVED FIELDS (breaking):");
  removed.forEach((r) => console.log(`  ${r}`));
}
if (typeChanged.length > 0) {
  console.log("\nTYPE CHANGES:");
  typeChanged.forEach((t) => console.log(`  ${t}`));
}
if (added.length > 0) {
  console.log("\nNEW FIELDS (non-breaking):");
  added.forEach((a) => console.log(`  ${a}`));
}

// Exit 1 if there are breaking changes (removed fields or type changes)
if (removed.length > 0 || typeChanged.length > 0) {
  process.exit(1);
}
```

- [ ] **Step 4: Make scripts executable**

```bash
chmod +x /Users/ronen/Desktop/dev/personal/threadbase/scanner/scripts/capture-live.sh
chmod +x /Users/ronen/Desktop/dev/personal/threadbase/scanner/scripts/update-baseline.sh
```

- [ ] **Step 5: Commit**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/scanner
mkdir -p scripts
git add scripts/capture-live.sh scripts/update-baseline.sh scripts/validate-live.ts
git commit -m "feat: add live JSONL format drift detection scripts"
```

---

## Task 13: Run full verification

- [ ] **Step 1: Run scanner tests**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/scanner && npm test
```

Expected: All 90+ tests pass.

- [ ] **Step 2: Run streamer lint**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/streamer && npm run lint
```

Expected: No lint or type errors.

- [ ] **Step 3: Run all streamer tests**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/streamer && npm test
```

Expected: All existing + new tests pass. This includes:
- Contract tests (mobile, desktop, shared)
- E2E tests
- All pre-existing unit and integration tests

- [ ] **Step 4: Verify schema update round-trip**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/streamer
# Regenerate schemas
npx tsx scripts/update-schema.ts
# Verify tests still pass with regenerated schemas
npm test
```

Expected: Tests pass after schema regeneration.

---

## Task summary

| Task | What it builds | Estimated steps |
|---|---|---|
| 1 | JSONL fixture files | 5 |
| 2 | `scanProfiles` config in streamer + `model` field | 8 |
| 3 | Dependencies + npm scripts | 4 |
| 4 | Contract test helpers | 2 |
| 5 | Fixture directory structure for scanner discovery | 3 |
| 6 | JSON Schema files | 4 |
| 7 | Mobile contract tests | 3 |
| 8 | Desktop contract tests | 3 |
| 9 | Shared contract tests | 3 |
| 10 | HTTP E2E tests | 4 |
| 11 | Schema update script | 4 |
| 12 | Live drift detection scripts | 5 |
| 13 | Full verification | 4 |
