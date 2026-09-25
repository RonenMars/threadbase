# Open issue audit — 2026-08-11

Audited all 27 open issues in `RonenMars/threadbase-mobile` against freshly fetched `origin/main` at `89a7514cc643c4a80d2f5dc0def23a08c67a739e`.

Only one issue is a confident closure candidate: #612.

No GitHub state was changed.

Rows are ordered from highest-confidence factual verdicts to intent-dependent decisions.

| # | Title | Verdict | Category | Evidence |
|---|---|---|---|---|
| 612 | P3: decide the source of /api/projects — it cannot see Codex | `close` | Answered | `git grep -n useProjects origin/main -- '*.ts' '*.tsx'` finds only its declaration in `hooks/useProjects.ts:15`; there are no runtime consumers. The app uses `useProjectSummaries` instead. The unused hook can be separate tech debt, but the question has a definite answer. |
| 602 | P0: App Store and Play listings unpopulated; no automated store deploy | `rewrite` | — | The automation claim is obsolete: `.github/workflows/deploy.yml:4-32` exposes iOS production and Android production targets; `:156-186` and `:309+` run store delivery. Keep only the still-unverified store-listing and content work. |
| 605 | P1: finish onboarding polish — manual tb pair exchange and NotificationsStep | `rewrite` | — | Manual exchange is fixed: `hooks/useTBPair.ts:63-95` exchanges both pair URIs and `pt_` tokens; targeted tests passed, 8/8. Notifications remain broken on fresh onboarding: `NotificationsStep.tsx:53-56` reads `activeServerIds`, but `OnboardingNavigator.tsx:100-113` does not add the paired server until the later Done step. |
| 614 | P3: three small UX parity items — settings entry, server-name slide, favorites CTA | `rewrite` | — | Two items already exist: Settings button at `components/servers/FilterSortSheet.tsx:148-157`; Favorites CTA at `app/manage-favorites.tsx:38-44`. Retain only the optional server-name customization request. |
| 618 | P3: retire stale docs — leftovers.md, mismatched brief heading | `rewrite` | — | `docs/leftovers.md` is deleted, and `docs/pre-relase-backlog-and-roadmap-analysis-2026-07-18-open-items.md:3` now has the supersession pointer. Only `docs/followups/mobile/07-pair-deep-link-route.md:1` still says `# 08`. |
| 616 | P3: build and toolchain cleanup — precompiled frameworks, warnings, bottom-sheet spike | `rewrite` | — | Its claim that no precompiled configuration exists is false: `ios/Podfile:21` enables `EXPO_USE_PRECOMPILED_MODULES`. Actual CI effectiveness, warning cleanup, EAS libraries, and the `@gorhom/bottom-sheet` spike remain open. |
| 617 | P3: orchestration feature cluster (Features 6-15) | `rewrite` | — | Feature 12 is already shipped. PR #639, commit `89a7514c…`, corrected `docs/ROADMAP.md`; `git merge-base --is-ancestor 89a7514c… origin/main` returned 0. Remove Feature 12; the other nine features remain live. |
| 601 | P0: 15 privacy and store-compliance items block the public listing | `rewrite` | — | Current checklist command `grep -c '^- \\[ \\]'` returns **17**, not 15. The work remains real, but the title and inventory need refreshing, including the payload contradiction in #636. |
| 610 | P2: expand Maestro coverage and add a visual regression gate | `rewrite` | — | PR #635 added separate pairing and multi-machine promo flows, but `test:e2e:mock` still runs the original 15 and has no visual comparison. Rewrite around promoting existing promo coverage into the gate plus remaining gaps. |
| 638 | P2: pair deep-link failure shows a raw exception instead of translated copy | `keep` | — | `app/pair.tsx:27-30` passes `err.message` into translations; `locales/en/pair.json` still renders `Could not reach the server: {{message}}`. PR #640 is open, not merged. |
| 636 | P0: Live Activity payload contains terminal output and prompt-derived text the privacy policy says it excludes | `keep` | — | `docs/privacy-policy/proposed-privacy-policy.md:42-51` still promises Expo transport and exclusion of terminal and prompt content. PR #639 explicitly reconfirmed the divergence and is on `main`. |
| 621 | P3: React Compiler follow-through — last hooks warning, then memoization audit | `keep` | — | Fresh `npx eslint app components hooks` reported exactly one warning: `app/session/[id].tsx:558`, missing `stopSession`. The memoization audit remains undone. |
| 609 | P2: finish the theming migration — DiffViewer and colour literals | `keep` | — | Fresh grep returns six matching `dark.*` references, all at `components/conversation/DiffViewer.tsx:124-179`. |
| 606 | P1: npm run typecheck is red locally and green in CI | `keep` | — | After Metro generated `.expo/types/router.d.ts`, fresh `npm run typecheck` produced the same 14 `TS2345` typed-route errors. Without generated routes it exited 0, reproducing the disagreement. |
| 603 | P1: retire useEagerConversations | `keep` | — | Still declared at `hooks/useConversations.ts:791` and mounted by `app/index.tsx:241-246`; Manage Favorites still reads its cache at `app/manage-favorites.tsx:23-31`. |
| 565 | P2: conversation_updated frames trigger a full eager-conversations re-drain per frame | `keep` | — | `lib/eagerCacheSync.ts:52-57` still invalidates `['conversations-eager']` after the debounce instead of patching a row. |
| 604 | P1: colocate Hub subscriptions to stop whole-tree re-renders | `keep` | — | Root-level subscriptions remain in `app/index.tsx:91-141`, including settings, server state, fetch status, WebSocket state, and cache alerts. |
| 615 | P3: queue-while-thinking composer affordance | `keep` | — | `ChatComposer.tsx:32-46` has no queue or turn-state input; `:139-148` always renders the ordinary send affordance. |
| 623 | P3: sync mode — JSONL-sourced bubbles and native prompt forms | `keep` | — | Fresh search found no `SyncModeMessageList`, `PromptForm`, `jsonl.message`, or `jsonl.prompt` implementation. |
| 620 | P3: structured prompt cards for Codex sessions | `keep` | — | Fresh search found no structured prompt-card or prompt-form implementation. The server-contract dependency does not make the enhancement irrelevant. |
| 611 | P3: 05_chat_flow hideKeyboard break on Maestro 2.6.1 / iOS 26.x | `keep` | — | Installed Maestro is still `2.6.1`; `e2e/05_chat_flow.yaml:34` still first waits for `first-session-card` and `:67` still invokes `hideKeyboard`. It is a distinct later failure, not a proven duplicate. |
| 600 | P0: E2E suite cannot gate at 11/15 passing flows | `keep` | — | Fresh preflight reached the booted iOS 26 simulator but stopped because the installed Release build lacks a freshness stamp. The suite therefore cannot currently produce a trustworthy green gate; rebuilding was outside this read-only audit. |
| 637 | P2: Servers Status modal is a single merged accessibility element, unreachable by VoiceOver | `keep` | — | Current hierarchy still nests the sheet `Pressable` inside the backdrop `Pressable` at `ServersStatusModal.tsx:287-288`, with controls beneath it. No accessibility fix has landed. A fresh device hierarchy check requires rebuilding the stale Release app. |
| 608 | P2: new session from tree view errors on Path | `keep` | — | `app/browse.tsx:219-243` still passes the drilled path through `/session/new`. No current device/server reproduction was available, but there is also no evidence the reported defect is gone; lack of reproduction is not grounds to close. |
| 607 | P2: measure the ADR 0001 render target | `keep` | — | `docs/adr/0001-hub-data-layer-lazy-pagination.md:33` still defines the target as an unrecorded measurement. No current result was found. |
| 619 | P3: smartwatch session surfaces via OS mirroring | `needs-decision` | — | Phone Live Activities are shipped, so the stated blocker is gone; however #636 and the self-hoster APNs limitation materially change the value. Decision needed: retain a maintainer/device-only mirroring verification task, or drop smartwatch scope until delivery works for self-hosters? |
| 613 | P3: decide whether the integration branch still has a future | `needs-decision` | — | #575 and #580 are both closed, every currently open PR targets `main`, but the two remote integration branches still exist. Decision needed: intentionally retain them as snapshots, or declare `main` the sole trunk and remove or archive them? |

