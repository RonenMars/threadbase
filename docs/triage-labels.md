# Triage labels

**Canonical for every Threadbase component repository.**
These are the *state* labels — what happens to an issue next — and they are additive to the priority, type and area taxonomy in [`issue-tracker.md`](./issue-tracker.md).

Component repos link here; they do not keep their own copy of the vocabulary.
A convention that exists in two places becomes two conventions.

Adopted by [`threadbase-mobile`](https://github.com/RonenMars/threadbase-mobile/issues) on 2026-08-14 and [`threadbase-streamer`](https://github.com/RonenMars/threadbase-streamer/issues) on 2026-08-20.
Adopting it in another component repo means creating the label set below — nothing else.

## The labels

| Label | Colour | Meaning |
|---|---|---|
| `needs-triage` | `E99695` | Maintainer needs to evaluate this issue. |
| `needs-info` | `F9D0C4` | Waiting on the reporter for more information. |
| `ready-for-agent` | `2E8B57` | Fully specified, ready for an unattended agent to pick up. |
| `ready-for-human` | `6F42C1` | Requires human implementation. |
| `wontfix` | `ffffff` | Will not be actioned. |

`wontfix` predates this scheme in both repos and is left at GitHub's default colour.

## Additive, never a substitute

A triage label answers *what happens to this issue next*.
Priority, type and area answer *what this issue is*.

They are orthogonal, so applying a triage label never means removing or substituting one of the others.
A well-formed issue carries a priority, a type, and — while in flight — a triage state.

## Two near-collisions worth naming

Reaching for the taxonomy label instead of the triage one loses information in both of these cases.

`question` is a **type** — "further information is requested" as a permanent classification of what the issue is.
`needs-info` is a **state** — "blocked on the reporter right now".
An issue can be `question` + `ready-for-human`, or `bug` + `needs-info`.

`wontfix` is the one label serving both roles at once.
Applying it is a terminal decision, not a state to move out of.

## Checking compliance

A triage state is optional, so there is nothing to assert about issues that carry none.
What is worth catching is an issue carrying two, which means the state was changed without the old one being removed.

```sh
R=RonenMars/threadbase-streamer   # or threadbase-mobile, or any adopting repo

gh issue list --state open --limit 200 --json number,labels -R "$R" \
  -q '.[] | select((.labels|map(.name)|map(select(test("^(needs-triage|needs-info|ready-for-agent|ready-for-human)$")))|length) > 1) | .number'
```
