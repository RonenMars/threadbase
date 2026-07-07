# File Browser & New Session from Directory

**Date**: 2026-04-24
**Status**: Approved

## Summary

Add a file browser to the mobile app that lets users browse the server's local file system (within a configured root) and start fresh Claude Code sessions in a chosen directory.

## Approach

Flat directory listing API (one level at a time). The mobile app navigates level-by-level, similar to iOS Files. Simple, stateless, easy to secure. Can evolve to a tree view later.

## Streamer API

### Configuration — `browseRoot`

A single directory that bounds all file browsing. Resolved in priority order:

1. `THREADBASE_BROWSE_ROOT` env var
2. `browseRoot` field in `~/.threadbase/server.yaml`
3. `--browse-root` CLI flag

If none are set, browse endpoints return 403. The value is resolved via `fs.realpath()` at startup.

### New Endpoints

**`GET /api/browse?path=<relative_path>`**

- `path` is relative to `browseRoot`. Defaults to empty string (root).
- Server resolves to absolute, does `fs.realpath()`, confirms it starts with `browseRoot`.
- Returns `{ path: string, directories: Array<{ name: string }> }` — immediate subdirectories, sorted alphabetically.
- 403 if `browseRoot` not configured, 400 if path escapes root.

**`POST /api/browse/mkdir`**

- Body: `{ path: string }` — relative to `browseRoot`.
- Same path validation as browse.
- Creates a single directory (not recursive).
- Returns `{ created: string }` with relative path.
- 409 if directory exists, 400 if name is invalid.

**`POST /api/sessions/start`**

- Body: `{ path: string }` — relative to `browseRoot`.
- Same path validation as browse.
- Spawns `claude` with `cwd` set to the resolved absolute path.
- Passes `--system-prompt` with guide-rail instruction constraining Claude to stay within `browseRoot`.
- Returns same session response shape as `/api/sessions/resume`.
- Session appears in WebSocket broadcast like any managed session.

### Claude Code Guide-Rails

When spawning `claude`, the streamer passes `--system-prompt` with:

> "You are working within the project boundary: `<browseRoot>`. Do not read, write, or execute commands that access files or directories outside this boundary."

The exact wording is a constant in the streamer, easy to tune. This is soft enforcement (not OS-level sandboxing).

## Mobile App UI

### Entry Point

A `+` button in the Sessions tab header (right side). Opens a full-screen modal.

### File Browser Modal

- **Route**: `app/browse.tsx` — presented as modal via Expo Router (`presentation: "modal"`).
- **Header**: Breadcrumb trail showing current path (e.g. `~ / projects / my-app`). Tapping a segment navigates back to that level.
- **List**: FlashList of directory names with folder icon and chevron. Tapping navigates deeper.
- **Loading**: Skeleton rows while fetching.
- **Empty state**: "No subdirectories" message.
- **Error state**: 403 → message to configure `browseRoot` on the server.
- **New Folder**: Button in the modal that shows a text input. After creation, refetches the current directory.
- **Footer**: "Start Session Here" button, always visible, showing current directory name. Calls `POST /api/sessions/start`, dismisses modal, navigates to `/session/[id]`.

### Data Fetching

- `useBrowse(path)` — React Query hook calling `GET /api/browse`.
- `useCreateDirectory()` — mutation calling `POST /api/browse/mkdir`.
- `useStartSession()` — mutation calling `POST /api/sessions/start`, on success dismisses modal and pushes to session detail.

### State

Browse state (current path) is local to the modal component. No Zustand store needed.

## Security & Edge Cases

### Path Security

- All paths resolved via `fs.realpath()` before comparison against resolved `browseRoot`.
- Handles `../` traversal, symlinks, double-encoding.

### Edge Cases

| Scenario | Behavior |
|---|---|
| `browseRoot` not configured | Browse endpoints return 403 |
| `browseRoot` doesn't exist on disk | Warning at startup, 403 from endpoints |
| Permission denied on subdirectory | Skip unreadable dirs, return the rest |
| `mkdir` on existing directory | 409 Conflict |
| `mkdir` with invalid name (contains `/`) | 400 Bad Request |
| Session spawn fails (`claude` not found) | 500 with error, mobile shows alert |
| Multi-server | Each server has its own `browseRoot` and guide-rail |

## Not In Scope

- File content viewing
- Deleting directories
- Searching within the file browser
- Configuring `browseRoot` from the mobile app
- Hard OS-level sandboxing
