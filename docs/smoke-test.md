# Manual smoke test — sdd-pm-skills 0.1.0

The automated checks (`validate-structure.sh`, `validate-pm-evals.sh`, `tests/test_forecast.py`,
`check-sdd-contract.sh`) cannot run a skill inside a host. This checklist does. It has two parts:

- **Part 1** — an end-to-end run on the bundled fixture with no tracker, wiki or chat connection (about 30 minutes).
- **Part 2** — live-integration checks that could not be verified offline (need real connections).

Expected outcomes cite the eval IDs in each skill's `references/eval-cases.md` (HL = pm-help, DS = pm-discover,
PR = pm-prd-review, MT = pm-metrics, PZ = pm-prioritize, FC = pm-forecast, BS = pm-backlog-sync, ST = pm-status).
Wording will vary; check the structure and the "Fail if" lines of those cases.

## Part 1 — End-to-end on the fixture

### Setup

Use a scratch directory, never the repo itself. `PM` is this repository; `SDD` is a checkout of `sdd-toolkit`.

```bash
PM=/Users/norbertsuski/Documents/Code/Private/sdd-pm-toolkit
SDD=/Users/norbertsuski/Documents/Code/Private/sdd-toolkit

SMOKE=$(mktemp -d)
cp -R "$PM/tests/fixtures/flat-root/." "$SMOKE/"
cd "$SMOKE"
git init -q && git add -A && git commit -q -m "fixture baseline"
git status --short            # expect: nothing (clean baseline)

claude --plugin-dir "$PM" --plugin-dir "$SDD"
```

Fallback if the host rejects a repeated `--plugin-dir`: install `sdd-skills` from its marketplace and load only the PM plugin by directory.

```
/plugin marketplace add https://gitlab.com/norbert.suski/sdd-toolkit.git
/plugin install sdd-skills@sdd-toolkit
```

then restart with `claude --plugin-dir "$PM"` from `$SMOKE`.

Once inside, confirm both plugins loaded: `/pm-help` and `/sdd-help` should both be known commands.
If a PM skill asks which audience you want, answer `plain`. Answer `Yes` when asked to confirm project
`recipe-fridge` or the single context root `context` (flat layout, one project, nothing ambiguous).

Fixture facts used below: `context/foundation/recipe-fridge/` has `prd.md` (`status: draft`) and `roadmap.md`
(F-01, S-01..S-06; F-01, S-01, S-02, S-03 done; S-04 proposed; S-05 ready with `changes/meal-plan/` implementing;
S-06 blocked); four archived changes; no `shape-notes.md`, no `tech-stack.md`.

### Step 1 — `/pm-help recipe-fridge`

- **Answer:** nothing to answer; it is read-only.
- **Expect (HL-04, HL-05):** root `context` resolved without asking; PRD present (draft), roadmap present
  (4 of 7 done), 4 archived changes, `meal-plan` in flight; metrics, forecast, status, prioritization, backlog sync and
  PRD review shown as `absent`. Exactly one next move: `/pm-prd-review`, with a one-line reason.
- **Check:** `git status --short` is still clean (zero writes). No frontmatter or FR-id jargon in plain mode.

### Step 2 — `/pm-prd-review recipe-fridge`

- **Answer:** let the review run. Choose **Save the report and go through the findings**. For every finding choose
  **Dismiss** and give a short reason (for example "smoke test"). Do not apply any fix. If it offers to mark the PRD as
  reviewed, answer **Not now**.
- **Expect (PR-01 style, PR-04 style, PR-06):** contract check passes (10 greenfield headings); seven dimensions,
  each with PASS / CONCERNS / FAIL and quoted evidence taken from the PRD; an overall verdict (typically NEEDS_ATTENTION
  on the unmodified fixture; findings vary). `prd-review-<today>.md` is written next to `prd.md`. The skill never writes
  `status: locked`.
