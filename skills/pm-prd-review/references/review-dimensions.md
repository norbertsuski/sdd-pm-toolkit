# PRD review dimensions

The seven dimensions `pm-prd-review` scores, with the rubric that turns what the PRD says into a
PASS / CONCERNS / FAIL verdict. Each dimension is judged only from the PRD text (and `metrics.md` when it
exists); a finding needs a quoted PRD line or a named absent section, never an impression.

## How a dimension gets its verdict

Findings carry a severity; the dimension verdict is derived from its **open** findings, mechanically:

| Worst open finding in the dimension | Dimension verdict |
|---|---|
| `blocker` | **FAIL** |
| `major` | **CONCERNS** |
| only `minor`, or none | **PASS** (minor findings are still listed, as "PASS, n minor") |

Severity meanings (the same scale in every dimension):

- `blocker` — the PRD cannot responsibly feed a roadmap as it stands: a build team would have to invent the
  answer, or two parts of the PRD cannot both be true.
- `major` — a build team could start, but a likely misreading or rework follows (a number missing, a
  requirement nobody can check, a promise with nothing behind it).
- `minor` — real but cheap: wording, a missing detail that does not change what gets built.

Overall verdict (also in `SKILL.md`): any `blocker` open → `REJECTED`; otherwise any `major` open (a CONCERNS
dimension) → `NEEDS_ATTENTION`; otherwise `APPROVED`. Findings resolved in triage (fixed, moved to Open
Questions, dismissed) stop counting; deferred ones keep counting.

## What the rubric reads, by PRD type

| Role | Greenfield (`context_type: greenfield`) | Brownfield (`context_type: brownfield`) |
|---|---|---|
| Problem | `## Vision & Problem Statement` | `## Current System Overview` + `## Problem Statement & Motivation` |
| People | `## User & Persona` | `## User & Persona` |
| Success | `## Success Criteria` (`### Primary`, `### Secondary`, `### Guardrails`) | same |
| Stories | `## User Stories` (`### US-NN:` with Given/When/Then and `#### Acceptance Criteria`) | same |
| What gets built | `## Functional Requirements` (`- FR-NNN: … Priority: must-have\|nice-to-have`) | `## Scope of Change` bullets tagged `[new]` `[modified]` `[removed]` `[preserved]` (the unit that plays the FR role) |
| Qualities | `## Non-Functional Requirements` | `## Constraints & Compatibility` |
| Rules | `## Business Logic` | `## Business Logic Changes` |
| Who may | `## Access Control` | `## Access Control Changes` |
| Out | `## Non-Goals` | `## Non-Goals` |
| Unknowns | `## Open Questions` | `## Open Questions` |

Below, "requirement" means an FR line (greenfield) or a `[new]` / `[modified]` / `[removed]` scope bullet
(brownfield); `[preserved]` bullets are constraints, not things to build.

## 1. Problem clarity

Question: can a stranger say who is hurting, how, and what it costs, without reading anything else?

- **PASS** — the problem names a person or role, a situation, what goes wrong and a consequence; the persona is
  specific enough to picture (a role, a context, a trigger moment), and the problem is stated apart from the solution.
- **CONCERNS** (`major`) — the problem is stated as a solution ("we need a dashboard for X") or its cost is
  missing; the persona is generic ("users", "customers") or several personas appear with no primary one.
  (`minor`: the cost is implied but not stated; the persona lacks a context.)
- **FAIL** (`blocker`) — no problem statement (the section is empty, a placeholder, or only lists features), or the
  persona section names nobody.

Evidence: quote the vision/problem sentence or the persona line. Absent → name the section.

## 2. Measurability

Question: after launch, could the team tell, with numbers, whether this worked?

Each `### Primary` criterion should carry (a) a quantity or threshold, (b) who it is measured over, (c) a time
window or a trigger, and (d) something observable (an event, a count, a rate). Guardrails should be thresholds
that can be breached. If `metrics.md` exists beside the PRD, read it: a Primary criterion that no metric there
covers is a finding; **its absence is never a finding** (`pm-metrics` may not have run yet).

- **PASS** — every Primary criterion has a threshold, a population and a window; guardrails are checkable.
- **CONCERNS** (`major`) — a Primary criterion lacks a number or a window ("most users", "faster", "improved
  engagement"); or the PRD claims a number whose data nothing in the PRD would capture (see Traceability for the
  requirement side). (`minor`: a Secondary criterion or a guardrail is vague.)
- **FAIL** (`blocker`) — no `### Primary` criterion at all, or none can be measured ("users love it").

Evidence: quote the criterion. Never supply the missing number in the finding or in a fix; the fix asks the PM.

## 3. Scope discipline

Question: is it clear what is in, what is out, and what matters most?

- **PASS** — `## Non-Goals` lists real exclusions with a reason; must-have and nice-to-have are both used and the
  must-haves read as a coherent first release; nothing in the requirements contradicts a non-goal.
- **CONCERNS** (`major`) — Non-Goals is thin or generic ("anything not listed"); every requirement is must-have so
  nothing is cuttable; a requirement quietly reaches into a non-goal's territory; a nice-to-have sits on the only
  path to a Primary criterion. (`minor`: one non-goal lacks a reason; a priority looks arbitrary.)
- **FAIL** (`blocker`) — a requirement directly contradicts a non-goal, or `## Non-Goals` is empty or a
  placeholder. (A *missing* `## Non-Goals` heading never reaches this step; it is a contract mismatch.)

Evidence: quote both lines of a contradiction; for a thin section quote what is there.

