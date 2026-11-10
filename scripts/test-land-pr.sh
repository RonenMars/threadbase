#!/usr/bin/env bash
# Self-check for plugins/threadbase-skills/skills/integration-by-batches/land-pr.sh.
# A throwaway origin repo plus a stub `gh` drive every guard; nothing touches GitHub.
#   bash scripts/test-land-pr.sh
set -u
land=$(cd "$(dirname "$0")/../plugins/threadbase-skills/skills/integration-by-batches" && pwd)/land-pr.sh
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
export GIT_CONFIG_GLOBAL=/dev/null LAND_POLL=0 STUB="$T/stub"
mkdir -p "$STUB" "$T/bin"

cat >"$T/bin/gh" <<'EOF'
#!/usr/bin/env bash
# Stub gh: answers only the calls land-pr.sh makes, from files in $STUB.
head=$(git --git-dir="$STUB/../origin.git" rev-parse refs/heads/feat)
case "$*" in
  "pr view"*headRefName*) echo "$(cat "$STUB/state" 2>/dev/null || echo OPEN) $(cat "$STUB/draft" 2>/dev/null || echo false) $head feat";;
  "pr view"*headRefOid*) echo "$head";;
  "pr list"*) cat "$STUB/children" 2>/dev/null; echo;;
  "pr checks"*) cat "$STUB/checks" 2>/dev/null || echo "3 0 0";;
  "pr merge"*) touch "$STUB/merged";;
  api*mergeable_state*) cat "$STUB/ms" 2>/dev/null || echo clean;;
  api*merged*) [ -e "$STUB/merged" ] && echo "true abc123" || echo "false null";;
  *) echo "stub gh: unexpected $*" >&2; exit 1;;
esac
EOF
chmod +x "$T/bin/gh"
export PATH="$T/bin:$PATH"

git init -q --bare "$T/origin.git"
git clone -q "$T/origin.git" "$T/w" 2>/dev/null; cd "$T/w" || exit 1
echo base >f; git add f; git commit -qm "chore: base"; git push -q origin HEAD:main
git checkout -qb feat; echo pr >g; git add g; git commit -qm "feat: pr"; git push -q origin feat
qa=$(git rev-parse HEAD)
git checkout -q main; echo other >h; git add h; git commit -qm "fix: other"; git push -q origin main; git checkout -q feat

log="$T/log.md"
fail=0
expect() { # $1 = wanted RESULT word, rest = land-pr.sh args
  want=$1; shift
  got=$(bash "$land" "$@" 2>&1 | tail -1)
  case "$got" in "RESULT=$want"*) echo "ok   $want";; *) echo "FAIL want $want, got: $got"; fail=1;; esac
}
reset() { git rebase --abort 2>/dev/null; git checkout -q -f feat; git reset -q --hard "$qa"; git push -qf origin "$qa:refs/heads/feat"; rm -f "$STUB"/*; }

: >"$log"
expect USAGE 7
expect HELD 7 --log "$log"                                    # no qa_head line
echo "qa_head: B1 #7 $qa" >"$log"
expect HELD 7 --log "$log"                                    # no verdict
echo 'qa_verdict: B1 approved 2026-11-10T19:00 build 123 "works"' >>"$log"
echo CLOSED >"$STUB/state"; expect HELD 7 --log "$log"; reset
echo true >"$STUB/draft"; expect HELD 7 --log "$log"; reset

echo dirty >>g; expect DIRTY 7 --log "$log"; reset
git checkout -q -b other; expect DIRTY 7 --log "$log"; git checkout -q feat; git branch -qD other
echo amended >g; git commit -qam "feat: amended"; expect DIRTY 7 --log "$log"; reset   # changes differ from QA
echo 12 >"$STUB/children"; expect CHILDREN 7 --log "$log"; reset

expect TESTS 7 --log "$log" --test false; reset
expect READY 7 --log "$log" --test true
expect READY 7 --log "$log" --test false                      # rebased HEAD already tested, same patch
reset

echo "1 0 1" >"$STUB/checks"; expect RED 7 --log "$log" --yes; reset
echo behind >"$STUB/ms"; expect STALE 7 --log "$log" --yes
rm -f "$STUB/ms"; expect MERGED 7 --log "$log" --yes        # the rerun accepts its own pushed rebase
reset
git checkout -q -b moved; echo moved >g; git commit -qam "feat: moved"; git push -qf origin moved:feat
git checkout -q feat; git branch -qD moved; expect HELD 7 --log "$log"; reset   # someone pushed new code after QA
echo "1 0 0" >"$STUB/checks"; LAND_TIMEOUT=2 expect TIMEOUT 7 --log "$log" --yes --min-checks 5; reset
expect MERGED 7 --log "$log" --yes --min-checks 3; reset

# A branch whose changes are already on main rebases to 0 commits: pushing it would close the PR.
git checkout -q main; git merge -q --no-edit feat; git push -q origin main; git checkout -q feat
expect EMPTY 7 --log "$log" --yes; reset

[ "$fail" = 0 ] && echo "all passed" || { echo "FAILED"; exit 1; }
