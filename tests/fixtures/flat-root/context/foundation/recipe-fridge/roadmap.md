---
project: 'Recipe Fridge'
version: 1
status: active
created: 2026-09-18
updated: 2026-10-14
prd_version: 1
main_goal: market-feedback
top_blocker: decisions
---

# Roadmap: Recipe Fridge

> Derived from `context/foundation/recipe-fridge/prd.md` (v1) + auto-researched codebase baseline.
> Edit-in-place; archive when superseded.
> Slices below are listed in dependency order. The "At a glance" table is the index.

## Vision recap

Home cooks stare into a half-full fridge, cannot see the dinner it already holds, and fall back on takeaway
or let food expire. Recipe Fridge starts from what is on the shelf and ranks recipes by how much of it they use.

## North star

**S-02: user can see recipes ranked by how much of their fridge each one uses** — this is the validation milestone that proves people act on fridge-first suggestions, which is what the market-feedback goal needs first.

> The north star is the smallest end-to-end slice whose successful delivery would prove the core product hypothesis — placed as early as Prerequisites allow because everything else only matters if this works.

## At a glance

| ID   | Change ID       | Outcome (user can …)                                            | Prerequisites                             | PRD refs      | Status   |
| ---- | --------------- | --------------------------------------------------------------- | ----------------------------------------- | ------------- | -------- |
| F-01 | auth-scaffold   | (foundation) sign-in works and every user has a private account | —                                         | Access Control | done     |
| S-01 | fridge-inventory | user can add and remove items in their fridge                  | F-01                                      | US-01, FR-001 | done     |
| S-02 | recipe-match    | user can see recipes ranked by how much of their fridge each uses | S-01                                    | US-01, FR-002 | done     |
| S-03 | save-favorites  | user can save a recipe to their favourites                      | S-02                                      | US-03, FR-003 | done     |
| S-04 | shopping-list   | user can get a shopping list of the ingredients a recipe still needs | S-02, ingredient unit convention agreed | US-02, FR-004 | proposed |
| S-05 | meal-plan       | user can plan the week's meals from their favourites            | S-03                                      | US-02, FR-005 | ready    |
| S-06 | share-recipe    | user can share a recipe, with its missing ingredients, with a household member | S-04                      | US-03, FR-003 | blocked  |

## Streams

Navigation aid — groups items that share a Prerequisites chain. Canonical ordering still lives in the dependency graph below; this table is the proposed reading order across parallel tracks.

| Stream | Theme                 | Chain                                          | Note                                                                 |
| ------ | --------------------- | ---------------------------------------------- | -------------------------------------------------------------------- |
| A      | Cook from the fridge  | `F-01` → `S-01` → `S-02` → `S-03` → `S-05`     | The path from "what can I cook?" to a planned week; carries the north star. |
| B      | Shop and share        | `S-04` → `S-06`                                | Starts from the recipe match in stream A; waits on the unit convention and the sharing decision. |

## Baseline

What's already in place in the codebase as of `2026-09-18` (auto-researched + user-confirmed).
Foundations below assume these are present and do NOT re-scaffold them.

- **Frontend:** absent — greenfield; the first slice lands the app shell.
- **Backend / API:** absent — greenfield.
- **Data:** absent — greenfield.
- **Auth:** absent — F-01 scaffolds it.
- **Deploy / infra:** absent — decided with the first slice.
- **Observability:** absent — not needed before the north star.

## Foundations

### F-01: Auth scaffold

- **Outcome:** (foundation) sign-in works and every user has a private account.
- **Change ID:** auth-scaffold
- **PRD refs:** Access Control
- **Unlocks:** S-01 (a fridge belongs to a signed-in user), S-03 and S-06 (favourites and sharing are per user).
- **Prerequisites:** —
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Every other slice stores per-user data, so sign-in has to exist first; the risk is over-building roles that the PRD does not ask for.
- **Status:** done

## Slices

### S-01: Fridge inventory

- **Outcome:** user can add and remove items in their fridge.
- **Change ID:** fridge-inventory
- **PRD refs:** US-01, FR-001
- **Prerequisites:** F-01
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Everything downstream reads the fridge, so the shape of an item (name, optional expiry date) is set here; getting it wrong costs rework in S-02.
- **Status:** done

### S-02: Recipe match