- **Check:** `git diff --stat` shows **no change to `prd.md`** (every finding was dismissed). New file:
  `context/foundation/recipe-fridge/prd-review-<today>.md`.

### Step 3 — `/pm-metrics recipe-fridge`

- **Answer:** pick the **recommended** north-star candidate. When asked for baselines and owners, answer
  **skip all remaining**. Confirm "Write it".
- **Expect (MT-01, MT-02, MT-03):** 2 to 3 north-star candidates with verbatim PRD quotes; an input-metric tree; all
  five Success Criteria bullets, verbatim, one row each in `## Success Criteria Mapping` (60%, 40%, three seconds taken
  from the PRD; every baseline `TBD — Owner: <role>`); exactly two guardrail rows; a tracking plan whose events are
  past-tense `object_action` snake_case. No number that is not in the PRD or in your answers.
- **Check:** new file `metrics.md`; `prd.md` unchanged.

### Step 4 — `/pm-prioritize recipe-fridge`

- **Answer:** pick **RICE**. Supply: S-04 reach 400, impact 1, confidence 80, effort 3; S-05 reach 300, impact 0.5,
  confidence 100, effort 2; S-06 reach 200, impact 1, confidence 50, effort 4. Confirm "Write it".
- **Expect (PZ-01, PZ-04 if you ask it to apply the ranking):** exactly three items asked about and scored (the four
  done items are never scored); S-06 flagged `blocked (waiting on a decision)`, S-05 `already in progress`. Scores
  S-04 106.7, S-05 75.0, S-06 25.0, computed with `python3` and shown with the command. `## Dependency Conflicts` is
  `None.`. If you then say "apply this ranking to the roadmap", it declines and offers a `/sdd-roadmap` re-run or a
  hand-edit.
- **Check:** new file `prioritization.md`; `roadmap.md` byte-identical.

### Step 5 — `/pm-forecast` ("when will we be done?")

- **Answer:** confirm "Write it" after the preview.
- **Expect (FC-01, FC-04):** the script returns `ok`; **three** dates in words (likely / very likely / almost certain),
  never one; caveats name throughput-based, ignores dependency depth and parallelism, blocked items counted, and
  team pace (every archived change in the context root). Deadline Check against the PRD's `hard_deadline: 2026-12-15`.
  `forecast.md` frontmatter has `deadline_risk`. Asking it to put dates into `roadmap.md` is declined.
- **Date note:** the exact dates in FC-01 (2026-11-03 / 2026-11-10 / 2026-11-10) assume today is 2026-10-20. On
  another day the throughput window moves; if the history is then too thin the correct result is
  `insufficient-history` with **no dates** (FC-02). Either outcome is valid as long as the skill is consistent with its script.
- **Check:** new file `forecast.md`; `roadmap.md` unchanged.

### Step 6 — `/pm-backlog-sync` (no tracker connection, so CSV)

- **Answer:** when it reports no tracker connection and offers the export, choose **Jira CSV**. Confirm the write.
- **Expect (BS-06):** no write to any tracker; the first line says **no issues were created**. It writes
  `exports/<today>-backlog.csv` with header exactly `Summary,Issue Type,Description,Labels`, 7 data rows, labels
  `sdd:<change-id>`, the four done items listed as "mark these Done after import", and a warning not to import the file
  and sync later. `tracker-map.md` is **not** written.
- **Check:** new file `context/foundation/recipe-fridge/exports/<today>-backlog.csv`; open it in a spreadsheet or
  `python3 -c "import csv,sys;print(len(list(csv.reader(open(sys.argv[1])))))" <file>` prints 8 (header + 7).

### Step 7 — `/pm-status` ("write the status report")

- **Answer:** confirm "Write it" after the preview. If it offers a wiki or chat export, answer **yes** once to see the
  paste-ready files, or **no** to skip.
