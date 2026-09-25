# Open issues closure audit

Audited 2026-08-11 against freshly fetched `origin/main` at
`68aa91b232ea12b473c4401828832ab221b762ec`.

All 41 open issues were reviewed. No issues were modified, commented on, or
closed. Only two closures have strong enough evidence: #498 and #514.

## Report

| # | Title | Verdict | Category | Evidence |
|---|-------|---------|----------|----------|
| 498 | P2: the release job leaves package-lock.json's root version stale | close | Fixed | High — PR #525 merged as `1d54d9be036bd34ecb9d3255ff750b9451d8fc26`; `git merge-base --is-ancestor … origin/main` exited 0. `.releaserc.json:27-30` now commits `package-lock.json`, and both package files currently report `1.47.2`. |
| 514 | P3: latent torn-line gap in the conversation watcher | close | Fixed | High — `conversationWatcher.ts:259-266` advances only through the last newline. `conversation-watcher.test.ts:133-152` verifies a partial line is held and later emitted whole. Focused run: **1 file, 14 tests passed**. |
| 480 | P2: no install path provisions APNs credentials for self-hosted Live Activity push | rewrite | — | High — provisioning remains absent and sandbox remains the default at `apnsClient.ts:100-113`. However, the claim that setup is undocumented is stale: `docs/guides/live-activity-push.md:25-65` documents credentials and manual installation. |
| 481 | P2: APNs key and .env loading are launchd-only, so self-hosted Windows and Linux cannot enable push | keep | — | High — `loadApnsKeyIntoEnv` still has its only call at `cli/launchd-entry.ts:238`; Linux/Windows launch paths contain no equivalent loader. |
| 483 | P1: boot auto-resume spends a slot on sessions that have no provider history | keep | — | High — `autoResumeOnBoot.ts:16-38` still has no history predicate or `history_missing` skip reason. |
| 485 | P2: re-land or formally accept the three hardening fixes reverted by #220 | needs-decision | — | High — `progress.routes.ts:64-69` still accepts a missing timestamp; `server.ts:1172-1227` still applies subscribe/hold by supplied session ID. Decision required: re-land versus formally accept each risk. |
| 486 | P2: log the 401 decision in the auth middleware | keep | — | High — `auth.middleware.ts:28-112` still returns 401/403 without logging. |
| 487 | P2: log PTY exit with code, elapsed time and failureReason | keep | — | High — `pty-manager.ts:1199-1234` computes all three values but emits no exit log. |
| 488 | P2: log WebSocket connect/disconnect and subscriber count | keep | — | High — `ws-hub.ts:15-47` changes connection state without logs; send/terminate failures remain silent at lines 49-125. |
| 489 | P2: log unhandled errors before returning a 500 | keep | — | High — `error.middleware.ts:4-7` still returns the error message with no server log. |
| 490 | P2: the updater has no structured logging at all | keep | — | High — `git grep` found no logger calls under `src/updater`; silent catches remain in `install.ts`, `restart.ts`, and `swap.ts`. |
| 491 | P2: log subscribe_session so an empty terminal is diagnosable | keep | — | High — `server.ts:1172-1224` handles subscription without logging receipt. The existing logs cover only permission/question replay. |
| 492 | P2: emit a ring-buffer pressure event when PTY output is trimmed | keep | — | High — `pty-manager.ts:820-826` trims the buffer without an event or dropped-byte count. |
| 493 | P2: close the remaining observability gaps catalogued in the audit | keep | — | High — representative gaps remain: silent auth/error middleware, silent WebSocket catches, and no updater logging. |
| 494 | P2: split src/server.ts along the existing ApiDeps seams | keep | — | High — current `src/server.ts` is still exactly 6,502 lines and `src/api/handlers/` does not exist. |
| 495 | P2: replace the flaky-file list in CLAUDE.md with the failure-signature rule | rewrite | — | High — `CLAUDE.md:329-334` still lacks failure-signature guidance, but there is no current flaky-file list to “replace.” Rewrite as an additive documentation task and fix the duplicate type labels. |
| 497 | P2: prune three redundant refs from origin | keep | — | High — all three named remote refs remain after `git fetch --prune`; the requested backup ref also remains. |
| 499 | P3: structured prompt cards for Codex sessions | keep | — | High — `capabilities.ts:91-110` still declares Codex `structuredQuestions: false`; only startup and usage-limit gates are detected. |
| 500 | P3: move the API key to the OS keychain | keep | — | High — no keychain/keytar/Credential Manager/libsecret integration exists; README still documents plaintext `server.yaml`. |
| 501 | P3: make warm-up delta-only, starting with logging which mode ran | keep | — | High — `server.ts:2281-2321` still selects an in-memory or persistent scanner without logging mode/duration and passes the full metadata set to `upsertFromScannerMeta`. |
| 502 | P3: accept HTTP QUERY on /api/search alongside GET | keep | — | High — only `app.get("/api/search", …)` exists at `scanner.routes.ts:11`. |
| 503 | P3: forward the three unmapped scanner message fields when a consumer needs them | keep | — | High — no `sourceToolAssistantUUID`, `stop_hook_summary`, or `bridge_status` mapping exists; `server.ts:4184` still forwards only `has_images`. |
| 504 | P3: normalize Commander boolean option parsing in prod logs | keep | — | High — `cli/prod.ts:368-375` still uses `!== false` and `=== true`. |
| 505 | P3: bounded page reads for large conversations | rewrite | — | High — the blocker is obsolete: scanner `v0.12.3` exposes bounded `getConversationPage`. The streamer still deliberately avoids it at `server.ts:4125`, so implementation remains real but the “blocked on scanner release” section should be removed. |
| 506 | P3: session source visibility and control (S1-S6) | keep | — | High — process discovery still returns only basic PID/path/start fields (`process-discovery.ts:78-105`); no `SessionSource`, `remoteControlled`, or ownership filtering exists. |
| 507 | P3: live-activity — no push-to-start send path | needs-decision | — | High — `liveActivityRenewal.ts:232-248` uses push-to-start only for replacement activities. Decision required: should an initial activity appear for work the app never foregrounded? |
| 509 | P3: live-activity — no delivery metrics and no push_tokens retention | keep | — | High — individual sends are logged, but no aggregate started/renewed/ended/retired metrics or dead-row retention policy exists. |
| 510 | P3: decide whether THREADBASE_INSTANCE_ID is stable enough to be serverId | needs-decision | — | High — hostname remains the fallback at `db/config.ts:14-16` and `server.ts:1423-1426`. Decision required: accept hostname identity or introduce persisted identity plus migration. |
| 511 | P3: GET /api/profiles is a stub that always returns [] | keep | — | High — `misc.routes.ts:104` remains exactly `app.get("/api/profiles", (c) => c.json([]))`. |
| 512 | P3: the nightly restart kills every live PTY at 04:00 | needs-decision | — | High — live `launchctl` state confirms the loaded job runs `kickstart -k` at 04:00 and last exited 0. Decision required: retain, reschedule, or redesign continuity. |
| 513 | P3: test-isolation hardening — ABI guard, scanner DB isolation, drain convention | rewrite | — | High — scanner `0.12.3` now dedupes onto `better-sqlite3@12`, making the nested-copy premise obsolete. The guard still checks only the root binary (`check-native-abi.mjs:23-38`), and the shared isolation/drain work remains absent. |
| 515 | P3: idle-session push notifications | rewrite | — | High — the body incorrectly says an Expo relay sender already ships. `PushRepository.listDeliverable()` exists at `push.repository.ts:303-312`, but no sender consumes it. Make #528 an explicit dependency. |
| 516 | P3: upstream the scanner checkpoint fix behind the reparse-stall guard | rewrite | — | High — scanner PR #41 already made `refreshFile` incremental and that code is present in released `v0.12.3`, which streamer consumes at `package.json:97`. Remaining work is only remeasurement/removal of `refreshFileGuarded`, not upstreaming. |
| 517 | P1: the server listens on all interfaces with no way to restrict it, and the README claimed loopback-only | rewrite | — | High — PR #518 fixed the false README claim (`README.md:46-79`). The server still calls `listen(port)` without a host at `server.ts:2450` and exposes no bind flag, so retitle around the remaining defect. |
| 519 | P0: the server never tells clients whether Live Activity push can work, so mobile offers a feature that silently no-ops | keep | — | High — `/api/push/health` still sets `available` from repository availability at `misc.routes.ts:204-207`; `/api/info` exposes no APNs/Live Activity capability. |
| 528 | P1: no ordinary push sender — a self-hosted streamer can deliver no notifications | keep | — | High — no Expo endpoint/client exists. Tokens are stored and `listDeliverable()` is unused outside its definition. |
| 482 | P1: server.test.ts grace-timer flake still blocks the merge pipeline | rewrite | — | Medium — the claimed fixed sleep has not existed since commit `171ee42`; current grace tests poll conditions at `server.test.ts:1673-1697`. Because the issue records later flakes, rewrite around a newly reproduced signature rather than closing on the obsolete diagnosis. |
| 496 | P2: verify the three live Codex ownership scenarios | keep | — | Medium — code inspection cannot answer the three real-client ownership scenarios; no new live evidence or recorded results were found. |
| 508 | P3: live-activity — observe one real renewal in wall-clock time | keep | — | Medium — renewal tests still inject numeric clocks, e.g. `live-activity-renewal.test.ts:104-112`; there is no physical-device wall-clock observation. |
| 529 | P2: Windows global install is unverified after the better-sqlite3 dedupe | rewrite | — | Medium — the actual Windows question remains unanswered. Its claim that the streamer override still exists is now false after PR #531; `package.json:143-147` contains only the Hono override. |
| 530 | P2: Node 24 crashes six vitest workers on Windows, so the Windows CI leg cannot run the pinned Node | keep | — | Medium — `.github/workflows/ci.yml` still deliberately runs Windows on Node 22 and documents the Node 24 crash. No newer Windows Node 24 result settles it. |

