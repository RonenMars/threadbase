---
title: "Threadbase Streamer — Setup on a Second Mac"
---

# Threadbase Streamer — Setup on a Second Mac

Claude Code prompt for setting up `@threadbase/streamer` on a new Mac and exposing it via a Cloudflare tunnel.

---

## The Prompt

Copy everything between the fences and paste into Claude Code on the target Mac.

```
You are setting up the Threadbase streamer server on this Mac. The streamer is a Node.js service that scans Claude Code conversation history from ~/.claude/, serves a REST API + WebSocket, and manages PTY sessions. The mobile app connects to it over HTTP/WS.

## Step 1: Prerequisites

Check these are installed. Install anything missing via Homebrew (install Homebrew first if needed):

- **Git** (with SSH key configured for github.com — verify with `ssh -T git@github.com`)
- **Node.js >= 18** (prefer via `fnm` or `nvm` — `node --version`)
- **npm** (comes with Node)
- **cloudflared** (`brew install cloudflare/cloudflare/cloudflared`)
- **Xcode command line tools** (`xcode-select -p` — if missing: `xcode-select --install`; needed for `node-pty` native compilation)

## Step 2: Clone the monorepo

First check if it's already cloned:

```bash
ls ~/Desktop/dev/personal/threadbase/.git 2>/dev/null && echo "ALREADY CLONED" || echo "NOT FOUND"
```

**If ALREADY CLONED:** `cd ~/Desktop/dev/personal/threadbase` and pull latest:
```bash
cd ~/Desktop/dev/personal/threadbase
git pull --recurse-submodules
```

**If NOT FOUND:** clone fresh:
```bash
cd ~/Desktop/dev/personal
git clone --recurse-submodules git@github.com:RonenMars/threadbase.git
cd threadbase
```

We only need the `scanner` and `streamer` submodules, but cloning all is fine.

## Step 3: Validate submodule commits

For each submodule, compare the checked-out commit against the latest on `main` at its remote. Run this from the threadbase root:

```bash
for sub in cli core electron intellij mobile scanner streamer ui vscode; do
  LOCAL=$(git -C "$sub" rev-parse HEAD 2>/dev/null | cut -c1-7)
  REMOTE=$(git -C "$sub" ls-remote origin HEAD 2>/dev/null | cut -c1-7)
  if [ "$LOCAL" = "$REMOTE" ]; then
    echo "$sub: $LOCAL (up to date)"
  else
    echo "$sub: LOCAL=$LOCAL REMOTE=$REMOTE (BEHIND)"
  fi
