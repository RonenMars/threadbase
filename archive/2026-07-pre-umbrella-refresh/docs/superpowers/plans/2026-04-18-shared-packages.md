# Shared Packages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract `@threadbase/core` from the VSCode extension and create `@threadbase/ui` with shared React rendering components, then wire all three apps to consume them.

**Architecture:** Two new private GitHub repos (`threadbase-core`, `threadbase-ui`) consumed by Electron, VSCode, and IntelliJ. Core owns the provider abstraction and typed tool results. UI owns ~16 props-only React rendering components extracted from Electron. Dependency chain: scanner → core → ui → apps.

**Tech Stack:** TypeScript, tsup (dual ESM/CJS), React 18+, Tailwind v4, Vitest

**Spec:** `docs/superpowers/specs/2026-04-18-shared-packages-design.md`

---

## Phase 1: Extract @threadbase/core

### Task 1: Create threadbase-core repo and scaffold

**Files:**
- Create: `package.json`
- Create: `tsconfig.json`
- Create: `tsup.config.ts`
- Create: `vitest.config.ts`
- Create: `.gitignore`

- [ ] **Step 1: Create GitHub repo**

```bash
gh repo create RonenMars/threadbase-core --private --clone
cd threadbase-core
```

- [ ] **Step 2: Create package.json**

```json
{
  "name": "@threadbase/core",
  "version": "0.1.0",
  "description": "Multi-assistant provider abstraction and typed tool results for Threadbase",
  "type": "module",
  "main": "dist/index.cjs",
  "module": "dist/index.js",
  "types": "dist/index.d.ts",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js",
      "require": "./dist/index.cjs"
    }
  },
  "files": ["dist"],
  "scripts": {
    "build": "tsup",
    "lint": "tsc --noEmit && npx biome check .",
    "format": "npx biome format --write .",
    "test": "vitest run"
  },
  "devDependencies": {
    "@biomejs/biome": "^1.9.4",
    "tsup": "^8.4.0",
    "typescript": "^5.7.0",
    "vitest": "^3.1.0"
  }
}
```

- [ ] **Step 3: Create tsup.config.ts**

```typescript
import { defineConfig } from "tsup";

export default defineConfig({
  entry: ["src/index.ts"],
  format: ["esm", "cjs"],
  dts: true,
  splitting: false,
  clean: true,
  outDir: "dist",
});
```

