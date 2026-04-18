# Shared Packages Design: @threadbase/core + @threadbase/ui

**Status:** Approved
**Date:** 2026-04-18
**Scope:** Extract `@threadbase/core` from VSCode and create `@threadbase/ui` for shared React rendering components

---

## Problem

The Threadbase suite has 3 apps with React webviews (Electron, VSCode, IntelliJ) that duplicate UI code:

- **15 components** are copy-pasted between Electron and VSCode (tool cards, message rendering, utilities)
- **IntelliJ** maintains a simplified 3-component subset that lacks feature parity
- **Type definitions** for tool results exist in 3 separate files (`vscode/packages/threadbase-core/src/session.ts`, `electron/src/shared/types.ts`, `intellij/webview/src/types.ts`)
- `@threadbase/core` (provider abstraction + typed tool results) is trapped inside `vscode/packages/` and unavailable to other apps

A future standalone web app (backed by `@threadbase/streamer`) would copy the same components a fourth time.

---

## Solution

Two new private GitHub repos:

1. **`threadbase-core`** (`@threadbase/core`) — extracted from `vscode/packages/threadbase-core/`. Multi-assistant provider abstraction + strongly-typed tool result types.
2. **`threadbase-ui`** (`@threadbase/ui`) — new package with ~15 shared React rendering components extracted from Electron (the most complete source).

---

## Dependency Chain

```
@threadbase/scanner      <- ConversationMeta, Conversation, ConversationMessage, generic ToolResultBlock
       ^
@threadbase/core         <- ProviderSession, ProviderMessage, typed ToolResults, ProviderRegistry, AssistantProvider
       ^
@threadbase/ui           <- ~15 React rendering components, peer deps on React 18+ and Tailwind v4
       ^
apps (vscode, electron, intellij, web)

@threadbase/streamer     <- depends on scanner only (live PTY, no UI concern)
```

**Rules:**
- `core` has zero React dependency — pure TypeScript types + provider logic
- `ui` depends on `core` for typed tool result props (e.g., `EditDiffCard` takes `EditToolResult`)
- `ui` does NOT depend on `scanner` — apps pass parsed data as props
- Components are props-only — no bridge abstraction, no data fetching, no side effects
- Tailwind v4 classes shipped as-is — consumers must have Tailwind configured

---

## Package 1: @threadbase/core

### Repo Structure

```
threadbase-core/
  src/
    index.ts          <- public API (re-exports)
    provider.ts       <- AssistantProvider interface
    registry.ts       <- ProviderRegistry class
    session.ts        <- ProviderSession, ProviderMessage, all typed ToolResult variants
  package.json        <- @threadbase/core, private
  tsconfig.json
  tsup.config.ts      <- dual ESM/CJS build (same pattern as scanner)
  vitest.config.ts
```

### Exports

Types:
- `ProviderSession`, `ProviderMessage`
- `ToolUseBlock`, `ToolResult` (union type)
- `EditToolResult`, `BashToolResult`, `ReadToolResult`, `WriteToolResult`, `GlobToolResult`, `GrepToolResult`, `TaskAgentToolResult`, `TaskCreateToolResult`, `TaskUpdateToolResult`, `GenericToolResult`
- `StructuredPatchHunk`
- `AssistantProvider`, `SessionFilter`

Classes:
- `ProviderRegistry`

### Build

tsup — dual ESM/CJS output with declaration files. Same setup as `@threadbase/scanner`. No runtime dependencies.

### Consumer Impact

- **VSCode:** `vscode/packages/threadbase-core/` deleted. Adds `"@threadbase/core": "github:RonenMars/threadbase-core"`. Imports unchanged.
- **Electron:** Adds `@threadbase/core`. Replaces local tool result type definitions.
- **IntelliJ:** Adds `@threadbase/core` for webview build. Replaces local tool types.
- Platform-specific provider implementations (e.g., `claude.ts`, `codex.ts`) stay in their respective apps.