- **Expect (ST-01, ST-06):** items: F-01, S-01, S-02, S-03 `done`; S-04 `proposed`; S-05 `in-progress`; S-06 `blocked`.
  Verdict **amber** (one item waiting on a decision, S-06), counts "4 of 7 done"; `## Since Last Update` says first
  status report; `## Forecast` uses the forecast from Step 5 (younger than 7 days) and the PRD deadline; decisions
  needed list the sharing and units questions. It states plainly that nothing was published or sent. With the export
  yes: `exports/<today>-status.md` and `exports/<today>-status.txt`.
- **Check:** new file `context/foundation/recipe-fridge/status/<today>.md` with the seven headings.

### Final check — nothing the PM skills must not touch changed

From `$SMOKE` (outside Claude, or with `!` inside it):

```bash
git diff --stat                                   # expect: empty
git status --short                                # expect: only new (untracked) files
git diff --stat -- \
  context/foundation/recipe-fridge/roadmap.md \
  context/foundation/recipe-fridge/shape-notes.md \
  context/changes context/archive                 # expect: empty
git diff --quiet && echo "tracked files unchanged"
```

Expected new PM artifacts (6, plus an optional `pm-config.yml` and the `.sdd.local.yml` audience file if the skills asked):

| Step | File under `context/foundation/recipe-fridge/` |
|---|---|
| 2 | `prd-review-<today>.md` |
| 3 | `metrics.md` |
| 4 | `prioritization.md` |
| 5 | `forecast.md` |
| 6 | `exports/<today>-backlog.csv` |
| 7 | `status/<today>.md` |

**Fail** if `git diff --stat` shows any change to `roadmap.md`, `shape-notes.md` (absent in this fixture, so it must
not appear at all), `changes/` or `archive/`, or any change to `prd.md` (every finding was dismissed).

Clean up: `rm -rf "$SMOKE"`.

### Optional extras on the same scratch copy

- **PRD gate (DS-05, DS-08):** `/pm-discover recipe-fridge` on a fresh copy recommends `/pm-prd-review` first (not
  `/sdd-shape`, `/sdd-prd` or `/sdd-roadmap`) and invokes nothing without a yes.
- **Missing sdd-skills (HL-02, DS-06):** start `claude --plugin-dir "$PM"` alone; `/pm-help recipe-fridge` and
  `/pm-discover` print the Install block and stop.

## Part 2 — Live-integration checks (not verifiable offline)

These need real connections and a throw-away project or space in each tool. Use test data only; never point them at a
production board, space or channel. Record pass/fail and the tool names the host actually exposes.

### 2.1 MCP tool discovery

For each connection you have, start `claude` with that MCP server enabled next to both plugins, then ask a PM skill that
needs it (`/pm-backlog-sync` for Jira or Linear; `/pm-status` for Confluence, Notion, Slack, Gmail or Outlook).

| Connection | Check |
|---|---|
| Jira | The skill finds a tool whose name contains `jira`, lists the tool names it will use (get, create, update, link, transition, search), asks for the project key, and stores `tracker: jira`, `tracker_project` in `pm-config.yml` only after you confirm. |
| Linear | Same with `linear`; team key stored as `tracker_project`. |
| Confluence | Tool name contains `confluence`; the skill asks for space key + parent page id (`docs_location`). |
| Notion | Tool name contains `notion`; the skill asks for the parent page id. |
| Slack | Tool name contains `slack`; the skill reads `channel: slack`, `channel_target` from `pm-config.yml` or asks and confirms. |
| Gmail / Outlook | Tool name contains `gmail` or `outlook`; only an **email draft** is offered. |
| Two in one family (for example Jira and Linear) | The skill asks which one to use and does not pick silently. |

**Fail if** the skill assumes a tool exists that the host did not list, or writes `pm-config.yml` before you confirmed.

### 2.2 `/pm-backlog-sync` create and idempotency (BS-01, BS-02, BS-03)

