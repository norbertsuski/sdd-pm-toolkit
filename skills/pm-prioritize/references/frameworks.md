# Prioritization frameworks and file format

What `pm-prioritize` scores with, how a conflict is defined, and the layout of
`$CONTEXT_ROOT/foundation/<slug>/prioritization.md`. The five `##` headings below (`## Method`, `## Scores`,
`## Dependency Conflicts`, `## Proposed Sequence Changes`, `## Open Questions`) are fixed, in this order, and always present
(an empty section says `None.`); `scripts/validate-structure.sh` checks them in this file. Headings stay in English in every
language; the text in cells follows the user's language.

The skill never supplies an input. Reach, impact, confidence, effort, ease and categories come from the person; a missing one
leaves the item unscored. All arithmetic runs through `python3 -c` (the commands are in `SKILL.md`, Step 6), never in the head.

## RICE (recommended)

```
score = reach × impact × (confidence/100) / effort
```

| Input | Allowed values | Meaning |
|---|---|---|
| reach | a number, 0 or more | How many people (or events) the item touches in one period. The unit and the period are the person's, stated once in `## Method`; the same for every item. |
| impact | one of 0.25, 0.5, 1, 2, 3 | Effect on each person reached: 3 massive, 2 high, 1 medium, 0.5 low, 0.25 minimal. |
| confidence | one of 50, 80, 100 | How sure the person is of the other three inputs, in percent: 100 high, 80 medium, 50 low. |
| effort | a number greater than 0, in person-weeks | The person's **own** rough estimate of the work. Never derived from `forecast.md`, from history or by the assistant. |

The score is rounded to one decimal (half up). Effort 0 is rejected (it would divide by zero and means "free", which is not an
estimate). Impact 4, confidence 70 or any value outside the sets is rejected with the allowed values, and the question is asked
again; "skip" leaves the item unscored.

**Effort stays in `prioritization.md`.** This file and `forecast.md` are the only places a size estimate appears; `roadmap.md`
stays estimate-free and the skill never writes it. An effort number is a ranking input here, not a schedule: dates come from
`/pm-forecast`.

## ICE

```
score = impact × confidence × ease
```

Each input is a whole number from 1 to 10 given by the person (impact: how much it matters; confidence: how sure; ease: how easy
to do, 10 easiest). The product is a whole number from 1 to 1000. No effort estimate is asked. Use it when reach or effort cannot
be estimated yet.

## MoSCoW

No arithmetic. The person gives each item one category for this release:

| Category | Meaning |
|---|---|
| Must | The release fails or is pointless without it. |
| Should | Important, but the release can ship without it. |
| Could | Wanted if there is room. |
| Won't | Deliberately not in this release. |

Order is Must, Should, Could, Won't, then the current roadmap order inside each category. For ordering only, the skill uses the
ranks Must 4, Should 3, Could 2, Won't 1; the ranks are not shown as scores.

## Dependency conflicts

A prerequisite is a roadmap item id (`F-NN`, `S-NN`) in an item's `Prerequisites` (the `## At a glance` cell and the slice's
`- **Prerequisites:**` line, taken together). Text that is not an id (for example "ingredient unit convention agreed") is an
outside condition: it is listed in `## Open Questions`, never checked as a conflict.

- **RICE and ICE:** item A has a conflict with its prerequisite B when A's score is **strictly higher** than B's. Reported as
  "A needs B first". Equal scores are not a conflict.
