---
name: pm-prd-review
description: >
  Review a PRD like a product lead would, before anyone plans or builds from it: seven dimensions (problem
  clarity, measurability, scope discipline, completeness, testability, traceability, open-question risk), each
  PASS / CONCERNS / FAIL, every finding backed by a quoted PRD line, an overall APPROVED / NEEDS_ATTENTION /
  REJECTED verdict, a saved report, and an interactive triage where each finding can be fixed in prd.md (diff
  shown first, one finding at a time), moved to Open Questions, dismissed with a reason, or deferred. May set the
  PRD to status reviewed once everything is resolved; never locks it. The only PM skill allowed to edit prd.md.
  Use after /sdd-prd and before /sdd-roadmap. Trigger phrases: "review the PRD", "review my PRD", "is this PRD
  good", "check the product requirements", "prd review", "audit the requirements", "is the PRD ready for the
  roadmap", "przejrzyj PRD", "zrecenzuj PRD", "sprawdź wymagania produktowe", "czy PRD jest gotowe",
  "ocena PRD", "recenzja PRD".
---

# /pm-prd-review — Review the PRD, Then Triage Findings

Finds the gaps in a product write-up while they are cheap: a vague success criterion costs a sentence now and a
rework later. The skill is a **reviewer**: it reads the PRD, judges seven dimensions, shows evidence for every
finding, and then, one finding at a time and only with the person's say-so, edits the PRD. It is the only PM
skill that may write `prd.md`, and only through the triage loop below.

Two modes:

- **Fresh review**: contract check, analysis, report, save, triage.
- **Resume triage**: given a saved report, jump to the findings still undecided.

## When to use, when to skip

**Use when** a `prd.md` exists (typically `status: draft`, right after `/sdd-prd`) and the person wants it
checked, or a saved review has findings left to triage.

**Skip when** there is no PRD yet (`/pm-discover`), the question is about the build plan rather than the write-up
(`/pm-status`, or `/sdd-plan-review` for a technical plan), or the person wants the PRD *rewritten* (that is
`/sdd-prd`; this skill only applies approved, single-section edits).

## Relationship to other skills

- `/sdd-prd` — writes `prd.md`. This skill never regenerates it; it edits sections in place when a finding is approved.
- `/pm-discover` — the router. It sends a PRD here until it counts as reviewed: `status` is `reviewed` or `locked`, or the
  latest `prd-review-*.md` has `verdict: APPROVED`. A latest report with `NEEDS_ATTENTION` or `REJECTED` keeps it here.
- `/pm-metrics` — may later write `metrics.md`; when that file exists this skill uses it for Measurability, when it does not
  that is not a finding.
- `/sdd-roadmap` — the next sdd step after the review and the stack step. This skill never starts it.
- `sdd-plan-review` (in `sdd-skills`) is the model for the shape of this skill (verdicts, findings, triage); it reviews
  technical plans, this one reviews PRDs.

Shared rules, linked rather than restated: finding the root and the project —
`../pm-help/references/context-resolution.md`; the contract check and PRD headings —
`../pm-help/references/sdd-contract.md`; audience and plain language —
`../pm-help/references/plain-language.md`; where the report sits among the PM artifacts —
`../pm-help/references/pm-artifacts.md`; dimensions, rubrics and finding rules —
`references/review-dimensions.md`; behavior fixtures — `references/eval-cases.md`.

## Initial Response

1. **A path to a saved review** (`prd-review-<date>.md`, or its `<!-- PRD-REVIEW-REPORT -->` marker) → **resume
   triage** (Step 9).
2. **A project name or a path to a `prd.md`** → review that PRD.
3. **Nothing given** → resolve the project (Step 1) and review its `prd.md`.
4. **A request to lock or sign off the PRD** at any point → refuse per guardrail 3 and carry on with what was asked.

## Process

Facilitation style (as the `sdd-*` skills do): recommended option first, marked "(Recommended)", always a
"Not sure" option, one decision at a time, show before write, never invent content.

### Step 1 — Audience, root and project

1. Resolve the audience per `../pm-help/references/plain-language.md` (ask once if `audience:` is absent). Plain mode:
   describe each finding by what it is about ("the goal about weekly cooking", "the shopping-list requirement") and
   keep ids, section names and file paths for the file; the saved report is identical in both modes.
