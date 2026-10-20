# Plain language and audience (PM skills)

PM skills speak plain language by default. Plain mode changes the conversation and the printed
summaries only; every file written to disk is identical in both modes.

## Audience resolution

`audience` is a per-person preference, kept in the git-ignored `$CONTEXT_ROOT/.sdd.local.yml` — never in
a committed artifact.

1. Read `audience:` from `$CONTEXT_ROOT/.sdd.local.yml`. Present → use it.
2. Absent → ask once:

   > Are you a developer, or a non-technical person (like a product owner or project manager)? I'll keep everything in plain language if you're not a developer.

   Map "developer" → `technical`; anything else → `plain`.
3. Write the answer as `audience: <plain|technical>` into `$CONTEXT_ROOT/.sdd.local.yml` (create it if
   needed). **Before writing**, make sure `$CONTEXT_ROOT/.gitignore` exists and contains the line
   `.sdd.local.yml`; create or append first. Because this is the same file and key the `sdd-*` skills read,
   they will not ask again.
4. Question unanswered → `plain` (the PM default; `sdd-skills` itself defaults to `technical`).

Read-only skills (`pm-help`) never write: when `audience:` is absent they use `plain` without asking.
If no `CONTEXT_ROOT` is resolved yet, use `plain`.

## What plain mode never shows

Frontmatter and field names, requirement and story numbering (FR-001, US-02, NFR), shell commands,
file paths and folder layout, schema and section-name talk, and git mechanics. Say what the thing does.
Mirror the user's language (Polish in, Polish out).

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

Skill names such as `/pm-prd-review` are the one thing a person must type, so name the step in words
first and show the command once in parentheses.

## Handoff block

Every skill ends its turn with this block (plain mode) instead of a status dump, and never starts the next
skill by itself:

```
Here's what I did: <2-4 plain sentences>.
Here's what happens next: <one plain sentence naming the next step in product terms>.
Want me to keep going?
```

In technical mode print the files touched and the exact next command instead.
