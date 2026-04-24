# File Browser & New Session Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let mobile users browse the server's local file system (within a configured root) and start fresh Claude Code sessions in a chosen directory.

**Architecture:** New streamer endpoints (`GET /api/browse`, `POST /api/browse/mkdir`, `POST /api/sessions/start`) secured by realpath-based path validation. New mobile modal screen (`app/browse.tsx`) with flat directory navigation, triggered by a `+` header button on the Sessions tab.

**Tech Stack:** Node.js fs/path (streamer), Expo Router modal + React Query + FlashList (mobile)

**Design doc:** `docs/plans/2026-04-24-file-browser-new-session-design.md`

---

## File Structure

### Streamer — new files
- `src/browse.ts` — path resolution, validation, directory listing, mkdir
- `__tests__/browse.test.ts` — unit tests for browse module

### Streamer — modified files
- `src/types.ts` — add `browseRoot` to `ServerConfig`, add `StartFreshSessionOptions`
- `cli/index.ts` — add `--browse-root` CLI flag
- `src/auth.ts` — add `loadBrowseRoot()` to read from YAML
- `src/server.ts` — add browse routes + start-session route, resolve `browseRoot` at construction
- `src/pty-manager.ts` — add `startFresh()` method

### Mobile — new files
- `app/browse.tsx` — file browser modal screen
- `hooks/useBrowse.ts` — React Query hooks for browse + mkdir + start session

### Mobile — modified files
- `types/api.ts` — add browse response types
- `app/(tabs)/_layout.tsx` — add `+` header button to Sessions tab
- `app/_layout.tsx` — register browse modal route

---

## Task 1: Add browseRoot to streamer types and config loading

**Files:**
- Modify: `streamer/src/types.ts:63-75`
- Modify: `streamer/src/auth.ts:20-33`
- Modify: `streamer/cli/index.ts:12-46`

- [ ] **Step 1: Add browseRoot to ServerConfig and add StartFreshSessionOptions type**

In `streamer/src/types.ts`, add `browseRoot` to `ServerConfig` and add the new options type:

```typescript
// Add to ServerConfig (after line 67):
  browseRoot?: string;

// Add after StartSessionOptions (after line 89):
export interface StartFreshSessionOptions {
  projectPath: string;
  projectName?: string;
  systemPrompt?: string;
}
```

- [ ] **Step 2: Add loadBrowseRoot() to auth.ts**

In `streamer/src/auth.ts`, add a function that reads `browse_root` from the YAML config file. Place it after `loadOrCreateApiKey()`:

```typescript
export function loadBrowseRoot(): string | undefined {
  try {
    const content = readFileSync(CONFIG_FILE, "utf-8");
    const match = content.match(/browse_root:\s*(.+)/);
    if (match?.[1]) return match[1].trim();
  } catch {
    // File doesn't exist or not readable
  }
  return undefined;
}
```

- [ ] **Step 3: Add --browse-root CLI flag**

In `streamer/cli/index.ts`, add the flag after line 18 and pass it to the server config:

```typescript
  .option("--browse-root <path>", "Root directory for file browsing")
```

Update the server construction (lines 23-28) to include browseRoot:

```typescript
    const server = new StreamerServer({
      port,
      apiKey,
      localNoAuth: opts.localNoAuth,
      verbose: opts.verbose,
      browseRoot: opts.browseRoot,
    });
```

- [ ] **Step 4: Commit**

```bash
cd streamer
git add src/types.ts src/auth.ts cli/index.ts
git commit -m "feat: add browseRoot config type, YAML loader, and CLI flag"
```

---

## Task 2: Implement browse path resolver with tests

**Files:**
- Create: `streamer/src/browse.ts`
- Create: `streamer/__tests__/browse.test.ts`

- [ ] **Step 1: Write failing tests for resolveBrowsePath and listDirectories**

Create `streamer/__tests__/browse.test.ts`:

