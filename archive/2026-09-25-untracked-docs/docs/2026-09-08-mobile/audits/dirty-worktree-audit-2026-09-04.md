# Dirty worktree audit — 2026-09-04

Re-verified 2026-09-05: eleven listed worktrees no longer exist and their rows were removed.
The five rows below were re-checked against the filesystem and are still dirty.

## Scope

This records uncommitted content found while preparing local worktree cleanup.

Nothing listed here was discarded, stashed, reset, or otherwise changed.

## Dirty worktrees

| Worktree | Branch | Uncommitted content |
| --- | --- | --- |
| `tb-mobile` | `main` | Untracked audit documents under `docs/audits/`, plus an untracked `.vscode/`. |
| `tb-mobile-worktrees/e2e-flow-fixes` | `fix/e2e-flow-fixes` | Extends pairing/setup and promo Maestro flows for the pair-confirm gate, Keychain password sheet, leave-session modal, and iOS timing; includes two captured iOS crash reports. |
| `tb-mobile-worktrees/e2e-flow-fixes-clean` | `fix/promo-e2e-flow-fixes` | Updates reusable Maestro setup for the added language onboarding step and renumbered onboarding flow. |
| `tb-mobile-worktrees/promo-04-e2e-verify` | `test/promo-04-e2e-verify` | Hardens multi-machine pairing E2E timing, save/password-sheet handling, and pair-confirm-gate assertions; also has iOS localization project-file and Podfile.lock changes. |
| `tb-mobile-worktrees/setup-yaml-mock-verify` | `test/setup-yaml-mock-verify` | Adds pair-confirm-gate handling to reusable Maestro setup and has iOS localized `InfoPlist.strings` project-file plus Podfile.lock changes. |

Rows removed on 2026-09-05 because the worktree is gone: `tb-mobile-i18n-status-cleanup`,
`d3-benchmark`, `e2ee-device-run`, `fix-pair-gate-modal`, `g-device-run`, `issue-600-chat`,
`issue-600-feedback`, `issue-600-search-anchor`, `probe-40ac02ac`, `prune-loader`, `rn-0-87`.
The `issue-600-*` and `prune-loader` content reached `main`; see the never-had-PR review.

## Cleanup boundary

Only Git-clean worktrees were eligible for removal.

`main`, `fix/kill-on-idle-navigation`, Dependabot worktrees, and every worktree above were retained at the time of the audit.

`e2ee-rest-envelope` briefly reported tracked-file deletions while its already-validated clean worktree was being removed. That was the filesystem removal in progress, not pre-existing uncommitted work, and it is intentionally not listed as dirty content.

## Completed local cleanup

- Removed 17 validated-clean linked worktrees and their attached local branches where applicable.
- Removed 115 additional unattached local branch refs after excluding `main`, Dependabot refs, attached worktree branches, and current open-PR heads.
- No remote branch was deleted by this cleanup.

## Threadbase Streamer local-branch audit

Checked `/Users/ronenmars/dev/ai-tools/tb-streamer` against freshly fetched `origin/main` at `1e1d5954` on 2026-09-04.

Re-verified 2026-09-05 against `origin/main` at `5a489ee9`: PR #775 merged 2026-09-04T18:37Z and
`feat/hold-session-ack` is gone, so that row is dropped. PR #754 is still open and `fix/snyk-ci`
still sits at its head `1f6f253f`. The five cleanup-candidate branches all still exist, uncleaned.

| Branch or group | PR state | Content result | Recommendation |
| --- | --- | --- | --- |
| `fix/snyk-ci` | No PR under this local name | Its two commits are represented by open PR #754 under `snyk-fix-4bb7318d98fb50ba980ab365465b6a70`; not in `main`. | Preserve until PR #754 lands; local branch is a duplicate delivery branch. |
| `feat/e2ee-access-probe`, `feat/e2ee-no-e2ee-flag`, `feat/e2ee-open-refusal-log` | No PR under these names | Absorbed by PR #752 / `a3a6adf0`; corresponding source and tests are present in `main`. | Cleanup candidates. |
| `fix/conversation-lookup-moved-project` | No PR under this name | Stale integration content is absorbed by `main`; only four old shared skill files remain branch-only. | Cleanup candidate after preserving any desired skill files. |
| `w-review` | No PR | Zero commits ahead of `main`; fully absorbed. | Cleanup candidate. |
| All other local branches | Merged PRs | Their substantive content is represented on `main`; divergence is historical or due to later `main` commits. | Cleanup candidates after dirty-worktree checks. |

### Streamer audit summary

There are 36 local branches besides `main`, including the local `fix/snyk-ci` repair branch.

Thirty branches correspond to existing PR names: 29 merged PRs and (at audit time) open PR #775, since merged.

The six branches without a PR under their current local name are listed above; none contains stranded application code.

As of 2026-09-05 the only local application code not on `main` is the Snyk/test-fix work covered by open PR #754; the hold-session-ack work landed with PR #775.

No local branch or worktree was deleted during this audit.
