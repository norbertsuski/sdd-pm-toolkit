---
name: pm-discover
description: >
  The product manager's discovery router. Works out, from the files on disk, where a product idea stands
  — no project folder yet, idea not shaped, shaping half-done, shaped, PRD drafted, PRD reviewed, waiting
  on the technology choice, ready for a roadmap — and walks the PM through the one next step, with a human
  yes between every step: /sdd-init, then (only if the idea is a solution without a problem) /sdd-frame,
  /sdd-shape, /sdd-prd, /pm-prd-review, the stack step, /sdd-roadmap. It produces no artifacts itself and
  never chains steps on its own. Hands a research insights file from /pm-research-synthesis to /sdd-shape
  as the seed. Use when the user has an idea, research, or a half-finished product definition and asks what
  to do next. Trigger phrases: "I have a product idea", "start a new product", "discover this idea",
  "shape this idea", "write a PRD", "what's the next discovery step", "where are we in discovery",
  "take me from idea to roadmap", "mam pomysł na produkt", "zacznij nowy produkt", "doprecyzuj pomysł",
  "napisz PRD", "co dalej w discovery", "od pomysłu do roadmapy", "przeprowadź mnie przez discovery".
---

# /pm-discover — From an Idea to a Build-Ready Plan, One Gated Step at a Time

A router, not a writer. It looks at what exists on disk, names the project's discovery stage in plain words,
proposes the single next step, and on a yes hands over to the skill that owns that step. When that skill
finishes it looks again and proposes the next one. The shaping conversation, the PRD and the roadmap all stay
with the `sdd-*` skills; this skill adds the sequencing, the stage detection and the hand-offs between them.

## When to use, when to skip

**Use when** the user has an idea (a sentence, a research insights file, a half-finished shaping session or a
draft PRD) and wants to be taken, step by step, to a roadmap — or just asks what the next step is.

**Skip when** the user only wants to know where a project stands across all PM and SDD artifacts (`/pm-help <project>`),
has raw research that is not yet synthesized (`/pm-research-synthesis` first), wants the PRD reviewed right now
(`/pm-prd-review`), or the project already has a roadmap (the stage report ends with a hand-over, see Step 5).

## Relationship to other skills

Owned by `sdd-skills` (checked in Step 1, started through the Skill tool, never copied): `/sdd-init`, `/sdd-frame`,
`/sdd-shape`, `/sdd-prd`, `/sdd-roadmap`. The stack step is also theirs: `/sdd-tech-stack-selector` for a
greenfield PRD, `/sdd-stack-assess` then `/sdd-health-check` for a brownfield one. Owned by this plugin:

- `/pm-research-synthesis` — upstream. Its `## Seed for shaping` section feeds `/sdd-shape`.
- `/pm-prd-review` — the review step. Referenced by name; if the host does not list it, the step is skipped with a note (Step 4).
- `/pm-prioritize`, `/pm-backlog-sync` — where a project with a roadmap goes next.
- `/pm-help` — the map; `/sdd-help` explains the sdd side.

Shared rules, linked rather than restated: finding the root and the project —
`../pm-help/references/context-resolution.md`; audience and plain language —
`../pm-help/references/plain-language.md`; the install block, the PRD contract and the shape-checkpoint and
stack-signal strings this skill reads — `../pm-help/references/sdd-contract.md`; behavior fixtures —
`references/eval-cases.md`.

## Initial Response

1. **An idea in words** (`/pm-discover a recipe app that suggests meals from what is in the fridge`) → keep it verbatim as the idea.
2. **A path** (`/pm-discover @…/research/2026-10-12-fridge-habits.md`) → treat it as the research file for Step 4.
3. **A project name** → use it as the project pick in Step 2.
4. **Nothing** → start at Step 1; the idea is asked for only when the stage turns out to be `unshaped`.

## Process

Facilitation style (as the `sdd-*` skills do): recommended option first, marked "(Recommended)", always a
"Not sure" option, one question at a time. **Exactly one step per gate**: after each step ask, wait for the
answer, act only on a yes. Never start a second skill because the first one succeeded.

### Step 1 — Required skills

