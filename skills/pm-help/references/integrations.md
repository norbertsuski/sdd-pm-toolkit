# Integrations protocol (trackers, docs, chat, email)

Markdown under `$CONTEXT_ROOT` is the source of truth. Trackers, doc tools and chat are projections:
PM skills write to them only through this protocol, one way, never deleting anything there.
Only skills that write outside the repository use this file (`pm-research-synthesis` imports are
reads; `pm-backlog-sync` and `pm-status` write).

## Adapter detection

Look at the tool names the host exposes (case-insensitive substring match). Do not assume a tool exists.

| Substring in tool name | Adapter |
|---|---|
| `jira` | tracker: Jira |
| `linear` | tracker: Linear |
| `confluence` | docs: Confluence |
| `notion` | docs: Notion |
| `slack` | channel: Slack |
| `gmail` or `outlook` | channel: email (drafts) |

Several matches in one family (for example both `jira` and `linear`) → ask which to use. No match →
use [Export fallback](#export-fallback) and say so. The choice is stored per project in `pm-config.yml`
after the user confirms; later runs read it and do not ask again.

## pm-config.yml

Path: `$CONTEXT_ROOT/foundation/<slug>/pm-config.yml`. Written by any PM skill, only after the user
confirms the values.

```yaml
tracker: jira | linear | none
tracker_project: <Jira project key | Linear team key>
docs: confluence | notion | none
docs_location: <Confluence space key + parent page id | Notion parent page id>
channel: slack | email | none
channel_target: <#channel | email address list>
```

Missing keys are treated as `none`. Never store tokens or credentials here.

## Write protocol

Every write to an external system follows these steps, in order:

1. **Preview** — what will be written, where (system, project/space/channel), and how many items.
2. **Choice** — ask for exactly one of `Apply`, `Export file instead`, `Cancel`. Nothing is written before an answer.
3. **Apply** — perform the writes **sequentially**. Stop on the first error. After each success, record
   it (for example in `tracker-map.md`) so a partial run is not lost.
4. **Report** — list the keys or URLs created or updated, the count, and anything not done.

`Export file instead` follows [Export fallback](#export-fallback). `Cancel` writes nothing.

## Messages

Default output is a **draft** (Slack message text, email draft body) shown in the chat or saved under
`exports/`. Posting or sending needs a separate, explicit yes that **names the destination** (the channel
or the recipient list). A yes given earlier for a different destination or a different draft does not count.

## Export fallback

When no matching tool is available, or the user chooses `Export file instead`, write files under
`$CONTEXT_ROOT/foundation/<slug>/exports/` and tell the user where they are and how to use them:

| Need | File |
|---|---|
| Jira / Linear import | `exports/<date>-<what>.csv` |
| Confluence / Notion page | `exports/<date>-<what>.md` |
| Slack / email text | `exports/<date>-<what>.txt` |

`<date>` is `YYYY-MM-DD` from `date +%Y-%m-%d`. Exports are PM-owned files and may be overwritten by a
rerun of the same skill on the same day.
