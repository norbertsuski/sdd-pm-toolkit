# pm-map eval cases

Behavioral prompt fixtures for `pm-map`. The fixture is `tests/fixtures/flat-root/context/` (project `recipe-fridge`,
a roadmap with F-01 and S-01..S-06). To try one by hand, copy it into a scratch git repo and run Claude Code with the
plugin loaded (see the README, "Local testing"). Every case also implies the guardrails in `SKILL.md`: it writes only
`roadmap-map.md`, never edits `roadmap.md`, never draws the graph by hand.

| ID | Given | Invoke | Expected |
|---|---|---|---|
| MP-01 | The fixture roadmap (F-01, S-01, S-02, S-03 `done`; S-05 `ready`; S-04 `proposed` with an unmet prerequisite; S-06 `blocked`). | `/pm-map recipe-fridge` | The skill resolves the renderer from the host-reported base directory, runs `bash "<skill dir>/render-roadmap-map.sh" "<…/roadmap.md>"`, and `roadmap-map.md` appears beside the roadmap with a `graph LR` Mermaid block containing all seven nodes (`F-01`, `S-01`..`S-06`), S-02 starred as the north star, 4 done / 1 ready / 2 blocked, and edges `F-01 → S-01 → S-02`. `roadmap.md` is byte-identical afterwards. |
| MP-02 | No base directory is reported by the host, `CLAUDE_PLUGIN_ROOT` is set. | `/pm-map` | The renderer is taken from `$CLAUDE_PLUGIN_ROOT/skills/pm-map/`. If neither works, the skill says the renderer cannot be found and STOPS; it does not draw the graph from the roadmap table itself. |
| MP-03 | A project with no `roadmap.md`. | `/pm-map` | "No roadmap yet - run `/pm-roadmap` to generate one." and stop; nothing is written. |
| MP-04 | A `roadmap.md` with no `## At a glance` table. | `/pm-map` | The renderer exits non-zero with its message; the skill surfaces it and stops. No `roadmap-map.md` is written and no graph is invented. |
| MP-05 | `audience: plain`; the fixture. | `/pm-map` | The confirmation is plain ("1 piece is finished ... can start now ... waiting on something earlier"), without the summary block, `S-NN` ids or schema words, and says the picture is saved next to the plan. The map file on disk is identical to a technical-mode run. |
| MP-06 | `roadmap-map.md` exists and the optional hook is NOT wired; the user edits `roadmap.md`. | (edit) | Nothing refreshes the map (the hook is optional and never installed by the skill); re-running `/pm-map` overwrites `roadmap-map.md` in place. |
