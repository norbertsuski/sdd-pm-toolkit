# sdd-pm-toolkit — Design (v0.1)

Date: 2026-10-20 · Author: Norbert Suski · Status: draft

## Purpose

A Claude Code plugin (`sdd-pm-skills`) with skills for a **product manager**. It covers the whole
product flow — project setup, research, discovery orchestration, framing, shaping, the PRD, PRD
review, metrics, the roadmap and its map, prioritization, backlog sync, forecasting and
stakeholder status — and produces the file formats developers' SDD tooling reads. As amended
(see Amendments), the six core SDD skills are vendored as `pm-*` skills, so the plugin has no
runtime dependency on any other plugin.

## Decisions (from the 2026-10-20 session)

| # | Decision |
|---|---|
| D1 | Product manager first. Project-manager skills (RAID, stakeholders, launch, retro) are v0.2+. |
| D2 | Core SDD skills vendored as `pm-*`; no runtime dependency. (Originally: depend on `sdd-skills` at runtime and invoke its skills via the Skill tool, nothing copied.) `pm-init`, `pm-frame`, `pm-shape`, `pm-prd`, `pm-roadmap` and `pm-map` are adapted copies recorded in `VENDORED.md`; the formats they write are unchanged. |
| D3 | Integrations: Jira, Confluence, Linear, Notion, Slack, email, plus git `context/` files. Markdown in `context/` is the source of truth; external tools are projections. |
| D4 | Time estimates (dates) live only in `forecast.md`, written by `pm-forecast`. `roadmap.md` stays estimate-free. `prioritization.md` may hold PM-supplied effort inputs (person-weeks), used only for scoring, never as a delivery estimate. |
| D5 | The upstream skills repository is never modified. Compatibility is by file format only: every format the PM skills read or write is pinned in `artifact-contract.md`, and `VENDORED.md` records the source commit of every vendored file. |

## Non-goals (v0.1)

- No changes to the upstream skills repository (D5). The six vendored skills (D2) are adapted copies recorded in
  `VENDORED.md`, not forks that track upstream; compatibility is by file format only.
