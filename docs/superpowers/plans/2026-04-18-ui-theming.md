# @threadbase/ui Semantic Theming Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a CSS custom properties contract (`--tb-*`) to @threadbase/ui so components are theme-agnostic, then wire up all three consumer apps with platform-specific theme mappings.

**Architecture:** 16 CSS variables define the theming contract. @threadbase/ui bridges these into Tailwind v4 via `@theme`. Components replace hardcoded color classes with semantic `tb-*` classes. Each consumer provides a small CSS file mapping `--tb-*` to their platform's colors. Decorative colors (syntax highlighting, per-tool accent colors) stay hardcoded.

**Tech Stack:** CSS custom properties, Tailwind v4 `@theme`, existing build pipelines (tsup, esbuild, Vite, electron-vite)

**Spec:** `docs/superpowers/specs/2026-04-18-ui-theming-design.md`

---

## Color Mapping Reference

This table drives all component edits. Decorative colors NOT listed here stay as-is.

| Hardcoded class(es) | Semantic replacement | Semantic meaning |
|---|---|---|
| `text-neutral-100`, `text-neutral-200`, `text-neutral-300` | `text-tb-text` | Primary text |
| `text-neutral-400`, `text-neutral-500`, `text-neutral-600` | `text-tb-text-muted` | Muted/secondary text |
| `hover:text-neutral-200`, `hover:text-neutral-300` | `hover:text-tb-text` | Hover → primary text |
| `bg-neutral-950`, `bg-[#0c0c0c]` | `bg-tb-bg` | Root background |
| `bg-neutral-800`, `bg-neutral-800/80`, `bg-neutral-900`, `bg-neutral-900/70` | `bg-tb-bg-surface` | Surface/card background |
| `bg-neutral-900/30`, `bg-neutral-900/50` | `bg-tb-bg-surface` | Surface variant |
| `hover:bg-neutral-700`, `hover:bg-neutral-800` | `hover:bg-tb-bg-surface-hover` | Surface hover state |
| `border-neutral-600`, `border-neutral-700`, `border-neutral-700/60`, `border-neutral-800`, `border-neutral-800/50` | `border-tb-border` | Standard border |
| `text-green-400` (in diff context) | `text-tb-diff-added-text` | Diff added text |
| `text-green-400/80` | `text-tb-diff-added-text` | Diff added prefix |
| `bg-green-900/40` (in diff context) | `bg-tb-diff-added-bg` | Diff added background |
| `border-green-700/40` (in diff context) | `border-tb-diff-added-bg` | Diff added border |
| `text-red-400` (in diff context) | `text-tb-diff-removed-text` | Diff removed text |
| `text-red-400/80` | `text-tb-diff-removed-text` | Diff removed prefix |
| `bg-red-900/40` (in diff context) | `bg-tb-diff-removed-bg` | Diff removed background |
| `border-red-700/40` (in diff context) | `border-tb-diff-removed-bg` | Diff removed border |
| `text-blue-400` (links, accent) | `text-tb-accent` | Accent/interactive |
| `hover:text-blue-300` | `hover:text-tb-accent` | Accent hover |
| `text-green-400` (non-diff: success badge) | `text-tb-success` | Success indicator |
| `text-green-500` (terminal prompt) | `text-tb-success` | Success indicator |
| `text-red-400` (non-diff: error) | `text-tb-error` | Error indicator |
| `text-red-500/60` | `text-tb-error` | Error indicator |
| `text-amber-400`, `text-amber-400/70`, `text-amber-400/80` | `text-tb-warning` | Warning |

**Stay hardcoded (decorative, per-tool accent):**
- `text-purple-*`, `bg-purple-*`, `border-purple-*` — JSON/code blocks
- `text-cyan-*`, `bg-cyan-*`, `border-cyan-*` — Grep results accent
- `text-emerald-*`, `bg-emerald-*`, `border-emerald-*` — Read file accent
- `text-indigo-*` — Generic tool card accent
- `border-claude-orange/*` — Brand accent
- `from-purple-*/to-blue-*` — Code block gradients
- `border-amber-*`, `bg-amber-*` (tool card headers) — Warning accent badges
- `border-blue-*`, `bg-blue-*` (tool card headers) — Info accent badges
- `border-green-*`, `bg-green-*` (tool card headers) — Success accent badges

