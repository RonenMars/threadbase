# Supported Providers

Threadbase currently focuses on AI coding-agent workflows around:

- Claude Code
- Codex

The architecture is provider-aware and designed to support additional coding-agent providers over time.

## Provider-aware design

Provider-aware design means:

- normalized session metadata,
- provider-specific details where needed,
- shared client UI concepts,
- search/history that can span providers,
- future adapters for additional coding agents.

## Current guidance

Use provider-specific language only when behavior is truly provider-specific.

Use broader language like "AI coding agents", "coding-agent sessions", and "supported providers" for product-level capability descriptions.
