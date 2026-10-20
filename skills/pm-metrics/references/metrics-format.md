# metrics.md format

The file `pm-metrics` writes: `$CONTEXT_ROOT/foundation/<slug>/metrics.md`. One file per project, updated in
place (see the collision rule in `SKILL.md` Step 9). The six `##` headings below are fixed, in this order, always
present (an empty section says `None.`), and the two table headers are fixed character for character:
`pm-prd-review` reads this file for its Measurability dimension, and `scripts/validate-structure.sh` checks both.
Headings and `TBD — Owner:` stay in English in every language; the text in cells follows the user's language,
except quotes from the PRD, which are copied as written.

## Frontmatter

```yaml
---
project: <project name, as in prd.md>
prd_version: <the PRD's version when this file was derived>
created: <YYYY-MM-DD>      # date +%Y-%m-%d; unchanged when the file is overwritten or merged
updated: <YYYY-MM-DD>      # date +%Y-%m-%d
---
```

Followed by a `# Metrics: <project name>` title line, then the six sections.

## Cell values

Every cell of `Target`, `Baseline`, `Window` and `Owner` holds exactly one of:

| Value | When |
|---|---|
| The PRD's own words or number, restated (`at least 60%`, `within one minute`, `0 (PRD: "never")`) | The PRD bullet states it. A statistic the bullet does not name (average, median, p95, max) is not added. |
| The person's value followed by `(PM)` | The person gave it in the conversation and the PRD does not say it. |
| `TBD — Owner: <role>` | Neither the PRD nor the person supplied it. `<role>` is who should supply it (default `product manager`; `analytics` for Baseline) or a name the person gave. Each one has an entry in `## Open Questions`. |

Never a benchmark, an industry norm, a guess, or an empty cell. The em dash in `TBD — Owner:` is the literal
character U+2014, with spaces around it.

## Event names

`object_action`: lowercase snake_case, the object first, the action last as a **past-tense verb**
(`recipe_saved`, `fridge_item_added`, `shopping_list_item_checked`). Not `save_recipe` (verb first),
`recipe_save` (not past), `RecipeSaved`, `recipe-saved` or `recipe saved`. Mechanical test: matches
`^[a-z][a-z0-9]*(_[a-z0-9]+)+$`, and the last token is a past-tense verb (ends in `ed`, or is an irregular past
such as `sent`, `built`, `shown`). Names are unique. One event per user action, not per screen. Properties are
snake_case attribute names (ids and counts), never names, emails or free text.

## Self-check

Run before showing the draft; fix and re-run. Every item is mechanical:

1. Each bullet under the PRD's `### Primary`, `### Secondary` and `### Guardrails` occurs verbatim (line breaks and repeated spaces
   collapsed; a literal `|` written as `\|`) in exactly one row of `## Success Criteria Mapping`, after its `[Primary] `, `[Secondary] ` or
   `[Guardrail] ` tag. Row count equals bullet count.
2. No `Target`, `Baseline`, `Window` or `Owner` cell is empty. Every `TBD — Owner: <role>` is covered by an entry in `## Open Questions`.
3. Every number in a `Target`, `Baseline` or `Window` cell occurs in that row's PRD bullet, or is the `0` of `0 (PRD: "never")` (an absolute word
   in the bullet), or the cell ends in `(PM)` and the number was given in the conversation. A number found in neither source is removed and the cell becomes `TBD — Owner: <role>`.
4. The north-star metric quotes a PRD line that occurs in `prd.md`; every input metric has a PRD ref that exists in `prd.md`.
5. Every event name passes the test in "Event names"; every event's PRD ref lists at least one existing `US-NN`; every `US-NN` of the
   PRD appears in at least one event; no event name is repeated.
6. Every row of `## Guardrail Metrics` comes from a `### Guardrails` bullet, and every `### Guardrails` bullet has a row.

## North Star Metric

One metric. A good candidate **reflects value delivered** to the user (a completed outcome, not a click on the way), **counts a repeated
behaviour** (so it can grow or shrink week to week), **can be moved by the team's work**, and **can be computed from events** (or the
event it lacks is named in `## Open Questions`). Candidates are derived from `### Primary` criteria, and the recommended one is the one
that measures the delivered outcome.