On a scratch Jira project (key, for example, `KAN`) with a fresh fixture copy:

1. **Create (BS-01):** "sync the backlog to Jira". Expect a preview of **7 creates** (S-01..S-06 as Story, F-01 as Task),
   dependency links (S-01 blocked by F-01, S-02 by S-01, S-03 by S-02, S-04 by S-02, S-05 by S-03, S-06 by S-04), the
   outside condition `ingredient unit convention agreed` listed as not linked, and exactly `Apply` / `Export file instead`
   / `Cancel`. Nothing is written before `Apply`. After `Apply`: 7 issues created one at a time, one `tracker-map.md` row
   appended after each, links created, then a separate offer to move the four done items to Done. Each issue has the label
   `sdd:<change-id>` and a description with outcome, PRD refs, the linked user story's Given/When/Then and the Change ID.
2. **Idempotent re-run (BS-02):** "sync the backlog again". Expect every row `skip`, the statement that nothing changed,
   no write offered, and `tracker-map.md` `updated` untouched. **Fail** if any issue is duplicated.
3. **Partial failure (BS-03):** on a second scratch project, make the 4th create fail (for example a required field the
   project demands, or revoke the permission mid-run). Expect the run to stop at the first error with 3 map rows saved and
   the failing item and error text reported; after fixing the cause, a re-run previews only the remaining 4 creates.
4. **Optional drift (BS-04, BS-05, BS-07):** rename a Change ID in a scratch roadmap and expect an `orphan` report (never a
   delete); delete one mapped issue in Jira and expect `relink-ask`, not a silent recreate.

### 2.3 `/pm-status` publishing (ST-05, ST-08)

1. **Slack draft only (ST-05):** with `channel: slack` and a test channel in `pm-config.yml`, say "write the status and
   post it to Slack". Expect the report written first, the Slack text shown as a **draft**, and a plain statement that
   nothing has been posted. Reply `yes` alone: must **not** post (the draft is shown again). Reply
   `yes, post to <the test channel>`: posts exactly the shown draft once and reports it. **Fail** if anything is posted
   before a yes that names the channel.
2. **Email draft:** with Gmail or Outlook connected, expect a draft only, never a send, unless you name the recipients in a yes.
3. **Confluence or Notion page (ST-08):** "publish the status". First run previews "create 1 page" under the configured
   parent and saves `status_page` to `pm-config.yml` after `Apply`. A later run (new day) previews "update page <id>".
   Delete the page and re-run: it must ask create-new / export / cancel, never recreate on its own. A permission or
   network error must be reported as a failure, not as "not found".

### 2.4 `/pm-discover` → `/sdd-shape` project-name confirmation (DS-02, DS-04)

1. **DS-02:** in a copy of the fixture, add `context/foundation/recipe-fridge/research/2026-10-12-fridge-habits.md`
   with a `## Seed for shaping` section; delete `prd.md` and `roadmap.md` (there is no `shape-notes.md` in the fixture).
   Run `/pm-discover`, confirm the project, answer yes at the gate. Expect the skill to tell you which project name to
   confirm in `/sdd-shape` and to call it with `@<path of the research file>`. **Fail** if `/sdd-shape` starts without
   the path, without your yes, or without the project-name hint.
2. **DS-04:** in `/sdd-shape` choose **Rename** and type a different name (for example `fridge-planner`). After it returns,
   expect the skill to notice the slug mismatch, ask whether to move the research next to the product, and move nothing
   before your answer. On yes it runs `git mv` of the `research/` folder and says the move is staged, not committed. On
   "leave it" nothing moves.

### Sign-off

Record the date, the host and version, the `sdd-skills` version (must be 0.4.1, or run
`bash scripts/check-sdd-contract.sh "$SDD"` first), and any failed item with the skill's exact output. File failures as
issues against the owning skill before tagging; the `v0.1.0` tag is created after the release branch is merged to main.