```typescript
import { mkdirSync, rmSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";
import { resolveBrowsePath, listDirectories, createDirectory } from "../src/browse";

const TEST_ROOT = join(tmpdir(), "threadbase-browse-test");

beforeEach(() => {
  rmSync(TEST_ROOT, { recursive: true, force: true });
  mkdirSync(join(TEST_ROOT, "projectA", "src"), { recursive: true });
  mkdirSync(join(TEST_ROOT, "projectA", "tests"), { recursive: true });
  mkdirSync(join(TEST_ROOT, "projectB"), { recursive: true });
});

afterAll(() => {
  rmSync(TEST_ROOT, { recursive: true, force: true });
});

describe("resolveBrowsePath", () => {
  it("resolves empty path to browseRoot", async () => {
    const resolved = await resolveBrowsePath(TEST_ROOT, "");
    expect(resolved).toBe(TEST_ROOT);
  });

  it("resolves a valid relative path", async () => {
    const resolved = await resolveBrowsePath(TEST_ROOT, "projectA");
    expect(resolved).toBe(join(TEST_ROOT, "projectA"));
  });

  it("resolves nested paths", async () => {
    const resolved = await resolveBrowsePath(TEST_ROOT, "projectA/src");
    expect(resolved).toBe(join(TEST_ROOT, "projectA", "src"));
  });

  it("rejects path traversal with ../", async () => {
    await expect(resolveBrowsePath(TEST_ROOT, "../")).rejects.toThrow("outside browse root");
  });

  it("rejects path traversal with nested ../", async () => {
    await expect(resolveBrowsePath(TEST_ROOT, "projectA/../../etc")).rejects.toThrow(
      "outside browse root",
    );
  });

  it("rejects nonexistent path", async () => {
    await expect(resolveBrowsePath(TEST_ROOT, "nonexistent")).rejects.toThrow();
  });
});

describe("listDirectories", () => {
  it("lists immediate subdirectories sorted alphabetically", async () => {
    const dirs = await listDirectories(TEST_ROOT);
    expect(dirs).toEqual([{ name: "projectA" }, { name: "projectB" }]);
  });

  it("lists subdirectories of a nested path", async () => {
    const dirs = await listDirectories(join(TEST_ROOT, "projectA"));
    expect(dirs).toEqual([{ name: "src" }, { name: "tests" }]);
  });

  it("returns empty array for leaf directory", async () => {
    const dirs = await listDirectories(join(TEST_ROOT, "projectB"));
    expect(dirs).toEqual([]);
  });
});

describe("createDirectory", () => {
  it("creates a new directory", async () => {
    await createDirectory(TEST_ROOT, "projectC");
    const dirs = await listDirectories(TEST_ROOT);
    expect(dirs.map((d) => d.name)).toContain("projectC");
  });

  it("rejects names containing /", async () => {
    await expect(createDirectory(TEST_ROOT, "a/b")).rejects.toThrow("Invalid directory name");
  });

  it("rejects names containing ..", async () => {
    await expect(createDirectory(TEST_ROOT, "..")).rejects.toThrow("Invalid directory name");
  });

  it("rejects if directory already exists", async () => {
    await expect(createDirectory(TEST_ROOT, "projectA")).rejects.toThrow("already exists");
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd streamer && npx vitest run __tests__/browse.test.ts
```

Expected: FAIL — `../src/browse` module not found.

- [ ] **Step 3: Implement the browse module**

Create `streamer/src/browse.ts`:

