# Anonymous Diagnostics consent — implementation (threadbase-mobile)

Spec: `docs/specs/anonymous-diagnostics-consent-v0.1.md` (copy the v0.1 spec there first; it is authoritative — 22 sections, 20 acceptance criteria). This prompt turns it into a phase-gated build.

## Ground rules
- Fresh worktree from `origin/main`, branch `feat/anonymous-diagnostics`. `npm ci`. Root checkout untouched.
- Read `CLAUDE.md` and `AGENTS.md` in full before editing. Surgical diffs. Tests land with code. Conventional commits, no AI attribution. No push.
- The core invariant (spec §2, §16) is non-negotiable and must be **proven, not asserted**: before consent, the initialised SDK transmits nothing — no events, no sessions, no breadcrumbs, no user identity. Phase 2 is that proof.
- User-facing wording is exactly **Anonymous diagnostics** everywhere (criterion 19), in all four locales.

## Phase 0 — technical design, no code. STOP at the end for approval.

1. **Inventory the current model.** Read `services/sentry.ts` (`performInit`, `reportOneShot`, the feedback self-init path), the settings store (`crashReportingEnabled`, `crashReportingUpsellDismissed`, notice flags), `RootErrorBoundary`, the feedback form and its `includeDiagnostics = true` default, the final onboarding screen, the Settings screen, and every locale key touching crash reporting. Produce a table: current behavior → spec requirement → change.

2. **Validate the SDK-ready-without-transmission design against the installed `@sentry/react-native`** (read the version from `node_modules`, use Context7 or the SDK source, not memory). Evaluate two designs and pick one with evidence:
   - **A. Gate at the edges:** single `Sentry.init` at startup with `autoSessionTracking: false`, `sendDefaultPii: false`, `tracesSampleRate: 0`, `beforeSend` / `beforeSendTransaction` returning `null` unless standing consent is ON or the event carries a one-shot authorization, `beforeBreadcrumb` returning `null` pre-consent (or `maxBreadcrumbs: 0` until consent), no `setUser` until consent ON and `setUser(null)` on OFF, sessions started manually via `Sentry.startSession()` when consent turns ON and ended on OFF, existing blocked integrations unchanged (DeviceContext stays off — criterion 17).
   - **B. `enabled: false` at init, flipped at runtime** via the client options — evaluate whether `captureFeedback` and one-shot capture still transmit under `enabled: false`, and whether the flip is supported in this SDK version.
   Show, from SDK source or docs, which hooks are honored for feedback envelopes, sessions, and native crash capture. State what the design does *not* cover (native fatal crashes — out of scope per §8).

3. **Web/IP (spec §17):** confirm `sendDefaultPii: false` prevents `user.ip_address: "{{auto}}"`; list the Sentry project-side setting ("Prevent storing of IP addresses" / data scrubbing) as an ops step in the final report, since it is outside the repo.

4. **State model (spec §19):** rename `crashReportingEnabled` → `anonymousDiagnosticsEnabled` (no users, no migration); add `onboardingDiagnosticsExperimentVariant: 'treatment' | 'control'` assigned once with `Math.random() < 0.4`, persisted, never reassigned; add `postFeedbackDiagnosticsSuggestionImpressions: number[]` (timestamps; allow a new impression only if fewer than 2 fall inside the trailing 30 days); remove `crashReportingUpsellDismissed` semantics (spec §14: "Not now" dismisses one suggestion, never "never again").

5. **UI plan, one bullet per surface:** onboarding final screen toggle (treatment only, default OFF, Continue independent, Learn more sheet); Settings control + Learn more; `RootErrorBoundary` — OFF: unchecked checkbox "Automatically send future crash reports and diagnostics" + "Report this crash", where Report sends the crash and, if checked, *then* enables consent; ON: no checkbox, no duplicate report; feedback form — OFF: "Include technical diagnostics" default unchecked; ON: checkbox hidden, diagnostics auto-included, "See what's included" stays; screenshots and email stay per-submission and explicit; post-feedback suggestion — non-modal, only after successful delivery, only when OFF, frequency-limited, "Enable anonymous diagnostics" / "Not now".

6. **Experiment measurement without pre-consent telemetry (spec §7):** tag `onboarding_variant` on events only *after* consent. Denominators come from store installs × 0.4 / 0.6, not from the app. Say this explicitly in the design so nobody adds a "consent shown" ping later.

7. **Test plan** mapping each of the 20 acceptance criteria to a named test. The transmission proof is a transport spy: assert zero envelopes at launch, after navigating, and after a caught error with consent OFF; exactly one envelope for a one-shot report; a session start on consent ON; user cleared and no further envelopes after OFF.

8. Locale keys to add/rename in en/he/ar/ru, with the primary copy from spec §3 verbatim.

## Phase 1 — implement, one commit per step, tests with each
1. `services/sentry.ts`: the chosen design; unify the temporary-init paths so `Sentry.init` runs exactly once.
2. Settings store: state rename, experiment assignment, impression window.
3. `RootErrorBoundary` flows (OFF and ON).
4. Feedback form defaults and the ON-state auto-include.
5. Settings control + Learn more.
6. Onboarding treatment toggle.
7. Post-feedback suggestion with the rolling-30-day limit.
8. Locales ×4, i18n parity green.

## Phase 2 — proof and paperwork
- Run the app in dev with the transport spy or a network log and record the evidence for the invariant (launch, navigation, caught error, feedback send, one-shot crash, consent ON, consent OFF). Save it as `docs/audits/anonymous-diagnostics-transmission-proof.md`.
- Update `README.md` privacy table and `docs/FEATURES.md` (one `[shipped]` line: "Anonymous diagnostics — opt-in crash reports and stability data with a random installation ID; off by default").
- Final report: commits, test results, the acceptance-criteria table with pass/fail, ops steps (Sentry project IP scrubbing, data scrubbers), and the exact policy behavior the landing page may now describe.