- No PM skill writes `changes/**` or `archive/**` (a developer's workflow owns them). The vendored skills are the
  sole writers of `shape-notes.md` (`pm-shape`), `prd.md` (`pm-prd`; `pm-prd-review` edits it only per approved
  finding), `roadmap.md` (`pm-roadmap`) and `roadmap-map.md` (`pm-map`), per the ownership table below.
- No two-way tracker sync: tracker status is never written back into `roadmap.md`.
- No sending of messages (Slack post, email send) without an explicit yes naming the destination.
- No time estimates outside `forecast.md`. `prioritization.md` may hold PM-supplied effort inputs used only for scoring, not as delivery estimates.

## Ownership boundary

| Artifact (under `$CONTEXT_ROOT/`) | Sole writer | PM toolkit access |
|---|---|---|
| `.sdd.yml`, `README.md` | `pm-init` | write (`pm-init`); read elsewhere |
| `.sdd.local.yml` (`audience:`) | `pm-init` and any audience-aware skill | read; write `audience:` only, same protocol as the plain-language reference |
| `foundation/<slug>/shape-notes.md` | `pm-shape` | write (`pm-shape`); read elsewhere |
| `foundation/<slug>/prd.md` | `pm-prd` (+ review skills flip `status`) | write (`pm-prd`); `pm-prd-review` edits with per-finding approval, may set `status: reviewed` |
| `foundation/<slug>/roadmap.md` | `pm-roadmap`; a developer's archive step (Done) | write (`pm-roadmap`); read elsewhere |
| `foundation/<slug>/roadmap-map.md` | `pm-map` | write |
| `foundation/<slug>/frame-<date>-<topic>.md` | `pm-frame` | write |
| `changes/**`, `archive/**` | a developer's workflow | read only |
| `foundation/<slug>/research/*.md` | `pm-research-synthesis` | write |
| `foundation/<slug>/prd-review-<date>.md` | `pm-prd-review` | write |
| `foundation/<slug>/metrics.md` | `pm-metrics` | write |
| `foundation/<slug>/prioritization.md` | `pm-prioritize` | write |
| `foundation/<slug>/forecast.md` | `pm-forecast` | write |
| `foundation/<slug>/tracker-map.md` | `pm-backlog-sync` | write |
| `foundation/<slug>/status/<date>.md` | `pm-status` | write |
| `foundation/<slug>/pm-config.yml` | any PM skill, after user confirms | write |
| `foundation/<slug>/exports/*` | PM skills (fallback when no MCP) | write |

## Compatibility with SDD development workflows

- The plugin needs no other plugin at runtime. Developers' SDD tooling and the PM skills meet
  only at file formats: `prd.md`, `roadmap.md`, `shape-notes.md`, the `context/` root, and the
  read-only `changes/**` and `archive/**` folders.
- Those formats are restated as data in `skills/pm-help/references/artifact-contract.md`
  (marker blocks plus the contract check procedure). No file links cross plugins.
- Every skill that parses `prd.md` or `roadmap.md` runs a **contract check** first: required
  `##` headings present per the contract. Mismatch → report the missing headings
  (`CONTRACT MISMATCH: <file> missing <headings>`) and STOP (never guess-parse).
- `VENDORED.md` records every vendored file: its source file, the source commit and the
  adaptations. `scripts/check-upstream.sh <path-to-source-checkout>` (manual, read-only, never
  in CI) greps a local checkout of the source for every contract string and lists the vendored
  source files that changed since the recorded commit.

## Audience

PM skills default to `audience: plain`. Resolution: read `$CONTEXT_ROOT/.sdd.local.yml`;
absent → ask the plain-mode question once, write the answer (ensuring `.gitignore` lists
`.sdd.local.yml`), so every PM skill invoked later reads it instead of asking again. Plain mode = no jargon in
operator-facing text (rules in `pm-help/references/plain-language.md`); artifacts on disk are
identical in both modes.

## Integrations

- Adapter detection by available tool names (case-insensitive substring): `jira`, `confluence`,
  `linear`, `notion`, `slack`, `gmail` / `outlook` (email drafts).
- Choice per project persisted in `foundation/<slug>/pm-config.yml` after confirmation:

  ```yaml
  tracker: jira | linear | none
  tracker_project: <Jira project key | Linear team key>
  docs: confluence | notion | none
  docs_location: <Confluence space key + parent page id | Notion parent page id>
  channel: slack | email | none
  channel_target: <#channel | email address list>
  status_page: <Confluence page id | Notion page id>
  ```
- **Write protocol** (every external write): preview (what, where, count) → explicit choice
  `Apply` / `Export file instead` / `Cancel` → sequential writes, stop on first error, persist
  partial progress → report keys/URLs.
- **Messages**: default is a draft (Slack draft text / email draft). Posting requires a
  separate yes that names the channel or recipients.
- **No MCP available** → export to `foundation/<slug>/exports/` (Jira CSV, Markdown page,
  message text) and say so.

## Skills (v0.1)

| Skill | Input | Output | Notes |
|---|---|---|---|
| `pm-help` | optional skill/project arg | chat only | Read-only map + "you are here" across the project's artifacts |
| `pm-init` | optional target folder | the `context/` root (`README.md`, `.sdd.yml`, `.sdd.local.yml`) | Vendored; idempotent |
| `pm-frame` | an observation plus a proposed cause or solution | `frame-<date>-<topic>.md` | Vendored; never touches `changes/**` |
| `pm-shape` | an idea or research file | `shape-notes.md` | Vendored; resumable; plain by default |
| `pm-prd` | `shape-notes.md` or raw notes | `prd.md` | Vendored; schema-conformant, gaps in Open Questions |
| `pm-roadmap` | `prd.md` | `roadmap.md` | Vendored; vertical slices, no estimates |
| `pm-map` | `roadmap.md` | `roadmap-map.md` | Vendored; deterministic Mermaid graph |
| `pm-research-synthesis` | transcripts, notes, survey exports | `research/<date>-<topic>.md` | Every insight cites verbatim quotes with source ids; PII pseudonymized |
| `pm-discover` | idea or research file | routes only | init → (frame) → shape → prd → prd-review → roadmap; human gate between steps |
| `pm-prd-review` | `prd.md` | `prd-review-<date>.md`, approved edits to `prd.md` | 7 dimensions, APPROVED / NEEDS_ATTENTION / REJECTED, triage loop |
| `pm-metrics` | `prd.md` | `metrics.md` | North-star metric, input tree, criteria→metric map, guardrails, tracking plan |
| `pm-prioritize` | `roadmap.md` (or PRD FRs) | `prioritization.md` | RICE default, ICE, MoSCoW; reports dependency conflicts; never edits roadmap |
| `pm-forecast` | `roadmap.md`, `archive/*/change.md` | `forecast.md` | Monte Carlo on weekly throughput, p50/p85/p95; insufficient history → no dates |
| `pm-backlog-sync` | roadmap Backlog Handoff + slices + PRD stories | Jira/Linear issues, `tracker-map.md` | Idempotent, one-way, never deletes |
| `pm-status` | roadmap, changes, archive, forecast, tracker-map | `status/<date>.md`, optional publish | RAG rules deterministic; diff vs previous status |

## Quality

- `scripts/validate-structure.sh` — structural invariants (manifests, frontmatter, counts,
  links, ownership strings, eval catalogs).
- `scripts/validate-pm-evals.sh` — deterministic reference functions for sync actions and RAG.
- `tests/test_forecast.py` — stdlib `unittest` for `pm-forecast/scripts/forecast.py`.
- `skills/*/references/eval-cases.md` — behavioral prompt fixtures per skill.
- GitHub Actions (`.github/workflows/validate.yml`) runs all three automated checks.

## Amendments (2026-10-20, during implementation)

- R11: sdd verdicts are spelled `APPROVED | NEEDS ATTENTION | REJECTED | SKIPPED (...)` (space); only `pm-prd-review`'s own artifact uses `NEEDS_ATTENTION`.
- R13: `pm-status` needs-triage follows sdd's classification: negative = REJECTED or NEEDS ATTENTION with pending decisions; positive = APPROVED, SKIPPED, triaged NEEDS ATTENTION.
- R16: `pm-discover` adds the technology-choice gate before the roadmap (`foundation/tech-stack.md` or `foundation/stack-assessment.md` present; a developer's step); the human may hand off or skip.
- R17: `prd.md` presence wins over shape state in `pm-discover` stage derivation; a draft unreviewed PRD is routed to `/pm-prd-review` even when a roadmap exists.
- R21: `pm-discover` counts the PRD as reviewed only by `status: reviewed|locked` or a latest review with `verdict: APPROVED`; a NEEDS_ATTENTION or REJECTED latest review keeps the stage `specified`.
- R23: `pm-prioritize` hand-off is a `/pm-roadmap` re-run (list as input to its anchor questions, with a warning that regeneration rebuilds statuses) or a human hand-edit of `roadmap.md`; no per-slice overrides are promised.
- R24: `pm-forecast` throughput pools every archived change under the context root (team pace), and `forecast.md` caveats say so.
- R25: `tracker-map.md` gains a `Synced hash` column (sha256 of the rendered description, 12 hex) so changed descriptions can be detected.
- R26: export files are named `exports/<YYYY-MM-DD>-<what>.<ext>` per `integrations.md` (for example `exports/<date>-backlog.csv`).
- R29: `forecast.md` frontmatter carries a machine-readable `deadline_risk` that `pm-status` reads; the script is unchanged.
- `pm-config.yml` gains `status_page` (pm-status stores the Confluence/Notion page id).
- Standalone (v0.1, before release): core SDD skills vendored as `pm-*` (`pm-init`, `pm-frame`, `pm-shape`, `pm-prd`, `pm-roadmap`, `pm-map`); no runtime dependency. D2 and the ownership table are amended accordingly, "Runtime dependency on sdd-skills" became "Compatibility with SDD development workflows", the contract file is `artifact-contract.md`, and the drift script is `scripts/check-upstream.sh`. The shared references `prd-schema.md` and `plain-language.md` carry the vendored schema and audience rules.
