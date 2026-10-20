---
name: pm-prioritize
description: >
  Rank what is left to build with a scoring method the person picks: RICE (recommended), ICE or MoSCoW. Scores every
  roadmap item that is not done (without a roadmap: the PRD's requirements) from inputs the person supplies, never
  guessed; computes each score with python3, not in the head; reports dependency conflicts ("S-06 needs S-04 first"
  when an item outranks its own prerequisite); proposes sequence changes the person can take to a /sdd-roadmap
  re-run; writes foundation/<slug>/prioritization.md. Never edits roadmap.md. Use after the roadmap exists, or any
  time the order is being argued about. Trigger phrases: "prioritize the roadmap", "rank the backlog", "RICE score",
  "ICE score", "MoSCoW", "what should we build first", "what to cut", "prioritise these features", "score these items",
  "priorytetyzacja", "zrób priorytetyzację", "uszereguj roadmapę", "co budować najpierw", "co wyciąć", "ocena RICE",
  "metoda MoSCoW", "ranking funkcji".
---

# /pm-prioritize — Rank What Is Left to Build

Turns "what should we do first?" from an argument into a table. The person supplies the judgement (how many people, how much it
matters, how sure, how much work); this skill does the arithmetic, sorts, checks the order against the roadmap's own dependencies
and writes down what it found. It is a **scorer and a checker**, not an oracle: every number in the file was given by the person
or computed from numbers the person gave, and the roadmap itself is never touched.

## When to use, when to skip

**Use when** a `roadmap.md` has at least two items that are not `done` and the person wants them ranked, or wants to test an order
someone proposed. Also when there is no roadmap yet but a `prd.md` has requirements to rank (a lighter result: no dependency check).

**Skip when** there is no PRD (`/pm-discover`), the question is "when will it be done?" (`/pm-forecast`), the question is whether
the plan is right rather than the order (`/sdd-roadmap`), or fewer than two items are unfinished (nothing to rank).

## Relationship to other skills

- `/sdd-roadmap` — owns `roadmap.md`. This skill reads it and never edits it. A proposed order becomes real only when the person
  brings the list to a `/sdd-roadmap` re-run, whose interview accepts overrides in the person's own words (Step 10).
- `/pm-metrics` — if `metrics.md` exists its baselines may help the person estimate reach; nothing is copied from it.
- `/pm-forecast` — turns throughput history into date ranges. The effort number asked here is a ranking input, not a schedule.
- `/pm-backlog-sync` — pushes the roadmap's items to a tracker; it does not use this file's order (the roadmap is the source).
- `/pm-help` — the map of the PM flow.

Shared rules, linked rather than restated: finding the root and the project — `../pm-help/references/context-resolution.md`; the
contract check and the roadmap headings — `../pm-help/references/sdd-contract.md`; audience and plain language —
`../pm-help/references/plain-language.md`; where `prioritization.md` sits among the PM artifacts —
`../pm-help/references/pm-artifacts.md`; scales, formulas, the conflict rule and the file layout — `references/frameworks.md`;
behavior fixtures — `references/eval-cases.md`.

## Initial Response

1. **A project name** → use it. **A method named** ("RICE", "MoSCoW") → remember it as the person's choice for Step 4.
2. **Nothing given** → resolve the project (Step 1).
3. **A request to change the roadmap** ("move S-05 up in the roadmap", "apply this ranking to the roadmap") → say plainly that this
   skill never edits `roadmap.md`; offer to score and propose the order, then hand the list over for a `/sdd-roadmap` re-run (Step 10).
   Carry on with scoring if the person agrees.

Say what is about to happen in one or two sentences, for example: "I'll list what is still to build, ask you a few numbers about each
item (I won't guess any), score them, and check that nothing you rank higher has to be built after something you rank lower. If you
don't know a number, we skip that item rather than invent one."

## Process

Facilitation style (as the `sdd-*` skills do): recommended option first, marked "(Recommended)", always a "Not sure" option, one decision
at a time, echo back and confirm before anything is written, never invent content.

### Step 1 — Audience, root and project

1. Resolve the audience per `../pm-help/references/plain-language.md` (ask once if `audience:` is absent). Plain mode: say "a scoring
   method" for RICE/ICE ("weighs how many people it reaches, how much it matters to each, how sure you are, and how much work it is"),
   "how many people it reaches", "how much it matters to each person", "how sure you are", "how much work (your own rough estimate, in
   person-weeks)", "has to be finished first" for prerequisites, "sort each into must, should, could or won't this time" for MoSCoW, and
   "something you ranked higher has to be built after something you ranked lower" for a dependency conflict. Keep ids (`S-04`) and file
   paths for the file. The saved file is identical in both modes.
2. Resolve `CONTEXT_ROOT` and the project per `../pm-help/references/context-resolution.md`. No root, or no project folder with a
   `roadmap.md` or `prd.md` → say so, point at `/pm-discover`, STOP. Several projects → ask which; a named one wins.

### Step 2 — Source and contract check (STOP on mismatch)

- **`roadmap.md` exists** → it is the source (`basis: roadmap`). Run the `## Contract check procedure` in
  `../pm-help/references/sdd-contract.md` with the `roadmap` heading list (`## Streams` optional) **before reading anything else
  from it**: test every heading for an exact whole-line match. Any missing → print one line and STOP: no questions, no draft, no file,
  no fall back to the PRD.

  ```
  CONTRACT MISMATCH: roadmap.md missing ## At a glance, ## Slices; sdd-skills expected 0.4.1
  ```

  (names comma-separated). Plain mode says it in words (the build plan is missing sections my steps rely on; please re-run the planning
  step) and keeps the exact line for the technical log.
- **No `roadmap.md`, but `prd.md` exists** → say so and ask:

  ```
  There is no roadmap yet, so I can rank the PRD's requirements, but I can't check dependencies (a roadmap records them).
  1. Rank the requirements now (Recommended)  2. Stop; build the roadmap first (/sdd-roadmap)  3. Not sure, explain
  ```

  Option 2 → STOP. Option 1 → run the contract check on `prd.md` (`prd-greenfield` or `prd-brownfield` by `context_type`, as in the
  contract) and continue with `basis: prd`.
- **Neither file** → STOP, point at `/pm-discover`.

### Step 3 — Read the items

**Roadmap.** Parse `## At a glance` by header text, not by column position: `ID`, `Change ID`, `Outcome (user can …)`, `Prerequisites`,
`PRD refs`, `Status`. For every row:

- **Excluded:** Status `done`. They are listed once, by id, in `## Method` and appear nowhere else in the file.
- **Prerequisite ids:** every `F-NN` / `S-NN` in the row's `Prerequisites` cell **and** in the matching slice body's
  `- **Prerequisites:**` line under `### <ID>:`, taken together. Text that is not an id (for example "ingredient unit convention
  agreed") is an outside condition: remembered for `## Open Questions` and the Notes cell, never checked. An id absent from the table, or
  a disagreement between the two sources, becomes an Open Question; the union is used.
- **Flags:** Status `blocked` → scorable, but flagged "blocked (waiting on a decision)" (the slice's Unknown with `Block: yes` is the
  reason). Status `planning` / `in-progress`, or an existing `$CONTEXT_ROOT/changes/<change-id>/change.md` (read-only look) → flagged
  "already in progress (changes/<change-id>/)": moving it later means pausing work that has begun.
- Keep the table's order: it is the roadmap's dependency order and the tie-breaker.

Fewer than two unfinished items → say there is nothing to rank, STOP.

**PRD (no roadmap).** Greenfield: each `- FR-NNN:` line of `## Functional Requirements` is an item (id `FR-NNN`, text, the PRD's
`Priority:` kept as context, never as a score). Brownfield: each `[new]` or `[modified]` bullet of `## Scope of Change` is an item with
a label `SC-01`, `SC-02`, … in PRD order (labels exist only in this file); `[removed]` and `[preserved]` are not items. No prerequisites.

Then check for an existing `$CONTEXT_ROOT/foundation/<slug>/prioritization.md`. If it exists, read it, remember its `created` date and
its method(s), and tell the person once that Step 9 will compare before anything is written. Nothing is written in the meantime.

### Step 4 — Pick the method

```
How do you want to score the <m> items that are still to build?
1. RICE (Recommended): reach × impact × confidence ÷ effort. Best when you can estimate how many people it touches and the work involved.
2. ICE: impact × confidence × ease, each 1 to 10. Quicker; no reach or effort needed.
3. MoSCoW: sort each item into Must / Should / Could / Won't for this release. No numbers; good for fixed deadlines.
4. Not sure, explain
```

"Not sure" explains the three in one sentence each, recommends RICE when the person can give rough reach and effort, ICE when they cannot,
MoSCoW when the argument is about what fits a date, and asks again. The choice is echoed back. If the person asked for a method in the
Initial Response, confirm it instead of asking.

### Step 5 — Collect the inputs (never guessed)

Show once, for the chosen method, the scales from `references/frameworks.md` (sets, meanings). For RICE also ask once, and record in
`## Method`, **how reach is counted** (the person's unit and period, for example "households per month"); every item uses it. If
`metrics.md` exists, mention that its baselines may help; copy nothing.

Then go **item by item**, in roadmap order. Show the id, the outcome, its flags, and ask for the inputs, one line or one at a time:

```
S-04: user can get a shopping list of the ingredients a recipe still needs   (proposed)
RICE inputs: reach (people per <the unit>), impact (0.25 / 0.5 / 1 / 2 / 3), confidence (50 / 80 / 100), effort (person-weeks, your own estimate)
Give them, or say "skip" (this item stays unscored) / "skip all remaining" / "Not sure, explain".
```

Rules:

1. **Every value is the person's.** No defaults, no "typical" values, no benchmarks, no estimate from the roadmap, `forecast.md` or
   history. Impact words ("high") map only through the table in `references/frameworks.md`; echo the number back ("impact 2, high").
2. **Validate before computing.** Each value must be a plain number in its allowed set: RICE reach a number of 0 or more; impact one of
   0.25, 0.5, 1, 2, 3; confidence one of 50, 80, 100; effort **greater than 0**, in person-weeks. ICE: whole numbers 1 to 10. MoSCoW:
   exactly Must, Should, Could or Won't. A value outside its set is rejected with a one-line reason and the allowed values, nothing is
   computed, and **that input is asked again**. Examples: "Effort must be greater than 0: it's in person-weeks (for example 0.5 for a
   couple of days). What's your estimate?"; "Impact has to be 0.25, 0.5, 1, 2 or 3."; effort given in days → ask for person-weeks, do
   not convert it for them; confidence "0.8" → "use 50, 80 or 100".
3. **Skip is fine.** "Skip", "don't know", an empty or evasive answer → the item is **unscored**, with an Open Question; no pressure,
   no estimate offered. "Skip all remaining" leaves every remaining item unscored.
4. **Effort is the person's own estimate and lives only in `prioritization.md`** (this file and `forecast.md` are the only places a size
   estimate appears). Say so when effort is first asked; never write it anywhere else, never into `roadmap.md`.
5. Fewer than two items scored at the end → say a ranking needs two; offer to keep scoring or stop. Zero scored → STOP, no file.

### Step 6 — Compute and rank

**All arithmetic goes through `python3 -c`, never in the head.** The command takes only numbers: values the person typed are first
parsed into plain numbers and validated against the allowed sets in Step 5, and the numbers (never the person's words) are passed as
separate arguments to a fixed script in single quotes. Nothing the person wrote is ever placed inside the script text or run as a
command. The script validates again and exits non-zero with an `INVALID:` message on anything off; on a non-zero exit show the message,
ask for the input again, and never print a score. Exact form (RICE: `rice <reach> <impact> <confidence> <effort>`; ICE:
`ice <impact> <confidence> <ease>`):

```bash
python3 -c 'import sys,re
from decimal import Decimal,ROUND_HALF_UP
m,*a=sys.argv[1:]
if not all(re.fullmatch(r"\d+(\.\d+)?",x) for x in a): sys.exit("INVALID: every input must be a plain non-negative number")
v=[Decimal(x) for x in a]
if m=="rice" and len(v)==4:
    r,i,c,e=v
    if i not in map(Decimal,("0.25","0.5","1","2","3")): sys.exit("INVALID: impact must be 0.25, 0.5, 1, 2 or 3")
    if c not in (50,80,100): sys.exit("INVALID: confidence must be 50, 80 or 100")
    if e<=0: sys.exit("INVALID: effort must be greater than 0 (person-weeks)")
    print((r*i*c/100/e).quantize(Decimal("0.1"),ROUND_HALF_UP))
elif m=="ice" and len(v)==3:
    if any(x!=x.to_integral_value() or not 1<=x<=10 for x in v): sys.exit("INVALID: impact, confidence and ease must be whole numbers 1 to 10")
    print(int(v[0]*v[1]*v[2]))
else: sys.exit("INVALID: usage: rice reach impact confidence effort | ice impact confidence ease")' rice 400 1 80 3
```

(prints `106.7`). One call per item. Rank best first by score; equal scores keep roadmap order. MoSCoW has no arithmetic: rank by category
(Must, Should, Could, Won't), then roadmap order.

Show the ranked table (id, outcome, inputs, score, flags) and ask once: "Re-check any of these inputs? (name an item / no)". A named
item gets its inputs re-asked (Step 5 rules) and recomputed. Never adjust a number to make the order look right.

### Step 7 — Dependency conflicts and the proposed order

Run the sequence command **once** for the scored and unscored items together; it applies the conflict rule in `references/frameworks.md`
(a RICE/ICE item scoring strictly higher than a prerequisite; a MoSCoW Must whose prerequisite is Could or Won't; `done` prerequisites
are not in the list so they never conflict; an unscored prerequisite is looked through) and builds the dependency-respecting order. One
argument per item in roadmap order, `ID=score=PREREQS`: the RICE/ICE score, or the MoSCoW rank (Must 4, Should 3, Could 2, Won't 1), or
`-` when unscored; `PREREQS` is a comma-separated list of ids or `-`. Ids are validated first (`[A-Z]{1,2}-` and digits) and only
unfinished prerequisites are listed. First argument: `rice`, `ice` or `moscow`.

```bash
python3 -c 'import sys,re
from decimal import Decimal
mode,*args=sys.argv[1:]
if mode not in("rice","ice","moscow"): sys.exit("INVALID mode")
it={};seq=[]
for a in args:
    p=a.split("=")
    if len(p)!=3 or not re.fullmatch(r"[A-Z]{1,2}-\d+",p[0]) or not re.fullmatch(r"-|\d+(\.\d+)?",p[1]) or not re.fullmatch(r"-|[A-Z]{1,2}-\d+(,[A-Z]{1,2}-\d+)*",p[2]): sys.exit("INVALID item: "+a)
    it[p[0]]=(None if p[1]=="-" else Decimal(p[1]),set() if p[2]=="-" else set(p[2].split(",")));seq.append(p[0])
def need(x,seen=()):
    for q in sorted(it[x][1]&set(it)):
        if q in seen: continue
        if it[q][0] is None: yield from need(q,seen+(x,))
        else: yield q
out=[]
while len(out)<len(seq):
    ok=[x for x in seq if x not in out and all(q in out for q in it[x][1]&set(it))]
    if not ok: sys.exit("CYCLE among: "+" ".join(x for x in seq if x not in out))
    out.append(max(ok,key=lambda x:(it[x][0] if it[x][0] is not None else -1,-seq.index(x))))
print("ORDER "+" ".join(out))
for a in seq:
    if it[a][0] is None: continue
    for b in dict.fromkeys(need(a)):
        if (it[a][0]==4 and it[b][0] in(1,2)) if mode=="moscow" else it[a][0]>it[b][0]: print("CONFLICT",a,"needs",b,"first")' rice S-04=106.7=- S-05=75.0=- S-06=240.0=S-04
```

(prints `ORDER S-04 S-06 S-05` and `CONFLICT S-06 needs S-04 first`). A `CYCLE` or `INVALID` exit → report it and STOP the pass; the roadmap's
own prerequisites form a cycle, which is a `/sdd-roadmap` problem, not something to repair here. PRD runs pass `-` for every `PREREQS` and
skip the conflict table.

From the output build the file's sections (formats in `references/frameworks.md`):

- **`## Dependency Conflicts`**: one row per `CONFLICT` line, worded "A needs B first", with both scores (or categories). None → `None.`
  PRD run → "Not checked: no roadmap, so no prerequisites are recorded."
- **`## Proposed Sequence Changes`**: compare the `ORDER` line with the roadmap's current order **among the scored items only** (unscored items
  are not moved). For each scored item that moves **earlier**, one numbered line: "Move S-06 from position 3 to 2 of 3 (ahead of S-05): it
  scores 240.0 against 75.0." Items that only shift later because another moved ahead are not listed as moves. Add a note line for each
  moved item that is `blocked` (moving it earlier changes nothing until its decision is made) and for each item that shifts later and is
  already in progress (it pauses work that has begun), and for a not-done north-star slice moved later than it is
  now ("this moves the north star later; `/sdd-roadmap` places it early on purpose"). Order identical → "None: the scores agree with the
  current order." A PRD run lists the proposed priority order of requirements instead, labelled as having no dependency check.
- **`## Open Questions`** (format in `references/frameworks.md`): unscored items, missing prerequisite ids, outside conditions, source
  disagreements, pairs that could not be checked, and for a PRD run a `nice-to-have` requirement scored above a `must-have` one.

### Step 8 — Self-check and confirm

Run the self-check list in `references/frameworks.md` (fix, then re-run; a dropped item is reported, other fixes are silent). Print the draft
compactly (the ranked table, the conflicts, the proposed changes, the number of open questions) and ask:

```
Write it? 1. Looks right, write prioritization.md (Recommended)  2. Change something (name an item and input)  3. Not sure, walk me through it
```

Apply changes, re-run the affected commands and the self-check, show only what moved.

### Step 9 — Write

Path: `$CONTEXT_ROOT/foundation/<slug>/prioritization.md`; layout and frontmatter in `references/frameworks.md`; dates from `date +%Y-%m-%d`.
New file: `created` and `updated` are today.

**A `prioritization.md` already exists** → never write first. Show a **diff** (existing file against the new draft: lines removed `-`, lines
added `+`, each hunk under its `##` heading; unchanged sections named, not printed; a scratch copy of the draft outside `$CONTEXT_ROOT` for
`diff -u` is fine) and ask:

```
prioritization.md already exists (last updated <date>, method <method>). What now?
1. Overwrite (keeps its created date)  2. Add this as a new method run, appended below the existing one  3. Cancel, change nothing  4. Not sure
```

Put the recommended mark on 2 when the new method differs from every method already in the file, and on 1 when it is the same method. Option 2 is
not offered when the new run uses a method the file already holds ("a new run of the same method replaces it"; offer Overwrite or Cancel).

- **Overwrite** replaces the file with the new draft, keeping `created`; `updated` is today. The diff already shown is the record of what is lost.
- **Add a new method run** keeps the existing file as is (top-level sections and `method` stay those of the first run), sets `updated` to today and
  appends `## Additional Run: <METHOD> (<date>)` with the five `###` subsections, as in `references/frameworks.md`. Print the appended block
  before writing it.
- **Cancel** or no answer → no write, and say so. "Not sure" explains the two options in a sentence each and asks again.
- A file that exists but lacks the five headings cannot take an appended run: say so, offer Overwrite (the diff shows the loss) or Cancel.

After writing, read the file back to confirm the frontmatter keys (`project`, `method`, `created`) and the five `##` headings exist, then print
the path (technical mode) or say it is saved (plain mode).

### Step 10 — Handoff

The proposed changes are a **list the person brings to a `/sdd-roadmap` re-run**: its interview accepts overrides in the person's own words (for
example "put S-05 before S-04"). That re-run regenerates the roadmap and asks before replacing the existing file. This skill does not edit
`roadmap.md`, prepare the re-run, or start it.

Plain mode ends with the handoff block from `../pm-help/references/plain-language.md`: how many items were ranked, how many conflicts were
found, that the order above is only a suggestion until the plan itself is changed, and the next step in product terms:
"update the plan with these priorities" (`/sdd-roadmap`), then "set up the tracker" (`/pm-backlog-sync`) or "see when it could be done" (`/pm-forecast`). Technical mode
prints the file path, the counts (scored, unscored, conflicts, proposed changes) and the exact next command (`/sdd-roadmap`). A PRD run says the
next step is the roadmap, after the technology step. Confirm a skill is in the host's available list before naming it. Do not start the next
skill.

## Output

One file: `$CONTEXT_ROOT/foundation/<slug>/prioritization.md`; frontmatter `project`, `method` (`rice` | `ice` | `moscow`), `basis`, `created`,
`updated`; sections `## Method`, `## Scores`, `## Dependency Conflicts`, `## Proposed Sequence Changes`, `## Open Questions`. Format and example:
`references/frameworks.md`. Besides this file the skill may write `audience:` to `.sdd.local.yml` (plain-language rule) and nothing else.

## Critical guardrails

Never writes `prd.md`, `shape-notes.md`, or `roadmap.md`.

1. **Never edits the roadmap.** "Apply this ranking to the roadmap" is declined; the answer is the proposed list and a `/sdd-roadmap` re-run in the person's hands. No status, order or estimate is ever written to `roadmap.md`.
2. **Never invents an input.** Reach, impact, confidence, effort, ease and categories come from the person, from the allowed sets only; a missing one leaves the item unscored. No defaults, benchmarks or guesses, and no effort derived from `forecast.md` or history.
3. **Scores are computed with `python3 -c`, never mentally,** from validated numbers passed as arguments. Text the person typed is never placed in a script or a shell command. An `INVALID:` exit shows its message and re-asks; no score is shown for it.
4. **Done items are excluded.** `done` items are never scored, listed as candidates or counted as conflicts; `blocked` items are scored and flagged; in-progress items are scored and flagged.
5. **Dependency beats score.** A higher score than a prerequisite is reported as "A needs B first"; the proposed order always puts unfinished prerequisites first. Finished prerequisites never conflict.
6. **Effort stays here.** The effort estimate is the person's own, appears only in `prioritization.md` (besides `forecast.md`), and is never copied into `roadmap.md`.
7. **Contract first.** A missing `roadmap.md` heading (or PRD heading, in a PRD run) → one `CONTRACT MISMATCH` line and STOP, before any question. A broken roadmap is not silently replaced by the PRD.
8. **No silent overwrite.** An existing `prioritization.md` triggers the diff and the Overwrite / Add run / Cancel question.
9. **Own files only.** Writes `prioritization.md` and `audience:` in `.sdd.local.yml`. `changes/**`, `archive/**`, `roadmap.md`, `prd-vN.md` are never touched.
10. **Never chain.** Do not start `/sdd-roadmap`, `/pm-forecast` or any other skill; the human decides.
11. **Mirror the user's language.** Questions, flags and notes follow the user's language; ids, headings, method names and `Must / Should / Could / Won't` stay as written.

## Notes

- A single-method file is the normal case. A second method (say MoSCoW after RICE) is added as an appended run when the person wants a second opinion.
- Re-running after a slice finished is normal: the item is now `done`, drops out of the list, and its dependants stop conflicting with it.
- Fixture example and behavior cases: `references/eval-cases.md`.
