# Conversation Metadata Fields — Cross-Platform Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Surface `firstMessage`, `lastMessage`, `filePath`, `preview`, and `account` in the conversation list UI across all four Threadbase apps (mobile, electron, vscode, intellij).

**Architecture:** The `@threadbase/scanner` package already exposes these fields. The streamer REST API already returns them. Each app has its own copy of the scanner/parser — the electron, vscode, and intellij apps parse JSONL directly with independent scanners that need the same `firstMessage`/`lastMessage` tracking added. The mobile app consumes the streamer API and already receives these fields — it only needs UI work.

**Tech Stack:** TypeScript (mobile/electron/vscode), Kotlin (intellij), React Native (mobile), React (electron/vscode webview), Swing/IntelliJ UI (intellij)

---

## File Map

### Mobile (API consumer — UI only)
| Action | File |
|--------|------|
| Modify | `mobile/hooks/useConversations.ts` — map new API fields through `adaptPage()` |
| Modify | `mobile/components/conversation/ConversationList.tsx` — render new fields |

### Electron (independent scanner + UI)
| Action | File |
|--------|------|
| Modify | `electron/src/shared/types.ts` — add `MessageSnapshot`, `firstMessage`, `lastMessage` to types |
| Modify | `electron/src/main/services/scanner.ts:109-188` — track first/last message in parser |
| Modify | `electron/src/renderer/src/components/ResultsList.tsx:757-856` — display in `ResultItem` |

### VSCode (independent scanner + UI)
| Action | File |
|--------|------|
| Modify | `vscode/src/core/types.ts:19-36` — add `MessageSnapshot`, `firstMessage`, `lastMessage` |
| Modify | `vscode/src/core/scanner.ts:126-239` — track first/last message in parser |
| Modify | `vscode/src/webview-ui-list/components/ConversationCard.tsx` — display new fields |

### IntelliJ (Kotlin scanner + UI)
| Action | File |
|--------|------|
| Modify | `intellij/src/main/kotlin/com/claudehistory/core/model/Models.kt:19-34` — add `MessageSnapshot`, `firstMessage`, `lastMessage` |
| Modify | `intellij/src/main/kotlin/com/claudehistory/core/scanner/ConversationScanner.kt:151-255` — track first/last message |
| Modify | `intellij/src/main/kotlin/com/claudehistory/ui/tree/nodes/ConversationNode.kt` — display new fields |

---

## Task 1: Mobile — Map API Fields Through Data Layer

The streamer API already returns `sessionName`, `filePath`, `preview`, `account`, `firstMessage`, `lastMessage`. The mobile types already declare them. But `useConversations.ts` has a legacy `adaptPage()` that drops them.

**Files:**
- Modify: `mobile/hooks/useConversations.ts:8-32`

- [ ] **Step 1: Update `RawSessionMeta` to accept camelCase fields from streamer**

The streamer returns camelCase (not snake_case like the old Go server). The `adaptPage()` function already has a fast path that returns `ConversationPage` directly when the response is not an array (line 22-23). But the streamer returns a `ConversationPage` object with a `conversations` array, so it hits that path. However, the conversations inside still lack the new fields because the `Conversation` objects come straight from the server.

Check whether the streamer response hits the array path or the object path. The streamer's `/api/conversations` returns `{ conversations: [...], hasMore, offset, total }` — so `!Array.isArray(raw)` is `true` and it returns `raw as ConversationPage` directly. This means the new fields are already flowing through if the `Conversation` type matches.

Verify this is the case — if the streamer returns camelCase and the types match, no adapter change is needed for the list endpoint. The search endpoint (`/api/search`) also returns `{ conversations: [...] }` via `useConversationSearch`, and that function (line 203) calls `api.get<RawSessionMeta[]>` which expects an array — but the streamer returns an object. Check if the search adapter works correctly.

```typescript
// mobile/hooks/useConversations.ts — line 203
// Current: api.get<RawSessionMeta[]>(`/api/search?q=...`)
// Streamer returns: { conversations: [...], hasMore, offset, total }
// Fix: extract .conversations from the response

// In useConversationSearch, change:
const raw = await api.get<RawSessionMeta[]>(`/api/search?q=${encodeURIComponent(query)}&limit=50`)
return { serverId, page: adaptPage(raw, 0, 50) }

// To:
const resp = await api.get<ConversationPage>(`/api/search?q=${encodeURIComponent(query)}&limit=50`)
return { serverId, page: resp }
```

- [ ] **Step 2: Verify list data flows through**

Start the mobile dev server and the streamer. Open the History tab. Add a `console.log` in `ConversationList.tsx` to print the first conversation object:

