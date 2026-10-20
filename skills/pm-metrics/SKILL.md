---
name: pm-metrics
description: >
  Turn a PRD's Success Criteria into a measurement plan: one north-star metric (2-3 candidates proposed, the
  recommended one first, grounded in the Primary criterion, you pick), the input metrics that drive it, a table
  mapping every Success Criteria bullet (Primary, Secondary, Guardrails) to a metric with target, baseline,
  window and owner, the guardrail metrics, and an event tracking plan derived from the user stories (event names
  like recipe_saved). Writes foundation/<slug>/metrics.md. Never invents targets or baselines: anything the PRD
  and the person do not supply is written as "TBD — Owner: <role>" and becomes an open question. Use after
  /pm-prd-review and before the roadmap. Trigger phrases: "define the metrics", "north star metric", "success
  metrics for this PRD", "what should we measure", "tracking plan", "event tracking plan", "guardrail metrics",
  "KPIs for the product", "how will we know it worked", "zdefiniuj metryki", "metryka północna", "north star",
  "plan śledzenia zdarzeń", "wskaźniki sukcesu", "jak zmierzymy sukces", "metryki dla PRD", "KPI produktu".
---

# /pm-metrics — From Success Criteria to a Measurement Plan

Makes "did it work?" answerable before anything is built. The PRD says what success looks like in words; this
skill turns each of those words into something a team can count: a north-star metric, the smaller metrics that
move it, the limits that must not be crossed, and the events the product has to record so the numbers exist at
all. The skill is a **deriver**, not a number generator: every metric traces to a line of the PRD, and every
target, baseline, window or owner comes from the PRD or from the person. A blank stays visibly blank.

## When to use, when to skip

**Use when** a `prd.md` exists with `## Success Criteria` (Primary, Secondary, Guardrails) and the person wants the
measures, the guardrails or the tracking plan spelled out, or an earlier `metrics.md` needs refreshing after the
PRD changed.

**Skip when** there is no PRD yet (`/pm-discover`), the Success Criteria need rewriting rather than measuring (that
is a PRD edit: `/pm-prd-review` for an approved single-section fix, or `/sdd-prd`), or the question is about
priorities or dates (`/pm-prioritize`, `/pm-forecast`).

## Relationship to other skills

- `/pm-prd-review` — usually runs first. It checks that Primary criteria carry a number, a population and a window;
  this skill works either way, and writes `TBD — Owner: <role>` where the PRD is silent. When `metrics.md` exists,
  the review's Measurability dimension reads it, so its headings and table headers below are fixed.
- `/sdd-prd` — owns `prd.md`. This skill reads it and never edits it; a vague criterion is reported, not fixed.
- `/sdd-roadmap` (through `/pm-discover`, which handles the stack step) — the next step. The roadmap's north star is a
  *slice*; the north-star *metric* here is a measure. They are related, not the same thing.
- `/pm-help` — the map of the PM flow.

Shared rules, linked rather than restated: finding the root and the project —
`../pm-help/references/context-resolution.md`; the contract check and PRD headings —
`../pm-help/references/sdd-contract.md`; audience and plain language —
`../pm-help/references/plain-language.md`; where `metrics.md` sits among the PM artifacts —
`../pm-help/references/pm-artifacts.md`; the file layout, naming rules and self-check —
`references/metrics-format.md`; behavior fixtures — `references/eval-cases.md`.

## Initial Response

1. **A project name or a path to a `prd.md`** → use that PRD.
2. **Nothing given** → resolve the project (Step 1) and use its `prd.md`.
3. **A request to change the PRD's criteria** ("make the target 70%") → say the PRD is edited through
   `/pm-prd-review` or `/sdd-prd`; offer to record the number as a *target in the mapping* (with the PM as source)
   instead, and carry on.

Say what is about to happen in one or two sentences, for example: "I'll read your success criteria and stories,
propose the one number that best tells you the product works, and build a measurement plan around it. Anything
I can't take from the PRD I'll ask you; if you don't know yet, I'll leave it marked as open rather than guess."

## Process

Facilitation style (as the `sdd-*` skills do): recommended option first, marked "(Recommended)", always a
"Not sure" option, one decision at a time, echo back and confirm before anything is written, never invent content.

### Step 1 — Audience, root and project

