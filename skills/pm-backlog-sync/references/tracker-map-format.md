# tracker-map.md format, issue mapping and sync rules

`$CONTEXT_ROOT/foundation/<slug>/tracker-map.md` is the only place that remembers which roadmap item became which
tracker issue. Issue keys are never written into `roadmap.md` (it belongs to `/sdd-roadmap`). The file is written by
`pm-backlog-sync` only; a person may edit it by hand to repair a mapping (for example after a relink).

## Frontmatter

```yaml
---
project: <project name, as in the roadmap frontmatter>
tracker: jira | linear
tracker_project: <Jira project key | Linear team key>
epic: <issue key of the epic / parent issue, or —>
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

`project`, `tracker`, `tracker_project`, `epic`, `updated` are the load-bearing keys; `created` is kept for the common
PM-artifact convention. `epic: —` means "asked, answer was no epic"; an absent file means "not asked yet". `tracker` and
`tracker_project` mirror `pm-config.yml` and must agree with it; on a disagreement, ask the PM which one is right.

## Mapping table

One row per roadmap item that has an issue. Heading `## Issues`, then exactly this header:

| Roadmap ID | Change ID | Issue key | Issue URL | Synced title | Synced hash | Synced at |
|---|---|---|---|---|---|---|
| S-02 | recipe-match | KAN-2 | https://example.atlassian.net/browse/KAN-2 | Rank recipes by fridge match | 3fa91c0d77ab | 2026-10-20 |

- `Roadmap ID` + `Change ID`: the key pair from the roadmap's `## Backlog Handoff` table. `Change ID` is the join key.
- `Issue key`: as the tracker reports it (`KAN-2`, `ENG-14`). `Issue URL`: the tracker's link, if it returned one, else `—`.
- `Synced title`: the title last written to the issue (the roadmap's `Suggested issue title`).
- `Synced hash`: the first 12 hex characters of the sha256 of the **rendered description** (see below) last written to the
  issue. It is what makes `changed` detectable without comparing tracker-side text, which the tracker may reformat.
  Compute it with the command in `SKILL.md` Step 4 (a `python3 -c` one-liner that reads a file); it applies the normalization
  of `## Canonical rendering` itself, so the hash is a function of the content, never of line endings, trailing spaces or how many
  blank lines the model happened to emit. The file path is the only thing put on the command line.
- `Synced at`: `YYYY-MM-DD` from `date +%Y-%m-%d`.
- A row is appended **immediately** after its create succeeds (not at the end of the run), so a partly failed run is resumable.

## Orphans

Heading `## Orphans`, after the mapping table, same header as the table above plus a final column `Orphaned on`
(`YYYY-MM-DD`). A row lives here when its `Change ID` no longer exists in the roadmap's `## Backlog Handoff` table. Orphan
rows are kept: the tracker issue is never closed, renamed or deleted by this skill, and the row stays until the PM removes it
by hand or relinks it. A Change ID that comes back to the roadmap while its row is here is offered a relink to that key, never a new
issue. Existing orphan rows are shown in every run's preview and report. With no orphans the section holds the line `None.`

## Issue mapping

| Roadmap item | Jira | Linear |
|---|---|---|
| `S-NN` (slice) | issue type `Story` | issue (no type) |
| `F-NN` (foundation) | issue type `Task` | issue with label `foundation` |
| title | the roadmap's `Suggested issue title`, verbatim | same |
| labels | `sdd:<change-id>` | `sdd:<change-id>` (plus `foundation` for `F-NN`) |
| epic (optional, asked once) | an `Epic` issue named after the project; items get it as their parent | a parent issue named after the project; items are created as its sub-issues |
| Prerequisites | `is blocked by` link to the issue of each prerequisite `F-NN` / `S-NN`, once both exist | same relation ("blocked by") |
| roadmap `done` | offer to move the issue to the tracker's done state (ask; never automatic) | same |

Prerequisites cells may mix roadmap IDs with free text (`S-02, ingredient unit convention agreed`). Only tokens matching
`F-NN` or `S-NN` become links; free text is listed in the report as "not linked" and is never invented into an issue.
The label `sdd:<change-id>` is how an issue found in the tracker is tied back to a roadmap item; do not drop it on update.

## Description template

The rendered description is plain text with these parts in this order (Markdown allowed; the PM's tracker renders it):

```
Outcome: <Outcome field of the item's roadmap section, verbatim>

PRD refs: <PRD refs field, verbatim>

Acceptance criteria:
<for each US-NN named in PRD refs, in order>
From US-NN (<story title>):
- Given <...>
- When <...>
- Then <...>
- <each bullet under "#### Acceptance Criteria" of that story, if the PRD has them>
<if no US-NN is named, or none is found in prd.md>
None linked: the PRD refs name no user story.   |   US-NN is named in the roadmap but not found in prd.md.

Change ID: <change-id>
Roadmap: <path of roadmap.md relative to the repository root> (<Roadmap ID>)
```

Given / When / Then lines are copied from the `### US-NN:` block's `- **Given**`, `- **When**`, `- **Then**` bullets, with the
bold markers removed. Nothing is paraphrased or invented. Prerequisites, status and risk are deliberately **not** in the
description: they change without the work changing, and would make every run look like an update. Prerequisites become links;
status becomes the transition offer.

## Canonical rendering

The hash must be stable across runs, so the description is rendered the same way every time:

1. Use the template above verbatim: the same labels (`Outcome:`, `PRD refs:`, `Acceptance criteria:`, `From US-NN (<title>):`,
   `Change ID:`, `Roadmap:`), the same order, one `- ` bullet per line, user stories in the order the PRD refs list them, Given /
   When / Then first and then the story's acceptance bullets in the PRD's order, one blank line between parts.
2. Copy field text from the roadmap and PRD as is (after removing the `**` around Given / When / Then); do not reword, reflow, re-wrap
   or "tidy" it.
3. The hash command normalizes before hashing: CRLF and CR become LF, trailing whitespace is stripped from every line, runs of blank
   lines collapse to one, leading and trailing blank lines are dropped, and the text ends with exactly one final newline. So two
   renderings that differ only in those ways hash the same, and the "trailing newline" question has one answer: the normalized text
   always ends with exactly one `\n`, whatever the file did.
4. Text content differences (a word, a bullet, an order change) change the hash on purpose: that is an `update`.

## Sync decision table

`sync_action <in_roadmap> <in_map> <tracker_exists> <changed>` (reference function and asserts:
`scripts/validate-pm-evals.sh`). `changed` is yes when the roadmap title differs from `Synced title` or the hash of the
newly rendered description differs from `Synced hash`.

| in_roadmap | in_map | tracker_exists | changed | Action | What it means |
|---|---|---|---|---|---|
| yes | no | — | — | `create` | New roadmap item; make an issue, append the map row |
| yes | yes | yes | no | `skip` | Already synced and unchanged |
| yes | yes | yes | yes | `update` | Title or description changed; update the issue, refresh the map row |
| yes | yes | no | — | `relink-ask` | The mapped issue is gone; ask, never recreate on its own |
| no | yes | — | — | `orphan` | Roadmap no longer has this Change ID; move the row to `## Orphans`, leave the issue alone |
| no | no | — | — | `none` | Not applicable |

A `create` whose Change ID matches a row in `## Orphans` is not created: it becomes `relink-ask` toward that row's key (SKILL.md
Step 6, orphan guards). The table above is the pure function; the guards run around it.

`tracker_exists` comes from fetching the mapped issue by key. A fetch that fails for any reason other than "not found"
(permissions, network, tool error) is **not** `tracker_exists=no`: stop and report it, never treat it as a deleted issue.