done
```

If any submodule shows **BEHIND**, ask me: "The following submodules are behind their remote: [list]. Would you like to pull the latest, or proceed with the current commits?"

If I say pull, run:
```bash
git submodule update --remote --merge
```

If I say proceed, continue with the current commits.

## Step 4: Install and build (scanner + streamer)

The streamer depends on scanner as a local file dependency. Install both:

```bash
cd scanner && npm install && cd ..
cd streamer && npm install && npm run build && cd ..
```

Verify the CLI binary was built:
```bash
node streamer/dist/cli.js serve --help
```

## Step 5: Start the streamer

First check if it's already running or has an existing config:

```bash
echo "--- existing config ---"
cat ~/.threadbase/server.yaml 2>/dev/null || echo "No config yet"
echo "--- running process ---"
pgrep -f "threadbase-streamer\|dist/cli.js serve" >/dev/null && echo "ALREADY RUNNING" || echo "NOT RUNNING"
echo "--- launchd service ---"
launchctl list 2>/dev/null | grep threadbase && echo "LAUNCHD SERVICE EXISTS" || echo "No launchd service"
```

**If ALREADY RUNNING:** The streamer is already active. Show me its config (`cat ~/.threadbase/server.yaml`) and skip to Step 6 to verify.

**If NOT RUNNING but config exists:** An API key was already generated. Start the streamer — it will reuse the existing key:

```bash
cd streamer
node dist/cli.js serve --port 3456
```

**If neither exists (fresh setup):**

```bash
cd streamer
node dist/cli.js serve --port 3456
```

On first run it auto-generates `~/.threadbase/server.yaml` with a random API key (`tb_<hex>`).
The server prints the API key to stdout. Save it — the mobile app needs it.

The server exposes:
- REST API at http://localhost:3456
- WebSocket at ws://localhost:3456/ws

## Step 6: Verify it works

In another terminal:

```bash
curl http://localhost:3456/sessions -H "Authorization: Bearer $(grep api_key ~/.threadbase/server.yaml | awk '{print $2}')"
```

Should return a JSON array of sessions (or `[]` if `~/.claude/` has no conversations yet).

## Step 7: Set up Cloudflare tunnel

We use Cloudflare Tunnels to expose the streamer to the internet (for mobile app access outside LAN). This follows the same pattern as the PC remote setup on rbv1000.win.

**Before creating anything, check what already exists on this Mac:**

```bash
echo "--- cloudflared auth ---"
ls ~/.cloudflared/cert.pem 2>/dev/null && echo "AUTHENTICATED" || echo "NOT AUTHENTICATED"
echo "--- existing tunnels ---"
cloudflared tunnel list 2>/dev/null || echo "Cannot list (not authenticated)"
echo "--- existing config ---"
cat ~/.cloudflared/config.yml 2>/dev/null || echo "No config.yml"
echo "--- existing launchd ---"
launchctl list 2>/dev/null | grep -i cloudflare && echo "CLOUDFLARE LAUNCHD EXISTS" || echo "No cloudflare launchd service"
```

Show me the output of the above and follow the appropriate path:

---

### Path A: Existing tunnel found

If `cloudflared tunnel list` shows a tunnel and `~/.cloudflared/config.yml` exists:

1. Show me the full output of `cloudflared tunnel list` and `cat ~/.cloudflared/config.yml`
2. Ask me: "Found existing tunnel(s) and config. The config routes to [hostname(s)]. Is this the correct tunnel to use for threadbase, or should I create a new one?"
3. **If I say use it:** check that the config has an ingress entry routing to `http://localhost:3456`. If it routes to a different port, ask me which port to use. If the ingress is correct, skip to 7e to test.
4. **If I say create new:** proceed to 7b below.

### Path B: Authenticated but no tunnel

If `cert.pem` exists but `cloudflared tunnel list` is empty — skip 7a, go to 7b.

### Path C: Fresh setup (not authenticated)

Follow all steps below in order.

---

### 7a. Authenticate cloudflared

Skip if already authenticated (`~/.cloudflared/cert.pem` exists).

```bash
cloudflared tunnel login
```

This opens a browser to authorize. Select the Cloudflare zone you want to use (e.g. `rbv1000.win`).

### 7b. Create the tunnel

```bash
cloudflared tunnel create threadbase-mac
```

Save the tunnel UUID from the output. Credentials are stored at `~/.cloudflared/<tunnel-uuid>.json`.

### 7c. Add DNS route

```bash
cloudflared tunnel route dns <tunnel-uuid> threadbase-mac.rbv1000.win
```

Replace `rbv1000.win` with your actual Cloudflare zone if different.

### 7d. Create tunnel config

Check if `~/.cloudflared/config.yml` already exists:

```bash
cat ~/.cloudflared/config.yml 2>/dev/null || echo "NO EXISTING CONFIG"
```

**If a config exists** with other ingress rules (other services on this Mac): add the threadbase entry to the existing ingress list rather than overwriting it. Show me the current config and ask: "There's an existing config with [N] ingress rules. Should I add the threadbase entry to it, or replace it entirely?"

**If no config exists**, write `~/.cloudflared/config.yml`:

```yaml
tunnel: <tunnel-uuid>
credentials-file: /Users/<username>/.cloudflared/<tunnel-uuid>.json

ingress:
  - hostname: threadbase-mac.rbv1000.win
    service: http://localhost:3456
  - service: http_status:404
```

Replace `<tunnel-uuid>` and `<username>` with actual values.

