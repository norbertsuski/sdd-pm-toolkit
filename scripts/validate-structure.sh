#!/usr/bin/env bash
# Static structural validation for the sdd-pm-skills plugin.
# Checks the mechanical invariants that keep the PM skill family consistent —
# manifests, frontmatter presence, skill counts in the README, and link
# resolution. Run from the repo root:
#
#   bash scripts/validate-structure.sh
#
# Exits non-zero on any failure. Extend this file when adding a skill or a
# cross-skill contract: append new numbered checks before the summary block.

set -u
cd "$(dirname "$0")/.." || exit 1
shopt -s nullglob

fail=0
err() { echo "FAIL: $*"; fail=1; }
ok()  { echo "  ok: $*"; }

# JSON field reader: json_get <file> <python-expression-on-d>; prints result or nothing.
json_get() {
  python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
print(eval(sys.argv[2]))' "$1" "$2" 2>/dev/null
}

# --- 1. plugin.json parses, carries a semver version and the right name -
if [[ -f .claude-plugin/plugin.json ]]; then
  version=$(json_get .claude-plugin/plugin.json 'd["version"]')
  pname=$(json_get .claude-plugin/plugin.json 'd["name"]')
  if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    ok "plugin.json valid, version $version"
  else
    err "plugin.json missing or malformed version (got: '$version')"
  fi
  [[ "$pname" == "sdd-pm-skills" ]] \
    && ok "plugin.json name is sdd-pm-skills" \
    || err "plugin.json name must be 'sdd-pm-skills' (got: '$pname')"
else
  err "plugin.json missing (.claude-plugin/plugin.json)"
fi

# --- 2. marketplace.json parses and lists the plugin --------------------
if [[ -f .claude-plugin/marketplace.json ]]; then
  mname=$(json_get .claude-plugin/marketplace.json 'd["name"]')
  msrc=$(json_get .claude-plugin/marketplace.json '[p["source"] for p in d["plugins"] if p["name"]=="sdd-pm-skills"][0]')
  [[ "$mname" == "sdd-pm-toolkit" ]] \
    && ok "marketplace.json name is sdd-pm-toolkit" \
    || err "marketplace.json name must be 'sdd-pm-toolkit' (got: '$mname')"
  [[ "$msrc" == "./" ]] \
    && ok "marketplace.json lists sdd-pm-skills with source ./" \
    || err "marketplace.json needs plugin entry sdd-pm-skills with source './' (got: '$msrc')"
else
  err "marketplace.json missing (.claude-plugin/marketplace.json)"
fi

# --- 3. every skill folder has SKILL.md with matching name frontmatter --
count=0
for dir in skills/pm-*/; do
  name=$(basename "$dir")
  count=$((count + 1))
  if [[ ! -f "$dir/SKILL.md" ]]; then
    err "$name has no SKILL.md"
    continue
  fi
  head -5 "$dir/SKILL.md" | grep -q "^name: $name$" \
    || err "$name/SKILL.md frontmatter name does not match folder"
  grep -q "^description:" "$dir/SKILL.md" \
    || err "$name/SKILL.md has no description frontmatter"
done
ok "$count skill folders, each with name-matching SKILL.md"

# --- 4. skill count and table rows consistent in the README -------------
needle="(${count} \`pm-*\` skills)"
grep -qF -- "$needle" README.md \
  && ok "README mentions the count: '$needle'" \
  || err "README does not carry the current skill count ('$needle' not found)"
for dir in skills/pm-*/; do
  name=$(basename "$dir")
  grep -qF -- "| \`$name\`" README.md \
    || err "README skills table has no row for $name"
done
ok "all skills have a README table row"

# --- 5. no cross-plugin relative links under skills/ --------------------
if [[ -d skills ]]; then
  if grep -rEn '\.\./sdd-[a-z-]+/' skills/ ; then
    err "skills/ contains relative links into ../sdd-*/ (cross-plugin links are forbidden)"
  else
    ok "no ../sdd-*/ links under skills/"
  fi
else
  ok "no skills/ directory yet, nothing to check for cross-plugin links"
fi