- [ ] **Step 4: Create tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "declaration": true,
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
```

- [ ] **Step 5: Create vitest.config.ts**

```typescript
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
  },
});
```

- [ ] **Step 6: Create .gitignore**

```
node_modules/
dist/
*.tsbuildinfo
```

- [ ] **Step 7: Install dependencies**

```bash
npm install
```

- [ ] **Step 8: Commit scaffold**

```bash
git add -A
git commit -m "chore: scaffold @threadbase/core package"
```

---

### Task 2: Copy source files from VSCode

**Files:**
- Create: `src/index.ts`
- Create: `src/provider.ts`
- Create: `src/registry.ts`
- Create: `src/session.ts`

- [ ] **Step 1: Copy source files**

```bash
cp /path/to/threadbase/vscode/packages/threadbase-core/src/provider.ts src/provider.ts
cp /path/to/threadbase/vscode/packages/threadbase-core/src/registry.ts src/registry.ts
cp /path/to/threadbase/vscode/packages/threadbase-core/src/session.ts src/session.ts
cp /path/to/threadbase/vscode/packages/threadbase-core/src/index.ts src/index.ts
```

- [ ] **Step 2: Verify build**

```bash
npm run build
```

Expected: `dist/index.js`, `dist/index.cjs`, `dist/index.d.ts` created without errors.

- [ ] **Step 3: Verify type-check**

```bash
npx tsc --noEmit
```

Expected: No errors.

- [ ] **Step 4: Commit source files**

```bash
git add src/
git commit -m "feat: add provider abstraction and typed tool results from vscode"
```

---

### Task 3: Copy and adapt tests

**Files:**
- Create: `__tests__/registry.test.ts`

- [ ] **Step 1: Copy existing test**

```bash
mkdir __tests__
cp /path/to/threadbase/vscode/packages/threadbase-core/src/registry.test.ts __tests__/registry.test.ts
```

- [ ] **Step 2: Update imports in test file**

Change the import path from relative `./registry` to the package source:

```typescript
// Old:
import { ProviderRegistry } from "./registry";
// New:
import { ProviderRegistry } from "../src/registry";
```

Similarly update any type imports to point to `../src/session` or `../src/provider`.

- [ ] **Step 3: Run tests**

```bash
npm test
```

Expected: All tests pass.

- [ ] **Step 4: Commit tests**

```bash
git add __tests__/
git commit -m "test: add registry tests"
```

---

### Task 4: Update VSCode to consume from GitHub repo

**Files:**
- Modify: `vscode/package.json`
- Modify: `vscode/tsconfig.json`
- Delete: `vscode/packages/threadbase-core/`

- [ ] **Step 1: Add GitHub dependency to VSCode**

In `vscode/package.json`, add to `dependencies`:

```json
"@threadbase/core": "github:RonenMars/threadbase-core"
```

- [ ] **Step 2: Install the new dependency**

```bash
cd /path/to/threadbase/vscode
npm install
```

- [ ] **Step 3: Update tsconfig.json path mapping**

In `vscode/tsconfig.json`, update the path alias to point to node_modules:

```json
"paths": {
  "@threadbase/core": ["./node_modules/@threadbase/core/dist/index.d.ts"]
}
```

Or remove the path alias entirely — with `@threadbase/core` as a real npm dependency, Node module resolution will find it automatically. Check if esbuild resolves it without the alias:

```bash
node esbuild.js
```

If the build succeeds without the path alias, remove the `paths` entry from `tsconfig.json`.

- [ ] **Step 4: Verify extension builds**

```bash
node esbuild.js
```

Expected: Extension + webview builds succeed.

- [ ] **Step 5: Verify tests pass**

```bash
npm test
```

Expected: All existing tests pass.

- [ ] **Step 6: Delete local packages directory**

```bash
rm -rf packages/threadbase-core/
```

- [ ] **Step 7: Verify build still works after deletion**

```bash
node esbuild.js && npm test
```

Expected: Build and tests still pass.

- [ ] **Step 8: Commit**

```bash
git add package.json package-lock.json tsconfig.json
git rm -r packages/threadbase-core/
git commit -m "refactor: consume @threadbase/core from GitHub repo instead of local package"
```

---

### Task 5: Add threadbase-core as submodule to umbrella repo

**Files:**
- Modify: `threadbase/.gitmodules`

- [ ] **Step 1: Add submodule**

```bash
cd /path/to/threadbase
git submodule add git@github.com:RonenMars/threadbase-core.git core
```

- [ ] **Step 2: Commit**

```bash
git add .gitmodules core
git commit -m "feat: add threadbase-core as submodule"
```

---

## Phase 2: Create @threadbase/ui

### Task 6: Create threadbase-ui repo and scaffold

**Files:**
- Create: `package.json`
- Create: `tsconfig.json`
- Create: `tsup.config.ts`
- Create: `vitest.config.ts`
- Create: `.gitignore`

- [ ] **Step 1: Create GitHub repo**

```bash
gh repo create RonenMars/threadbase-ui --private --clone
cd threadbase-ui
```

- [ ] **Step 2: Create package.json**

```json
{
  "name": "@threadbase/ui",
  "version": "0.1.0",
  "description": "Shared React rendering components for Threadbase",
  "type": "module",
  "main": "dist/index.cjs",
  "module": "dist/index.js",
  "types": "dist/index.d.ts",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js",
      "require": "./dist/index.cjs"
    }
  },
  "files": ["dist"],
  "scripts": {
    "build": "tsup",
    "lint": "tsc --noEmit && npx biome check .",
    "format": "npx biome format --write .",
    "test": "vitest run"
  },
  "peerDependencies": {
    "react": "^18.0.0 || ^19.0.0",
    "react-dom": "^18.0.0 || ^19.0.0"
  },
  "dependencies": {
    "@threadbase/core": "github:RonenMars/threadbase-core",
    "react-markdown": "^10.1.0",
    "remark-gfm": "^4.0.1"
  },
  "devDependencies": {
    "@biomejs/biome": "^1.9.4",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "react": "^19.2.4",
    "react-dom": "^19.2.4",
    "tsup": "^8.4.0",
    "typescript": "^5.7.0",
    "vitest": "^3.1.0"
  }
}
```

- [ ] **Step 3: Create tsup.config.ts**

```typescript
import { defineConfig } from "tsup";

