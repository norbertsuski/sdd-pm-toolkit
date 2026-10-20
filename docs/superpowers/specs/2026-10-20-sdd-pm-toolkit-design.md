# sdd-pm-toolkit — Design (v0.1)

Date: 2026-10-20 · Author: Norbert Suski · Status: draft

## Purpose

A Claude Code plugin (`sdd-pm-skills`) with skills for a **product manager**, built as a
companion to the `sdd-skills` plugin (repo `sdd-toolkit`, v0.4.1). The PM toolkit covers the
product work around the SDD pipeline — research, discovery orchestration, PRD review, metrics,
prioritization, backlog sync, forecasting and stakeholder status — and **reuses** `sdd-skills`
for shaping, PRD and roadmap instead of copying them.

## Decisions (from the 2026-10-20 session)

| # | Decision |
|---|---|
| D1 | Product manager first. Project-manager skills (RAID, stakeholders, launch, retro) are v0.2+. |
| D2 | Depend on `sdd-skills` at runtime. PM skills invoke `/sdd-init`, `/sdd-frame`, `/sdd-shape`, `/sdd-prd`, `/sdd-roadmap` via the Skill tool. Nothing is copied. |
| D3 | Integrations: Jira, Confluence, Linear, Notion, Slack, email, plus git `context/` files. Markdown in `context/` is the source of truth; external tools are projections. |
| D4 | Time estimates (dates) live only in `forecast.md`, written by `pm-forecast`. `roadmap.md` stays estimate-free. `prioritization.md` may hold PM-supplied effort inputs (person-weeks), used only for scoring, never as a delivery estimate. |
| D5 | The `sdd-toolkit` repository is not modified. Every integration point uses contracts `sdd-skills` 0.4.1 already exposes. |

## Non-goals (v0.1)

- No changes to `sdd-toolkit`; no forked copies of its skills or references.
- No PM skill writes `shape-notes.md`, `roadmap.md`, `changes/**` or `archive/**`.
  `prd.md` is written only by `pm-prd-review` triage, with per-finding approval.
- No two-way tracker sync: tracker status is never written back into `roadmap.md`.
- No sending of messages (Slack post, email send) without an explicit yes naming the destination.
- No time estimates outside `forecast.md`. `prioritization.md` may hold PM-supplied effort inputs used only for scoring, not as delivery estimates.

## Ownership boundary

| Artifact (under `$CONTEXT_ROOT/`) | Sole writer | PM toolkit access |
|---|---|---|
| `.sdd.yml`, `README.md` | `/sdd-init` | read |
| `.sdd.local.yml` (`audience:`) | any audience-aware skill | read; write `audience:` only, same protocol as sdd plain-mode |
| `foundation/<slug>/shape-notes.md` | `/sdd-shape` | read |
| `foundation/<slug>/prd.md` | `/sdd-prd` (+ review skills flip `status`) | read; `pm-prd-review` edits with per-finding approval, may set `status: reviewed` |
| `foundation/<slug>/roadmap.md` | `/sdd-roadmap`, `/sdd-archive` (Done) | read only |
| `changes/**`, `archive/**` | sdd change skills | read only |
| `foundation/<slug>/research/*.md` | `pm-research-synthesis` | write |
| `foundation/<slug>/prd-review-<date>.md` | `pm-prd-review` | write |
| `foundation/<slug>/metrics.md` | `pm-metrics` | write |
| `foundation/<slug>/prioritization.md` | `pm-prioritize` | write |
| `foundation/<slug>/forecast.md` | `pm-forecast` | write |
| `foundation/<slug>/tracker-map.md` | `pm-backlog-sync` | write |
| `foundation/<slug>/status/<date>.md` | `pm-status` | write |
| `foundation/<slug>/pm-config.yml` | any PM skill, after user confirms | write |
| `foundation/<slug>/exports/*` | PM skills (fallback when no MCP) | write |

## Runtime dependency on sdd-skills

- Every PM skill that invokes an sdd skill first checks that the skill is listed among the
  host's available skills (`sdd-shape`, `sdd-prd`, `sdd-roadmap`, `sdd-init`, `sdd-frame`).
  Missing → STOP with the install block from `pm-help/references/sdd-contract.md`.
- PM skills never link files across plugins (`../sdd-*/…`). Shared knowledge they need from
  sdd-skills (section names, frontmatter keys, folder layout, root discovery) is restated as a
  pinned **consumer contract** in `skills/pm-help/references/sdd-contract.md`, tagged
  `sdd_skills_version: 0.4.1`.
- Every skill that parses `prd.md` or `roadmap.md` runs a **contract check** first: required
  `##` headings present per the contract. Mismatch → report the missing headings and STOP
  (never guess-parse).
- `scripts/check-sdd-contract.sh <path-to-sdd-toolkit>` (manual, read-only) greps a local
  sdd-toolkit checkout for every contract string and reports drift.

## Audience

PM skills default to `audience: plain`. Resolution: read `$CONTEXT_ROOT/.sdd.local.yml`;
absent → ask the sdd plain-mode question once, write the answer (ensuring `.gitignore` lists
`.sdd.local.yml`), so sdd skills invoked later do not ask again. Plain mode = no jargon in
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
| `pm-help` | optional skill/project arg | chat only | Read-only map + "you are here" across PM and SDD artifacts |
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
- GitLab CI runs all three automated checks.

## Amendments (2026-10-20, during implementation)

- R11: sdd verdicts are spelled `APPROVED | NEEDS ATTENTION | REJECTED | SKIPPED (...)` (space); only `pm-prd-review`'s own artifact uses `NEEDS_ATTENTION`.
- R13: `pm-status` needs-triage follows sdd's classification: negative = REJECTED or NEEDS ATTENTION with pending decisions; positive = APPROVED, SKIPPED, triaged NEEDS ATTENTION.
- R16: `pm-discover` adds the sdd stack gate before the roadmap (`foundation/tech-stack.md` or `foundation/stack-assessment.md`); the human may hand off or skip.
- R17: `prd.md` presence wins over shape state in `pm-discover` stage derivation; a draft unreviewed PRD is routed to `/pm-prd-review` even when a roadmap exists.
- R21: `pm-discover` counts the PRD as reviewed only by `status: reviewed|locked` or a latest review with `verdict: APPROVED`; a NEEDS_ATTENTION or REJECTED latest review keeps the stage `specified`.
- R23: `pm-prioritize` hand-off is a `/sdd-roadmap` re-run (list as input to its anchor questions, with a warning that regeneration rebuilds statuses) or a human hand-edit of `roadmap.md`; no per-slice overrides are promised.
- R24: `pm-forecast` throughput pools every archived change under the context root (team pace), and `forecast.md` caveats say so.
- R25: `tracker-map.md` gains a `Synced hash` column (sha256 of the rendered description, 12 hex) so changed descriptions can be detected.
- R26: export files are named `exports/<YYYY-MM-DD>-<what>.<ext>` per `integrations.md` (for example `exports/<date>-backlog.csv`).
- R29: `forecast.md` frontmatter carries a machine-readable `deadline_risk` that `pm-status` reads; the script is unchanged.