```typescript
import { readdir, mkdir, realpath, stat } from "fs/promises";
import { join, resolve } from "path";

export async function resolveBrowsePath(browseRoot: string, relativePath: string): Promise<string> {
  const target = relativePath ? resolve(browseRoot, relativePath) : browseRoot;
  const resolved = await realpath(target);
  const root = await realpath(browseRoot);
  if (!resolved.startsWith(root + "/") && resolved !== root) {
    throw new Error("Path outside browse root");
  }
  return resolved;
}

export async function listDirectories(
  absolutePath: string,
): Promise<Array<{ name: string }>> {
  const entries = await readdir(absolutePath, { withFileTypes: true });
  return entries
    .filter((e) => e.isDirectory())
    .map((e) => ({ name: e.name }))
    .sort((a, b) => a.name.localeCompare(b.name));
}

export async function createDirectory(
  parentAbsolutePath: string,
  name: string,
): Promise<string> {
  if (name.includes("/") || name.includes("\\") || name === ".." || name === ".") {
    throw new Error("Invalid directory name");
  }
  const target = join(parentAbsolutePath, name);
  try {
    const s = await stat(target);
    if (s.isDirectory()) throw new Error("Directory already exists");
  } catch (err: any) {
    if (err.code !== "ENOENT") throw err;
  }
  await mkdir(target);
  return target;
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd streamer && npx vitest run __tests__/browse.test.ts
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
cd streamer
git add src/browse.ts __tests__/browse.test.ts
git commit -m "feat: add browse path resolver with directory listing and mkdir"
```

---

## Task 3: Add browse and mkdir endpoints to streamer server

**Files:**
- Modify: `streamer/src/server.ts:27-49` (constructor — add browseRoot field)
- Modify: `streamer/src/server.ts:151-211` (handleRequest — add routes)
- Modify: `streamer/src/server.ts` (new handler methods)

- [ ] **Step 1: Add browseRoot resolution to server constructor**

In `streamer/src/server.ts`, add the import at the top:

```typescript
import { resolveBrowsePath, listDirectories, createDirectory } from "./browse";
import { loadBrowseRoot } from "./auth";
import { realpath } from "fs/promises";
```

Add a private field after line 43 (`private dbPool`):

```typescript
  private browseRoot: string | null = null;
```

In the constructor (after `this.scanProfiles = config.scanProfiles;` on line 49), add browseRoot resolution:

```typescript
    // Resolve browseRoot: env var > YAML config > CLI flag
    const rawRoot =
      process.env.THREADBASE_BROWSE_ROOT ?? loadBrowseRoot() ?? config.browseRoot;
    if (rawRoot) {
      realpath(rawRoot)
        .then((resolved) => {
          this.browseRoot = resolved;
          if (this.verbose) console.log(`Browse root: ${resolved}`);
        })
        .catch(() => {
          console.warn(`Warning: browse root does not exist: ${rawRoot}`);
        });
    }
```

- [ ] **Step 2: Add browse routes to handleRequest**

In the `handleRequest` method, add these routes after the `sessions/resume` route (after line 186):

```typescript
      if (method === "GET" && path === "/api/browse") return await this.handleBrowse(url, res);
      if (method === "POST" && path === "/api/browse/mkdir")
        return await this.handleMkdir(req, res);
```

- [ ] **Step 3: Implement handleBrowse handler**

Add after the `handleCancel` method (after line 576):

```typescript
  private async handleBrowse(url: URL, res: ServerResponse): Promise<void> {
    if (!this.browseRoot) {
      json(res, 403, { error: "File browsing not configured. Set browseRoot on the server." });
      return;
    }
    const relativePath = url.searchParams.get("path") ?? "";
    try {
      const resolved = await resolveBrowsePath(this.browseRoot, relativePath);
      const directories = await listDirectories(resolved);
      json(res, 200, { path: relativePath, directories });
    } catch (err) {
      const message = err instanceof Error ? err.message : "Browse failed";
      if (message.includes("outside browse root")) {
        json(res, 400, { error: message });
      } else {
        json(res, 400, { error: message });
      }
    }
  }
```

- [ ] **Step 4: Implement handleMkdir handler**

Add after `handleBrowse`:

```typescript
  private async handleMkdir(req: IncomingMessage, res: ServerResponse): Promise<void> {
    if (!this.browseRoot) {
      json(res, 403, { error: "File browsing not configured. Set browseRoot on the server." });
      return;
    }
    const body = await readBody(req);
    const { path: relativePath, name } = body;
    if (!name || typeof name !== "string") {
      json(res, 400, { error: "Missing name field" });
      return;
    }
    try {
      const parentPath = await resolveBrowsePath(this.browseRoot, relativePath ?? "");
      await createDirectory(parentPath, name);
      const parentRelative = relativePath ?? "";
      const created = parentRelative ? `${parentRelative}/${name}` : name;
      json(res, 201, { created });
    } catch (err) {
      const message = err instanceof Error ? err.message : "Failed to create directory";
      if (message.includes("already exists")) {
        json(res, 409, { error: message });
      } else if (message.includes("Invalid directory name")) {
        json(res, 400, { error: message });
      } else {
        json(res, 400, { error: message });
      }
    }
  }
```

