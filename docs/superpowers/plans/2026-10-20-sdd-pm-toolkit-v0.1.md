# sdd-pm-toolkit v0.1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship `sdd-pm-skills` v0.1.0 — a Claude Code plugin with 9 product-manager skills that run on top of the existing `sdd-skills` plugin without modifying it.

**Architecture:** Skills are `SKILL.md` folders (same format as sdd-toolkit). PM skills read sdd artifacts under `$CONTEXT_ROOT/`, write only their own PM artifacts, and invoke sdd skills through the Skill tool. A pinned consumer contract (`pm-help/references/sdd-contract.md`) replaces cross-plugin file links. Logic that must be exact (forecast math, sync actions, RAG rules) lives in tested scripts or deterministic reference functions.

**Tech Stack:** Markdown skills; bash 5 (validators); Python 3.9+ stdlib only (`forecast.py`, `unittest`); GitLab CI (`python:3.12-slim`).

**Spec:** `docs/superpowers/specs/2026-10-20-sdd-pm-toolkit-design.md`

## Global Constraints

- Repo root: `/Users/norbertsuski/Documents/Code/Private/sdd-pm-toolkit`. **Never write to `../sdd-toolkit`** (read-only reference; `scripts/check-sdd-contract.sh` may grep it).
- Plugin name `sdd-pm-skills`, marketplace name `sdd-pm-toolkit`, initial version `0.1.0`, author `Norbert Suski`.
- Skill folder names: `skills/pm-<name>/`; frontmatter `name:` equals the folder name; every `SKILL.md` has `description:` with trigger phrases (English + Polish, as sdd-toolkit does).
- Consumer contract pinned to `sdd_skills_version: 0.4.1`.
- No relative link from any PM file to `../sdd-*` paths. Shared PM references live in `skills/pm-help/references/` and are linked as `../pm-help/references/<file>.md`.
- Ownership: every skill except `pm-prd-review` contains the exact line ``Never writes `prd.md`, `shape-notes.md`, or `roadmap.md`.``; `pm-prd-review` contains ``Never writes `shape-notes.md` or `roadmap.md`.``. No skill writes `changes/**` or `archive/**`.
- Every skill that writes outside the repo links `../pm-help/references/integrations.md` and follows its write protocol.
- Dates in artifacts: `YYYY-MM-DD` from `date +%Y-%m-%d`. Artifacts carry YAML frontmatter with at least `project`, `created`, `updated`.
- Default audience `plain`; artifacts on disk identical regardless of audience.
- Python: stdlib only, no third-party imports.

## Review Focus

1. **Research folder slug ≠ slug `/sdd-shape` picks** → `pm-discover` must detect that `shape-notes.md` landed in a different `foundation/<slug>/` than `research/` and offer a `git mv` of the research folder (eval DS-04, Task 4).
2. **Re-running `pm-backlog-sync` after a partial failure or on an already-synced roadmap** → no duplicate issues; only `create` for unmapped rows (bash eval `sync_action` cases + BS-02/BS-03, Task 9).
3. **`/sdd-roadmap` regenerated with renamed or removed Change IDs** → orphaned `tracker-map.md` rows are reported, never deleted, relink offered (bash eval `orphan` case + BS-04, Task 9).
4. **`sdd-skills` missing, or installed at a version whose section names drifted** → skills STOP with the install block / list of missing headings instead of misparsing (HL-02, PR-05, Tasks 2 and 5; contract check step in every parsing skill).
5. **Interview transcripts with real names, emails, phone numbers** → `pm-research-synthesis` pseudonymizes to `P1…Pn` by default and asks before keeping any identity (RS-03, Task 3).

---

## File Structure

```
sdd-pm-toolkit/
├── .claude-plugin/plugin.json            # Task 1
├── .claude-plugin/marketplace.json       # Task 1
├── .gitignore  .gitlab-ci.yml            # Task 1 (CI extended in 8, 9)
├── README.md                             # Task 1, row added per skill task
├── CHANGELOG.md                          # Task 11
├── scripts/validate-structure.sh         # Task 1, checks added per task
├── scripts/check-sdd-contract.sh         # Task 2
├── scripts/validate-pm-evals.sh          # Task 9 (extended in 10)
├── skills/pm-help/                       # Task 2
│   ├── SKILL.md
│   └── references/{context-resolution,sdd-contract,pm-artifacts,integrations,plain-language,eval-cases}.md
├── skills/pm-research-synthesis/         # Task 3  SKILL.md, references/{insights-format,eval-cases}.md
├── skills/pm-discover/                   # Task 4  SKILL.md, references/eval-cases.md
├── skills/pm-prd-review/                 # Task 5  SKILL.md, references/{review-dimensions,eval-cases}.md
├── skills/pm-metrics/                    # Task 6  SKILL.md, references/{metrics-format,eval-cases}.md
├── skills/pm-prioritize/                 # Task 7  SKILL.md, references/{frameworks,eval-cases}.md
├── skills/pm-forecast/                   # Task 8  SKILL.md, scripts/forecast.py, references/{forecast-format,eval-cases}.md
├── skills/pm-backlog-sync/               # Task 9  SKILL.md, references/{tracker-map-format,eval-cases}.md
├── skills/pm-status/                     # Task 10 SKILL.md, references/{status-format,eval-cases}.md
└── tests/
    ├── fixtures/flat-root/context/…      # Task 2 (archive dates set in 8)
    └── test_forecast.py                  # Task 8
```

