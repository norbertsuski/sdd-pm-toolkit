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

# desc_hash <file>: first 12 hex chars of the sha256 of the rendered description text.
desc_hash() {
  python3 -c 'import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest()[:12])' "$1"
}

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

# --- BS: description hash (first 12 hex of sha256 of the rendered description text) ---
bs_tmp=$(mktemp -d)
printf 'abc' > "$bs_tmp/desc.txt"
assert_eq BS-hash-known-vector ba7816bf8f01 "$(desc_hash "$bs_tmp/desc.txt")"
printf 'abd' > "$bs_tmp/desc2.txt"
assert_eq BS-hash-differs-on-change yes "$([[ "$(desc_hash "$bs_tmp/desc.txt")" != "$(desc_hash "$bs_tmp/desc2.txt")" ]] && echo yes || echo no)"

# --- BS: the Jira CSV export script embedded in SKILL.md (RFC 4180 quoting, exact columns) ---
BS_SKILL=skills/pm-backlog-sync/SKILL.md
bs_csv_script() {
  [[ -f "$BS_SKILL" ]] || return 0
  python3 -c 'import sys,re
s=open(sys.argv[1]).read()
m=re.search(re.escape("<!-- pm-backlog-sync:csv-script -->")+r"\n```bash\npython3 -c \x27([^\x27]*)\x27 [^\n]*\n```",s,re.S)
sys.stdout.write(m.group(1) if m else "")' "$BS_SKILL"
}
BS_CSV_PY=$(bs_csv_script)
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