1. Resolve the audience per `../pm-help/references/plain-language.md` (ask once if `audience:` is absent). Plain mode:
   say "the one number that shows the product works" for the north-star metric, "smaller numbers that move it" for input
   metrics, "limits that must not be crossed" for guardrails, "a moment the product records" for an event; keep ids
   (`US-01`, `FR-002`), table talk and file paths for the file. The saved file is identical in both modes.
2. Resolve `CONTEXT_ROOT` and the project per `../pm-help/references/context-resolution.md`. No root, or no project folder
   with a `prd.md` → say so, point at `/pm-discover`, STOP. Several projects → ask which; a named one wins.
3. The file read is `$CONTEXT_ROOT/foundation/<slug>/prd.md`; versioned copies (`prd-vN.md`) are history and never used.

### Step 2 — Contract check (STOP on mismatch)

Run the `## Contract check procedure` in `../pm-help/references/sdd-contract.md` on `prd.md` before reading anything else
from it: read `context_type` from the frontmatter, pick `prd-greenfield` or `prd-brownfield`, test every heading for an
exact whole-line match. A missing or unknown `context_type` counts as a mismatch on `context_type:`.

This skill also needs the three subsections of `## Success Criteria` (the `prd-success-criteria` block in the contract:
`### Primary`, `### Secondary`, `### Guardrails`). Test each as an exact whole-line match, and test that it sits between
the `## Success Criteria` heading and the next `##` heading. Any heading or subsection missing → print one line and
STOP: no questions, no draft, no file, no guessing.

```
CONTRACT MISMATCH: prd.md missing ### Primary, ### Guardrails; sdd-skills expected 0.4.1
```

(names comma-separated, each with its `##` or `###` prefix). Plain mode says it in words (the product write-up has no
clearly labelled main, secondary and must-not-break success measures, so there is nothing to build metrics from; please
re-run the PRD step) and keeps the exact line for the technical log. This skill does not add the subsections itself.

### Step 3 — Read

Read `prd.md` fully and collect, with their ids:

- **Success criteria**: every bullet under `### Primary`, `### Secondary` and `### Guardrails`, in PRD order, as written.
  Number them for yourself as `Primary 1`, `Primary 2`, `Secondary 1`, `Guardrail 1`, and so on (the numbers are for the
  conversation; the file quotes the bullet text). A subsection with no bullets is noted as empty.
- **User stories**: every `### US-NN: <Title>` with its Given / When / Then and acceptance criteria.
- **Requirements**: greenfield → the `- FR-NNN: …` lines of `## Functional Requirements` (id, text, priority). Brownfield →
  the tagged bullets of `## Scope of Change` (`[new]`, `[modified]`, `[removed]`, `[preserved]`); they have no ids, so cite them as
  `Scope [new] "<first words>"`. `[removed]` items produce no events; `[preserved]` items are guardrail context.
- `version` (becomes `prd_version`), `project`, `status`, `context_type`; Non-Functional Requirements only as context.

`### Primary` empty or absent of bullets → there is nothing to ground a north-star metric in. Say so, ask the person to state
the primary outcome in their own words (then it is recorded as theirs, with the PRD gap in Open Questions) or to stop and
fix the PRD first (`/pm-prd-review`); never write one for them.

Then check for an existing `$CONTEXT_ROOT/foundation/<slug>/metrics.md`. If it exists, read it, remember its `created` date
and every value a person gave (targets, baselines, windows, owners, a chosen north-star metric), and tell the person once
that Step 9 will compare the new draft with it before anything is written. Nothing is written in the meantime.

### Step 4 — Propose the north-star metric

A north-star metric is the single measure that best says users are getting the value the PRD promises. Derive **2 to 3
candidates**, each from a `### Primary` criterion (a candidate built from a Secondary criterion is allowed only as the weaker
option, labelled so). Rules for a candidate are in `references/metrics-format.md` (reflects value delivered, counts a repeated
user behaviour, can be moved by the team, has an event behind it). For each show: a short name; a one-sentence definition
(who is counted, what counts, over what period) using only words the PRD uses; **the Primary line it comes from, quoted
verbatim**; and a one-line reason it is or is not the stronger choice.

