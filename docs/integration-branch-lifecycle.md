# Integration branches — lifecycle and stale-ref audit

**Canonical for every Threadbase component repository.**
The `integration-branch` skill in each repo operates under this rule and cites this file.

## An integration branch is a staging area with an expiry

It exists to **test a set of pull requests together**, and it is deleted once `main` holds its content.
Deleting it costs nothing while a backup ref points at the same commit.

Three consequences:

- **Never develop on it.** The moment a fix is committed to the integration branch rather than to the pull request that needs it, it has stopped being a staging area and become a second trunk — one nobody reviews and nothing lands from.
- **A run is not finished when the branch is green; it is finished when the branch is gone.** Name the condition under which it is deleted, and who deletes it.
- **If the plan is to land pull requests one at a time onto `main`, an integration branch is the wrong tool.** That is a different procedure and needs no such branch, though it still deserves a log and a summary.

`threadbase-mobile` retired its long-lived integration branch on 2026-08-12 and landed all 20 open pull requests onto `main` individually instead.
The decision, the refs deleted and the per-ref audit results are recorded in [`threadbase-mobile/docs/integration-branch-retirement-2026-08-12.md`](https://github.com/RonenMars/threadbase-mobile/blob/main/docs/integration-branch-retirement-2026-08-12.md).
That document is the origin of the rule above and stays in that repo, because the history is that repo's.

## The audit that makes deletion safe

The question for each ref is **not** "is it merged".
None of these refs are ancestors of `main`, because every pull request that fed them was squash-merged under a new SHA.

The question is **does it hold a file that `main` has never had.**

```bash
# for each candidate ref: files present there and absent from main, ignoring docs
git diff --diff-filter=A --name-only origin/main "$REF" | grep -v '^docs/' |
while read -r f; do
  # empty result = main never deleted it = main never had it
  [ -z "$(git log --diff-filter=D -1 --format=%h origin/main -- "$f")" ] && echo "NEVER on main: $f"
done
```

Across the 16 surviving integration-named refs in the 2026-08-12 audit, zero files were ever unlanded.

## Two checks that return a confident wrong answer

Both were hit during that audit, and neither fails loudly.

**A branch-name glob is a filter, not an inventory.**
`git branch -a --list '*integration/*'` reported zero remaining branches, and that was reported as fact.
It matches only refs containing a literal `integration/`, so every hyphenated name — `integration-merge-…`, `integration-dev-…`, `land/integration-prep` — was invisible to it.
The true count was 23 refs.
Use `git branch -a | grep -i <word>` when the question is "what exists", and reserve globs for when the pattern *is* the question.

**"Not an ancestor of `main`" does not mean "unlanded".**
Squash-merging gives the landed content a new SHA, so ancestry calls every merged pull request unlanded.
The file-level test above is what actually answers it.
The same trap applies to comparing a pull request against a branch by filename rather than by content.
