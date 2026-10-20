# status report format

`$CONTEXT_ROOT/foundation/<slug>/status/<YYYY-MM-DD>.md`, written by `pm-status` and nobody else; one file per day, earlier files are
never edited. Dates are `YYYY-MM-DD`. The file is the same in plain and technical mode, and it is written for stakeholders (people who
do not read the roadmap): outcomes in the roadmap's own words, no frontmatter talk, no commands except the one suggestion in `## Forecast`.
Everything in it is derived from files; nothing is typed in by hand and nothing is estimated.

## Frontmatter

```yaml
---
project: Recipe Fridge
created: 2026-10-20
updated: 2026-10-20
rag: green | amber | red
---
```

`project` is the `project` value of the roadmap's frontmatter. `rag` is exactly one of the three words, lower case, from the rule in
`SKILL.md` Step 5. `created` is kept when the same day's file is overwritten; `updated` is today.

## Complete example (fixture, today 2026-10-20, no forecast, no tracker map)

~~~~markdown
---
project: Recipe Fridge
created: 2026-10-20
updated: 2026-10-20
rag: amber
---

# Status: Recipe Fridge, 2026-10-20

## Summary

**Amber — needs attention:** 1 item is waiting on a decision (S-06 share-recipe).

4 of 7 items done; 1 in progress; 1 waiting on a decision; 1 not started.
Hard deadline (PRD): 2026-12-15.
RAG inputs: north_star_blocked=no, needs_triage=no, blocking_unknown=yes, deadline_risk=none

## Progress

| ID | Change ID | Outcome | State | Note | Ticket |
|---|---|---|---|---|---|
| F-01 | auth-scaffold | (foundation) sign-in works and every user has a private account | done | archived 2026-09-29 | — |
| S-01 | fridge-inventory | user can add and remove items in their fridge | done | archived 2026-10-01 | — |
| S-02 | recipe-match | user can see recipes ranked by how much of their fridge each uses | done | north star; archived 2026-10-08 | — |
| S-03 | save-favorites | user can save a recipe to their favourites | done | archived 2026-10-14 | — |
| S-04 | shopping-list | user can get a shopping list of the ingredients a recipe still needs | proposed | — | — |
| S-05 | meal-plan | user can plan the week's meals from their favourites | in-progress | change status: implementing | — |
| S-06 | share-recipe | user can share a recipe, with its missing ingredients, with a household member | blocked | waiting on a decision | — |

## Since Last Update

First status report: there is nothing to compare with.

## Risks & Blockers

- S-06 share-recipe is waiting on a decision: does sharing happen by link or by invitation inside the product? Owner: product.

## Decisions Needed

- Does sharing happen by link or by invitation inside the product? Owner: product. Blocks: S-06 share-recipe.
- Which units do quantities use (metric, imperial, both)? Owner: product. Not blocking yet.

## Next Up

- S-04 shopping-list: user can get a shopping list of the ingredients a recipe still needs. Also needs: ingredient unit convention agreed.

## Forecast

No current forecast. A forecast can be made with `/pm-forecast`.
Hard deadline (PRD): 2026-12-15.
~~~~

## Headings (in this order, all seven always present)

### `## Summary`

Four things, in this order, wording fixed so a re-run reads the same:

1. The verdict line: `**<Green|Amber|Red> — <on track|needs attention|off track>:** <reasons joined with "; ">.` Reasons are
   the ones whose RAG input fired, in this order (red reasons first, then amber), each from this table; green has the one reason below:

   | Input | Reason text |
   |---|---|
   | `north_star_blocked=yes` | `the first piece worth building (<ID> <change-id>) is blocked` |
   | `needs_triage=yes` | `<n> change(s) failed review and need a decision (<change-ids>)` |
   | `deadline_risk=p50-after-deadline` | `at the current pace the deadline <date> will probably be missed` |
   | `blocking_unknown=yes` | `<n> item(s) waiting on a decision (<ID> <change-id>, …)` |
   | `deadline_risk=p85-after-deadline` | `the deadline <date> is roughly a coin flip at the current pace` |
   | none (green) | `no item is blocked and no review needs a decision` |

   Green with a hard deadline but no usable forecast adds ` The deadline has not been checked against a forecast.` after the reason.
