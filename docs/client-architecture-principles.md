# Client Architecture Principles

Threadbase clients should preserve a clean boundary:

```text
domain logic → platform adapter → UI
```

Domain logic should avoid direct imports from specific runtimes such as Electron, VS Code, IntelliJ, or React Native whenever practical.

## Why this matters

This boundary keeps core behavior portable, testable, and easier to share across clients.

Domain logic should stay platform-agnostic. Platform adapters translate runtime-specific APIs into domain operations. UI layers render state and forward user intent.

## Where this applies

This principle is especially relevant for:

- Electron,
- VS Code,
- IntelliJ,
- shared packages (`threadbase-core`, `threadbase-scanner`, `threadbase-ui`),
- future clients.

## Practical guidance

- Keep parsing, indexing, filtering, and export logic in shared/domain layers when possible.
- Isolate IPC, extension APIs, Swing/JCEF bridges, and mobile runtime APIs in adapters.
- Test domain logic without booting a full client shell when practical.
- Avoid leaking UI concerns into domain models.