```typescript
// Temporary — add at top of ConversationRow
console.log('conv fields:', JSON.stringify({
  sessionName: c.sessionName,
  preview: c.preview,
  firstMessage: c.firstMessage,
  lastMessage: c.lastMessage,
  account: c.account,
  filePath: c.filePath,
}, null, 2))
```

Run: `cd mobile && npx expo start`

Expected: Console shows all six fields populated for conversations that have them.

- [ ] **Step 3: Remove temporary log and commit**

```bash
cd mobile
git add hooks/useConversations.ts
git commit -m "fix: use ConversationPage type for search results to pass new fields through"
```

---

## Task 2: Mobile — Display New Fields in Conversation List

**Files:**
- Modify: `mobile/components/conversation/ConversationList.tsx:26-57`

- [ ] **Step 1: Add `firstMessage` timestamp as subtitle**

Below the existing `sessionName` line (line 37-39), add the first message date formatted as a full date-time. Replace the generic `lastActivity` date on the right with the `lastMessage` timestamp when available.

```tsx
// In ConversationRow, after the sessionName block (around line 39):
{c.firstMessage ? (
  <Text style={styles.metaText} numberOfLines={1}>
    {new Date(c.firstMessage.timestamp).toLocaleDateString()} — {c.firstMessage.text.slice(0, 80)}
  </Text>
) : null}
```

- [ ] **Step 2: Add `preview` as a content snippet when no `firstMessage`**

```tsx
// Fallback when firstMessage is not available:
{!c.firstMessage && c.preview ? (
  <Text style={styles.metaText} numberOfLines={1}>
    {c.preview.slice(0, 80)}
  </Text>
) : null}
```

- [ ] **Step 3: Test on device**

Run: `cd mobile && npx expo start`

Verify:
- Conversations with firstMessage show date + truncated text
- Conversations without firstMessage show preview
- Layout doesn't overflow or clip badly
- Scrolling performance is fine (no expensive renders)

- [ ] **Step 4: Commit**

```bash
cd mobile
git add components/conversation/ConversationList.tsx
git commit -m "feat(mobile): display first message preview in conversation list"
```

---

## Task 3: Electron — Add Types

**Files:**
- Modify: `electron/src/shared/types.ts:15-29`

- [ ] **Step 1: Add `MessageSnapshot` interface and new fields to `ConversationMeta`**

```typescript
// electron/src/shared/types.ts — add before ConversationMeta:
export interface MessageSnapshot {
  text: string
  timestamp: string
}

// Add to ConversationMeta (after line 28, before the closing brace):
  firstMessage: MessageSnapshot | null
  lastMessage: MessageSnapshot | null
```

- [ ] **Step 2: Add the same fields to `SearchResult`**

```typescript
// In SearchResult interface (after line 56):
  firstMessage: MessageSnapshot | null
  lastMessage: MessageSnapshot | null
```

- [ ] **Step 3: Verify it compiles**

Run: `cd electron && npm run typecheck` (or `npx tsc --noEmit`)

Expected: Type errors in scanner.ts and indexer.ts because the return objects now miss the new required fields. This is correct — we'll fix them in the next task.

- [ ] **Step 4: Commit**

```bash
cd electron
git add src/shared/types.ts
git commit -m "feat(electron): add MessageSnapshot, firstMessage, lastMessage to types"
```

---

## Task 4: Electron — Update Scanner Parser

**Files:**
- Modify: `electron/src/main/services/scanner.ts:109-188`

- [ ] **Step 1: Add tracking variables**

At the top of `parseConversationMeta` (after line 115), add:

```typescript
    let firstMessage: { text: string; timestamp: string } | null = null
    let lastMessage: { text: string; timestamp: string } | null = null
```

- [ ] **Step 2: Capture first/last message in the parse loop**

Inside the `if (content)` block (around line 140), after `messageCount++` and before the preview logic, add:

```typescript
            const ts = entry.timestamp || ''
            if (!firstMessage) {
              firstMessage = { text: content.slice(0, 200), timestamp: ts }
            }
            lastMessage = { text: content.slice(0, 200), timestamp: ts }
```

- [ ] **Step 3: Add fields to return object**

In the return object (line 174-187), add after `account`:

```typescript
      firstMessage,
      lastMessage,
```

- [ ] **Step 4: Update the indexer to pass through new fields**

The `SearchIndexer` in `electron/src/main/services/indexer.ts` builds `SearchResult` objects from `ConversationMeta`. Find where it maps meta → SearchResult and add the new fields:

```typescript
      firstMessage: meta.firstMessage,
      lastMessage: meta.lastMessage,
```

- [ ] **Step 5: Verify it compiles**

Run: `cd electron && npx tsc --noEmit`

Expected: No type errors.

- [ ] **Step 6: Commit**

```bash
cd electron
git add src/main/services/scanner.ts src/main/services/indexer.ts
git commit -m "feat(electron): track firstMessage/lastMessage in scanner parser"
```