2. The counts line: `<d> of <t> items done; <p> in progress; <b> waiting on a decision; <n> not started.` (`done`, `in-progress`,
   `blocked`, and everything else, from the Progress table; `t` is the number of rows).
3. `Hard deadline (PRD): <date>.` or `No hard deadline is set in the PRD.`
4. The RAG basis, one line, exactly `RAG inputs: north_star_blocked=<yes|no>, needs_triage=<yes|no>, blocking_unknown=<yes|no>, deadline_risk=<none|p85-after-deadline|p50-after-deadline>`
   (no trailing period). `Since Last Update` reads it back from the previous file.

### `## Progress`

One table, every roadmap item (`F-NN` and `S-NN`) in roadmap order, header exactly:

```markdown
| ID | Change ID | Outcome | State | Note | Ticket |
|---|---|---|---|---|---|
```

- `Outcome` is the roadmap's `Outcome (user can …)` cell verbatim.
- `State` is the reporting state (`SKILL.md` Step 4): `done`, `in-progress`, `blocked`, or the roadmap's own Status
  (`proposed`, `ready`, `planning`). Nothing else, so the next report can compare states.
- `Note` is `—` or `;`-joined parts, in this order: `north star` (the item named in the roadmap's `## North star`); then one of
  `archived <date>` (first 10 characters of `archived_at`; `done on the roadmap` when there is no usable date),
  `change status: <status>`, `waiting on a decision`; then `needs triage: review <verdict>` when the item's change has negative
  evidence; `archived, but the roadmap is not closed` when an archive folder exists and the roadmap row is not `done`.
- `Ticket` is `[<issue key>](<issue url>)` from `tracker-map.md` (the key alone when its URL is `—`), else `—` (also when
  there is no `tracker-map.md`). Tracker status is not shown here; the tracker never changes a state.

### `## Since Last Update`

Compared with the newest earlier `status/*.md` (a file dated before today; today's own file, if it exists, is the one being overwritten).
Comparison reads the previous file's `rag`, its `RAG inputs:` line, its Progress table and its Forecast table.

- No earlier file: `First status report: there is nothing to compare with.`
- An earlier file whose Progress table or `RAG inputs:` line cannot be read: `The previous report (<date>) could not be compared.`
- Otherwise `Compared with <date>.` then bullets in this order, only the ones that apply:
  1. `- Overall: <old rag> → <new rag>` (when different)
  2. `- <ID> <change-id>: <old state> → <new state>` for every item in roadmap order whose State changed
  3. `- New on the roadmap: <ID> <change-id>` / `- No longer on the roadmap: <ID> <change-id>`
  4. `- <input>: <old> → <new>` for each RAG input that changed (the four names above)
  5. `- Forecast: likely <old date> → <new date>; very likely <old> → <new>; almost certain <old> → <new>` when both reports used a
     forecast (a changed line only); `- Forecast: now available` / `- Forecast: no longer used (<stale|absent>)` when only one did
- Nothing differs: `Nothing changed since <date>.`

### `## Risks & Blockers`

Bulleted, each line says what, since which item, and who owns the answer when known. In this order, only those that apply:

1. The north-star item is blocked (or waits on a blocked prerequisite): `- The first piece worth building (<ID> <change-id>) is blocked: <why>.`
2. Each blocked item: `- <ID> <change-id> is waiting on a decision: <the Unknown's question>. Owner: <owner>.`
3. Each change with negative evidence: `- <ID> <change-id> failed review (<verdict>) and has not been triaged.`
4. Each archive/roadmap mismatch: `- <ID> <change-id> was archived but the roadmap does not show it as done.`
5. A change whose verification could not be read: `- <ID> <change-id>: the review result could not be read, so its state may be out of date.`
6. The deadline verdict when `deadline_risk` is not `none`: the Amber or Red sentence copied from forecast.md's `## Deadline Check`.

None apply: `No known risks or blockers.`

### `## Decisions Needed`

Bulleted; every line is a decision a person must make, never something the skill decided:

1. Each Unknown of a not-done item, in roadmap order, de-duplicated by question text:
   `- <question> Owner: <owner>. Blocks: <ID> <change-id>.` for `Block: yes`, `... Not blocking yet.` for `Block: no`.
2. Each change with negative evidence: `- Decide what to do with the review of <change-id> (<verdict>). Owner: the developer.`
3. When `deadline_risk` is `p85-after-deadline` or `p50-after-deadline`: `- Decide how to protect the deadline <date>: cut scope (/pm-prioritize helps choose what), move the deadline, or add capacity.`

None apply: `No decisions are waiting.`

### `## Next Up`

At most 3 items, roadmap order: not `done`, not `in-progress`, not `blocked`, and every `F-NN` / `S-NN` in its Prerequisites is `done`.
Line: `- <ID> <change-id>: <outcome>.` plus ` Also needs: <free-text prerequisites>.` when the Prerequisites cell holds text that is not a roadmap ID.
Items already in progress are in Progress, not here. None qualify: `Nothing is ready to start; see Risks & Blockers.`
(When everything is done: `Everything on the roadmap is done.`)

### `## Forecast`

Uses `forecast.md` only when it is fresh (`SKILL.md` Step 6); the dates and sentences are copied, never recomputed. Exactly one of:

| Situation | Content |
|---|---|
| fresh, with dates | `Forecast of <updated date>.`, then the three-row table from forecast.md's `## Forecast` verbatim, then the block under forecast.md's `## Deadline Check` verbatim |
| fresh, `insufficient-history` | `No dates yet: <the reason sentence under forecast.md's ## Forecast>` |
| stale | `The saved forecast is <n> days old (dated <date>) and was not used. Run /pm-forecast to refresh it.` |
| fresh but no `deadline_risk` key | `The saved forecast (<date>) predates the deadline result and was not used. Run /pm-forecast to refresh it.` |
| unreadable date | `The saved forecast has no readable date and was not used. Run /pm-forecast to refresh it.` |
| none | `No current forecast. A forecast can be made with /pm-forecast.` (with backticks around the command) |

Then always one line: `Hard deadline (PRD): <date>.` or `No hard deadline is set in the PRD.`

## Message drafts (Slack, email)

Built from the saved file only (no new facts), shown as drafts; posting or sending is a separate step that needs a yes naming the
channel or recipients (`SKILL.md` Step 10). No emoji; the traffic light is a word.

Slack (mrkdwn):

```
*Recipe Fridge status, 2026-10-20: AMBER (needs attention)*
4 of 7 items done; 1 in progress; 1 waiting on a decision; 1 not started.
Since last update: first status report.
Risks: S-06 share-recipe is waiting on a decision (sharing by link or by invitation; owner: product).
Decisions needed: sharing by link or invitation (product); units for quantities (product, not blocking yet).
Next up: S-04 shopping-list.
Forecast: none yet. Hard deadline: 2026-12-15.
Full report: <page URL>
```

The last line appears only when a page exists. Each line is a one-line digest of the same-named section (the counts line and the
`Since Last Update` bullets joined with `; `; at most 3 risks and 3 decisions, then `and <n> more`).

Email: subject `Recipe Fridge status, 2026-10-20: AMBER`, the same lines as the body in plain text, greeting and sign-off left to the PM
(`Hi all,` is a placeholder the PM edits; no name is invented).

## Page body (Confluence, Notion)

Title `<project> — status` (constant, so later runs update the same page). Body = the file below the frontmatter, headings and tables
unchanged, passed in the format the tool accepts (Markdown when it takes it). Wording is never changed for the page.