```
Which one number best tells you this product works?
1. <Name> (Recommended): <definition>. From: "<Primary quote>". <why it leads>
2. <Name>: <definition>. From: "<Primary or Secondary quote>". <why it is weaker or different>
3. <Name>: ...
4. None of these, I'll say it   5. Not sure, explain the options
```

The recommended option goes first and is the one that measures value actually delivered (a completed outcome) rather than a
step toward it. "Not sure" explains the difference between the candidates in plain words and asks again. "I'll say it" takes
the person's own wording, recorded as theirs, with the closest Primary line as its PRD ref (or a note that none fits, which
becomes an Open Question). A candidate never carries a number the PRD or the person did not give.

The chosen metric fills `## North Star Metric`: name, definition, source (the quoted Primary line), target / baseline / window as
the Success Criteria Mapping will carry them (the same cells, not new values).

### Step 5 — Derive the input metrics

Show a short tree: the north-star metric on top, **3 to 5 input metrics** beneath it, each a lever the team can move that
should move the north-star metric (typically: reach, activation or first value, frequency or depth, efficiency or quality; use
only those the PRD supports). Each input metric has a name, a one-line definition, the lever it represents, and a **PRD ref**: a
criterion (`Secondary 1`), a requirement (`FR-002`) or a story (`US-01`). An input metric with no PRD ref is dropped, not
written. Confirm the list with the person ("Keep / change / drop one / Not sure"), once.

### Step 6 — Map every success criterion

One row in `## Success Criteria Mapping` per bullet of `### Primary`, `### Secondary` and `### Guardrails`, in PRD order, no
bullet left out and none combined (`[Primary] `, `[Secondary] ` or `[Guardrail] ` followed by the bullet text, verbatim). Columns,
exactly as in `references/metrics-format.md`: `PRD criterion | Metric | Target | Baseline | Window | Owner`.

Fill each cell from the first source that has it, in this order, and never from anywhere else:

1. **The PRD bullet.** A number, comparison or time phrase in the bullet is restated as written ("at least 60%", "within one
   minute", "three seconds"). An absolute word ("never", "no") may be shown as `0 (PRD: "never")`. A statistic the bullet does
   not name (average, median, p95, maximum) is not chosen: ask.
2. **The person**, asked now (below). Their words are recorded; the cell notes `(PM)` after a value that is not in the PRD.
3. **Otherwise the cell is `TBD — Owner: <role>`**, where `<role>` is the role best placed to supply the value (default: product
   manager for Target, Window and Owner; analytics or data owner for Baseline); a name the person gives replaces the role. Every
   `TBD` also becomes an entry in `## Open Questions` (Step 8).

`Metric` is a measurable restatement of the bullet, defined from the PRD's own words (what is counted, over whom). Where the metric
needs data no story or requirement would capture, the row still gets written; the gap is reported in Step 7.

Ask for the missing values **one criterion at a time**, naming only what is blank:

```
[Primary 2] "At least 40% of weekly active users cook a suggested recipe at least twice a week ..."
Still open: baseline, owner.   Give a value, or say "skip" (it will be marked TBD) / "skip all remaining" / "Not sure, explain".
```

"Skip", "don't know", an empty or evasive answer → `TBD — Owner: <role>` and an Open Question; no pressure, no estimate offered. A
number the person gives is taken as given and not second-guessed. Never offer "typical" benchmarks as defaults.

### Step 7 — Guardrails and tracking plan

**Guardrail metrics** (`## Guardrail Metrics`): one row per `### Guardrails` bullet: the metric, the **breach condition** (the
Guardrail's own threshold restated as "breached when …", or `TBD — Owner: <role>` when the target is open) and the owner (same
value as in the mapping). Guardrails come only from the PRD; this skill adds none to the table. When the north-star metric could be
pushed up at a cost the PRD does not guard (for example a count that can be inflated), say so in `## Open Questions` as a question
to the PM ("should the PRD guard X?"), at most two, and never as a table row.

**Tracking plan** (`## Tracking Plan`, columns `Event | Trigger | Properties | PRD ref`):

- Every `### US-NN` gets **at least one event**, for the user-visible action that completes it or proves it happened. Add events
  that a mapped or input metric needs *when a story covers that action*; every event's PRD ref names at least one `US-NN` (plus any
  `FR-NNN` or scope bullet it serves).