---

## Step 1: Theme Infrastructure in @threadbase/ui

### Task 1: Create theme CSS files

**Files:**
- Create: `/Users/ronen/Desktop/dev/personal/threadbase/ui/src/theme.css`
- Create: `/Users/ronen/Desktop/dev/personal/threadbase/ui/src/theme-default.css`

- [ ] **Step 1: Create src/theme.css**

This file bridges `--tb-*` CSS variables into Tailwind v4's `@theme` system:

```css
@theme {
  --color-tb-text: var(--tb-text);
  --color-tb-text-muted: var(--tb-text-muted);
  --color-tb-bg: var(--tb-bg);
  --color-tb-bg-surface: var(--tb-bg-surface);
  --color-tb-bg-surface-hover: var(--tb-bg-surface-hover);
  --color-tb-border: var(--tb-border);
  --color-tb-diff-added-bg: var(--tb-diff-added-bg);
  --color-tb-diff-added-text: var(--tb-diff-added-text);
  --color-tb-diff-removed-bg: var(--tb-diff-removed-bg);
  --color-tb-diff-removed-text: var(--tb-diff-removed-text);
  --color-tb-code-bg: var(--tb-code-bg);
  --color-tb-code-text: var(--tb-code-text);
  --color-tb-accent: var(--tb-accent);
  --color-tb-success: var(--tb-success);
  --color-tb-error: var(--tb-error);
  --color-tb-warning: var(--tb-warning);
}
```

- [ ] **Step 2: Create src/theme-default.css**

