# Threadbase Architecture

Threadbase is structured as a local-first ecosystem around three core ideas:

1. Runtime control through `threadbase-streamer`
2. History and search through `threadbase-scanner`
3. Client surfaces across mobile, desktop, IDEs, and lightweight utilities

## Core architecture

```mermaid
flowchart TD
    Agents["Claude Code · Codex · Future Coding Agents"]
    Streamer["threadbase-streamer<br/>Local runtime bridge<br/>REST API · WebSocket · QR pairing"]
    Scanner["threadbase-scanner<br/>History index<br/>Search · Metadata · Provider awareness"]
    Mobile["threadbase-mobile<br/>iOS · Android"]
    Desktop["threadbase-electron<br/>Desktop app"]
    IDEs["IDE clients<br/>VS Code · IntelliJ"]
    Menubar["threadbase-menubar<br/>Tray/status utility"]

    Agents --> Streamer
    Agents --> Scanner
    Streamer --> Mobile
    Streamer --> Desktop
    Streamer --> IDEs
    Streamer --> Menubar
    Scanner --> Mobile
    Scanner --> Desktop
    Scanner --> IDEs
```

## Runtime and history flow

```mermaid
sequenceDiagram
    participant Agent as Claude Code / Codex
    participant Streamer as threadbase-streamer
    participant Scanner as threadbase-scanner
    participant Client as Threadbase client

    Agent->>Streamer: Session output / status
    Streamer->>Client: WebSocket events
    Client->>Streamer: Prompt / input / session action
    Streamer->>Agent: Forward control action

    Agent->>Scanner: Local history files
    Scanner->>Scanner: Index + metadata extraction
    Client->>Scanner: Search / history request
    Scanner->>Client: Normalized results
```

## Orchestration experiments

```mermaid
flowchart TD
    Request["Incoming task"]
    Workflow["Temporal workflow"]
    Worker["Worker agent"]
    Reviewer["Reviewer agent"]
    Signoff["Sign-off / coordinator"]
    Result["Durable result"]
    Client["Threadbase client"]

    Request --> Workflow
    Workflow --> Worker
    Worker --> Reviewer
    Reviewer --> Signoff
    Signoff --> Result
    Workflow --> Client
    Result --> Client
```

This layer is experimental and separate from the core streamer/mobile flow.