---

## Task 5: Electron — Display in ResultItem

**Files:**
- Modify: `electron/src/renderer/src/components/ResultsList.tsx:757-856`

- [ ] **Step 1: Add first message date to ResultItem**

In the `ResultItem` component, find where `timestamp` is displayed (around line 828). Below the existing session name / UUID line, add a row showing the first message date and snippet:

```tsx
{result.firstMessage ? (
  <div className="result-first-message">
    <span className="first-message-date">
      {new Date(result.firstMessage.timestamp).toLocaleDateString()}
    </span>
    <span className="first-message-text">
      {result.firstMessage.text.slice(0, 60)}
    </span>
  </div>
) : null}
```

- [ ] **Step 2: Add CSS for the new element**

Match the existing muted text style used for session slugs. Use `color: var(--text-secondary)` and `font-size: 0.8em`.

- [ ] **Step 3: Test in Electron**

Run: `cd electron && npm run dev`

Verify:
- First message snippet appears below session name
- Text truncates cleanly
- No layout breakage in flat, grouped, and tree views

- [ ] **Step 4: Commit**

```bash
cd electron
git add src/renderer/src/components/ResultsList.tsx
git commit -m "feat(electron): display first message preview in conversation list"
```

---

## Task 6: VSCode — Add Types

**Files:**
- Modify: `vscode/src/core/types.ts:19-36`

- [ ] **Step 1: Add `MessageSnapshot` and new fields to `ConversationMeta`**

```typescript
// vscode/src/core/types.ts — add before ConversationMeta:
export interface MessageSnapshot {
  text: string;
  timestamp: string;
}

// Add to ConversationMeta (after lastMessageSender line):
  firstMessage: MessageSnapshot | null;
  lastMessage: MessageSnapshot | null;
```

- [ ] **Step 2: Verify it compiles**

Run: `cd vscode && npx tsc --noEmit`

Expected: Type errors in scanner.ts where the return object is missing the new fields.

- [ ] **Step 3: Commit**

```bash
cd vscode
git add src/core/types.ts
git commit -m "feat(vscode): add MessageSnapshot, firstMessage, lastMessage to types"
```

---

## Task 7: VSCode — Update Scanner Parser

**Files:**
- Modify: `vscode/src/core/scanner.ts:126-239`

- [ ] **Step 1: Add tracking variables**

After line 138 (`let firstUserSeen = false;`), add:

```typescript
    let firstMessage: { text: string; timestamp: string } | null = null;
    let lastMessage: { text: string; timestamp: string } | null = null;
```

- [ ] **Step 2: Capture first/last message in parse loop**

Inside the `if (content)` block (around line 176), after `messageCount++` and the `lastMessageSender` assignment, before the preview logic:

```typescript
            const ts = entry.timestamp || "";
            if (!firstMessage) {
              firstMessage = { text: content.slice(0, 200), timestamp: ts };
            }
            lastMessage = { text: content.slice(0, 200), timestamp: ts };
```

- [ ] **Step 3: Add to return object**

In the return object (line 220-238), add after `account`:

```typescript
      firstMessage,
      lastMessage,
```

- [ ] **Step 4: Verify it compiles**

Run: `cd vscode && npx tsc --noEmit`

Expected: No type errors.

- [ ] **Step 5: Commit**

```bash
cd vscode
git add src/core/scanner.ts
git commit -m "feat(vscode): track firstMessage/lastMessage in scanner parser"
```

---

## Task 8: VSCode — Display in Conversation Card

**Files:**
- Modify: `vscode/src/webview-ui-list/components/ConversationCard.tsx`

- [ ] **Step 1: Add first message preview to the card**

Below the existing preview text, add the first message date and snippet. Match the existing secondary text styling:

```tsx
{meta.firstMessage ? (
  <div className="conversation-first-message">
    <span className="first-msg-date">
      {new Date(meta.firstMessage.timestamp).toLocaleDateString()}
    </span>
    {" — "}
    <span className="first-msg-text">
      {meta.firstMessage.text.slice(0, 60)}
    </span>
  </div>
) : null}
```

- [ ] **Step 2: Update the tree view tooltip**

In `vscode/src/providers/ConversationTreeProvider.ts`, find where the tooltip is built for `ConversationItem` (around line 200). Add first/last message timestamps to the tooltip:

```typescript
if (meta.firstMessage) {
  tooltip += `\nStarted: ${new Date(meta.firstMessage.timestamp).toLocaleString()}`
}
if (meta.lastMessage) {
  tooltip += `\nLast activity: ${new Date(meta.lastMessage.timestamp).toLocaleString()}`
}
```

- [ ] **Step 3: Test in VSCode**

Run: `cd vscode && npm run watch` then open the extension host via F5.

