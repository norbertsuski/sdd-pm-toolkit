---
name: pm-frame
description: >
  Challenge framing assumptions about WHAT to build before shaping or planning
  HOW. Use when input is a "bug + proposed fix", a scope question, a design
  choice, or any case where the observation and the stated cause (or the
  problem and the solution) are presented as one. Trigger phrases: "fix",
  "bug", "broken", "root cause", "should we even", "is this the right",
  "challenge the assumption", "rethink", "before I plan". Use BEFORE /pm-shape
  or before handing a change to a developer, not in place of them.
---

# Frame: Challenge the Framing Before Planning

Plans built on the wrong problem statement are perfect solutions to the wrong question. This skill exists for one job: separate **observation** from **stated cause** — and **problem** from **proposed solution** — before any planning begins.

The shape this skill addresses is general: the user describes something (an observation, a perceived problem, a scope they want to take on) and proposes a response (a cause, an approach, a plan structure) in the same breath. The two get treated as one fact. A perfect plan then ships a perfect solution — and the actual problem remains, because the framing was wrong; the plan was right; the user lost the day.

This skill is the framing step. Planning answers _how to build it_. /pm-frame answers _what's actually the right thing to plan_.

Writes only: `$CONTEXT_ROOT/foundation/<slug>/frame-<YYYY-MM-DD>-<topic>.md` (the Frame Brief; the `foundation/<slug>/` folder is created if the project has none yet), the per-operator `.sdd.local.yml` and its `.gitignore` line. It never writes under `changes/` or `archive/` (those belong to a developer's workflow), never writes a plan, and never edits code.

This skill resolves `CONTEXT_ROOT` per `../pm-help/references/context-resolution.md` (discovery, then the one-line pick when several roots exist; if no root exists it offers `/pm-init`). `app:` may be absent for flat roots; do not require it. It resolves its own `audience` per `../pm-help/references/plain-language.md` (`## Audience resolution`: read `$CONTEXT_ROOT/.sdd.local.yml`, else ask once and write there, after making sure `$CONTEXT_ROOT/.gitignore` contains a `.sdd.local.yml` line; default `plain`). When `plain`, questions, the dimension map and the hand-off are given in plain language (no `file:line` dumps, no "hypothesis table" talk, no schema words) — the Frame Brief written to disk is identical in both modes.

## When to use, when to skip

**Use when**: input has bug-shape ("X is broken, let's build Y"), scope-shape ("we should split this into two plans", "is this even the right scope"), design-shape ("which approach do we even want"), or assumption-shape ("we're assuming X — is that true?"). Use also when stakes are high, when the system is unfamiliar to the user, or when a developer is about to start planning a task that smells like a stated cause rather than a verified one.

**Skip when**: the task is a pure mechanical change ("rename this function", "bump dep version"), the user has already worked out the framing themselves and verified it ("I've confirmed it — plan the fix"), or the request is a clearly scoped feature with no underlying premise to challenge.

When in doubt, this skill asks a short round of questions and exits cheaply if the framing turns out to be solid. Cost of running it on a clear request: ~2–3 questions. Cost of skipping it on a misframed task: a wrong plan and a lost day.

## Relationship to other skills

- `/pm-shape` — the next step when the reframed problem is large or product-level (a new module, a significant feature): it turns the reframed problem into `shape-notes.md`, then `/pm-prd`.
- `/pm-research-synthesis` — turns interview and survey evidence into insights. Frame can consume an insights file as input but does not replace it.
- Planning and building a single change — a developer's step in their own development workflow, never invoked from here. A small, single-change reframe goes to a developer as the Frame Brief.

The Frame Brief is useful standalone (as a discussion artifact, or to scope a quick fix) — it does not require anything to follow.

## Initial Response

When this skill is invoked:

1. **If a file path was provided** (e.g. `/pm-frame @$CONTEXT_ROOT/foundation/<slug>/research/<date>-<topic>.md` or `/pm-frame @notes/incident.md`), read the file FULLY and proceed to Step 1.
   **If a change-id was provided** (e.g. `/pm-frame foo`, where `$CONTEXT_ROOT/changes/foo/` exists): framing a single change is a developer's step in their development workflow — this skill does not read or write `changes/**`. Say so in one sentence ("Framing an in-flight change is a developer step; I can frame the underlying problem here if you paste or describe it") and STOP, unless the user then supplies the observation inline or as a file, in which case continue with that input only.
2. **If a problem description was provided inline**, proceed to Step 1.
3. **If nothing was provided**, respond with:

```
I'll help you check whether you're framing the right problem before planning a solution.

Please share:
1. The observation — what is happening, what you're seeing, or what scope you're considering?
2. Your initial framing — what you think is causing it, the approach you have in mind, or the way you'd cut the work?
3. (Optional) Any related research, prior incidents, or files I should read

Tip: pass the evidence directly — `/pm-frame @path/to/notes.md`, or describe it inline: `/pm-frame signups drop after the pricing page; we think the price is too high`
```

Then wait.

## Process

### Step 1: Capture the framing — keep observation and stated cause SEPARATE

This is the most important step. Do not skip it. Do not collapse it.

Read `$CONTEXT_ROOT/foundation/lessons.md` (legacy: `context/<app>/foundation/lessons.md`) if present (a developer-maintained file; read-only here) and use prior framing-shape lessons (recurring framing pitfalls and accepted rules) as priors when constructing the dimension map in Step 2 — they're load-bearing context, not optional reading.

Read every file the user mentioned, FULLY. Then extract and record three things, **distinctly**:

- **Reported observation** — the literal observable thing. Not a cause. Not a fix. The effect a user or operator sees, or the scope/design question as stated.
- **User's stated cause or approach** — what they think is causing the observation, or the framing they're bringing to the work.
- **User's proposed direction** — what they want to do about it.

Echo these back as three separate bullets and confirm:

```
Let me make sure I have this right:

  Observation (what's stated):     [literal effect or scope/design question]
  Your initial framing:            [user's theory or approach]
  Your proposed direction:         [what they want to do about it]

I'm going to question the framing before we plan the work. The observation is fixed
ground — that's what we know. Everything else is a hypothesis until verified.
```

The framing is locked at this point. Even if the user pushes back ("just plan the fix"), do not collapse the observation into the framing. The whole skill rests on this separation.

If the user did not provide a clear initial framing ("something feels off, fix it"), skip the framing bullet and note that this is purely observation-driven — the skill becomes more open-ended but the protocol still applies.

### Step 1.5: Clarifying questions before dispatch

This step always runs. Before building the dimension map (Step 2) or dispatching parallel sub-agents (Step 3), pause for one round of clarifying questions on every invocation. The goal is to disambiguate the _observation and scope_ — "which of these items is the leading concern?", "is this one observation or several?", "is the observable a single symptom or a class of symptoms?" — so the dimension map is built against a focused observation rather than a multi-pronged punch list.

Ask the user:

- question: "Which of these items is the leading concern?" (or similar, to disambiguate observation/scope)
  header: "Clarifying Observation"
  options:
  - label: "Option 1 (describes an observation or scope position)"
  - label: "Option 2 (describes an observation or scope position)"
  - label: "I'm not sure / haven't separated them yet"

These questions are bound by guardrail #4 below ("Narrowing questions ≠ solution questions"). Pre-dispatch questions describe observations or scope positions, never causes or fixes. If you find yourself drafting an option that proposes a fix or approach, you've crossed into solution-design territory — stop and rewrite it as an observation.

Capture the answers into the framing record alongside the Step 1 capture; Step 6's Frame Brief preserves both as separate bullets under "Initial Framing (preserved)" (a new `Pre-dispatch narrowing` line). The original observation, stated cause, and proposed direction stay verbatim from Step 1; Step 1.5's narrowing layers on top, not as a replacement.

This step does not dispatch sub-agents — that remains Step 3's job.

### Step 2: Map the dimensions of the problem

Construct a **map** of the dimensions the observation could originate from — for THIS user's THIS situation. Do not reach for a generic template; the value of the map is that it's fit to the system, codebase, or design space you're looking at.

How to build the map:

- **Read first.** Open the files the user mentioned. Open neighbors. Trace the path from the stated cause to the observed effect — _whether that path is runtime data flow, a chain of design decisions, or a sequence of assumptions_. The dimensions fall out of what's actually there: stages of input, transformation, state, side effects; or axes of the design space; or layers of a scoping decision. Don't list dimensions you haven't seen evidence of.
- **Use sub-agents when the surface is large or unfamiliar.** Spawn one or two Explore sub-agents with prompts like: "Trace the path from <stated cause> to <observed effect>. List every distinct stage or axis the chain passes through, with file:line or document:section references." The map is what they return — not what you guessed before reading.
- **Treat each dimension as a possible origin.** A useful dimension is one where, if the framing broke at this point, you'd see roughly this observation. Dimensions that couldn't plausibly produce the observation don't belong on the map.

**Pin the observation to the map**: at which dimension does the user's framing land? Where else _could_ the observation originate? The user's framing is one node on the map; the rest of the map is the hypothesis space.

Present the map back as text, briefly:

```
The observation could originate at any of these dimensions:

  1. [Dimension A] — [what would go wrong / what the framing assumes here]
  2. [Dimension B] — [what would go wrong / what the framing assumes here]   ← user's current framing
  3. [Dimension C] — [what would go wrong / what the framing assumes here]
  4. [Dimension D] — [what would go wrong / what the framing assumes here]

Going to investigate each in parallel before deciding.
```

### Step 3: Spawn parallel hypothesis agents

Use your AI coding assistant's task management features to register one task per plausible dimension. Then spawn parallel sub-agents — typically 2–4, capped at 5 — using the task tool, **all in one message** for concurrency.

For each hypothesis, the sub-agent investigates: "**If the framing broke at this dimension, what evidence would we expect to see, and does that evidence exist?**"

- Use `subagent_type: "Explore"` for "find the code or document that handles X, show me the structure".
- Use `subagent_type: "general-purpose"` for "trace this chain and tell me whether assumption Y holds".

Each prompt must include:

- The literal observation from Step 1 (verbatim).
- The specific dimension hypothesis being tested.
- The expected-evidence framing: "What would we see if THIS were the dimension where the framing breaks? Look for that. Report whether it's present, partial, or absent, with file:line or document:section references."
- A read-only directive — no edits.

After all return, synthesize: which hypotheses have **strong**, **weak**, or **no** evidence? The hypothesis that has strong evidence and the user's initial framing didn't is the candidate reframe.

### Step 4: Narrowing questions (Socratic, not solution)

Ask the user: **The questions and options here are fundamentally different from planning questions**: in planning, options are _solution choices_; here, options are _hypothesis disambiguators_. The user's answer narrows the hypothesis space.

**Rules for narrowing questions:**

- Each question should isolate one or two dimensions of the map. The right question is one whose answer rules dimensions in or out.
- Options describe **observations or design positions** — what the user actually sees, or which side of a real tradeoff they're on — not causes or solutions.
- Keep `header` short: e.g. "Pattern", "When", "Scope", "Tradeoff".
- Aim for 2–5 questions total — enough to triangulate, not enough to drag.
- ALWAYS include an "I'm not sure / haven't checked" option. The user's certainty is itself a signal; false certainty is the enemy.

A narrowing question that doesn't change the hypothesis ranking is wasted. **Design each question to be decisive.** A single well-aimed question, answered honestly, often resolves the entire reframing question on its own.

If hypothesis evidence from Step 3 is already conclusive (one hypothesis has strong evidence, others have none), you may skip questioning and proceed to Step 5 — but say so explicitly: "Step 3 found strong evidence for [hypothesis] and none for the others. Skipping the questioning step; reframing directly."

### Step 5: Cross-system check — pressure-test the leading hypothesis

Before finalizing the reframe, pressure-test it from a different angle than the investigation that produced it. The goal is to surface evidence the hypothesis investigation didn't see, not to confirm what you already believe.

Pick whichever of these are useful for the case in front of you:

- **Independent search.** Spawn a fresh Explore sub-agent with a prompt that does NOT name the leading hypothesis. Describe only the observation and ask: "What in this system or design space is most likely responsible? Look without preconception." If the agent independently lands on the same hypothesis, confidence rises. If it surfaces something different, that's a signal worth reading carefully.
- **Look for prior occurrences.** Search `$CONTEXT_ROOT/foundation/**/`, `$CONTEXT_ROOT/changes/**/` and `$CONTEXT_ROOT/archive/**/` (legacy: `context/<app>/…`; read-only), commit messages, and issue history for similar observations or scope decisions in this project before. Past incidents and prior decisions often hold the answer or rule one out.
- **Check the inverse.** What other evidence would the leading hypothesis predict — that you haven't checked yet? Verify it. What should NOT be visible if the hypothesis is true? Confirm its absence.
- **Sanity-check against the user's stated framing once more.** If their original framing still fits the evidence equally well, the reframe may be unnecessary. Don't override a working framing with a more elegant one.

If pressure-testing strengthens the leading hypothesis, lock confidence. If it surfaces a credible alternative or contradicts the hypothesis, **stop** and re-run Step 3 with the new hypothesis on the map. A reframe is only valuable when it survives an honest attempt to break it.

### Step 6: Synthesize the Frame Brief

Resolve where to write before writing:

- Resolve `CONTEXT_ROOT` (see the top of this file) and the project folder `$CONTEXT_ROOT/foundation/<slug>/` (legacy: `context/<app>/foundation/<slug>/`): if exactly one project folder exists use it; if several, ask which one the frame belongs to; if none exists, create `$CONTEXT_ROOT/foundation/<slug>/` with a kebab-case `<slug>` derived from the observation (confirm it in one line).
- The file is `frame-<YYYY-MM-DD>-<topic>.md` (`<topic>`: a short kebab-case name for the observation; a same-day second frame on the same topic gets `-2`). Never overwrite an existing frame file.
- This skill NEVER writes under `$CONTEXT_ROOT/changes/` or `$CONTEXT_ROOT/archive/` and never creates a change folder. (A developer who wants the brief inside a change folder copies the file there by hand.) If the user's input pointed at an archived or in-flight change, the brief still lands in the project folder.

Use this template:

```markdown
# Frame Brief: [Topic]

> Framing step before shaping or planning. This document captures what is _actually_
> at issue, separated from what was initially assumed.

## Reported Observation

[Literal observable effect or stated scope/design question — copied from
Step 1, unchanged.]

## Initial Framing (preserved)

- **User's stated cause or approach**: [from Step 1]
- **User's proposed direction**: [from Step 1]
- **Pre-dispatch narrowing**: [from Step 1.5 — the observation/scope position the user picked, in their words; "not separated yet" is itself a valid answer worth recording]

## Dimension Map

The observation could originate at any of these dimensions:

1. **[Dimension A]** — [what would go wrong / what the framing assumes here]
2. **[Dimension B]** — [...] ← initial framing
3. **[Dimension C]** — [...]
4. **[Dimension D]** — [...]

## Hypothesis Investigation

| Hypothesis                     | Evidence                                      | Verdict              |
| ------------------------------ | --------------------------------------------- | -------------------- |
| [Dimension A: brief claim]     | [file:line / document:section / observations] | STRONG / WEAK / NONE |
| [Dimension B: initial framing] | [evidence]                                    | STRONG / WEAK / NONE |
| [Dimension C]                  | [evidence]                                    | STRONG / WEAK / NONE |
| [Dimension D]                  | [evidence]                                    | STRONG / WEAK / NONE |

## Narrowing Signals

Decisive observations from Step 4 (user reports + sub-agent findings) that
narrowed the hypothesis space:

- [Observation that ruled in or out a dimension]
- [Observation that ruled in or out a dimension]

## Cross-System Convention

[How is this class of observation usually handled? Does the leading
hypothesis match the convention?]

## Reframed (or Confirmed) Problem Statement

> **The actual problem to plan around is**: [one sentence — root, not surface]

[2–3 sentences explaining why this is the real problem and what would change
if it were addressed. If the original framing held up, say so explicitly:
"The initial framing was correct — proceed with the originally proposed
direction." Do not manufacture a reframing if the evidence doesn't support
one.]

## Confidence

- **HIGH** — strong evidence + matches convention + decisive narrowing signal
- **MEDIUM** — evidence points one way but convention or signal weaker
- **LOW** — evidence inconclusive; recommending further reproduction or
  evidence-gathering before planning

[Pick one. If LOW, list the specific verification step needed before shaping or planning.]

## What Changes for Planning

[1–2 sentences: what the shaping or the plan should actually be about, given the reframe.
If reframe is "no change", state that the original framing held up.]

## References

- Source files: [file:line]
- Related research: `$CONTEXT_ROOT/foundation/<slug>/research/<date>-<topic>.md` (if present)
- Investigation tasks: [list of TaskCreate IDs from Step 3]
```

Keep the brief tight — aim for ~80–150 lines. The hypothesis table is the heart; everything else supports it.

### Step 7: Present and hand off

**When `audience: plain`:** skip the status block below. Give the plain hand-off from the contract
(`../pm-help/references/plain-language.md`, `## Handoff style`): one or two plain sentences saying what the real
problem turned out to be (or that the original thinking held up) and how sure you are, where the brief is saved
(in words — "saved with your project documents"), and what comes next, then "Want me to keep going?".

Otherwise print a one-screen summary:

```
═══════════════════════════════════════════════════════════
  FRAME COMPLETE: [Topic]
  Confidence: [HIGH/MEDIUM/LOW]
═══════════════════════════════════════════════════════════

  Reported observation: [one line]
  Initial framing:      [one line]
  Reframed problem:     [one line — or "Initial framing held"]

  ► Brief: $CONTEXT_ROOT/foundation/<slug>/frame-<YYYY-MM-DD>-<topic>.md
═══════════════════════════════════════════════════════════
```

Then ask the user:

- question: "Frame done. How would you like to proceed?"
  header: "Next step"
  options:
  - label: "Shape it into a product write-up"
    description: "The reframed problem is large or product-level: continue with /pm-shape, which starts from this brief."
  - label: "Hand the brief to a developer"
    description: "The reframed problem is a small, single change: the Frame Brief goes to a developer to plan and build."
  - label: "Reproduce / verify first"
    description: "Confidence is too low or the reframe needs a manual check before shaping or planning."
  - label: "Discuss before moving on"
    description: "I want to push back on the reframe or explore alternatives."
  - label: "Stop here"
    description: "The brief alone is enough — nothing further right now."
    multiSelect: false

On "Shape it into a product write-up": say the next step is `/pm-shape` (pass the brief path as its input, e.g. `/pm-shape @$CONTEXT_ROOT/foundation/<slug>/frame-<date>-<topic>.md`) and copy that command to the clipboard silently (`pbcopy`, else `clip.exe`, else `xclip -selection clipboard`, else skip) — do not start it. On "Hand the brief to a developer": print the brief path and state that the developer takes it from there; this skill does not plan or build. Never chain into another skill automatically.

## Critical guardrails

1. **Allowed conclusion: "the framing was right."** This skill is not value-additive only when it produces a reframing. If the hypothesis investigation confirms the user's initial framing, that IS a successful frame — say so plainly and stop. Manufactured reframings are worse than no frame: they introduce confusion the user has to untangle later.

2. **Observation and stated cause stay separate.** Through every step. The Frame Brief preserves the original framing verbatim — even when reframed — because future readers and reviewers need to see what was assumed vs what was discovered.

3. **No solution design.** This skill never picks an implementation approach. It does not propose phases, file changes, or technical decisions, and it never writes a plan. It produces ONE artifact: the reframed (or confirmed) problem statement. Shaping (`/pm-shape`) or a developer owns what happens next.

4. **Narrowing questions ≠ solution questions.** Planning asks "which approach?". /pm-frame asks "where in the dimension map does the actual problem live?". This rule binds both Step 1.5 (pre-dispatch scope/observation narrowing) and Step 4 (post-dispatch hypothesis narrowing). Options describe observations or design positions, not choices about how to address them. If you find yourself drafting a question whose answer changes the _direction_, you've crossed into solution territory — stop.

5. **Read the source material before reaching for priors.** Source material means code, docs, prior decisions, or whatever the framing actually rests on. It is tempting to recognize a shape from training-data familiarity and propose a reframing before investigating. Don't. Hypotheses must come from the dimension map you constructed in Step 2 from THIS material, and evidence must come from sub-agent reads of THIS project. A confident-sounding reframe with no file:line or document:section evidence is the failure mode this skill exists to prevent.

6. **No hypothesis padding.** If only two dimensions are plausible, investigate two. Spawning agents to investigate hypotheses with no plausibility burns budget and signals false rigor.

7. **Time-box the investigation.** Frame should typically complete in 2–4 sub-agent rounds and 2–5 questions. If it's dragging past that, the case probably needs reproduction or evidence-gathering before any further analysis — recommend that and stop.

## Notes

- This is a **framing** skill. Investigate and report — do not edit code, do not write plans, do not touch `changes/**`.
- Be specific. Specifics with `file:line` or `document:section` beat hand-waves.
- Distinguish "evidence found in this project" (verifiable, with file:line or document:section) from "I have a hunch from past systems I've seen" (prior, unverified). Priors are useful for forming hypotheses; only verified evidence belongs in the Frame Brief.
- If the user pushes back on the reframe, take it seriously — they may know context the investigation missed. Re-run Step 3 against their objection rather than defending the reframe.
- The Frame Brief is the only artifact. Keep it short, scannable, and actionable for whoever takes it next (`/pm-shape` or a developer).
