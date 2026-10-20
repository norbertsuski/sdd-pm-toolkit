# pm-init eval cases

Behavioral prompt fixtures for `pm-init`. To try one by hand, copy the fixture `tests/fixtures/flat-root/context/`
(or an empty folder, where the case says so) into a scratch git repo and run Claude Code with the plugin loaded
(see the README, "Local testing"). Every case also implies the guardrails in `SKILL.md`: never overwrite existing
content, never pre-create `foundation/`, `changes/` or `archive/`, never chain into another skill.

| ID | Given | Invoke | Expected |
|---|---|---|---|
| IN-01 | An empty git repo, no `context/` folder. | `/pm-init` | `ROOT = context`. The skill creates `context/`, `context/README.md` (the flat-layout text), `context/.sdd.yml` containing exactly `layout: flat`, asks the audience question once (non-technical option first and marked Recommended), then writes `context/.gitignore` containing the line `.sdd.local.yml` BEFORE it writes `context/.sdd.local.yml` with `audience: plain`. `foundation/`, `changes/` and `archive/` are not created. The summary lists five paths, each `created`. Fail if `audience:` appears in `.sdd.yml`, or `.sdd.local.yml` is written before the `.gitignore` line exists. |
| IN-02 | `IN-01` was already run; all five files exist and `.sdd.local.yml` has `audience: plain`. | `/pm-init` | Idempotent no-op: nothing is rewritten, the audience question is not asked again, the status block shows all five entries as `present`. Fail if any file's content or modified time changes, or the `.gitignore` gains a second `.sdd.local.yml` line. |
| IN-03 | A repo with a `frontend/posting/` folder and no context root. | `/pm-init frontend/posting` | `ROOT = frontend/posting/context`; the five files are created under that path only, and no `context/` appears at the repo root. The paragraph at the end says a repo may hold several roots and that `/pm-shape` asks which one to use. The skill stops and does not start `/pm-shape`. |
| IN-04 | `context/.sdd.yml` written by an older version, containing `audience: technical` and no `layout:` key; no `.sdd.local.yml`. | `/pm-init` | `.sdd.yml` is backfilled with `layout: flat` and the stale `audience:` key is dropped; other content stays. The audience question is asked and the answer lands only in `.sdd.local.yml`. `README.md` is left untouched (`present`). |
| IN-05 | The user answers the audience question with "Developers". | `/pm-init` | `.sdd.local.yml` gets `audience: technical`; the end-of-run output is the status block plus the layout paragraph. With the other answer (`plain`) the skill prints no status block and no file names: it gives the plain handoff ("Here's what I did / Here's what happens next / Want me to keep going?") naming `/pm-shape` once in parentheses. Fail if a `plain` run shows paths or YAML. |
