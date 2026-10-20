---
name: pm-help
description: >
  Explain the product-manager (PM) toolkit that sits on top of the SDD skills — what the pm-* skills
  do, in what order, and which plugin owns each step — and show where a project stands. Read-only:
  never writes or edits files. With NO argument it shows the whole PM flow from research to stakeholder
  status. With a skill or topic argument it answers that targeted question. With a project name, or a
  "where am I" request, it reports which PM and SDD artifacts exist (with dates) and names the single
  next skill to run. Use when the user asks "pm help", "how does the PM toolkit work", "what pm skills
  are there", "which pm skill do I run", "what should I do next on my product", "where are we on this
  project", "explain the product flow", "pomoc pm", "jak działa pm toolkit", "od czego zacząć jako PM",
  "gdzie jesteśmy w projekcie", "co dalej z produktem", or is unsure how research, PRD review, metrics,
  roadmap, backlog and status fit together. This is the map and entry point for the pm-* skill family.
---

# /pm-help — How the Product-Manager Toolkit Works

This skill is the **map** for the `pm-*` skills (plugin `sdd-pm-skills`). They cover the product work
around the SDD pipeline — research, discovery, PRD review, metrics, prioritization, backlog sync,
forecasting and status — and reuse the `sdd-*` skills (plugin `sdd-skills`) for shaping, the PRD and the
roadmap instead of copying them. How this skill answers depends on the argument:

- **No argument** → the whole flow, step by step, with the skill and the plugin that owns each step.
  It does not look at any project files.
- **A skill or topic** (`/pm-help prd-review`, `/pm-help metrics`) → a targeted answer about that one thing.
- **A project name** (`/pm-help recipe-fridge`) or a status request ("where am I", "what's next") → a
  "you are here" report for that project plus the single next skill.

It is **read-only**: it never creates, edits or moves files, and it never starts another skill. It points
at the skill that owns each step and stops.

Never writes `prd.md`, `shape-notes.md`, or `roadmap.md`.

## Step 0 — check the required sdd skills (every branch)

The PM toolkit depends on `sdd-skills` at runtime. Check that these are listed among the host's available
skills: `sdd-init`, `sdd-frame`, `sdd-shape`, `sdd-prd`, `sdd-roadmap`. If any is missing, print the
**Install block** from `references/sdd-contract.md` (section `## Install block`), say which skills were
not found, and:

- **Branch A and B** → continue; they only explain, so they stay useful. Add one line that steps owned by
  `sdd-skills` cannot be started until it is installed.
- **Branch C** → STOP after the Install block. A "you are here" report needs the sdd artifacts and the
  sdd skills to act on them; do not guess a position.

Audience: `pm-help` never asks the audience question and never writes `.sdd.local.yml`. Read `audience:`
from `$CONTEXT_ROOT/.sdd.local.yml` when a root is resolved (Branch C); otherwise use `plain`. Plain mode
follows `references/plain-language.md`: say what each step does first, show the command once in
parentheses, and keep the output free of schema talk.

Installed in this plugin (3): `pm-help`, `pm-research-synthesis`, `pm-discover`. Planned for this release, not installed yet unless the host lists them:
`pm-prd-review`, `pm-metrics`, `pm-prioritize`, `pm-forecast`,
`pm-backlog-sync`, `pm-status`. Before recommending any `/pm-*` command, confirm it is in the host's
available skills; if it is not, still name the step but say plainly that this command is not installed in
this project, and never imply it will run.

## The flow

```
 research ──▶ discover ──────────────────────────────▶ prd-review ──▶ metrics
 (pm-research-   (pm-discover routes:                    (pm-prd-       (pm-metrics)
  synthesis)      sdd-init → sdd-frame? →                 review)
                  sdd-shape → sdd-prd)
                                                                          │
 status ◀── forecast ◀── backlog-sync ◀── prioritize ◀── roadmap ◀────────┘
 (pm-status)  (pm-forecast) (pm-backlog-sync) (pm-prioritize) (sdd-roadmap)
                                                               │
                                                  build side: sdd-plan → sdd-implement → sdd-archive
```