- [ ] **Step 5: Run lint and tests**

```bash
cd streamer && npm run lint && npm test
```

Expected: all pass.

- [ ] **Step 6: Commit**

```bash
cd streamer
git add src/server.ts
git commit -m "feat: add GET /api/browse and POST /api/browse/mkdir endpoints"
```

---

## Task 4: Add POST /api/sessions/start endpoint with system prompt

**Files:**
- Modify: `streamer/src/pty-manager.ts:39-78` (add `startFresh` method)
- Modify: `streamer/src/server.ts` (add route + handler)

- [ ] **Step 1: Add startFresh method to PTYManager**

In `streamer/src/pty-manager.ts`, add a new method after the `start()` method (after line 78):

```typescript
  async startFresh(options: StartFreshSessionOptions): Promise<ManagedSession> {
    const nodePty = await loadPty();
    const sessionId = `ses_${randomBytes(8).toString("hex")}`;
    const projectName = options.projectName ?? basename(options.projectPath);

    const args: string[] = [];
    if (options.systemPrompt) {
      args.push("--system-prompt", options.systemPrompt);
    }

    const proc = nodePty.spawn("claude", args, {
      name: "xterm-256color",
      cols: 120,
      rows: 40,
      cwd: options.projectPath,
      env: process.env as Record<string, string>,
    });

    const session: InternalSession = {
      id: sessionId,
      conversationId: "",
      projectPath: options.projectPath,
      projectName,
      branch: "",
      status: "running",
      startedAt: new Date(),
      completedAt: null,
      promptCount: 0,
      lastOutput: "",
      process: proc,
      outputBuffer: Buffer.alloc(0),
    };

    this.sessions.set(sessionId, session);

    proc.onData((data: string) => {
      this.handleOutput(sessionId, data);
    });

    proc.onExit(({ exitCode }: { exitCode: number }) => {
      this.handleExit(sessionId, exitCode);
    });

    return toPublicSession(session);
  }
```

Update the import at the top of pty-manager.ts (line 3) to include the new type:

```typescript
import type { ManagedSession, PTYManagerOptions, StartFreshSessionOptions, StartSessionOptions } from "./types";
```

- [ ] **Step 2: Add the system prompt constant and route handler to server.ts**

Add a constant near the top of `server.ts` (after the imports):

```typescript
const BROWSE_SYSTEM_PROMPT = (browseRoot: string) =>
  `You are working within the project boundary: ${browseRoot}. ` +
  `Do not read, write, or execute commands that access files or directories outside this boundary.`;
```

Add the route in `handleRequest` after the browse/mkdir routes:

```typescript
      if (method === "POST" && path === "/api/sessions/start")
        return await this.handleStartSession(req, res);
```

Add the handler method:

```typescript
  private async handleStartSession(req: IncomingMessage, res: ServerResponse): Promise<void> {
    if (!this.browseRoot) {
      json(res, 403, { error: "File browsing not configured. Set browseRoot on the server." });
      return;
    }
    const body = await readBody(req);
    const { path: relativePath } = body;

    if (typeof relativePath !== "string") {
      json(res, 400, { error: "Missing path field" });
      return;
    }

    let resolvedPath: string;
    try {
      resolvedPath = await resolveBrowsePath(this.browseRoot, relativePath);
    } catch (err) {
      const message = err instanceof Error ? err.message : "Invalid path";
      json(res, 400, { error: message });
      return;
    }

    try {
      const session = await this.ptyManager.startFresh({
        projectPath: resolvedPath,
        projectName: body.projectName,
        systemPrompt: BROWSE_SYSTEM_PROMPT(this.browseRoot),
      });

      this.sessionStore.addManaged(session);
      this.wsHub.broadcast({ type: "session_list", sessions: this.sessionStore.list() });

      const resp = this.sessionStore.get(session.id);
      json(res, 201, resp ?? session);
    } catch (err) {
      const message = err instanceof Error ? err.message : "Failed to start session";
      json(res, 500, { error: message });
    }
  }
```

