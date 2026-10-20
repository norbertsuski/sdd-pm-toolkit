---
name: pm-help
description: >
  Explain the product-manager (PM) toolkit — what the pm-* skills do and in what order — and show
  where a project stands. Read-only:
  never writes or edits files. With NO argument it shows the whole PM flow from research to stakeholder
  status. With a skill or topic argument it answers that targeted question. With a project name, or a
  "where am I" request, it reports which project artifacts exist (with dates) and names the single
  next skill to run. Use when the user asks "pm help", "how does the PM toolkit work", "what pm skills
  are there", "which pm skill do I run", "what should I do next on my product", "where are we on this
  project", "explain the product flow", "pomoc pm", "jak działa pm toolkit", "od czego zacząć jako PM",
  "gdzie jesteśmy w projekcie", "co dalej z produktem", or is unsure how research, PRD review, metrics,
  roadmap, backlog and status fit together. This is the map and entry point for the pm-* skill family.
---

# /pm-help — How the Product-Manager Toolkit Works

This skill is the **map** for the `pm-*` skills (plugin `sdd-pm-skills`). They cover the whole product
flow in one plugin — setup, research, discovery, framing, shaping, the PRD, PRD review, metrics, the
roadmap, prioritization, backlog sync, forecasting and status — and hand the roadmap to developers
when it is ready to build. How this skill answers depends on the argument:

- **No argument** → the whole flow, step by step, with the skill that owns each step.
  It does not look at any project files.
- **A skill or topic** (`/pm-help prd-review`, `/pm-help metrics`) → a targeted answer about that one thing.
- **A project name** (`/pm-help recipe-fridge`) or a status request ("where am I", "what's next") → a
  "you are here" report for that project plus the single next skill.

It is **read-only**: it never creates, edits or moves files, and it never starts another skill. It points
at the skill that owns each step and stops.

Never writes `prd.md`, `shape-notes.md`, or `roadmap.md`.

## Audience and installed skills

Audience: `pm-help` never asks the audience question and never writes `.sdd.local.yml`. Read `audience:`
from `$CONTEXT_ROOT/.sdd.local.yml` when a root is resolved (Branch C); otherwise use `plain`. Plain mode
follows `references/plain-language.md`: say what each step does first, show the command once in
parentheses, and keep the output free of schema talk.

Installed in this plugin (15): `pm-help`, `pm-init`, `pm-frame`, `pm-shape`, `pm-prd`, `pm-roadmap`, `pm-map`, `pm-research-synthesis`, `pm-discover`, `pm-prd-review`, `pm-metrics`, `pm-prioritize`, `pm-backlog-sync`, `pm-forecast`, `pm-status`.
Before recommending any `/pm-*` command, confirm it is in the host's
available skills; if it is not, still name the step but say plainly that this command is not available in
this session, and never imply it will run.

## The flow

```
 init ──▶ research ──▶ discover ─────────────────────────────▶ prd-review ──▶ metrics
 (pm-init) (pm-research-  (pm-discover routes:                   (pm-prd-       (pm-metrics)
            synthesis)     pm-frame? → pm-shape → pm-prd)         review)
                                                                          │
 status ◀── forecast ◀── backlog-sync ◀── prioritize ◀── map ◀── roadmap ◀┘
 (pm-status) (pm-forecast) (pm-backlog-sync) (pm-prioritize) (pm-map) (pm-roadmap)
                                                               │
                                       build side: developers plan, build and archive each change
```

