#!/bin/sh
# Mirror the threadbase-skills plugin skills into a repo's .agents/skills/ and print a content hash.
#   sync-agents-skills.sh [dest]        copy skills into dest (default .agents/skills), print the hash of dest
#   sync-agents-skills.sh --hash [dir]  print the hash of dir (default: the plugin's skills/), copy nothing
# The hash covers only the skills that exist in the plugin, so a repo's local skills in dest do not change it.
# CI in a sibling repo: [ "$(sync-agents-skills.sh --hash)" = "$(sync-agents-skills.sh --hash .agents/skills)" ]
set -eu
src=$(cd "$(dirname "$0")/../plugins/threadbase-skills/skills" && pwd)

hash() { # $1 = dir
  for n in $(ls "$src"); do (cd "$1" && find "$n" -type f 2>/dev/null); done | LC_ALL=C sort |
    while IFS= read -r f; do (cd "$1" && shasum -a 256 "$f"); done | shasum -a 256 | cut -d' ' -f1
}

if [ "${1:-}" = "--hash" ]; then hash "${2:-$src}"; exit; fi
dest=${1:-.agents/skills}
for n in $(ls "$src"); do rm -rf "${dest:?}/$n"; mkdir -p "$dest"; cp -R "$src/$n" "$dest/$n"; done
hash "$dest"
