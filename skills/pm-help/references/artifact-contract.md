# Artifact format contract

Several PM skills read files that developers' SDD tooling also reads or writes: the PRD, the roadmap, the
change folders, the shaping checkpoint. This file is the contract for those formats. It restates, as data,
every heading, column, key and value the PM skills depend on, so a skill can check a file before it reads
it and a maintainer can check the list against the developers' tooling. The skills that write `prd.md`,
`roadmap.md` and `shape-notes.md` (`pm-prd`, `pm-roadmap`, `pm-shape`) write exactly these formats; the
change and archive formats are written by developers' tooling and are read-only here. Which upstream
revision the vendored skills were taken from is recorded only in `VENDORED.md`;
`scripts/check-upstream.sh <path-to-source-checkout>` greps a local checkout of that source for every
string in the marker blocks below and lists what changed there since.

## Marker-block extraction rule

Each list is wrapped in `<!-- <name>:start -->` / `<!-- <name>:end -->` lines. Inside a block, one
entry per line, written as ``- `<string>` ``. The string is everything between the first ``- ` ``
and the **last** backtick on the line (so a string may itself contain backticks). Lines in a block
that do not match this form are ignored. Headings are written with their `## ` prefix. Strings are
copied exactly as the files are written. `scripts/validate-structure.sh` and
`scripts/check-upstream.sh` use this same rule:

```bash
sed -n -E 's/^- `(.*)`[[:space:]]*$/\1/p'
```

## PRD contract

Path: `$CONTEXT_ROOT/foundation/<project-slug>/prd.md` (versioned saves `prd-vN.md` may sit beside it).

Frontmatter keys (names are load-bearing; order is not). `status` is one of `draft | reviewed | locked`;
`context_type` is `greenfield | brownfield`; `delivery_mode` is `mvp | product-feature`.
`timeline_budget` is `null`, or `{ hard_deadline: <YYYY-MM-DD> }` in `product-feature` mode, or the
`mvp_weeks` / `delivery_weeks` + `hard_deadline` + `after_hours_only` object in `mvp` mode.
`audience` is never a frontmatter key. Flat roots omit `app:`.

<!-- prd-frontmatter:start -->
- `project:`
- `version:`
- `status:`
- `created:`
- `context_type:`
- `delivery_mode:`
- `timeline_budget:`
- `hard_deadline:`
<!-- prd-frontmatter:end -->

Greenfield PRD, 10 `##` headings in this order:

<!-- prd-greenfield:start -->
- `## Vision & Problem Statement`
- `## User & Persona`
- `## Success Criteria`
- `## User Stories`
- `## Functional Requirements`
- `## Non-Functional Requirements`
- `## Business Logic`
- `## Access Control`
- `## Non-Goals`
- `## Open Questions`
<!-- prd-greenfield:end -->

Brownfield PRD, 11 `##` headings in this order:

<!-- prd-brownfield:start -->
- `## Current System Overview`
- `## Problem Statement & Motivation`
- `## User & Persona`
- `## Success Criteria`
- `## User Stories`
- `## Scope of Change`
- `## Constraints & Compatibility`
- `## Business Logic Changes`
- `## Access Control Changes`
- `## Non-Goals`
- `## Open Questions`
<!-- prd-brownfield:end -->

Line formats inside a PRD:

- `## Success Criteria` carries exactly three subsections, in this order (greenfield and brownfield alike):

<!-- prd-success-criteria:start -->
- `### Primary`
- `### Secondary`
- `### Guardrails`
<!-- prd-success-criteria:end -->

  A skill that reads Success Criteria (`pm-metrics`) checks these as whole-line matches inside the
  `## Success Criteria` section, right after the heading check of the contract procedure; a missing
  subsection is the same `CONTRACT MISMATCH` stop.