- [ ] **Step 3: Run lint and tests**

```bash
cd streamer && npm run lint && npm test
```

Expected: all pass.

- [ ] **Step 4: Commit**

```bash
cd streamer
git add src/pty-manager.ts src/server.ts
git commit -m "feat: add POST /api/sessions/start for fresh Claude sessions with system prompt"
```

---

## Task 5: Add browse types to mobile app

**Files:**
- Modify: `mobile/types/api.ts`

- [ ] **Step 1: Add browse response types**

In `mobile/types/api.ts`, add after the `PushRegisterPayload` interface (after line 128):

```typescript
// ── Browse types ────────────────────────────────────────────────────

export interface BrowseResponse {
  path: string
  directories: Array<{ name: string }>
}

export interface MkdirResponse {
  created: string
}
```

- [ ] **Step 2: Commit**

```bash
cd mobile
git add types/api.ts
git commit -m "feat: add browse API response types"
```

---

## Task 6: Add browse hooks to mobile app

**Files:**
- Create: `mobile/hooks/useBrowse.ts`

- [ ] **Step 1: Create the browse hooks**

Create `mobile/hooks/useBrowse.ts`:

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { createApiForServer } from '@/services/api-client'
import type { BrowseResponse, MkdirResponse, Session } from '@/types/api'

export function useBrowse(serverId: string, path: string) {
  const api = createApiForServer(serverId)

  return useQuery<BrowseResponse>({
    queryKey: ['browse', serverId, path],
    queryFn: () => api.get<BrowseResponse>(`/api/browse?path=${encodeURIComponent(path)}`),
  })
}

export function useCreateDirectory(serverId: string) {
  const qc = useQueryClient()
  const api = createApiForServer(serverId)

  return useMutation<MkdirResponse, Error, { parentPath: string; name: string }>({
    mutationFn: ({ parentPath, name }) =>
      api.post<MkdirResponse>('/api/browse/mkdir', { path: parentPath, name }),
    onSuccess: (_data, { parentPath }) => {
      qc.invalidateQueries({ queryKey: ['browse', serverId, parentPath] })
    },
  })
}

export function useStartSession(serverId: string) {
  const qc = useQueryClient()
  const api = createApiForServer(serverId)

  return useMutation<Session, Error, { path: string; projectName?: string }>({
    mutationFn: (vars) => api.post<Session>('/api/sessions/start', vars),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['sessions'] })
    },
  })
}
```

- [ ] **Step 2: Commit**

```bash
cd mobile
git add hooks/useBrowse.ts
git commit -m "feat: add useBrowse, useCreateDirectory, useStartSession hooks"
```

---

## Task 7: Create the file browser modal screen

**Files:**
- Create: `mobile/app/browse.tsx`

- [ ] **Step 1: Create the browse modal screen**

Create `mobile/app/browse.tsx`:

```tsx
import React, { useState, useCallback } from 'react'
import {
  View,
  Text,
  TouchableOpacity,
  TextInput,
  Alert,
  StyleSheet,
  ActivityIndicator,
} from 'react-native'
import { useRouter, useLocalSearchParams } from 'expo-router'
import { FlashList } from '@shopify/flash-list'
import { SafeAreaView } from 'react-native-safe-area-context'
import { useBrowse, useCreateDirectory, useStartSession } from '@/hooks/useBrowse'
import { SkeletonBox } from '@/components/ui/Skeleton'
import { EmptyState } from '@/components/ui/EmptyState'
import { dark, font, radius, spacing } from '@/constants/theme'

