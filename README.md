# sdd-pm-toolkit

Personal Claude Code marketplace of product-manager skills for the SDD workflow.

Ships one plugin: **sdd-pm-skills** (6 `pm-*` skills) — requires the **sdd-skills** plugin.

## Install

Install both plugins (the PM skills call into `sdd-skills`):

```
/plugin marketplace add https://gitlab.com/norbert.suski/sdd-toolkit.git
/plugin install sdd-skills@sdd-toolkit
/plugin marketplace add https://gitlab.com/norbert.suski/sdd-pm-toolkit.git
/plugin install sdd-pm-skills@sdd-pm-toolkit
```

## Update

```
# after pushing changes (and bumping "version" in .claude-plugin/plugin.json)
/plugin marketplace update
/plugin update
```

## Local testing (no install)

Run Claude Code in any project with both repos as plugin dirs:

```
claude --plugin-dir /path/to/sdd-pm-toolkit --plugin-dir /path/to/sdd-toolkit
```

## Skills

| Skill | Purpose |
|---|---|
| `pm-help` | Map of the PM flow and a "you are here" report for a project. Read-only. |
| `pm-research-synthesis` | Turns interview transcripts, notes and survey exports into evidence-linked insights (verbatim quotes, pseudonymized) with a seed for shaping. |
| `pm-discover` | The discovery router: derives the project's stage from files on disk and walks the PM, one human-gated step at a time, through `/sdd-init`, `/sdd-shape`, `/sdd-prd`, `/pm-prd-review`, the stack step and `/sdd-roadmap`. Writes nothing itself. |
| `pm-prd-review` | Reviews the PRD on seven dimensions (PASS / CONCERNS / FAIL, quoted evidence), gives an APPROVED / NEEDS_ATTENTION / REJECTED verdict, saves a report, and triages findings one by one: approved fixes edit `prd.md` (diff shown first); may set `status: reviewed`, never `locked`. |
| `pm-metrics` | Derives a north-star metric (you pick from 2-3 candidates), input metrics, a mapping of every PRD success criterion to a metric (target, baseline, window, owner), guardrail metrics and an event tracking plan from the PRD; writes `metrics.md`. Never invents targets or baselines: gaps are marked `TBD — Owner: <role>` and listed as open questions. |
| `pm-prioritize` | Scores every roadmap item that is not done (without a roadmap: the PRD's requirements) with RICE (recommended), ICE or MoSCoW from numbers you give; scoring is computed with `python3`, never guessed. Reports dependency conflicts ("A needs B first"), proposes a sequence you can use for a `/sdd-roadmap` re-run or a hand-edit of the roadmap, and writes `prioritization.md`. Never edits `roadmap.md`. |

## Ownership

The PM skills never take over artifacts owned by `sdd-skills`. Each artifact under
`$CONTEXT_ROOT/` has one sole writer:

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

## Install for Cursor

Cursor has native [Skills](https://cursor.com/docs/skills) that use the **same
`SKILL.md` format** as Claude Code, so there is no conversion — copy the skill
folders into a Cursor skills directory (`.cursor/skills/` per project or
`~/.cursor/skills/` globally). Copy the whole `pm-*` folders so each keeps its
`references/` subfolder and the `../pm-help/references/…` links still resolve.
The PM skills also need the `sdd-*` skills from **sdd-skills** installed alongside them.

```
mkdir -p ~/.cursor/skills
cp -R /path/to/sdd-pm-toolkit/skills/pm-* ~/.cursor/skills/
```

## Validate

```
bash scripts/validate-structure.sh
```
