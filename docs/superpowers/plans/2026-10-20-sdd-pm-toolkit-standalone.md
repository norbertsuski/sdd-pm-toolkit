# sdd-pm-toolkit Standalone (vendored core) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `sdd-pm-skills` self-contained: copy (vendor) the six SDD skills the PM flow uses into this repo as `pm-*` skills, rewire the existing nine skills to them, and remove every reference to the `sdd-toolkit` repo / `sdd-skills` plugin / `/sdd-*` commands — while keeping every on-disk artifact format byte-compatible so developers' SDD tooling still reads PM output.

**Architecture:** Vendored skills live beside the existing ones (`skills/pm-init`, `pm-frame`, `pm-shape`, `pm-prd`, `pm-roadmap`, `pm-map`). Shared references move to one place, `skills/pm-help/references/` (vendored `prd-schema.md`; `plain-language.md` absorbs the vendored plain-mode contract; existing `context-resolution.md` stays canonical). `sdd-contract.md` becomes `artifact-contract.md` (formats only). Provenance lives only in `VENDORED.md` + `scripts/check-upstream.sh <path>` (manual, not CI).

**Tech Stack:** Markdown skills, bash, Python 3.9+ stdlib (unchanged).

**Spec:** `docs/superpowers/specs/2026-10-20-sdd-pm-toolkit-design.md` (this plan amends decision D2: "depend on sdd-skills at runtime" → "vendor the core and stand alone").

## Global Constraints