| # | Step | Skill | Plugin | Produces |
|---|---|---|---|---|
| 1 | Research (optional) | `pm-research-synthesis` | sdd-pm-skills | `research/<date>-<topic>.md` — insights with verbatim quotes |
| 2 | Discover: scaffold, shape, PRD | `pm-discover` (routes to `sdd-init`, `sdd-frame`, `sdd-shape`, `sdd-prd`) | sdd-pm-skills + sdd-skills | `shape-notes.md`, `prd.md` (written by the sdd skills) |
| 3 | PRD review | `pm-prd-review` | sdd-pm-skills | `prd-review-<date>.md`; approved edits to `prd.md` |
| 4 | Metrics | `pm-metrics` | sdd-pm-skills | `metrics.md` — success measures, guardrails, tracking plan |
| 5 | Roadmap | `sdd-roadmap` | sdd-skills | `roadmap.md` — ordered, user-visible slices |
| 6 | Prioritize | `pm-prioritize` | sdd-pm-skills | `prioritization.md` (the roadmap is never edited) |
| 7 | Backlog sync | `pm-backlog-sync` | sdd-pm-skills | tracker issues + `tracker-map.md` |
| 8 | Forecast | `pm-forecast` | sdd-pm-skills | `forecast.md` — dates as ranges, only with enough history |
| 9 | Status | `pm-status` | sdd-pm-skills | `status/<date>.md` — stakeholder report, optional publish |

After step 5 the **build side** belongs to `sdd-skills`: `/sdd-plan <change-id>` → `/sdd-implement` →
`/sdd-impl-review` → `/sdd-archive`. `/sdd-help` explains that half; `pm-help` only shows where it meets
the PM flow. Steps 6–9 repeat as the project moves.

Artifacts live under a resolved context root, per project: `foundation/<slug>/` for PM and PRD files,
`changes/` for work in flight, `archive/` for finished changes. The PM skills write only their own files
(see `references/pm-artifacts.md`); the sdd files are read-only to them. Shared rules: `references/context-resolution.md`
(finding the root), `references/sdd-contract.md` (what the PM skills expect from sdd files),
`references/integrations.md` (Jira/Linear/Confluence/Notion/Slack/email), `references/plain-language.md`.

## Process

Classify the argument first, then run exactly one branch:

- **No argument** → Branch A.
- **A skill name or topic** (`research`, `discover`, `prd-review`, `metrics`, `prioritize`, `backlog-sync`,
  `forecast`, `status`, `shape`, `prd`, `roadmap`, or a question such as "difference between prd-review
  and metrics") → Branch B.
- **A project slug**, a root path, or a status request ("where am I", "what's next", "gdzie jesteśmy") → Branch C.

If ambiguous, prefer Branch B for a single word that matches a skill name, otherwise Branch C.

### Branch A — No argument: the flow map

Do not read project files. Walk the nine steps above in order, one or two plain sentences each, naming the
skill and the plugin that owns it, and say which steps are optional (research, prioritize, forecast) and
which come from `sdd-skills`. Lead with the first action, then stop:

```
► Start here: /pm-discover "<one line about the product or feature idea>"
  (Have interview notes or survey results first? /pm-research-synthesis turns them into insights.)
  Already working on a project? /pm-help <project-name> shows where it stands.
  Want the build side explained? /sdd-help.
```

If the audience is `plain`, replace command-first phrasing with what each step does and show each command once
in parentheses. Do not run any command for the user.

### Branch B — A skill or topic

Answer only that. For a `pm-*` skill, read that skill's own `SKILL.md` (it sits in a sibling folder named after
the skill) and summarize what it needs, what it writes, where it stops and what comes next; if that skill is not
installed, say so and answer from the table above. For an `sdd-*` topic (`shape`, `prd`, `roadmap`, `plan`),
give the one-paragraph role from the table above and point at `/sdd-help <topic>` for detail. Do not probe the
project. Then stop.

### Branch C — A project or "where am I": the you-are-here report

1. Resolve the root and the project exactly as `references/context-resolution.md` says (discover `.sdd.yml`,
   classify flat or legacy, show the pick with the nearest root preselected, then pick the project under
   `foundation/`, excluding `archive/`). No root → say so and recommend `/sdd-init`; stop. No project → recommend
   `/pm-discover`; stop.