## Proposed closures

In confidence order:

1. `gh issue close 498 --reason completed`
2. `gh issue close 514 --reason completed`

Neither command has been run. If approved, they must be executed one at a time.

## Compliance defects

Priority/title consistency:

- No priority-label/title-prefix disagreements.
- Every issue has exactly one priority label.

Missing the exact `## Verified state` section:

- #480
- #481
- #482
- #483

Additional type-label defects:

- #482 has both `bug` and `tech-debt`.
- #495 has both `documentation` and `tech-debt`.

## Verification conditions

The full suite was not run: machine load was moderate, the shell was on Node 26
rather than pinned Node 24, and broad results would not meet the requested
evidence standard. Both native `.node` binaries were present. The only necessary
focused test, `npx vitest run __tests__/conversation-watcher.test.ts`, passed all
14 tests in 205 ms.

## Critical issues remaining

The live open critical set contains one P0 and four P1 issues:

| Priority | # | State after audit | Why it remains critical |
|----------|---|-------------------|-------------------------|
| P0 | 519 | keep | Clients cannot tell whether Live Activity delivery is actually configured, so the feature can silently no-op. |
| P1 | 528 | keep | Self-hosted installations have no ordinary Expo push sender. |
| P1 | 517 | rewrite, then keep | The README is corrected, but there is still no way to restrict the HTTP listener to loopback. |
| P1 | 483 | keep | Boot auto-resume wastes a bounded slot on sessions that have no provider history. |
| P1 | 482 | rewrite, then re-verify | The recorded fixed-sleep diagnosis is obsolete; the later flake needs a fresh reproduction before the release-blocking claim can be trusted. |

