#!/usr/bin/env bash
# Deterministic reference cases for the PM skills' decision rules.
# Each section below holds one skill's reference function(s) and the asserts that pin
# the contract the skill's SKILL.md describes. Run from anywhere:
#
#   bash scripts/validate-pm-evals.sh
#
# Exits non-zero on any failing assert. Append new sections (one per skill) above the
# summary block; keep the helpers in "Shared helpers" untouched.

set -u
cd "$(dirname "$0")/.." || exit 1

# ============================ Shared helpers ============================
fail=0
assert_eq() {
  local id="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "  ok: $id -> $actual"
  else
    echo "FAIL: $id expected '$expected', got '$actual'"
    fail=1
  fi
}

# ===================== pm-backlog-sync (Task 9) =========================

# sync_action <in_roadmap> <in_map> <tracker_exists> <changed>  (each yes|no)
# The decision table pm-backlog-sync's SKILL.md uses per Backlog Handoff row / map row.
# tracker_exists is only meaningful when in_map=yes; changed only when the issue exists.
sync_action() {
  local in_roadmap="$1" in_map="$2" tracker_exists="$3" changed="$4"
  if [[ "$in_roadmap" == yes && "$in_map" == no ]]; then echo create
  elif [[ "$in_roadmap" == yes && "$in_map" == yes && "$tracker_exists" == no ]]; then echo relink-ask
  elif [[ "$in_roadmap" == yes && "$in_map" == yes && "$changed" == no ]]; then echo skip
  elif [[ "$in_roadmap" == yes && "$in_map" == yes ]]; then echo update
  elif [[ "$in_roadmap" == no && "$in_map" == yes ]]; then echo orphan
  else echo none
  fi
}

# embedded_script <skill file> <marker>: the python3 -c script in the fenced block after "<!-- marker -->" in a SKILL.md
# (block layout: marker line, ```bash, python3 -c '...' args, ```; the script contains no single quote).
embedded_script() {
  [[ -f "$1" ]] || return 0
  python3 -c 'import sys,re
s=open(sys.argv[1]).read()
m=re.search(re.escape("<!-- "+sys.argv[2]+" -->")+r"\n```bash\npython3 -c \x27([^\x27]*)\x27 [^\n]*\n```",s,re.S)
sys.stdout.write(m.group(1) if m else "")' "$1" "$2"
}

BS_SKILL=skills/pm-backlog-sync/SKILL.md
# desc_hash <file>: the normalizing hash command from SKILL.md Step 4 (first 12 hex of sha256).
BS_HASH_PY=$(embedded_script "$BS_SKILL" pm-backlog-sync:hash-script)
desc_hash() { python3 -c "$BS_HASH_PY" "$1"; }

# --- BS: sync_action decision table ---
assert_eq BS-sync-create create "$(sync_action yes no no no)"
assert_eq BS-sync-skip skip "$(sync_action yes yes yes no)"
assert_eq BS-sync-update update "$(sync_action yes yes yes yes)"
assert_eq BS-sync-relink relink-ask "$(sync_action yes yes no no)"
assert_eq BS-sync-relink-ignores-changed relink-ask "$(sync_action yes yes no yes)"
assert_eq BS-sync-orphan orphan "$(sync_action no yes yes no)"
assert_eq BS-sync-orphan-issue-gone orphan "$(sync_action no yes no no)"
assert_eq BS-sync-create-ignores-tracker create "$(sync_action yes no yes yes)"
assert_eq BS-sync-nothing none "$(sync_action no no no no)"

# --- BS: description hash (normalized text; first 12 hex of sha256) ---
bs_tmp=$(mktemp -d)
assert_eq BS-hash-script-found yes "$([[ -n "$BS_HASH_PY" ]] && echo yes || echo no)"
printf 'abc\n' > "$bs_tmp/a.txt"
assert_eq BS-hash-known-vector edeaaff3f177 "$(desc_hash "$bs_tmp/a.txt")"
printf 'abc' > "$bs_tmp/no-final-newline.txt"
printf 'abc\n\n\n' > "$bs_tmp/many-final-newlines.txt"
printf 'abc  \r\n' > "$bs_tmp/crlf-trailing-space.txt"
printf 'abc\r' > "$bs_tmp/cr.txt"
for v in no-final-newline many-final-newlines crlf-trailing-space cr; do
  assert_eq "BS-hash-normalized-$v" "$(desc_hash "$bs_tmp/a.txt")" "$(desc_hash "$bs_tmp/$v.txt")"
done
printf 'Outcome: x\n\n\n\nChange ID: y\n' > "$bs_tmp/blank-runs.txt"
printf 'Outcome: x\n\nChange ID: y\n' > "$bs_tmp/one-blank.txt"
assert_eq BS-hash-blank-runs-collapse "$(desc_hash "$bs_tmp/one-blank.txt")" "$(desc_hash "$bs_tmp/blank-runs.txt")"
printf 'abd\n' > "$bs_tmp/changed.txt"
assert_eq BS-hash-differs-on-change yes "$([[ "$(desc_hash "$bs_tmp/a.txt")" != "$(desc_hash "$bs_tmp/changed.txt")" ]] && echo yes || echo no)"
printf 'a b\n' > "$bs_tmp/inner.txt"
printf 'a  b\n' > "$bs_tmp/inner2.txt"
assert_eq BS-hash-inner-space-is-content yes "$([[ "$(desc_hash "$bs_tmp/inner.txt")" != "$(desc_hash "$bs_tmp/inner2.txt")" ]] && echo yes || echo no)"

# --- BS: the Jira CSV export script embedded in SKILL.md (RFC 4180 quoting, exact columns) ---
BS_CSV_PY=$(embedded_script "$BS_SKILL" pm-backlog-sync:csv-script)
assert_eq BS-csv-script-found yes "$([[ -n "$BS_CSV_PY" ]] && echo yes || echo no)"
if [[ -n "$BS_CSV_PY" ]]; then
  cat > "$bs_tmp/rows.json" <<'JSON'
[{"summary":"Rank recipes, by fridge match","type":"Story","description":"Outcome: a, b\n\nGiven \"x\", When y\nChange ID: recipe-match","label":"sdd:recipe-match"},
 {"summary":"Add sign-in","type":"Task","description":"Outcome: sign-in","label":"sdd:auth-scaffold"}]
JSON
  python3 -c "$BS_CSV_PY" "$bs_tmp/out.csv" < "$bs_tmp/rows.json" > /dev/null
  assert_eq BS-csv-header "Summary,Issue Type,Description,Labels" "$(head -1 "$bs_tmp/out.csv" | tr -d '\r')"
  assert_eq BS-csv-roundtrip "2|Rank recipes, by fridge match|Story|Outcome: a, b

Given \"x\", When y
Change ID: recipe-match|sdd:recipe-match" "$(python3 -c 'import csv,sys
r=list(csv.reader(open(sys.argv[1],newline="")))
d=r[1]
print(len(r)-1,d[0],d[1],d[2],d[3],sep="|")' "$bs_tmp/out.csv")"
  assert_eq BS-csv-crlf-rows 3 "$(python3 -c 'import sys;print(open(sys.argv[1],"rb").read().count(b"\r\n"))' "$bs_tmp/out.csv")"
fi
rm -rf "$bs_tmp"

# ============================== Summary ================================
if [[ $fail -eq 0 ]]; then
  echo "validate-pm-evals: ALL CASES PASSED"
else
  echo "validate-pm-evals: FAILURES ABOVE"
fi
exit $fail