## 4. Completeness

Question: is every section filled with something a build team can use?

- **PASS** — every required section has real content; Access Control says who may do what and what an
  unauthenticated visitor gets; the qualities section covers at least performance and privacy/access where
  relevant; Business Logic states inputs, rule and output (or says plainly there is none); the frontmatter
  (`delivery_mode`, `timeline_budget`) matches what the text promises.
- **CONCERNS** (`major`) — a section is a stub, "TBD", or one line where a paragraph is needed and a build decision
  depends on it; Business Logic is named but its rule is missing; a deadline in the frontmatter conflicts with the text.
  (`minor`: a section is thin but nothing downstream depends on it.)
- **FAIL** (`blocker`) — a required section is empty or a placeholder and everything else relies on it: no
  requirements at all, no access rules for a product with sign-in, no stories.

Evidence: quote the stub line or name the empty section. This dimension never re-reports a gap another dimension
owns (a missing number is Measurability, an uncheckable line is Testability).

## 5. Testability

Question: could a tester pass or fail each story and requirement without asking the author?

- **PASS** — every `### US-NN` has Given / When / Then and `#### Acceptance Criteria` that describe observable
  outcomes; requirements and qualities avoid unmeasured adjectives or give a threshold beside them.
- **CONCERNS** (`major`) — a story has no acceptance criteria, or criteria that restate the title; a requirement
  or quality rests on "fast", "easy", "intuitive", "secure", "scalable", "robust" with no threshold; a rule in
  Business Logic that changes behaviour has no story or criterion that would show it working.
  (`minor`: one criterion is ambiguous but the story is otherwise checkable.)
- **FAIL** (`blocker`) — most stories lack acceptance criteria, or the must-have requirements are written so that
  no observable outcome could fail them.

Evidence: quote the unverifiable line. Fix options propose a checkable form, and ask the PM for any number.

## 6. Traceability

Question: does every promise have something behind it, and every piece of work a reason?

The PRD does not link ids to each other, so coverage is judged by meaning: a requirement is **covered** when a
story's When/Then or an acceptance criterion exercises the behaviour it states. Write the mapping you used
into the finding so the PM can disagree. Check, in order:

1. every must-have requirement is covered by at least one story or acceptance criterion;
2. every story supports at least one requirement (an orphan story is work with no demand);
3. every `### Primary` success criterion can be reached by a must-have requirement or story that produces or
   records the thing counted (a criterion about "cooking a suggested recipe" needs something that captures it);
4. every guardrail is backed by a quality (greenfield) or constraint (brownfield) or an access rule.

- **PASS** — all four hold.
- **CONCERNS** (`major`) — a must-have requirement with no covering story and no acceptance criterion (name its
  FR id); a Primary criterion with nothing that could produce its number; a guardrail with no backing line.
  (`minor`: a nice-to-have requirement is uncovered; an orphan story; a covering story only touches part of a
  requirement.)
- **FAIL** (`blocker`) — the only requirement a Primary criterion depends on has neither story nor criterion, or
  most must-have requirements are uncovered.

Evidence: quote the requirement line (with its FR id) and say which sections were searched for coverage.

## 7. Open-question risk

Question: what is still unknown, who owns it, and what does it hold up?

An open question is well formed when it is a question, has an owner, has an `By:` date and a `Block:` flag
(`Block: yes` gates the PRD, see `../../pm-help/references/sdd-contract.md`).

- **PASS** — every question is well formed; any `Block: yes` question names (in its text or in the requirement
  it touches) what it gates, and its `By:` date leaves room before `timeline_budget.hard_deadline`; no requirement
  hides an unanswered decision.
- **CONCERNS** (`major`) — a `Block: yes` question has no owner or no date, or its date is after the point it
  gates (or after the hard deadline); a question marked `Block: no` whose answer would change a must-have
  requirement or quality; a requirement contains "TBD", "to be decided", "?" or an unnamed alternative.
  (`minor`: a well-formed `Block: yes` question that gates a must-have, listed so the PM sees the dependency;
  a question missing only its date.)
- **FAIL** (`blocker`) — a `Block: yes` question about the core problem, the primary user, or the main success
  criterion; or the `## Open Questions` list is missing questions the text itself raises throughout and
  several must-have requirements depend on them.

Evidence: quote the question line (or the requirement with the hidden decision).

## Finding rules (apply to every dimension)

1. **Evidence or absence.** Each finding has an `Evidence:` line with a verbatim quote from `prd.md` (or from
   `metrics.md`), or the exact form `Absent: <section or item>`. A quote must occur in the file (checked before
   printing); a finding without either is dropped.
2. **One problem, one finding.** Do not report the same gap under two dimensions; put it under the one named
   in this file. Group several nice-to-have items of the same kind into one `minor` finding.
3. **Cap.** At most 12 findings, ordered blocker, major, minor. Beyond that, merge related minors.
4. **No manufactured findings.** A PASS dimension has no finding. A clean PRD is reported as clean.
5. **Fix options (1 to 3).** Each option is one sentence and says whether it is an *edit* (a change to a named
   PRD section the skill can apply) or an *ask* (the PM must supply a fact, a number or a decision first). Offer
   one option unless there is a real trade-off. Mark the recommended option "(Recommended)". An option never
   contains an invented number, name, date or requirement.
6. **Fixes stay in one section.** An option edits exactly one `##` section of `prd.md`. If the right fix touches
   two sections, split it: the second part is a separate finding or a follow-up the PM confirms.
