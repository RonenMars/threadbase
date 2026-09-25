# Remote branch tree comparison — 2026-09-05

Supersedes the 2026-09-04 edition, whose baseline (`cd0207c341f71db654850420f11997557902a64a`) is now 14 commits behind `origin/main`, making every delta count in it wrong.

## Scope

Read-only comparison of every current `origin` branch-tip tree with `origin/main` at `ba3d81473ac95b451b0de094d7c63659a3b4b847`.

`main` itself is excluded, as is the stray `refs/remotes/origin/origin` ref (tree identical to `main`).

Unlike the previous edition, no Dependabot branch is excluded — only two PRs are open repo-wide (#969 `docs/main-branch-protection`, #952 `dependabot/npm_and_yarn/react-native/jest-preset-0.87.1`), and both are listed below.

## Method and limits

For each remote branch, this report compares the two tip trees directly with `git diff --name-status origin/main origin/<branch>`.

The table contains every branch whose tip tree is not identical to `origin/main`: 52 of 54.

The two omitted as identical are `chore/gitignore-vscode` (PR #968, merged 2026-09-05) and the stray `origin` ref.

`A / M / D / R` is the count of files added, modified, deleted, and renamed in the branch tip relative to `origin/main`.

Ahead/behind is shown only as history context.

Neither history divergence nor a tree delta proves that product behavior is missing from `main`; old branch bases, deliberate deletions, squash merges, and later rewrites all produce differences.

## Non-identical branch-tip trees

| Branch | Tip | PR history | Ahead / behind | A / M / D / R |
| --- | --- | --- | --- | --- |
| `chore/deps-update-podfile-lock-2026-07-22` | `98d640f384d9` | #373:CLOSED | 1 / 405 | 27 / 360 / 507 / 0 |
| `chore/deps-update-podfile-lock-file-2026-07-22` | `86db1277a7e6` | #374:CLOSED | 74 / 405 | 27 / 368 / 482 / 0 |
| `chore/i18n-unused-keys-validation` | `32387876b0b7` | #356:CLOSED | 1 / 411 | 27 / 360 / 508 / 0 |
| `ci/i18n-parity-gate` | `9bcbfdbe05ba` | #368:CLOSED | 1 / 408 | 27 / 361 / 509 / 0 |
| `dependabot/npm_and_yarn/react-native/jest-preset-0.87.1` | `3964998c1dd4` | #952:OPEN | 1 / 9 | 0 / 18 / 0 / 0 |
| `docs/hold-session-comments` | `7a2274d88dc5` | #393:CLOSED | 104 / 403 | 30 / 373 / 463 / 0 |
| `docs/jest-suite-verification` | `d666e370509f` | #372:CLOSED | 1 / 405 | 27 / 360 / 507 / 0 |
| `docs/main-branch-protection` | `436b1b2af7c5` | #969:OPEN | 1 / 1 | 0 / 3 / 0 / 0 |
| `docs/pre-release-status-2026-07-19` | `05f6f34340aa` | #347:CLOSED | 1 / 414 | 27 / 363 / 508 / 0 |
| `docs/pre-release-status-sync-2026-07-22` | `0b89b501bbc3` | #358:CLOSED | 1 / 411 | 27 / 361 / 509 / 0 |
| `docs/smartwatch-roadmap` | `44bdd496569b` | #416:CLOSED | 1 / 398 | 27 / 359 / 505 / 0 |
| `feat/cache-integrity-alert` | `c8802b6a9302` | #339:CLOSED | 3 / 414 | 27 / 365 / 504 / 0 |
| `feat/cache-warmup-status` | `40457504fe4c` | #341:CLOSED | 5 / 414 | 27 / 364 / 502 / 0 |
| `feat/collapse-wrapped-prompt-lines` | `8f3ab81bb5b0` | #449:CLOSED | 2 / 383 | 27 / 362 / 505 / 0 |
| `feat/conversation-live-reload-pause-toggle` | `f9e5bdbd006c` | #378:CLOSED | 1 / 403 | 27 / 360 / 504 / 0 |
| `feat/crash-consent-model` | `393b9ca8d820` | #343:CLOSED | 2 / 414 | 27 / 361 / 510 / 0 |
| `feat/live-activity-android` | `90750ca0a601` | #423:CLOSED | 92 / 398 | 28 / 389 / 403 / 0 |
| `feat/live-activity-contract` | `2f763ed25c4e` | #420:CLOSED | 85 / 398 | 28 / 384 / 410 / 0 |
| `feat/live-activity-ios-render` | `7cee9f72fd10` | #421:CLOSED | 88 / 398 | 28 / 386 / 407 / 0 |
| `feat/live-activity-ios-target` | `1c5a023401a0` | #419:CLOSED | 84 / 398 | 28 / 381 / 413 / 0 |
| `feat/live-external-sessions` | `71463a4d742b` | #354:CLOSED | 4 / 411 | 27 / 367 / 496 / 0 |
| `feat/live-external-sessions-integration` | `e87619c6aca0` | #355:CLOSED | 23 / 414 | 27 / 371 / 485 / 0 |
| `feat/multi-server-resilience` | `17b37cf78669` | #400:CLOSED | 112 / 403 | 28 / 373 / 451 / 0 |
| `feat/onboarding-notifications-step` | `1761f13846e4` | #364:CLOSED | 1 / 411 | 27 / 361 / 509 / 0 |
| `feat/onboarding-pairing` | `17b37cf78669` | #401:CLOSED | 112 / 403 | 28 / 373 / 451 / 0 |
| `feat/onboarding-polish-top5` | `93d0fb84acbb` | #360:CLOSED | 3 / 411 | 27 / 361 / 509 / 0 |
| `feat/per-server-claude-flags` | `2907a6fee49c` | #392:CLOSED | 102 / 403 | 28 / 373 / 468 / 0 |
| `feat/session-mental-model` | `17b37cf78669` | #399:CLOSED | 112 / 403 | 28 / 373 / 451 / 0 |
| `feat/thinking-skeleton` | `8e6ccad0e97b` | #391:CLOSED | 101 / 403 | 28 / 370 / 474 / 0 |
| `fix/abandoned-empty-sessions` | `b84f18c24da7` | #346:CLOSED | 2 / 414 | 27 / 360 / 509 / 0 |
| `fix/cold-start-deep-links` | `b7e37b948552` | #422:CLOSED | 89 / 398 | 28 / 387 / 405 / 0 |
| `fix/core-session-lifecycle` | `17b37cf78669` | #402:CLOSED | 112 / 403 | 28 / 373 / 451 / 0 |
| `fix/e2e-browse-and-feat1` | `82e650cbb5d2` | #361:CLOSED | 1 / 411 | 27 / 361 / 509 / 0 |
| `fix/e2e-drag-reorder-in-suite` | `3db05dbefb86` | #363:CLOSED | 1 / 411 | 27 / 361 / 509 / 0 |
| `fix/e2e-grant-speech-recognition` | `6b035fcdbe6c` | #359:CLOSED | 1 / 411 | 27 / 361 / 509 / 0 |
| `fix/expo-modules-jsi-swift6-abs-ambiguity` | `659fde626374` | #417:CLOSED, #428:CLOSED | 88 / 397 | 27 / 380 / 415 / 0 |
| `fix/expo-sdk-57-version-skew` | `279313623576` | #425:CLOSED | 83 / 398 | 28 / 379 / 416 / 0 |
| `fix/integration-branch-ci-failures` | `422709d5bce9` | #426:CLOSED | 83 / 398 | 28 / 379 / 418 / 0 |
| `fix/live-conversation-scroll-anchor-main` | `057a56ec5880` | #388:CLOSED | 102 / 403 | 28 / 369 / 475 / 0 |
| `fix/message-bubble-double-margin-main` | `46058fdcbe75` | #390:CLOSED | 100 / 403 | 28 / 369 / 475 / 0 |
| `fix/multi-attachment-send` | `0c09489509a4` | #345:CLOSED | 1 / 414 | 27 / 361 / 510 / 0 |
| `fix/onboarding-pair-token-exchange` | `ec5260f49e3f` | #362:CLOSED | 3 / 411 | 27 / 362 / 508 / 0 |
| `fix/servers-remove-dialog-i18n` | `8934962fdde9` | #357:CLOSED | 1 / 411 | 27 / 361 / 509 / 0 |
| `fix/session-name-display` | `3911b170d598` | #376:CLOSED | 76 / 405 | 28 / 370 / 479 / 0 |
| `fix/status-line-native-rendering` | `a8443a502e50` | #389:CLOSED | 100 / 403 | 28 / 369 / 475 / 0 |
| `fix/terminal-empty-replay-fallback` | `34f345122e16` | #385:CLOSED | 1 / 401 | 27 / 360 / 506 / 0 |
| `fix/terminal-load-full-history` | `0a550294e9f8` | #436:CLOSED | 91 / 395 | 27 / 385 / 399 / 0 |
| `fix/terminal-seq-guard` | `bb58f8a672cf` | #437:CLOSED | 91 / 395 | 27 / 386 / 398 / 0 |
| `fix/thinking-bubble-status-resync` | `6368b14f3c80` | #433:CLOSED | 1 / 393 | 27 / 360 / 507 / 0 |
| `perf/cap-virtualterminal-scrollback` | `4b2555118294` | #387:CLOSED | 90 / 403 | 28 / 369 / 475 / 0 |
| `perf/freeze-hidden-session-screens` | `77e568b68d8c` | #386:CLOSED | 89 / 403 | 28 / 369 / 475 / 0 |
| `pr/question-card-close-button-main` | `737299701330` | #448:CLOSED | 1 / 383 | 27 / 360 / 507 / 0 |
