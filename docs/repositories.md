# Repository Map

This repository is the project hub for Threadbase. It does not vendor or submodule component repositories. Each component lives in its own repository and is linked below.

This document maps the main `threadbase-*` repositories and explains how they fit into the Threadbase ecosystem.

## Active repositories

| Repository | Purpose | Status |
|---|---|---|
| [`threadbase-streamer`](https://github.com/RonenMars/threadbase-streamer) | Local runtime, REST API, WebSocket streaming, QR pairing, session control | Active |
| [`threadbase-scanner`](https://github.com/RonenMars/threadbase-scanner) | Local conversation indexing, search, provider metadata | Active |
| [`threadbase-mobile`](https://github.com/RonenMars/threadbase-mobile) | iOS/Android client for monitoring and controlling sessions | Active beta |
| [`threadbase-electron`](https://github.com/RonenMars/threadbase-electron) | Desktop app for browsing, searching, and interacting with sessions | Active / evolving |
| [`threadbase-vscode`](https://github.com/RonenMars/threadbase-vscode) | VS Code extension for browsing and searching coding-agent history | Active |
| [`threadbase-intellij`](https://github.com/RonenMars/threadbase-intellij) | JetBrains plugin for browsing and searching coding-agent history | Active |
| [`threadbase-menubar`](https://github.com/RonenMars/threadbase-menubar) | Tray/menubar status indicator for Threadbase Streamer | Active / lightweight |

## Shared packages

| Repository | Purpose | Status |
|---|---|---|
| [`threadbase-core`](https://github.com/RonenMars/threadbase-core) | Shared TypeScript types and provider abstractions | Internal shared package |
| [`threadbase-ui`](https://github.com/RonenMars/threadbase-ui) | Shared React UI components for Threadbase clients | Internal shared package |
| [`threadbase-agent-types`](https://github.com/RonenMars/threadbase-agent-types) | Shared agent/provider type definitions | Active / internal |

## Experimental repositories

| Repository | Purpose | Status |
|---|---|---|
| [`threadbase-multi-agent-orchestration`](https://github.com/RonenMars/threadbase-multi-agent-orchestration) | Durable multi-agent workflow experiments | Experimental |

## Distribution repositories

| Repository | Purpose | Status |
|---|---|---|
| [`homebrew-threadbase`](https://github.com/RonenMars/homebrew-threadbase) | Homebrew tap for installing Threadbase packages | Distribution |

## Historical repositories

| Repository | Purpose | Status |
|---|---|---|
| `threadbase-cli` | Original CLI prototype for searching and resuming coding-agent history | Deprecated / archived |

`threadbase-cli` is historical and has been superseded by the current streamer/scanner/client ecosystem.
