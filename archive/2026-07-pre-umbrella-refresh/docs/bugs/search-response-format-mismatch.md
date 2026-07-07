# Bug: Search endpoint response format doesn't match mobile expectations

## Summary

The `/api/search` endpoint returns results in scanner format, but the mobile app expects the same adapted format as `/api/conversations`.

## Details

**Streamer returns** (array of scanner search results):
```json
[
  {
    "meta": { "id": "/full/path.jsonl", "filePath": "...", "sessionId": "...", "projectName": "dev/briya/agents", ... },
    "score": 1,
    "matches": [{ "field": "contentSnippet", "snippet": "..." }]
  }
]
```

**Mobile expects** (`useConversationSearch` in `hooks/useConversations.ts:193`):
The hook calls `api.get<RawSessionMeta[]>('/api/search?q=...')` and passes the result to `adaptPage()`, which expects the same shape as the list endpoint — objects with `id` (UUID only), `title`, `projectPath`, `branch`, `messageCount`, `lastActivity`.

The mismatch causes `adaptPage` to produce empty/broken results silently.

## Fix

In `streamer/src/server.ts` `handleSearch`, adapt the scanner search results to the mobile-expected format, same as `handleListConversations` does:

```typescript
const results = await search(q, { limit });
const adapted = results.map((r) => ({
  id: r.meta.id.split("/").pop()?.replace(/\.jsonl$/, "") ?? r.meta.id,
  title: r.meta.projectName,
  projectPath: r.meta.projectPath,
  branch: r.meta.gitBranch ?? undefined,
  messageCount: r.meta.messageCount,
  lastActivity: r.meta.timestamp,
  score: r.score,
  matches: r.matches,
}));
json(res, 200, { conversations: adapted, hasMore: false, offset: 0, total: adapted.length });
```

## Files involved

- `streamer/src/server.ts` — `handleSearch` returns raw scanner format
- `mobile/hooks/useConversations.ts:193` — `useConversationSearch` expects adapted format