- Source to copy from (READ ONLY, never write): `/Users/norbertsuski/Documents/Code/Private/sdd-toolkit`, pinned commit `478b4d0` (plugin version 0.4.1).
- Rename map (applies to skill names, folder names, frontmatter `name:`, and every `/command` mention): `sdd-init→pm-init`, `sdd-frame→pm-frame`, `sdd-shape→pm-shape`, `sdd-prd→pm-prd`, `sdd-roadmap→pm-roadmap`, `sdd-map→pm-map`.
- **No-reference rule:** outside `VENDORED.md`, `scripts/check-upstream.sh`, and `docs/superpowers/**`, no tracked file contains `sdd-toolkit`, `sdd-skills`, or a `/sdd-` command (after removing the allowed tokens `sdd-pm-toolkit`, `sdd-pm-skills`, and the artifact-format literal ``Ready for `/sdd-plan` `` — the `## Backlog Handoff` column header that developers' tooling expects; it is a file-format string, not a reference, and is kept verbatim). Cell values that mention `/sdd-plan` (e.g. "Run `/sdd-plan <id>`" in Notes) are rewritten generically ("Ready for a developer to plan"). Developer-only steps (planning/implementing a change, archiving, choosing/assessing the tech stack, the project factory) are described generically as "a developer's step in their development workflow" — no command names.
- **Format rule:** artifact paths, file names, frontmatter keys, `##` headings, table columns and status enums written by the vendored skills stay exactly as the source writes them (`context/`, `.sdd.yml`, `.sdd.local.yml`, `foundation/<slug>/{shape-notes,prd,roadmap,roadmap-map}.md`, `changes/`, `archive/`). Only prose, command names and audience defaults change.
- Audience: vendored skills default to `plain` when `.sdd.local.yml` has no `audience:` (the source defaulted to `technical`); the ask-once question and `.gitignore` precondition stay.
- Citation form (R9): shared refs as `../pm-help/references/<file>.md`, own refs as `references/<file>.md`; no `skills/...` prefix.
- Ownership: the vendored skills are the new sole writers of `shape-notes.md` (pm-shape), `prd.md` (pm-prd; pm-prd-review still edits per approved finding), `roadmap.md` (pm-roadmap), `roadmap-map.md` (pm-map). The ownership line in the existing nine skills stays. Vendored writers carry their own ownership statement instead (validator R5 check gets an explicit per-skill expectation).
- Commit trailer: `Co-Authored-By:` naming the authoring model.

## Review Focus

1. **A vendored skill still routes to a developer command** (`/sdd-plan`, `/sdd-archive`, `/sdd-project-run`…) or links `../sdd-shape/...` → the global no-reference validator check (Task 3) fails; each task greps its own files first.
2. **Format drift introduced while editing** (a renamed heading, a changed frontmatter key, `pm-shape` writing to a new path) → developers' tooling can no longer read PM output; `scripts/check-upstream.sh` contract-string pass + validator fixture/contract checks must stay green.
3. **Two copies of one rule** (context resolution / plain-mode in both `pm-help/references` and a vendored skill's own `references/`) → only one canonical file per rule; vendored `references/` folders keep only skill-specific files.
4. **`pm-map` renderer path** hard-coded as `.claude/skills/sdd-map/…` in the source → must resolve from the skill's own base directory (same approach as pm-forecast Step 3).
5. **Cross-skill names after rename** (pm-discover, pm-help ladder, pm-prioritize hand-off, pm-backlog-sync, pm-status) still say `/sdd-roadmap` etc. → covered by the global check and per-skill eval updates.

---

### Task 1: Vendor pm-init, pm-shape, pm-prd + shared references

**Files:**
- Create: `skills/pm-init/SKILL.md`, `skills/pm-shape/SKILL.md`, `skills/pm-prd/SKILL.md`, `skills/pm-help/references/prd-schema.md`, `VENDORED.md`
- Modify: `skills/pm-help/references/plain-language.md` (absorb source `plain-mode.md`: Auto-decision policy table, Auto-decision audit trail, Handoff style, "Artifacts are unchanged"), `skills/pm-help/references/context-resolution.md` (reconcile with source `sdd-shape/references/context-resolution.md`: nothing in the source may be missing; "offer /sdd-init" → "offer /pm-init"), `scripts/validate-structure.sh`, `README.md`, `skills/pm-help/SKILL.md`, `skills/pm-help/references/pm-artifacts.md` (rows for shape-notes/prd as PM-written now)

**Interfaces:**
- Produces: `/pm-init`, `/pm-shape`, `/pm-prd` with the source's outputs and formats unchanged; `prd-schema.md` at `skills/pm-help/references/prd-schema.md` (cited by pm-shape, pm-prd, later pm-roadmap); `VENDORED.md` table `| PM file | Source file | Source commit | Notes |` (one row per vendored/merged file).

- [ ] **Step 1: Validator checks (red)** — new section: the three skill folders exist with name-matching frontmatter; none of their files contains `sdd-toolkit`, `sdd-skills`, `/sdd-`, `../sdd-`; `prd-schema.md` exists and contains every heading listed in the `prd-greenfield` and `prd-brownfield` marker blocks of the contract file; `plain-language.md` contains `## Auto-decision policy`, `## Auto-decision audit trail`, `## Handoff style`; `VENDORED.md` lists each new file. Run → FAIL.
- [ ] **Step 2: Copy + adapt** each source file per the Global Constraints: rename map; `../sdd-shape/references/X` → `../pm-help/references/X` (`plain-mode.md` → `plain-language.md`); developer-only next steps (stack selection/assessment, health check, bootstrapper, planning) become generic developer hand-offs; default audience `plain`; keep every format element. pm-shape and pm-prd keep the `## Repo profile — product-feature delivery mode` behaviour.
- [ ] **Step 3: Eval cases** — `references/eval-cases.md` per new skill (≥4 rows each, IDs `IN-`, `SH-`, `PD-`): no-root → pm-init offered (SH), resume from checkpoint (SH), PRD greenfield 10 headings from fixture-like shape notes (PD), init idempotent (IN), plain-mode default when `.sdd.local.yml` absent (all three).
- [ ] **Step 4: Register** — README rows + count, pm-help installed list + count (12), pm-artifacts rows; pm-help Branch A flow names `/pm-shape`, `/pm-prd`.
- [ ] **Step 5: Green** — `bash scripts/validate-structure.sh`, `bash scripts/validate-pm-evals.sh`, `python3 -m unittest discover -s tests -v`.
- [ ] **Step 6: Commit** `feat(vendor): add pm-init, pm-shape, pm-prd and shared prd-schema`.

### Task 2: Vendor pm-roadmap, pm-frame, pm-map

**Files:**
- Create: `skills/pm-roadmap/SKILL.md`, `skills/pm-frame/SKILL.md`, `skills/pm-map/SKILL.md`, `skills/pm-map/render-roadmap-map.sh`, `skills/pm-map/roadmap-map-hook.sh`
- Modify: `VENDORED.md`, `scripts/validate-structure.sh`, `README.md`, `skills/pm-help/SKILL.md`, `skills/pm-help/references/pm-artifacts.md` (roadmap + roadmap-map rows)

**Interfaces:**
- Consumes: `prd-schema.md`, `context-resolution.md`, `plain-language.md` from Task 1.
- Produces: `/pm-roadmap` (same `roadmap.md` template, sections, columns, statuses), `/pm-frame` (Frame Brief), `/pm-map` (`roadmap-map.md` via `render-roadmap-map.sh <roadmap path>`, resolved from the skill's base directory, then `$CLAUDE_PLUGIN_ROOT/skills/pm-map/`, else STOP).

- [ ] **Step 1: Validator checks (red)** — as Task 1 Step 1 for the three skills; `render-roadmap-map.sh` is executable; a new check runs `bash skills/pm-map/render-roadmap-map.sh <copy of fixture roadmap in a temp dir>` and asserts the output file contains `graph` / `flowchart` and every fixture Roadmap ID (`F-01`, `S-01`…`S-06`). Run → FAIL.
- [ ] **Step 2: Copy + adapt** — rename map; pm-roadmap's references to `/sdd-plan`, `/sdd-implement`, `/sdd-archive`, `/sdd-project-run`, `/sdd-run`, `/sdd-research` become generic developer-workflow descriptions (e.g. "a developer picks a ready item and plans it", "when a developer archives the change, the item's Status becomes `done`"); pm-frame's `/sdd-plan` hand-off becomes "the reframed problem goes to `/pm-shape` (large) or to a developer (small)"; pm-map's `/sdd-help` mentions → `/pm-help`; scripts copied, any `sdd-` strings in them adapted.
- [ ] **Step 3: Eval cases** — `RM-`, `FR-`, `MP-` (≥4 rows each), including: pm-roadmap from the fixture PRD keeps the `## Backlog Handoff` columns exactly; pm-map on the fixture renders all 7 nodes; pm-frame never writes a plan.
- [ ] **Step 4: Register** (count 15) — README, pm-help, pm-artifacts.
- [ ] **Step 5: Green** (all three suites). **Step 6: Commit** `feat(vendor): add pm-roadmap, pm-frame, pm-map`.

### Task 3: Rewire the nine PM skills, remove sdd references, docs

**Files:**
- Rename: `skills/pm-help/references/sdd-contract.md` → `skills/pm-help/references/artifact-contract.md`; `scripts/check-sdd-contract.sh` → `scripts/check-upstream.sh`
- Modify: every existing `skills/pm-*/**` file found by `grep -rlE 'sdd-toolkit|sdd-skills|/sdd-|sdd-contract'`, `scripts/validate-structure.sh`, `scripts/validate-pm-evals.sh` (strings only), `README.md`, `CHANGELOG.md`, `docs/smoke-test.md`, spec (Amendments + D2 line)

**Interfaces:**
- `artifact-contract.md`: same marker blocks and extraction rule as before; header explains it is the file-format contract shared with developers' SDD tooling; no plugin/version wording; `## Install block` and `## Required skills` sections removed; contract check procedure unchanged (mismatch line becomes `CONTRACT MISMATCH: <file> missing <headings>`).
- `scripts/check-upstream.sh <path-to-source-checkout>` (manual, never in CI): (1) the old contract-string drift pass against `<path>/skills/`; (2) `git -C <path> diff --stat <pinned commit>..HEAD -- <each source file in VENDORED.md>` listing upstream changes since vendoring; exit 1 if either finds something, 2 on bad args. Pinned commit read from `VENDORED.md`.

- [ ] **Step 1: Global validator check (red)** — scan all tracked files except `VENDORED.md`, `scripts/check-upstream.sh`, `docs/superpowers/**`: after deleting the tokens `sdd-pm-toolkit` and `sdd-pm-skills`, no line matches `sdd-toolkit|sdd-skills|/sdd-[a-z]|sdd-contract`. Also: no "required skills" / "install sdd" text in any skill. Run → FAIL with the current hits.
- [ ] **Step 2: Rewire** — `/sdd-init|shape|prd|roadmap|frame|map` → `/pm-*` everywhere; pm-help and pm-discover lose the required-skills check, the install block and the "not installed" branches for those six (they ship in this plugin); stack-gate and developer hand-offs reworded generically; `sdd-contract.md` links → `artifact-contract.md`; eval cases updated (e.g. HL-02 and DS-06 "sdd-skills missing" cases are replaced by a case asserting the skill never asks for another plugin).
- [ ] **Step 3: Scripts** — rename + extend `check-upstream.sh`; validator sections that read the contract file use the new name; CI unchanged (does not run check-upstream).
- [ ] **Step 4: Docs** — README: one marketplace, one plugin; "Relationship to sdd-skills" → "Compatibility with SDD development workflows" (formats only, no repo name) + pointer to `VENDORED.md`; Cursor note: copy `skills/pm-*` only; CHANGELOG 0.1.0 entry lists 15 skills; `docs/smoke-test.md` uses a single `--plugin-dir`; spec: D2 amended + Amendments line "core SDD skills vendored as pm-*; no runtime dependency".
- [ ] **Step 5: Green** — validator, evals, unittest; `bash scripts/check-upstream.sh /Users/norbertsuski/Documents/Code/Private/sdd-toolkit` → exit 0 (no upstream changes since `478b4d0`, contract strings present).
- [ ] **Step 6: Commit** `refactor: stand alone — rewire to vendored pm-* skills, drop sdd-toolkit references`.