- User story heading: `### US-NN: <Title>` (two-digit, from `01`), followed by Given/When/Then.
- Functional requirement (greenfield) is one line matching
  `^- FR-\d{3}: .*Priority: (must-have|nice-to-have)`. Brownfield uses `## Scope of Change` bullets
  tagged `[new]`, `[modified]`, `[removed]`, `[preserved]` instead of FR lines.
- `## Open Questions` is a numbered list; an entry that gates the PRD ends with `Block: yes`.

## Roadmap contract

Path: `$CONTEXT_ROOT/foundation/<project-slug>/roadmap.md`. Frontmatter: `project`, `version`,
`status` (`draft | active | locked`), `created`, `updated`, `prd_version`, `main_goal`, `top_blocker`.

Required `##` headings (10), in this order. `## Streams` is optional and sits between `## At a glance`
and `## Baseline` when present (11 headings then).

<!-- roadmap:start -->
- `## Vision recap`
- `## North star`
- `## At a glance`
- `## Baseline`
- `## Foundations`
- `## Slices`
- `## Backlog Handoff`
- `## Open Roadmap Questions`
- `## Parked`
- `## Done`
<!-- roadmap:end -->

<!-- roadmap-optional:start -->
- `## Streams`
<!-- roadmap-optional:end -->

Tables and item fields, listed one per entry (padded table headers do not grep as whole rows).
`## At a glance` columns: `ID`, `Change ID`, `Outcome (user can …)`, `Prerequisites`, `PRD refs`,
`Status`. `## Backlog Handoff` columns: `Roadmap ID`, `Change ID`, `Suggested issue title`,
``Ready for `/sdd-plan` ``, `Notes`. Every `### S-NN:` slice carries nine fields (`Outcome`,
`Change ID`, `PRD refs`, `Prerequisites`, `Parallel with`, `Blockers`, `Unknowns`, `Risk`, `Status`);
every `### F-NN:` foundation carries the same plus `Unlocks`.

<!-- roadmap-columns:start -->
- `Roadmap ID`
- `Change ID`
- `Outcome (user can …)`
- `Prerequisites`
- `PRD refs`
- `Suggested issue title`
- `Ready for `/sdd-plan``
- `Notes`
- `- **Outcome:**`
- `- **Change ID:**`
- `- **PRD refs:**`
- `- **Prerequisites:**`
- `- **Parallel with:**`
- `- **Blockers:**`
- `- **Unknowns:**`
- `- **Risk:**`
- `- **Status:**`
- `- **Unlocks:**`
<!-- roadmap-columns:end -->

Item status enum (`Status` column and `- **Status:**` field): `proposed | ready | planning | in-progress | done | blocked`.
`blocked` means at least one Unknown with `Block: yes`. `pm-roadmap` emits `proposed`, `ready`, `blocked`;
a developer's archive step flips an item to `done` and appends to `## Done`:
``- **<ID>: <Outcome>** — Archived <YYYY-MM-DD> → `<root>/archive/<created-date>-<change-id>/`. Lesson: —.``
Slices are in dependency order; ids are `F-NN` and `S-NN`; the `Change ID` is kebab-case and is the
join key to `changes/<change-id>/` and `archive/`.

## Change contract

Written only by developers' change tooling (creating, planning, implementing, reviewing and archiving a
change); the PM toolkit reads them and never writes them.

- Live change: `$CONTEXT_ROOT/changes/<change-id>/change.md` (also `plan.md`, `plan-brief.md`, `reviews/`).
- Archived change: `$CONTEXT_ROOT/archive/<created-date>-<change-id>/change.md`, where `<created-date>`
  is the change's `created:` date (`YYYY-MM-DD`). The stamped file carries `status: archived`.