Default dark values (Electron's palette) so components render without consumer setup:

```css
:root {
  --tb-text: #e5e5e5;
  --tb-text-muted: #a3a3a3;
  --tb-bg: #0d0d0d;
  --tb-bg-surface: #1a1a1a;
  --tb-bg-surface-hover: #262626;
  --tb-border: rgba(64, 64, 64, 0.5);
  --tb-diff-added-bg: rgba(34, 197, 94, 0.1);
  --tb-diff-added-text: #86efac;
  --tb-diff-removed-bg: rgba(239, 68, 68, 0.1);
  --tb-diff-removed-text: #fca5a5;
  --tb-code-bg: #1a1a1a;
  --tb-code-text: #e5e5e5;
  --tb-accent: #60a5fa;
  --tb-success: #4ade80;
  --tb-error: #f87171;
  --tb-warning: #fbbf24;
}
```

- [ ] **Step 3: Verify Tailwind picks up the theme**

The consumer's Tailwind build must process `theme.css` for the `@theme` block to register. Since @threadbase/ui is bundled by each consumer's build tool (esbuild, Vite, electron-vite), the `@theme` block needs to be in a CSS file that the consumer imports. The component `.tsx` files will use `tb-*` classes which Tailwind generates from the `@theme` block.

For now, verify the files exist and are valid CSS. Integration testing happens in Tasks 5-7.

- [ ] **Step 4: Commit**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/ui
git add src/theme.css src/theme-default.css
git commit -m "feat: add semantic theme CSS contract and default dark values"
```

---

### Task 2: Update tool card components to use semantic tokens

**Files:**
- Modify: `/Users/ronen/Desktop/dev/personal/threadbase/ui/src/components/tool-cards/BashTerminalCard.tsx`
- Modify: `/Users/ronen/Desktop/dev/personal/threadbase/ui/src/components/tool-cards/EditDiffCard.tsx`
- Modify: `/Users/ronen/Desktop/dev/personal/threadbase/ui/src/components/tool-cards/GrepResultCard.tsx`
- Modify: `/Users/ronen/Desktop/dev/personal/threadbase/ui/src/components/tool-cards/WriteFileCard.tsx`
- Modify: `/Users/ronen/Desktop/dev/personal/threadbase/ui/src/components/tool-cards/ReadFileCard.tsx`
- Modify: `/Users/ronen/Desktop/dev/personal/threadbase/ui/src/components/tool-cards/GlobResultCard.tsx`
- Modify: `/Users/ronen/Desktop/dev/personal/threadbase/ui/src/components/tool-cards/GenericToolCard.tsx`

- [ ] **Step 1: Update BashTerminalCard.tsx**

Apply these replacements:
- Line 18: `bg-neutral-900` → `bg-tb-bg-surface`
- Line 20: `text-green-500` → `text-tb-success`
- Line 21: `text-neutral-300` → `text-tb-text`
- Line 25: leave `border-red-700/40 bg-red-900/40 text-red-400` as-is (decorative stderr badge)
- Line 32: `border-neutral-800 bg-[#0c0c0c]` → `border-tb-border bg-tb-bg`
- Line 34: `text-neutral-300` → `text-tb-text`
- Line 40: `border-neutral-800/50 text-amber-400/70` → `border-tb-border text-tb-warning`
- Line 45: `border-neutral-800/50 text-amber-400/80` → `border-tb-border text-tb-warning`
- Line 51: `text-neutral-600` → `text-tb-text-muted`
- Line 57: `border-neutral-800/50 bg-neutral-900/30 text-neutral-500` → `border-tb-border bg-tb-bg-surface text-tb-text-muted`
- Line 57: `hover:text-neutral-300` → `hover:text-tb-text`

- [ ] **Step 2: Update EditDiffCard.tsx**

Apply these replacements:
- Line 19: `text-neutral-500` → `text-tb-text-muted`
- Line 23: leave `border-amber-700/40 bg-amber-900/40 text-amber-400` (decorative badge)
- Line 27: leave `border-blue-700/40 bg-blue-900/40 text-blue-400` (decorative badge)
- Line 47: `text-neutral-500` → `text-tb-text-muted`
- Line 48: `border-neutral-700 text-neutral-500` → `border-tb-border text-tb-text-muted`
- Line 52: `border-neutral-800 bg-neutral-950 text-neutral-400` → `border-tb-border bg-tb-bg text-tb-text-muted`
- Line 54: `text-red-400/80` → `text-tb-diff-removed-text`
- Line 57: `text-green-400/80` → `text-tb-diff-added-text`

- [ ] **Step 3: Update GrepResultCard.tsx**

Apply these replacements:
- Line 16: leave `text-cyan-400` (decorative grep accent)
- Line 19: `text-neutral-300` → `text-tb-text`
- Line 20: `text-neutral-500` → `text-tb-text-muted`
- Line 24: leave `border-cyan-700/40 bg-cyan-900/40 text-cyan-400` (decorative)
- Line 29: `border-neutral-700 bg-neutral-800 text-neutral-400` → `border-tb-border bg-tb-bg-surface text-tb-text-muted`
- Line 37: `border-neutral-800 bg-neutral-950` → `border-tb-border bg-tb-bg`
- Line 38: `text-neutral-400` → `text-tb-text-muted`
- Line 44: `border-neutral-800/50 bg-neutral-900/30 text-neutral-500` → `border-tb-border bg-tb-bg-surface text-tb-text-muted`
- Line 44: `hover:text-neutral-300` → `hover:text-tb-text`

- [ ] **Step 4: Update WriteFileCard.tsx**

- Line 13: leave `text-green-400` (decorative icon)
- Line 16: `text-neutral-500` → `text-tb-text-muted`
- Line 17: `text-neutral-200` → `text-tb-text`
- Line 19: leave `border-green-700/40 bg-green-900/40 text-green-400` (decorative badge)

- [ ] **Step 5: Update ReadFileCard.tsx**

- Line 13: leave `text-emerald-400` (decorative icon)
- Line 17: `text-neutral-500` → `text-tb-text-muted`
- Line 18: `text-neutral-200` → `text-tb-text`
- Line 20: leave `border-emerald-700/40 bg-emerald-900/40 text-emerald-400` (decorative badge)

- [ ] **Step 6: Update GlobResultCard.tsx**

- Line 15: leave `text-purple-400` (decorative icon)
- Line 18: `text-neutral-300` → `text-tb-text`
- Line 21: leave `border-purple-700/40 bg-purple-900/40 text-purple-400` (decorative)
- Line 25: leave `border-amber-700/40 bg-amber-900/40 text-amber-400` (decorative badge)
- Line 33: `border-neutral-800 bg-neutral-950` → `border-tb-border bg-tb-bg`
- Line 34: `text-neutral-400` → `text-tb-text-muted`
- Line 42: `border-neutral-800/50 bg-neutral-900/30 text-neutral-500` → `border-tb-border bg-tb-bg-surface text-tb-text-muted`
- Line 42: `hover:text-neutral-300` → `hover:text-tb-text`

- [ ] **Step 7: Update GenericToolCard.tsx**

- Line 30: `border-neutral-700 bg-neutral-800 text-neutral-400` → `border-tb-border bg-tb-bg-surface text-tb-text-muted`
- Line 37: `text-neutral-500` → `text-tb-text-muted`, `hover:text-neutral-300` → `hover:text-tb-text`
- Line 43: `text-neutral-500` → `text-tb-text-muted`, `hover:text-neutral-300` → `hover:text-tb-text`
- Line 51: `border-neutral-800 bg-neutral-950 text-neutral-400` → `border-tb-border bg-tb-bg text-tb-text-muted`
- Line 64: leave `text-indigo-400` (decorative)
- Line 67: `text-neutral-300` → `text-tb-text`
- Line 68: `text-neutral-500` → `text-tb-text-muted`
- Line 72-73: leave decorative badges as-is
- Line 87: `text-green-400` → `text-tb-success`
- Line 90: `text-neutral-300` → `text-tb-text`
- Line 91: `text-neutral-400` → `text-tb-text-muted`
- Line 93: leave `border-green-700/40 bg-green-900/40 text-green-400` (decorative badge)
- Line 106: `text-blue-400` → `text-tb-accent`
- Line 109: `text-neutral-300` → `text-tb-text`
- Line 111: `text-neutral-500` → `text-tb-text-muted`
- Line 116: leave `border-blue-700/40 bg-blue-900/40 text-blue-400` (decorative badge)

- [ ] **Step 8: Verify type-check**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/ui
npx tsc --noEmit
```

Expected: No errors (only className strings changed, no type changes).

- [ ] **Step 9: Commit**

```bash
git add src/components/tool-cards/
git commit -m "feat: replace hardcoded colors with semantic tb-* tokens in tool cards"
```

---

### Task 3: Update message components and utilities to use semantic tokens

**Files:**
- Modify: `/Users/ronen/Desktop/dev/personal/threadbase/ui/src/components/message/MessageContent.tsx`
- Modify: `/Users/ronen/Desktop/dev/personal/threadbase/ui/src/components/message/MessageNavigation.tsx`
- Modify: `/Users/ronen/Desktop/dev/personal/threadbase/ui/src/components/message/ToolResultCard.tsx`
- Modify: `/Users/ronen/Desktop/dev/personal/threadbase/ui/src/components/message/ToolInvocationBadge.tsx`
- Modify: `/Users/ronen/Desktop/dev/personal/threadbase/ui/src/components/DiffViewer.tsx`
- Modify: `/Users/ronen/Desktop/dev/personal/threadbase/ui/src/components/util/ErrorBoundary.tsx`

- [ ] **Step 1: Update MessageContent.tsx**

Apply these replacements (many lines — do them systematically):
- `border-neutral-700` → `border-tb-border` (lines 81, 91, 107, 179)
- `bg-neutral-800/80` → `bg-tb-bg-surface` (line 87)
- `text-neutral-300` → `text-tb-text` (lines 91, 98)
- `text-neutral-100` → `text-tb-text` (lines 107, 114, 185)
- `text-neutral-200` → `text-tb-text` (lines 121, 128, 191)
- `border-neutral-800` → `border-tb-border` (line 98)
- `text-neutral-400` → `text-tb-text-muted` (line 157)
- `text-blue-400` → `text-tb-accent` (line 170)
- `hover:text-blue-300` → `hover:text-tb-accent` (line 170)
- `bg-neutral-900` → `bg-tb-bg-surface` (line 278)
- `text-neutral-500` → `text-tb-text-muted` (lines 279, 340)
- `border-neutral-600 bg-neutral-800 text-neutral-400` → `border-tb-border bg-tb-bg-surface text-tb-text-muted` (line 282)
- `hover:bg-neutral-700 hover:text-neutral-200` → `hover:bg-tb-bg-surface-hover hover:text-tb-text` (line 282)
- `bg-neutral-950` → `bg-tb-bg` (lines 287, 353)
- `hover:text-neutral-300` → `hover:text-tb-text` (line 340)

Leave these as-is (decorative code/JSON styling):
- All `border-purple-*`, `bg-purple-*`, `text-purple-*` (lines 335, 337, 347)
- `bg-linear-to-r from-purple-900/20 to-blue-900/20` (line 335)
- `border-claude-orange/50` (line 157)

- [ ] **Step 2: Update MessageNavigation.tsx**

- Line 62: `border-neutral-700 bg-neutral-900` → `border-tb-border bg-tb-bg-surface`
- Line 67: `text-neutral-400` → `text-tb-text-muted`
- Line 67: `hover:bg-neutral-800 hover:text-neutral-200` → `hover:bg-tb-bg-surface-hover hover:text-tb-text`
- Line 90: same pattern as line 67
- Line 111: `text-neutral-400` → `text-tb-text-muted`
- Line 123: `border-neutral-600 bg-neutral-800 text-neutral-300` → `border-tb-border bg-tb-bg-surface text-tb-text`
- Line 145: same pattern as line 67
- Line 168: same pattern as line 67

- [ ] **Step 3: Update ToolInvocationBadge.tsx**

- Line 14: `border-neutral-700/60 bg-neutral-800/80 text-neutral-400` → `border-tb-border bg-tb-bg-surface text-tb-text-muted`
- Line 18: `text-neutral-300` → `text-tb-text`
- Line 20: `text-neutral-500` → `text-tb-text-muted`

- [ ] **Step 4: Update DiffViewer.tsx**

- Line 42: `border-neutral-800 bg-neutral-950` → `border-tb-border bg-tb-bg`
- Line 46: `border-neutral-800 bg-neutral-900/70` → `border-tb-border bg-tb-bg-surface`
- Line 49: `text-neutral-500` → `text-tb-text-muted`
- Line 50: `text-neutral-200` → `text-tb-text`
- Line 53: `text-green-400` → `text-tb-diff-added-text`
- Line 54: `text-red-400` → `text-tb-diff-removed-text`
- Line 75: `border-neutral-800/50 bg-neutral-900/50 text-neutral-500` → `border-tb-border bg-tb-bg-surface text-tb-text-muted`
- Line 75: `hover:text-neutral-300` → `hover:text-tb-text`
- Line 114: `border-neutral-800/50 bg-neutral-900/50` → `border-tb-border bg-tb-bg-surface`
- Line 115: `text-neutral-500` → `text-tb-text-muted`
- Line 120: `text-neutral-600` → `text-tb-text-muted`, `hover:text-neutral-300` → `hover:text-tb-text`
- Line 132: same as 120
- Line 158: `text-neutral-600` → `text-tb-text-muted`
- Line 172: `text-blue-400` → `text-tb-accent`

- [ ] **Step 5: Update ErrorBoundary.tsx**

- Line 32: `text-neutral-400` → `text-tb-text-muted`
- Line 34: `text-red-500/60` → `text-tb-error`
- Line 38: `text-neutral-500` → `text-tb-text-muted`
- Line 41: `border border-neutral-700 bg-neutral-800` → `border border-tb-border bg-tb-bg-surface`
- Line 41: `hover:bg-neutral-700` → `hover:bg-tb-bg-surface-hover`

- [ ] **Step 6: Update ToolResultCard.tsx (dispatcher)**

ToolResultCard is a dispatcher — it likely only has `space-y-2` layout classes, no color classes. Read the file; if no color classes, skip it.

- [ ] **Step 7: Verify type-check and build**

```bash
npx tsc --noEmit && npm run build
```

Expected: No errors. Build outputs dist/ files.

- [ ] **Step 8: Commit**

```bash
git add src/components/message/ src/components/DiffViewer.tsx src/components/util/
git commit -m "feat: replace hardcoded colors with semantic tb-* tokens in message and utility components"
```

---

### Task 4: Update package exports and rebuild

**Files:**
- Modify: `/Users/ronen/Desktop/dev/personal/threadbase/ui/src/index.ts`

- [ ] **Step 1: Document theme CSS in index.ts**

Add a comment block at the top of `src/index.ts` documenting the CSS variable contract:

```typescript
/**
 * @threadbase/ui — Shared React rendering components
 *
 * Theming: Components use semantic CSS custom properties (--tb-* prefix).
 * Consumers must either:
 * 1. Import theme-default.css for dark-mode defaults, OR
 * 2. Set --tb-* variables in their own CSS (see theme.css for the @theme bridge)
 *
 * Required CSS variables:
 *   --tb-text, --tb-text-muted, --tb-bg, --tb-bg-surface, --tb-bg-surface-hover,
 *   --tb-border, --tb-diff-added-bg, --tb-diff-added-text, --tb-diff-removed-bg,
 *   --tb-diff-removed-text, --tb-code-bg, --tb-code-text, --tb-accent,
 *   --tb-success, --tb-error, --tb-warning
 */
```

- [ ] **Step 2: Full build**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/ui
npm run build
```

Expected: dist/ outputs without errors.

- [ ] **Step 3: Commit and push to GitHub**

```bash
git add src/index.ts
git commit -m "docs: document CSS variable theming contract in package entry"
git push origin main
```

Consumers install from GitHub, so the push makes the themed components available.

- [ ] **Step 4: Update consumer lockfiles**

Each consumer must reinstall @threadbase/ui to get the updated components:

```bash
cd /path/to/threadbase/electron && pnpm update @threadbase/ui
cd /path/to/threadbase/vscode && npm update @threadbase/ui
cd /path/to/threadbase/intellij/webview && npm update @threadbase/ui
```

---

## Step 2: Wire up Electron

### Task 5: Add Electron theme mapping

**Files:**
- Create: `/Users/ronen/Desktop/dev/personal/threadbase/electron/src/renderer/src/styles/threadbase-theme.css`
- Modify: `/Users/ronen/Desktop/dev/personal/threadbase/electron/src/renderer/src/styles/globals.css`

- [ ] **Step 1: Create threadbase-theme.css**

```css
/* Threadbase UI theme mapping — Electron (dark mode) */
:root {
  --tb-text: #e5e5e5;
  --tb-text-muted: #a3a3a3;
  --tb-bg: #0d0d0d;
  --tb-bg-surface: #1a1a1a;
  --tb-bg-surface-hover: #262626;
  --tb-border: rgba(64, 64, 64, 0.5);
  --tb-diff-added-bg: rgba(34, 197, 94, 0.1);
  --tb-diff-added-text: #86efac;
  --tb-diff-removed-bg: rgba(239, 68, 68, 0.1);
  --tb-diff-removed-text: #fca5a5;
  --tb-code-bg: #1a1a1a;
  --tb-code-text: #e5e5e5;
  --tb-accent: #60a5fa;
  --tb-success: #4ade80;
  --tb-error: #f87171;
  --tb-warning: #fbbf24;
}
```

- [ ] **Step 2: Import theme in globals.css**

Add at the top of `globals.css`, after the existing `@import "tailwindcss"` and `@theme` block:

```css
@import "./threadbase-theme.css";
```

- [ ] **Step 3: Also import the @threadbase/ui theme.css**

The Tailwind build needs the `@theme` block from @threadbase/ui to generate the `tb-*` utility classes. Add to globals.css:

```css
@import "@threadbase/ui/src/theme.css";
```

If this doesn't resolve (because @threadbase/ui doesn't export CSS files via its package.json), copy the `@theme` block directly into `threadbase-theme.css` below the `:root` variables.

- [ ] **Step 4: Verify build**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/electron
pnpm run build
```

Expected: electron-vite build succeeds.

- [ ] **Step 5: Visual check**

```bash
pnpm run dev
```

Open a conversation with tool results. Components should render identically to before — the semantic tokens map to the same hex values Electron was already using.

- [ ] **Step 6: Run tests**

```bash
pnpm test
```

Expected: All tests pass.

- [ ] **Step 7: Commit**

```bash
git add src/renderer/src/styles/threadbase-theme.css src/renderer/src/styles/globals.css
git commit -m "feat: add threadbase-theme.css mapping for @threadbase/ui semantic tokens"
```

---

## Step 3: Wire up VSCode and migrate 3 more components

### Task 6: Add VSCode theme mapping

**Files:**
- Create: `/Users/ronen/Desktop/dev/personal/threadbase/vscode/src/webview-ui/threadbase-theme.css`
- Modify: `/Users/ronen/Desktop/dev/personal/threadbase/vscode/src/webview-ui/styles.css`

- [ ] **Step 1: Create threadbase-theme.css**

```css
/* Threadbase UI theme mapping — VSCode (delegates to host theme) */
:root {
  --tb-text: var(--vscode-foreground);
  --tb-text-muted: var(--vscode-descriptionForeground);
  --tb-bg: var(--vscode-editor-background);
  --tb-bg-surface: var(--vscode-badge-background);
  --tb-bg-surface-hover: var(--vscode-list-hoverBackground);
  --tb-border: var(--vscode-widget-border);
  --tb-diff-added-bg: rgba(74, 222, 128, 0.1);
  --tb-diff-added-text: var(--vscode-terminal-ansiGreen);
  --tb-diff-removed-bg: rgba(248, 113, 113, 0.1);
  --tb-diff-removed-text: var(--vscode-terminal-ansiRed, #f87171);
  --tb-code-bg: var(--vscode-textBlockQuote-background);
  --tb-code-text: var(--vscode-foreground);
  --tb-accent: var(--vscode-terminal-ansiBlue);
  --tb-success: var(--vscode-terminal-ansiGreen);
  --tb-error: var(--vscode-terminal-ansiRed, #f87171);
  --tb-warning: var(--vscode-terminal-ansiYellow);
}
```

- [ ] **Step 2: Import in styles.css**

Add to `src/webview-ui/styles.css` after `@import "tailwindcss"`:

```css
@import "./threadbase-theme.css";
```

Also add the `@theme` block for tb-* tokens (same as in theme.css from @threadbase/ui):

```css
@theme {
  --color-tb-text: var(--tb-text);
  --color-tb-text-muted: var(--tb-text-muted);
  --color-tb-bg: var(--tb-bg);
  --color-tb-bg-surface: var(--tb-bg-surface);
  --color-tb-bg-surface-hover: var(--tb-bg-surface-hover);
  --color-tb-border: var(--tb-border);
  --color-tb-diff-added-bg: var(--tb-diff-added-bg);
  --color-tb-diff-added-text: var(--tb-diff-added-text);
  --color-tb-diff-removed-bg: var(--tb-diff-removed-bg);
  --color-tb-diff-removed-text: var(--tb-diff-removed-text);
  --color-tb-code-bg: var(--tb-code-bg);
  --color-tb-code-text: var(--tb-code-text);
  --color-tb-accent: var(--tb-accent);
  --color-tb-success: var(--tb-success);
  --color-tb-error: var(--tb-error);
  --color-tb-warning: var(--tb-warning);
}
```

- [ ] **Step 3: Verify build**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/vscode
node esbuild.js
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add src/webview-ui/threadbase-theme.css src/webview-ui/styles.css
git commit -m "feat: add threadbase-theme.css mapping --tb-* to --vscode-* variables"
```

---

### Task 7: Migrate 3 VSCode components to @threadbase/ui

**Files:**
- Modify: files that import ErrorBoundary, MessageNavigation, ToolInvocationBadge from local paths
- Delete: `/Users/ronen/Desktop/dev/personal/threadbase/vscode/src/webview-ui/components/ErrorBoundary.tsx`
- Delete: `/Users/ronen/Desktop/dev/personal/threadbase/vscode/src/webview-ui/components/MessageNavigation.tsx`
- Delete: `/Users/ronen/Desktop/dev/personal/threadbase/vscode/src/webview-ui/components/ToolInvocationBadge.tsx`

- [ ] **Step 1: Find all files importing these 3 components**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/vscode
grep -rn "from.*ErrorBoundary" src/webview-ui/ --include="*.tsx" --include="*.ts"
grep -rn "from.*MessageNavigation" src/webview-ui/ --include="*.tsx" --include="*.ts"
grep -rn "from.*ToolInvocationBadge" src/webview-ui/ --include="*.tsx" --include="*.ts"
```

- [ ] **Step 2: Update imports**

For each importing file, change local imports to @threadbase/ui:

```typescript
// Old:
import ErrorBoundary from './components/ErrorBoundary'
// New:
import { ErrorBoundary } from '@threadbase/ui'

// Old:
import MessageNavigation from './components/MessageNavigation'
// New:
import { MessageNavigation } from '@threadbase/ui'

// Old:
import ToolInvocationBadge from './components/ToolInvocationBadge'
// New:
import { ToolInvocationBadge } from '@threadbase/ui'
```

Note: VSCode uses default imports, @threadbase/ui uses named exports. Make sure to switch from `import X` to `import { X }`.

- [ ] **Step 3: Delete local copies**

```bash
rm src/webview-ui/components/ErrorBoundary.tsx
rm src/webview-ui/components/MessageNavigation.tsx
rm src/webview-ui/components/ToolInvocationBadge.tsx
```

- [ ] **Step 4: Verify build**

```bash
node esbuild.js
```

Expected: Build succeeds.

- [ ] **Step 5: Run tests**

```bash
npm test
```

Expected: Tests pass. Fix any test files that imported the deleted components.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "refactor: migrate ErrorBoundary, MessageNavigation, ToolInvocationBadge to @threadbase/ui"
```

---

## Step 4: Wire up IntelliJ

### Task 8: Add IntelliJ theme mapping

**Files:**
- Create: `/Users/ronen/Desktop/dev/personal/threadbase/intellij/webview/src/threadbase-theme.css`
- Modify: `/Users/ronen/Desktop/dev/personal/threadbase/intellij/webview/src/index.css`

- [ ] **Step 1: Create threadbase-theme.css**

```css
/* Threadbase UI theme mapping — IntelliJ (maps to existing CSS variables) */
:root {
  --tb-text: var(--text-primary);
  --tb-text-muted: var(--text-secondary);
  --tb-bg: var(--bg-primary);
  --tb-bg-surface: var(--tool-bg);
  --tb-bg-surface-hover: var(--bg-secondary);
  --tb-border: var(--border-color);
  --tb-diff-added-bg: rgba(74, 222, 128, 0.1);
  --tb-diff-added-text: #4ade80;
  --tb-diff-removed-bg: rgba(248, 113, 113, 0.1);
  --tb-diff-removed-text: #f87171;
  --tb-code-bg: var(--code-bg);
  --tb-code-text: var(--text-primary);
  --tb-accent: var(--accent-color);
  --tb-success: #4caf50;
  --tb-error: #ef4444;
  --tb-warning: #fbbf24;
}
```

- [ ] **Step 2: Import in index.css**

Add to `webview/src/index.css` after the existing `@import "tailwindcss"`:

```css
@import "./threadbase-theme.css";
```

Also add the `@theme` block for tb-* tokens (same block as VSCode/Electron):

```css
@theme {
  --color-tb-text: var(--tb-text);
  --color-tb-text-muted: var(--tb-text-muted);
  --color-tb-bg: var(--tb-bg);
  --color-tb-bg-surface: var(--tb-bg-surface);
  --color-tb-bg-surface-hover: var(--tb-bg-surface-hover);
  --color-tb-border: var(--tb-border);
  --color-tb-diff-added-bg: var(--tb-diff-added-bg);
  --color-tb-diff-added-text: var(--tb-diff-added-text);
  --color-tb-diff-removed-bg: var(--tb-diff-removed-bg);
  --color-tb-diff-removed-text: var(--tb-diff-removed-text);
  --color-tb-code-bg: var(--tb-code-bg);
  --color-tb-code-text: var(--tb-code-text);
  --color-tb-accent: var(--tb-accent);
  --color-tb-success: var(--tb-success);
  --color-tb-error: var(--tb-error);
  --color-tb-warning: var(--tb-warning);
}
```

- [ ] **Step 3: Verify Vite build**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/intellij/webview
npm run build
```

Expected: Assets built to `../src/main/resources/webview/`.

- [ ] **Step 4: Verify Gradle build**

```bash
cd /Users/ronen/Desktop/dev/personal/threadbase/intellij
./gradlew buildWebview
```

Expected: BUILD SUCCESSFUL.

- [ ] **Step 5: Commit**

```bash
git add webview/src/threadbase-theme.css webview/src/index.css
git commit -m "feat: add threadbase-theme.css mapping --tb-* to IntelliJ CSS variables"
```
