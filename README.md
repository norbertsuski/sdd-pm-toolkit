# sdd-pm-toolkit

Personal Claude Code marketplace of product-manager skills: the whole product flow from idea to stakeholder status.

Ships one plugin: **sdd-pm-skills** (15 `pm-*` skills). It is self-contained: nothing else has to be installed.

## Install

```
/plugin marketplace add https://github.com/norbertsuski/sdd-pm-toolkit.git
/plugin install sdd-pm-skills@sdd-pm-toolkit
```

## Update

```
# after pushing changes (and bumping "version" in .claude-plugin/plugin.json)
/plugin marketplace update
/plugin update
```

## Local testing (no install)

Run Claude Code in any project with this repo as the plugin dir:

```
claude --plugin-dir /path/to/sdd-pm-toolkit
```

## Skills
| Skill | Purpose |
|---|---|
| `pm-help` | Map of the PM flow and a "you are here" report for a project. Read-only. |
| `pm-init` | Scaffolds the `context/` root: a flat-layout `README.md`, `.sdd.yml` (`layout: flat`), and the per-person, git-ignored `.sdd.local.yml` that remembers whether you want plain language or the technical view. Idempotent: re-running changes nothing that exists. Optional target folder (`/pm-init frontend/posting`). |
| `pm-research-synthesis` | Turns interview transcripts, notes and survey exports into evidence-linked insights (verbatim quotes, pseudonymized) with a seed for shaping. |
| `pm-discover` | The discovery router: derives the project's stage from files on disk and walks the PM, one human-gated step at a time, through `/pm-init`, `/pm-frame`, `/pm-shape`, `/pm-prd`, `/pm-prd-review`, the technology choice a developer makes and `/pm-roadmap`. Writes nothing itself. |
| `pm-frame` | Challenges the framing before anything is shaped or planned: separates what is observed from the stated cause and the proposed fix, maps where the problem could really originate, investigates each candidate with parallel read-only agents, and writes a Frame Brief (`frame-<date>-<topic>.md`) that may conclude the original framing was right. Never writes a plan and never touches a developer's `changes/` folders; hands a large reframed problem to `/pm-shape` and a small one to a developer. |
| `pm-shape` | Facilitates the discovery conversation that turns an idea (new product or a change to an existing one) into `shape-notes.md`: one question at a time, never inventing content, resumable from a checkpoint, plain language by default. Detects whether the product is new or existing on its own, keeps stack and tooling choices out, and ends with a closing quality cross-check that warns but never blocks. |
| `pm-prd` | Turns `shape-notes.md` (or pasted raw notes) into a schema-conformant `prd.md` (10 sections for a new product, 11 for a change to an existing one). Never invents content: every gap lands in Open Questions. Warns when the input is thin, asks which project raw notes belong to, recommends overwriting `prd.md` on a collision (the old version stays in git history; a `prd-vN.md` copy is possible, and it then offers to replace `prd.md` because the later steps read `prd.md` only), and points to `/pm-prd-review` next. |
| `pm-prd-review` | Reviews the PRD on seven dimensions (PASS / CONCERNS / FAIL, quoted evidence), gives an APPROVED / NEEDS_ATTENTION / REJECTED verdict, saves a report, and triages findings one by one: approved fixes edit `prd.md` (diff shown first); may set `status: reviewed`, never `locked`. |
| `pm-metrics` | Derives a north-star metric (you pick from 2-3 candidates), input metrics, a mapping of every PRD success criterion to a metric (target, baseline, window, owner), guardrail metrics and an event tracking plan from the PRD; writes `metrics.md`. Never invents targets or baselines: gaps are marked `TBD — Owner: <role>` and listed as open questions. |
| `pm-roadmap` | Turns the PRD into `roadmap.md`: ordered vertical slices (plus the foundations that unblock them) with prerequisites, parallel tracks, blockers and unknowns, a Backlog Handoff table and a recommended next move. Probes the codebase baseline with parallel read-only agents, asks at most three anchor questions with a grounded recommendation each, and aborts on a self-review failure (an uncovered must-have, a dependency cycle) instead of writing a bad file. No estimates or dates; archives the previous roadmap instead of overwriting. |
| `pm-map` | Draws the roadmap as a Mermaid dependency graph (`roadmap-map.md`): slices as nodes, prerequisites as edges, coloured done / ready / blocked, north-star slice marked. A bundled script does the drawing, so the same roadmap always gives the same picture; never edits `roadmap.md`. An optional hook can keep the map fresh. |
| `pm-prioritize` | Scores every roadmap item that is not done (without a roadmap: the PRD's requirements) with RICE (recommended), ICE or MoSCoW from numbers you give; scoring is computed with `python3`, never guessed. Reports dependency conflicts ("A needs B first"), proposes a sequence you can use for a `/pm-roadmap` re-run or a hand-edit of the roadmap, and writes `prioritization.md`. Never edits `roadmap.md`. |
| `pm-backlog-sync` | Copies the roadmap's Backlog Handoff into Jira or Linear through whatever tracker connection the host has, safely and repeatably: one issue per item (slice = Story, foundation = Task or a `foundation` label), title from the roadmap, description with outcome, PRD refs and the acceptance criteria of the linked user stories, label `sdd:<change-id>`, "is blocked by" links for prerequisites. Remembers which item became which issue in `tracker-map.md` (never in `roadmap.md`), so a re-run creates only what is new, updates only what changed and asks before anything unusual. Never deletes issues; roadmap items that vanished are reported as orphans. Every write waits for an explicit `Apply`. Without a tracker connection it writes a Jira CSV import file or a Markdown checklist and says no issues were created. |
| `pm-forecast` | Answers "when will we be done?" with three dates (likely / very likely / almost certain), never one: a bundled stdlib `python3` script replays the weekly throughput of archived changes against the items left on the roadmap (Monte Carlo), checks the PRD's hard deadline, and writes `forecast.md`. With too little history it gives no dates and says what is needed. Never edits `roadmap.md`, which stays estimate-free. |
| `pm-status` | Writes the stakeholder status report `status/<date>.md`: per-item state (done / in-progress / blocked / next) derived from the roadmap, `changes/` and `archive/`, a red / amber / green verdict from a fixed rule (never by feel), what changed since the previous report, risks, decisions needed, next up, and the saved forecast when it is at most 7 days old. Offers to publish a Confluence or Notion page (created once, then updated); Slack and email are drafts, and nothing is posted or sent without a yes that names the channel or recipients. Without a connection it saves paste-ready files. A reporting view: the developers' own state tracking stays authoritative. |

## Typical PM flow

Start anywhere; `/pm-help` shows the map and, given a project name, where that project stands.

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

1. `/pm-help` for the map. `/pm-init` once per repository sets up the project folder. Optional: `/pm-research-synthesis @interviews/*.md <topic>` first.
2. `/pm-discover "<idea>"` walks frame (when needed), shape and PRD, one confirmed step at a time. Then `/pm-prd-review`, then `/pm-metrics`.
3. `/pm-roadmap` turns the PRD into ordered slices (after the technology choice a developer makes, when there is one); `/pm-map` draws them as a graph.
4. `/pm-prioritize`, `/pm-backlog-sync` and `/pm-forecast` work from the roadmap; `/pm-status` writes the stakeholder report.
5. The build side (planning, implementing, reviewing and archiving each change) is a developer's workflow, outside this plugin. Steps 4 and 5 repeat as the project moves.

## Ownership

Each artifact under `$CONTEXT_ROOT/` has one sole writer, and the PM skills never write the developers'
change and archive folders:

| Artifact (under `$CONTEXT_ROOT/`) | Sole writer | PM toolkit access |
|---|---|---|
| `.sdd.yml`, `README.md` | `pm-init` | write (`pm-init`); read elsewhere |
| `.sdd.local.yml` (`audience:`) | `pm-init` and any audience-aware skill | read; write `audience:` only, same protocol as the plain-language reference |
| `foundation/<slug>/shape-notes.md` | `pm-shape` | write (`pm-shape`); read elsewhere |
| `foundation/<slug>/prd.md` | `pm-prd` (+ review skills flip `status`) | write (`pm-prd`); `pm-prd-review` edits with per-finding approval, may set `status: reviewed` |
| `foundation/<slug>/roadmap.md` | `pm-roadmap` (a developer's archive step sets items `done` and appends `## Done`) | write (`pm-roadmap`); read elsewhere |
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

## Integrations

Markdown under `$CONTEXT_ROOT/` is the source of truth; trackers, doc tools and chat are one-way projections.
The full protocol is in [`skills/pm-help/references/integrations.md`](skills/pm-help/references/integrations.md).

- **Adapters** are detected by the tool names the host exposes (case-insensitive substring): `jira`, `linear`
  (tracker); `confluence`, `notion` (docs); `slack` (chat); `gmail` / `outlook` (email drafts). Nothing is assumed.
- **`pm-config.yml`** (`foundation/<slug>/pm-config.yml`) remembers the choice per project (`tracker`,
  `tracker_project`, `docs`, `docs_location`, `channel`, `channel_target`, `status_page`), written only after you confirm it.
  No tokens or credentials are ever stored.
- **Write protocol** for every external write: preview (what, where, how many) → `Apply` / `Export file instead` /
  `Cancel` → sequential writes that stop on the first error and keep partial progress → report of keys and URLs.
  Nothing is ever deleted in a tracker.
- **Messages are drafts first.** Slack and email text is shown (or saved) as a draft; posting or sending needs a
  separate yes that names the channel or recipients.
- **No connection?** The skills write paste-ready files to `foundation/<slug>/exports/<date>-<what>.<ext>` (Jira CSV,
  Markdown page, message text) and say plainly that nothing was created or sent.

## Compatibility with SDD development workflows

The artifacts the PM skills write (`prd.md`, `roadmap.md`, `shape-notes.md`, the `context/` root) use the file
formats that developers' SDD tooling reads, so a roadmap written here can be planned and built by a developer
without conversion, and the developers' `changes/` and `archive/` folders can be read back by the PM skills. Only
formats are shared: nothing here calls into, or needs, any other plugin. The formats the PM skills rely on (PRD and
roadmap headings, frontmatter keys, change and archive keys, folder layout) are restated as data in
[`skills/pm-help/references/artifact-contract.md`](skills/pm-help/references/artifact-contract.md). Every skill that
reads `prd.md` or `roadmap.md` checks the required headings first and stops on a mismatch instead of guessing.

Six skills (`pm-init`, `pm-frame`, `pm-shape`, `pm-prd`, `pm-roadmap`, `pm-map`) were adapted from an upstream skills
repository; [`VENDORED.md`](VENDORED.md) records which files, at which commit, and what was changed. To see what
changed upstream since then, and whether the contract strings still exist there (manual, read-only):

```
bash scripts/check-upstream.sh /path/to/source-checkout
```

It prints `drift: <string>` for every contract string the checkout no longer contains and `changed upstream: <file>`
for every vendored source file that differs since the recorded commit (exit 0 = clean, 1 = drift or changes).

## Install for Cursor

Cursor has native [Skills](https://cursor.com/docs/skills) that use the **same
`SKILL.md` format** as Claude Code, so there is no conversion — copy the skill
folders into a Cursor skills directory (`.cursor/skills/` per project or
`~/.cursor/skills/` globally). Copy the whole `skills/pm-*` folders and nothing else, so each keeps its
`references/` subfolder and the `../pm-help/references/…` links still resolve.
No other plugin or skill is needed.

```
mkdir -p ~/.cursor/skills
cp -R /path/to/sdd-pm-toolkit/skills/pm-* ~/.cursor/skills/
```

## Validate

```
bash scripts/validate-structure.sh
bash scripts/validate-pm-evals.sh
python3 -m unittest discover -s tests -v
bash scripts/check-upstream.sh /path/to/source-checkout   # manual upstream check
```

The skills themselves are checked by hand with [`docs/smoke-test.md`](docs/smoke-test.md): a manual end-to-end
checklist on the bundled fixture, plus the live-integration checks that cannot run offline.