export default defineConfig({
  entry: ["src/index.ts"],
  format: ["esm", "cjs"],
  dts: true,
  splitting: false,
  clean: true,
  outDir: "dist",
  external: ["react", "react-dom"],
});
```

- [ ] **Step 4: Create tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "declaration": true,
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "jsx": "react-jsx",
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
```

- [ ] **Step 5: Create vitest.config.ts**

```typescript
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
    environment: "jsdom",
  },
});
```

- [ ] **Step 6: Create .gitignore**

```
node_modules/
dist/
*.tsbuildinfo
```

- [ ] **Step 7: Install dependencies**

```bash
npm install
```

- [ ] **Step 8: Commit scaffold**

```bash
git add -A
git commit -m "chore: scaffold @threadbase/ui package"
```

---

### Task 7: Extract standalone tool cards (no inter-component deps)

**Files:**
- Create: `src/components/tool-cards/BashTerminalCard.tsx`
- Create: `src/components/tool-cards/GrepResultCard.tsx`
- Create: `src/components/tool-cards/WriteFileCard.tsx`
- Create: `src/components/tool-cards/ReadFileCard.tsx`
- Create: `src/components/tool-cards/GlobResultCard.tsx`
- Create: `src/components/tool-cards/GenericToolCard.tsx`

Source: Electron's `src/renderer/src/components/tool-cards/`

- [ ] **Step 1: Create directory**

```bash
mkdir -p src/components/tool-cards
```

- [ ] **Step 2: Copy standalone tool card components**

```bash
ELECTRON=/path/to/threadbase/electron/src/renderer/src/components/tool-cards
cp $ELECTRON/BashTerminalCard.tsx src/components/tool-cards/
cp $ELECTRON/GrepResultCard.tsx src/components/tool-cards/
cp $ELECTRON/WriteFileCard.tsx src/components/tool-cards/
cp $ELECTRON/ReadFileCard.tsx src/components/tool-cards/
cp $ELECTRON/GlobResultCard.tsx src/components/tool-cards/
cp $ELECTRON/GenericToolCard.tsx src/components/tool-cards/
```

- [ ] **Step 3: Update imports in all copied files**

In each file, replace the relative type import:

```typescript
// Old (varies by file):
import type { BashToolResult } from "../../../../shared/types";
// New:
import type { BashToolResult } from "@threadbase/core";
```

Apply this to all 6 files, using the correct type name for each:
- `BashTerminalCard.tsx`: `BashToolResult`
- `GrepResultCard.tsx`: `GrepToolResult`
- `WriteFileCard.tsx`: `WriteToolResult`
- `ReadFileCard.tsx`: `ReadToolResult`
- `GlobResultCard.tsx`: `GlobToolResult`
- `GenericToolCard.tsx`: `GenericToolResult`, `TaskAgentToolResult`, `TaskCreateToolResult`, `TaskUpdateToolResult`

- [ ] **Step 4: Verify type-check**

```bash
npx tsc --noEmit
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add src/components/tool-cards/
git commit -m "feat: add standalone tool card components"
```

---

### Task 8: Extract DiffViewer and EditDiffCard

**Files:**
- Create: `src/components/DiffViewer.tsx`
- Create: `src/components/tool-cards/EditDiffCard.tsx`

Source: Electron's `src/renderer/src/components/`

- [ ] **Step 1: Copy DiffViewer**

```bash
cp /path/to/threadbase/electron/src/renderer/src/components/DiffViewer.tsx src/components/DiffViewer.tsx
```

