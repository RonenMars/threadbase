# Bug: Conversation detail takes 5-10s to load

## Summary

Opening a conversation detail (`GET /api/conversations/:id`) takes ~5 seconds server-side. The mobile app shows a basic spinner with no progress indication, making it feel even slower.

## Root cause

`findConversationByUuid` in `server.ts` creates a new `ConversationScanner`, calls `scanner.scan()` (walks all JSONL files), then searches the metadata cache for a matching UUID. This full scan happens on every detail request — there's no caching or direct lookup.

```typescript
private async findConversationByUuid(uuid: string): Promise<Conversation | null> {
  const scanner = new ConversationScanner();
  await scanner.scan();  // <-- scans ALL conversation files every time
  const meta = [...scanner.getMetadataCache().values()].find((m) =>
    m.id.endsWith(`/${uuid}.jsonl`),
  );
  if (!meta) return null;
  return scanner.getConversation(meta.id);
}
```

## Measured

| Conversation | Messages | Response size | Server time |
|---|---|---|---|
| f91695d9... | 33 | 34 KB | ~5s |

## Fix options

### Backend (performance)

**Option A — Cache the scanner instance.** Keep a single `ConversationScanner` alive on the server, refresh it periodically or on file changes. Avoids re-scanning on every request.

**Option B — Direct file lookup.** The UUID maps directly to a file path pattern: `~/.claude/projects/*/<uuid>.jsonl`. Use a glob instead of a full scan.

**Option C — Build an index.** On startup, scan once and build a UUID → filePath map. Refresh on file watcher events.

### Mobile (UX)

**Option D — Skeleton loader.** Replace the plain `ActivityIndicator` with a skeleton screen showing placeholder message bubbles. Feels faster even if the load time is the same.

**Option E — Progressive loading.** Stream the conversation metadata first (title, message count), then load messages. Show the header immediately and messages as they arrive.

## Files involved

- `streamer/src/server.ts` — `findConversationByUuid` does a full scan per request
- `mobile/app/conversation/[id].tsx` — loading state is a centered `ActivityIndicator`