2. Resolve `CONTEXT_ROOT` and the project per `../pm-help/references/context-resolution.md`. No root, or no project folder
   with a `prd.md` → say so, point at `/pm-discover`, STOP. Several projects → ask which; a named one wins.
3. The file under review is `$CONTEXT_ROOT/foundation/<slug>/prd.md`. Versioned copies (`prd-vN.md`) are history and are
   never reviewed or edited.

### Step 2 — Contract check (STOP on mismatch)

Run the `## Contract check procedure` in `../pm-help/references/sdd-contract.md` on `prd.md` before reading anything else from it:
read `context_type` from the frontmatter, pick `prd-greenfield` or `prd-brownfield`, test every heading for an exact
whole-line match. A missing or unknown `context_type` counts as a mismatch on `context_type:`.

Any heading missing → print one line and STOP; no review, no report, no edits, no guessing:

```
CONTRACT MISMATCH: prd.md missing ## Non-Goals; sdd-skills expected 0.4.1
```

(headings comma-separated). Plain mode says it in words (the product write-up is missing sections the next steps rely
on, please re-run the PRD step) and keeps the exact line for the technical log. For a hand-edited PRD with a renamed
heading, the fix is the person's, or `/sdd-prd`'s; this skill does not repair headings.

### Step 3 — Read

Read `prd.md` fully. Note `version`, `status`, `context_type`, `delivery_mode`, `timeline_budget`. Read `metrics.md` from the
same folder if it exists (its absence is not a finding). Look only for the *existence* of `roadmap.md` and read its
`prd_version` frontmatter if there; nothing else in it is used.

`status: locked` → the review runs read-only: findings are produced and the report saved, but every triage choice that
would edit `prd.md` is withheld (see Step 8) and the person is told why in one line.

### Step 4 — Evaluate the seven dimensions

Judge each dimension in `references/review-dimensions.md` (Problem clarity, Measurability, Scope discipline, Completeness,
Testability, Traceability, Open-question risk) against that file's rubric, using the table there for brownfield PRDs.
For Traceability, build the requirement-to-story coverage map first and keep it for the finding text.

### Step 5 — Compile findings and self-check

Each finding has, in this order: `F<n>` and title; `Severity: blocker|major|minor`; `Dimension:`; `PRD ref:` (the
section plus the FR or US id, when the line has one); `Evidence:` (a verbatim quote from the PRD or `Absent: <item>`);
`Why it matters:`; `Fix options:` (1 to 3, each marked *edit* or *ask*, recommended first); `Decision: PENDING`.
Finding rules (one problem one finding, cap 12, no manufactured findings, no invented numbers) are in
`references/review-dimensions.md`.

Self-check before printing: every `Evidence` quote must occur in `prd.md` (or `metrics.md`) after collapsing line breaks and
repeated spaces; check by Read and compare, and never put quote text on a command line (if a shell search is unavoidable,
write the quote to a scratch file with the host file-write tool and use `grep -F -f <file>`). **A finding whose quote is not found is
dropped, never reworded.** An `Absent:` finding must name a section or item that really is not there.

Derive dimension verdicts and the overall verdict by the rules in `references/review-dimensions.md`: any open `blocker` →
`REJECTED`; otherwise any open `major` (a CONCERNS dimension) → `NEEDS_ATTENTION`; otherwise `APPROVED`.

### Step 6 — Print the report and offer to save

```
═══════════════════════════════════════════════════════════
  PRD REVIEW: <project name>
  PRD version <n> · status <status> · <greenfield|brownfield> · <YYYY-MM-DD>
  Findings: <n> blocker · <n> major · <n> minor
═══════════════════════════════════════════════════════════

  Problem clarity       PASS
  Measurability         CONCERNS   (1 finding)
  Scope discipline      PASS
  Completeness          PASS
  Testability           PASS       (1 minor)
  Traceability          CONCERNS   (2 findings)
  Open-question risk    PASS       (1 minor)

  ► Overall: NEEDS_ATTENTION

  F1 — <title>
    Severity:     major
    Dimension:    Measurability
    PRD ref:      ## Success Criteria › Primary
    Evidence:     > "<quoted line>"
    Why it matters: <one or two sentences>
    Fix options:  1. (edit) … (Recommended)   2. (ask) …
```

