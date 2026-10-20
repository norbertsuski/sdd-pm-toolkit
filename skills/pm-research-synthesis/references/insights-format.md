# Insights file format

The file `pm-research-synthesis` writes: `$CONTEXT_ROOT/foundation/<slug>/research/<YYYY-MM-DD>-<topic-slug>.md`.
One file per synthesis. The seven `##` headings below are fixed, in this order, always present (an empty
section says `None found in these sources.`). Headings stay in English in every language; the text under them
follows the user's language, except quotes, which are never translated or edited.

## Frontmatter

```yaml
---
project: <project slug>
topic: <topic, as the user named it>
created: <YYYY-MM-DD>      # date +%Y-%m-%d; unchanged when the file is overwritten
updated: <YYYY-MM-DD>      # date +%Y-%m-%d
sources: <n>               # count of rows in ## Sources
---
```

Followed by a `# Research synthesis — <topic>` title line, then the sections.

## Ids

| Id | Meaning |
|---|---|
| `S1…Sn` | One source (a transcript, a notes file, a survey export, a pasted block), numbered in the order received |
| `P1…Pn` | One participant, numbered by first appearance across all sources (a person who appears in two sources keeps one id) |
| `[company]`, `[company-2]` … | Company names. `[email]`, `[phone]` replace addresses and numbers |
| `I-01…` | One insight, contiguous after any drops |
| `Q-01…` | One open question |

## Sections

Each heading below is the exact heading written into the file, followed by what goes under it.

## Sources

```markdown
| ID | Kind | Origin | Date | Participants |
|---|---|---|---|---|
| S1 | interview | interview-1.md | 2026-10-02 | P1 |
| S2 | survey (CSV, 14 rows) | survey-export.csv | 2026-10-09 | P2–P15 |
| S3 | notes | pasted in chat | — | P16 |
```

`Origin` is the file name only when it carries no name or company; otherwise a neutral label
(`interview-1`). `Date` is from the source when it states one, else `—`. A CSV row is cited as
`S2 (row 7)`; row numbers count data rows below the header.

## Insights

```markdown
### I-01: <one-sentence statement of what participants do, need or struggle with>
- Evidence:
  > "<verbatim quote>" — S1
  > "<verbatim quote>" — S3
- Frequency: 2/3 sources
- Confidence: medium
```

- The statement describes participants, never a solution or a feature.
- **Evidence**: at least one quote. A quote is copied character for character from a source
  (after the pseudonym pass). No edits, no stitched fragments, no fixed typos or grammar, and no
  ellipsis; two separate stretches are two quotes. Only participants are quoted, never the interviewer.
  Attribution is `— <source id>` with an optional `(row N)` locator.
- **Frequency**: `n/N` where `n` is the number of distinct sources that carry a quote for this insight
  and `N` is the total in `## Sources`. Counted from the evidence bullets, never estimated.
- **Confidence**: `high` = quotes from 3 or more distinct sources; `medium` = 2; `low` = 1 (and always `low`
  when `N` is 1). Lower it one step when the only support is an answer to a leading question.
- Order: highest frequency first, then by id.

## Jobs to Be Done

```markdown
- When <situation>, I want to <motivation>, so I can <outcome>.
  - Based on: I-01, I-03
```

Written only where the evidence states all three parts. A missing part becomes a question under
`## Open Questions`, not a guess.

## Pains & Gains

```markdown
### Pains
- <pain, in participants' terms> — I-01, I-04
### Gains
- <what would be better for them, as they said it> — I-02
```

## Contradictions & Surprises

```markdown
- Contradiction: <what differs> — "<quote>" (S1) versus "<quote>" (S3)
- Surprise: <what the team likely did not expect> — "<quote>" (S2) — I-05
```

## Open Questions

```markdown
- Q-01: <what is not known> — <why it matters, or who/what to ask next>
```

Covers gaps, single-source insights, missing parts of a job, and groups of people not heard yet.

## Seed for shaping

Written in the participants' words. `pm-discover` hands this section unchanged to `/pm-shape` as the starting
idea, so it must stand alone and must not add anything the sources do not say.

```markdown
*In the participants' words. Every line is a quote or traces to one.*

**Who:** <who the participants are, only as the sources say> (S1, S3)
**The problem, as they put it:**
> "<verbatim quote>" — S1
**What they do today:**
- <workaround, in their vocabulary> (S2)
**What they say they want:**
> "<verbatim quote>" — S3
**Not known yet:** Q-01, Q-02
```

Rules: no feature, solution, requirement number or product name that is not inside a quote; at most one
connecting sentence per label; about 15 lines in all; every line cites a source id.

## Self-check (run before writing)

1. The seven headings are present, in order, once each; frontmatter has the five keys.
2. Every `### I-NN` has at least one evidence bullet; ids are contiguous.
3. Every quote is found verbatim in its cited source (pseudonymized text).
4. `n` equals the distinct source ids in the evidence; `N` equals `sources:`; confidence follows the rule.
5. No real name, email, phone or company remains unless the user chose to keep identities (then emails and
   phones are still replaced).
6. Every JTBD, pain, gain and seed line traces to an insight or a quote.