## Compliance defects

- Priority/title mismatch: none.
- Missing `## Verified state` section: #565, #602, #605, #607, #608, #610, #611, #612, #613, #614, #616, #617, #618, #619, #620, #621, #623.
- Additional canonical label defect: #606 has two type labels (`bug`, `tech-debt`); #636 has two (`bug`, `documentation`). The convention requires exactly one.

## Proposed closure

If approved, the sole closure should be performed first and alone:

```bash
gh issue close 612 --repo RonenMars/threadbase-mobile --reason "not planned"
```

No comment should be posted.

## Critical issues remaining open

Using the tracker definition of **P0 = release blocker**, four critical issues remain open:

| # | Remaining critical work | Audit verdict |
|---|---|---|
| 600 | Restore a trustworthy E2E release gate; the mock suite is not green. | `keep` |
| 601 | Complete and accurately enumerate the privacy and store-compliance checklist. | `rewrite`, then keep open |
| 602 | Populate the App Store and Play listings. Automated deployment already exists and should be removed from the issue. | `rewrite`, then keep open |
| 636 | Resolve the Live Activity payload and published privacy-policy contradiction. | `keep` |

## P1 issues remaining open

| # | Remaining P1 work | Audit verdict |
|---|---|---|
| 603 | Retire `useEagerConversations`. | `keep` |
| 604 | Colocate Hub subscriptions to stop whole-tree re-renders. | `keep` |
| 605 | Finish onboarding polish: retain the NotificationsStep repair and remove the already-shipped manual `tb pair` work from the issue. | `rewrite`, then keep open |
| 606 | Make `npm run typecheck` agree locally and in CI. | `keep` |