| # | Step | Skill | Produces |
|---|---|---|---|
| 0 | Set up the project folder (once per repo) | `pm-init` | the context root: `README.md`, `.sdd.yml`, `.sdd.local.yml` |
| 1 | Research (optional) | `pm-research-synthesis` | `research/<date>-<topic>.md` — insights with verbatim quotes |
| 2 | Discover: frame, shape, PRD | `pm-discover` (routes to `pm-shape` and `pm-prd`; each can also be run directly; `pm-frame` challenges the framing of a problem first when needed) | `frame-<date>-<topic>.md` (`pm-frame`), `shape-notes.md` (`pm-shape`), `prd.md` (`pm-prd`) |
| 3 | PRD review | `pm-prd-review` | `prd-review-<date>.md`; approved edits to `prd.md` |
| 4 | Metrics | `pm-metrics` | `metrics.md` — success measures, guardrails, tracking plan |
| 5 | Roadmap | `pm-roadmap` (`pm-map` draws it as a dependency graph) | `roadmap.md` — ordered, user-visible slices; `roadmap-map.md` — the graph |
| 6 | Prioritize | `pm-prioritize` | `prioritization.md` (the roadmap is never edited) |
| 7 | Backlog sync | `pm-backlog-sync` | tracker issues + `tracker-map.md` |
| 8 | Forecast | `pm-forecast` | `forecast.md` — dates as ranges, only with enough history |
| 9 | Status | `pm-status` | `status/<date>.md` — stakeholder report, optional publish |

After step 5 the **build side** belongs to the developers: they plan, build, review and archive each
change in their own development workflow, and `pm-help` only shows where it meets the PM flow. Steps 6–9
repeat as the project moves.

Artifacts live under a resolved context root, per project: `foundation/<slug>/` for PM and PRD files,
`changes/` for work in flight, `archive/` for finished changes. The PM skills write only their own files
(see `references/pm-artifacts.md`); the developers' files (`changes/**`, `archive/**`) are read-only to them. Shared rules: `references/context-resolution.md`
(finding the root), `references/artifact-contract.md` (the file formats the PM skills expect),
`references/integrations.md` (Jira/Linear/Confluence/Notion/Slack/email), `references/plain-language.md`.

## Process

Classify the argument first, then run exactly one branch:

- **No argument** → Branch A.
- **A skill name or topic** (`research`, `discover`, `prd-review`, `metrics`, `prioritize`, `backlog-sync`,
  `forecast`, `status`, `init`, `frame`, `shape`, `prd`, `roadmap`, `map`, or a question such as "difference between prd-review
  and metrics") → Branch B.
- **A project slug**, a root path, or a status request ("where am I", "what's next", "gdzie jesteśmy") → Branch C.

If ambiguous, prefer Branch B for a single word that matches a skill name, otherwise Branch C.

### Branch A — No argument: the flow map

Do not read project files. Walk the steps above in order, one or two plain sentences each, naming the
skill that owns it, and say which steps are optional (research, prioritize, forecast) and which are done
by developers (the build side). For step 2 say that the PM can also run its parts directly: `/pm-init` (set up the
project folder), `/pm-frame` (check you are solving the right problem), `/pm-shape` (shape the idea into notes) and `/pm-prd` (turn the notes into the PRD); for step 5 it can also name `/pm-roadmap` (the ordered build plan) and `/pm-map` (the plan as a picture). Lead with the first action, then stop:

```
► Start here: /pm-discover "<one line about the product or feature idea>"
  (Have interview notes or survey results first? /pm-research-synthesis turns them into insights.)
  Already working on a project? /pm-help <project-name> shows where it stands.
  No project folder yet? /pm-init sets one up.
```

If the audience is `plain`, replace command-first phrasing with what each step does and show each command once
in parentheses. Do not run any command for the user.

### Branch B — A skill or topic

Answer only that. For a `pm-*` skill, read that skill's own `SKILL.md` (it sits in a sibling folder named after
the skill) and summarize what it needs, what it writes, where it stops and what comes next; if that skill is not
available in the session, say so and answer from the table above. For a build-side topic (`plan`, `implement`, `archive`),
say it is a developer's step in their own workflow, outside this plugin, and show where it meets the flow above. Do not probe the
project. Then stop.

### Branch C — A project or "where am I": the you-are-here report

1. Resolve the root and the project exactly as `references/context-resolution.md` says (discover `.sdd.yml`,
   classify flat or legacy, show the pick with the nearest root preselected, then pick the project under
   `foundation/`, excluding `archive/`). No root → say so and recommend `/pm-init`; stop. No project → recommend
   `/pm-discover`; stop.