- [ ] **Step 2: Update DiffViewer imports**

```typescript
// Old:
import type { StructuredPatchHunk } from "../../../shared/types";
// New:
import type { StructuredPatchHunk } from "@threadbase/core";
```

- [ ] **Step 3: Copy EditDiffCard**

```bash
cp /path/to/threadbase/electron/src/renderer/src/components/tool-cards/EditDiffCard.tsx src/components/tool-cards/EditDiffCard.tsx
```

- [ ] **Step 4: Update EditDiffCard imports**

```typescript
// Old:
import type { EditToolResult } from "../../../../shared/types";
import DiffViewer from "../DiffViewer";
// New:
import type { EditToolResult } from "@threadbase/core";
import { DiffViewer } from "../DiffViewer";
```

Verify the DiffViewer export style matches (named vs default). Adjust to use named exports consistently.

- [ ] **Step 5: Verify type-check**

```bash
npx tsc --noEmit
```

Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add src/components/DiffViewer.tsx src/components/tool-cards/EditDiffCard.tsx
git commit -m "feat: add DiffViewer and EditDiffCard"
```

---

### Task 9: Extract message components

**Files:**
- Create: `src/components/message/MessageContent.tsx`
- Create: `src/components/message/MessageNavigation.tsx`
- Create: `src/components/message/ToolInvocationBadge.tsx`

Source: Electron's `src/renderer/src/components/`

- [ ] **Step 1: Create directory**

```bash
mkdir -p src/components/message
```

- [ ] **Step 2: Copy MessageContent**

```bash
cp /path/to/threadbase/electron/src/renderer/src/components/MessageContent.tsx src/components/message/MessageContent.tsx
```

- [ ] **Step 3: Verify MessageContent imports**

MessageContent imports `react-markdown` and `remark-gfm` — both are declared in `package.json` dependencies. No type import changes needed (this component uses string props, not `@threadbase/core` types).

Verify no remaining relative imports to Electron paths.

- [ ] **Step 4: Copy MessageNavigation**

```bash
cp /path/to/threadbase/electron/src/renderer/src/components/MessageNavigation.tsx src/components/message/MessageNavigation.tsx
```

MessageNavigation uses only React — no import changes needed.

- [ ] **Step 5: Copy ToolInvocationBadge**

```bash
cp /path/to/threadbase/electron/src/renderer/src/components/ToolInvocationBadge.tsx src/components/message/ToolInvocationBadge.tsx
```

- [ ] **Step 6: Update ToolInvocationBadge imports**

```typescript
// Old:
import type { ToolUseBlock } from "../../../shared/types";
// New:
import type { ToolUseBlock } from "@threadbase/core";
```

- [ ] **Step 7: Verify type-check**

```bash
npx tsc --noEmit
```

Expected: No errors.

- [ ] **Step 8: Commit**

```bash
git add src/components/message/
git commit -m "feat: add message rendering components"
```

---

### Task 10: Extract ToolResultCard dispatcher and ErrorBoundary

**Files:**
- Create: `src/components/message/ToolResultCard.tsx`
- Create: `src/components/util/ErrorBoundary.tsx`

- [ ] **Step 1: Create util directory**

```bash
mkdir -p src/components/util
```

- [ ] **Step 2: Copy ErrorBoundary**

```bash
cp /path/to/threadbase/electron/src/renderer/src/components/ErrorBoundary.tsx src/components/util/ErrorBoundary.tsx
```

ErrorBoundary uses only React — no import changes needed.

- [ ] **Step 3: Copy ToolResultCard**

```bash
cp /path/to/threadbase/electron/src/renderer/src/components/ToolResultCard.tsx src/components/message/ToolResultCard.tsx
```

- [ ] **Step 4: Update ToolResultCard imports**

This is the dispatcher that imports all tool cards. Update all imports:

```typescript
// Old:
import type { ToolResult } from "../../../shared/types";
import EditDiffCard from "./tool-cards/EditDiffCard";
import BashTerminalCard from "./tool-cards/BashTerminalCard";
// ... etc