### 7e. Test the tunnel

```bash
cloudflared tunnel run
```

From another device, verify:
```bash
curl https://threadbase-mac.rbv1000.win/sessions -H "Authorization: Bearer <api-key>"
```

### 7f. Run as a launchd service (auto-start on boot)

Check if a cloudflare launchd service already exists:

```bash
ls ~/Library/LaunchAgents/com.cloudflare.* 2>/dev/null && echo "PLIST EXISTS" || echo "NO PLIST"
launchctl list 2>/dev/null | grep cloudflare
```

**If a cloudflare plist already exists and is loaded:** the tunnel is already running as a service. Verify it uses the correct config:
```bash
cat ~/Library/LaunchAgents/com.cloudflare.*.plist
```
Show me the output. If it's already pointing at the right tunnel, skip creating a new plist.

**If no plist exists**, create `~/Library/LaunchAgents/com.cloudflare.threadbase-tunnel.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.cloudflare.threadbase-tunnel</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/cloudflared</string>
        <string>tunnel</string>
        <string>run</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/cloudflared-threadbase.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/cloudflared-threadbase.log</string>
</dict>
</plist>
```

Load it:
```bash
launchctl load ~/Library/LaunchAgents/com.cloudflare.threadbase-tunnel.plist
```

Also check if a streamer launchd service already exists:

```bash
ls ~/Library/LaunchAgents/com.threadbase.* 2>/dev/null && echo "PLIST EXISTS" || echo "NO PLIST"
launchctl list 2>/dev/null | grep threadbase
```

**If it already exists and is loaded**, show me its contents. If it points to the correct working directory and node path, skip creating a new one.

**If no plist exists**, create `~/Library/LaunchAgents/com.threadbase.streamer.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.threadbase.streamer</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/node</string>
        <string>dist/cli.js</string>
        <string>serve</string>
        <string>--port</string>
        <string>3456</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Users/REPLACE_USERNAME/Desktop/dev/personal/threadbase/streamer</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/threadbase-streamer.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/threadbase-streamer.log</string>
</dict>
</plist>
```

Replace REPLACE_USERNAME with the actual macOS username. Also verify the node path (`which node`).

Load it:
```bash
launchctl load ~/Library/LaunchAgents/com.threadbase.streamer.plist
```

## Step 8: Confirm

Show me:
1. Output of `curl http://localhost:3456/sessions` (with auth header)
2. Output of `cloudflared tunnel info threadbase-mac`
3. Output of `curl https://threadbase-mac.rbv1000.win/sessions` (with auth header)
4. The API key from `~/.threadbase/server.yaml`

## Mobile app configuration

The mobile app `.env` needs:
```
EXPO_PUBLIC_DEFAULT_SERVER_URL=https://threadbase-mac.rbv1000.win
EXPO_PUBLIC_DEFAULT_API_KEY=<key from ~/.threadbase/server.yaml>
```

For LAN-only access (no tunnel), use `http://<this-mac-ip>:3456` instead.

## Notes

- The streamer reads conversation history from `~/.claude/` JSONL files. If there are no conversations on this Mac yet, the API returns empty results — that's fine.
- No database needed. Everything is in-memory scanning of the JSONL files via `@threadbase/scanner`.
- The `node-pty` dependency requires native compilation — if `npm install` fails on it, ensure Xcode command line tools are installed: `xcode-select --install`.
- API key is stored at `~/.threadbase/server.yaml` and auto-generated on first run.
- Default port is 3456. Change with `--port <number>`.
```

---

## Streamer CLI flags reference

| Flag | Default | Purpose |
|------|---------|---------|
| `--port, -p` | `3456` | Port to listen on |
| `--api-key` | auto-generated | Override the API key |
| `--local-no-auth` | `false` | Skip auth for localhost requests |
| `-v, --verbose` | `false` | Verbose output |

## Config file

`~/.threadbase/server.yaml` — auto-created on first `serve` run:

```yaml
api_key: tb_<hex32>
```
