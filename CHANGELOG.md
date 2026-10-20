# Changelog

## 0.1.0 — 2026-10-20

First release of the `sdd-pm-skills` plugin (marketplace `sdd-pm-toolkit`): product-manager skills that
extend the `sdd-skills` workflow without modifying it. Consumer contract pinned to `sdd-skills 0.4.1`.

### Skills (9)

- `pm-help` — map of the PM flow and a read-only "you are here" report for a project.
- `pm-research-synthesis` — interview transcripts, notes and survey exports into evidence-linked insights (verbatim quotes, pseudonymized) with a seed for shaping.
- `pm-discover` — discovery router: derives the stage from files on disk and walks `/sdd-init`, `/sdd-shape`, `/sdd-prd`, `/pm-prd-review`, the stack step and `/sdd-roadmap`, one human-gated step at a time. Writes nothing itself.
- `pm-prd-review` — seven-dimension PRD review with quoted evidence, APPROVED / NEEDS_ATTENTION / REJECTED verdict, and per-finding triage with approved edits to `prd.md`; may set `status: reviewed`, never `locked`.
- `pm-metrics` — north-star metric, input metrics, criteria-to-metric mapping, guardrails and tracking plan; never invents targets or baselines.
- `pm-prioritize` — RICE / ICE / MoSCoW scoring computed with `python3`, dependency conflicts, proposed sequence; never edits `roadmap.md`.
- `pm-backlog-sync` — idempotent one-way sync of the roadmap Backlog Handoff to Jira or Linear with `tracker-map.md`; CSV or Markdown export when no tracker is connected; never deletes.
- `pm-forecast` — Monte Carlo forecast from archived-change throughput (stdlib `python3`), three dates never one, hard-deadline check; no dates on thin history.
- `pm-status` — stakeholder status report with deterministic red/amber/green, diff since the previous report, optional Confluence/Notion page, draft-only Slack and email.

### Contract and integrations

- Shared references in `skills/pm-help/references/`: `sdd-contract.md` (pinned `sdd_skills_version: 0.4.1`), `integrations.md`, `context-resolution.md`, `plain-language.md`, `pm-artifacts.md`.
- `scripts/check-sdd-contract.sh <path-to-sdd-toolkit>` reports drift between the contract and a local `sdd-toolkit` checkout.
- Adapters detected by tool name (Jira, Linear, Confluence, Notion, Slack, Gmail/Outlook); per-project choice in `pm-config.yml`; preview / `Apply` / `Export file instead` / `Cancel` write protocol; messages are drafts until a yes that names the destination.

### Quality

- `scripts/validate-structure.sh`, `scripts/validate-pm-evals.sh`, `tests/test_forecast.py`, per-skill `references/eval-cases.md`, and a fixture project (`tests/fixtures/flat-root`).
- `docs/smoke-test.md`: manual end-to-end checklist and live-integration checks (not verifiable offline).

### Notes

- Design amendments made during implementation are listed in `docs/superpowers/specs/2026-10-20-sdd-pm-toolkit-design.md` under "Amendments".
- Not yet verified in a live host: MCP tool discovery for Jira, Linear, Confluence, Notion and Slack; see the second section of `docs/smoke-test.md`.
