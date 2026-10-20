# pm-help eval cases

Behavioral prompt fixtures for `pm-help`. The fixture project is `tests/fixtures/flat-root/context/`
(project `recipe-fridge`). To try one by hand, copy it into a scratch git repo and run Claude Code with
both plugins loaded (see the README, "Local testing"). Every case also implies HL-05.

Format: **Setup** (what exists), **Prompt**, **Expected**, **Fail if**.

## HL-01 — No argument shows the flow map, writes nothing

- **Setup:** any repo; `sdd-skills` and `sdd-pm-skills` both installed. A context root may or may not exist.
- **Prompt:** `/pm-help`
- **Expected:** Branch A. The nine-step flow (research, discover, PRD review, metrics, roadmap, prioritize,
  backlog sync, forecast, status), each step naming its skill and the plugin that owns it (`sdd-roadmap`
  and the discover sub-steps are `sdd-skills`, the rest `sdd-pm-skills`). Optional steps are marked.
  Ends with a single "Start here" action (`/pm-discover …`) and a pointer to `/pm-help <project>`.
  No project files are read, nothing is written.
- **Fail if:** it lists project state, runs or starts any skill, creates a file, or recommends more than one first action.

## HL-02 — sdd-skills absent: install block, Branch C refused

- **Setup:** only `sdd-pm-skills` installed; none of `sdd-init`, `sdd-frame`, `sdd-shape`, `sdd-prd`, `sdd-roadmap` is available.
- **Prompt (a):** `/pm-help` — **Expected:** the Install block from `references/sdd-contract.md` (both `/plugin` lines),
  naming the missing skills, then the flow map with a note that sdd-owned steps cannot start until it is installed.
- **Prompt (b):** `/pm-help recipe-fridge` — **Expected:** the Install block and a stop; no "you are here" report, no next move.
- **Fail if:** (b) reports project state or a next command; the Install block is omitted or paraphrased.

## HL-03 — Two roots: pick shown, nearest preselected

- **Setup:** repo with two roots: a legacy root `context/` (its `.sdd.yml` has no `layout:` key; app folder
  `context/assets/` holds `foundation/`) and a flat root `posting/context/` (`layout: flat`). Working directory
  is `posting/context/`.
- **Prompt:** `/pm-help where am I`
- **Expected:** Branch C. Discovery finds both `.sdd.yml` files and shows a pick listing each root with its
  layout (`context` legacy, `posting/context` flat); `posting/context` is preselected as the deepest root that is
  an ancestor of, or equal to, the working directory, but the choice is still shown. If the user instead picks the
  legacy root, it then asks which `<app>` (`assets`) before resolving `CONTEXT_ROOT = context/assets`.
- **Fail if:** it silently picks one root, hides the other, ignores the working directory for the default, or
  skips the `<app>` pick for the legacy root.

## HL-04 — Fixture project: report and next move

- **Setup:** the fixture (`recipe-fridge`: `prd.md` with `status: draft`, `roadmap.md` with 7 items, four archived
  changes, `changes/meal-plan/` with `status: implementing`). No `shape-notes.md`, `metrics.md`, `forecast.md`,
  `prioritization.md`, `tracker-map.md`, `pm-config.yml`, `status/` or `prd-review-*.md`. Both plugins installed.
- **Prompt:** `/pm-help recipe-fridge`
- **Expected:** Branch C. Root `context` (flat) resolved without ambiguity. Report shows PRD present (draft, created
  2026-09-15), roadmap present (4 of 7 done, updated 2026-10-14), 4 archived changes, `meal-plan` in flight, and
  metrics, forecast and status reports as `absent` (also prioritization, backlog sync, PRD review). One next move:
  `/pm-prd-review` with a one-line reason (the PRD is still a draft and has never been reviewed). If `pm-prd-review`
  is not installed in the host, it says so plainly instead of implying it will run.
- **Fail if:** next move is anything other than `/pm-prd-review`, more than one next move is given, an absent artifact is
  reported as present, or the report shows frontmatter/FR jargon to a plain-audience user.

## HL-05 — Zero file writes on any branch

- **Setup:** any of HL-01 to HL-04, plus a variant with no `.sdd.local.yml` and one with `audience: technical`.
- **Prompt:** any `/pm-help` invocation.
- **Expected:** the working tree and `$CONTEXT_ROOT` are byte-identical before and after (`git status --porcelain`
  empty; no `.sdd.local.yml` or `.gitignore` created even though no audience was recorded; `plain` is used silently).
  No tracker, docs or chat tool is called.
- **Fail if:** any file is created, edited or deleted; the audience question is asked; any external write tool is called.
