# PM artifacts

Everything the PM skills write, under `$CONTEXT_ROOT/foundation/<slug>/`. Each row is owned by exactly
one skill; the owning skill's task fills in the **Frontmatter** and **Required headings** cells.
Common frontmatter for every dated artifact: `project`, `created`, `updated`.

`prd.md` is the one `sdd-*` file a PM skill may edit (`pm-prd-review`, per-finding approval, may set
`status: reviewed`). `shape-notes.md`, `roadmap.md`, `changes/**` and `archive/**` are never written by
any PM skill. See `sdd-contract.md` for the sdd-owned artifacts.

| Path | Written by | Frontmatter | Required headings |
|---|---|---|---|
| `research/*.md` | `pm-research-synthesis` | — (filled by the owning skill's task) | — (filled by the owning skill's task) |
| `prd-review-<date>.md` | `pm-prd-review` | — (filled by the owning skill's task) | — (filled by the owning skill's task) |
| `metrics.md` | `pm-metrics` | — (filled by the owning skill's task) | — (filled by the owning skill's task) |
| `prioritization.md` | `pm-prioritize` | — (filled by the owning skill's task) | — (filled by the owning skill's task) |
| `forecast.md` | `pm-forecast` | — (filled by the owning skill's task) | — (filled by the owning skill's task) |
| `tracker-map.md` | `pm-backlog-sync` | — (filled by the owning skill's task) | — (filled by the owning skill's task) |
| `status/<date>.md` | `pm-status` | — (filled by the owning skill's task) | — (filled by the owning skill's task) |
| `pm-config.yml` | any PM skill, after the user confirms | schema in `integrations.md` (`## pm-config.yml`) | — (YAML, no headings) |
| `exports/*` | PM skills (fallback when no connected tool) | — (CSV/Markdown/text, see `integrations.md`) | — |

`pm-discover` writes nothing of its own; it routes to the skills above and to `sdd-*`.