# --- 6. relative .md links in every SKILL.md resolve --------------------
for dir in skills/pm-*/; do
  skill=$(basename "$dir")
  [[ -f "$dir/SKILL.md" ]] || continue
  while IFS= read -r link; do
    resolved=$(cd "$dir" 2>/dev/null && cd "$(dirname "$link")" 2>/dev/null && pwd)/$(basename "$link")
    [[ -f "$resolved" ]] || err "$skill/SKILL.md dangling relative link: $link"
  done < <(grep -oE '(\.\./|references/)[A-Za-z0-9/._-]+\.md' "$dir/SKILL.md" | sort -u)
done
ok "relative .md links in SKILL.md files resolve"

# --- 7. CI runs this validator ------------------------------------------
[[ -f .gitlab-ci.yml ]] \
  && grep -q "bash scripts/validate-structure.sh" .gitlab-ci.yml \
  && ok "GitLab CI runs the structural validator" \
  || err ".gitlab-ci.yml does not run bash scripts/validate-structure.sh"

# --- 8. pm-help shared references exist ---------------------------------
HELP_REFS=skills/pm-help/references
for f in context-resolution sdd-contract pm-artifacts integrations plain-language eval-cases; do
  [[ -f "$HELP_REFS/$f.md" ]] || err "missing shared reference: $HELP_REFS/$f.md"
done
[[ -f skills/pm-help/SKILL.md ]] || err "missing skills/pm-help/SKILL.md"
ok "pm-help shared reference files checked"