2. Probe with read-only commands (`find`, `ls`, `test`, `grep`, Read) only. For each artifact give its date from
   frontmatter (`updated:`, else `created:`):

   | Side | Artifacts |
   |---|---|
   | Spec and build | `shape-notes.md`; `prd.md` (status, version, open questions that say `Block: yes`); `roadmap.md` (item counts by status); `changes/*/` (each change and its `status`); `archive/` (count of finished changes) |
   | PM | `research/*.md` (count, newest); `prd-review-*.md` (newest and its verdict); `metrics.md`; `prioritization.md`; `forecast.md`; `tracker-map.md`; `status/*.md` (newest); `pm-config.yml` (tracker, docs, channel) |

   Mark each missing artifact as `absent`; do not infer it exists elsewhere. Keep reads light: this skill
   orients, it does not audit. If `prd.md` or `roadmap.md` is read for details beyond file presence and the
   frontmatter, run the contract check from `references/artifact-contract.md` first and STOP with its mismatch line
   if headings are missing.
3. Print the report, then one next move:

   ```
   ═══════════════════════════════════════════════════════════
     PM STATUS — <project name>      root: <CONTEXT_ROOT> (flat|legacy)
   ═══════════════════════════════════════════════════════════
     SPEC  shape-notes: <date|absent> | PRD: <status, date|absent> | roadmap: <n done / n total, date|absent>
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
2. `shape-notes.md` present, no `prd.md` → `/pm-prd` (or `/pm-shape` if shaping looks unfinished: its `checkpoint.current_phase` is below 8).
3. `prd.md` is not reviewed (its `status` is not `reviewed` or `locked`, and the **latest** `prd-review-*.md` is absent or its `verdict` is not `APPROVED`) → `/pm-prd-review` (if a latest report exists with another verdict, say that review can be resumed).
4. No `metrics.md` → `/pm-metrics`.
5. No `roadmap.md` → `/pm-roadmap` (the tech-stack choice comes before it, as a developer's step; mention it only if `foundation/tech-stack.md` or `foundation/stack-assessment.md` is absent and the user has not skipped it).
6. No `prioritization.md` and at least two roadmap items are not `done` → `/pm-prioritize`.
7. A roadmap exists, no `tracker-map.md` yet, and `pm-config.yml` is absent or its `tracker` is not explicitly `none` → `/pm-backlog-sync`.
8. No `forecast.md` and `archive/` is not empty → `/pm-forecast`.
9. No `status/*.md`, or the newest is more than 7 days old → `/pm-status`.
10. Everything above is current → hand over to the build side: name the north-star slice if it is `ready` (else the first `ready` slice) as ready for a developer to plan; if a change is already in `changes/`, say so (with its `status`) and leave its next step to the developers.

Always stop after reporting. Never run the recommended command.

## Guardrails

1. **Read-only.** Never write, edit, move or delete a file, never write `.sdd.local.yml`, never call a write tool of a tracker, docs or chat adapter. Probes are `find`/`test`/`ls`/`grep`/Read only.
2. **No guessing.** A missing artifact is `absent`, a missing heading is a contract mismatch; do not infer state the files do not show.
3. **Honest about what is available.** Name only what the host lists as available; say plainly when a recommended skill is not available in the session.
4. **One recommendation, not a menu.** End Branch C with one next move and a one-line reason; offer alternatives only when asked.
5. **Never chain.** Do not start the next skill; the human decides.
6. **Plain by default.** PM audience is `plain` unless `.sdd.local.yml` says `technical`; no jargon in operator-facing text (`references/plain-language.md`).
7. **Mirror the user's language.** A Polish question gets a Polish answer; translate section names (`Open Questions` → `Otwarte pytania`).
8. **Ownership.** `prd.md`, `shape-notes.md` and `roadmap.md` belong to `pm-prd`, `pm-shape` and `pm-roadmap`; `changes/**` and `archive/**` belong to the developers' workflow; this skill reads them and nothing else.

## Notes

- This is an orientation skill. Its output is an explanation and a recommendation, never a file.
- If the PM flow or the installed set changes, update the flow table, the installed list above and `references/eval-cases.md` together.
