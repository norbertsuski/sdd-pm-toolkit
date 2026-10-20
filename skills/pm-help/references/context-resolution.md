# Finding the context root and the project (PM discovery)

Every PM skill that reads or writes artifacts resolves two things first: **`CONTEXT_ROOT`** (which
`context/` folder) and the **project** (which folder under `foundation/`). This one contract is shared
by every `pm-*` skill that reads or writes artifacts, including `pm-init`, `pm-shape`, `pm-prd`,
`pm-roadmap` and `pm-map`.

## What a context root is

A directory named `context/` that holds a `.sdd.yml` marker. A repository may hold several (one at
the repo root and/or one per team directory). `.sdd.yml` has one key:

```yaml
layout: flat            # flat | (absent = legacy app-partitioned)
```

## Step 1 — discover roots

```bash
find . -name .sdd.yml \
  -not -path '*/node_modules/*' -not -path '*/.git/*' \
  -not -path '*/dist/*' -not -path '*/build/*' \
  -not -path '*/.next/*' -not -path '*/coverage/*' 2>/dev/null
```

Each match's directory is a candidate root `R`.

## Step 2 — classify and pick

- **Layout:** `grep -qE '^layout:[[:space:]]*flat' R/.sdd.yml` → **flat**. Otherwise **legacy**
  (a direct `R/foundation/` child means flat; `R/*/foundation/` subfolders mean legacy; roots
  created before the `layout:` key existed have none and are legacy).
- **None found** → the repo has no context root. Offer to run `/pm-init` (ask for a target folder,
  default the repo root), then discover again. A read-only skill only recommends `/pm-init`.
- **One or more found** → show them as a pick, each with its path and layout. Pre-select the root
  nearest to the current working directory (the deepest root that is an ancestor of, or equal to,
  cwd). Always show the choice; the user picks one root `R`.
- **Set `CONTEXT_ROOT`:** flat `R` → `CONTEXT_ROOT = R` (for example `context`). Legacy `R` → list the
  `R/*/` subfolders, have the user pick `<app>`, then `CONTEXT_ROOT = R/<app>` (for example
  `context/assets`).

Every artifact path is relative to `CONTEXT_ROOT`: `foundation/…`, `changes/…`, `archive/…`.
Flat roots omit `app:` from artifact frontmatter; legacy artifacts keep their `app:` and are read as they are.
PM skills never create a legacy-layout artifact.

**Who runs discovery.** Write-entry skills (`/pm-shape`) run this algorithm once, then hand the resolved
`CONTEXT_ROOT` (or a fully-resolved artifact path derived from it) to downstream skills. Pure downstream
skills (`/pm-prd`) never re-run discovery for an input inside a `foundation/<slug>/` folder; they operate on the path they are handed. Given raw notes from anywhere else, `/pm-prd` resolves the root and project (Steps 1-3) and writes into the project folder, never next to the notes. Standalone entry
points (`/pm-roadmap`, `/pm-map`, `/pm-help`, `/pm-status` and the other PM skills) are invoked directly
without a live `CONTEXT_ROOT`, so they run discovery themselves, to locate an existing artifact or to
enumerate roots for a status report. The "never re-run" rule applies only to a skill that was handed a
root by a write-entry skill within the same run.

`audience` is a per-operator preference in `$CONTEXT_ROOT/.sdd.local.yml` (git-ignored); see
`plain-language.md`. The committed `.sdd.yml` holds `layout:` only.

## Step 3 — pick the project

Glob `$CONTEXT_ROOT/foundation/*/` and drop the `archive/` folder (finished projects live in
`foundation/archive/`). A project folder is any remaining subfolder; its name is the project slug
(lowercase, each run of non-alphanumeric characters replaced by one hyphen, trimmed).

- **One** project → use it, and say which.
- **Several** → ask which, showing each slug (and the project name from its `prd.md` when there is one).
  If the user's request already names one, use it.
- **None** → there is no project yet. A skill that needs one says so and points at `/pm-discover`.

When a skill is handed a resolved `CONTEXT_ROOT` and slug by another skill in the same run it does not
run discovery again.

## Reading dates

Artifact dates come from frontmatter (`updated:`, else `created:`). Where a file has neither (for
example `.sdd.yml`), report the file's modified date and label it as such. Dates written by PM skills
are `YYYY-MM-DD`, produced with `date +%Y-%m-%d`.
