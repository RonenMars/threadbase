# Bug: Expo runtime warnings and errors

## Summary

Several warnings and errors appear in Expo dev logs during normal app usage.

## Issues

### 1. TerminalStream fetches output for discovered sessions (404)

```
WARN [TerminalStream] history fetch failed: [NotFoundError: Not found: /api/sessions/disc_15277/output]
WARN [TerminalStream] history fetch failed: [NotFoundError: Not found: /api/sessions/disc_90266/output]
```

The session screen tries to fetch `/api/sessions/:id/output` for discovered sessions (`disc_*`). Discovered sessions don't have PTY output — only managed sessions (started via Resume) do. The mobile app should skip the output fetch for `source: "discovered"` sessions, or the streamer should return an empty output instead of 404.

### 2. VirtualizedList slow update warning

```
LOG VirtualizedList: You have a large list that is slow to update - make sure your renderItem function renders components that follow React performance best practices like PureComponent, shouldComponentUpdate, etc. {"contentLength": 15316, "dt": 8049, "prevDt": 8664}
```

The conversation detail FlashList takes 8+ seconds to render. Related to the large message bubble issue (tool results rendering as massive bubbles). Fixing the bubble overflow bug should also fix this — fewer/smaller items means faster rendering.

### 3. expo-notifications warnings (ignorable)

```
WARN expo-notifications: Android Push notifications functionality was removed from Expo Go with SDK 53.
WARN expo-notifications functionality is not fully supported in Expo Go.
```

Expected when running in Expo Go. Will disappear with a development build. Not a bug.

## Files involved

- `mobile/hooks/useTerminalStream.ts` — fetches output for all sessions including discovered
- `mobile/app/conversation/[id].tsx` — FlashList rendering performance
- `mobile/components/conversation/MessageBubble.tsx` — uncapped code blocks cause slow renders