// New:
import type { ToolResult } from "@threadbase/core";
import { EditDiffCard } from "../tool-cards/EditDiffCard";
import { BashTerminalCard } from "../tool-cards/BashTerminalCard";
import { GrepResultCard } from "../tool-cards/GrepResultCard";
import { WriteFileCard } from "../tool-cards/WriteFileCard";
import { ReadFileCard } from "../tool-cards/ReadFileCard";
import { GlobResultCard } from "../tool-cards/GlobResultCard";
import { GenericToolCard, TaskAgentCard, TaskCreateCard, TaskUpdateCard } from "../tool-cards/GenericToolCard";
```

Adjust named vs default exports to match what was established in Tasks 7-8. Standardize all components to named exports.

- [ ] **Step 5: Verify type-check**

```bash
npx tsc --noEmit
```

Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add src/components/message/ToolResultCard.tsx src/components/util/ErrorBoundary.tsx
git commit -m "feat: add ToolResultCard dispatcher and ErrorBoundary"
```

---

### Task 11: Create public API index and verify full build

**Files:**
- Create: `src/index.ts`

- [ ] **Step 1: Create src/index.ts**

```typescript
// Tool cards
export { BashTerminalCard } from "./components/tool-cards/BashTerminalCard";
export { EditDiffCard } from "./components/tool-cards/EditDiffCard";
export { GrepResultCard } from "./components/tool-cards/GrepResultCard";
export { WriteFileCard } from "./components/tool-cards/WriteFileCard";
export { ReadFileCard } from "./components/tool-cards/ReadFileCard";
export { GlobResultCard } from "./components/tool-cards/GlobResultCard";
export {
  GenericToolCard,
  TaskAgentCard,
  TaskCreateCard,
  TaskUpdateCard,
} from "./components/tool-cards/GenericToolCard";

// Message rendering
export { MessageContent } from "./components/message/MessageContent";
export { MessageNavigation } from "./components/message/MessageNavigation";
export { ToolResultCard } from "./components/message/ToolResultCard";
export { ToolInvocationBadge } from "./components/message/ToolInvocationBadge";

// Utilities
export { DiffViewer } from "./components/DiffViewer";
export { ErrorBoundary } from "./components/util/ErrorBoundary";
```

Adjust export names to match what each component actually exports (named vs default). If any component uses `export default`, convert to named export first.

- [ ] **Step 2: Run full build**

```bash
npm run build
```

Expected: `dist/index.js`, `dist/index.cjs`, `dist/index.d.ts` created. No errors.

- [ ] **Step 3: Verify dist/index.d.ts exports all components**

```bash
grep "export" dist/index.d.ts
```

Expected: All 16 component names appear in the type declarations.

- [ ] **Step 4: Commit**

```bash
git add src/index.ts
git commit -m "feat: create public API with all component exports"
```

---

### Task 12: Standardize exports to named exports

During Tasks 7-11, import mismatches between default and named exports may have surfaced. This task normalizes everything.

**Files:**
- Modify: All files in `src/components/` that use `export default`

- [ ] **Step 1: Find all default exports**

```bash
grep -r "export default" src/
```

- [ ] **Step 2: Convert each to named export**

For each file found, change:

```typescript
// Old:
export default memo(function BashTerminalCard(...)  { ... })
// New:
export const BashTerminalCard = memo(function BashTerminalCard(...) { ... })
```

Or for non-memo components:

```typescript
// Old:
export default function ErrorBoundary(...) { ... }
// New:
export function ErrorBoundary(...) { ... }
```

- [ ] **Step 3: Update all internal imports to use named imports**

Any file in `src/` that imports another component in `src/` must use `{ Named }` syntax.

- [ ] **Step 4: Verify build**

```bash
npm run build
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add src/
git commit -m "refactor: standardize all exports to named exports"
```

---

### Task 13: Add threadbase-ui as submodule to umbrella repo

**Files:**
- Modify: `threadbase/.gitmodules`

- [ ] **Step 1: Add submodule**

```bash
cd /path/to/threadbase
git submodule add git@github.com:RonenMars/threadbase-ui.git ui
```