```markdown
## North Star Metric

**<Metric name>**: <one sentence: who is counted, what counts, over what period>.

- Source: > "<verbatim Primary line it is derived from>" (Primary <n>)
- Chosen by: <person / role> on <YYYY-MM-DD>
- Target, baseline, window: see the matching row in [Success Criteria Mapping](#success-criteria-mapping)
```

An own-words choice by the person is written the same way with `Source:` naming the closest Primary line, or `none fits (see Open Questions)`.

## Input Metrics

A tree under the north-star metric (3 to 5 inputs), then a table. Every input metric has a PRD ref (`Primary n`, `Secondary n`, `FR-NNN`,
`US-NN`, or `Scope [new] "<words>"` in a brownfield PRD); an input metric with no ref is not written.

````markdown
## Input Metrics

```text
<North-star metric>
├── <input metric 1>
├── <input metric 2>
└── <input metric 3>
```

| Input metric | Definition | Lever | PRD ref |
|---|---|---|---|
| <name> | <one line: what is counted> | <reach / first value / frequency / quality> | <ref> |
````

## Success Criteria Mapping

One row per Success Criteria bullet, in PRD order: Primary, then Secondary, then Guardrails. The first cell is the tag plus the bullet
verbatim. The table header:

```markdown
| PRD criterion | Metric | Target | Baseline | Window | Owner |
|---|---|---|---|---|---|
| [Primary] <bullet text> | <measurable restatement: what is counted, over whom> | <cell value> | <cell value> | <cell value> | <cell value> |
```

## Guardrail Metrics

One row per `### Guardrails` bullet. The breach condition restates the guardrail's own threshold as "breached when …" (or is
`TBD — Owner: <role>` when the mapping target is open).

```markdown
| Guardrail | Metric | Breach condition | Owner |
|---|---|---|---|
| <bullet text> | <metric name> | <breached when …, or TBD — Owner: <role>> | <same value as the mapping row> |
```

## Tracking Plan

At least one event per user story, plus events a metric needs when a story covers that action. Header fixed:

```markdown
| Event | Trigger | Properties | PRD ref |
|---|---|---|---|
| `recipe_saved` | The user saves a recipe to favourites | `recipe_id` | US-03, FR-003 |
```

`PRD ref` lists one or more `US-NN` first, then the `FR-NNN` (greenfield) or `Scope [tag] "<words>"` (brownfield) it serves.

## Open Questions

A numbered list, one entry per open item, in the PRD's style. Each `TBD` cell, each metric with no event behind it and each unguarded
risk has an entry; no entries → `None.`.

```markdown
1. **What is the baseline for <metric>?** — Owner: analytics. Affects: Success Criteria Mapping, Primary 1.
```

## Worked example (fixture project `recipe-fridge`)

Derived from `tests/fixtures/flat-root/context/foundation/recipe-fridge/prd.md`, as the skill would write it when the person picked the
recommended north-star metric and answered "skip" to every baseline and owner. Nothing in it is a number the PRD did not state.

````markdown
---
project: Recipe Fridge
prd_version: 1
created: 2026-10-20
updated: 2026-10-20
---

# Metrics: Recipe Fridge

## North Star Metric

**Weekly users who cook a suggested recipe twice**: weekly active users who cook a suggested recipe at least twice in a week.