export default function BrowseScreen() {
  const router = useRouter()
  const { server: serverId } = useLocalSearchParams<{ server: string }>()
  const [currentPath, setCurrentPath] = useState('')
  const [newFolderName, setNewFolderName] = useState('')
  const [showNewFolder, setShowNewFolder] = useState(false)

  const { data, isLoading, isError, error } = useBrowse(serverId ?? '', currentPath)
  const createDir = useCreateDirectory(serverId ?? '')
  const startSession = useStartSession(serverId ?? '')

  const breadcrumbs = currentPath ? currentPath.split('/') : []

  const navigateTo = useCallback((path: string) => {
    setCurrentPath(path)
    setShowNewFolder(false)
  }, [])

  const navigateToBreadcrumb = useCallback((index: number) => {
    if (index < 0) {
      setCurrentPath('')
    } else {
      const segments = currentPath.split('/')
      setCurrentPath(segments.slice(0, index + 1).join('/'))
    }
    setShowNewFolder(false)
  }, [currentPath])

  const handleCreateFolder = useCallback(() => {
    const name = newFolderName.trim()
    if (!name) return
    createDir.mutate(
      { parentPath: currentPath, name },
      {
        onSuccess: () => {
          setNewFolderName('')
          setShowNewFolder(false)
        },
        onError: (err) => {
          Alert.alert('Error', err.message)
        },
      },
    )
  }, [currentPath, newFolderName, createDir])

  const handleStartSession = useCallback(() => {
    const displayName = currentPath ? currentPath.split('/').pop() : '~'
    startSession.mutate(
      { path: currentPath, projectName: displayName },
      {
        onSuccess: (session) => {
          router.dismiss()
          router.push(`/session/${session.id}?server=${serverId}`)
        },
        onError: (err) => {
          Alert.alert('Failed to start session', err.message)
        },
      },
    )
  }, [currentPath, serverId, startSession, router])

  const renderItem = useCallback(
    ({ item }: { item: { name: string } }) => {
      const childPath = currentPath ? `${currentPath}/${item.name}` : item.name
      return (
        <TouchableOpacity style={styles.row} onPress={() => navigateTo(childPath)}>
          <Text style={styles.folderIcon}>📁</Text>
          <Text style={styles.dirName} numberOfLines={1}>
            {item.name}
          </Text>
          <Text style={styles.chevron}>›</Text>
        </TouchableOpacity>
      )
    },
    [currentPath, navigateTo],
  )

  const is403 = isError && error?.message?.includes('403')

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      {/* Breadcrumbs */}
      <View style={styles.breadcrumbs}>
        <TouchableOpacity onPress={() => navigateToBreadcrumb(-1)}>
          <Text style={[styles.crumb, currentPath === '' && styles.crumbActive]}>~</Text>
        </TouchableOpacity>
        {breadcrumbs.map((segment, i) => (
          <React.Fragment key={i}>
            <Text style={styles.crumbSeparator}>/</Text>
            <TouchableOpacity onPress={() => navigateToBreadcrumb(i)}>
              <Text style={[styles.crumb, i === breadcrumbs.length - 1 && styles.crumbActive]}>
                {segment}
              </Text>
            </TouchableOpacity>
          </React.Fragment>
        ))}
      </View>

      {/* Directory list */}
      <View style={styles.listContainer}>
        {isLoading ? (
          <View style={styles.skeletons}>
            {Array.from({ length: 6 }).map((_, i) => (
              <SkeletonBox key={i} height={44} style={{ marginBottom: spacing.sm }} />
            ))}
          </View>
        ) : is403 ? (
          <EmptyState
            title="Browsing not configured"
            subtitle="Set browseRoot on your server to enable file browsing."
          />
        ) : isError ? (
          <EmptyState title="Error" subtitle={error?.message ?? 'Failed to load directories'} />
        ) : data?.directories.length === 0 ? (
          <EmptyState title="Empty directory" subtitle="No subdirectories here." />
        ) : (
          <FlashList
            data={data?.directories ?? []}
            renderItem={renderItem}
            estimatedItemSize={52}
            keyExtractor={(item) => item.name}
          />
        )}
      </View>

      {/* New folder inline input */}
      {showNewFolder && (
        <View style={styles.newFolderRow}>
          <TextInput
            style={styles.newFolderInput}
            value={newFolderName}
            onChangeText={setNewFolderName}
            placeholder="Folder name"
            placeholderTextColor={dark.text.secondary}
            autoFocus
            onSubmitEditing={handleCreateFolder}
          />
          <TouchableOpacity style={styles.newFolderBtn} onPress={handleCreateFolder}>
            {createDir.isPending ? (
              <ActivityIndicator size="small" color={dark.text.accent} />
            ) : (
              <Text style={styles.newFolderBtnText}>Create</Text>
            )}
          </TouchableOpacity>
        </View>
      )}

      {/* Footer */}
      <View style={styles.footer}>
        <TouchableOpacity
          style={styles.newFolderToggle}
          onPress={() => setShowNewFolder((v) => !v)}
        >
          <Text style={styles.newFolderToggleText}>
            {showNewFolder ? 'Cancel' : 'New Folder'}
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.startBtn, startSession.isPending && styles.startBtnDisabled]}
          onPress={handleStartSession}
          disabled={startSession.isPending}
        >
          {startSession.isPending ? (
            <ActivityIndicator size="small" color="#fff" />
          ) : (
            <Text style={styles.startBtnText}>
              Start Session Here
            </Text>
          )}
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: dark.bg.primary,
  },
  breadcrumbs: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: dark.border,
    flexWrap: 'wrap',
    gap: spacing.xs,
  },
  crumb: {
    color: dark.text.accent,
    fontSize: font.sm,
  },
  crumbActive: {
    color: dark.text.primary,
    fontWeight: '600',
  },
  crumbSeparator: {
    color: dark.text.secondary,
    fontSize: font.sm,
  },
  listContainer: {
    flex: 1,
  },
  skeletons: {
    padding: spacing.lg,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: dark.border,
  },
  folderIcon: {
    fontSize: 20,
    marginRight: spacing.md,
  },
  dirName: {
    flex: 1,
    color: dark.text.primary,
    fontSize: font.base,
  },
  chevron: {
    color: dark.text.secondary,
    fontSize: font.xl,
    marginLeft: spacing.sm,
  },
  newFolderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.sm,
    borderTopWidth: 1,
    borderTopColor: dark.border,
    gap: spacing.sm,
  },
  newFolderInput: {
    flex: 1,
    height: 40,
    borderRadius: radius.md,
    backgroundColor: dark.bg.card,
    paddingHorizontal: spacing.md,
    color: dark.text.primary,
    fontSize: font.base,
  },
  newFolderBtn: {
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.sm,
    borderRadius: radius.md,
    backgroundColor: dark.bg.card,
    height: 40,
    justifyContent: 'center',
  },
  newFolderBtnText: {
    color: dark.text.accent,
    fontSize: font.sm,
    fontWeight: '600',
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    borderTopWidth: 1,
    borderTopColor: dark.border,
    gap: spacing.md,
  },
  newFolderToggle: {
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.md,
  },
  newFolderToggleText: {
    color: dark.text.accent,
    fontSize: font.sm,
  },
  startBtn: {
    flex: 1,
    backgroundColor: dark.text.accent,
    borderRadius: radius.md,
    paddingVertical: spacing.md,
    alignItems: 'center',
  },
  startBtnDisabled: {
    opacity: 0.6,
  },
  startBtnText: {
    color: '#fff',
    fontSize: font.base,
    fontWeight: '600',
  },
})
```

- [ ] **Step 2: Commit**

```bash
cd mobile
git add app/browse.tsx
git commit -m "feat: add file browser modal screen"
```

---

## Task 8: Register browse modal and add + button to Sessions tab

**Files:**
- Modify: `mobile/app/_layout.tsx:131-142` (add Stack.Screen for browse)
- Modify: `mobile/app/(tabs)/_layout.tsx:22-28` (add headerRight to sessions)

- [ ] **Step 1: Register the browse modal route in root layout**

In `mobile/app/_layout.tsx`, add a new Stack.Screen after the conversation screen (after line 141):

```tsx
              <Stack.Screen
                name="browse"
                options={{
                  presentation: 'modal',
                  title: 'Browse',
                  headerBackTitle: 'Cancel',
                }}
              />
