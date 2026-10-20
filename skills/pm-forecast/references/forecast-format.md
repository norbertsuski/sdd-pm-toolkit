# forecast.md format

`$CONTEXT_ROOT/foundation/<slug>/forecast.md`, written by `pm-forecast` and nobody else. Dates are `YYYY-MM-DD`.
The file is the same in plain and technical mode. Every number comes from the script's JSON; nothing is typed in
by hand and nothing is estimated by the person or by Claude. The word "forecast" here means a range of dates built
from how fast finished work actually shipped, never a promise and never a single date.

## Frontmatter

```yaml
---
project: recipe-fridge
created: 2026-10-20
updated: 2026-10-20
method: monte-carlo-throughput
runs: 2000
seed: 42
---
```

`created` is kept on an overwrite; `updated` is today. `runs` and `seed` are the values the script reported, so a
re-run with the same values on the same data reproduces the same dates.

## Complete example (fixture, today 2026-10-20)

~~~~markdown
---
project: recipe-fridge
created: 2026-10-20
updated: 2026-10-20
method: monte-carlo-throughput
runs: 2000
seed: 42
---

# Forecast: Recipe Fridge

## Forecast

| How sure | Date | Weeks from today |
|---|---|---|
| Likely (about 1 in 2) | 2026-11-03 | 2 |
| Very likely (about 17 in 20) | 2026-11-10 | 3 |
| Almost certain (about 19 in 20) | 2026-11-10 | 3 |

3 items are left. Likely by 2026-11-03, very likely by 2026-11-10, almost certain by 2026-11-10.

## Inputs

- Run date: 2026-10-20. Finished changes counted: 4 (archive entries skipped: none).
- Items left: 3 (`shopping-list`, `meal-plan`, `share-recipe`), every roadmap item whose Status is not `done`, blocked ones included.
- Finished per week, 2026-09-28 to 2026-10-18 (oldest first): 2, 1, 1.
- Method: `monte-carlo-throughput`, 2000 runs, seed 42.
- Hard deadline in the PRD: 2026-12-15.

## Assumptions & Caveats

1. Throughput-based: the forecast replays how many changes finished per week in the past; it does not look at how big the remaining items are.
2. It ignores dependency depth and parallelism: the order of items, what has to be finished first and how many people work at once are not modelled.
3. Blocked items are counted as remaining and treated as deliverable at the normal pace; if a block lasts, the real dates move later.
4. Team pace: history is every archived change in the context root, not only this project's; with several projects in one root the pace is pooled.
5. A forecast is a range, not a promise; three weeks of history is little, and a change in team size, scope or holidays breaks the assumption that the future looks like the past.

## Deadline Check

Green: even the almost certain date (2026-11-10) is on or before the deadline (2026-12-15).
~~~~

## Headings (in this order, all four always present)

### `## Forecast`

`status: ok` — three named dates, never one, as a table, then one plain sentence under it:

```markdown
| How sure | Date | Weeks from today |
|---|---|---|
| Likely (about 1 in 2) | 2026-11-03 | 2 |
| Very likely (about 17 in 20) | 2026-11-10 | 3 |
| Almost certain (about 19 in 20) | 2026-11-10 | 3 |

3 items are left. Likely by 2026-11-03, very likely by 2026-11-10, almost certain by 2026-11-10.
```

The three rows are the script's `p50`, `p85`, `p95`. Equal dates stay as three rows (do not merge them). If a date
is 520 weeks out the run hit the simulation cap: write "more than 10 years away at this pace" instead of a date and
say the pace is too slow to forecast.

`status: insufficient-history` — no dates, no table:

```markdown
No forecast yet: <the script's `reason`>. A forecast needs at least 3 finished changes that were archived
with a date, spread over at least 3 complete calendar weeks, with something finished in them. Archive each
finished change with `/sdd-archive` (it stamps the date), then run `/pm-forecast` again.
```

`items left: 0` with `ok` → "Nothing is left to deliver on the roadmap; the forecast is today."

### `## Inputs`

Facts the script used, so a reader can check them:

- Date of the run (`today`), the number of finished changes counted (`completions`) and how many archive entries were
  skipped for a missing or unreadable archive date (`skipped`; say "none" when 0).
- Items left (`remaining`) with their Change IDs (`remaining_ids`), taken from the roadmap's `## At a glance` table:
  every item whose Status is not `done`, **blocked items included**.
- Weekly throughput: the counts per calendar week (Mon–Sun), oldest first, from `throughput_from` to `throughput_to`
  (zero weeks included), for example `2, 1, 1` for the three weeks 2026-09-28 to 2026-10-18. Window: the last 12
  complete weeks at most; the current week is not counted.
- Method line: `monte-carlo-throughput`, `runs`, `seed`.
- Hard deadline from the PRD (`hard_deadline`), or "none set".

### `## Assumptions & Caveats`

Always present, also when there are no dates. Always these five, in the person's terms in the chat and in these
words in the file:

1. **Throughput-based.** The forecast replays how many changes finished per week in the past; it does not look at
   how big the remaining items are.
2. **It ignores dependency depth and parallelism.** The order of items, what has to be finished first and how many
   people work at once are not modelled; the past pace is assumed to continue.
3. **Blocked items counted as remaining.** Items waiting on a decision are included in the count and treated as
   deliverable at the normal pace; if a block lasts, the real dates move later.
4. **Team pace.** History is every archived change in the context root, not only this project's (archive entries carry no
   project id); with several projects in one root the pace is pooled.
5. **A forecast is a range, not a promise.** Few weeks of history make the range unreliable; a change in team size,
   scope or holidays breaks the assumption that the future looks like the past.

Add a sixth line when it applies: "N archive entries had no usable archive date and were not counted."

The file never contains a story-point, hour or day estimate for an item. `roadmap.md` stays estimate-free.

### `## Deadline Check`

One block, chosen by the script's `deadline_risk` and `hard_deadline` (wording is fixed so it reads the same every
time; fill in the dates and the difference in weeks, rounded up):

| Situation | Wording |
|---|---|
| no `hard_deadline` | `No hard deadline is set in the PRD, so there is nothing to check against.` |
| `insufficient-history` | `Not checked: there is not enough history yet to forecast a date to compare with <deadline>.` (no deadline: first row) |
| `none`, almost-certain date on or before the deadline | `Green: even the almost certain date (<p95>) is on or before the deadline (<deadline>).` |
| `none`, almost-certain date after the deadline | `Green, thin margin: the very likely date (<p85>) is on or before the deadline (<deadline>), but the almost certain date (<p95>) is after it.` |
| `p85-after-deadline` | `Amber: the likely date (<p50>) is on or before the deadline (<deadline>), but the very likely date (<p85>) is after it. At this pace hitting the deadline is roughly a coin flip, not a safe bet.` |
| `p50-after-deadline` | `Red: even the likely date (<p50>) is after the deadline (<deadline>), by about <n> weeks. At this pace the deadline will probably be missed.` |

After an Amber or Red block add one line of options, all of them decisions for the person: cut scope (`/pm-prioritize`
helps choose what), move the deadline, or add capacity. The skill does not change the plan, the PRD or the roadmap.
