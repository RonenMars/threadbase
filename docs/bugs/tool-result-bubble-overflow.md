# Bug: Large message bubbles overflow and overlap other messages

## Summary

In the conversation detail view, messages with large content (tool results, long assistant responses with code blocks) overflow their bounds and overlap adjacent messages. Affects both user bubbles (blue) and assistant bubbles (gray).

## Root cause

The JSONL has three kinds of `user`-role messages:

1. **Real user prompts** — short text the user typed
2. **Tool results** — have `toolUseResult` key and `content[0].type === "tool_result"`; contain the full output of a tool (e.g. 17K chars from a Read)
3. **Meta/system messages** — have `isMeta: true` and `sourceToolUseID`; injected context like CLAUDE.md contents (up to 122K chars)

The scanner collapses all three into `{ role: "user", text: "..." }`. The streamer passes them through as plain text. The mobile app renders all user-role messages as blue `MessageBubble` components with no height cap on code blocks.

## Reproduction

Open conversation `83f79acc-9b8a-4f6b-80cf-abda1d7395cc` (dev/briya/e2e) in the mobile app. Scroll to the Read tool result — it renders as a massive blue bubble showing the full Shell README (17K chars with multiple code blocks).

## Affected messages

| JSONL line | Size   | Type                        |
|------------|--------|-----------------------------|
| 22         | 122 KB | Meta/system (isMeta + sourceToolUseID) |
| 58         | 27 KB  | Tool result (Read)          |
| 62         | 38 KB  | Tool result (Read)          |

## Fix options

**Option A — Filter in streamer (recommended for user bubbles).** In `handleGetConversation`, skip or collapse messages where the scanner metadata indicates a tool result or meta message. The assistant's `tool_use` card already represents the tool interaction — the result just needs a short summary or nothing.

**Option B — Filter in mobile.** Add format detection in the mobile adapter to identify tool result messages (e.g. by matching against the preceding assistant tool_use) and render them as collapsible cards instead of bubbles.

**Option C — Cap in MessageBubble (recommended for both roles).** Add `maxHeight` + "Show more" to `CodeBlock` in `MessageBubble.tsx`. This is needed regardless of A/B because assistant messages can also contain large code blocks that overflow. `FlashList` needs accurate item heights — uncapped content breaks layout estimation and causes overlap.

## Files involved

- `streamer/src/server.ts` — `handleGetConversation` message mapping
- `mobile/components/conversation/MessageBubble.tsx` — `CodeBlock` has no height limit
- `mobile/app/conversation/[id].tsx` — `MessageItem` doesn't distinguish tool results from user text