**Per-skill task pattern (Tasks 3–10).** Each skill task follows the same test cycle; steps list only what differs:
1. Add the skill's checks to `validate-structure.sh` (red).
2. Run `bash scripts/validate-structure.sh` → expect `FAIL:` lines naming the new skill.
3. Write `SKILL.md` + references.
4. Write `references/eval-cases.md` (table `| ID | Given | Invoke | Expected |`, same as sdd-toolkit).
5. Add the README table row and the `pm-help` installed-list entry; bump both counts.
6. Run the validator → `validate-structure: ALL CHECKS PASSED`.
7. Smoke-run against the fixture (command in Task 2, Step 9) and compare with the listed eval cases.
8. Commit.

**SKILL.md skeleton** (every skill, mirroring sdd-toolkit): frontmatter → `# /pm-x — Title` → `## When to use, when to skip` → `## Relationship to other skills` → `## Initial Response` → `## Process` (numbered steps) → `## Output` → `## Critical guardrails` (includes the ownership line) → `## Notes`.

---

### Task 1: Repository scaffold, manifests, validator, CI

**Files:**
- Create: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.gitignore`, `.gitlab-ci.yml`, `README.md`, `scripts/validate-structure.sh`

**Interfaces:**
- Produces: `validate-structure.sh` with helpers `err()` / `ok()`, `shopt -s nullglob`, variable `count` (number of `skills/pm-*/` dirs), and the final `ALL CHECKS PASSED` / `FAILURES ABOVE` lines — later tasks append checks before the summary block.

- [ ] **Step 1: `git init`** in the repo root (the `docs/` folder already exists), branch `main`.
- [ ] **Step 2: Write `scripts/validate-structure.sh`** modeled on `../sdd-toolkit/scripts/validate-structure.sh`, with these checks only:
  1. `plugin.json` parses and `version` matches `^[0-9]+\.[0-9]+\.[0-9]+$`; `name == "sdd-pm-skills"`.
  2. `marketplace.json` parses, `name == "sdd-pm-toolkit"`, has a plugin entry `name: sdd-pm-skills`, `source: ./`.
  3. Every `skills/pm-*/` has `SKILL.md`, `name:` matching folder within the first 5 lines, `description:` present.
  4. README contains ``(${count} `pm-*` skills)`` and a ``| `<name>` `` row per skill.
  5. No file under `skills/` contains a link matching `\.\./sdd-[a-z-]+/`.
  6. Every relative `.md` link (`(\.\./|references/)[A-Za-z0-9/._-]+\.md`) in every `SKILL.md` resolves.
  7. `.gitlab-ci.yml` contains `bash scripts/validate-structure.sh`.
- [ ] **Step 3: Run it before the manifests exist.** Run: `bash scripts/validate-structure.sh` — Expected: `FAIL: plugin.json …`, exit 1.
- [ ] **Step 4: Write manifests.** `plugin.json`: `{"name":"sdd-pm-skills","version":"0.1.0","description":"Product-manager skills on top of the SDD (sdd-skills) workflow","author":{"name":"Norbert Suski"},"repository":"https://gitlab.com/norbert.suski/sdd-pm-toolkit"}`. `marketplace.json`: `{"name":"sdd-pm-toolkit","owner":{"name":"Norbert Suski"},"plugins":[{"name":"sdd-pm-skills","source":"./","description":"Product-manager skills for the SDD workflow"}]}`.
- [ ] **Step 5: Write `.gitignore`** (`.DS_Store`, `*.log`, `.claude/`, `__pycache__/`), **`.gitlab-ci.yml`** (job `validate-pm-toolkit`, image `python:3.12-slim`, script `bash scripts/validate-structure.sh`), and **`README.md`** with: title, the line `Ships one plugin: **sdd-pm-skills** (0 \`pm-*\` skills) — requires the **sdd-skills** plugin.`, Install (both marketplaces: `/plugin marketplace add https://gitlab.com/norbert.suski/sdd-toolkit.git`, `/plugin install sdd-skills@sdd-toolkit`, `/plugin marketplace add https://gitlab.com/norbert.suski/sdd-pm-toolkit.git`, `/plugin install sdd-pm-skills@sdd-pm-toolkit`), Local testing (`claude --plugin-dir /path/to/sdd-pm-toolkit --plugin-dir /path/to/sdd-toolkit`), an empty skills table header `| Skill | Purpose |`, and an Ownership section copied from the spec's ownership table.
- [ ] **Step 6: Run validator.** Expected: `validate-structure: ALL CHECKS PASSED` (0 skills).
- [ ] **Step 7: Commit** `chore: scaffold sdd-pm-toolkit plugin, validator and CI` (include `docs/`).

---

### Task 2: `pm-help` with shared contracts and fixtures

**Files:**
- Create: `skills/pm-help/SKILL.md`, `skills/pm-help/references/{context-resolution,sdd-contract,pm-artifacts,integrations,plain-language,eval-cases}.md`, `scripts/check-sdd-contract.sh`, `tests/fixtures/flat-root/context/**`
- Modify: `scripts/validate-structure.sh`, `README.md`

**Interfaces:**
- Produces (used by all later skills):
  - `context-resolution.md` — **PM discovery algorithm**: `find . -name .sdd.yml` with the same exclusions as sdd (`node_modules .git dist build .next coverage`); flat if `^layout:[[:space:]]*flat`; legacy → pick `<app>`; none → offer `/sdd-init`; multiple → pick, preselect nearest ancestor of cwd. Then project pick: glob `$CONTEXT_ROOT/foundation/*/` excluding `archive/`; one → use; many → ask.
  - `sdd-contract.md` — headings: `## Version`, `## Install block`, `## Required skills`, `## PRD contract`, `## Roadmap contract`, `## Change contract`, `## Contract check procedure`. Contents copied **as data** from sdd-skills 0.4.1: PRD frontmatter keys (`project`, `version`, `status` ∈ draft|reviewed|locked, `created`, `context_type`, `delivery_mode`, `timeline_budget.hard_deadline`); greenfield 10 and brownfield 11 `##` headings verbatim; FR line regex `^- FR-\d{3}: .*Priority: (must-have|nice-to-have)`; story heading `### US-NN:`; roadmap `##` headings (`Vision recap`, `North star`, `At a glance`, `Streams` optional, `Baseline`, `Foundations`, `Slices`, `Backlog Handoff`, `Open Roadmap Questions`, `Parked`, `Done`); At-a-glance columns `ID | Change ID | Outcome (user can …) | Prerequisites | PRD refs | Status`; Backlog Handoff columns `Roadmap ID | Change ID | Suggested issue title | Ready for /sdd-plan | Notes`; slice fields (`Outcome`, `Change ID`, `PRD refs`, `Prerequisites`, `Parallel with`, `Blockers`, `Unknowns`, `Risk`, `Status`, foundations add `Unlocks`); item status enum `proposed|ready|planning|in-progress|done|blocked`; `change.md` keys `status`, `created`, `archived_at`, `verified_verdict` (APPROVED|NEEDS_ATTENTION|REJECTED, set with `status: impl_reviewed`); archive folder `archive/<created-date>-<change-id>/`. Contract check procedure: grep required headings, list missing, STOP with `CONTRACT MISMATCH: <file> missing <headings>; sdd-skills expected 0.4.1`.
  - `pm-artifacts.md` — path + frontmatter + required headings of every PM artifact (filled in incrementally by Tasks 3–10; Task 2 writes the table with all nine paths from the spec).
  - `integrations.md` — `## Adapter detection` (substrings `jira confluence linear notion slack gmail outlook`), `## pm-config.yml` (schema from spec), `## Write protocol` (Preview → `Apply` / `Export file instead` / `Cancel` → sequential, stop on first error, persist progress → report), `## Messages` (draft by default; post needs a yes naming the destination), `## Export fallback` (paths under `foundation/<slug>/exports/`).
  - `plain-language.md` — audience resolution (read `.sdd.local.yml`; absent → ask *"Are you a developer, or a non-technical person (like a product owner or project manager)? I'll keep everything in plain language if you're not a developer."*; write `audience:` after ensuring `.gitignore` has `.sdd.local.yml`; PM default `plain`), jargon table (FR/US/NFR, slug, frontmatter, Change ID, MCP, CSV → plain phrases), handoff block `Here's what I did: … / Here's what happens next: … / Want me to keep going?`.
- Fixture `tests/fixtures/flat-root/context/`: `.sdd.yml` (`layout: flat`); `foundation/recipe-fridge/prd.md` (greenfield, all 10 headings, `status: draft`, FR-001…FR-005, US-01…US-03, `timeline_budget: { hard_deadline: 2026-12-15 }`); `foundation/recipe-fridge/roadmap.md` (all required headings, 7 items F-01, S-01…S-06, Change IDs `auth-scaffold`, `fridge-inventory`, `recipe-match`, `save-favorites`, `shopping-list`, `meal-plan`, `share-recipe`; statuses: 4 `done`, `meal-plan` `ready`, `share-recipe` (S-06, Prerequisites `S-04`) `blocked` with an Unknown `Block: yes`, `shopping-list` `proposed`; north star S-02 `recipe-match`); `archive/2026-09-22-auth-scaffold/change.md` etc. for the 4 done items (Task 8 sets exact dates); `changes/meal-plan/change.md` (`status: implementing`).

- [ ] **Step 1: Add checks** to the validator: the six `pm-help/references/*.md` files exist; `sdd-contract.md` contains `sdd_skills_version: 0.4.1`; `pm-help/SKILL.md` contains ``Installed in this plugin (${count})``; every skill other than `pm-help` is mentioned as `` `pm-x` `` in `pm-help/SKILL.md`; the fixture `prd.md` contains every greenfield heading listed in `sdd-contract.md` and the fixture `roadmap.md` every required roadmap heading (parse the heading list from the contract file between `<!-- prd-greenfield:start -->`/`end` and `<!-- roadmap:start -->`/`end` markers, so the contract is the single source).
- [ ] **Step 2: Run validator** → Expected FAIL lines for missing pm-help files.
- [ ] **Step 3: Write the five reference files** per Interfaces (contract heading lists wrapped in the HTML comment markers above).
- [ ] **Step 4: Write the fixture tree.**
- [ ] **Step 5: Write `pm-help/SKILL.md`.** Read-only. Branch A (no arg): the PM flow `research → discover (shape → prd) → prd-review → metrics → roadmap → prioritize → backlog-sync → forecast → status`, each step naming the skill and the plugin that owns it. Branch B (skill/topic arg): answer from that skill's `SKILL.md`. Branch C (project arg or "where am I"): resolve root+project per `context-resolution.md`, list which PM and SDD artifacts exist with dates, name the single next skill to run. Step 0 in every branch: check required sdd skills are available; missing → print the Install block and continue Branch A/B only (C needs sdd artifacts, so C stops). Contains `Installed in this plugin (1)`.
- [ ] **Step 6: Write `eval-cases.md`** — HL-01 no arg → flow map, no writes; HL-02 sdd-skills absent → install block, Branch C refused; HL-03 two roots (flat + legacy `context/assets/`) → pick shown, nearest preselected; HL-04 fixture project → reports PRD, roadmap, no metrics/forecast/status, next = `/pm-prd-review`; HL-05 any branch → zero file writes.
- [ ] **Step 7: Write `scripts/check-sdd-contract.sh <sdd-toolkit-path>`**: for each heading/column/key string inside the contract markers, `grep -rqF` under `<path>/skills/`; print `drift: <string>` for misses; exit 1 on any drift. Never writes.
- [ ] **Step 8: Run** `bash scripts/validate-structure.sh` → ALL CHECKS PASSED; run `bash scripts/check-sdd-contract.sh ../sdd-toolkit` → Expected exit 0 (confirms the contract matches 0.4.1).
- [ ] **Step 9: Smoke** — `S=$(mktemp -d) && cp -R tests/fixtures/flat-root/. "$S" && cd "$S" && git init -q && claude --plugin-dir /Users/norbertsuski/Documents/Code/Private/sdd-pm-toolkit --plugin-dir /Users/norbertsuski/Documents/Code/Private/sdd-toolkit`; run `/pm-help recipe-fridge`, compare with HL-04. (If the host rejects a repeated `--plugin-dir`, install sdd-skills from its marketplace and pass only the PM dir.)
- [ ] **Step 10: Commit** `feat(pm-help): add pm-help, sdd consumer contract, integrations protocol and fixtures`.

---

### Task 3: `pm-research-synthesis`

**Files:** Create `skills/pm-research-synthesis/SKILL.md`, `references/{insights-format,eval-cases}.md`; modify validator, README, `pm-help/SKILL.md`, `pm-artifacts.md`.

**Interfaces:**
- Consumes: `context-resolution.md`, `plain-language.md`.
- Produces: `$CONTEXT_ROOT/foundation/<slug>/research/<YYYY-MM-DD>-<topic-slug>.md`, frontmatter `project`, `topic`, `created`, `updated`, `sources` (count); headings in order: `## Sources`, `## Insights`, `## Jobs to Be Done`, `## Pains & Gains`, `## Contradictions & Surprises`, `## Open Questions`, `## Seed for shaping`. Insight format: `### I-NN: <statement>` + `- Evidence:` bullets `> "<verbatim quote>" — <source id>` + `- Frequency: n/N sources` + `- Confidence: high|medium|low`. JTBD line: `When <situation>, I want to <motivation>, so I can <outcome>.` `## Seed for shaping` is written in the participants' words and is what `pm-discover` passes to `/sdd-shape`.

- [ ] **Step 1: Validator checks** — skill files exist; `insights-format.md` contains all seven headings; SKILL.md contains `verbatim` and `P1`; eval IDs RS-01…RS-05 present.
- [ ] **Steps 2–6** per pattern. Process: resolve root/project (new project → ask name, slug rule *lowercase, non-alphanumeric runs → `-`, trim*); collect sources (`@path`, globs, pasted text; CSV via header row); assign source ids `S1…Sn`; **PII pass** (names, emails, phones, company names → `P1…Pn` / `[company]`; ask once whether to keep real identities, default no); extract candidate insights; cluster; for each insight require ≥1 verbatim quote; show insights to the user for confirm/merge/drop before writing; write file; plain handoff naming `pm-discover` next. Guardrails: never paraphrase inside quote marks; never invent a quote, frequency or participant; insight with zero evidence is dropped, not written.
- [ ] Eval cases: RS-01 three transcripts → file with all seven headings, every insight has ≥1 quote; RS-02 quote not found verbatim in sources → rejected in self-check; RS-03 transcript with names/emails → pseudonymized, identity question asked; RS-04 no project folder → slug proposed and confirmed before write; RS-05 existing same-date file → asks overwrite / new suffix `-2`.
- [ ] **Step 7: Smoke** with two short transcripts placed in the scratch fixture dir.
- [ ] **Step 8: Commit** `feat(pm-research-synthesis): synthesize research into evidence-linked insights`.

---

### Task 4: `pm-discover`

**Files:** Create `skills/pm-discover/SKILL.md`, `references/eval-cases.md`; modify validator, README, `pm-help/SKILL.md`.

**Interfaces:**
- Consumes: research file from Task 3 (`## Seed for shaping`); sdd skills `/sdd-init`, `/sdd-frame`, `/sdd-shape`, `/sdd-prd`, `/sdd-roadmap`; `/pm-prd-review` (Task 5 — referenced by name; absence handled by "skill not available → skip with note").
- Produces: no artifacts of its own. Stage derivation (first match wins): no root → `uninitialized`; no `shape-notes.md` → `unshaped`; shape-notes `checkpoint.current_phase` < final → `shaping`; no `prd.md` → `shaped`; PRD `status: draft` and no `prd-review-*.md` → `specified`; no `roadmap.md` → `reviewed`; else `roadmapped` (hand over to `pm-prioritize` / `pm-backlog-sync`).

- [ ] **Step 1: Validator checks** — files; SKILL.md contains each of `/sdd-init`, `/sdd-shape`, `/sdd-prd`, `/sdd-roadmap`, `/pm-prd-review`; contains `git mv`; contains the ownership line; eval IDs DS-01…DS-06.
- [ ] **Steps 2–6** per pattern. Process: required-skills check → resolve root (none → offer `/sdd-init`) → audience (write `plain` default) → derive stage → present stage + the one next step in plain words → on yes invoke the owning skill via the Skill tool; return here after it completes and re-derive. Solution-shaped input ("build X", no problem stated) → offer `/sdd-frame` first. If a research file exists, invoke `/sdd-shape @<research path>` and tell the operator beforehand which project name to confirm. **After shape returns:** if `shape-notes.md` is in `foundation/<slugB>/` but research lives in `foundation/<slugA>/`, offer `git mv foundation/<slugA>/research foundation/<slugB>/research` (ask; never silent). Never auto-chains: one human gate between every step.
- [ ] Eval cases: DS-01 empty repo → offers `/sdd-init`, nothing else; DS-02 research present, no shape → invokes `/sdd-shape` with the research path; DS-03 shape mid-phase → routes to `/sdd-shape` resume, not `/sdd-prd`; DS-04 slug mismatch after shape → offers `git mv`, does not move without yes; DS-05 PRD draft, no review → recommends `/pm-prd-review`; DS-06 sdd-skills missing → install block, STOP.
- [ ] **Step 7: Smoke** DS-05 on the fixture (PRD draft) — expected recommendation `/pm-prd-review`.
- [ ] **Step 8: Commit** `feat(pm-discover): route PM discovery through sdd shape/prd/roadmap`.

---

### Task 5: `pm-prd-review`

**Files:** Create `skills/pm-prd-review/SKILL.md`, `references/{review-dimensions,eval-cases}.md`; modify validator, README, `pm-help/SKILL.md`, `pm-artifacts.md`.

**Interfaces:**
- Consumes: `prd.md` (+ `metrics.md` if present), `sdd-contract.md` contract check.
- Produces: `foundation/<slug>/prd-review-<YYYY-MM-DD>.md` with frontmatter `project`, `prd_version`, `created`, `verdict` ∈ `APPROVED|NEEDS_ATTENTION|REJECTED`; headings `## Verdicts`, `## Findings`, `## Triage log`. Finding format: `### F<n> — <title>` with `Severity: blocker|major|minor`, `Dimension:`, `PRD ref:` (section + FR/US id), `Why it matters:`, `Fix options:` (1–3). Dimensions (in `review-dimensions.md`, each with a PASS / CONCERNS / FAIL rubric): Problem clarity, Measurability, Scope discipline, Completeness, Testability, Traceability, Open-question risk. Overall: any `blocker` → REJECTED; any `major` or CONCERNS → NEEDS_ATTENTION; else APPROVED. May set PRD `status: reviewed` only when overall is APPROVED **after** triage and the user confirms; never sets `locked`.

- [ ] **Step 1: Validator checks** — files; `review-dimensions.md` names all 7 dimensions; SKILL.md contains ``Never writes `shape-notes.md` or `roadmap.md`.``, `status: reviewed`, and `never sets \`locked\``; eval IDs PR-01…PR-06.
- [ ] **Steps 2–6** per pattern. Process: locate PRD (arg or project pick) → contract check (STOP on mismatch) → evaluate each dimension with quoted PRD lines as evidence → compile findings (no finding without a PRD quote or a named absent section) → print report → offer save → triage loop per finding: `Apply fix` (edit `prd.md`, show diff first, keep every `##` heading name) / `Move to Open Questions` / `Dismiss (reason required)` / `Defer` → append to `## Triage log` → recompute verdict → status flip offer.
- [ ] Eval cases: PR-01 fixture PRD with success criteria lacking numbers → Measurability CONCERNS, NEEDS_ATTENTION; PR-02 FR not covered by any US and no acceptance → Traceability finding with FR id; PR-03 apply fix → only the targeted section changes, headings intact; PR-04 all findings resolved → offers `status: reviewed`; PR-05 PRD missing `## Non-Goals` → CONTRACT MISMATCH, no review; PR-06 user asks to lock → refuses, explains sign-off is a human step outside the skill.
- [ ] **Step 7: Smoke** PR-01 on the fixture.
- [ ] **Step 8: Commit** `feat(pm-prd-review): review PRDs with verdicts and triage`.

---

### Task 6: `pm-metrics`

**Files:** Create `skills/pm-metrics/SKILL.md`, `references/{metrics-format,eval-cases}.md`; modify validator, README, `pm-help/SKILL.md`, `pm-artifacts.md`.

**Interfaces:**
- Consumes: `prd.md` `## Success Criteria` (Primary/Secondary/Guardrails), FRs, USs.
- Produces: `foundation/<slug>/metrics.md`, frontmatter `project`, `prd_version`, `created`, `updated`; headings `## North Star Metric`, `## Input Metrics`, `## Success Criteria Mapping`, `## Guardrail Metrics`, `## Tracking Plan`, `## Open Questions`. Mapping table `| PRD criterion | Metric | Target | Baseline | Window | Owner |`. Tracking plan table `| Event | Trigger | Properties | PRD ref |`, event names `object_action` past tense snake_case (`recipe_saved`).

- [ ] **Step 1: Validator checks** — files; `metrics-format.md` has all six headings and both table headers; SKILL.md contains `TBD — Owner`; eval IDs MT-01…MT-05.
- [ ] **Steps 2–6** per pattern. Process: contract check → propose NSM candidates (2–3, recommended first) grounded in Primary success criterion → user picks → derive input metrics → map every success criterion → guardrails from PRD Guardrails → tracking events from USs (one or more per US) → write. Guardrails: never invent targets or baselines — ask; unanswered → `TBD — Owner: <role>` and an Open Question.
- [ ] Eval cases: MT-01 fixture → every Success Criteria bullet appears in the mapping table; MT-02 user gives no target → `TBD — Owner` + Open Question; MT-03 events follow `object_action` naming and each cites a US; MT-04 existing `metrics.md` → shows diff, asks overwrite/merge; MT-05 PRD without Success Criteria subsections → contract mismatch STOP.
- [ ] **Step 7: Smoke** MT-01.
- [ ] **Step 8: Commit** `feat(pm-metrics): derive north-star metric tree and tracking plan from PRD`.

---

### Task 7: `pm-prioritize`

**Files:** Create `skills/pm-prioritize/SKILL.md`, `references/{frameworks,eval-cases}.md`; modify validator, README, `pm-help/SKILL.md`, `pm-artifacts.md`.

**Interfaces:**
- Consumes: `roadmap.md` (At a glance, slice Prerequisites, statuses) or, without a roadmap, PRD FRs.
- Produces: `foundation/<slug>/prioritization.md`, frontmatter `project`, `method` ∈ `rice|ice|moscow`, `created`; headings `## Method`, `## Scores`, `## Dependency Conflicts`, `## Proposed Sequence Changes`, `## Open Questions`. RICE score = `reach × impact × (confidence/100) / effort`, impact ∈ {0.25, 0.5, 1, 2, 3}, confidence ∈ {50, 80, 100}, effort > 0 (person-weeks, PM's own estimate), rounded to 1 decimal; computed with `python3 -c`, never mentally. ICE = `impact × confidence × ease` (1–10 each). Dependency conflict = item A scores higher than a prerequisite B of A (report "A needs B first").

- [ ] **Step 1: Validator checks** — files; `frameworks.md` contains the RICE formula string `reach × impact × (confidence/100) / effort`; SKILL.md contains `python3 -c` and the ownership line; eval IDs PZ-01…PZ-05.
- [ ] **Steps 2–6** per pattern. Process: pick items (exclude `done`) → pick method (RICE recommended) → collect inputs per item from the PM (never guessed; skip allowed → item unscored) → compute → sort → dependency-conflict pass → proposed sequence changes as a list the PM can bring to `/sdd-roadmap` (re-run, its interview accepts overrides) → write.
- [ ] Eval cases: PZ-01 fixture → `done` items excluded, 3 items scored; PZ-02 effort 0 → rejected with message, re-asked; PZ-03 S-06 scored above its prerequisite → listed in Dependency Conflicts; PZ-04 user asks to apply ranking to roadmap → refuses to edit, offers `/sdd-roadmap` re-run; PZ-05 no roadmap → falls back to PRD FRs.
- [ ] **Step 7: Smoke** PZ-01.
- [ ] **Step 8: Commit** `feat(pm-prioritize): score roadmap items with RICE/ICE/MoSCoW`.

---

### Task 8: `pm-forecast`

**Files:** Create `skills/pm-forecast/SKILL.md`, `skills/pm-forecast/scripts/forecast.py`, `references/{forecast-format,eval-cases}.md`, `tests/test_forecast.py`; modify fixture archive dates, validator, `.gitlab-ci.yml`, README, `pm-help/SKILL.md`, `pm-artifacts.md`.

**Interfaces:**
- `forecast.py` (stdlib):
  - `read_frontmatter(path: Path) -> dict[str, str]` — flat `key: value` lines between the first two `---`.
  - `load_history(context_root: Path) -> list[Completed]` — `Completed = NamedTuple(change_id: str, archived_at: date)` from `archive/*/change.md` with non-null `archived_at`.
  - `remaining_items(roadmap: Path) -> list[str]` — Change IDs from the `## At a glance` table whose Status ≠ `done`.
  - `weekly_throughput(history: list[Completed], today: date, window_weeks: int = 12) -> list[int]` — counts per ISO week (Mon–Sun), from the week of the earliest completion (or `today − window_weeks` weeks, whichever is later) through the **last complete week before `today`'s week**; zero weeks included.
  - `simulate(throughput: list[int], remaining: int, runs: int, seed: int) -> list[int]` — `random.Random(seed)`; per run add `choice(throughput)` per week until ≥ remaining; cap 520 weeks.
  - `percentile(samples: list[int], p: int) -> int` — nearest-rank: sorted, index `ceil(p/100 × n) − 1`.
  - `forecast(context_root: Path, project: str, today: date, runs: int = 2000, seed: int = 42) -> dict` — keys `status` (`ok`|`insufficient-history`), `remaining`, `throughput`, `weeks` `{p50,p85,p95}`, `dates` `{p50,p85,p95}` (ISO; `today + 7×weeks`), `hard_deadline`, `deadline_risk` ∈ `none|p85-after-deadline|p50-after-deadline`. Insufficient when < 3 completions, < 3 weeks in the throughput list, or all-zero throughput → `weeks`/`dates` = null.
  - CLI: `python3 forecast.py --context-root <p> --project <slug> [--today YYYY-MM-DD] [--runs N] [--seed N]` → JSON on stdout.
- Fixture archive dates (today in tests = `2026-10-20`): `auth-scaffold` 2026-09-29, `fridge-inventory` 2026-10-01, `recipe-match` 2026-10-08, `save-favorites` 2026-10-14 → throughput `[2, 1, 1]`; remaining 3.
- Produces `foundation/<slug>/forecast.md`: frontmatter `project`, `created`, `method: monte-carlo-throughput`, `runs`, `seed`; headings `## Forecast`, `## Inputs`, `## Assumptions & Caveats`, `## Deadline Check`. Caveats always state: throughput-based, ignores dependency depth and parallelism, blocked items counted as remaining.

- [ ] **Step 1: Write failing tests** in `tests/test_forecast.py` (import via `sys.path.insert` of `skills/pm-forecast/scripts`):
  - `test_weekly_throughput_fixture`: `weekly_throughput(load_history(FIX), date(2026,10,20)) == [2,1,1]`
  - `test_remaining_fixture`: `sorted(remaining_items(FIX/'foundation/recipe-fridge/roadmap.md')) == ['meal-plan','share-recipe','shopping-list']`
  - `test_constant_throughput_is_exact`: `set(simulate([1,1,1], 3, 500, 1)) == {3}`
  - `test_seed_reproducible`: two `simulate([0,1,2], 5, 200, 7)` calls equal
  - `test_percentile_nearest_rank`: `percentile([1,2,3,4,5,6,7,8,9,10], 85) == 9`
  - `test_insufficient_history`: fixture copy with 2 archive entries → `status == 'insufficient-history'` and `dates is None`
  - `test_deadline_risk`: fixture `hard_deadline` 2026-10-25 → `deadline_risk == 'p50-after-deadline'`; 2027-06-01 → `'none'`
- [ ] **Step 2: Run** `python3 -m unittest discover -s tests -v` → Expected: `ModuleNotFoundError: forecast`.
- [ ] **Step 3: Implement `forecast.py`** per Interfaces; update fixture `change.md` dates.
- [ ] **Step 4: Run tests** → Expected: 7 passed.
- [ ] **Step 5: Validator checks + CI** — `.gitlab-ci.yml` adds `python3 -m unittest discover -s tests -v`; validator asserts that line exists; SKILL.md contains `scripts/forecast.py` and `roadmap.md stays estimate-free`; eval IDs FC-01…FC-05.
- [ ] **Step 6: Write SKILL.md + references** — Process: resolve project → run the script (`python3 "<skill dir>/scripts/forecast.py" …`) → `insufficient-history` → write `forecast.md` with no dates and explain what history is needed; `ok` → present p50/p85/p95 in plain words ("likely by …, very likely by …") → write. Never edits roadmap; never presents a single date.
- [ ] Eval cases: FC-01 fixture → three dates, caveats present; FC-02 2 archived changes → no dates; FC-03 deadline before p50 → Deadline Check red wording; FC-04 user asks to write dates into roadmap → refuses; FC-05 re-run same day same seed → identical output.
- [ ] **Step 7: Validator + tests green; smoke FC-01. Commit** `feat(pm-forecast): Monte Carlo throughput forecast with tested script`.

---

### Task 9: `pm-backlog-sync`

**Files:** Create `skills/pm-backlog-sync/SKILL.md`, `references/{tracker-map-format,eval-cases}.md`, `scripts/validate-pm-evals.sh`; modify validator, `.gitlab-ci.yml`, README, `pm-help/SKILL.md`, `pm-artifacts.md`.

**Interfaces:**
- Consumes: roadmap `## Backlog Handoff`, `## At a glance`, slice bodies; PRD `### US-NN:` Given/When/Then; `pm-config.yml`; `integrations.md` write protocol.
- Produces `foundation/<slug>/tracker-map.md`: frontmatter `project`, `tracker` (`jira|linear`), `tracker_project`, `epic` (key or `—`), `updated`; table `| Roadmap ID | Change ID | Issue key | Issue URL | Synced title | Synced at |`; section `## Orphans` (rows whose Change ID no longer exists in the roadmap — kept, never deleted).
- Issue mapping: `S-NN` → Story, `F-NN` → Task (Jira) / issue with label `foundation` (Linear); title = Suggested issue title; description = Outcome, PRD refs, acceptance criteria from linked USs, `Change ID: <id>`, path to `roadmap.md`; label `sdd:<change-id>`; Prerequisites → "is blocked by" links once both issues exist. Optional epic per project (asked once).
- `scripts/validate-pm-evals.sh` reference function (contract for the skill's decision table):
  `sync_action in_roadmap in_map tracker_exists changed` →
  `in_roadmap=yes in_map=no` → `create`; `yes yes yes no` → `skip`; `yes yes yes yes` → `update`; `yes yes no *` → `relink-ask`; `no yes * *` → `orphan`.

- [ ] **Step 1: Write `scripts/validate-pm-evals.sh`** with `assert_eq` (copy of the sdd-toolkit helper) and the 5 cases above as asserts, but **no** `sync_action` body yet → Run `bash scripts/validate-pm-evals.sh` → Expected FAIL (`sync_action: command not found`).
- [ ] **Step 2: Implement `sync_action`** → run → Expected 5 `ok:` lines, exit 0.
- [ ] **Step 3: CI + validator** — `.gitlab-ci.yml` adds `bash scripts/validate-pm-evals.sh`; validator asserts it; SKILL.md links `../pm-help/references/integrations.md`, contains `never deletes`, `Export file instead`, ownership line; eval IDs BS-01…BS-06.
- [ ] **Step 4: Write SKILL.md + references.** Process: contract check → load/create `pm-config.yml` (adapter detection; ask tracker + project key, epic yes/no) → build desired issue set → load `tracker-map.md` → per row `sync_action` (fetch the mapped issue to set `tracker_exists`; `changed` = title or description hash differs from `Synced title` / stored hash) → preview table (action, roadmap ID, title, key) → write protocol → after each successful create, append the map row immediately (partial-failure resume) → link dependencies → for roadmap `done` items offer (ask) transitioning the issue to Done → report. No MCP → Jira CSV export `exports/backlog-<date>.csv` (columns `Summary,Issue Type,Description,Labels`) or Markdown checklist for Linear.
- [ ] Eval cases: BS-01 fixture, empty map, Jira MCP → 7 creates previewed, nothing written before `Apply`; BS-02 re-run after full sync → all `skip`; BS-03 failure on 4th create → map has 3 rows, re-run creates only the remaining 4; BS-04 Change ID renamed in roadmap → old row moved to `## Orphans`, new row `create`, relink offered; BS-05 mapped issue deleted in Jira → `relink-ask`, never auto-recreate; BS-06 no tracker MCP → CSV export, states no issues were created.
- [ ] **Step 5: Validator + evals green; smoke BS-06 (no MCP in fixture). Commit** `feat(pm-backlog-sync): idempotent one-way roadmap to Jira/Linear sync`.

---

### Task 10: `pm-status`

**Files:** Create `skills/pm-status/SKILL.md`, `references/{status-format,eval-cases}.md`; modify `scripts/validate-pm-evals.sh`, validator, README, `pm-help/SKILL.md`, `pm-artifacts.md`.

**Interfaces:**
- Consumes: roadmap, `changes/*/change.md`, `archive/*`, `forecast.md` (used only if `created` ≤ 7 days old, else suggest re-running `pm-forecast`), `tracker-map.md` (issue links), PRD `hard_deadline`, previous `status/*.md`.
- Item reporting state (reporting view only; `/sdd-project-run --status` remains the authoritative state machine): `done` if roadmap Status `done` or an `archive/*-<change-id>/` exists; `in-progress` if `changes/<change-id>/` exists; `blocked` if roadmap Status `blocked` or any Unknown `Block: yes`; else roadmap Status.
- RAG reference function in `validate-pm-evals.sh`: `rag north_star_blocked needs_triage blocking_unknown deadline_risk` → `red` if `north_star_blocked=yes` or `needs_triage=yes` or `deadline_risk=p50-after-deadline`; `amber` if `blocking_unknown=yes` or `deadline_risk=p85-after-deadline`; else `green`. `needs_triage=yes` when any active `changes/<id>/change.md` has `status: impl_reviewed` and `verified_verdict: REJECTED`.
- Produces `foundation/<slug>/status/<YYYY-MM-DD>.md`: frontmatter `project`, `created`, `rag`; headings `## Summary`, `## Progress`, `## Since Last Update`, `## Risks & Blockers`, `## Decisions Needed`, `## Next Up`, `## Forecast`.

- [ ] **Step 1: Add RAG asserts** (6 cases: all-no/none → green; blocking_unknown → amber; p85 → amber; p50 → red; north_star_blocked → red; needs_triage → red) → run → FAIL (`rag: command not found`).
- [ ] **Step 2: Implement `rag`** → run → all `ok:`.
- [ ] **Step 3: Validator checks** — SKILL.md links `integrations.md`, contains `draft`, ownership line, `/sdd-project-run --status`; `status-format.md` has all seven headings; eval IDs ST-01…ST-06.
- [ ] **Step 4: Write SKILL.md + references.** Process: resolve project → contract check → derive item states → compute RAG inputs → diff vs latest previous status file → write file → audience-appropriate summary → publish offer per `pm-config.yml`: Confluence/Notion page (create or update the page id stored in `pm-config.yml` as `status_page`), Slack/email **draft**; posting needs a yes naming the channel/recipients.
- [ ] Eval cases: ST-01 fixture → `share-recipe` blocked → amber, `meal-plan` in-progress; ST-02 fresh forecast with p50 after deadline → red; ST-03 stale forecast (10 days) → not used, suggestion shown; ST-04 second run → `## Since Last Update` lists changes vs previous file; ST-05 Slack MCP present → draft shown, nothing posted without yes naming the channel; ST-06 no MCP → file only + paste-ready text.
- [ ] **Step 5: Green; smoke ST-01. Commit** `feat(pm-status): stakeholder status report with deterministic RAG`.

---

### Task 11: Release v0.1.0

**Files:** Create `CHANGELOG.md`; modify `README.md`.

- [ ] **Step 1: README** — final skills table (9 rows, pipeline order), "Typical PM flow" block (the Branch A flow), Integrations section (adapters, `pm-config.yml`, write protocol, draft-first messages), "Relationship to sdd-skills" (consumer contract, `check-sdd-contract.sh`), Cursor note (same copy-folders approach as sdd-toolkit: copy `skills/pm-*` alongside `sdd-*`).
- [ ] **Step 2: CHANGELOG** — `## 0.1.0 — <date>` listing the 9 skills and the contract pin `sdd-skills 0.4.1`.
- [ ] **Step 3: Full checks** — `bash scripts/validate-structure.sh && bash scripts/validate-pm-evals.sh && python3 -m unittest discover -s tests -v` → all green; `bash scripts/check-sdd-contract.sh ../sdd-toolkit` → exit 0.
- [ ] **Step 4: End-to-end smoke** in a fresh scratch copy of the fixture: `/pm-help recipe-fridge` → `/pm-prd-review` (save, dismiss all) → `/pm-metrics` → `/pm-prioritize` → `/pm-forecast` → `/pm-backlog-sync` (no MCP → CSV) → `/pm-status`. Expected: 6 new PM artifacts, `git diff --stat` shows **no** change to `roadmap.md`, `shape-notes.md`, `changes/`, `archive/`.
- [ ] **Step 5: Commit** `chore(release): sdd-pm-skills 0.1.0` and `git tag v0.1.0`. Creating and pushing the GitLab remote is left to the user.