Check that `sdd-init`, `sdd-frame`, `sdd-shape`, `sdd-prd`, `sdd-roadmap` are among the host's available skills
(the host may list them as `sdd-skills:<name>`). Any missing → print the **Install block** from
`../pm-help/references/sdd-contract.md` (section `## Install block`) verbatim, say which were not found, and
**STOP**. Do not derive a stage and do not offer a workaround.

### Step 2 — Root, project and audience

1. Resolve `CONTEXT_ROOT` as `../pm-help/references/context-resolution.md` says. **No root found** → the stage is
   `uninitialized`: skip to Step 4 and offer `/sdd-init` (nothing else; the project, the idea and the audience
   come later). A root found but not yet picked → show the pick with the nearest preselected.
2. Resolve the project: a name or path the user gave wins; one project → use it and say which; several → ask
   which (show each slug and, where a `prd.md` exists, its project name). **No project folder at all** is a valid
   result (stage `unshaped`, new idea). A folder that holds only `research/` counts as a project.
3. Resolve the audience per `../pm-help/references/plain-language.md`: read `audience:` from
   `$CONTEXT_ROOT/.sdd.local.yml`; absent → ask once, and write `plain` (the PM default) or `technical` into that file,
   creating `$CONTEXT_ROOT/.gitignore` with the line `.sdd.local.yml` first if needed. Because this is the same
   key the `sdd-*` skills read, they will not ask again. In plain mode say "your idea", "the product write-up",
   "the build plan"; the table in Step 3 gives the words.

### Step 3 — Derive the stage (first match wins)

Read-only probes (`find`, `test`, `ls`, `grep`, Read). `<P>` = `$CONTEXT_ROOT/foundation/<slug>`.

| # | Stage | Detected by | Owner of the next step |
|---|---|---|---|
| 1 | `uninitialized` | no context root | `/sdd-init` |
| 2 | `unshaped` | no `<P>/shape-notes.md` **and** no `<P>/prd.md` (or no project folder yet) | `/sdd-shape` (`/sdd-frame` first when the idea is a solution without a problem) |
| 3 | `shaping` | no `<P>/prd.md`; `shape-notes.md` frontmatter `checkpoint.current_phase` below 8 (or the block is unreadable) | `/sdd-shape` (resumes from its own checkpoint) |
| 4 | `shaped` | no `<P>/prd.md`; `checkpoint.current_phase` is 8 | `/sdd-prd` |
| 5 | `specified` | `<P>/prd.md` exists and is **not reviewed** (see the rule below) | `/pm-prd-review` (or resuming the latest saved review) |
| 6 | `stack-pending` | `prd.md` **reviewed** (see the rule below); no `<P>/roadmap.md`; stack signal absent | the stack step, by a developer |
| 7 | `reviewed` | as 6 but the stack signal is present | `/sdd-roadmap` |
| 8 | `roadmapped` | `<P>/roadmap.md` exists | hand over: `/pm-prioritize`, `/pm-backlog-sync` |

Rules that keep the table honest:

- **`prd.md` wins over shape state.** A PRD that was written by hand, or whose `shape-notes.md` was moved or never
  existed, is legitimate (the `sdd-skills` rule): rows 2–4 apply only while there is no `prd.md`, so a project with
  a `prd.md` but no `shape-notes.md` starts at row 5.
- **Row 3 vs row 4 comes from `shape-notes.md`, never from the conversation.** Read `checkpoint.current_phase`
  (`1`..`6` discovery, `7` closing cross-check, `8` finalized; strings in `../pm-help/references/sdd-contract.md`,
  section `## Shape checkpoint contract`). Only an exact `8` is `shaped`.
- **Reviewed means one of two things.** `prd.md` frontmatter `status` is `reviewed` or `locked`; or the **latest**
  `<P>/prd-review-*.md` has frontmatter `verdict: APPROVED`. Latest = newest date in the file name, then the highest
  `-N` suffix (`prd-review-2026-10-18-2.md` is later than `prd-review-2026-10-18.md`). Any other case is **not reviewed**:
  no report, or a latest report whose verdict is `NEEDS_ATTENTION` or `REJECTED`. A saved but unfinished or negative
  review never lets the PRD through to the stack step or the roadmap.