- **Outcome:** user can see recipes ranked by how much of their fridge each one uses.
- **Change ID:** recipe-match
- **PRD refs:** US-01, FR-002
- **Prerequisites:** S-01
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Tests the core hypothesis (people act on fridge-first suggestions), so it comes as early as the fridge allows; weak matches here would undermine every later slice.
- **Status:** done

### S-03: Save favourites

- **Outcome:** user can save a recipe to their favourites.
- **Change ID:** save-favorites
- **PRD refs:** US-03, FR-003
- **Prerequisites:** S-02
- **Parallel with:** S-04
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Small and safe once recipes exist; it feeds the meal plan and the sharing slice.
- **Status:** done

### S-04: Shopping list

- **Outcome:** user can get a shopping list of the ingredients a recipe still needs.
- **Change ID:** shopping-list
- **PRD refs:** US-02, FR-004
- **Prerequisites:** S-02, ingredient unit convention agreed
- **Parallel with:** S-03, S-05
- **Blockers:** —
- **Unknowns:**
  - Which units do quantities use (metric, imperial, both)? — Owner: product. Block: no.
- **Risk:** Comparing the fridge with a recipe needs one unit convention; it is sequenced after the north star so the decision can wait until the match proves useful.
- **Status:** proposed

### S-05: Meal plan

- **Outcome:** user can plan the week's meals from their favourites.
- **Change ID:** meal-plan
- **PRD refs:** US-02, FR-005
- **Prerequisites:** S-03
- **Parallel with:** S-04
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Nice-to-have in the PRD, sequenced after favourites because it plans from them; the cheapest slice to cut if the deadline tightens.
- **Status:** ready

### S-06: Share recipe

- **Outcome:** user can share a recipe, with its missing ingredients, with a household member.
- **Change ID:** share-recipe
- **PRD refs:** US-03, FR-003
- **Prerequisites:** S-04
- **Parallel with:** S-05
- **Blockers:** —
- **Unknowns:**
  - Does sharing happen by link or by invitation inside the product? — Owner: product. Block: yes.
- **Risk:** The sharing mechanism changes both the access rules and the screens; building before the decision is made risks throwing the work away.
- **Status:** blocked

## Backlog Handoff

| Roadmap ID | Change ID        | Suggested issue title                                         | Ready for `/sdd-plan` | Notes                                  |
| ---------- | ---------------- | ------------------------------------------------------------- | --------------------- | -------------------------------------- |
| F-01       | auth-scaffold    | Add sign-in and private accounts                              | no                    | Done — archived 2026-09-29             |
| S-01       | fridge-inventory | Add and remove fridge items                                   | no                    | Done — archived 2026-10-01             |
| S-02       | recipe-match     | Rank recipes by fridge match                                  | no                    | Done — archived 2026-10-08             |
| S-03       | save-favorites   | Save recipes to favourites                                    | no                    | Done — archived 2026-10-14             |
| S-04       | shopping-list    | Generate a shopping list for a recipe                         | no                    | Waiting on the unit convention         |
| S-05       | meal-plan        | Plan the week's meals                                         | yes                   | Ready for a developer to plan          |
| S-06       | share-recipe     | Share a recipe with a household member                        | no                    | Blocked on the sharing decision        |

This table is the clean handoff to Jira/Linear or any MCP-backed backlog. Include one row for every `F-NN` and `S-NN`. It should be compact enough to copy into issues, but it must not duplicate the detailed roadmap body.

## Open Roadmap Questions

1. **Which units do ingredient quantities use (metric, imperial, both)?** — Owner: product. Block: S-04.
2. **Does sharing happen by link or by invitation inside the product?** — Owner: product. Block: S-06.

## Parked

- **Grocery ordering and delivery** — Why parked: PRD Non-Goals; the product tells the user what to buy, it does not buy it.
- **Offline use** — Why parked: PRD Non-Goals; not in this release.

## Done

- **F-01: (foundation) sign-in works and every user has a private account** — Archived 2026-09-29 → `context/archive/2026-09-22-auth-scaffold/`. Lesson: —.
- **S-01: user can add and remove items in their fridge** — Archived 2026-10-01 → `context/archive/2026-09-24-fridge-inventory/`. Lesson: —.
- **S-02: user can see recipes ranked by how much of their fridge each one uses** — Archived 2026-10-08 → `context/archive/2026-10-01-recipe-match/`. Lesson: —.
- **S-03: user can save a recipe to their favourites** — Archived 2026-10-14 → `context/archive/2026-10-06-save-favorites/`. Lesson: —.
