#!/usr/bin/env bash
# Contract drift check: does a local sdd-toolkit checkout still contain every
# heading, column and key the PM skills rely on?
#
#   bash scripts/check-sdd-contract.sh /path/to/sdd-toolkit
#
# Reads every <!-- name:start --> ... <!-- name:end --> block of
# skills/pm-help/references/sdd-contract.md, extracts the strings (one
# "- `<string>`" per line; string = text between the first "- `" and the last
# backtick), and greps each one (fixed string) under <path>/skills/.
# Prints "drift: <string>" for every miss. Exit 0 = no drift, 1 = drift,
# 2 = usage error. Manual, read-only: never writes anything.

set -u
cd "$(dirname "$0")/.." || exit 1

if [[ $# -ne 1 || ! -d "$1/skills" ]]; then
  echo "usage: bash scripts/check-sdd-contract.sh <path-to-sdd-toolkit>  (needs <path>/skills/)" >&2
  exit 2
fi
target="$1/skills"
contract=skills/pm-help/references/sdd-contract.md
[[ -f "$contract" ]] || { echo "missing $contract" >&2; exit 2; }

drift=0
checked=0
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

if [[ $drift -eq 0 ]]; then
  echo "check-sdd-contract: no drift ($checked strings found under $target)"
else
  echo "check-sdd-contract: DRIFT DETECTED (see lines above; contract pins sdd_skills_version 0.4.1)"
fi
exit $drift
