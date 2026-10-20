---
project: 'Recipe Fridge'
version: 1
status: draft
created: 2026-09-15
context_type: greenfield
delivery_mode: product-feature
product_type: web-app
target_scale:
  users: medium
  qps: low
  data_volume: small
timeline_budget: { hard_deadline: 2026-12-15 }
---

# Recipe Fridge — Product Requirements

## Vision & Problem Statement

Home cooks with a half-full fridge decide what to make by staring into it, then end up ordering food or
letting ingredients expire. A busy person has the ingredients for a good dinner most evenings and cannot
see it; the cost is wasted food and an unplanned takeaway several times a week.

The insight is that the fridge, not the recipe book, is the starting point. Matching recipes to what is
already on the shelf, ranked by how much of it they use, turns a 20-minute decision into a 20-second one.

## User & Persona

**Mara, 34, product designer, lives with a partner.** She cooks on weekdays after work, shops once a week,
and reaches for the product at 18:30 when she opens the fridge and has no plan. She wants dinner decided
quickly using what is already there and a short list of what to buy for the rest.

## Success Criteria

### Primary

- At least 60% of weekly active users open a recipe suggestion within one minute of opening the product.
- At least 40% of weekly active users cook a suggested recipe at least twice a week by the end of the launch month.

### Secondary

- Users who save a recipe come back to it at least once in the following two weeks.

### Guardrails

- A suggestion list never takes more than three seconds to appear after the fridge is updated.
- Fridge contents are never shared with another user unless the owner explicitly shares them.

## User Stories

### US-01: User sees what they can cook from the fridge

- **Given** a signed-in user who has added at least three items to their fridge
- **When** they ask "What can I cook?"
- **Then** they see recipes ranked by how many of the fridge items each recipe uses

#### Acceptance Criteria

- Recipes that use more of the user's items rank above recipes that use fewer
- An empty fridge shows an explanation and an invitation to add items, not an empty list
- Removing an item updates the suggestions on the next request

### US-02: User plans the week and knows what to buy

- **Given** a user who has chosen several recipes for the coming week
- **When** they open their plan
- **Then** they see each day's meal and a list of the ingredients they still need to buy

#### Acceptance Criteria

- Ingredients already in the fridge are not on the shopping list
- Changing a day's meal updates the shopping list
- The list can be checked off item by item

### US-03: User saves and shares favourite recipes

- **Given** a user looking at a recipe they liked
- **When** they save it and choose to share it with a household member
- **Then** the other person sees the recipe, with what is missing from their own fridge

#### Acceptance Criteria

- Saved recipes appear in one list, newest first
- Only people the user chooses can see a shared recipe
- Unsharing removes the recipe from the other person's view

## Functional Requirements

- FR-001: A signed-in user can add and remove items in their fridge inventory. Priority: must-have
- FR-002: A signed-in user can see recipes ranked by how much of their fridge each recipe uses. Priority: must-have
- FR-003: A signed-in user can save a recipe to favourites and share it with a household member. Priority: must-have
- FR-004: A signed-in user can get a shopping list of the ingredients missing for a chosen recipe. Priority: must-have
- FR-005: A signed-in user can plan meals for the week. Priority: nice-to-have

## Non-Functional Requirements

- A user sees recipe suggestions within 3 seconds of updating their fridge.
- A user's fridge contents are visible only to that user and to people they explicitly share with.
- The product remains usable on the latest two major versions of the four mainstream desktop browsers and on a phone-sized screen.

## Business Logic

A recipe is worth cooking tonight in proportion to how much of it the user already has, with recipes that use items about to expire ranked first.

The rule consumes the user's fridge items (each with an optional expiry date) and the ingredients of each
recipe. Its output is an ordered list of recipes with the missing ingredients named. The user meets it as
the "What can I cook?" list and again as the shopping list for a chosen recipe.

## Access Control

Signed-in users only. Each user sees their own fridge, favourites and plan. A user can share a single recipe
with a household member they choose; the recipient sees that recipe and nothing else of the sender's.
An unauthenticated visitor is sent to sign-in.

## Non-Goals

- No grocery ordering or delivery — the product tells the user what to buy, it does not buy it.
- No nutrition tracking or calorie counting — different product, different audience.
- No public recipe feed or social features beyond sharing with a chosen household member.
- No offline use in this release.

## Open Questions

1. **Which units do ingredient quantities use (metric, imperial, both)?** — Owner: product. By: 2026-10-30. Block: no.
2. **Does sharing happen by link or by invitation inside the product?** — Owner: product. By: 2026-11-05. Block: yes.
3. **Is there a licensed recipe source, or do users enter their own?** — Owner: product. By: 2026-10-30. Block: no.