2. Probe with read-only commands (`find`, `ls`, `test`, `grep`, Read) only. For each artifact give its date from
   frontmatter (`updated:`, else `created:`):

   | Side | Artifacts |
   |---|---|
   | SDD | `shape-notes.md`; `prd.md` (status, version, open questions that say `Block: yes`); `roadmap.md` (item counts by status); `changes/*/` (each change and its `status`); `archive/` (count of finished changes) |
   | PM | `research/*.md` (count, newest); `prd-review-*.md` (newest and its verdict); `metrics.md`; `prioritization.md`; `forecast.md`; `tracker-map.md`; `status/*.md` (newest); `pm-config.yml` (tracker, docs, channel) |

   Mark each missing artifact as `absent`; do not infer it exists elsewhere. Keep reads light: this skill
   orients, it does not audit. If `prd.md` or `roadmap.md` is read for details beyond file presence and the
   frontmatter, run the contract check from `references/sdd-contract.md` first and STOP with its mismatch line
   if headings are missing.
3. Print the report, then one next move:

   ```
   ═══════════════════════════════════════════════════════════
     PM STATUS — <project name>      root: <CONTEXT_ROOT> (flat|legacy)
   ═══════════════════════════════════════════════════════════
     SDD   shape-notes: <date|absent> | PRD: <status, date|absent> | roadmap: <n done / n total, date|absent>
           in flight: <change-id (status)> … | archived: <n>
     PM    research: <n|absent> | PRD review: <verdict, date|absent> | metrics: <date|absent>
           prioritization: <date|absent> | backlog sync: <date|absent> | forecast: <date|absent> | status: <date|absent>

     ► Next move: <one command> — <one-line reason>
   ═══════════════════════════════════════════════════════════
   ```

   When the audience is `plain`, use the plain-language table for the labels ("product write-up", "build plan",
   "weekly report") and the handoff block from `references/plain-language.md` instead of the frame.

**Next-move ladder** (first match wins; one recommendation, not a menu):

1. No `prd.md` and no `shape-notes.md` → `/pm-discover` (or `/pm-research-synthesis` first if the user has raw research).
2. `shape-notes.md` present, no `prd.md` → `/sdd-prd` (or `/sdd-shape` if shaping looks unfinished: its `checkpoint.current_phase` is below 8).
3. `prd.md` has `status: draft` → `/pm-prd-review` (if a `prd-review-*.md` exists with a verdict other than APPROVED, say the review can be resumed).
4. No `metrics.md` → `/pm-metrics`.
5. No `roadmap.md` → `/sdd-roadmap` (the stack step comes before it; name it only if `foundation/tech-stack.md` or `foundation/stack-assessment.md` is absent and the user has not skipped it).
6. No `prioritization.md` and at least two roadmap items are not `done` → `/pm-prioritize`.
7. No `tracker-map.md` and `pm-config.yml` names a tracker other than `none` → `/pm-backlog-sync`.
8. No `forecast.md` and `archive/` is not empty → `/pm-forecast`.
9. No `status/*.md`, or the newest is more than 7 days old → `/pm-status`.
10. Everything above is current → hand over to the build side: `/sdd-plan <change-id>` for the north-star slice if it is `ready` (else the first `ready` slice); if a change is already in `changes/`, say so and point at `/sdd-help <slug>` for its exact next command.

Always stop after reporting. Never run the recommended command.

## Guardrails

1. **Read-only.** Never write, edit, move or delete a file, never write `.sdd.local.yml`, never call a write tool of a tracker, docs or chat adapter. Probes are `find`/`test`/`ls`/`grep`/Read only.
2. **No guessing.** A missing artifact is `absent`, a missing heading is a contract mismatch; do not infer state the files do not show.
3. **Honest about what is installed.** Name only what the host lists as available; say plainly when a recommended skill is not installed.
4. **One recommendation, not a menu.** End Branch C with one next move and a one-line reason; offer alternatives only when asked.
5. **Never chain.** Do not start the next skill; the human decides.
6. **Plain by default.** PM audience is `plain` unless `.sdd.local.yml` says `technical`; no jargon in operator-facing text (`references/plain-language.md`).
7. **Mirror the user's language.** A Polish question gets a Polish answer; translate section names (`Open Questions` → `Otwarte pytania`).
8. **Ownership.** `prd.md`, `shape-notes.md`, `roadmap.md`, `changes/**` and `archive/**` belong to `sdd-skills`; this skill reads them and nothing else.

## Notes

- This is an orientation skill. Its output is an explanation and a recommendation, never a file.
- If the PM flow or the installed set changes, update the flow table, the installed list above and `references/eval-cases.md` together.
