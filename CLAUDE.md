# Session Handoff Command — Project Context

Maintenance workspace for two **personal Claude Code slash-commands** that give a solo
developer session-to-session continuity:

- `/session-handoff [topic] [--done]` — save the current session as a structured,
  resumable, gitignored handoff file, then stop.
- `/session-resume [topic] [--all]` — pick + load the right handoff and continue.

This folder is the **source of truth and the shareable package** (for later proposing the
commands to the buzzwoo-standard maintainer). The commands themselves run from a **global**
location — see Deploy below.

## Repository layout

```
session-handoff-command/
├── CLAUDE.md                     # this file
├── README.md                     # user-facing documentation (English)
├── lifecycle.html                # visual: where the commands sit + how they work
├── commands/                     # CANONICAL command sources — edit HERE
│   ├── session-handoff.md
│   └── session-resume.md
├── tests/                        # two test layers
│   ├── validate-commands.ps1     #   static: structure/frontmatter/parity (pwsh, no deps)
│   ├── README.md
│   └── behavioral/               #   behavioral: subagent runs commands in a sandbox
│       ├── setup-sandbox.ps1
│       ├── scenarios/            #   S1 handoff · S2 carry-forward · S3 resume
│       ├── verify-artifacts.ps1
│       └── README.md
└── plan/
    └── session-handoff-plan.md   # final, grilled design (12 decisions)
```

After editing + deploying, run `pwsh -File .\tests\validate-commands.ps1` — it checks
structural invariants AND source==deployed parity (exit 0/1). For runtime behaviour, the
`tests/behavioral/` suite has Claude dispatch subagents that execute the commands in an
isolated sandbox, then `verify-artifacts.ps1` asserts on the output (last run: 26/26 green).
See `tests/README.md` + `tests/behavioral/README.md`.

## Deploy (important)

Claude Code loads personal commands from `~/.claude/commands/`, NOT from this folder.
So `commands/` here is the **source**; deploy by copying to the live location:

```powershell
Copy-Item .\commands\session-handoff.md "$env:USERPROFILE\.claude\commands\session-handoff.md" -Force
Copy-Item .\commands\session-resume.md  "$env:USERPROFILE\.claude\commands\session-resume.md"  -Force
```

**Rule: edit here, then deploy.** Do not edit the live copies directly — they would drift
from this source.

## Where handoff *output* goes (not here)

When `/session-handoff` runs inside some *other* project, its handoff `.md` files are
written to **that project's** `.claude/session-handoffs/` (gitignored) — never into this
maintenance repo.

## Status (2026-06-30)

- Both commands written + deployed to `~/.claude/commands/`.
- Reviewed by `component-reviewer-clara` (B/B). Valid fixes applied: `argument-hint`,
  Bash-based `--done` archive (`mv`/`git mv`), `--all` glob now includes `done/`,
  explicit staleness date calc, absolute-path enforcement. One finding (missing `Glob`)
  was a false alarm — `Glob` was already present.
- **2026-06-30:** added a **closing-reflection step** (now Step 7) to `/session-handoff`,
  renumbering `--done`→8 and confirm→9. Propose-only (show → ask → write on confirm, never
  auto-write): (7a) capture *durable* facts to Claude memory — transient state stays in the
  handoff; (7b) propose a surgical plan update when a plan drifted. Plus Step 1 + template
  awareness of superpowers `docs/superpowers/{specs,plans}/` artifacts (link, never copy;
  detection is artifact-based, not a plugin presence-check). Redeployed.
- **2026-06-30 (later):** added **Step 7c — doc drift** to `/session-handoff`: propose-only
  refresh of project docs the session left stale (`README`, `docs/*.md`, HTML explainers,
  `KNOWN_LIMITATIONS.md`-style notes). Detection limited to Step-1 session-touched files (no
  sweep); excludes source/plans/specs/memory. Added a `Docs updated:` confirm line + 2 static
  checks (now 57/57). Redeployed.
- **2026-06-30 (deep-link fix):** fixed depth loss on resume. The handoff links substantial
  files ("do NOT duplicate") but `/session-resume` Step 4 read **only** the handoff text, so
  full roadmaps, rejected options and grilled decisions in the linked files never surfaced.
  Both sides fixed: handoff now tags substantial Reference/Key-files links with
  `[READ-AT-RESUME]` (+ a Hard-rule defining it); resume Step 4 dereferences those (tagged OR
  obvious plan/spec/roadmap), folds their depth into the summary, and **explicitly lists
  rejected options / deliberate no-decisions**. Added static Section K (6 checks → **63/63**)
  and a focused behavioral sub-test `tests/behavioral/depth-recovery/` (subagent runs
  `/session-resume` against a handoff whose linked plan holds a rejected-option sentinel the
  handoff itself omits — proves resume actually opened the link). Redeployed.
- NOT yet runtime-tested in a real project (sandbox-tested only).

## Next

- Runtime test — see README → Testing.
- If it proves useful: propose to the buzzwoo-standard maintainer for inclusion next to
  `/park` (then switch the store path to a buzzwoo convention + integrate resume into
  `/resume-bw`).

## Conventions

- Windows 11, no WSL: no `&&`/`||`/`;` chaining in Bash; create files via the Write tool;
  edit `.gitignore` via Read+Edit; single `git`/`date` calls.
- Commands are **manual-only** (no auto-trigger) by design — that is a requirement, not a
  gap.