- Source: > "At least 40% of weekly active users cook a suggested recipe at least twice a week by the end of the launch month." (Primary 2)
- Chosen by: product manager on 2026-10-20
- Target, baseline, window: see the matching row in [Success Criteria Mapping](#success-criteria-mapping)

## Input Metrics

```text
Weekly users who cook a suggested recipe twice
├── Fridge filled: users with at least three fridge items
├── Suggestion opened: weekly active users who open a recipe suggestion
├── Shopping list used: users who view a shopping list for a chosen recipe
└── Saved recipe revisited: users who return to a saved recipe
```

| Input metric | Definition | Lever | PRD ref |
|---|---|---|---|
| Fridge filled | Users with at least three items in their fridge | first value | US-01, FR-001 |
| Suggestion opened | Weekly active users who open a recipe suggestion | reach | Primary 1, US-01, FR-002 |
| Shopping list used | Users who view a shopping list for a chosen recipe | frequency | US-02, FR-004 |
| Saved recipe revisited | Users who come back to a recipe they saved | frequency | Secondary 1, US-03, FR-003 |

## Success Criteria Mapping

| PRD criterion | Metric | Target | Baseline | Window | Owner |
|---|---|---|---|---|---|
| [Primary] At least 60% of weekly active users open a recipe suggestion within one minute of opening the product. | Share of weekly active users who open a recipe suggestion within one minute of opening the product | at least 60% | TBD — Owner: analytics | within one minute of opening the product; weekly | TBD — Owner: product manager |
| [Primary] At least 40% of weekly active users cook a suggested recipe at least twice a week by the end of the launch month. | Share of weekly active users who cook a suggested recipe at least twice in a week | at least 40% | TBD — Owner: analytics | by the end of the launch month; weekly | TBD — Owner: product manager |
| [Secondary] Users who save a recipe come back to it at least once in the following two weeks. | Share of users who save a recipe and come back to it within two weeks | TBD — Owner: product manager | TBD — Owner: analytics | two weeks after saving | TBD — Owner: product manager |
| [Guardrail] A suggestion list never takes more than three seconds to appear after the fridge is updated. | Time from a fridge update to the suggestion list appearing | no more than three seconds (PRD: "never") | TBD — Owner: analytics | TBD — Owner: product manager | TBD — Owner: product manager |
| [Guardrail] Fridge contents are never shared with another user unless the owner explicitly shares them. | Cases where fridge contents are visible to a user the owner has not shared with | 0 (PRD: "never") | TBD — Owner: analytics | TBD — Owner: product manager | TBD — Owner: product manager |

## Guardrail Metrics

| Guardrail | Metric | Breach condition | Owner |
|---|---|---|---|
| A suggestion list never takes more than three seconds to appear after the fridge is updated. | Time from a fridge update to the suggestion list appearing | breached when a list takes more than three seconds | TBD — Owner: product manager |
| Fridge contents are never shared with another user unless the owner explicitly shares them. | Cases where fridge contents are visible to a user the owner has not shared with | breached by any case | TBD — Owner: product manager |

## Tracking Plan

| Event | Trigger | Properties | PRD ref |
|---|---|---|---|
| `fridge_item_added` | The user adds an item to their fridge | `item_id` | US-01, FR-001 |
| `fridge_item_removed` | The user removes an item from their fridge | `item_id` | US-01, FR-001 |
| `recipe_suggestions_viewed` | The user asks "What can I cook?" and the ranked list appears | `suggestion_count` | US-01, FR-002 |
| `recipe_suggestion_opened` | The user opens a recipe from the suggestion list | `recipe_id`, `rank` | US-01, FR-002 |
| `meal_plan_updated` | The user chooses or changes a day's meal in the plan | `day`, `recipe_id` | US-02, FR-005 |
| `shopping_list_viewed` | The user opens the shopping list for their plan | `item_count` | US-02, FR-004 |
| `shopping_list_item_checked` | The user checks an item off the shopping list | `item_id` | US-02, FR-004 |
| `recipe_saved` | The user saves a recipe to favourites | `recipe_id` | US-03, FR-003 |
| `recipe_shared` | The user shares a saved recipe with a household member | `recipe_id` | US-03, FR-003 |
| `recipe_unshared` | The user stops sharing a recipe | `recipe_id` | US-03, FR-003 |

## Open Questions

1. **What are the baselines for the five criteria?** — Owner: analytics. Affects: Success Criteria Mapping, all rows.
2. **What share of users should come back to a saved recipe within two weeks?** — Owner: product manager. Affects: Success Criteria Mapping, Secondary 1.
3. **Over what period is fridge-content sharing checked, and which statistic applies to the three-second limit (every list, or most lists)?** — Owner: product manager. Affects: Guardrail Metrics, Guardrail 1 and 2.
4. **Who owns each criterion's number?** — Owner: product manager. Affects: Success Criteria Mapping, Owner column.
5. **Which event records that a user cooked a suggested recipe?** Primary 2 and the north-star metric count it and no story records it. — Owner: product manager. Affects: North Star Metric, Primary 2. Consider a story via `/pm-prd-review`.
6. **What makes a user "weekly active"?** Two Primary criteria count them and the PRD does not say. — Owner: product manager. Affects: Primary 1, Primary 2.
````
