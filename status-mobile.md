# threadbase-mobile — Status & Action Items

**Last scanned:** 2026-04-12  
**Language:** TypeScript · React Native 0.74 · Expo 51  
**Visibility:** Private

---

## Status

The mobile app is the newest repo in the suite (created 2026-04-09). It is an Expo-based React Native app that acts as a **remote control center** for Claude Code agent sessions running on a server — distinct from the other clients which read local JSONL files directly. The architecture and feature set are solid for an early-stage product, but the app **cannot be built or tested** in the current environment because `npm install` has not been run. There are also a few bugs and gaps that need attention before the first real test run.

### What's working
- Onboarding: server URL + API key setup, QR code hint, SecureStore credential persistence
- Kanban board: 4 columns (Running / Waiting / Completed / Failed) with real-time WebSocket updates
- Session detail: streamed terminal output, ANSI stripping, "jump to bottom", copy to clipboard
- Prompt queue: bottom-sheet modal, drag-to-reorder, add/remove prompts, plan preview sheet
- Conversation history: infinite-scroll list with search, conversation detail with tool_use / tool_result / diff rendering
- Settings: per-event notification preferences, quiet hours, terminal max-lines, test notification button
- WebSocket client: live updates, auto-reconnect with exponential backoff (1 s → 30 s)
- Push notifications: permission flow, platform detection, server registration, notification-tap navigation
- Zustand stores for connection, sessions, settings state; React Query for server queries
- TypeScript strict mode; NativeWind (Tailwind) dark theme

### What's incomplete / missing
- `npm install` not run; all dependencies are UNMET
- No ESLint config — linting is not enforced despite `eslint` being in devDependencies
- No Prettier config — code formatting not enforced
- No error boundary component — React render errors will crash the entire app
- No offline mode — app is non-functional when server is unreachable
- Only 1 test file (`KanbanBoard.test.tsx`) — hooks, services, stores, and most screens are untested
- Conversation history detail screen appears incomplete
- Settings screen code is truncated in the repo

---

## Action Items

### Critical
- [ ] Run `npm install` before any development or build work
- [ ] Fix bug in `useConversations` hook (line 9): `dateTo` is set twice; the first assignment should be `dateFrom`
- [ ] Add an ESLint config file (`.eslintrc.js` or `eslint.config.mjs`) — currently the dependency is installed but nothing is configured

### High
- [ ] Add a top-level React `ErrorBoundary` in `app/_layout.tsx` so render crashes don't take down the entire app
- [ ] Fix silent push-token failure in `app/_layout.tsx` line 61: `registerPushToken(...).catch(() => {})` swallows errors with no logging; at minimum log the error
- [ ] Complete the conversation detail screen (`app/conversations/[id].tsx`) — appears truncated
- [ ] Complete the settings screen (`app/settings/index.tsx`) — appears truncated past line 100
- [ ] Add Prettier config and enforce consistent formatting

### Medium
- [ ] Add tests for hooks (`useSession`, `useConversations`, `useSessionDetail`), services (`api-client`, `ws-client`), and Zustand stores
- [ ] Reduce polling frequency — `useSessionDetail` refetches every 5 s and `useSession` every 3 s; evaluate whether WebSocket pushes can replace polling entirely
- [ ] Add React Query `staleTime` to conversation list queries to avoid unnecessary refetches
- [ ] Add a README with setup instructions, environment variable documentation, and dev/build commands
- [ ] Validate `EXPO_PUBLIC_DEFAULT_SERVER_URL` at startup and show a clear error if it points to localhost in a production build

### Low
- [ ] Implement offline detection and a user-facing "disconnected" banner
- [ ] Add retry UI for failed mutations (e.g., failed prompt queue operations)
- [ ] Add accessibility testing (e.g., with `@testing-library/react-native` accessibility queries)
- [ ] Extract hardcoded color hex values (`#ff5f57`, `#febc2e`, etc.) into the theme constants file
- [ ] Replace all magic poll-interval numbers with named constants