- [ ] **Step 2: Commit**

```bash
git add .gitmodules ui
git commit -m "feat: add threadbase-ui as submodule"
```

---

## Phase 3: Wire up consumers

### Task 14: Migrate Electron to @threadbase/ui

**Files:**
- Modify: `electron/package.json`
- Modify: `electron/src/renderer/src/components/ToolResultCard.tsx` (delete, import from package)
- Modify: All files that import from local tool-cards/
- Delete: `electron/src/renderer/src/components/tool-cards/EditDiffCard.tsx`
- Delete: `electron/src/renderer/src/components/tool-cards/BashTerminalCard.tsx`
- Delete: `electron/src/renderer/src/components/tool-cards/GrepResultCard.tsx`
- Delete: `electron/src/renderer/src/components/tool-cards/WriteFileCard.tsx`
- Delete: `electron/src/renderer/src/components/tool-cards/ReadFileCard.tsx`
- Delete: `electron/src/renderer/src/components/tool-cards/GlobResultCard.tsx`
- Delete: `electron/src/renderer/src/components/tool-cards/GenericToolCard.tsx`
- Delete: `electron/src/renderer/src/components/DiffViewer.tsx`
- Delete: `electron/src/renderer/src/components/MessageContent.tsx`
- Delete: `electron/src/renderer/src/components/MessageNavigation.tsx`
- Delete: `electron/src/renderer/src/components/ToolInvocationBadge.tsx`
- Delete: `electron/src/renderer/src/components/ErrorBoundary.tsx`

- [ ] **Step 1: Add dependencies**

In `electron/package.json`, add:

```json
"dependencies": {
  "@threadbase/core": "github:RonenMars/threadbase-core",
  "@threadbase/ui": "github:RonenMars/threadbase-ui"
}
```

```bash
cd /path/to/threadbase/electron
pnpm install
```

- [ ] **Step 2: Find all files importing from local components**

```bash
grep -r "from.*tool-cards/" src/renderer/src/ --include="*.tsx" --include="*.ts" -l
grep -r "from.*MessageContent" src/renderer/src/ --include="*.tsx" --include="*.ts" -l
grep -r "from.*MessageNavigation" src/renderer/src/ --include="*.tsx" --include="*.ts" -l
grep -r "from.*ToolInvocationBadge" src/renderer/src/ --include="*.tsx" --include="*.ts" -l
grep -r "from.*ToolResultCard" src/renderer/src/ --include="*.tsx" --include="*.ts" -l
grep -r "from.*DiffViewer" src/renderer/src/ --include="*.tsx" --include="*.ts" -l
grep -r "from.*ErrorBoundary" src/renderer/src/ --include="*.tsx" --include="*.ts" -l
```

- [ ] **Step 3: Update imports in each file found**

For each importing file, change the local import to the package import:

```typescript
// Old (example):
import { EditDiffCard } from "./tool-cards/EditDiffCard";
// New:
import { EditDiffCard } from "@threadbase/ui";
```

```typescript
// Old:
import MessageContent from "./MessageContent";
// New:
import { MessageContent } from "@threadbase/ui";
```

Apply to all files found in Step 2.

- [ ] **Step 4: Also update type imports**

Any file importing tool result types from `../../../shared/types` that are now in `@threadbase/core`:

```typescript
// Old:
import type { EditToolResult } from "../../../shared/types";
// New:
import type { EditToolResult } from "@threadbase/core";
```

Only change imports for types that moved to core. Types like `ConversationMeta` stay in the local shared types file.

- [ ] **Step 5: Delete local copies of migrated components**

```bash
rm src/renderer/src/components/tool-cards/EditDiffCard.tsx
rm src/renderer/src/components/tool-cards/BashTerminalCard.tsx
rm src/renderer/src/components/tool-cards/GrepResultCard.tsx
rm src/renderer/src/components/tool-cards/WriteFileCard.tsx
rm src/renderer/src/components/tool-cards/ReadFileCard.tsx
rm src/renderer/src/components/tool-cards/GlobResultCard.tsx
rm src/renderer/src/components/tool-cards/GenericToolCard.tsx
rm src/renderer/src/components/DiffViewer.tsx
rm src/renderer/src/components/MessageContent.tsx
rm src/renderer/src/components/MessageNavigation.tsx
rm src/renderer/src/components/ToolInvocationBadge.tsx
rm src/renderer/src/components/ToolResultCard.tsx
rm src/renderer/src/components/ErrorBoundary.tsx
```