```

- [ ] **Step 2: Add + button to Sessions tab header**

In `mobile/app/(tabs)/_layout.tsx`, add the import at the top:

```tsx
import { TouchableOpacity } from 'react-native'
import { useRouter } from 'expo-router'
import { useServersStore } from '@/stores/servers'
```

Replace the `TabsLayout` function to add the header button:

```tsx
export default function TabsLayout() {
  const router = useRouter()
  const activeServerIds = useServersStore((s) => s.activeServerIds)

  return (
    <Tabs
      screenOptions={{
        tabBarStyle: {
          backgroundColor: dark.bg.secondary,
          borderTopColor: dark.border,
          borderTopWidth: 1,
        },
        tabBarActiveTintColor: dark.text.accent,
        tabBarInactiveTintColor: dark.text.secondary,
        headerStyle: { backgroundColor: dark.bg.secondary },
        headerTintColor: dark.text.primary,
        headerShadowVisible: false,
      }}
    >
      <Tabs.Screen
        name="sessions"
        options={{
          title: 'Sessions',
          tabBarIcon: ({ color }) => <Text style={{ color, fontSize: 20 }}>⚡</Text>,
          headerRight: () => (
            <TouchableOpacity
              onPress={() => {
                const serverId = activeServerIds[0]
                if (serverId) router.push(`/browse?server=${serverId}`)
              }}
              style={{ marginRight: 16 }}
            >
              <Text style={{ color: dark.text.accent, fontSize: 24, fontWeight: '300' }}>+</Text>
            </TouchableOpacity>
          ),
        }}
      />
      <Tabs.Screen
        name="history"
        options={{
          title: 'History',
          tabBarIcon: ({ color }) => <Text style={{ color, fontSize: 20 }}>📚</Text>,
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: 'Settings',
          tabBarIcon: ({ color }) => <Text style={{ color, fontSize: 20 }}>⚙️</Text>,
        }}
      />
    </Tabs>
  )
}
```

- [ ] **Step 3: Run type-check**

```bash
cd mobile && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
cd mobile
git add app/_layout.tsx app/\(tabs\)/_layout.tsx
git commit -m "feat: register browse modal route and add + button to sessions header"
```

---

## Task 9: End-to-end manual verification

- [ ] **Step 1: Start streamer with browseRoot configured**

```bash
cd streamer && THREADBASE_BROWSE_ROOT=~/projects npm run dev -- serve
```

Or add to `~/.threadbase/server.yaml`:

```yaml
browse_root: /Users/ronen/Desktop/dev
```

- [ ] **Step 2: Test browse API with curl**

```bash
# List root
curl -H "Authorization: Bearer <key>" http://localhost:3456/api/browse

# List subdirectory
curl -H "Authorization: Bearer <key>" "http://localhost:3456/api/browse?path=personal"

# Create directory
curl -X POST -H "Authorization: Bearer <key>" -H "Content-Type: application/json" \
  -d '{"path":"","name":"test-folder"}' http://localhost:3456/api/browse/mkdir

# Start session
curl -X POST -H "Authorization: Bearer <key>" -H "Content-Type: application/json" \
  -d '{"path":"personal/threadbase"}' http://localhost:3456/api/sessions/start
```

- [ ] **Step 3: Test mobile app**

```bash
cd mobile && npx expo start
```

1. Open the app on a device/simulator
2. Tap the `+` button in the Sessions tab header
3. Verify the browse modal opens and shows directories
4. Navigate into a directory, verify breadcrumbs update
5. Create a new folder, verify it appears in the list
6. Tap "Start Session Here", verify modal dismisses and session detail opens
7. Verify the session appears in the Kanban board on the Sessions tab

- [ ] **Step 4: Test error cases**

1. Server without browseRoot configured — verify 403 and "not configured" message in modal
2. Empty directory — verify "No subdirectories" empty state
3. Start session in a directory — verify Claude opens with the correct working directory
