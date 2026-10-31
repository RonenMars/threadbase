<p align="center">
  <img src="docs/assets/readme-hero.webp" alt="An empty desk at dusk with a coding agent still running on the screens; a glowing thread carries session cards out of the window, through a padlock, across a lake to a developer holding a phone on a dock" width="720">
</p>

<h1 align="center">Threadbase</h1>

<p align="center"><strong>Leave the desk. Keep the agent working.</strong></p>

<p align="center">
  Claude Code, Codex and GitHub Copilot run on your machine.<br>
  Threadbase puts them on your phone: see what the agent is doing, answer when it asks, queue the next prompt.<br>
  End-to-end encrypted between your phone and your machines. Threadbase can't read your sessions.
</p>

<p align="center">
  <a href="https://threadbase.sh/betas"><strong>Get the app</strong></a> ·
  <a href="https://threadbase.sh/docs">Docs</a> ·
  <a href="https://threadbase.sh">threadbase.sh</a>
</p>

<p align="center">
  <img alt="iOS TestFlight beta" src="https://img.shields.io/badge/iOS-TestFlight_beta-black">
  <img alt="Android closed testing" src="https://img.shields.io/badge/Android-closed_testing-black">
  <img alt="Streamer for macOS, Linux and Windows" src="https://img.shields.io/badge/streamer-macOS_·_Linux_·_Windows-black">
  <img alt="MIT license" src="https://img.shields.io/badge/license-MIT-black">
</p>

---

## The problem

You start a long agent run. Twenty minutes in, it stops: *"Allow this edit?"* You find out an hour later, when you walk back to the desk.

Agents work asynchronously. Your terminal does not.

## What Threadbase does

- **Pings you the moment the agent needs you.** A push notification when the session stops for input, not a stream you have to babysit.
- **Approvals as cards, not a tiny terminal.** Permission prompts and questions arrive on your phone. Tap the answer. The agent keeps going.
- **Keeps the agent fed.** Queue the next three prompts while it works. Dictate them. Attach a screenshot. It picks them up in order.
- **Start from your phone, or take over.** Browse a machine's projects and launch a new session, or adopt one you started in your terminal.
- **Search everything.** Full-text search across every session on every machine. Find the conversation where the agent explained that migration.
- **Every machine, one app.** Pair your Mac, your Linux box and your Windows PC. Each phone gets its own revocable credentials.

## How it works

```
 your machine                              your phone
┌────────────────────────┐    E2E encrypted    ┌──────────────────┐
│ Claude Code / Codex /  │ ◄─────────────────► │  Threadbase app  │
│ Copilot                │                     │                  │
│   ▲                    │                     │  approve · queue │
│   └─ tb-streamer       │                     │  search · start  │
└────────────────────────┘                     └──────────────────┘
          no Threadbase server in between by default
```

1. **Install the streamer** on any machine that runs your agents. One binary.
2. **Pair your phone** by scanning the QR code the streamer prints. Keys are exchanged right there.
3. **Leave.** Threadbase pushes you when the agent needs you.

## Get started in a minute

```bash
# 1. Install the streamer
npm install -g @threadbase-sh/streamer
# or: brew tap RonenMars/threadbase && brew install tb-streamer

# 2. Start it
tb-streamer serve

# 3. Open the Threadbase app, tap Pair, scan the QR in your terminal
```

Get the app at [threadbase.sh/betas](https://threadbase.sh/betas). Full setup, Linux and Windows notes: [threadbase.sh/docs](https://threadbase.sh/docs).

## Your sessions stay yours

By default the phone talks straight to the streamer on your machine. No Threadbase server sits in between, and there are no analytics.
Traffic is end-to-end encrypted with per-device credentials you can revoke from the streamer at any time.
Everything is open source under MIT, so you can read exactly what runs.

Details: [threadbase.sh/privacy](https://threadbase.sh/privacy) · [`docs/privacy-and-security.md`](docs/privacy-and-security.md)

## Beta, honestly

- **Distribution is beta.** iOS ships through TestFlight, Android through closed testing on Google Play.
- **You run the streamer.** Reaching it from outside your network is on you. A Cloudflare quick-tunnel helper is included, a guided setup is not yet.
- **Some prompts still need the terminal.** Single-choice approvals and questions work from the phone. Multi-select forms fall back to the raw terminal for now.
- **Providers differ.** Claude Code, Codex and GitHub Copilot are all supported, but approvals, recovery and resume behavior vary by provider.

## The pieces

This repository is the project hub. The code lives in the component repos.

| | Repository | What it is |
|---|---|---|
| 📱 | [`threadbase-mobile`](https://github.com/RonenMars/threadbase-mobile) | The iOS and Android app |
| 🖥️ | [`threadbase-streamer`](https://github.com/RonenMars/threadbase-streamer) | The local runtime you install next to your agents |
| 🔍 | [`threadbase-scanner`](https://github.com/RonenMars/threadbase-scanner) | Local indexing and search of your session history |
| 🌐 | [`threadbase-website`](https://github.com/RonenMars/threadbase-website) | threadbase.sh, docs and privacy policy |
| 🧩 | [Desktop and IDE clients](docs/repositories.md) | Electron, VS Code, IntelliJ and menubar |

Architecture, concepts, roadmap and the full repository map: [`docs/`](docs/README.md).

## Contributing and security

Contributions welcome, see [`CONTRIBUTING.md`](CONTRIBUTING.md). Implementation issues belong in the component repo.
Threadbase controls live coding-agent sessions, so please report security issues privately: [`SECURITY.md`](SECURITY.md).

---

<p align="center">
  MIT licensed. Threadbase is a trademark of Ronen Mars, see <a href="TRADEMARK.md">TRADEMARK.md</a>.
</p>