- [ ] **Step 6: Verify build**

```bash
pnpm run build
```

Expected: electron-vite build succeeds.

- [ ] **Step 7: Run tests**

```bash
pnpm test
```

Expected: All tests pass. Fix any broken imports in test files.

- [ ] **Step 8: Manual smoke test**

```bash
pnpm run dev
```

Open the Electron app. Navigate to a conversation with tool results (Edit, Bash, Grep). Verify all tool cards render correctly.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "refactor: consume shared components from @threadbase/ui"
```

---

### Task 15: Migrate VSCode to @threadbase/ui

**Files:**
- Modify: `vscode/package.json`
- Modify: All webview-ui files that import migrated components
- Delete: `vscode/src/webview-ui/components/tool-cards/` (all files that exist in @threadbase/ui)
- Delete: `vscode/src/webview-ui/components/MessageContent.tsx`
- Delete: `vscode/src/webview-ui/components/MessageNavigation.tsx`
- Delete: `vscode/src/webview-ui/components/ToolInvocationBadge.tsx`
- Delete: `vscode/src/webview-ui/components/ToolResultCard.tsx`
- Delete: `vscode/src/webview-ui/components/DiffView.tsx` (VSCode's equivalent of DiffViewer)
- Delete: `vscode/src/webview-ui/components/ErrorBoundary.tsx`

- [ ] **Step 1: Add dependency**

In `vscode/package.json`, add to `dependencies`:

```json
"@threadbase/ui": "github:RonenMars/threadbase-ui"
```

```bash
cd /path/to/threadbase/vscode
npm install
```

- [ ] **Step 2: Find all importing files**

```bash
grep -r "from.*tool-cards/" src/webview-ui/ --include="*.tsx" --include="*.ts" -l
grep -r "from.*MessageContent" src/webview-ui/ --include="*.tsx" --include="*.ts" -l
grep -r "from.*MessageNavigation" src/webview-ui/ --include="*.tsx" --include="*.ts" -l
grep -r "from.*ToolInvocationBadge" src/webview-ui/ --include="*.tsx" --include="*.ts" -l
grep -r "from.*ToolResultCard" src/webview-ui/ --include="*.tsx" --include="*.ts" -l
grep -r "from.*DiffView" src/webview-ui/ --include="*.tsx" --include="*.ts" -l
grep -r "from.*ErrorBoundary" src/webview-ui/ --include="*.tsx" --include="*.ts" -l
```

- [ ] **Step 3: Update imports**

```typescript
// Old:
import EditDiffCard from "./tool-cards/EditDiffCard";
// New:
import { EditDiffCard } from "@threadbase/ui";
```

Apply to all files found in Step 2.

- [ ] **Step 4: Handle VSCode-specific component naming differences**

VSCode may have slightly different component names (e.g., `DiffView` vs `DiffViewer`). For each mismatch:
- If the VSCode component is functionally identical to the Electron version, swap to `@threadbase/ui` import
- If it has VSCode-specific behavior, keep the local version and don't migrate that component

- [ ] **Step 5: Delete local copies**

Remove all component files that were replaced by `@threadbase/ui` imports.

- [ ] **Step 6: Verify build**

```bash
node esbuild.js
```

Expected: Extension + webview build succeeds.

- [ ] **Step 7: Run tests**

```bash
npm test
```

Expected: All tests pass.

- [ ] **Step 8: Manual smoke test**

Press F5 in VS Code to launch Extension Development Host. Open a conversation with tool results. Verify rendering.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "refactor: consume shared components from @threadbase/ui"
```

---

### Task 16: Migrate IntelliJ webview to @threadbase/ui

