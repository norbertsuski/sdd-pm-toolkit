# PM artifacts

Everything the PM skills write, under `$CONTEXT_ROOT/foundation/<slug>/`. Each row is owned by exactly
one skill; the owning skill's task fills in the **Frontmatter** and **Required headings** cells.
Common frontmatter for every dated artifact: `project`, `created`, `updated`.

`prd.md` is the one `sdd-*` file a PM skill may edit (`pm-prd-review`, per-finding approval, may set
`status: reviewed`). `shape-notes.md`, `roadmap.md`, `changes/**` and `archive/**` are never written by
any PM skill. See `sdd-contract.md` for the sdd-owned artifacts.

| Path | Written by | Frontmatter | Required headings |
|---|---|---|---|
| `research/<date>-<topic>.md` (matches `research/*.md`) | `pm-research-synthesis` | `project`, `topic`, `created`, `updated`, `sources` (count) | `## Sources`, `## Insights`, `## Jobs to Be Done`, `## Pains & Gains`, `## Contradictions & Surprises`, `## Open Questions`, `## Seed for shaping` (format: `skills/pm-research-synthesis/references/insights-format.md`) |
| `prd-review-<date>.md` (a same-day second review is `prd-review-<date>-2.md`) | `pm-prd-review` | `project`, `prd_version`, `created`, `updated`, `verdict` (`APPROVED` \| `NEEDS_ATTENTION` \| `REJECTED`); marker `<!-- PRD-REVIEW-REPORT -->` | `## Verdicts`, `## Findings`, `## Triage log`; each finding is `### F<n> — <title>` with `Severity`, `Dimension`, `PRD ref`, `Evidence`, `Why it matters`, `Fix options`, `Decision` (format: `skills/pm-prd-review/SKILL.md` Step 7) |
| `metrics.md` | `pm-metrics` | `project`, `prd_version`, `created`, `updated` | `## North Star Metric`, `## Input Metrics`, `## Success Criteria Mapping`, `## Guardrail Metrics`, `## Tracking Plan`, `## Open Questions`; mapping table `\| PRD criterion \| Metric \| Target \| Baseline \| Window \| Owner \|`, tracking table `\| Event \| Trigger \| Properties \| PRD ref \|`; unknown values are `TBD — Owner: <role>` (format: `skills/pm-metrics/references/metrics-format.md`) |
| `prioritization.md` | `pm-prioritize` | — (filled by the owning skill's task) | — (filled by the owning skill's task) |
| `forecast.md` | `pm-forecast` | — (filled by the owning skill's task) | — (filled by the owning skill's task) |
| `tracker-map.md` | `pm-backlog-sync` | — (filled by the owning skill's task) | — (filled by the owning skill's task) |
| `status/<date>.md` | `pm-status` | — (filled by the owning skill's task) | — (filled by the owning skill's task) |
| `pm-config.yml` | any PM skill, after the user confirms | schema in `integrations.md` (`## pm-config.yml`) | — (YAML, no headings) |
| `exports/*` | PM skills (fallback when no connected tool) | — (CSV/Markdown/text, see `integrations.md`) | — |

`pm-discover` writes nothing of its own; it routes to the skills above and to `sdd-*`.
