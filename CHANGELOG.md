# Changelog

## 0.1.0 — 2026-10-20

First release of the `sdd-pm-skills` plugin (marketplace `sdd-pm-toolkit`): the whole product-manager flow in one
self-contained plugin, with no runtime dependency on any other plugin. Six core skills were adapted from an
upstream skills repository and are recorded in `VENDORED.md`; their file formats are unchanged, so developers'
SDD tooling reads what they write.

### Skills (15)

- `pm-help` — map of the PM flow and a read-only "you are here" report for a project.
- `pm-init` — scaffolds the `context/` root (`README.md`, `.sdd.yml`, per-person `.sdd.local.yml`); idempotent.
- `pm-research-synthesis` — interview transcripts, notes and survey exports into evidence-linked insights (verbatim quotes, pseudonymized) with a seed for shaping.
- `pm-discover` — discovery router: derives the stage from files on disk and walks `/pm-init`, `/pm-frame`, `/pm-shape`, `/pm-prd`, `/pm-prd-review`, the developers' technology choice and `/pm-roadmap`, one human-gated step at a time. Writes nothing itself.
- `pm-frame` — challenges the framing of a problem before shaping; writes a Frame Brief (`frame-<date>-<topic>.md`); never touches `changes/**`.
- `pm-shape` — facilitated discovery conversation into `shape-notes.md`; resumable from a checkpoint; plain language by default.
- `pm-prd` — `shape-notes.md` (or raw notes) into a schema-conformant `prd.md`; every gap lands in Open Questions.
- `pm-prd-review` — seven-dimension PRD review with quoted evidence, APPROVED / NEEDS_ATTENTION / REJECTED verdict, and per-finding triage with approved edits to `prd.md`; may set `status: reviewed`, never `locked`.
- `pm-metrics` — north-star metric, input metrics, criteria-to-metric mapping, guardrails and tracking plan; never invents targets or baselines.
- `pm-roadmap` — PRD into `roadmap.md`: ordered vertical slices, foundations, prerequisites, a Backlog Handoff table; no estimates or dates.
- `pm-map` — the roadmap as a Mermaid dependency graph (`roadmap-map.md`) drawn by a bundled script; optional hook keeps it fresh.
- `pm-prioritize` — RICE / ICE / MoSCoW scoring computed with `python3`, dependency conflicts, proposed sequence; never edits `roadmap.md`.
- `pm-backlog-sync` — idempotent one-way sync of the roadmap Backlog Handoff to Jira or Linear with `tracker-map.md`; CSV or Markdown export when no tracker is connected; never deletes.
- `pm-forecast` — Monte Carlo forecast from archived-change throughput (stdlib `python3`), three dates never one, hard-deadline check; no dates on thin history.
- `pm-status` — stakeholder status report with deterministic red/amber/green, diff since the previous report, optional Confluence/Notion page, draft-only Slack and email.

### Contract and integrations

- Shared references in `skills/pm-help/references/`: `artifact-contract.md` (the file-format contract with developers' SDD tooling), `prd-schema.md`, `integrations.md`, `context-resolution.md`, `plain-language.md`, `pm-artifacts.md`.
- `VENDORED.md` lists every vendored file with its source file, source commit and the adaptations made.
- `scripts/check-upstream.sh <path-to-source-checkout>` (manual, never in CI) reports contract strings the source no longer contains and vendored source files that changed since the recorded commit.
- Adapters detected by tool name (Jira, Linear, Confluence, Notion, Slack, Gmail/Outlook); per-project choice in `pm-config.yml`; preview / `Apply` / `Export file instead` / `Cancel` write protocol; messages are drafts until a yes that names the destination.

### Quality

- `scripts/validate-structure.sh`, `scripts/validate-pm-evals.sh`, `tests/test_forecast.py`, per-skill `references/eval-cases.md`, and a fixture project (`tests/fixtures/flat-root`).
- `docs/smoke-test.md`: manual end-to-end checklist and live-integration checks (not verifiable offline).

### Notes

- Design amendments made during implementation are listed in `docs/superpowers/specs/2026-10-20-sdd-pm-toolkit-design.md` under "Amendments".
- Not yet verified in a live host: MCP tool discovery for Jira, Linear, Confluence, Notion and Slack; see the second section of `docs/smoke-test.md`.
