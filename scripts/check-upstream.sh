#!/usr/bin/env bash
# Upstream check: has the source repository changed since the vendored skills were
# taken from it, and does it still contain every heading, column and key the PM
# skills rely on? Manual maintainer tool, never run by CI or by a skill.
#
#   bash scripts/check-upstream.sh /path/to/source-checkout
#
# Two passes, both read-only (nothing is written, nothing is checked out):
#
#  1. Contract drift. Reads every <!-- name:start --> ... <!-- name:end --> block
#     of skills/pm-help/references/artifact-contract.md, extracts the strings (one
#     "- `<string>`" per line; string = text between the first "- `" and the last
#     backtick) and greps each one (fixed string) under <path>/skills/.
#     Prints "drift: <string>" for every miss.
#  2. Upstream changes since vendoring. VENDORED.md records, for every vendored
#     file, its source file (relative to the source repository root) and the commit
#     it was taken at. For each row this runs
#       git -C <path> diff --stat <commit>..HEAD -- <source file>
#     and prints "changed upstream: <source file>" plus the stat for every file
#     that differs. Committed history only: uncommitted edits in the checkout are
#     not looked at.
#
# Exit 0 = clean, 1 = contract drift and/or upstream changes, 2 = usage error
# (wrong arguments, unreadable VENDORED.md or contract, not a git checkout, or a
# pinned commit the checkout does not know).

set -u
cd "$(dirname "$0")/.." || exit 1

usage() { echo "usage: bash scripts/check-upstream.sh <path-to-source-checkout>  (needs <path>/skills/ and a git checkout)" >&2; exit 2; }

[[ $# -eq 1 && -d "$1/skills" ]] || usage
src="$1"
target="$src/skills"
contract=skills/pm-help/references/artifact-contract.md
vendored=VENDORED.md
[[ -f "$contract" ]] || { echo "missing $contract" >&2; exit 2; }
[[ -f "$vendored" ]] || { echo "missing $vendored" >&2; exit 2; }
git -C "$src" rev-parse --git-dir >/dev/null 2>&1 || { echo "$src is not a git checkout (needed for the upstream-changes pass)" >&2; exit 2; }

drift=0
checked=0

# --- pass 1: contract strings ------------------------------------------------
blocks=$(sed -n -E 's/^<!-- ([a-z-]+):start -->$/\1/p' "$contract")
[[ -n "$blocks" ]] || { echo "no marker blocks found in $contract" >&2; exit 2; }

for b in $blocks; do
  while IFS= read -r s; do
    checked=$((checked + 1))
    if ! grep -rqF -- "$s" "$target"; then
      echo "drift: $s   [block: $b]"
      drift=1
    fi
  done < <(awk -v n="$b" '
      $0 == "<!-- " n ":start -->" {on=1; next}
      $0 == "<!-- " n ":end -->"   {on=0}
      on' "$contract" | sed -n -E 's/^- `(.*)`[[:space:]]*$/\1/p')
done

# --- pass 2: source files changed since the pinned commit ----------------------
# Table rows of VENDORED.md:  | `<pm file>` | `<source file>` | `<commit>` | notes |
# (the header and separator rows have no backticks in column 3 and are skipped).
rows=$(awk -F'|' '
  function clean(x) { gsub(/^[ \t]*`?|`?[ \t]*$/, "", x); return x }
  NF >= 5 && clean($4) ~ /^[0-9a-f]{7,40}$/ { print clean($4) "\t" clean($3) }' "$vendored")
[[ -n "$rows" ]] || { echo "no vendored source rows (file, source, commit) found in $vendored" >&2; exit 2; }

changed=0
files=0
while IFS=$'\t' read -r commit file; do
  [[ -n "$commit" && -n "$file" ]] || continue
  git -C "$src" cat-file -e "${commit}^{commit}" 2>/dev/null \
    || { echo "pinned commit $commit (from $vendored) is not in $src" >&2; exit 2; }
  files=$((files + 1))
  stat=$(git -C "$src" diff --stat "$commit..HEAD" -- "$file" 2>&1)
  if [[ -n "$stat" ]]; then
    echo "changed upstream: $file   [since $commit]"
    echo "$stat" | sed 's/^/    /'
    changed=$((changed + 1))
  fi
done <<< "$rows"

# --- summary -------------------------------------------------------------------
status=0
if [[ $drift -ne 0 ]]; then
  echo "check-upstream: CONTRACT DRIFT (see 'drift:' lines above; $checked strings checked under $target)"
  status=1
else
  echo "check-upstream: no contract drift ($checked strings found under $target)"
fi
if [[ $changed -ne 0 ]]; then
  echo "check-upstream: $changed of $files vendored source files changed upstream since vendoring (see above); review the diffs, port what is wanted, then update VENDORED.md"
  status=1
else
  echo "check-upstream: no upstream changes since vendoring ($files source files compared)"
fi
exit $status
