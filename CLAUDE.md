# Session Handoff Command — Project Context

Maintenance workspace for two **personal Claude Code slash-commands** that give a solo
developer session-to-session continuity:

- `/session-handoff [topic] [--done]` — save the current session as a structured,
  resumable, gitignored handoff file, then stop.
- `/session-resume [topic] [--all]` — pick + load the right handoff and continue.

This folder is the **source of truth and the shareable package** (for later proposing the
commands to the buzzwoo-standard maintainer). The commands themselves run from a **global**
location — see Deploy below.

## Deploy (most important gotcha)

Claude Code loads personal commands from `~/.claude/commands/`, NOT from this folder.
So `commands/` here is the **source**; deploy by copying to the live location:

```powershell
Copy-Item .\commands\session-handoff.md "$env:USERPROFILE\.claude\commands\session-handoff.md" -Force
Copy-Item .\commands\session-resume.md  "$env:USERPROFILE\.claude\commands\session-resume.md"  -Force
```

**Rule: edit here, then deploy.** Do not edit the live copies directly — they would drift
from this source. The static test asserts source==deployed parity, so a forgotten deploy
fails the suite rather than passing silently.

## Where handoff *output* goes (not here)

When `/session-handoff` runs inside some *other* project, its handoff `.md` files are
written to **that project's** `.claude/session-handoffs/` (gitignored) — never into this
maintenance repo.

## What the layout does not show

- `plan/` holds **three** design documents, not one: `session-handoff-plan.md` (the original
  grilled design, 12 decisions + post-design additions 13–20), `token-optimization-plan.md`
  (the v0.2.0 token-aware loading design) and `readability-preflight-plan.md` (the v0.4.x
  readability work, Track B for v0.5.0, and §16 the output-volume and briefing-order redesign).
- The commands contain **platform-conditional** execution paths (PowerShell batching on
  `win32` hosts that hard-block chained Bash, plain chained Bash elsewhere). This looks like
  redundancy but is deliberate — the verified reasoning is plan Decision 18. Do not collapse
  it into one branch.
- Apparent redundancy in the command files is mostly hardened. Before simplifying either,
  read the do-not-touch list in `reviews/subagent-review-2026-08-21.md` (safe ceiling ~3%).

## Testing

Run `pwsh -File .\tests\validate-commands.ps1` after changing and deploying a command file —
static structure, frontmatter, step numbering, cross-references, and source==deployed parity
(exit 0/1, no dependencies). Runtime behaviour is covered by `tests/behavioral/`, where
Claude dispatches subagents that execute the commands in a sandbox and `verify-artifacts.ps1`
asserts on the output. Suite contents and how to re-run: `tests/README.md` +
`tests/behavioral/README.md`. Check counts live in `README.md` → Testing and nowhere else.

- Rewrapping prose in a command file can fail a check: most are literal `Contains()`, and a
  phrase split across a line break no longer matches.
- A new check goes **scoped** to the block that must hold the content: use a shared slice
  (`$hFm`, `$rFm`, `$tpl`, `$gitBlock`, `$hop`). Unscoped passes on text found anywhere.
- `compat-old-chain.ps1` counts `Done:` **bullets**, not a number stated in prose. Collapsing
  several closed items into one summarising bullet makes it report phantom loss.

## Where to look

- Current state and open work: this project's Claude memory (`MEMORY.md` + fact files)
- Released versions and their contents: `CHANGELOG.md`
- Why things are the way they are, incl. rejected alternatives: `docs/decision-log.md`
- The design as designed (three records, incl. Track B): `plan/`
- Visual explainer (open in a browser): `docs/how-it-works.html`

## Invocation policy

The never-unasked rule lives in each command's `description` and its "Invocation policy" section,
not in the file format — plan addition 20. The command files must stay self-contained for anyone
who gets them without this repo.

`disable-model-invocation: true` would be a harder stop and the official frontmatter table
documents it for exactly this case. It was added on 2026-08-22 and **reverted the same day**: it
was never approved, and addition 20 is a decision, not an oversight. Do not re-add it without
asking — the reasoning both ways is in `docs/decision-log.md`.
