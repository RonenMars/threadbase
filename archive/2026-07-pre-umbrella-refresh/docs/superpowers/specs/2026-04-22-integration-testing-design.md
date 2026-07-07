# Design: Integration & Contract Testing

**Date:** 2026-04-22
**Status:** Draft
**Scope:** scanner, streamer, mobile, electron

---

## Problem

No test in the Threadbase monorepo verifies the actual contract between a client (mobile, electron) and the running streamer server. Every app mocks its server boundary. The streamer tests exercise real HTTP but use whatever scanner returns from the real `~/.claude` directory — no controlled fixtures.

When the streamer API response shape changes, there is no automated way to know if mobile or electron will break.

## Goals

1. **Contract confidence** — When the streamer API response shape changes, tests fail immediately for the affected consumer (mobile, desktop, or both).
2. **End-to-end flow verification** — A real streamer server starts with deterministic fixture data, receives real HTTP requests, and returns responses validated against consumer schemas.
3. **Live format drift detection** — Detect when Anthropic changes the JSONL format Claude Code writes, before it breaks the pipeline.

## Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Fixture location | `scanner/__fixtures__/` | Scanner already owns the JSONL format and has 5 fixture files. Streamer references via relative path. |
| Contract approach | Consumer-driven with JSON Schema | Each consumer defines its expected response shapes. JSON Schema is language-agnostic (mobile uses Jest, streamer uses Vitest). |
| Schema location | `streamer/contracts/` | Streamer owns the transformation layer that maps scanner output to consumer-expected shapes. |
| Schema update UX | Explicit update scripts (Playwright snapshot pattern) | `npm run update-schema --mobile/--desktop/--shared`. Prevents silent drift — format changes require conscious acceptance. |
| E2E scope | HTTP-level in streamer (no mobile app runtime) | Proves the full pipeline JSONL → scanner → streamer → HTTP. Mobile runtime specifics (React Query, hooks) already covered by mobile's own tests. |
| Live drift capture | `claude --print` + manual script + weekly CI | Low-frequency check. Anthropic rarely changes JSONL format. Manual for ad-hoc, weekly CI for passive monitoring. |
| Initial consumer focus | Mobile-only (desktop follow-up) | Mobile is the active HTTP consumer post-migration. Electron calls the same endpoints — coverage transfers. |

## Architecture

```
Tier 1: Contract Tests
───────────────────────
scanner/__fixtures__/*.jsonl
        │
        ▼
streamer test suite:
  1. scan() pointed at fixtures
  2. Response passed through API adaptation layer
  3. Validated against JSON Schema
        │
        ▼
streamer/contracts/
  shared.schema.json
  mobile.schema.json
  desktop.schema.json

Tier 2A: HTTP E2E Tests
───────────────────────
Real StreamerServer on random port
        │
  fetch() calls to all endpoints
        │
  Responses validated against same contract schemas

Tier 2B: Live Format Drift
───────────────────────
claude --print "test prompt"
        │
  Resulting JSONL parsed by scanner
        │
  Diffed against baseline-live.jsonl
        │
  Weekly CI job opens issue on drift
```

## Out of Scope

- Mobile app E2E against real streamer (needs Expo test environment)
- Electron transport tests against real streamer (when electron migrates off `cch`)
- VS Code / IntelliJ (use scanner directly, no HTTP boundary)
- `@threadbase/ui` component tests (separate concern)
