# Plain language and audience (PM skills)

PM skills speak plain language by default. Plain mode changes the conversation and the printed
summaries only; every file written to disk is identical in both modes.

`audience` marks **who is operating the skill**, not what is being built:

- `plain` — a non-technical operator (product owner / project manager). The default. The skill
  facilitates and reports in plain language, silently handles technical-only decisions, and logs every
  such decision for a technical reviewer.
- `technical` — a developer. Full behavior: YAML, schemas, FR-NNN, shell commands and git shown, exactly
  as each skill's own body describes.

## Audience resolution

`audience` is a per-person preference, kept in the git-ignored `$CONTEXT_ROOT/.sdd.local.yml` — never in
a committed artifact. Every audience-aware skill resolves it the same way; it is a cheap local read, so
there is no inheritance through frontmatter and no re-stamping into artifacts: each skill checks the
local file itself every time.

1. Read `audience:` from `$CONTEXT_ROOT/.sdd.local.yml`. Present → use it.
2. Absent → ask once:

   > Are you a developer, or a non-technical person (like a product owner or project manager)? I'll keep everything in plain language if you're not a developer.

   Map "developer" → `technical`; anything else → `plain`.
3. Write the answer as `audience: <plain|technical>` into `$CONTEXT_ROOT/.sdd.local.yml` (create it if
   needed). **Before writing**, make sure `$CONTEXT_ROOT/.gitignore` exists and contains the line
   `.sdd.local.yml`; create or append first. Every PM skill reads this same file and key, so none of them
   asks again.
4. Question unanswered → `plain` (the PM default).

Read-only skills (`pm-help`) never write: when `audience:` is absent they use `plain` without asking.
If no `CONTEXT_ROOT` is resolved yet, use `plain`.

## What plain mode never shows

Frontmatter and field names (`context_type`, `product_type`, `timeline_budget` and the like), requirement
and story numbering (FR-001, US-02, NFR), the "one-sentence business rule" framing, the empty-CRUD label,
"Socratic round", shell commands (`pbcopy`, PowerShell blocks), file paths and folder layout, schema and
section-name talk (the PRD or roadmap schema, self-review and lint internals), and git or branch mechanics.
Say what the thing does. Mirror the user's language (Polish in, Polish out); plain mode adds "no jargon", it
does not change language mirroring.

| Instead of | Say |
|---|---|
| FR, US, NFR | "what people need to be able to do", "a story about one person's goal", "a quality it must have (speed, privacy …)" |
| slug | "the project's short name" |
| frontmatter | "the details at the top of the file" |
| Change ID | "the build item's short name" |
| roadmap slice, vertical slice | "one piece of the product a user can actually use" |
| north star | "the first piece worth building — the one that proves the idea works" |
| Prerequisites | "what has to be finished first" |
| MCP, adapter | "the connection to your tracker / docs / chat tool" |
| CSV export | "a file you can import into your tracker" |
| `prd.md` | "the product write-up" |
| `roadmap.md` | "the build plan" |
| blocked / `Block: yes` | "waiting on a decision or answer" |
| greenfield / brownfield | (not named — "starting from scratch" / "changing something that exists") |
| fan-out, dependency graph, foundation | "which pieces can be built independently", "what depends on what", "the product's core documents" |
| "State the one-sentence business rule." | "In one sentence, what's the smart thing this does for the user that a plain spreadsheet couldn't?" |
| "I'll write shape-notes.md, then run /pm-prd." | "I'll save your answers, then turn them into a product write-up you can share." |
| "Which starter/stack should we use?" | (not asked — see Auto-decision policy) |

Skill names such as `/pm-prd-review` are the one thing a person must type, so name the step in words
first and show the command once in parentheses.

## Auto-decision policy

In plain mode, the skill resolves technical-only decisions itself and does NOT ask the operator. Each row:
the safe default, and whether it must be logged (see the audit trail).

| Decision | Owner skill | Plain-mode default | Log? |
| --- | --- | --- | --- |
| Context root / project resolution | pm-shape, pm-roadmap | Auto-detect from cwd; if ambiguous, ask in product terms ("which part of the product is this for?") and map the answer to the root | yes |
| Greenfield vs brownfield | pm-shape, pm-prd | Auto-detect silently from project markers; never surface the term | no |
| Tech stack / starter (starting from scratch) | a developer | Not asked here; noted for the developer who chooses it | yes (the note) |
| Stack assessment (changing something that exists) | a developer | Not asked here; anything risky noted for the developer | yes (anything risky) |
| Test strategy, implementation variant, commit / branch mechanics | a developer | Not part of PM skills; never shown as git commands | no |

The skill never invents PRODUCT content (business rules, success criteria, requirements). That rule is
unchanged in plain mode — genuine product gaps still surface as plain questions, and unresolved ones still
land in the artifact's Open Questions. Auto-decisions cover TECHNICAL choices only.

## Auto-decision audit trail

Every technical decision the skill made silently in plain mode (rows marked "Log? yes" above) is appended
to an `## Auto-decisions (for review)` block on the artifact the skill produces (`shape-notes.md`).
Format — one bullet per decision:

```markdown
## Auto-decisions (for review)

- **<what was decided>** — <the choice made>. Why: <one-line rationale>. A developer should confirm
  this at review.
```

This block is additive: it does NOT replace or alter any schema-required section, and it is ignored by
downstream parsers (which grep for the contract section names). Its sole audience is the human technical
reviewer. This upholds the principle "gaps surface, they don't hide" — auto-handling is logged, never
silent invention.

## Handoff style

Plain mode KEEPS every human handoff (nothing auto-chains) but replaces the jargon status block with a
plain summary and a plain continue-gate. Every skill ends its turn with this handoff block (plain mode)
instead of a status dump, and never starts the next skill by itself:

```
Here's what I did: <2-4 plain sentences>.
Here's what happens next: <one plain sentence naming the next step in product terms>.
Want me to keep going?
```

Do NOT print the schema status block or the clipboard command. Where a skill copies the next command to the
clipboard, it does so silently; describe the next step in words and show its `/pm-…` command once in
parentheses.

In technical mode print the files touched and the exact next command instead.

## Artifacts are unchanged

The files written to disk are identical in both modes and fully schema-conformant. Plain mode changes only
(a) the conversation, (b) the printed summaries, and (c) the additive `## Auto-decisions (for review)`
block. A technical reviewer opening a PM-produced `prd.md` gets the real, complete PRD. This is the
property that makes the whole approach safe.
