# Issue tracker conventions

**Canonical for every Threadbase component repository.** One label vocabulary and one issue format across the ecosystem, so a reader moving between repos does not relearn anything and a cross-repo item reads the same from either side.

This file is the single source of truth. Component repos link here; they do not keep their own copy. A convention that exists in two places becomes two conventions — the first divergence is always a pointer sentence, and by the time anyone notices, the rules have drifted too.

Adopted 2026-08-10, generalising the scheme `threadbase-mobile` and `threadbase-streamer` converged on.

**Adopted today by:** [`threadbase-streamer`](https://github.com/RonenMars/threadbase-streamer/issues), [`threadbase-mobile`](https://github.com/RonenMars/threadbase-mobile/issues). Adopting it in another component repo means creating the label set below — nothing else.

> **Maintainer triage, not the public report form.** This describes how maintainers file and label work. External bug reports arrive through [`.github/ISSUE_TEMPLATE/`](../.github/ISSUE_TEMPLATE/) in this repo, which routes reporters to the right component and uses a `[Bug]: ` title. A maintainer picking such a report up re-titles and labels it to the scheme below. The two are different audiences and neither replaces the other.

---

## The shape of an issue

```
Title:   P<N>: <what is wrong or what should exist>
Labels:  <one priority> + <one type> + <zero or more areas>
```

Three rules, and all three are checkable:

1. **Exactly one priority label**, and the title repeats it as a `P<N>: ` prefix. The prefix is what makes a plain issue list scannable — GitHub renders labels after the title, and they wrap out of view on a narrow screen.
2. **Exactly one type label.**
3. **Areas are free** — zero, one, or several.

## Priority

Priority answers *when*, never *how hard*. A one-line fix that blocks a release is P0; a month of work nobody is waiting on is P3.

| Label | Colour | Meaning |
|---|---|---|
| `P0` | `B60205` | Release blocker. Ships broken, or blocks the store listing / public invite. |
| `P1` | `D93F0B` | Fix before release. Not broken for users, but the release should not go out with it. |
| `P2` | `FBCA04` | Soon, but does not gate a release. |
| `P3` | `0E8A16` | Deferred. Real, but nobody is waiting — includes work blocked on an external dependency. |

**Re-prioritising means editing the title too.** They are two representations of one fact, and a mismatch is worse than either alone.

`P0` and `P1` are the release gate, and keeping them few is the point. If everything is P0, the tracker no longer says what to do next.

## Type

Exactly one. What kind of change this is.

| Label | Colour | Meaning |
|---|---|---|
| `bug` | `d73a4a` | Behaviour is wrong. Something worked, or was supposed to. |
| `enhancement` | `a2eeef` | New capability, or a deliberate improvement to existing behaviour. |
| `documentation` | `0075ca` | The code is right; what is written about it is not. |
| `question` | `d876e3` | A decision to make or a fact to establish. Closing it produces an answer, not a diff. |
| `tech-debt` | `C5DEF5` | Cleanup with no user-visible change. Refactors, test isolation, dead code. |

`question` earns its place. A real category of work here is *verify X against a live session* or *decide whether Y is acceptable*, and filing that as `bug` or `enhancement` misrepresents what finishing it looks like.

## Area

Zero or more. Where the work lands. Useful for filtering, never for priority.

| Label | Colour | Meaning |
|---|---|---|
| `ci` | `1D76DB` | CI, workflows, release automation, build harness. |
| `e2e` | `1D76DB` | End-to-end and contract test suites. |
| `performance` | `5319E7` | Query cost, latency, memory, render cost, throughput. |
| `security` | `EE0701` | Auth boundary, secrets, replay, injection. |
| `observability` | `BFDADC` | Logging, metrics, traceability of runtime behaviour. |
| `platform` | `FEF2C0` | OS-level behaviour. Streamer: launchd, systemd, Task Scheduler. Mobile: OS and store-level behaviour. |
| `native` | `006B75` | Native modules and toolchain. Streamer: `node-pty`, `better-sqlite3`. Mobile: iOS/Android modules. |
| `provider` | `D4C5F9` | Claude Code / Codex integration — collision, resume, prompt detection. |
| `ux` | `BFD4F2` | User-facing interaction and polish. Clients: the interface. Streamer: CLI and API ergonomics. |

`dependencies` and `javascript` are applied by Dependabot to PRs. Do not hand-apply them to issues.

### `platform` versus `native`

These get confused. `native` is about *code that compiles*; `platform` is about *the OS behaving differently*. A `better-sqlite3` ABI mismatch is `native`. Task Scheduler not redirecting stdout is `platform`. An issue can be both — a Windows-only `node-pty` build failure is `native` + `platform`.

## Triage state

Priority, type and area say *what an issue is*.
A separate, additive set of labels says *what happens to it next* — `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`.

Those are canonical in [`triage-labels.md`](./triage-labels.md), and applying one never means removing a priority, type or area.

## Body

Lead with what is wrong, in one or two sentences, with no heading. Then use whichever sections below carry real content, and omit the rest. **Do not pad an issue to fit the template.**

| Section | Purpose |
|---|---|
| `## Verified state` | What is true in the code today, with a `file.ts:123`, a PR number, or a quoted log line. Say when it was checked. |
| `## Blocked on` | The named blocker. Only when the work genuinely cannot start. |
| `## Depends on` | Ordering against other work, and why the order matters. |
| `## Done looks like` | Observable acceptance. What a reviewer checks. |
| `## Reference` | Doc paths, PR numbers, related issues in any repo. |

`## Verified state` is the section that earns the format. An issue asserting a defect without evidence costs the next reader a re-investigation, and an issue whose claim silently went stale is worse than no issue at all. This whole scheme was adopted after an audit found trackers listing eight already-merged PRs as open work.

**Prose rules**, matching the commit and PR conventions across these repos:

- One sentence per line. Never break a line mid-sentence; let the renderer wrap.
- No AI attribution anywhere — issues, comments, commits, or PR bodies.
- Name files as `path/to/file.ts:123`. GitHub does not linkify them, but they are greppable and unambiguous.

## Cross-repo items

Plenty of work spans repos: a server contract plus the client that consumes it.

File it in **both**, each describing that repo's half, and link them by URL. Never one issue covering both — one side then tracks work it cannot close, and neither issue has a meaningful "done".

Where a change must ship in a specific order, say so under `## Depends on` on both sides. The streamer is usually the compatibility-constrained end: released mobile builds cannot be force-updated, so an additive server change lands first and the client follows.

## Worked example

```markdown
Title: P2: log the 401 decision in the auth middleware
Labels: P2, enhancement, observability, security

`src/api/middleware/auth.middleware.ts` contains zero log calls, so a 401 is invisible.

Silent 401s hide a brute-force attempt and a misconfigured client equally well, and the
streamer is reachable from the public internet through a tunnel.

## Verified state

Confirmed absent 2026-08-10: no `log.` or `logger.` reference anywhere in the file.

## Done looks like

A rejected request logs `{event, path, method, remoteAddr}` at warn.

## Reference

`docs/observability-audit.md` Rank 1
```

## Checking compliance

```sh
R=RonenMars/threadbase-streamer   # or threadbase-mobile, or any adopting repo

# exactly one priority label
gh issue list --state open --limit 200 --json number,labels -R "$R" \
  -q '.[] | select((.labels|map(.name)|map(select(test("^P[0-3]$")))|length) != 1) | .number'

# a type label
gh issue list --state open --limit 200 --json number,labels -R "$R" \
  -q '.[] | select((.labels|map(.name)|map(select(.=="bug" or .=="enhancement" or .=="documentation" or .=="question" or .=="tech-debt"))|length)==0) | .number'

# the title carries its priority prefix
gh issue list --state open --limit 200 --json number,title -R "$R" \
  -q '.[] | select(.title|test("^P[0-3]: ")|not) | .number'
```

All three print nothing when a tracker is clean.

## Changing the vocabulary

Add a label when **three or more** issues need it and no existing label fits. A label with one member is a filter nobody uses and a decision everybody has to make.

Add it to **every adopting repo in the same sitting**, even where it has no members yet. A vocabulary that has diverged is no longer shared, and re-converging costs more than an empty label.

Then update this file — and only this file. Component repos link here; if you find a copy of these rules living in a component repo, replace it with a link rather than editing it.
