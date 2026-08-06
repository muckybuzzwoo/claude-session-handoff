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

- `plan/` holds **two** design documents, not one: `session-handoff-plan.md` (the original
  grilled design, 12 decisions + post-design additions 13–20) and
  `token-optimization-plan.md` (the v0.2.0 token-aware loading design).
- The commands contain **platform-conditional** execution paths (PowerShell batching on
  `win32` hosts that hard-block chained Bash, plain chained Bash elsewhere). This looks like
  redundancy but is deliberate — the verified reasoning is plan Decision 18. Do not collapse
  it into one branch.

## Testing

Run `pwsh -File .\tests\validate-commands.ps1` after changing and deploying a command file —
static structure, frontmatter, step numbering, cross-references, and source==deployed parity
(exit 0/1, no dependencies). Runtime behaviour is covered by `tests/behavioral/`, where
Claude dispatches subagents that execute the commands in a sandbox and `verify-artifacts.ps1`
asserts on the output. Suite contents, check counts and how to re-run: `tests/README.md` +
`tests/behavioral/README.md`.

## Status

**v0.3.0 released** (2026-07-29), deployed, all static checks green. Validated in a real
project — the token-aware loading held up on a 98 KB file behind a bare `[READ-AT-RESUME]`
tag (~55k tokens avoided).

- Released versions and their contents: `CHANGELOG.md`
- Why things are the way they are, incl. rejected alternatives: `docs/decision-log.md`
- Visual explainer (open in a browser): `docs/how-it-works.html`

## Next

- No open work item.
- If it proves useful: propose to the buzzwoo-standard maintainer for inclusion next to
  `/park` (then switch the store path to a buzzwoo convention + integrate resume into
  `/resume-bw`).

## Invocation policy

The commands are **user-driven** by design: explicit request (slash command or plain-text
ask) runs them; Claude may *suggest* a handoff when a session winds down but never executes
one unasked. Since the commands→skills merge they are model-invocable at the harness level —
the never-unasked rule lives in each command's description and "Invocation policy" section,
not in the file format (see plan addition 20).
