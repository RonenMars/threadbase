# Plan: Automated Claude PR Reviews Across Repositories

Status: proposed. Not yet implemented in any repository.

## Goal

Give a solo indie developer a reusable, low-maintenance setup for automated
Claude Code PR reviews, deployable across roughly 20 selected GitHub
repositories (not all repos).

Requirements:

- Automatically review every non-draft pull request.
- Automatically re-review whenever new commits are pushed to the PR.
- Allow manual re-review by commenting `/review`.
- Keep reviews minimal, fast, and inexpensive.
- Roll out to ~20 selected repositories via script, not by hand.
- Easy to maintain: one workflow file, copied everywhere, updated centrally.

Non-goals:

- This does not block merges or act as a required check.
- This does not replace human review.
- This does not roll out to every repository the owner has — only an
  explicit allowlist.

## Deliverables

Five files, described below. Implementation (writing the actual files) is a
separate follow-up task from this plan.

### 1. `.github/workflows/claude-pr-review.yml`

The reusable workflow, copied into each target repository.

**Action:** `anthropics/claude-code-action@v1`

**Permissions:**

```yaml
permissions:
  contents: read
  pull-requests: write
  issues: write
```

**Concurrency** (cancel superseded reviews on the same PR):

```yaml
concurrency:
  group: claude-pr-review-${{ github.event.pull_request.number || github.event.issue.number }}
  cancel-in-progress: true
```

**Triggers:**

```yaml
on:
  pull_request:
    types: [opened, reopened, ready_for_review, synchronize]
  issue_comment:
    types: [created]
  workflow_dispatch:
```

**Job condition** — runs only for non-draft PRs, `/review` comments on a PR,
or a manual dispatch:

```yaml
jobs:
  review:
    if: |
      github.event_name == 'workflow_dispatch' ||
      (
        github.event_name == 'pull_request' &&
        github.event.pull_request.draft == false
      ) ||
      (
        github.event_name == 'issue_comment' &&
        github.event.issue.pull_request != null &&
        contains(github.event.comment.body, '/review')
      )
    runs-on: ubuntu-latest
```

**Claude action configuration:**

- Auth via repository secret `ANTHROPIC_API_KEY`.
- Sticky comment enabled (one comment updated in place, not a new comment
  per run).
- "Fix links" disabled.
- `--max-turns 3` to bound cost.

**Review prompt** — minimal, cost-conscious, changed-code-only review:

- Look at the diff only, not the whole repo.
- Flag: obvious bugs, broken logic, risky edge cases, accidental security
  issues, important missing tests.
- Do not: nitpick formatting, comment on style, suggest naming changes,
  recommend large refactors, or rewrite code unnecessarily.
- If nothing meaningful is found, respond with exactly `No major issues
  found.`
- Output format, capped for brevity:
  - Summary (1–2 bullets)
  - Issues (max 5 bullets)
  - Severity: High / Medium / Low per issue

Before implementing, verify the exact input names and defaults for
`anthropics/claude-code-action@v1` (sticky-comment flag, fix-links flag,
max-turns flag, prompt input) against the action's current README/marketplace
listing — flag names and defaults can change between versions.

### 2. `repos.txt`

Plain allowlist of target repositories, one `OWNER/REPOSITORY` per line.
Blank lines and lines starting with `#` are ignored by the tooling.

```text
# Replace these with your own repositories

myuser/project-a
myuser/project-b
myuser/project-c
```

### 3. `rollout-claude-review.sh`

Bash script (`set -euo pipefail`, macOS-compatible) that installs the
workflow into every repo listed in `repos.txt`:

1. Read `repos.txt`, skipping blank lines and `#` comments.
2. For each repo:
   - Clone it (shallow, temp dir) via `gh repo clone`.
   - Create/checkout branch `add-claude-pr-review`.
   - Create `.github/workflows/` if missing.
   - Copy `claude-pr-review.yml` into
     `.github/workflows/claude-pr-review.yml`.
   - If the file is unchanged (identical content already present), skip
     this repo with a clear message — no empty commit, no PR.
   - Commit, push the branch, open a PR via `gh pr create`.
3. Handle gracefully, without aborting the whole run:
   - Workflow file already exists and is identical → skip.
   - No changes to commit → skip.
   - Branch `add-claude-pr-review` already exists (local or remote) → reuse
     it or report and skip, rather than failing.
   - Repository clone failure (bad name, no access) → report and continue
     to the next repo.
4. Print a clear per-repo progress line and a final summary (created /
   skipped / failed counts).

### 4. `set-anthropic-secret.sh`

Bash script that provisions the `ANTHROPIC_API_KEY` repository secret across
the same repo list:

1. Read the key from `~/.secrets/anthropic_api_key.txt`.
2. Validate the file exists and is non-empty before doing anything.
3. Read `repos.txt` (same parsing rules as above).
4. For each repo, run:

   ```bash
   gh secret set ANTHROPIC_API_KEY --repo "$repo" < ~/.secrets/anthropic_api_key.txt
   ```

5. Print progress per repo and report failures without aborting the whole
   run.

### 5. `README.md`

Usage documentation for the rollout tooling, covering:

- **Overview** — what the setup does, why every non-draft PR is reviewed
  automatically, why `/review` still matters for manual reruns (e.g. after
  addressing feedback without pushing new commits, or re-running after a
  transient failure).
- **Installation** — install `gh`, `gh auth login`, create
  `~/.secrets/anthropic_api_key.txt`, populate `repos.txt`, run
  `./set-anthropic-secret.sh`, then `./rollout-claude-review.sh`.
- **Usage** — opening a PR triggers Claude; every push re-triggers it;
  commenting `/review` forces a rerun; `workflow_dispatch` is available for
  manual runs from the Actions tab.
- **Warnings**:
  - Never commit the Anthropic API key to any repo; it lives only in
    GitHub Secrets.
  - Start with ~5 repositories before rolling out to all ~20.
  - This workflow assists review — it does not block merges and is not a
    required status check.

## Quality bar for implementation

- Simple, clean, maintainable Bash — no unnecessary abstraction.
- Prefer official `gh` CLI commands over raw API calls.
- Follow current GitHub Actions best practices (least-privilege
  permissions, pinned action version, concurrency control).
- Verify the action configuration against the latest
  `anthropics/claude-code-action` documentation at implementation time
  rather than relying on this plan's syntax going stale.

## Open questions for implementation time

- Where do these five files live long-term? Candidates: a new
  `threadbase-tooling`-style repo, or a `tools/claude-pr-review/` directory
  in an existing repo the owner controls. This plan does not decide that —
  it's an implementation-time choice.
- Confirm the exact `repos.txt` location the scripts expect (same directory
  vs. configurable path).
