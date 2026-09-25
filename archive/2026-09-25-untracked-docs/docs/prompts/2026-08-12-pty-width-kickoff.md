# Kick-off — widen the PTY so Claude stops wrapping prose

**Run with: Opus 5, effort `high`.**
Not because the diff is large — it is small — but because the failure mode is silent. The prerequisite is a desync between two numbers that must agree, and getting it wrong produces no error, no failing test, and no crash: just absolute cursor moves landing on the wrong rows, exactly the class of bug tb-mobile#652 spent a day chasing. `medium` will produce a plausible patch that nobody can tell is wrong. Do not use a smaller model for the "mechanical" first step and switch later — the two halves share the invariant.

---

## Paste from here

Work in tb-streamer. Issue: https://github.com/RonenMars/threadbase-streamer/issues/549 — read it first, it carries the measurements this task rests on.

Create a worktree **outside** the repo root and branch from the current `origin/main`:

```
git worktree add ../tb-streamer-worktrees/fix-pty-width -b fix/pty-width origin/main
```

### The problem

Claude Code word-wraps its output to the PTY width. The streamer spawns at 120 columns, mobile re-wraps those already-broken rows to a ~40-column screen, and paragraphs arrive with ragged mid-sentence breaks.

Measured on the real CLI (v2.1.228): Claude does **not** cap its layout width. At 120 columns it fills 120; at 500 it fills 498; at 1000 a whole 120-word paragraph came back as **one row of 754 characters**. A wide enough PTY removes the wrapping at the source.

`isWrapped` was 0 at every width — Claude emits real newlines rather than overflowing the terminal's wrap, so no server-side rejoin is possible. "Do not wrap" is the only available fix.

### Step 1 — the prerequisite, and do not skip it

`src/pty-manager.ts:343` and `:431` spawn the PTY with **literal** `cols: 120, rows: 40`, while `createScreen()` at `:176-182` uses the `PTY_COLS`/`PTY_ROWS` constants. Changing the constant today moves the render screen and leaves the real PTY at 120.

`src/pty-manager.ts:39-41` states the invariant that breaks:

> The headless render terminal (`session.screen`) MUST match these so Claude's absolute cursor moves (`ESC[<row>;<col>H`) resolve to the same screen coordinates the real TUI is painting against.

Route both spawn sites through the constants. Then check `src/codex-pty-runner.ts` (`:316`, `:430`) for the same problem rather than assuming it is clean.

**Land this as its own commit** even if you go on to change the width in the same PR. It is correct independently and it is what makes step 2 reviewable.

### Step 2 — choose and apply a width

500 is comfortably past any real paragraph and costs a quarter of 1000's cells. 1000 buys headroom the measurements did not show a need for. Either removes the wrapping; the tradeoff is memory and chrome width, not correctness. Say in the PR body which you picked and why.

### Step 3 — verify, and verify the things that are quiet

The measurement harness is in the issue and spawns `claude` directly, so it needs no running streamer. Reuse it rather than rebuilding it.

- **Readiness at the new width.** Boot is measurably slower at 1000 columns — a 6-second wait sufficed at 120 and did not at 1000, and the prompt landed mid-boot and sat unsubmitted. Check `CLAUDE_READY_FALLBACK_MS` and the prompt-marker detection at whatever width you choose. This is the most likely real regression.
- **Memory.** xterm.js allocates per cell; cols × `SCREEN_SCROLLBACK` is the figure that changes. Measure with several concurrent sessions rather than reasoning about it.
- **Codex.** `codexStatusBarLine` takes the last non-blank rendered line and `CODEX_BUSY_STATUS_RE` matches against it. Confirm the status bar still parses; do not assume it follows Claude.
- **Box chrome.** The header row becomes as wide as the terminal. Mobile's `BOX_BORDER_RE` drops whole-border rows, but the header contains text (`╭─── Claude Code v2.1.228 ───…`) and survives the filter, so it will reach the transcript. Decide whether that is acceptable or needs a filter change on the mobile side — and if it does, that is a separate tb-mobile issue, not scope creep into this PR.
- Full suite, `tsc --noEmit --pretty false`, and `biome check` on changed files.

### Two rules that were earned on this codebase

**Run the broken variant before deciding what a test proves.** A test written after the fix, that passes, tells you nothing until you have seen it fail against the unfixed code. On this exact area a guard test was written that passed both with and without the code it was guarding.

**A zero is evidence of absence only if the same command returns non-zero on a file you know contains a match.** If you grep a capture and find nothing, run the positive control before believing it. `grep -c` counts lines and these captures have no newlines; `grep` skips files `file(1)` calls `data` unless you pass `-a`.

### Out of scope

Do not add a resize protocol. `src/pty-host/protocol.ts:38-41` deliberately omits `resize` because nothing can send it; that stays true. Do not put geometry on the wire. Do not touch the mobile client — tb-mobile#672 is already handling the user-prompt half there, and this change should reduce its relevance rather than collide with it.

### Finishing

Conventional commit title, one sentence per line in the body, no AI attribution. Show me the staged diff and the message before committing. Rebase onto `origin/main`, push, and open a PR referencing #549.
