---
name: pm-research-synthesis
description: >
  Turn raw user research — interview transcripts, notes, survey exports (CSV), pasted text — into an
  evidence-linked insights file: every insight cites verbatim quotes with source ids, participants are
  pseudonymized, and a "Seed for shaping" section (in the participants' own words) is ready to feed
  /sdd-shape through pm-discover. Use BEFORE pm-discover when the user has research, not in place of it.
  Never invents quotes, counts or participants. Trigger phrases: "synthesize research", "summarize
  interviews", "analyze these transcripts", "what did users say", "find insights in this survey",
  "affinity map", "jobs to be done from interviews", "research synthesis", "zsyntetyzuj badania",
  "podsumuj wywiady", "przeanalizuj transkrypcje", "co mówili użytkownicy", "wnioski z ankiety",
  "analiza badań użytkowników".
---

# /pm-research-synthesis — From Raw Research to Evidence-Linked Insights

Turns what users actually said into a short, checkable insights file under the project's `research/` folder.
Its value is traceability: each insight carries the exact words that support it, so a reader can tell what
participants said from what the PM concluded. The skill is a **synthesizer**, not a content generator: it
never writes a quote, a count or a participant that the sources do not contain.

## When to use, when to skip

**Use when** the user has interview transcripts, call notes, support threads or a survey export and wants
patterns, jobs to be done, pains and gains, or a starting point for shaping a product.

**Skip when** there is no raw research (go to `/pm-discover` with the idea), the user wants to *collect* research
(this skill only analyzes it), or the question is about a PRD or roadmap that already exists (`/pm-prd-review`).

## Relationship to other skills

- `/pm-discover` — the next step. It takes the `## Seed for shaping` section of the file this skill writes and
  hands it to `/sdd-shape` as the starting idea.
- `/sdd-shape` — owned by `sdd-skills`. This skill never calls it and never writes its files. The `research/`
  folder it creates is safe: `sdd-shape` only treats a project folder as a prior session when `shape-notes.md` exists.
- `/pm-help` — the map of the PM flow.

Shared rules, linked rather than restated: finding the root and the project —
`../pm-help/references/context-resolution.md`; audience and plain language —
`../pm-help/references/plain-language.md`; where this file sits among the PM artifacts —
`../pm-help/references/pm-artifacts.md`; the file layout, id scheme and self-check —
`references/insights-format.md`; behavior fixtures — `references/eval-cases.md`.

## Initial Response

1. **Paths, globs or a topic given** (`/pm-research-synthesis @research/*.md onboarding`) → collect them (Step 2) and
   take any leftover words as the topic.
2. **Text pasted into the message** → treat it as one source (several clearly separated pastes are several sources).
3. **Nothing given** → ask:

```
I'll turn your research into a short list of findings, each backed by the exact words people used.

Please share:
1. The research — file paths (@interview-1.md, a folder or a pattern like research/*.md), a survey export, or just paste the text
2. (Optional) What you were trying to learn — a few words, used to name the file

Tip: more than one source helps. A finding backed by one person is flagged as weak.
```

## Process

Facilitation style (as the `sdd-*` skills do): recommended option first, marked "(Recommended)", always a
"Not sure" option, one question at a time, echo back and confirm before anything is written.

### Step 1 — Audience, root and project

1. Resolve the audience per `../pm-help/references/plain-language.md` (ask once if `audience:` is absent). In plain
   mode say "findings" for insights and "what they were trying to get done" for jobs; the file itself is identical.
2. Resolve `CONTEXT_ROOT` and the project per `../pm-help/references/context-resolution.md`. No root found → recommend
   `/sdd-init` and stop; this skill does not scaffold a root.
3. **No project folder yet** (new project): ask for the project name, propose the slug (lowercase, each run of
   non-alphanumeric characters replaced by one `-`, leading/trailing `-` trimmed), and confirm it. Nothing is
   created until Step 7. Several projects → ask which; a project the user named wins.

### Step 2 — Collect the sources

- Read every file fully with Read (PDFs by page range). Expand globs and folders; ignore non-text files and say which.
- **CSV / survey exports**: the first row is the header. List the columns and ask which hold free text (quotable);
  choice and number columns only inform counts and are never quoted. Each data row is one respondent.
- Assign ids `S1…Sn` in the order received. Record kind, origin, date (if the source states one) and participants.
- Unreadable, empty or machine-garbled input → say so and ask; never fill the gap. Ask what the user wanted to
  learn only if the topic is still unknown.

### Step 3 — Pseudonymize (PII pass)

Before extracting anything, replace in the working text: person names → `P1…Pn` (by first appearance, one id per
person across sources), company names → `[company]` (`[company-2]` for a second one), emails → `[email]`,
phones → `[phone]`. Apply it to file names too when they carry a name (`Origin` becomes a neutral label).

Then ask **once**: "Keep real names and companies in the file? (No — use pseudonyms (Recommended) / Yes, keep them / Not sure)".
Default and "Not sure" → pseudonyms. "Yes" keeps names and companies but still replaces emails and phones, and
warns that the file lives in the repository. The mapping from `P1` to a real person is never written to disk.
All later steps, including quote checking, use the pseudonymized text.

### Step 4 — Extract and cluster

1. Per source, list candidate statements: what the participant does, needs, tries, works around or complains
   about. Quote only the participant, never the interviewer. An answer that only echoes a leading question
   is not evidence for a new insight.
2. Cluster the candidates into insights. For each insight write a one-sentence statement about the participants
   (no solutions, no features) and attach **at least one verbatim quote** with its source id. Copy character
   for character; do not paraphrase inside quote marks, do not stitch fragments, split a long answer into
   two quotes instead of cutting with an ellipsis.
3. Compute `Frequency: n/N` by counting the distinct source ids in the quotes, and `Confidence` by the rule in
   `references/insights-format.md` (3+ sources high, 2 medium, 1 low; always low with one source).
4. **A candidate with no quote is dropped**, not written, and not "softened" into a statement.
5. Derive, only from the insights: Jobs to Be Done (`When <situation>, I want to <motivation>, so I can <outcome>.`;
   a job missing a part becomes an open question), Pains & Gains, Contradictions & Surprises, Open Questions,
   and the Seed for shaping in the participants' words.

### Step 5 — Confirm with the user

Show a compact list — id, statement, `n/N`, confidence, number of quotes — and the draft Seed for shaping. Then ask:

```
Does this match what you heard? 1. Looks right — write it (Recommended)  2. Change something (keep / merge / drop / reword a finding)  3. Not sure — show me the quotes behind each finding
```

Apply merges and drops, renumber `I-NN` contiguously, recompute frequency and confidence, show the changed
items, and confirm again if anything moved. The user may reword a *statement*; quotes are never edited.

### Step 6 — Self-check

Run the self-check in `references/insights-format.md` before writing. The quote test is mechanical: every
quote must occur in its cited source, after the pseudonym pass and ignoring only line breaks and repeated spaces.
For files, a literal search per quote (`grep -F`, or Read and compare) is enough.

- **Quote not found** → do not repair it by rewording. Show the nearest real text from the source and ask
  whether to use that text instead; if there is none, drop the quote. An insight left with no quote is dropped
  and the user is told which one and why.
- Any other failed check → fix, re-run, and only then write.

### Step 7 — Write

1. File name: `<YYYY-MM-DD>-<topic-slug>.md` with the date from `date +%Y-%m-%d` and the topic slug by the same slug rule;
   propose the topic slug if the user gave none.
2. Path: `$CONTEXT_ROOT/foundation/<slug>/research/`. Create the folders (new project: show the planned path and
   slug and get an explicit yes first).
3. **The file already exists** (same date and topic) → ask: "Write a new file with suffix -2 (Recommended) /
   Overwrite it / Not sure". Overwrite keeps `created` and sets `updated` to today; the suffix takes the next
   free number (`-2`, `-3`, …). Never overwrite without the answer.
4. Write the file in the layout from `references/insights-format.md`. Then read it back to confirm the seven
   headings are present.

### Step 8 — Handoff

Plain mode ends with the handoff block from `../pm-help/references/plain-language.md`: what was found (count of
findings and sources, the weakest and strongest in a phrase), what was saved (in words, no path), and that the
next step is turning this into a shaped product idea (`/pm-discover`). Technical mode prints the file path and
the exact next command. Before naming `/pm-discover`, confirm it is among the host's available skills; if it is
not, say so and offer to paste the Seed for shaping into `/sdd-shape` yourself. Do not start the next skill.

## Output

One file: `$CONTEXT_ROOT/foundation/<slug>/research/<YYYY-MM-DD>-<topic-slug>.md`; frontmatter `project`, `topic`,
`created`, `updated`, `sources`; sections `## Sources`, `## Insights`, `## Jobs to Be Done`, `## Pains & Gains`,
`## Contradictions & Surprises`, `## Open Questions`, `## Seed for shaping`. Format and example:
`references/insights-format.md`. Besides this file the skill may write `audience:` to `.sdd.local.yml` (per the
plain-language rule) and nothing else.

## Critical guardrails

Never writes `prd.md`, `shape-notes.md`, or `roadmap.md`.

1. **Verbatim or nothing.** Text in quote marks is copied exactly from a source. Never paraphrase, translate, correct or combine inside quote marks.
2. **Never invent.** No quote, frequency, participant, source, JTBD clause or open-question answer that the sources do not contain.
3. **No evidence, no insight.** An insight with zero quotes is dropped, never written. A failed quote check is not repaired by rewording.
4. **Pseudonymize first.** Names, emails, phones and companies are replaced before extraction. The identity question is asked once; the default is no.
5. **Confirm before write.** The user sees and approves the insights and the Seed for shaping before the file exists.
6. **No silent overwrite.** An existing same-day file triggers the overwrite or `-2` question.
7. **Counts are counted.** Frequency comes from the evidence bullets; a single source never rates above low confidence.
8. **Seed stays in their words.** No feature, solution or requirement that is not inside a quote.
9. **Own files only.** Writes only under `research/` (plus `audience:` in `.sdd.local.yml`); `changes/**` and `archive/**` are never touched. A new project may get its `foundation/<slug>/research/` folders only.
10. **Never chain.** Do not start `/pm-discover`; the human decides.
11. **Mirror the user's language.** Statements follow the user's language; quotes stay in the language spoken; headings stay English.

## Notes

- A short run (one or two sources) is valid; the file says so through `low` confidence and open questions.
- Very large inputs: process source by source, keep each source's candidate quotes, then cluster; do not drop
  sources to save effort.
- Re-running on new sources writes a new file; it does not merge into an older one.