- Lifecycle `status` values include `new`, `planned`, `plan_reviewed`, `implementing`, `implemented`, `impl_reviewed`, `archived`.
- `archived_at:` is an ISO-8601 UTC datetime (`2026-10-08T09:30:00Z`); read the first 10 characters as the date.
- A full verification sets `status: impl_reviewed` together with the four `verified_*` keys plus `updated`:
  `verified_source` (`review:<path>` or `factory-log:run-<K>`), `verified_verdict`, `verified_fingerprint`
  (`sha256:<hex>`), `verified_at` (`YYYY-MM-DD`), and `updated`. Any verdict below can sit on an
  `impl_reviewed` change. How a current verification is classified:
  - **positive** — `APPROVED`, `SKIPPED (trivial)`, `SKIPPED (declined)`, or `NEEDS ATTENTION` whose review
    file has zero PENDING decisions (already triaged);
  - **negative** — `REJECTED` (always), or `NEEDS ATTENTION` that is not yet triaged.
  Verdict values as developers' review tooling writes them (note the space in `NEEDS ATTENTION`):

<!-- change-verdicts:start -->
- `APPROVED`
- `NEEDS ATTENTION`
- `REJECTED`
- `SKIPPED (trivial)`
- `SKIPPED (declined)`
<!-- change-verdicts:end -->

<!-- change-keys:start -->
- `status:`
- `created:`
- `archived_at:`
- `verified_source:`
- `verified_verdict:`
- `verified_fingerprint:`
- `verified_at:`
<!-- change-keys:end -->

## Shape checkpoint contract

Path: `$CONTEXT_ROOT/foundation/<project-slug>/shape-notes.md`, written only by `pm-shape`. Its
frontmatter carries a `checkpoint:` block that lets a session resume from disk; the PM toolkit reads
it (never writes it) to tell a shaping session in progress from a finished one.

<!-- shape-checkpoint:start -->
- `checkpoint:`
- `current_phase:`
- `phases_completed:`
- `quality_check_status:`
<!-- shape-checkpoint:end -->

`checkpoint.current_phase` is an integer: `1`..`6` are the discovery phases (shaping in progress), `7` is
the closing cross-check (still in progress), `8` is finalized and ready for `pm-prd`. So "shaping" means
`current_phase` below 8 and "shaped" means exactly 8. `quality_check_status` is `pending | warned | accepted`;
at phase 8 it is `warned` or `accepted`. A missing or unparseable `checkpoint:` block is not guessed: treat
the session as in progress and let `pm-shape` decide where to resume.

## Stack signals

The tech-stack step is a developer's step between the PRD and the roadmap. It is detected by file
presence only, and the files are **root-level** (shared by every project under the same `CONTEXT_ROOT`,
not per project): `foundation/tech-stack.md` for a greenfield PRD (written when the stack is chosen),
`foundation/stack-assessment.md` for a brownfield PRD (written when the existing stack is assessed, usually
followed by a health check). Paths are relative to `CONTEXT_ROOT`.

<!-- stack-signals:start -->
- `foundation/tech-stack.md`
- `foundation/stack-assessment.md`
<!-- stack-signals:end -->

A person may skip this step and go straight to `pm-roadmap`; the skill never skips it by policy.

## Contract check procedure

Every PM skill that parses `prd.md` or `roadmap.md` runs this before reading anything else from it:

1. Pick the heading list: `prd-greenfield` or `prd-brownfield` (by the PRD's `context_type`), or `roadmap`.
2. For each heading, test for an exact whole-line match, for example
   `grep -qxF -- "## Success Criteria" prd.md`.
3. Collect the headings that did not match.
4. None missing → continue. Any missing → print one line and STOP; never guess-parse:

   ```
   CONTRACT MISMATCH: <file> missing <comma-separated headings>
   ```

Skills that read a PRD section with its own required subsections (the `prd-success-criteria` block) add
those subsection lines to the same check: they are tested as whole-line matches, and a missing one is
reported in the same `CONTRACT MISMATCH` line (for example `prd.md missing ### Guardrails`).

In plain mode say it in words instead ("The product write-up is missing sections my other steps rely on:
… . Please re-run the PRD step"), and keep the exact line for the technical log. The drift check
(`scripts/check-upstream.sh`) is a maintainer tool, run by hand against a local checkout of the source the
vendored skills came from; skills never run it.