Findings are grouped blocker, major, minor; PASS dimensions appear only in the table. Plain mode prints the same
content in words ("Overall: needs attention — two things should be decided before planning the build") without ids or
section names. No findings → say the PRD is clean, still show the table, and go to Step 10 with nothing to triage.

Then ask:

```
What now? 1. Save the report and go through the findings (Recommended)  2. Save the report, triage later  3. Don't save (the report stays on screen only; no edits are possible without a saved report)  4. Not sure
```

Triage writes a log into the report, and edits to `prd.md` are only made while a log can record them, so options 1 and 2
save first. "Not sure" explains this and re-asks.

### Step 7 — Save the report

Path: `$CONTEXT_ROOT/foundation/<slug>/prd-review-<YYYY-MM-DD>.md`, date from `date +%Y-%m-%d`. Layout:

```markdown
---
project: <project name from prd.md>
prd_version: <prd.md version>
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
verdict: NEEDS_ATTENTION
---
<!-- PRD-REVIEW-REPORT -->
# PRD Review: <project name>

PRD: foundation/<slug>/prd.md (version <n>, status <status>, <context_type>). Findings: <n> blocker, <n> major, <n> minor.

## Verdicts

| Dimension | Verdict | Open findings |
|---|---|---|
| Problem clarity | PASS | — |
| Measurability | CONCERNS | F1 |
| ... (all seven, in the order of review-dimensions.md) | | |
| **Overall** | **NEEDS_ATTENTION** | |

## Findings

### F1 — <title>

Severity: major
Dimension: Measurability
PRD ref: ## Success Criteria › Primary
Evidence: > "<verbatim quote>"
Why it matters: <text>
Fix options:
1. (edit) <option> (Recommended)
2. (ask) <option>
Decision: PENDING

## Triage log

- <YYYY-MM-DD> — Initial verdict: NEEDS_ATTENTION (<n> findings)
```

`verdict` is one of `APPROVED`, `NEEDS_ATTENTION`, `REJECTED` (this skill's own enum, with an underscore; unrelated to the
`NEEDS ATTENTION` that sdd writes on change reviews). `Decision` is `PENDING`, `FIXED (option n)`, `MOVED (Open Question n)`,
`DISMISSED`, or `DEFERRED`.

**A file with today's date already exists** → ask: "Overwrite it (keeps its `created`) / Save as `prd-review-<date>-2.md`
(Recommended) / Not sure". The suffix takes the next free number. Never overwrite without the answer. Read the file back to
confirm the three required headings and the frontmatter exist, then print its path (technical mode) or say it is saved (plain).

Option 2 of Step 6 ends here with the resume hint: re-run `/pm-prd-review` with the saved report's path.

### Step 8 — Triage loop

Walk the findings with `Decision: PENDING` or `DEFERRED`, in order blocker, major, minor. For each, show the finding (as in
Step 6) and ask:

```
F<n> — <title>.  1. Apply fix  2. Move to Open Questions  3. Dismiss (reason required)  4. Defer  5. Not sure
```

One finding at a time; momentum matters: take the decision, move on, do not argue a dismissal. Responses:

- **Apply fix** → if there are several fix options, ask which (the recommended one first). An *ask* option first collects the
  missing fact from the person (a number, a name, a date, a decision). If they do not know it: offer Move to Open Questions or
  Defer instead; **never fill the gap with a guess**. Then draft the exact edit and **show the diff** (the lines before and after,
  only the changed section, with its heading), and ask "Write it / Change it / Skip". Only on "Write it" edit `prd.md`.
  - **Section integrity.** The edit changes exactly one `##` section. Every `##` heading name and its order stay intact; the
    frontmatter is untouched (including `version`: edits are in-place, history is git's); new lines follow the PRD's own formats
    (`- FR-NNN: … Priority: must-have|nice-to-have` with the next free number, `### US-NN: <Title>` with Given/When/Then and
    `#### Acceptance Criteria`, a numbered Open Questions entry). A fix that needs a second section is split: finish this one, then
    offer the second as its own confirmed edit.
  - After writing, re-run the contract check from Step 2 and confirm that nothing outside the targeted section changed (compare
    the file before and after; the diff shown is the only difference). A failure → restore the previous text, say so, mark the
    finding PENDING.
  - Record `Decision: FIXED (option n)`. The first time an edit lands and a `roadmap.md` exists, say once that the build plan was
    made from the earlier text and may need a look (name `prd_version` of the roadmap vs the PRD).
- **Move to Open Questions** → turn the finding into a question for `## Open Questions`: draft it as a numbered entry
  (`N. **<question>?** — Owner: <name>. By: <YYYY-MM-DD>. Block: yes|no.`), ask for owner, date and the Block flag (do not
  guess them), show the diff of that section, and write on confirmation. Record `Decision: MOVED (Open Question N)`. A
  question the person marks `Block: yes` is re-scored under Open-question risk (a `minor` finding unless the rubric says
  more), so moving a problem there never hides it.
- **Dismiss** → ask for a reason (one line, required; no reason, no dismissal); record `Decision: DISMISSED`. The PRD is
  not touched.
- **Defer** → record `Decision: DEFERRED`. The PRD is not touched. A deferred finding still counts toward the verdict.
- **Not sure** → explain the finding and the options in plain words, then ask again.

On `status: locked`, options 1 and 2 are withheld ("this PRD is locked, so I can't edit it; unlocking is a human step"); only
Dismiss and Defer are offered.

After every decision: update that finding's `Decision:` line and append one line to `## Triage log`
(`<YYYY-MM-DD> — F<n> — <FIXED (option n) | MOVED (Open Question N) | DISMISSED: <reason> | DEFERRED> — <what changed, in a phrase>`);
recompute the dimension and overall verdicts from the findings that are still open; update the `verdict` and `updated`
frontmatter and the `## Verdicts` table in the report. Edits to `prd.md` and updates to the report are two writes: if the PRD
write succeeded and the report write fails, say so and retry the report before anything else.

Stopping early is allowed ("that's enough for now"): remaining findings stay `PENDING`, the report is saved as it stands, and
the resume hint is printed.

### Step 9 — Resume mode

Entered when given a saved report. First run Steps 1 to 3 for the report's project: resolve the audience, `CONTEXT_ROOT` and
project (the report's folder under `foundation/<slug>/` and its `PRD:` line give the PRD path; a `prd.md` that is missing
there is a STOP), run the contract check of Step 2 on that `prd.md` (mismatch → the one `CONTRACT MISMATCH` line and STOP, nothing
edited), and read the PRD and its `status` (a `locked` PRD stays read-only). Only then read the report, parse the `### F` headings and their `Decision:` lines, take those `PENDING` or
`DEFERRED`; none → "All findings are triaged", show the final verdict and go to Step 10. Before triaging, re-check each
remaining finding's `Evidence:` quote against the current `prd.md` (the file may have changed since the review). A quote that no
longer occurs → tell the person the line has changed, show the nearest current text, and ask: "Dismiss as already resolved
(Recommended) / Keep reviewing it / Not sure". If the PRD's `version` differs from the report's `prd_version`, say so once.
Then run the loop of Step 8 on the remaining findings. The report is updated in place; no collision question.

### Step 10 — Summary, verdict and the status offer

```
═══════════════════════════════════════════════════════════
  TRIAGE COMPLETE
═══════════════════════════════════════════════════════════
  Fixed:     F1 (option 1), F3     (2)
  Moved:     F2 → Open Question 4  (1)
  Dismissed: F5                    (1)
  Deferred:  F4                    (1)
  Pending:   —

  ► Verdict after triage: NEEDS_ATTENTION  (was NEEDS_ATTENTION)
═══════════════════════════════════════════════════════════
```

Then:

- **Overall is `APPROVED`**, `status` is `draft`, and nothing is `PENDING` or `DEFERRED` → offer: "Mark the PRD as reviewed
  (changes `status: draft` to `status: reviewed`)? 1. Yes (Recommended)  2. Not now  3. Not sure". If any finding was dismissed
  with `blocker` or `major` severity, list it with its reason in the offer so the choice is informed. On yes show the one-line diff,
  edit only the `status:` line of the frontmatter to `status: reviewed`, add a triage-log line, and report it. Anything else on that
  line, and every other key, stays as it is.
- **Overall is not `APPROVED`**, or findings remain open → no offer. Say which findings keep the verdict where it is, and that a
  re-run (or resume) can finish them. Never flip the status.
- **`status` is already `reviewed`** → nothing to flip; say so. **`locked`** → nothing to flip and no edits were made.
- A request to *lock* the PRD → refuse (guardrail 3); offer `status: reviewed` if the conditions above hold.

### Step 11 — Handoff

Plain mode ends with the handoff block from `../pm-help/references/plain-language.md`: what was reviewed and the verdict in words, what was
changed in the product write-up (a phrase per edit, or "nothing was changed"), and the next step in product terms: after
`APPROVED` and reviewed status, continue the flow with `/pm-discover` (it handles the technology decision and the build plan) and,
when the host lists it, `/pm-metrics`; otherwise finish the open findings first. Technical mode prints the report path, the files
edited and the exact next command. Confirm a skill is in the host's available list before naming it. Do not start the next skill.

## Output

One file per review, `$CONTEXT_ROOT/foundation/<slug>/prd-review-<YYYY-MM-DD>[-N].md`: frontmatter `project`, `prd_version`,
`created`, `updated`, `verdict`; marker `<!-- PRD-REVIEW-REPORT -->`; sections `## Verdicts`, `## Findings`, `## Triage log`.
Besides the report the skill may edit, per approved finding, one section of `prd.md`, may append to `## Open Questions` of
`prd.md`, may change `prd.md` frontmatter `status:` from `draft` to `reviewed` (only as Step 10 describes), and may write
`audience:` to `.sdd.local.yml` (plain-language rule). Nothing else.

## Critical guardrails

Never writes `shape-notes.md` or `roadmap.md`.

1. **Evidence or no finding.** Every finding quotes a PRD line verbatim or names a section or item that is absent. A quote that does not occur in the file drops the finding; it is never reworded to fit.
2. **PRD edits only through triage.** `prd.md` changes only after the person chose Apply fix or Move to Open Questions for that one finding and approved the shown diff. No batch edits, no "fix all", no edit during analysis, no edit when the report is unsaved.
3. **Never locks.** This skill never sets `locked` and never reads a request to lock as permission: `status: locked` is a human sign-off outside the skill. It refuses, says why in one sentence, and offers `status: reviewed` when the conditions in Step 10 hold.
4. **`reviewed` is earned.** The status moves from `draft` to `reviewed` only when the overall verdict is `APPROVED` after triage, nothing is pending or deferred, and the person confirms. Never on `NEEDS_ATTENTION` or `REJECTED`, never as a side effect of anything else.
5. **Never invents.** No number, date, owner, requirement, story or quote that the PRD or the person did not supply. Missing facts are asked for, moved to Open Questions, or deferred.
6. **Structure is sacred.** Every `##` heading name and its order stay intact, one `##` section changes per edit, frontmatter is untouched except the `status:` line at the end; the contract check is re-run after each edit.
7. **Contract first.** Contract mismatch → one `CONTRACT MISMATCH` line and STOP, before any analysis.
8. **Dismissal needs a reason; deferral stays visible.** A dismissed finding keeps its reason in the log; a deferred one still counts toward the verdict.
9. **No silent overwrite.** A same-date report triggers the overwrite or `-2` question.
10. **Own files only.** Writes `prd-review-*.md`, the approved sections of `prd.md`, and `audience:` in `.sdd.local.yml`. `changes/**`, `archive/**` and `prd-vN.md` are never touched.
11. **Never chain.** Do not start `/pm-discover`, `/sdd-roadmap` or any other skill; the human decides.
12. **Mirror the user's language.** Findings and questions follow the user's language; quotes stay as written in the PRD; headings and enum values stay English.
13. **No source/quote text on a command line.** Quote checks are done by Read and compare; a shell search, if unavoidable, takes the quote from a scratch file via `grep -F -f <file>`.

## Notes

- A clean PRD is a valid outcome: say so briefly and stop. Do not manufacture findings.
- Severity is about consequence if ignored, not about effort: a `blocker` can be a one-line fix.
- Fixture example and behavior cases: `references/eval-cases.md`.
