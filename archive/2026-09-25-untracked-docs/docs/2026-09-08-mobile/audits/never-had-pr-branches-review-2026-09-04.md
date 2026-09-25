# Review — mobile branches that never had a PR

Written 2026-09-04, following up on `dirty-worktree-audit-2026-09-04.md`'s
"never had a PR" category. Each branch's actual uncommitted diff was read
against current `origin/main` (not just commit-distance/staleness), to judge
whether the content is still applicable or genuinely abandoned.

Re-verified 2026-09-05 against `origin/main` at `a4da8dea`. Six of the nine rows are
discharged and were removed:

- **Landed on `main`** — `feat/prune-confirm-loader` (`components/…/CacheAlertModal.tsx:168`),
  `fix/issue-600-chat` (`components/sessions/SessionCard.tsx:152,155`),
  `fix/issue-600-feedback` (`app/help-feedback.tsx:340`),
  `fix/issue-600-search-anchor` (`e2e/fixtures/conv-search-anchor.json` plus the mock-server
  project filter).
- **Branch deleted without landing** — `chore/rn-0.87` (`main` is still on React Native
  `0.86.3` and dependabot #952 is still open) and `spike/d3-crypto-benchmark`.

The three rows below still exist as local-only, still-dirty worktrees, and issue #600 is
still open.

## Verdicts

| Branch | What it actually changes | Verdict |
|---|---|---|
| `fix/e2e-flow-fixes` | E2E YAML flow updates for pairing/setup and promo flows (pair-confirm gate, Keychain password sheet, leave-session modal, iOS timing) + two captured iOS crash reports (`safari-view-service-crash.txt`, `spring-board-crash.txt`). | **Likely superseded** by `test/promo-04-e2e-verify` and `test/setup-yaml-mock-verify` (both touch the same pair-confirm-gate E2E territory, more recently — 13 days vs 2 weeks old). **Pull the two crash reports out before discarding the branch** — those are evidence, not code, and shouldn't be lost with the branch. |
| `test/promo-04-e2e-verify` | Hardens multi-machine pairing E2E timing, save/password-sheet handling, pair-confirm-gate assertions; also carries iOS localization project-file and `Podfile.lock` changes. 4 commits ahead of its merge-base (the only one of this group with actual committed-but-unpushed work, not just a dirty working tree). | **Likely the current/superseding version** of the pairing-gate E2E hardening work. Worth finishing over `fix/e2e-flow-fixes`. |
| `test/setup-yaml-mock-verify` | Adds pair-confirm-gate handling to reusable Maestro setup + iOS localized `InfoPlist.strings` project-file and `Podfile.lock` changes. | Overlaps `test/promo-04-e2e-verify` in the same territory (pair-confirm-gate Maestro setup). **A human needs to pick which of these two — or both, merged — is the one to finish**; don't guess which is authoritative without running them. |

## Recommendation

One open decision remains. **The E2E-flow-fixes overlap** (`fix/e2e-flow-fixes`,
`test/promo-04-e2e-verify`, `test/setup-yaml-mock-verify`) needs a human to pick the
current/authoritative attempt among three overlapping ones — I can characterize the
diffs but shouldn't guess which one is "the" fix.

Before `fix/e2e-flow-fixes` is discarded, pull `safari-view-service-crash.txt` and
`spring-board-crash.txt` out of its worktree — confirmed still untracked there on
2026-09-05. Those are evidence, not code.

Not deleted, not touched beyond reading, in any of these worktrees.