- **Row 5 and 6 read only the frontmatter of `prd.md`** (`status`, `context_type`), the file names and the frontmatter
  `verdict` of the latest review report; no section is parsed, so the contract check procedure is not needed here.
  Whoever reads headings later runs it first.
- **Row 5 wins over row 8** even if a `roadmap.md` already exists: a PRD that is not reviewed (never reviewed, or its latest review ended `NEEDS_ATTENTION` or `REJECTED`) is flagged first.
  Say that a build plan already exists, so the review is a check after the fact; the choice stays with the PM.
- **The stack signal** (row 6/7) is file presence only, and root-level: `$CONTEXT_ROOT/foundation/tech-stack.md`
  when the PRD's `context_type` is `greenfield`, `$CONTEXT_ROOT/foundation/stack-assessment.md` when `brownfield`
  (paths in the contract, section `## Stack signals`). A signal written for another project under the same root
  counts: it is shared. `context_type` missing and neither file present → ask whether this is a new product
  or a change to an existing system; do not guess.
- Several projects: stage is derived for the project picked in Step 2, never mixed.

Plain-mode words for each stage and its next step (show the command once in parentheses):

| Stage | Plain wording | Next step in words |
|---|---|---|
| `uninitialized` | "There is no notes folder for product work in this repository yet." | Set it up (`/sdd-init`) |
| `unshaped` | "Your idea hasn't been talked through yet." | A guided conversation that turns it into a clear product idea (`/sdd-shape`) |
| `shaping` | "You started talking the idea through and stopped part-way." | Pick the conversation up where it stopped (`/sdd-shape`) |
| `shaped` | "The idea is fully talked through; no product write-up yet." | Write the product write-up (`/sdd-prd`) |
| `specified` | "The product write-up is a first draft nobody has checked." (or, after a review that found problems: "A review found things to settle before planning.") | Have it reviewed for gaps and risks, or pick the unfinished review back up (`/pm-prd-review`) |
| `stack-pending` | "The write-up is reviewed. One technical decision is still open." | A developer chooses the technology (see Step 4) |
| `reviewed` | "The write-up is reviewed and the technology is decided." | Turn it into a build plan (`/sdd-roadmap`) |
| `roadmapped` | "There is a build plan." | Rank the pieces or send them to your tracker (`/pm-prioritize`, `/pm-backlog-sync`) |

### Step 4 — Present the stage and the one next step; on yes, invoke the owner

Print the stage and the next step in the audience's words (one short paragraph, no menu of stages), then ask
for the go-ahead with the options named in the sub-step for that stage. **A yes starts exactly that skill**
through the Skill tool, passing the arguments below. Anything else, including silence on a "Not sure", stops
the run. When the invoked skill finishes, **go back to Step 3 and re-derive from disk** (never from memory of
what the skill said it did); then offer the next step. If the invoked skill stopped early, say so in one line
and re-derive anyway: the stage will still be the same one, and that is the honest answer.

**`uninitialized`** — offer only `/sdd-init`: "Set up the notes folder? 1. Yes, set it up (Recommended)  2. Not now". Nothing else is
offered or discussed. On yes, ask for the target folder (default the repository root), invoke `/sdd-init`, then
return to Step 2 (root discovery runs again).

**`unshaped`** — needs the idea and, if it exists, the research.
1. **Research present?** Look for `foundation/*/research/*.md` (the chosen project's folder first; if several
   files exist, offer the newest by date in its name, list the others). If a research file exists → go to 3.
2. **No research.** Ask for the idea in one line if it was not given. If it is **solution-shaped** — it says
   what to build ("build X", a feature or tool) and states no problem, user or pain — offer the framing check
   first: "Before we shape this, check that it solves a real problem? 1. Yes, check the problem first (Recommended)
   2. No, shape it as it is 3. Not sure". On 1, invoke `/sdd-frame` with the idea verbatim, then re-derive;
   frame produces no PRD and does not change the stage. Then `/sdd-shape <idea verbatim>` on a yes.
