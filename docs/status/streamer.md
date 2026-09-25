# threadbase-streamer — Status

**Last updated:** 2026-09-25  
**Language:** TypeScript · Node.js  
**Visibility:** Public

Open work is tracked in the [threadbase-streamer issues](https://github.com/RonenMars/threadbase-streamer/issues), not here.

---

## Recent reliability work (2026-09-25)

Four follow-ups to the shutdown and deploy fixes in #971 and #976, each merged on green CI:

| PR | Change | Merge |
|---|---|---|
| [#977](https://github.com/RonenMars/threadbase-streamer/pull/977) | `dev:verbose`, `prepublishOnly` and `test:smoke-isolated` run their nested build with the npm that launched them, which silences the npm 11 `global-ignore-file` warning. | `2fe47d6d` |
| [#980](https://github.com/RonenMars/threadbase-streamer/pull/980) | The `external-live-tails` test waits until the directory watcher is actually delivering events, instead of sleeping a fixed 1500 ms. It went from up to 8 failures in 10 under load to 0 in 10. | `4540a3d0` |
| [#978](https://github.com/RonenMars/threadbase-streamer/pull/978) | Shutdown tracks the boot reconcile → auto-resume chain, so a stop during boot no longer spawns an orphan PTY or writes to the closed session registry. | `fd3e7dae` |
| [#981](https://github.com/RonenMars/threadbase-streamer/pull/981) | The startup warm-up upserts the conversation cache in 50-item batches, so it no longer blocks the event loop for 1.7–2.2 s of CPU time on a ~1500-conversation cache. | `7ccb1787` |