- **MoSCoW:** item A has a conflict with its prerequisite B when A's category is **higher** than B's (order Must > Should > Could > Won't): for example a Must or a Should whose prerequisite is Could or Won't, or a Must whose prerequisite is Should. Same category is not a conflict. Reported as "A needs B first".
- A prerequisite whose Status is `done` never conflicts (it is not scored and is not in the list).
- A prerequisite that is not done but unscored is looked through: its own prerequisites are checked instead. An unscored item
  cannot itself be in a conflict; `## Open Questions` says which pairs could not be checked.
- Without a roadmap there are no recorded prerequisites: the section says the check was not run.

## Proposed sequence

The proposed order is the highest-scoring order that still puts every unfinished prerequisite first: repeatedly place, among the
items whose unfinished prerequisites are all placed, the highest-scoring one (ties keep the current roadmap order; unscored items
come last in roadmap order). A dependency always beats a score. `## Proposed Sequence Changes` lists where this order differs
from the roadmap's current order among the scored items; it is a list for the person to use as input to a `/pm-roadmap` re-run or to hand-edit the roadmap order, never an edit by this skill.

## prioritization.md layout

One file per project, updated in place (collision rule in `SKILL.md` Step 9).

```yaml
---
project: <project name, as in roadmap.md or prd.md>
method: <rice | ice | moscow>      # the method of the first (top) run
basis: <roadmap | prd>             # what was scored: roadmap items, or PRD requirements
created: <YYYY-MM-DD>              # date +%Y-%m-%d; unchanged when the file is overwritten or a run is added
updated: <YYYY-MM-DD>
---
```

Followed by `# Prioritization: <project name>` and the five sections.

## Method

```markdown
## Method

- **Method:** RICE: reach × impact × (confidence/100) / effort
- **Reach counted as:** <the person's unit and period, e.g. households per month>
- **Effort:** person-weeks, the person's own estimate. It is recorded only in this file; `roadmap.md` carries no estimates.
- **Source:** roadmap.md (version <n>, updated <date>); scored <k> of <m> unfinished items; `done` items excluded: <ids>
```

ICE: `impact × confidence × ease`, scales 1 to 10; MoSCoW: `Must / Should / Could / Won't, no arithmetic`. Source for a PRD
run: `prd.md (version <n>); no roadmap, so no prerequisites are recorded`.

## Scores

Ranked best first; ties keep roadmap order. Unscored items are listed last with `-` cells and `not scored` in Notes. The Notes
cell carries the flags: `blocked (waiting on a decision)`, `already in progress (changes/<change-id>/)`, `needs outside condition: <text>`.
Table headers are fixed per method:

```markdown
| Rank | ID | Outcome | Reach | Impact | Confidence | Effort (person-weeks) | Score | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | S-06 | user can share a recipe, with its missing ingredients, with a household member | 600 | 2 | 80 | 4 | 240.0 | blocked (waiting on a decision) |
```

ICE: `| Rank | ID | Outcome | Impact | Confidence | Ease | Score | Notes |`. MoSCoW: `| Rank | ID | Outcome | Category | Notes |`.
`Outcome` is copied from the roadmap table (or the requirement text for a PRD run); `ID` is the roadmap id, `FR-NNN`, or
`SC-NN` for a brownfield scope bullet (numbered in PRD order for this file only, with the bullet's first words in `Outcome`).

## Dependency Conflicts

```markdown
| Item | Needs first | Item score | Prerequisite score | Note |
|---|---|---|---|---|
| S-06 | S-04 | 240.0 | 106.7 | S-06 needs S-04 first |
```

MoSCoW: columns `Item | Needs first | Item category | Prerequisite category | Note`. No conflicts → `None.`; no roadmap →
`Not checked: no roadmap, so no prerequisites are recorded.`

## Proposed Sequence Changes

A numbered list; each line names a move to an **earlier** position (items that only shift later as a result are not listed), the positions and the reason in numbers the file already shows. Notes follow for blocked items moved earlier and in-progress items shifted later. After the list, one
line states how to use it. No changes → `None: the scores agree with the current order.`

```markdown
1. Move S-06 from position 3 to 2 of 3 (ahead of S-05): it scores 240.0 against 75.0. S-04 stays first because S-06 needs it.
2. Note: S-06 is blocked, so moving it earlier changes nothing until its decision is made.
3. Note: S-05 is already in progress and shifts later; that means pausing work that has begun.

To apply: use this list as input to the three anchor questions of a `/pm-roadmap` re-run (it has no per-item order override, and it regenerates `roadmap.md` from scratch: statuses are rebuilt and `## Done` starts empty; the archived copy keeps the old one), or edit the order in `roadmap.md` by hand. This file does not edit `roadmap.md`.
```

A PRD run lists the proposed priority order of the requirements instead (`1. FR-004 ...`) and says the order has no dependency
check.

## Open Questions

Numbered, in the roadmap's style: `N. **<question>?** — Owner: <role>. Affects: <id>.`. Entries: each unscored item and why;
each prerequisite id missing from the roadmap table; each outside condition; each pair that could not be checked because a
prerequisite was unscored; each place the two Prerequisites sources disagree; for a PRD run, a `nice-to-have` requirement scored
above a `must-have` one. No entries → `None.`.

## Additional runs

Adding a run of another method (collision choice 2) appends below `## Open Questions`:

```markdown
## Additional Run: MoSCoW (2026-10-20)

### Method
### Scores
### Dependency Conflicts
### Proposed Sequence Changes
### Open Questions
```

with the same content rules, one `###` level down. The top-level sections and the `method` key stay those of the first run.

## Self-check

Run before showing the draft; fix and re-run:

1. Every score in `## Scores` was produced by the scoring command from the inputs in its own row; re-running the command on the row
   gives the same number. Every input is in its allowed set; every effort is greater than 0.
2. No item with Status `done` appears anywhere in the file.
3. Rows are sorted by score (or category) descending, ties in roadmap order; rank numbers run 1..k without gaps among scored rows.
4. Every line in `## Dependency Conflicts` matches a `CONFLICT` line of the sequence command, and every `CONFLICT` line is in the table.
5. Every id in `## Proposed Sequence Changes` exists in `## Scores`; positions match the `ORDER` line.
6. No effort or other size estimate appears outside this file; none was written to `roadmap.md`.
7. The five headings exist, in order, with the fixed table headers for the method.

## Worked example (fixture project `recipe-fridge`, illustrative inputs)

The inputs below are invented to show the arithmetic; they are not a recommendation, and the skill never proposes values like these.
Unfinished roadmap items are S-04, S-05, S-06 (F-01 and S-01..S-03 are `done` and excluded).

| ID | Reach | Impact | Confidence | Effort | Score |
|---|---|---|---|---|---|
| S-04 | 400 | 1 | 80 | 3 | 106.7 |
| S-05 | 300 | 0.5 | 100 | 2 | 75.0 |
| S-06 | 600 | 2 | 80 | 4 | 240.0 |

S-06's prerequisite is S-04 (unfinished) and S-06 scores higher, so `## Dependency Conflicts` has the row "S-06 needs S-04 first".
S-05's prerequisite S-03 is `done`, so it never conflicts. The proposed order is S-04, S-06, S-05 against the roadmap's S-04, S-05, S-06.
