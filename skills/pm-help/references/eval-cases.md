# pm-help eval cases

Behavioral prompt fixtures for `pm-help`. The fixture project is `tests/fixtures/flat-root/context/`
(project `recipe-fridge`). To try one by hand, copy it into a scratch git repo and run Claude Code with
the plugin loaded (see the README, "Local testing"). Every case also implies HL-05.

Format: **Setup** (what exists), **Prompt**, **Expected**, **Fail if**.

## HL-01 — No argument shows the flow map, writes nothing

- **Setup:** any repo; `sdd-pm-skills` installed. A context root may or may not exist.
- **Prompt:** `/pm-help`
- **Expected:** Branch A. The flow (project setup, research, discover with its frame/shape/PRD parts, PRD review,
  metrics, roadmap, prioritize, backlog sync, forecast, status), each step naming the `pm-*` skill that owns it,
  with the build side described as the developers' own step. Optional steps are marked.
  Ends with a single "Start here" action (`/pm-discover …`) and a pointer to `/pm-help <project>`.
  No project files are read, nothing is written.
- **Fail if:** it lists project state, runs or starts any skill, creates a file, or recommends more than one first action.

## HL-02 — Never asks to install another plugin

- **Setup:** only `sdd-pm-skills` installed (no other plugin of any kind); no context root, or the fixture root.
- **Prompt (a):** `/pm-help` — **Expected:** the flow map, with `/pm-init`, `/pm-frame`, `/pm-shape`, `/pm-prd`,
  `/pm-roadmap` and `/pm-map` named as steps of this plugin. No install block, no dependency check, no
  mention of any other plugin.
- **Prompt (b):** `/pm-help recipe-fridge` — **Expected:** the full "you are here" report and one next move,
  exactly as in HL-04; nothing is refused for lack of another plugin.
- **Fail if:** either answer tells the user to install, add or enable any plugin or marketplace, prints an install
  block, refuses Branch C, or says a `pm-init`/`pm-frame`/`pm-shape`/`pm-prd`/`pm-roadmap`/`pm-map` step "cannot start".

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
  `prioritization.md`, `tracker-map.md`, `pm-config.yml`, `status/` or `prd-review-*.md`.
- **Prompt:** `/pm-help recipe-fridge`
- **Expected:** Branch C. Root `context` (flat) resolved without ambiguity. Report shows PRD present (draft, created
  2026-09-15), roadmap present (4 of 7 done, updated 2026-10-14), 4 archived changes, `meal-plan` in flight, and
  metrics, forecast and status reports as `absent` (also prioritization, backlog sync, PRD review). One next move:
  `/pm-prd-review` with a one-line reason (the PRD is still a draft and has never been reviewed). If `pm-prd-review`
  is not available in the host, it says so plainly instead of implying it will run.
- **Fail if:** next move is anything other than `/pm-prd-review`, more than one next move is given, an absent artifact is
  reported as present, or the report shows frontmatter/FR jargon to a plain-audience user.

## HL-05 — Zero file writes on any branch

- **Setup:** any of HL-01 to HL-04, plus a variant with no `.sdd.local.yml` and one with `audience: technical`.
- **Prompt:** any `/pm-help` invocation.
- **Expected:** the working tree and `$CONTEXT_ROOT` are byte-identical before and after (`git status --porcelain`
  empty; no `.sdd.local.yml` or `.gitignore` created even though no audience was recorded; `plain` is used silently).
  No tracker, docs or chat tool is called.
- **Fail if:** any file is created, edited or deleted; the audience question is asked; any external write tool is called.
