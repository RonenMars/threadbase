# Prompt — notify the user when the agent has responded and is waiting for input

Hand this to a fresh agent session opened in `~/dev/ai-tools/tb-streamer`.

Tracked as **RonenMars/threadbase-streamer#528**.

---

## The goal

When an agent finishes its turn and is waiting for the user, push a notification to their phone. That is the one moment the away-from-desk workflow depends on: the user put the phone down expecting to be told when it is their turn.

## The blocker you are removing

**The streamer cannot send an ordinary notification at all today.** Verified against `main` on 2026-08-11: no Expo push client, no `exp.host` / `expo.dev` call, no FCM, no `sendNotification` anywhere in `src/`.

`POST /api/push/register` (`src/api/routes/misc.routes.ts:131`) accepts and stores tokens; `src/db/repositories/push.repository.ts:6` records it "was a no-op returning `{ ok: true }`". Nothing consumes those tokens except `LiveActivitySender`.

## Why you must not extend the APNs path

`ApnsClient` signs its own pushes with an APNs `.p8` and targets `${bundleId}.push-type.liveactivity` (`src/services/push/apnsClient.ts:160-167`).

Apple issues APNs keys **per developer team**, and a key signs only topics for bundle IDs that team owns. A self-hosted streamer's key cannot sign for the published app's bundle ID. That is Apple's trust boundary — so anything built on `ApnsClient` works only for the maintainer, forever.

Self-hosting is the primary deployment. Build for that.

## The transport that works with no Apple credentials

Mobile already registers an **Expo** token — `threadbase-mobile` `services/push.ts:40` calls `getExpoPushTokenAsync()`, yielding `ExponentPushToken[...]`.

Expo holds the APNs and FCM credentials for the app, uploaded once by whoever built it. Any streamer can therefore send with a plain POST:

```
POST https://exp.host/--/api/v2/push/send
Content-Type: application/json

{ "to": "ExponentPushToken[...]", "title": "...", "body": "...", "data": { ... } }
```

No `.p8`, no Team ID, no bundle-ID signing, and one code path for iOS and Android.

## Where the trigger already exists

Do not invent a new detection mechanism. `PTYManager.markReady()` (`src/pty-manager.ts:1168`) is exactly "the agent reached its prompt and is waiting". It is called from three detectors — prompt-marker (`:839`), screen-marker (`:1138`), and a timeout fallback (`:1153`) — and it is what already drives the `waiting_input` status.

`src/services/push/liveActivityNotifier.ts` is the existing consumer of that transition. Read it first: it shows the established shape for reacting to a status change, and the new sender should sit alongside it rather than duplicating its wiring.

## What to build

A push sender module beside the existing ones in `src/services/push/`, invoked on the same transition, that:

1. Looks up registered Expo tokens for the device(s) that care about this session.
2. Sends one notification per token via Expo.
3. Handles the response.

## The parts that are easy to get wrong

**Do not notify the user who is already looking.** If the app is foregrounded on that session, a push is noise. Decide how you know — a WS subscription for that session is the obvious signal — and say what you chose.

**Do not notify per output chunk.** `markReady` should fire once per turn, but verify that against the three call sites rather than assuming; a fallback firing after a marker already fired would double-send. Add a guard and a test if it can.

**Evict dead tokens.** Expo returns per-token tickets; `DeviceNotRegistered` means the token is permanently dead. `LiveActivitySender` already retires dead APNs tokens — mirror that rather than inventing a second policy.

**Independent sends.** One rejected token must not stop the others. `LiveActivitySender`'s doc comment explains why: a single dead device would otherwise silence every other device watching the same session.

**Auth is a real decision.** Expo accepts unauthenticated sends by default, so anyone holding a token can push to that device. Expo's access-token mode restricts senders and adds only an Expo credential, not an Apple one. Pick one and state the reasoning; do not leave it undecided.

## Payload — this is a privacy decision, not a formatting one

**Read `RonenMars/threadbase-mobile#636` before choosing the payload.** The Live Activity payload carries `lastOutput` (raw terminal output), a prompt-derived `title`, and `projectName` — while the published privacy policy claims notification payloads exclude exactly those. That mismatch is an open P0.

Do not reproduce it. A notification saying *which session* needs attention does not need to carry *what the agent said*. Default to session and project identifiers plus a neutral prompt like "waiting for your input", and treat any inclusion of session content as a deliberate choice that has to be reflected in the policy text before it ships.

If you believe content is needed for the feature to be useful, say so and stop — that is the maintainer's call, and it changes legal copy in two repos.

## Done looks like

- A self-hosted streamer with **no Apple credentials** delivers a notification to a TestFlight or App Store build when an agent finishes its turn.
- Tapping it opens that session.
- A foregrounded, actively-viewed session does not produce one.
- A dead token is evicted rather than retried forever.
- Tests cover: send on ready, no double-send within a turn, dead-token eviction, and one token failing without blocking the rest.
- What the payload contains is written down, and matches what the privacy policy says.

## Constraints

- Follow `CLAUDE.md` / `AGENTS.md` in this repo for branch, commit and PR conventions. Conventional title, one sentence per line, no AI attribution.
- Work in a worktree **outside** the repo root.
- `npm run build`, the vitest suite, and biome must pass before the PR.
- Do not modify `ApnsClient` or the Live Activity path. This is additive.

## Reference

- `RonenMars/threadbase-streamer#528` — this issue
- `RonenMars/threadbase-mobile#636` — the payload/policy divergence to avoid repeating
- `src/services/push/liveActivitySender.ts`, `liveActivityNotifier.ts` — the shape to follow
- `src/pty-manager.ts:1168` — `markReady`, the trigger
- `src/api/routes/misc.routes.ts:131` — where tokens arrive