**Files:**
- Modify: `intellij/webview/package.json`
- Modify: `intellij/webview/src/components/MessageCard.tsx`
- Modify: `intellij/webview/src/components/ConversationView.tsx`
- Delete: `intellij/webview/src/components/TaskToolCard.tsx`
- Modify: `intellij/webview/src/types.ts` (remove types now in @threadbase/core)

This is the most involved migration because IntelliJ currently uses custom CSS, not Tailwind.

- [ ] **Step 1: Add Tailwind v4 to IntelliJ webview**

```bash
cd /path/to/threadbase/intellij/webview
npm install tailwindcss @tailwindcss/vite --save-dev
```

- [ ] **Step 2: Add Tailwind Vite plugin**

In `intellij/webview/vite.config.ts`:

```typescript
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
  // ... existing config
});
```

- [ ] **Step 3: Add Tailwind import to CSS entry**

In `intellij/webview/src/index.css`, add at the top:

```css
@import "tailwindcss";

/* existing custom CSS below */
```

- [ ] **Step 4: Add @threadbase/core and @threadbase/ui dependencies**

In `intellij/webview/package.json`:

```json
"dependencies": {
  "@threadbase/core": "github:RonenMars/threadbase-core",
  "@threadbase/ui": "github:RonenMars/threadbase-ui"
}
```

```bash
npm install
```

- [ ] **Step 5: Update MessageCard to use shared components**

In `intellij/webview/src/components/MessageCard.tsx`, replace local tool rendering with `@threadbase/ui` components:

```typescript
import { ToolResultCard, ToolInvocationBadge } from "@threadbase/ui";
```

This replaces the simplified inline tool rendering with the full-featured shared components.

- [ ] **Step 6: Remove local types that now live in @threadbase/core**

In `intellij/webview/src/types.ts`, remove `ToolUseBlock` and any tool result types. Import from core instead:

```typescript
export type { ToolUseBlock } from "@threadbase/core";
```

Keep IntelliJ-specific types (`Conversation`, `ConversationMessage`, `MessageMetadata`) that may differ from core's `ProviderSession`/`ProviderMessage`.

- [ ] **Step 7: Delete local TaskToolCard**

```bash
rm intellij/webview/src/components/TaskToolCard.tsx
```

- [ ] **Step 8: Verify Vite build**

```bash
cd intellij/webview
npm run build
```

Expected: Assets built to `../src/main/resources/webview/` without errors.

- [ ] **Step 9: Verify Gradle build**

```bash
cd /path/to/threadbase/intellij
./gradlew buildWebview
```

Expected: Build succeeds.

- [ ] **Step 10: Manual smoke test**

```bash
./gradlew runIde
```

Open a conversation with tool results in the sandboxed IDE. Verify the new shared tool cards render correctly alongside the existing custom-CSS layout.

- [ ] **Step 11: Commit**

```bash
git add -A
git commit -m "refactor: consume shared components from @threadbase/ui, add Tailwind v4"
```

---

### Task 17: Update umbrella repo documentation

**Files:**
- Modify: `threadbase/README.md`
- Delete: `threadbase/vscode/SHARED_UI_PACKAGE_PROPOSAL.md`

- [ ] **Step 1: Update README shared packages table**

In `threadbase/README.md`, update the Shared Packages table:

```markdown
### Shared Packages

| Package | Description | Status |
|---|---|---|
| [`@threadbase/scanner`](./scanner/) | Scan, parse, search, and filter Claude Code conversation history | v0.1.0 |
| [`@threadbase/streamer`](./streamer/) | PTY session management, WebSocket streaming, REST API server | WIP |
| [`@threadbase/core`](./core/) | Multi-assistant provider abstraction and typed tool results | v0.1.0 |
| [`@threadbase/ui`](./ui/) | Shared React rendering components (tool cards, message display) | v0.1.0 |
```

- [ ] **Step 2: Delete superseded proposal**

```bash
rm vscode/SHARED_UI_PACKAGE_PROPOSAL.md
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git rm vscode/SHARED_UI_PACKAGE_PROPOSAL.md
git commit -m "docs: update shared packages table, remove superseded proposal"
```