---

## Package 2: @threadbase/ui

### Repo Structure

```
threadbase-ui/
  src/
    components/
      tool-cards/
        EditDiffCard.tsx
        BashTerminalCard.tsx
        GrepResultCard.tsx
        WriteFileCard.tsx
        ReadFileCard.tsx
        GlobResultCard.tsx
        GenericToolCard.tsx
        TaskToolCard.tsx
      message/
        MessageContent.tsx
        MessageNavigation.tsx
        ToolResultCard.tsx        <- dispatcher that routes to the correct tool card
        ToolInvocationBadge.tsx
      util/
        ErrorBoundary.tsx
        CollapsibleJson.tsx
    index.ts                      <- public API, named exports for all components
  package.json
  tsconfig.json
  tsup.config.ts
  vitest.config.ts
```

### Package Config

```json
{
  "name": "@threadbase/ui",
  "private": true,
  "peerDependencies": {
    "react": "^18.0.0 || ^19.0.0",
    "react-dom": "^18.0.0 || ^19.0.0"
  },
  "dependencies": {
    "@threadbase/core": "github:RonenMars/threadbase-core"
  }
}
```

### Component Contract

- Every component is a pure rendering component
- Props typed using `@threadbase/core` types (e.g., `EditDiffCard` takes `EditToolResult`)
- No data fetching, no bridge abstraction, no side effects beyond rendering
- Source of truth: Electron's current implementations (most complete)

### Styling

- Tailwind v4 classes shipped as-is
- No bundled CSS — the consuming app's Tailwind build picks up classes from `node_modules/@threadbase/ui`
- Consumers must have Tailwind v4 configured

### Consumer Impact

- **Electron:** Deletes local copies of 15 components, imports from `@threadbase/ui`
- **VSCode:** Deletes webview-ui copies, imports from `@threadbase/ui`
- **IntelliJ:** Replaces 3 simplified components, gains full tool card feature parity
- **Future web app:** Installs `@threadbase/ui`, gets all rendering components immediately

---

## Migration Strategy

### Phase 1 — Extract @threadbase/core

1. Create `threadbase-core` GitHub repo
2. Copy `vscode/packages/threadbase-core/src/` into the new repo
3. Add tsup build, vitest config, package.json (matching scanner's patterns)
4. Verify it builds and existing tests pass
5. Update VSCode to consume from the new repo instead of local `packages/`
6. Delete `vscode/packages/threadbase-core/`

### Phase 2 — Create @threadbase/ui

1. Create `threadbase-ui` GitHub repo
2. Copy 15 components from Electron, organize into `tool-cards/`, `message/`, `util/`
3. Replace local type imports with `@threadbase/core` imports
4. Add package.json with core dependency and React peer deps
5. Verify it builds cleanly

### Phase 3 — Wire up consumers (one at a time)

1. **Electron first** — swap local components for `@threadbase/ui` imports, delete local copies, run tests
2. **VSCode second** — same swap, verify webview renders correctly
3. **IntelliJ last** — replace its 3 components, gains full tool card support

Each phase is independently shippable. No big-bang migration — each app keeps working on current code until it explicitly switches.

---

## Why a Types Package Is Not Needed

At this scale, a separate `@threadbase/types` repo is redundant:

- Each package owns types for its own domain (scanner: ConversationMeta; core: ProviderSession/ToolResults; streamer: ManagedSession/WSMessage)
- The only overlap is `ToolUseBlock` (3 fields, identical in scanner and core)
- The dependency chain itself is the sync mechanism — core imports from scanner, ui imports from core
- If 10+ shared types emerge that don't belong to any domain layer, revisit this decision

---

## Supersedes

This design replaces `vscode/SHARED_UI_PACKAGE_PROPOSAL.md`, which was written under the old `claude-history` name and predates the Electron app, streamer package, and multi-assistant provider work.
