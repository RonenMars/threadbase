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
  <a href="https://threadbase.sh/betas"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/assets/badge-ios-dark.svg"><img alt="iOS: beta on TestFlight" src="docs/assets/badge-ios-light.svg" width="176" height="48"></picture></a>&nbsp;&nbsp;
  <a href="https://threadbase.sh/betas"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/assets/badge-android-dark.svg"><img alt="Android: closed testing on Google Play" src="docs/assets/badge-android-light.svg" width="176" height="48"></picture></a>
</p>

<p align="center">
  <a href="https://www.npmjs.com/package/@threadbase-sh/streamer"><img alt="streamer version on npm" src="https://img.shields.io/npm/v/%40threadbase-sh%2Fstreamer?logo=npm&logoColor=white&label=streamer&labelColor=0f1620&color=1f2d3d"></a>
  <a href="LICENSE"><img alt="MIT license" src="https://img.shields.io/github/license/RonenMars/threadbase?labelColor=0f1620&color=1f2d3d"></a>
</p>

## Why

You start a long agent run. Twenty minutes in, it stops: *"Allow this edit?"* You find out an hour later, back at the desk.

Agents work asynchronously. Your terminal does not.

## What you get

1. **A push the moment the agent needs you.** No stream to babysit.
2. **Approvals and questions as cards.** Tap the answer on your phone. The agent keeps going.
3. **A prompt queue.** Type or dictate the next three prompts while it works. It picks them up in order.
4. **Start or take over from anywhere.** Launch a session on any paired machine, or adopt one you started in your terminal.
5. **Search across every session on every machine.** Find the conversation where the agent explained that migration.

## Get started in a minute

```bash
npm install -g @threadbase-sh/streamer   # or: brew tap RonenMars/threadbase && brew install tb-streamer
tb-streamer serve                        # then open the app, tap Pair, scan the QR
```

Get the app at [threadbase.sh/betas](https://threadbase.sh/betas). Full setup, Linux and Windows notes: [threadbase.sh/docs](https://threadbase.sh/docs).

## Your sessions stay yours

By default the phone talks straight to the streamer on your machine. No Threadbase server in between, no analytics.
Traffic is end-to-end encrypted with per-device credentials you can revoke at any time, and all of it is open source under MIT.

Beta, honestly: iOS ships through TestFlight and Android through closed testing, reaching your streamer from outside your network is on you, and multi-select prompts still fall back to the terminal.
Details: [threadbase.sh/privacy](https://threadbase.sh/privacy) · [`docs/privacy-and-security.md`](docs/privacy-and-security.md)

## The pieces

This repository is the project hub. The code lives in the component repos.

| | Repository | What it is |
|---|---|---|
| 📱 | [`threadbase-mobile`](https://github.com/RonenMars/threadbase-mobile) | The iOS and Android app |
| 🖥️ | [`threadbase-streamer`](https://github.com/RonenMars/threadbase-streamer) | The local runtime you install next to your agents |
| 🔍 | [`threadbase-scanner`](https://github.com/RonenMars/threadbase-scanner) | Local indexing and search of your session history |
| 🌐 | [`threadbase-website`](https://github.com/RonenMars/threadbase-website) | threadbase.sh, docs and privacy policy |
| 🧩 | [Desktop and IDE clients](docs/repositories.md) | Electron, VS Code, IntelliJ and menubar |

Architecture, roadmap and the full repository map: [`docs/`](docs/README.md). Contributions: [`CONTRIBUTING.md`](CONTRIBUTING.md). Security issues, privately: [`SECURITY.md`](SECURITY.md).

---

<p align="center">
  MIT licensed. Threadbase is a trademark of Ronen Mars, see <a href="TRADEMARK.md">TRADEMARK.md</a>.
</p>
