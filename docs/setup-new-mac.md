# Threadbase — New Mac Setup Prompt

Copy the prompt below and paste it into a Claude Code session on the target Mac.

---

## Prompt

```
I need you to set up the Threadbase development environment on this Mac. Threadbase is a cross-platform suite for browsing Claude Code conversation history — it has an Electron app, VS Code extension, IntelliJ plugin, Go CLI, mobile app (Expo), and shared npm packages, all managed as git submodules under one umbrella repo.

## Step 1: Prerequisites

Check which of these are already installed. Install anything missing via Homebrew (install Homebrew first if needed):

- **Git** (with SSH key configured for github.com — verify with `ssh -T git@github.com`)
- **Node.js >= 18** (prefer via `fnm` or `nvm`)
- **npm** (comes with Node)
- **pnpm** (needed for the Electron app — `npm install -g pnpm`)
- **Go >= 1.26** (`brew install go`)
- **JDK 17+** (needed for IntelliJ plugin — `brew install openjdk@17`)
- **Gradle** (optional — the IntelliJ plugin uses the wrapper `./gradlew`)
- **Expo CLI** (for mobile — `npm install -g expo-cli` and `npm install -g eas-cli`)

Don't install Xcode or Android Studio unless I ask — mobile builds go through EAS Build.

## Step 2: Clone the Monorepo

```bash
cd ~/Desktop/dev/personal   # or wherever the user keeps projects
git clone --recurse-submodules git@github.com:RonenMars/threadbase.git
cd threadbase
```

Verify all submodules checked out:
```bash
git submodule status
```

Expected submodules: cli, core, electron, intellij, mobile, scanner, streamer, ui, vscode.

## Step 3: Install Dependencies (per submodule)

Run these in parallel where possible. Each submodule is independent.

**Shared packages (npm):**
```bash
cd scanner && npm install && cd ..
cd core && npm install && cd ..
cd ui && npm install && cd ..
cd streamer && npm install && cd ..
```

**Electron app (pnpm):**
```bash
cd electron && pnpm install && cd ..
```

**VS Code extension (npm):**
```bash
cd vscode && npm install && cd ..
```

**Mobile app (npm):**
```bash
cd mobile && npm install && cd ..
```

**Go CLI:**
```bash
cd cli && go build -o cch ./cmd/cch && cd ..
```

**IntelliJ plugin (Gradle):**
```bash
cd intellij && ./gradlew build && cd ..
```

## Step 4: Verify Each App Starts

Run a quick smoke test for each:

1. **Scanner:** `cd scanner && npm test`
2. **Streamer:** `cd streamer && npm test` (or `npm run dev` to start the REST server)
3. **Electron:** `cd electron && pnpm run dev` — should open a desktop window
4. **VS Code:** `cd vscode && npm run build` — then open in VS Code and press F5
5. **CLI:** `cd cli && ./cch list` — should show conversations from `~/.claude/`
6. **IntelliJ:** `cd intellij && ./gradlew runIde` — should launch a sandboxed IDE
7. **Mobile:** `cd mobile && npx expo start` — should show the Expo dev server QR code

## Step 5: Confirm

After setup, run `git submodule status` from the root and show me the output.

## Notes

- There are no .env files to configure for local dev — the apps read directly from `~/.claude/` JSONL files.
- The `cli/` submodule is deprecated (replaced by `streamer/`) but still builds and works.
- The monorepo root has docs and coordination files only — no build step needed at root level.
- Conventional commits are used throughout: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:` with optional scope.
```
