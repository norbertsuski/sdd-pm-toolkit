# Vendored files

These files were copied from an upstream SDD skills repository at commit `478b4d0` (plugin version 0.4.1)
and adapted for this plugin: command names renamed to `pm-*`, cross-skill links rewired, developer-only
hand-offs made generic, and the default audience set to `plain`. Artifact formats (paths, frontmatter keys,
headings, table columns, status values) are unchanged, so files written here stay readable by the upstream
tooling. This file is the only place (besides `scripts/check-upstream.sh` and `docs/superpowers/`) that names
the upstream repository.

`scripts/check-upstream.sh <path-to-upstream-checkout>` lists the upstream changes made since this commit.

Source paths below are relative to the upstream repository root.

| PM file | Source file | Source commit | Notes |
|---|---|---|---|
| `skills/pm-init/SKILL.md` | `skills/sdd-init/SKILL.md` | `478b4d0` | Renamed; audience question lists the non-technical option first (Recommended); plain handoff added; ownership line `Writes only: …` |
| `skills/pm-shape/SKILL.md` | `skills/sdd-shape/SKILL.md` | `478b4d0` | Renamed; refs point at `../pm-help/references/`; stack/health/planning steps described as developer steps; default audience `plain`; ownership line `Writes only: …` |
| `skills/pm-prd/SKILL.md` | `skills/sdd-prd/SKILL.md` | `478b4d0` | Renamed; refs point at `../pm-help/references/`; next step is `/pm-prd-review`, stack steps are generic developer hand-offs; default audience `plain`; ownership line `Writes only: …` |
| `skills/pm-help/references/prd-schema.md` | `skills/sdd-shape/references/prd-schema.md` | `478b4d0` | Moved to the shared references; self-references to its load path fixed; command names renamed |
| `skills/pm-help/references/plain-language.md` | `skills/sdd-shape/references/plain-mode.md` | `478b4d0` | Merged into the existing PM file: audience definitions, auto-decision policy and audit trail, handoff style, "artifacts are unchanged"; default `plain` |
| `skills/pm-help/references/context-resolution.md` | `skills/sdd-shape/references/context-resolution.md` | `478b4d0` | Existing PM version stays canonical; added who-runs-discovery rule, legacy-root note and the `audience` pointer; `/pm-init` offered when no root exists |
