---
name: pm-forecast
description: >
  Answer "when will we be done?" with a range of dates, never a single date. Replays how many changes the team really finished
  per week (read from archive/*/change.md) against the items still left on the roadmap, thousands of times, with the bundled
  python3 script scripts/forecast.py; reports a likely date, a very likely date and an almost certain date, checks them against
  the PRD's hard deadline, and writes foundation/<slug>/forecast.md. With too little history it says so and gives no dates.
  roadmap.md stays estimate-free: this skill never edits it. Use after some work has been archived, or when a deadline is in
  doubt. Trigger phrases: "forecast", "when will we be done", "when will it ship", "will we make the deadline", "delivery date",
  "how long is left", "release date estimate", "Monte Carlo", "prognoza", "kiedy skończymy", "kiedy będzie gotowe",
  "czy zdążymy na termin", "ile jeszcze zostało", "prognoza dostawy", "przewidywany termin".
---

# /pm-forecast — When Will We Be Done?

Turns the pace the team has really kept into a range of dates. It does not ask anyone to estimate anything: it counts what was
finished each week, counts what is left on the roadmap, and replays the past weeks at random until the remaining items are done,
2000 times. The answer is a range ("likely by …, very likely by …, almost certain by …"), because a single date would claim a
precision the data does not have. A bundled script does the arithmetic; this skill explains the result in plain words, checks it
against the deadline and saves it. The roadmap itself is never touched: **roadmap.md stays estimate-free.**

## When to use, when to skip

**Use when** some changes have been finished and archived (`archive/` holds them) and the roadmap still has items that are not
`done`, and the person wants a date, a range, or to know whether a deadline is at risk.

**Skip when** nothing has been archived yet (say so, and that the forecast needs history; point at `/pm-status` for the current
picture), when the question is which item to do first (`/pm-prioritize`), or when the person wants a date for one single item (the
method forecasts all the items left together, not one of them).

## Relationship to other skills

- `/pm-roadmap` — owns `roadmap.md`; this skill reads the `## At a glance` table and never edits the file.
- A developer's archive step — stamps `archived_at` on a finished change; that date is this skill's only source of history. Changes archived
  without a date are not counted (reported as skipped).
- `/pm-prioritize` — what to cut or reorder when the forecast says a deadline is at risk. Its effort numbers are scoring inputs and
  are not used here.
- `/pm-status` — shows the current state; it may quote the saved forecast but does not recompute it.
- `/pm-help` — the map of the PM flow.

Shared rules, linked rather than restated: finding the root and the project — `../pm-help/references/context-resolution.md`; the
contract check and the roadmap headings — `../pm-help/references/artifact-contract.md`; audience and plain language —
`../pm-help/references/plain-language.md`; where `forecast.md` sits among the PM artifacts — `../pm-help/references/pm-artifacts.md`;
the file layout, caveats and Deadline Check wording — `references/forecast-format.md`; behavior fixtures —
`references/eval-cases.md`; the script and its tests — `scripts/forecast.py`, `tests/test_forecast.py` in the repository.

## Initial Response

1. **A project name** → use it.
2. **Nothing given** → resolve the project (Step 1).
3. **A request to put dates into the roadmap** ("add these dates to roadmap.md", "write the forecast next to each slice") → decline in
   one sentence: the roadmap belongs to `/pm-roadmap`, stays estimate-free, and dates live only in `forecast.md`; offer to
   continue with the forecast.
4. **A request for the date of one item** → say the method gives one range for everything left, not a date per item, and offer that.

Say what is about to happen in a sentence or two, for example: "I'll look at how many changes you finished each week, count what is
left on the build plan, and work out a range of dates. I won't ask you for any estimates."

## Process

### Step 1 — Audience, root and project

1. Resolve the audience per `../pm-help/references/plain-language.md` (ask once if `audience:` is absent). Plain mode: say "how many
   things you finished each week" (not throughput), "the build plan" (roadmap), "likely / very likely / almost certain" (never p50,
   p85, p95), "replayed your past weeks thousands of times" (never Monte Carlo, seed, runs), "the product write-up" (PRD). Keep the
   file path for the file only. The saved file is identical in both modes.
2. Resolve `CONTEXT_ROOT` and the project per `../pm-help/references/context-resolution.md`. No root, or no project folder with a
   `roadmap.md` → say so, point at `/pm-discover`, STOP. Several projects → ask which; a named one wins. The slug is used as a
   command argument below, so it must be exactly the folder name (lowercase letters, digits, hyphens); anything else → ask again.

### Step 2 — Contract check (STOP on mismatch)

Run the `## Contract check procedure` in `../pm-help/references/artifact-contract.md` with the `roadmap` heading list **before reading
anything else from `roadmap.md`**: test every heading for an exact whole-line match. Any missing → print one line and STOP: no
script run, no question, no file.

```
CONTRACT MISMATCH: roadmap.md missing ## At a glance
```

(names comma-separated). Plain mode says it in words (the build plan is missing sections my steps rely on; please re-run the planning
step) and keeps the exact line for the technical log. The PRD is read only for one frontmatter key (`hard_deadline`, listed in the
contract's PRD frontmatter block), so no PRD heading check is run; a missing PRD simply means no deadline.

### Step 3 — Run the script

Find the skill directory `<skill dir>` (the folder that holds this `SKILL.md`), robustly, in this order:

1. **The base directory the host reports.** When a skill is loaded the host prints `Base directory for this skill: <path>`; use that
   path. It is correct wherever the plugin was installed (plugin cache, `--plugin-dir`, a copied `~/.cursor/skills/`).
2. If no base directory was reported: `$CLAUDE_PLUGIN_ROOT/skills/pm-forecast` when `CLAUDE_PLUGIN_ROOT` is set.
3. Otherwise search: `find "$HOME/.claude/plugins" "$HOME/.cursor/skills" . -path '*/pm-forecast/scripts/forecast.py' -not -path '*/node_modules/*' 2>/dev/null | head -5`.
   One hit → use its folder two levels up. Several → ask which. None → say plainly that the forecast script cannot be found and STOP;
   never recompute the forecast by hand or "estimate" the dates in the head.

Before running, confirm `<skill dir>/scripts/forecast.py` exists. Get today with `date +%Y-%m-%d`, then run (all values quoted):

```bash
python3 "<skill dir>/scripts/forecast.py" --context-root "$CONTEXT_ROOT" --project "<slug>" --today "$(date +%Y-%m-%d)"
```

Defaults are 2000 runs and seed 42; do not change them unless the person asks (a re-run of an existing `forecast.md` reuses its `runs` and
`seed`, Step 7). The script only reads files, uses nothing but the Python standard library (3.9+), and prints one JSON object. Exit
code 2 with an `error:` line means the roadmap could not be read: if the message says the table needs `Change ID` and `Status`
columns, treat it as a contract mismatch (print `CONTRACT MISMATCH: roadmap.md At a glance table missing <columns>` and STOP); otherwise show the message and STOP. `python3` missing → say so and STOP.

JSON keys you rely on: `status` (`ok` | `insufficient-history`), `reason`, `remaining`, `remaining_ids`, `completions`, `skipped`,
`throughput`, `throughput_from`, `throughput_to`, `weeks` and `dates` (each `p50`, `p85`, `p95`; null when insufficient),
`hard_deadline`, `deadline_risk` (`none` | `p85-after-deadline` | `p50-after-deadline`), `runs`, `seed`, `today`. Every number you say
comes from this JSON; never adjust, round to a friendlier date or add a "buffer".

### Step 4 — Present the result

**`status: insufficient-history`** → no dates, not even a hint ("probably around …" is also a date). Say what is missing in words,
from `reason`: the forecast needs at least 3 finished changes archived with a date, spread over at least 3 complete calendar weeks,
with something finished in them; say how many there are now (`completions`) and that a developer's archive step stamps the date. If `skipped` >
0, say that many archive entries had no usable date and were not counted. Offer to save a `forecast.md` that records this (Step 6) or to
stop.

**`status: ok`** → say, in this order:

1. How many items are left (`remaining`), and that blocked ones are counted as left.
2. The three dates as one sentence, plain wording: "Likely by 2026-11-03, very likely by 2026-11-10, almost certain by 2026-11-10." Add
   what each means once: likely is about a one in two chance, very likely about 17 in 20, almost certain about 19 in 20. **Never
   reduce this to a single date**, even when asked for "just one" ("the date to plan around" is the very likely one; give it with the
   other two). If two dates are equal, still say all three. A date more than 10 years away (520 weeks) is reported as "more than 10
   years away at this pace".
3. What it is built on: the weekly counts (`throughput`, from `throughput_from` to `throughput_to`), in one line.
4. The caveats in one or two sentences (the five in `references/forecast-format.md`): it extrapolates the past pace, ignores how big
   items are, what depends on what and how many people work in parallel, counts blocked items as ordinary work, and uses the pace of
   everything archived in the context root, not only this project (plain mode: "it uses how fast the whole team has finished things,
   not only this product").

### Step 5 — Deadline check

`hard_deadline` is null → say no deadline is set in the product write-up (so nothing to check). Otherwise use the wording table in
`references/forecast-format.md` for `deadline_risk`:

- `none` → Green (or "Green, thin margin" when the almost certain date is after the deadline).
- `p85-after-deadline` → Amber: the likely date meets the deadline, the very likely date does not.
- `p50-after-deadline` → Red: even the likely date is after the deadline; state by about how many weeks.

For Amber and Red, name the options as the person's decisions, never as something done: cut or reorder scope (`/pm-prioritize` helps
choose what), move the deadline, add capacity. Do not recommend one as correct, edit the PRD or touch the roadmap. For
`insufficient-history` the check is "not checked".

### Step 6 — Write `forecast.md`

Path `$CONTEXT_ROOT/foundation/<slug>/forecast.md`, layout, frontmatter and headings exactly as in `references/forecast-format.md`
(`project`, `created`, `updated`, `method: monte-carlo-throughput`, `runs`, `seed`, `deadline_risk` = the script's value unchanged,
which `/pm-status` reads; `## Forecast`, `## Inputs`, `## Assumptions & Caveats`, `## Deadline Check`). Dates in the file from the script's JSON and `date +%Y-%m-%d`. The four headings
and the caveats are written in every case, including `insufficient-history` (no dates there).

Preview the whole file first and ask: `1. Write forecast.md (Recommended)  2. Change something  3. Don't write`. Nothing is written
before an answer.

- **No file yet** → write it; `created` and `updated` are today.
- **File exists** → show a short summary of the difference (old dates against new, `runs`/`seed`, deadline verdict) and ask
  `1. Overwrite (keeps its created date)  2. Cancel, change nothing`. Never overwrite silently. A forecast is derived data and git keeps the
  old one.

Afterwards read the file back and confirm the frontmatter keys and the four headings exist; then print the path (technical mode) or say
it is saved (plain mode).

### Step 7 — Re-runs

"Run it again" with an existing `forecast.md` → run the script with that file's `runs` and `seed` and today's date. Same data on the same
day gives identical output (the simulation is seeded); say "nothing changed" instead of re-presenting. New archived changes or a new day
shift the dates, which is the point. A different seed or run count requested by the person is allowed; say small shifts in the dates are
simulation noise and record the new values in the file.

### Step 8 — Handoff

Plain mode ends with the handoff block from `../pm-help/references/plain-language.md`: what was found (the three dates or why there are
none, the deadline verdict), and the next step in product terms: "set up the tracker" (`/pm-backlog-sync`) or "see where everything
stands" (`/pm-status`); after an Amber or Red verdict, "decide what to cut or reorder" (`/pm-prioritize`). Technical mode prints the path,
the status, the three dates and the exact next command. Confirm a skill is in the host's available list before naming it. Do not start the
next skill.

## Output

One file: `$CONTEXT_ROOT/foundation/<slug>/forecast.md`; frontmatter `project`, `created`, `updated`, `method`, `runs`, `seed`, `deadline_risk`; sections
`## Forecast`, `## Inputs`, `## Assumptions & Caveats`, `## Deadline Check`. Format and wording: `references/forecast-format.md`. Besides
this file the skill may write `audience:` to `.sdd.local.yml` (plain-language rule) and nothing else. The script writes nothing.

## Critical guardrails

Never writes `prd.md`, `shape-notes.md`, or `roadmap.md`.

1. **roadmap.md stays estimate-free.** No dates, durations, sizes or estimates are ever written into the roadmap; a request to do so is
   declined and the dates stay in `forecast.md`. The same applies to the PRD and to `changes/**` and `archive/**`, which are read only.
2. **Never a single date.** Always the three named dates (likely / very likely / almost certain), including when the person asks for "one
   date". Never a date per item.
3. **No dates without history.** `insufficient-history` means no date, no hint, no "rough guess"; the explanation of what is needed
   replaces it. Never invent, borrow or assume history (no industry averages, no velocity from memory).
4. **The script is the only source of numbers.** Never compute, adjust, round or "sanity-correct" dates or weeks mentally; if the script
   cannot be found or run, say so and STOP.
5. **Caveats always written.** Throughput-based, ignores dependency depth and parallelism, blocked items counted as remaining, team pace
   (every archived change in the context root, not only this project's; pooled across projects), a range not a promise: in the chat summary and in the file, also when there are no dates.
6. **Contract first.** A missing roadmap heading → one `CONTRACT MISMATCH` line and STOP, before running the script.
7. **No silent overwrite.** An existing `forecast.md` triggers the summary of differences and the Overwrite / Cancel question; a write needs
   a yes to the preview.
8. **Deadline decisions stay with the person.** Amber and Red list options; the skill never changes the deadline, the scope or the plan.

## Notes

- **Where the history comes from.** Every `archive/*/change.md` in the context root with a usable `archived_at` counts as one finished
  change in the week it was archived (the archive step writes an ISO datetime such as `2026-09-29T15:10:00Z`; only the date part is read). Weeks run
  Monday to Sunday; the current week is not counted; at most the last 12 complete weeks are used; weeks with nothing finished count as
  zero. The archive is not filtered by project, so with several projects in one context root the pace is the pooled pace.
- **How it is simulated.** For each of 2000 runs, a random past week's count is added week after week until the remaining items are
  covered (at most 520 weeks); the 50th, 85th and 95th percentile of those runs are the likely, very likely and almost certain
  numbers of weeks, added to today's date as `today + 7 × weeks`. The seed (42) makes the result repeatable.
- **Python.** Standard library only, Python 3.9 or newer. Tests: `python3 -m unittest discover -s tests -v` from the repository root (CI runs them).
- **Nothing is installed or fetched** and no external system is written, so the integrations protocol does not apply.