Verify:
- Conversation cards show first message preview
- Tree view tooltips show start/last timestamps
- No regressions in existing functionality

- [ ] **Step 4: Commit**

```bash
cd vscode
git add src/webview-ui-list/components/ConversationCard.tsx src/providers/ConversationTreeProvider.ts
git commit -m "feat(vscode): display first/last message in conversation card and tooltip"
```

---

## Task 9: IntelliJ — Add Data Model Fields

**Files:**
- Modify: `intellij/src/main/kotlin/com/claudehistory/core/model/Models.kt:19-34`

- [ ] **Step 1: Add `MessageSnapshot` data class**

Before `ConversationMeta`, add:

```kotlin
@Serializable
data class MessageSnapshot(
    val text: String,
    val timestamp: String
)
```

- [ ] **Step 2: Add new fields to `ConversationMeta`**

Add at the end of the `ConversationMeta` data class (before the closing parenthesis on line 34):

```kotlin
    val firstMessage: MessageSnapshot? = null,
    val lastMessage: MessageSnapshot? = null
```

- [ ] **Step 3: Verify it compiles**

Run: `cd intellij && ./gradlew compileKotlin`

Expected: Errors in `ConversationScanner.kt` where the constructor call is missing the new fields (or no errors if using named args with defaults).

- [ ] **Step 4: Commit**

```bash
cd intellij
git add src/main/kotlin/com/claudehistory/core/model/Models.kt
git commit -m "feat(intellij): add MessageSnapshot, firstMessage, lastMessage to model"
```

---

## Task 10: IntelliJ — Update Scanner Parser

**Files:**
- Modify: `intellij/src/main/kotlin/com/claudehistory/core/scanner/ConversationScanner.kt:151-255`

- [ ] **Step 1: Add tracking variables**

After line 167 (`var model: String? = null`), add:

```kotlin
        var firstMessage: MessageSnapshot? = null
        var lastMessage: MessageSnapshot? = null
```

- [ ] **Step 2: Capture first/last message in parse loop**

Inside the `if (content.isNotBlank())` block (line 215), before the preview logic:

```kotlin
                    if (content.isNotBlank()) {
                        val ts = entry["timestamp"]?.jsonPrimitive?.contentOrNull ?: ""
                        if (firstMessage == null) {
                            firstMessage = MessageSnapshot(text = content.take(200), timestamp = ts)
                        }
                        lastMessage = MessageSnapshot(text = content.take(200), timestamp = ts)

                        // existing preview/snippet logic continues...
```

- [ ] **Step 3: Add to constructor call**

In the `ConversationMeta(...)` constructor call (line 237-254), add:

```kotlin
            firstMessage = firstMessage,
            lastMessage = lastMessage
```

- [ ] **Step 4: Verify it compiles**

Run: `cd intellij && ./gradlew compileKotlin`

Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
cd intellij
git add src/main/kotlin/com/claudehistory/core/scanner/ConversationScanner.kt
git commit -m "feat(intellij): track firstMessage/lastMessage in scanner parser"
```

---

## Task 11: IntelliJ — Display in ConversationNode

**Files:**
- Modify: `intellij/src/main/kotlin/com/claudehistory/ui/tree/nodes/ConversationNode.kt`

- [ ] **Step 1: Add first message info to the tree node display**

In `ConversationNode`, the `update` method builds the presentation. Add the first message date to the location text or as a secondary line. Find where `meta.preview` is used as the node text and append the first message info to the tooltip:

```kotlin
// In the tooltip builder, add:
if (meta.firstMessage != null) {
    append("\nStarted: ${formatTimestamp(meta.firstMessage.timestamp)}")
}
if (meta.lastMessage != null) {
    append("\nLast: ${formatTimestamp(meta.lastMessage.timestamp)}")
}
```

Add a helper:
```kotlin
private fun formatTimestamp(iso: String): String {
    return try {
        val instant = java.time.Instant.parse(iso)
        val local = java.time.LocalDateTime.ofInstant(instant, java.time.ZoneId.systemDefault())
        local.format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"))
    } catch (_: Exception) {
        iso
    }
}
```

- [ ] **Step 2: Test in IntelliJ**

Run: `cd intellij && ./gradlew runIde`

Verify:
- Hover over conversation nodes shows start/last timestamps in tooltip
- No visual regressions

- [ ] **Step 3: Commit**

```bash
cd intellij
git add src/main/kotlin/com/claudehistory/ui/tree/nodes/ConversationNode.kt
git commit -m "feat(intellij): display first/last message timestamps in tree tooltip"
```

---

## Task 12: Update Root Submodule Refs

- [ ] **Step 1: Update all submodule refs**

```bash
cd /path/to/threadbase
git add mobile electron vscode intellij
git commit -m "chore: update submodule refs (conversation metadata fields)"
git push
```