- **Names are `object_action`, past tense, lowercase snake_case** (`recipe_saved`, `shopping_list_item_checked`): object first, then the
  action as a past-tense verb. No `save_recipe`, `RecipeSaved`, `recipe-saved` or `recipe_save`. Each name is unique; one event per
  user action, not per screen.
- **Trigger**: one sentence in the story's words: when exactly the event fires. **Properties**: snake_case attribute names taken from
  the story (ids and counts such as `recipe_id`, `items_matched`); never names, emails or free text. A property the story does not
  imply is not added.
- A metric or criterion that no story records (for example a criterion that counts something no story captures) is **not** given
  an invented event. The mapping row is still written; an Open Question names the gap ("Primary 2 counts X; no story records it;
  add a story or an event?") and points at `/pm-prd-review`. The north-star metric may be in this position; it is reported the same way.

### Step 8 — Open questions, self-check, confirm

Compile `## Open Questions`: one numbered entry per open item, in the PRD's format (`N. **<question>?** — Owner: <role>.
Affects: <row or PRD ref>.`). Each `TBD` cell is covered by an entry (one entry may list several blanks of the same row); each
data gap and each unguarded risk from Step 7 has one. No entries → `None.`.

Self-check before showing the draft (list in `references/metrics-format.md`; fix, then re-run; fixes are silent, but a dropped
item is reported):

- every `### Primary`, `### Secondary` and `### Guardrails` bullet occurs, verbatim, in exactly one mapping row;
- no mapping or guardrail cell is empty; every blank value is `TBD — Owner: <role>` with a matching Open Question;
- every number in a Target, Baseline or Window cell occurs in the PRD bullet of that row, is the `0` restating an absolute word
  ("never", "no") in it, or occurs in an answer given in this conversation (a number found in neither is removed and the cell becomes `TBD — Owner: <role>`);
- every input metric has a PRD ref; the north-star metric has a quoted source line that occurs in the PRD;
- every event name matches `object_action` past tense snake_case; every event has an existing `US-NN` in its PRD ref; every
  `US-NN` has at least one event; no duplicate names.

Print the draft compactly (north-star metric, the tree, the mapping with its `TBD` cells visible, guardrails, the event list, the
number of open questions) and ask:

```
Write it? 1. Looks right, write metrics.md (Recommended)  2. Change something (name a row, event or metric)  3. Not sure, walk me through it
```

Apply changes, re-run the self-check, show only what moved, and confirm again if anything did.

### Step 9 — Write

Path: `$CONTEXT_ROOT/foundation/<slug>/metrics.md`; layout and frontmatter in `references/metrics-format.md`; dates from
`date +%Y-%m-%d`. `created` and `updated` are today for a new file; for an existing one `created` is kept and `updated` is today.
Frontmatter has `project`, `prd_version` (the PRD's `version`), `created`, `updated`.

**A `metrics.md` already exists** → never write first. Show a **diff** (the existing file against the new draft: lines removed
`-`, lines added `+`, each hunk under its `##` heading; unchanged sections are named, not printed; a scratch copy of the draft
outside `$CONTEXT_ROOT` for `diff -u` is fine) and ask:

```
metrics.md already exists (last updated <date>, built from PRD version <n>). What now?
1. Merge (Recommended): keep every value a person gave, add what is new, flag what no longer matches the PRD  2. Overwrite (keeps its created date)  3. Cancel, change nothing  4. Not sure
```

- **Merge** takes the existing file as the base. Rows are matched on the PRD criterion text (mapping, guardrails) and on the event
  name (tracking plan). A matched row keeps every existing Target, Baseline, Window and Owner value, **never replacing a given
  value with `TBD` or with a newly derived one**; a `TBD` cell that the new run could fill (the PM answered in this session) is
  filled. New criteria, events and input metrics are added. A row whose criterion or story no longer occurs in the PRD is kept and
  gets an Open Question ("Row <X> no longer matches the PRD; keep or drop?"); nothing is deleted silently. The existing
  north-star metric stays unless the person picked a different one in Step 4 (then the old one is named in Open Questions). Show
  the **merged** result as a second diff and ask "Write it / Change it / Cancel" before writing.
- **Overwrite** replaces the file with the new draft, keeping `created`. The diff already shown is the record of what is lost; no
  value from the old file is carried over except `created`.
- **Cancel** or no answer → no write, and say so. "Not sure" explains merge versus overwrite in a sentence each and asks again.
- A file that exists but lacks the six headings (hand-made or from another tool) cannot be merged: say so, and offer Overwrite (the
  diff shows the loss) or Cancel.

After writing, read the file back to confirm the frontmatter, the six `##` headings and both table headers exist, then print the
path (technical mode) or say it is saved (plain mode).

### Step 10 — Handoff

Plain mode ends with the handoff block from `../pm-help/references/plain-language.md`: the one number chosen, how many
success measures were mapped and how many are still open (a count, in words), that the measures need these moments recorded (the
count of events), and the next step in product terms: if open questions remain on the main success measures, go back to the product
write-up first (`/pm-prd-review`); otherwise on to the technology decision and the build plan (`/pm-discover`). Technical mode prints
the file path, the number of TBD cells and open questions, and the exact next command (`/pm-prd-review` to resume, or `/pm-discover`,
or `/sdd-roadmap` once the stack step is done). Confirm a skill is in the host's available list before naming it. Do not start the
next skill.

## Output

One file: `$CONTEXT_ROOT/foundation/<slug>/metrics.md`; frontmatter `project`, `prd_version`, `created`, `updated`; sections
`## North Star Metric`, `## Input Metrics`, `## Success Criteria Mapping`, `## Guardrail Metrics`, `## Tracking Plan`,
`## Open Questions`. Mapping table `| PRD criterion | Metric | Target | Baseline | Window | Owner |`; tracking table
`| Event | Trigger | Properties | PRD ref |`. Format and example: `references/metrics-format.md`. Besides this file the skill may write
`audience:` to `.sdd.local.yml` (plain-language rule) and nothing else.

## Critical guardrails

Never writes `prd.md`, `shape-notes.md`, or `roadmap.md`.

1. **Never invents a number.** Targets, baselines, windows and owners come from the PRD bullet or from the person; otherwise the cell is `TBD — Owner: <role>` and an Open Question exists. No benchmarks, no "typical" values, no rounding a guess into a target, no statistic (p95, median) the PRD does not name.
2. **Every criterion is mapped.** All Success Criteria bullets (Primary, Secondary, Guardrails) appear, verbatim, one row each. A bullet that is vague stays vague in the table and is flagged in Open Questions; it is not rewritten.
3. **Grounded in the PRD.** The north-star metric quotes its Primary line; every input metric cites a criterion, requirement or story; every event cites a `US-NN`. Nothing is derived from outside the PRD and the person's answers.
4. **Contract first.** A missing PRD heading or a missing `### Primary` / `### Secondary` / `### Guardrails` subsection → one `CONTRACT MISMATCH` line and STOP, before any question.
5. **The person picks the north-star metric.** Candidates are proposed, recommended first; no choice, no metric. The choice is theirs and is echoed back.
6. **Event names are `object_action`, past tense, snake_case,** unique, one per user action; no personal data in properties.
7. **No silent overwrite.** An existing `metrics.md` triggers the diff and the Merge or Overwrite question; merge never replaces a given value with `TBD`.
8. **Guardrails come from the PRD.** The guardrail table lists the PRD's Guardrails only; extra risks are questions, not rows.
9. **Reports, never repairs, the PRD.** A vague criterion, a story with no event, a metric with no data source is named and routed to `/pm-prd-review`; `prd.md` is not edited.
10. **Own files only.** Writes `metrics.md` and `audience:` in `.sdd.local.yml`. `changes/**`, `archive/**`, `roadmap.md` and `prd-vN.md` are never touched.
11. **Never chain.** Do not start `/pm-prd-review`, `/pm-discover` or any other skill; the human decides.
12. **Mirror the user's language.** Metric names, definitions and questions follow the user's language; quotes stay as written in the PRD; headings, event names and `TBD — Owner:` stay English.

## Notes

- A PRD whose Primary criteria carry no numbers is a valid input: the file is full of `TBD — Owner: product manager` cells and
  Open Questions, which is the honest result and the to-do list for the PM.
- Re-running after the PRD changed is the normal path: choose Merge to keep the values people supplied.
- Fixture example and behavior cases: `references/eval-cases.md`.
