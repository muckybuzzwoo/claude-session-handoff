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
- **2026-07-01:** added a **no-handoff fallback** to `/session-resume` Step 1. Refines
  Decision 15 ("resume does not read memory, it auto-loads each session") — that's only
  true for the `MEMORY.md` index; the dossier files it links do not auto-load. Empty
  topic list now reads those files + `git log`/`git status` for a short orientation
  briefing instead of a dead end. Read-only, no writes. Added static Section L (4 checks
  → **67/67**). Redeployed.
- **2026-07-01 (later):** verified against `code.claude.com/docs/en/permissions` that the
  "never chain, one call at a time" rule was overstated — sub-command matching for compound
  commands is identical for Bash and PowerShell, on any platform; the actual Windows
  specificity is host-local tooling (a PreToolUse hook) that can hard-block Bash chains
  regardless. Made Step 1 (both commands) and Step 3 (resume) platform-conditional:
  batch via PowerShell (added to both commands' `allowed-tools`) or split on `win32`,
  chain freely elsewhere. Added a README note that the topic argument also skips
  handoff's confirmation round-trip. Added static Section M (4 checks → **71/71**).
  Redeployed.
- **2026-07-02:** repo made public (`github.com/muckybuzzwoo/claude-session-handoff`) —
  checked first for secrets/personal paths in tracked files (none found; `buzzwoo` mentions
  are non-sensitive context). Then extended Step 7a of `/session-handoff`: it now also
  scans for *feedback*-type learnings (a correction the user gave, or an approach they
  confirmed worked), not just project facts. If a candidate reads as a persistent rule for
  how to work rather than a fact to recall, 7a flags it and points to `/revise-claude-md`
  instead — `/session-handoff` never edits CLAUDE.md itself, that stays the dedicated
  skill's job. Added a `CLAUDE.md:` confirm line (shown only when flagged) + static
  Section N (4 checks → **75/75**). Redeployed.
- **2026-07-03 (critical re-review + fixes):** full design + clara re-review (handoff B
  50/60, resume A 54/60; no contradictions/ordering defects found). Fixes applied:
  (a) **invocation policy corrected** — since the commands→skills merge, command files are
  model-invocable by default, so "manual-only, structurally guaranteed" (Decision 1) was
  wrong; new policy per user decision: explicit request (slash OR plain text) runs it,
  Claude may *suggest* a handoff at session end, never executes unasked — encoded in both
  descriptions + an "Invocation policy" section; (b) **staleness tree check fixed** — the
  handoff header now records a `Tree:` porcelain snapshot and resume compares against it
  (dirty-now alone was a systematic false positive), skipping older handoffs without the
  field; (c) **archived-chain fork guard** — handoff Step 2 asks un-archive vs. fresh when
  the slug exists only in `done/`; resume marks `(archived)` in the `--all` picker;
  (d) smaller: compaction cross-check in Step 1, Step-7-after-Step-6 ordering rationale,
  Step 8 single-Bash rationale, Windows-rule consolidation (Hard rules → pointer to Step
  1), PID/port wording for background processes, extension points in both Customizing
  sections. Added static Section O (10 checks → **85/85**). Redeployed.
- **2026-07-03 (release):** published **v0.1.0** on GitHub — tag `v0.1.0` on `b66a47a`,
  release notes cover commands, features, test coverage, known limitations
  (`github.com/muckybuzzwoo/claude-session-handoff/releases/tag/v0.1.0`). Added
  `CHANGELOG.md` mirroring the notes in-repo.
- NOT yet runtime-tested in a real project (sandbox-tested only).

## Next

- Runtime test — see README → Testing.
- If it proves useful: propose to the buzzwoo-standard maintainer for inclusion next to
  `/park` (then switch the store path to a buzzwoo convention + integrate resume into
  `/resume-bw`).

## Conventions

- Windows 11, no WSL: create files via the Write tool; edit `.gitignore` via Read+Edit. On
  `win32`, batch read-only checks via the PowerShell tool where available (some Windows
  setups hard-block chained Bash calls even when every sub-command is approved) or fall
  back to single Bash calls; on macOS/Linux a single chained Bash call is fine — see plan
  Decision 18 for the verified reasoning.
- Commands are **user-driven** by design: explicit request (slash command or plain-text
  ask) runs them; Claude may *suggest* a handoff when a session winds down but never
  executes one unasked. Since the commands→skills merge they are model-invocable at the
  harness level — the never-unasked rule lives in each command's description and
  "Invocation policy" section, not in the file format (see plan addition 20).
