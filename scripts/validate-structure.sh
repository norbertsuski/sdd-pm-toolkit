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

echo
if [[ $fail -eq 0 ]]; then
  echo "validate-structure: ALL CHECKS PASSED"
else
  echo "validate-structure: FAILURES ABOVE"
fi
exit $fail
