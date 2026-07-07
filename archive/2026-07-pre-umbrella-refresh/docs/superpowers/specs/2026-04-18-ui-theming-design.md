# @threadbase/ui Semantic Theming Layer

**Status:** Approved
**Date:** 2026-04-18
**Scope:** Add a CSS custom properties contract to @threadbase/ui so components are theme-agnostic across all consumer apps
**Depends on:** `docs/superpowers/specs/2026-04-18-shared-packages-design.md`

---

## Problem

The @threadbase/ui components currently use hardcoded Tailwind color classes (e.g., `text-neutral-300`, `bg-neutral-900`) extracted from Electron's dark-mode-only palette. This prevents adoption in apps that need different color schemes:

- **VSCode** — must follow the host IDE's active theme via `--vscode-*` CSS variables. 12 of 16 shared components couldn't migrate because they'd render wrong in light themes or non-default dark themes.
- **IntelliJ** — uses its own CSS variable system (`--text-primary`, `--bg-primary`) with explicit light/dark themes.
- **Future web app** — would need its own color scheme.

---

## Solution

Define a CSS custom properties contract (`--tb-*` prefix) that @threadbase/ui components use internally via Tailwind. Each consumer provides a small CSS file mapping these variables to their platform's color system.

---

## Token Contract

16 CSS variables covering everything the shared components need:

```css
/* Text */
--tb-text              /* Primary text */
--tb-text-muted        /* Secondary/dimmed text (paths, metadata, line numbers) */

/* Backgrounds */
--tb-bg                /* Root/page background */
--tb-bg-surface        /* Card, panel, code block background */
--tb-bg-surface-hover  /* Hover state for interactive surfaces */

/* Borders */
--tb-border            /* Standard border */

/* Diff */
--tb-diff-added-bg     /* Added line background */
--tb-diff-added-text   /* Added line text */
--tb-diff-removed-bg   /* Removed line background */
--tb-diff-removed-text /* Removed line text */

/* Code */
--tb-code-bg           /* Code/pre block background */
--tb-code-text         /* Code text color */

/* Semantic */
--tb-accent            /* Links, interactive highlights */
--tb-success           /* Green indicators */
--tb-error             /* Red indicators, stderr */
--tb-warning           /* Amber indicators */
```

---

## Tailwind Integration

@threadbase/ui ships a `theme.css` file that bridges the CSS variables into Tailwind v4's `@theme` system:

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

Components use standard Tailwind classes: `text-tb-text`, `bg-tb-bg-surface`, `border-tb-border`, etc.

@threadbase/ui also ships a `theme-default.css` with Electron's dark-mode values as defaults, so components render correctly even if the consumer hasn't set the variables yet.

---

## Consumer Mappings

### Electron (dark mode, static values)

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

### VSCode (delegates to host theme)

```css
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

### IntelliJ (maps to existing CSS variables)

```css
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

VSCode and IntelliJ mappings point to their own CSS variables, so theme changes propagate automatically. Electron uses static values.

---

## Component Color Migration

Replace all hardcoded Tailwind color classes in @threadbase/ui components with semantic `tb-*` classes:

| Hardcoded class | Semantic replacement |
|---|---|
| `text-neutral-300` | `text-tb-text` |
| `text-neutral-500` | `text-tb-text-muted` |
| `bg-neutral-900` | `bg-tb-bg-surface` |
| `bg-neutral-950` | `bg-tb-bg` |
| `border-neutral-800` | `border-tb-border` |
| `text-green-400` | `text-tb-diff-added-text` or `text-tb-success` |
| `bg-green-900/40` | `bg-tb-diff-added-bg` |
| `text-red-400` | `text-tb-diff-removed-text` or `text-tb-error` |
| `bg-red-900/40` | `bg-tb-diff-removed-bg` |
| `text-blue-400` | `text-tb-accent` |
| `text-amber-400` | `text-tb-warning` |

Non-semantic colors that don't map to the contract (e.g., syntax highlighting colors in MessageContent, purple JSON labels) stay as hardcoded Tailwind classes — they're decorative, not theme-dependent.

---

## VSCode Component Migration (Unlocked by Theming)

With semantic tokens, 3 additional VSCode components can migrate to @threadbase/ui:

| Component | Why it's now possible |
|---|---|
| ErrorBoundary | Inline `--vscode-*` styles replaced by `tb-*` tokens |
| MessageNavigation | Inline `--vscode-*` styles replaced by `tb-*` tokens |
| ToolInvocationBadge | Inline `--vscode-*` styles replaced by `tb-*` tokens |

Components that remain local in VSCode (functional differences, not theming):

| Component | Reason |
|---|---|
| ToolResultCard | Has `onOpenSubagent` prop not in shared version |
| BashTerminalCard | Uses local CollapsibleJson and DiffView/splitDiffSegments |
| EditDiffCard | Different diff input format (raw text vs StructuredPatchHunk[]) |
| GenericToolCard | Uses @uiw/react-json-view via CollapsibleJson |
| TaskToolCard variants | onOpenSubagent prop, richer status display |
| DiffView | Parses raw unified diff text, fundamentally different |
| CollapsibleJson | VSCode-specific, uses @uiw/react-json-view |
| TeamBadge | VSCode-specific, not in @threadbase/ui |

---

## Implementation Steps

### Step 1 — Update @threadbase/ui

1. Create `src/theme.css` with the `@theme` block mapping `tb-*` variables to Tailwind colors
2. Create `src/theme-default.css` with Electron's dark values as defaults
3. Replace hardcoded color classes in all 16 components with semantic `tb-*` classes
4. Update `src/index.ts` to document the CSS variable contract
5. Rebuild and verify

### Step 2 — Update Electron

1. Create `threadbase-theme.css` with the static dark-mode mapping
2. Import it in globals.css
3. Verify components render identically to before

### Step 3 — Update VSCode

1. Create `threadbase-theme.css` mapping `--tb-*` to `--vscode-*` variables
2. Import in webview styles.css
3. Migrate ErrorBoundary, MessageNavigation, ToolInvocationBadge to @threadbase/ui imports
4. Delete local copies
5. Convert remaining inline `--vscode-*` styles in non-migrated components to use `--tb-*` where applicable
6. Verify build and test in light + dark themes

### Step 4 — Update IntelliJ

1. Create `threadbase-theme.css` mapping `--tb-*` to IntelliJ's CSS variables
2. Import in webview index.css
3. Verify rendering in light and dark themes

Each step is independently shippable. The `theme-default.css` fallback ensures components render in dark mode even without an explicit consumer mapping.

---

## Files Summary

**@threadbase/ui (new/modified):**
- Create: `src/theme.css` — Tailwind @theme block
- Create: `src/theme-default.css` — default dark values
- Modify: all 16 component files (color class replacements)

**Electron:**
- Create: `src/renderer/src/styles/threadbase-theme.css`
- Modify: `src/renderer/src/styles/globals.css` (import)

**VSCode:**
- Create: `src/webview-ui/threadbase-theme.css`
- Modify: `src/webview-ui/styles.css` (import)
- Delete: `src/webview-ui/components/ErrorBoundary.tsx`
- Delete: `src/webview-ui/components/MessageNavigation.tsx`
- Delete: `src/webview-ui/components/ToolInvocationBadge.tsx`
- Modify: files that import the 3 deleted components

**IntelliJ:**
- Create: `webview/src/threadbase-theme.css`
- Modify: `webview/src/index.css` (import)