# --- 9. sdd-contract.md: pinned version, headings, parseable blocks -----
CONTRACT="$HELP_REFS/sdd-contract.md"
# contract_block <name>: strings between <!-- name:start --> and <!-- name:end -->.
# Extraction rule (shared with scripts/check-sdd-contract.sh): one entry per line
# in the form  - `<string>` ; the string is everything between the first "- `"
# and the LAST backtick on the line (so strings may contain backticks).
contract_block() {
  awk -v n="$1" '
    $0 == "<!-- " n ":start -->" {on=1; next}
    $0 == "<!-- " n ":end -->"   {on=0}
    on' "$CONTRACT" | sed -n -E 's/^- `(.*)`[[:space:]]*$/\1/p'
}
if [[ -f "$CONTRACT" ]]; then
  grep -qF "sdd_skills_version: 0.4.1" "$CONTRACT" \
    || err "sdd-contract.md must contain 'sdd_skills_version: 0.4.1'"
  for h in "## Version" "## Install block" "## Required skills" "## PRD contract" \
           "## Roadmap contract" "## Change contract" "## Contract check procedure"; do
    grep -qxF -- "$h" "$CONTRACT" || err "sdd-contract.md missing heading: $h"
  done
  for b in prd-greenfield:10 prd-brownfield:11 roadmap:10 roadmap-columns:1 change-keys:7 change-verdicts:5 prd-frontmatter:1; do
    bname=${b%%:*}; bmin=${b##*:}
    bn=$(contract_block "$bname" | wc -l | tr -d ' ')
    grep -qxF "<!-- $bname:start -->" "$CONTRACT" && grep -qxF "<!-- $bname:end -->" "$CONTRACT" \
      || err "sdd-contract.md missing markers for block '$bname'"
    [[ "$bn" -ge "$bmin" ]] || err "sdd-contract.md block '$bname' has $bn entries (expected >= $bmin)"
  done
  [[ "$(contract_block prd-greenfield | wc -l | tr -d ' ')" -eq 10 ]] || err "prd-greenfield block must have exactly 10 headings"
  [[ "$(contract_block prd-brownfield | wc -l | tr -d ' ')" -eq 11 ]] || err "prd-brownfield block must have exactly 11 headings"
  ok "sdd-contract.md pinned to 0.4.1 with parseable blocks"
else
  err "sdd-contract.md missing ($CONTRACT)"
fi

# --- 10. pm-help/SKILL.md: installed count, mentions every other skill --
if [[ -f skills/pm-help/SKILL.md ]]; then
  grep -qF "Installed in this plugin (${count})" skills/pm-help/SKILL.md \
    || err "pm-help/SKILL.md must contain 'Installed in this plugin (${count})'"
  for dir in skills/pm-*/; do
    name=$(basename "$dir")
    [[ "$name" == "pm-help" ]] && continue
    grep -qF "\`$name\`" skills/pm-help/SKILL.md \
      || err "pm-help/SKILL.md does not mention \`$name\`"
  done
  ok "pm-help lists the installed count and every other skill"
fi

# --- 11. shared reference structure (integrations, artifacts) -----------
if [[ -f "$HELP_REFS/integrations.md" ]]; then
  for h in "## Adapter detection" "## pm-config.yml" "## Write protocol" "## Messages" "## Export fallback"; do
    grep -qxF -- "$h" "$HELP_REFS/integrations.md" || err "integrations.md missing heading: $h"
  done
fi
if [[ -f "$HELP_REFS/pm-artifacts.md" ]]; then
  for p in 'research/*.md' 'prd-review-<date>.md' 'metrics.md' 'prioritization.md' 'forecast.md' \
           'tracker-map.md' 'status/<date>.md' 'pm-config.yml' 'exports/*'; do
    grep -qF -- "$p" "$HELP_REFS/pm-artifacts.md" || err "pm-artifacts.md has no row for $p"
  done
fi
ok "integrations.md headings and pm-artifacts.md rows checked"

# --- 12. fixture project conforms to the sdd contract -------------------
FIX=tests/fixtures/flat-root/context
FPRD=$FIX/foundation/recipe-fridge/prd.md
FRM=$FIX/foundation/recipe-fridge/roadmap.md
grep -qE '^layout:[[:space:]]*flat' "$FIX/.sdd.yml" 2>/dev/null || err "fixture $FIX/.sdd.yml missing or not 'layout: flat'"
if [[ -f "$FPRD" && -f "$CONTRACT" ]]; then
  while IFS= read -r h; do
    grep -qxF -- "$h" "$FPRD" || err "fixture prd.md missing greenfield heading: $h"
  done < <(contract_block prd-greenfield)
  while IFS= read -r k; do
    grep -qF -- "$k" "$FPRD" || err "fixture prd.md missing frontmatter key: $k"
  done < <(contract_block prd-frontmatter)
else
  err "fixture prd.md missing ($FPRD)"
fi
if [[ -f "$FRM" && -f "$CONTRACT" ]]; then
  while IFS= read -r h; do
    grep -qxF -- "$h" "$FRM" || err "fixture roadmap.md missing heading: $h"
  done < <(contract_block roadmap)
  while IFS= read -r c; do
    grep -qF -- "$c" "$FRM" || err "fixture roadmap.md missing column/field: $c"
  done < <(contract_block roadmap-columns)
else
  err "fixture roadmap.md missing ($FRM)"
fi
# archive folders: <created-date>-<change-id>, change.md stamped archived
for d in "$FIX"/archive/*/; do
  [[ -d "$d" ]] || continue
  aname=$(basename "$d")
  adate=${aname:0:10}
  [[ -f "$d/change.md" ]] || { err "fixture archive $aname has no change.md"; continue; }
  grep -qx "status: archived" "$d/change.md" || err "fixture archive $aname: status must be archived"
  grep -qx "created: $adate" "$d/change.md" || err "fixture archive $aname: created must equal folder date $adate"
  grep -q "^archived_at: " "$d/change.md" || err "fixture archive $aname: archived_at missing"
done
[[ -f "$FIX/changes/meal-plan/change.md" ]] && grep -qx "status: implementing" "$FIX/changes/meal-plan/change.md" \
  || err "fixture changes/meal-plan/change.md must exist with status: implementing"
ok "fixture prd, roadmap, archive and changes checked against the contract"

# --- 13. ownership line in every skill (R5) -----------------------------
OWN_ALL='Never writes `prd.md`, `shape-notes.md`, or `roadmap.md`.'
OWN_REVIEW='Never writes `shape-notes.md` or `roadmap.md`.'
for dir in skills/pm-*/; do
  name=$(basename "$dir")
  [[ -f "$dir/SKILL.md" ]] || continue
  if [[ "$name" == "pm-prd-review" ]]; then
    grep -qF -- "$OWN_REVIEW" "$dir/SKILL.md" || err "$name/SKILL.md missing ownership line: $OWN_REVIEW"
  else
    grep -qF -- "$OWN_ALL" "$dir/SKILL.md" || err "$name/SKILL.md missing ownership line: $OWN_ALL"
  fi
done
ok "ownership line present in every skill"

# --- 14. pm-research-synthesis: files, insights-format headings, eval ids
RS=skills/pm-research-synthesis
for f in SKILL.md references/insights-format.md references/eval-cases.md; do
  [[ -f "$RS/$f" ]] || err "missing $RS/$f"
done
if [[ -f "$RS/references/insights-format.md" ]]; then
  for h in "## Sources" "## Insights" "## Jobs to Be Done" "## Pains & Gains" \
           "## Contradictions & Surprises" "## Open Questions" "## Seed for shaping"; do
    grep -qxF -- "$h" "$RS/references/insights-format.md" || err "insights-format.md missing heading: $h"
  done
fi
if [[ -f "$RS/SKILL.md" ]]; then
  grep -qF "verbatim" "$RS/SKILL.md" || err "pm-research-synthesis/SKILL.md must mention 'verbatim'"
  grep -qF "P1" "$RS/SKILL.md" || err "pm-research-synthesis/SKILL.md must mention the 'P1' pseudonym scheme"
fi
if [[ -f "$RS/references/eval-cases.md" ]]; then
  for id in RS-01 RS-02 RS-03 RS-04 RS-05; do
    grep -qF "$id" "$RS/references/eval-cases.md" || err "pm-research-synthesis eval-cases.md missing $id"
  done
fi
ok "pm-research-synthesis files, headings and eval ids checked"

# --- 15. pm-discover: files, routed sdd skills, git mv, stack gate, eval ids, contract blocks
PD=skills/pm-discover
for f in SKILL.md references/eval-cases.md; do
  [[ -f "$PD/$f" ]] || err "missing $PD/$f"
done
if [[ -f "$PD/SKILL.md" ]]; then
  for s in '/sdd-init' '/sdd-frame' '/sdd-shape' '/sdd-prd' '/pm-prd-review' '/sdd-roadmap' \
           '/sdd-tech-stack-selector' '/sdd-stack-assess' '/sdd-health-check' \
           'git mv' 'checkpoint.current_phase' 'stack-pending' 'verdict: APPROVED'; do
    grep -qF -- "$s" "$PD/SKILL.md" || err "pm-discover/SKILL.md must mention '$s'"
  done
fi
if [[ -f "$PD/references/eval-cases.md" ]]; then
  for id in DS-01 DS-02 DS-03 DS-04 DS-05 DS-06 DS-07 DS-08; do
    grep -qF "$id" "$PD/references/eval-cases.md" || err "pm-discover eval-cases.md missing $id"
  done
fi
if [[ -f "$CONTRACT" ]]; then
  for b in shape-checkpoint:4 stack-signals:2; do
    bname=${b%%:*}; bmin=${b##*:}
    grep -qxF "<!-- $bname:start -->" "$CONTRACT" && grep -qxF "<!-- $bname:end -->" "$CONTRACT" \
      || err "sdd-contract.md missing markers for block '$bname'"
    [[ "$(contract_block "$bname" | wc -l | tr -d ' ')" -ge "$bmin" ]] \
      || err "sdd-contract.md block '$bname' has fewer than $bmin entries"
  done
fi
ok "pm-discover files, routed skills, stack gate, eval ids and contract blocks checked"

# --- 16. pm-prd-review: files, dimensions, mandate strings, report headings, eval ids
PR=skills/pm-prd-review
for f in SKILL.md references/review-dimensions.md references/eval-cases.md; do
  [[ -f "$PR/$f" ]] || err "missing $PR/$f"
done
if [[ -f "$PR/references/review-dimensions.md" ]]; then
  for d in "Problem clarity" "Measurability" "Scope discipline" "Completeness" "Testability" \
           "Traceability" "Open-question risk"; do
    grep -qF -- "$d" "$PR/references/review-dimensions.md" || err "review-dimensions.md must name dimension '$d'"
  done
  grep -qF "PASS" "$PR/references/review-dimensions.md" && grep -qF "CONCERNS" "$PR/references/review-dimensions.md" \
    && grep -qF "FAIL" "$PR/references/review-dimensions.md" \
    || err "review-dimensions.md must carry a PASS / CONCERNS / FAIL rubric"
fi
if [[ -f "$PR/SKILL.md" ]]; then
  for s in 'status: reviewed' 'never sets `locked`' '## Verdicts' '## Findings' '## Triage log' \
           'NEEDS_ATTENTION' 'CONTRACT MISMATCH' 'Contract check procedure' 'Move to Open Questions' \
           'Dismiss' 'Defer' 'Apply fix'; do
    grep -qF -- "$s" "$PR/SKILL.md" || err "pm-prd-review/SKILL.md must mention '$s'"
  done
fi
if [[ -f "$PR/references/eval-cases.md" ]]; then
  for id in PR-01 PR-02 PR-03 PR-04 PR-05 PR-06; do
    grep -qF "$id" "$PR/references/eval-cases.md" || err "pm-prd-review eval-cases.md missing $id"
  done
fi
if [[ -f "$HELP_REFS/pm-artifacts.md" ]]; then
  grep -F 'prd-review-<date>.md' "$HELP_REFS/pm-artifacts.md" | grep -qF 'verdict' \
    || err "pm-artifacts.md prd-review row must name the verdict frontmatter key"
fi
ok "pm-prd-review files, dimensions, mandate strings and eval ids checked"

# --- 17. pm-metrics: files, format headings and table headers, TBD rule, eval ids, contract block
PM=skills/pm-metrics
for f in SKILL.md references/metrics-format.md references/eval-cases.md; do
  [[ -f "$PM/$f" ]] || err "missing $PM/$f"
done
if [[ -f "$PM/references/metrics-format.md" ]]; then
  for h in "## North Star Metric" "## Input Metrics" "## Success Criteria Mapping" "## Guardrail Metrics" \
           "## Tracking Plan" "## Open Questions"; do
    grep -qxF -- "$h" "$PM/references/metrics-format.md" || err "metrics-format.md missing heading: $h"
  done
  for t in '| PRD criterion | Metric | Target | Baseline | Window | Owner |' '| Event | Trigger | Properties | PRD ref |'; do
    grep -qxF -- "$t" "$PM/references/metrics-format.md" || err "metrics-format.md missing table header: $t"
  done
fi
if [[ -f "$PM/SKILL.md" ]]; then
  for s in 'TBD — Owner' 'CONTRACT MISMATCH' 'Contract check procedure' 'object_action' 'North Star Metric' \
           '### Primary' '### Guardrails' 'Overwrite' 'Merge'; do
    grep -qF -- "$s" "$PM/SKILL.md" || err "pm-metrics/SKILL.md must mention '$s'"
  done
fi
if [[ -f "$PM/references/eval-cases.md" ]]; then
  for id in MT-01 MT-02 MT-03 MT-04 MT-05; do
    grep -qF "$id" "$PM/references/eval-cases.md" || err "pm-metrics eval-cases.md missing $id"
  done
fi
if [[ -f "$CONTRACT" ]]; then
  grep -qxF "<!-- prd-success-criteria:start -->" "$CONTRACT" && grep -qxF "<!-- prd-success-criteria:end -->" "$CONTRACT" \
    || err "sdd-contract.md missing markers for block 'prd-success-criteria'"
  [[ "$(contract_block prd-success-criteria | wc -l | tr -d ' ')" -eq 3 ]] \
    || err "sdd-contract.md block 'prd-success-criteria' must have exactly 3 entries"
  if [[ -f "$FPRD" ]]; then
    while IFS= read -r h; do
      grep -qxF -- "$h" "$FPRD" || err "fixture prd.md missing Success Criteria subsection: $h"
    done < <(contract_block prd-success-criteria)
  fi
fi
if [[ -f "$HELP_REFS/pm-artifacts.md" ]]; then
  grep -F '`metrics.md`' "$HELP_REFS/pm-artifacts.md" | grep -qF 'prd_version' \
    || err "pm-artifacts.md metrics.md row must name the prd_version frontmatter key"
fi
ok "pm-metrics files, format headings, TBD rule, eval ids and contract block checked"

# --- 18. pm-prioritize: files, formula strings, python3 -c, headings, eval ids, artifact row
PP=skills/pm-prioritize
for f in SKILL.md references/frameworks.md references/eval-cases.md; do
  [[ -f "$PP/$f" ]] || err "missing $PP/$f"
done
if [[ -f "$PP/references/frameworks.md" ]]; then
  grep -qF 'reach × impact × (confidence/100) / effort' "$PP/references/frameworks.md" \
    || err "frameworks.md must contain the RICE formula 'reach × impact × (confidence/100) / effort'"
  grep -qF 'impact × confidence × ease' "$PP/references/frameworks.md" \
    || err "frameworks.md must contain the ICE formula 'impact × confidence × ease'"
  for h in "## Method" "## Scores" "## Dependency Conflicts" "## Proposed Sequence Changes" "## Open Questions"; do
    grep -qxF -- "$h" "$PP/references/frameworks.md" || err "frameworks.md missing heading: $h"
  done
  for s in '0.25, 0.5, 1, 2, 3' '50, 80, 100' 'Must' 'Won'"'"'t' 'person-weeks'; do
    grep -qF -- "$s" "$PP/references/frameworks.md" || err "frameworks.md must mention '$s'"
  done
fi
if [[ -f "$PP/SKILL.md" ]]; then
  for s in 'python3 -c' 'CONTRACT MISMATCH' 'Contract check procedure' '## Dependency Conflicts' \
           '## Proposed Sequence Changes' 'MoSCoW' 'Overwrite' '/sdd-roadmap' 'person-weeks' 'update the plan with these priorities'; do
    grep -qF -- "$s" "$PP/SKILL.md" || err "pm-prioritize/SKILL.md must mention '$s'"
  done
fi
if [[ -f "$PP/references/eval-cases.md" ]]; then
  for id in PZ-01 PZ-02 PZ-03 PZ-04 PZ-05; do
    grep -qF "$id" "$PP/references/eval-cases.md" || err "pm-prioritize eval-cases.md missing $id"
  done
fi
if [[ -f "$HELP_REFS/pm-artifacts.md" ]]; then
  grep -F '`prioritization.md`' "$HELP_REFS/pm-artifacts.md" | grep -qF 'method' \
    || err "pm-artifacts.md prioritization.md row must name the method frontmatter key"
fi
ok "pm-prioritize files, formulas, python3 -c, headings and eval ids checked"

# --- 19. pm-prioritize: run the two embedded python3 -c scripts from SKILL.md ------
# The scripts sit in fenced bash blocks right after an HTML-comment marker; the script text is the
# single-quoted part of the block (it contains no single quote), run here with fixed test arguments.
pp_script() {
  python3 -c 'import sys,re
s=open(sys.argv[1]).read()
m=re.search(re.escape("<!-- "+sys.argv[2]+" -->")+r"\n```bash\npython3 -c \x27([^\x27]*)\x27 [^\n]*\n```",s,re.S)
sys.stdout.write(m.group(1) if m else "")' "$PP/SKILL.md" "$1"
}
if [[ -f "$PP/SKILL.md" ]]; then
  SCORE_PY=$(pp_script pm-prioritize:score-script)
  SEQ_PY=$(pp_script pm-prioritize:sequence-script)
  if [[ -z "$SCORE_PY" || -z "$SEQ_PY" ]]; then
    err "pm-prioritize/SKILL.md must hold both scripts after <!-- pm-prioritize:score-script --> / <!-- pm-prioritize:sequence-script --> markers"
  else
    pp_tmp=$(mktemp -d)
    pp_expect() { # pp_expect <label> <expected substring> <script> args...
      local label=$1 want=$2 py=$3; shift 3
      local out; out=$(python3 -c "$py" "$@" 2>&1)
      [[ "$out" == *"$want"* ]] || err "pm-prioritize script test '$label': expected '$want', got '$out'"
    }
    pp_expect "RICE 400 1 80 3" "106.7" "$SCORE_PY" rice 400 1 80 3
    pp_expect "RICE rounds to one decimal (0.125)" "0.1" "$SCORE_PY" rice 1 0.5 100 4
    pp_expect "RICE effort 0" "INVALID" "$SCORE_PY" rice 400 1 80 0
    pp_expect "RICE impact 4" "INVALID" "$SCORE_PY" rice 400 4 80 3
    pp_expect "RICE confidence 70" "INVALID" "$SCORE_PY" rice 400 1 70 3
    pp_expect "ICE 8 7 5" "280" "$SCORE_PY" ice 8 7 5
    pp_expect "ICE 11" "INVALID" "$SCORE_PY" ice 11 7 5
    pp_expect "injection-shaped argument" "INVALID" "$SCORE_PY" rice 5 1 80 "3;touch $pp_tmp/pwned"
    [[ ! -e "$pp_tmp/pwned" ]] || err "pm-prioritize score script executed an injected argument"
    pp_expect "sequence PZ-03 order" "ORDER S-04 S-06 S-05" "$SEQ_PY" rice S-04=106.7=- S-05=75.0=- S-06=240.0=S-04
    pp_expect "sequence PZ-03 conflict" "CONFLICT S-06 needs S-04 first" "$SEQ_PY" rice S-04=106.7=- S-05=75.0=- S-06=240.0=S-04
    pp_expect "MoSCoW Must needs Could" "CONFLICT S-06 needs S-04 first" "$SEQ_PY" moscow S-04=2=- S-06=4=S-04
    pp_expect "MoSCoW Should needs Won't" "CONFLICT S-06 needs S-04 first" "$SEQ_PY" moscow S-04=1=- S-06=3=S-04
    pp_expect "MoSCoW Should needs Could" "CONFLICT S-06 needs S-04 first" "$SEQ_PY" moscow S-04=2=- S-06=3=S-04
    seq_out=$(python3 -c "$SEQ_PY" moscow S-04=4=- S-06=2=S-04 2>&1)
    [[ "$seq_out" != *CONFLICT* ]] || err "pm-prioritize MoSCoW: Could needing a Must must not conflict (got '$seq_out')"
    seq_out=$(python3 -c "$SEQ_PY" rice S-04=106.7=- S-06=25.0=S-04 2>&1)
    [[ "$seq_out" != *CONFLICT* ]] || err "pm-prioritize RICE: a lower score than its prerequisite must not conflict (got '$seq_out')"
    pp_expect "sequence rejects injection-shaped item" "INVALID" "$SEQ_PY" rice "S-04=1=-;touch $pp_tmp/pwned"
    [[ ! -e "$pp_tmp/pwned" ]] || err "pm-prioritize sequence script executed an injected argument"
    rm -rf "$pp_tmp"
  fi
fi
ok "pm-prioritize embedded scripts run (scores, rejections, injection, conflicts)"

# --- 20. pm-forecast: files, script + tests, CI line, headings, caveat/wording strings, eval ids, artifact row
PF=skills/pm-forecast
for f in SKILL.md scripts/forecast.py references/forecast-format.md references/eval-cases.md; do
  [[ -f "$PF/$f" ]] || err "missing $PF/$f"
done
[[ -f tests/test_forecast.py ]] || err "missing tests/test_forecast.py"
if [[ -f .gitlab-ci.yml ]]; then
  grep -qxF -- '    - python3 -m unittest discover -s tests -v' .gitlab-ci.yml \
    || err ".gitlab-ci.yml must run: python3 -m unittest discover -s tests -v"
else
  err ".gitlab-ci.yml missing"
fi
if [[ -f "$PF/scripts/forecast.py" ]]; then
  grep -qxF 'from __future__ import annotations' "$PF/scripts/forecast.py" \
    || err "forecast.py must start with 'from __future__ import annotations' (Python 3.9 compatibility)"
  if grep -En '^(import|from)[[:space:]]+(numpy|pandas|scipy|yaml|requests)' "$PF/scripts/forecast.py" >/dev/null; then
    err "forecast.py must be stdlib only"
  fi
fi
if [[ -f "$PF/SKILL.md" ]]; then
  for s in 'scripts/forecast.py' 'roadmap.md stays estimate-free' 'insufficient-history' 'CONTRACT MISMATCH' \
           'Contract check procedure' 'likely by' 'very likely by' 'almost certain by' 'Deadline Check' 'Base directory'; do
    grep -qF -- "$s" "$PF/SKILL.md" || err "pm-forecast/SKILL.md must mention '$s'"
  done
fi
if [[ -f "$PF/references/forecast-format.md" ]]; then
  for h in "## Forecast" "## Inputs" "## Assumptions & Caveats" "## Deadline Check"; do
    grep -qxF -- "$h" "$PF/references/forecast-format.md" || err "forecast-format.md missing heading: $h"
  done
  for s in 'monte-carlo-throughput' 'ignores dependency depth and parallelism' 'blocked items' 'Team pace'; do
    grep -qF -- "$s" "$PF/references/forecast-format.md" || err "forecast-format.md must mention '$s'"
  done
fi
if [[ -f "$PF/references/eval-cases.md" ]]; then
  for id in FC-01 FC-02 FC-03 FC-04 FC-05; do
    grep -qF "$id" "$PF/references/eval-cases.md" || err "pm-forecast eval-cases.md missing $id"
  done
fi
if [[ -f "$HELP_REFS/pm-artifacts.md" ]]; then
  grep -F '`forecast.md`' "$HELP_REFS/pm-artifacts.md" | grep -qF 'method' \
    || err "pm-artifacts.md forecast.md row must name the method frontmatter key"
fi
ok "pm-forecast files, script, tests, CI line, headings and eval ids checked"

# --- 21. pm-backlog-sync: files, tracker-map format, mandate strings, eval ids, CI line, artifact row
BS=skills/pm-backlog-sync
for f in SKILL.md references/tracker-map-format.md references/eval-cases.md; do
  [[ -f "$BS/$f" ]] || err "missing $BS/$f"
done
[[ -f scripts/validate-pm-evals.sh ]] || err "missing scripts/validate-pm-evals.sh"
if [[ -f .gitlab-ci.yml ]]; then
  grep -qxF -- '    - bash scripts/validate-pm-evals.sh' .gitlab-ci.yml \
    || err ".gitlab-ci.yml must run: bash scripts/validate-pm-evals.sh"
fi
if [[ -f "$BS/references/tracker-map-format.md" ]]; then
  for h in "## Frontmatter" "## Mapping table" "## Orphans" "## Issue mapping" "## Description template" "## Canonical rendering" "## Sync decision table"; do
    grep -qxF -- "$h" "$BS/references/tracker-map-format.md" || err "tracker-map-format.md missing heading: $h"
  done
  grep -qxF -- '| Roadmap ID | Change ID | Issue key | Issue URL | Synced title | Synced hash | Synced at |' "$BS/references/tracker-map-format.md" \
    || err "tracker-map-format.md missing the mapping table header"
fi
if [[ -f "$BS/SKILL.md" ]]; then
  for s in '../pm-help/references/integrations.md' 'never deletes' 'Export file instead' 'Contract check procedure' \
           'CONTRACT MISMATCH' 'tracker-map.md' 'pm-config.yml' 'sync_action' 'relink-ask' '## Orphans' \
           'Summary,Issue Type,Description,Labels' 'sdd:<change-id>' 'is blocked by' 'python3 -c' \
           'pm-backlog-sync:csv-script' 'pm-backlog-sync:hash-script' 'single-quoted heredoc' 'never interpolated' 'Apply'; do
    grep -qF -- "$s" "$BS/SKILL.md" || err "pm-backlog-sync/SKILL.md must mention '$s'"
  done
fi
if [[ -f "$BS/references/eval-cases.md" ]]; then
  for id in BS-01 BS-02 BS-03 BS-04 BS-05 BS-06 BS-07; do
    grep -qF "$id" "$BS/references/eval-cases.md" || err "pm-backlog-sync eval-cases.md missing $id"
  done
  grep -qF '<date>-backlog.csv' "$BS/references/eval-cases.md" && grep -qF '<date>-backlog.csv' "$BS/SKILL.md" \
    || err "pm-backlog-sync must name its export exports/<date>-backlog.csv (integrations.md convention)"
  if grep -qF 'backlog-<date>' "$BS/SKILL.md" "$BS/references/eval-cases.md"; then
    err "pm-backlog-sync must not use the old export name backlog-<date> (use <date>-backlog)"
  fi
fi
if [[ -f "$HELP_REFS/pm-artifacts.md" ]]; then
  grep -F '`tracker-map.md`' "$HELP_REFS/pm-artifacts.md" | grep -qF 'tracker_project' \
    || err "pm-artifacts.md tracker-map.md row must name the tracker_project frontmatter key"
fi
ok "pm-backlog-sync files, tracker-map format, mandate strings, eval ids and CI line checked"

echo
if [[ $fail -eq 0 ]]; then
  echo "validate-structure: ALL CHECKS PASSED"
else
  echo "validate-structure: FAILURES ABOVE"
fi
exit $fail