3. **With research:** the seed is the research file. `/sdd-shape` reads the whole file as its seed
   (`/sdd-shape @<research path>`). **Before invoking, tell the operator which project name to confirm.**
   `/sdd-shape` proposes a name from the seed at its project-name step and asks "Use this name?". The name that keeps the
   research next to the product is the research folder's own name, spoken as words (`recipe-fridge` → "Recipe Fridge"):
   > When it asks you to confirm the project name, pick "Recipe Fridge" (or choose Rename and type it), so your research stays with the product.
   In plain mode say this in words with no folder talk. A different name still works; the post-shape check below
   deals with it.
   Snapshot the existing `foundation/*/shape-notes.md` paths, then invoke.
4. **After `/sdd-shape` returns — slug-mismatch check.** Find the `shape-notes.md` that is new since the snapshot.
   If it sits in `foundation/<slugB>/` while the research file sits in `foundation/<slugA>/research/` and
   `<slugA>` ≠ `<slugB>`, the research and the shaping ended up in different folders. **Offer, never do silently**:
   > Your research is in "<A>" but the product was saved as "<B>". Move the research next to it? 1. Yes, move it (Recommended) 2. Leave it where it is 3. Not sure
   On yes run `git mv foundation/<slugA>/research foundation/<slugB>/research` (paths under `$CONTEXT_ROOT`), tell the
   operator it is staged but not committed, and leave the old folder alone; if it is empty now, mention that, do not delete it.
   Fallbacks, each also offered, not assumed: the research folder is untracked (`git mv` fails) → offer plain `mv`;
   `foundation/<slugB>/research` already exists → list the files that would move, move only non-colliding ones on a yes,
   never overwrite. On 2 or 3 do nothing and say where the research stays. In plain mode say "move your notes next to the product" and
   do not show the command. Then continue to re-derivation (Step 3), which now reads the new project.

**`shaping`** — "Resume the conversation? 1. Yes, pick it up where it stopped (Recommended) 2. Not now". On yes invoke
`/sdd-shape` with no idea text and, when the project is known, no path either: it finds its own checkpoint and
offers to resume. Never route to `/sdd-prd` from here, even if the operator says "it feels done": the checkpoint says
the closing cross-check did not finish, so the PRD would be written from an unfinished shaping.

**`shaped`** — "Write the product write-up now? 1. Yes (Recommended) 2. Not now". On yes invoke `/sdd-prd @<path to the project's shape-notes.md>` (it takes a path argument, so it cannot pick another project's notes).

**`specified`** — recommend the review. First confirm `pm-prd-review` is among the host's available skills.
- **Available, and the latest `prd-review-*.md` has `verdict: NEEDS_ATTENTION` or `REJECTED`** → say what that review concluded
  in words (and that it was saved on its date), then: "Pick that review back up and settle what's open? 1. Yes, resume it (Recommended)
  2. Start a fresh review 3. Skip the review this time 4. Not sure". On 1 invoke `/pm-prd-review` with the path of that report (resume
  mode); on 2 invoke it with the project; on 3 treat the PRD as reviewed for this run only, as below, and say plainly that the last
  review was not approved. Never route to the stack step or the roadmap because a report merely exists.
- **Available, no negative report** → "Have the write-up reviewed before planning the build? 1. Yes, review it (Recommended) 2. Skip the review this time 3. Not sure".
  On 1 invoke `/pm-prd-review` for this project. On 2 treat the PRD as reviewed **for this run only**: continue as `stack-pending` or `reviewed` by the
  stack signal; the next run will offer the review again, because skipping leaves no mark on disk. Say so.
- **Not available** → "The review step (/pm-prd-review) isn't installed in this project, so I'm skipping it for now." Continue as above for this run.
  Never imply that it ran or that the PRD was reviewed.

**`stack-pending`** — the sdd family requires a stack decision before a roadmap: it grounds the build plan's foundations in
real choices. Explain in the audience's words, then ask. Plain mode, no jargon, framed as a step for a developer:
> Before the build plan, someone technical needs to decide which technology the product will be built with. That is a step for a developer, because the choice affects cost, hiring and how fast the team can move; it shouldn't be guessed. 1. Hand this to a developer (Recommended) 2. Skip it and make the build plan now 3. Not sure

