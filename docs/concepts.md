# Core Concepts

## Streamer

The streamer is the local runtime bridge between Threadbase clients and AI coding agents.

`threadbase-streamer` runs next to your coding agents and exposes APIs for:

- session control,
- terminal/session streaming,
- WebSocket events,
- QR pairing,
- API-key authenticated access,
- mobile connectivity.

## Scanner

The scanner is the local indexing and search layer for coding-agent conversation history.

`threadbase-scanner` indexes local provider histories, extracts metadata, and enables search across sessions.

## Clients

Threadbase clients provide different surfaces for the same underlying workflows:

- mobile,
- desktop,
- VS Code,
- IntelliJ,
- menubar.

## Providers

Threadbase currently focuses on:

- Claude Code
- Codex

Provider support may vary by repository and client.

## Orchestration

Threadbase is exploring durable multi-agent workflows where tasks can move through worker, reviewer, and sign-off stages.
