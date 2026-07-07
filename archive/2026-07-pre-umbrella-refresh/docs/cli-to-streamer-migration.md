---
title: "Migration: Deprecated Go CLI → Streamer Service"
date: 2026-04-24
---

# Migration: Deprecated Go CLI → Streamer Service

Completed 2026-04-24. Documents the removal of the old Go CLI (`cch`) and the activation of the streamer as a macOS launchd service.

## What changed

### 1. Removed: Go CLI binary (`cch`)

The deprecated Go CLI at `/usr/local/bin/cch` was a Mach-O arm64 binary built from `deprecated/cli/`. It was orphaned — no launchd plist referenced it, and all functionality had been replaced by `@threadbase/streamer`.

**Action taken:** `sudo rm /usr/local/bin/cch`

The source code remains in `deprecated/cli/` for historical reference.

### 2. Activated: Streamer launchd service

The plist `com.ronen.threadbase.plist` already existed (symlinked from dotfiles) and was correctly configured to run the streamer, but was not loaded.

**Action taken:** `launchctl load ~/Library/LaunchAgents/com.ronen.threadbase.plist`

## Current service configuration

| Setting | Value |
|---------|-------|
| Plist | `~/Library/LaunchAgents/com.ronen.threadbase.plist` |
| Plist source | `~/Desktop/dev/personal/mac-env-config/dotfiles/LaunchAgents/com.ronen.threadbase.plist` |
| Binary | `/usr/local/bin/threadbase-streamer` → `~/.threadbase/cli.js` |
| Command | `threadbase-streamer serve --port 8766 --api-key tb_123 --verbose` |
| Stdout log | `/tmp/threadbase.log` |
| Stderr log | `/tmp/threadbase.err` |
| RunAtLoad | `true` (starts on login) |
| KeepAlive | `true` (restarts on crash) |
| Node modules | `~/.threadbase/node_modules/` |
| Config | `~/.threadbase/server.yaml` |

## Verification

```bash
# Service is running
launchctl list | grep threadbase
# → PID  0  com.ronen.threadbase

# API responds (401 without auth, 200 with auth)
curl -s -o /dev/null -w "%{http_code}" http://localhost:8766/health
curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer tb_123" http://localhost:8766/api/sessions

# Old binary is gone
which cch  # → not found
```

## Managing the service

```bash
# Stop
launchctl unload ~/Library/LaunchAgents/com.ronen.threadbase.plist

# Start
launchctl load ~/Library/LaunchAgents/com.ronen.threadbase.plist

# Check status
launchctl list | grep threadbase

# View logs
tail -f /tmp/threadbase.log
tail -f /tmp/threadbase.err
```

## Note on port difference

The plist uses port **8766** with a hardcoded API key (`tb_123`), while the setup-new-mac doc (`threadbase-server-mac.md`) references port **3456** with an auto-generated key. The plist configuration is the authoritative one for this Mac.