- **1, hand off** → print a short note the developer can act on and **stop** (no further skill, nothing written). Greenfield:
  run `/sdd-tech-stack-selector` (it writes `foundation/tech-stack.md`). Brownfield: run `/sdd-stack-assess`, then `/sdd-health-check`
  (the first writes `foundation/stack-assessment.md`). Add: "then run `/pm-discover` again and it will continue with the build plan."
  In plain mode the note is addressed to the developer and may use technical words; the PM-facing text around it does not.
  In technical mode print the same note as the next command(s).
- **2, skip** → the human may skip, this skill never skips by policy. Warn in one sentence that the plan may need rework if the technology
  choice changes things, then treat the stack as skipped for this run and go to the `reviewed` step. The next run asks again.
- **3, not sure** → explain once more in one sentence and re-ask; two "not sure" answers in a row mean option 1.
Do not invoke any stack skill from here: the technology choice is the developer's call.

**`reviewed`** — "Turn the write-up into a build plan now? 1. Yes (Recommended) 2. Not now". On yes invoke `/sdd-roadmap` with the
project's `prd.md` path (it reads the root from that path and runs its own readiness check; do not duplicate it). Hand back.

**`roadmapped`** — nothing to route. End with the hand-over (Step 5), name `/pm-prioritize` (if two or more items are not done) and
`/pm-backlog-sync` (if `pm-config.yml` names a tracker), each only if installed; otherwise say they are not installed in this project.

### Step 5 — Hand over (end of each turn)

Plain mode ends every turn with the handoff block from `../pm-help/references/plain-language.md`: what just happened,
what the next step is in product terms, and "Want me to keep going?". Technical mode prints the stage, the files that changed
and the exact next command. After a `roadmapped` result say that discovery is complete for this project. Do not start the
next step; the human decides.

## Output

None. `pm-discover` creates no artifact. The only things it may write are `audience:` in `$CONTEXT_ROOT/.sdd.local.yml`
(with the `.gitignore` line first, per the plain-language rule), and, after an explicit yes, the move of a project's own
`research/` folder in Step 4. Everything else is written by the skills it hands over to.

## Critical guardrails

Never writes `prd.md`, `shape-notes.md`, or `roadmap.md`.

1. **Routes, never produces.** The shaping conversation, the PRD and the roadmap come only from `/sdd-shape`, `/sdd-prd`, `/sdd-roadmap`; never draft their content here, never "fix" their files.
2. **One human gate between every step.** No chaining: finishing a step is not a yes to the next one. A skill's success is not a green light.
3. **Stage comes from disk.** Re-derive after every hand-back; never from what was said in the conversation or from a skill's summary. A missing or unreadable `checkpoint:` is "in progress", never "shaped".
4. **`shaping` never goes to `/sdd-prd`.** Only `checkpoint.current_phase: 8` makes a project `shaped`.
5. **`sdd-skills` missing → Install block, STOP.** No partial run, no manual workaround.
6. **The stack step is the developer's, and skippable only by a human.** Never by policy, never silently; the skip lasts for this run only.
7. **Name the project name beforehand, move research only on a yes.** The `git mv` of `research/` is offered after shape returns with a slug mismatch and happens only after "Yes"; never overwrite a file in the target folder.
8. **Be honest about what is installed.** `/pm-prd-review` or a stack skill not listed by the host → say so and skip with a note; never imply a step ran.
9. **No sdd internals.** No relative links into the `sdd-*` plugin; shape, PRD and stack strings are used as pinned in `../pm-help/references/sdd-contract.md`.
10. **Own scope only.** Never touches `changes/**` or `archive/**`; writes nothing but `audience:` and the confirmed `research/` move.
11. **Plain by default.** PM audience is `plain` unless `.sdd.local.yml` says `technical`; no paths, schema words or git talk in plain mode (the one developer hand-off note is addressed to the developer).
12. **Mirror the user's language.** A Polish idea gets Polish questions; stage and command names stay as they are.

## Notes

- A stage skipped "for this run" is not remembered: the next `/pm-discover` re-derives and offers it again. This is by design; there is no state file.
- An idea that arrives together with a research file always prefers the research as the seed; the user's one-liner can still be pasted into shape's own questions.
- Several roots or projects: Step 2 shows the pick every time; the stage is never inferred across projects.
- If the PM flow, the stage table or the hand-offs change, update this file, `references/eval-cases.md`, the flow in `pm-help` and the validator together.
