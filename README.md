# Session Handoff — personal Claude Code commands

Two manual slash-commands for **solo session continuity**: save where you are, then pick
the work back up in a fresh session — same topic, full context, nothing lost.

- **`/session-handoff [topic] [--done]`** — capture the current session into a structured,
  resumable handoff file, then stop.
- **`/session-resume [topic] [--all]`** — choose the right handoff and continue.

They are **manual only** (no auto-trigger), so they never collide with other
skills/commands.

## Why these exist

Claude Code starts every session with an empty context window. For a solo dev who returns
to the *same topic* hours or days later, you want a precise, controllable snapshot — not an
always-on memory system. These commands synthesize the best existing patterns:

| Borrowed from | Idea |
|---|---|
| Nate Herk (session-handoff) | Strict schema + hard rules: running state, verification commands, absolute paths, "never invent state" |
| Matt Pocock (handoff) | "Suggested skills" section, reference artifacts by path (don't duplicate), secret convention |
| REMvisual (claude-handoff) | Sequence chain-linking — continue the same topic across many sessions |
| buzzwoo `/park` | File persistence (survives `/clear`) |

## Install / deploy

Claude Code loads personal commands from `~/.claude/commands/`. Copy the two files there:

```powershell
Copy-Item .\commands\session-handoff.md "$env:USERPROFILE\.claude\commands\session-handoff.md" -Force
Copy-Item .\commands\session-resume.md  "$env:USERPROFILE\.claude\commands\session-resume.md"  -Force
```

Then restart / reload Claude Code so the new commands are registered.

## Usage

### Save a session
```
/session-handoff checkout-bug
```
Writes `.claude/session-handoffs/checkout-bug_01.md` in the **current project** (gitignored
automatically). Run it again later on the same topic → `checkout-bug_02.md`, carrying the
still-open context forward so the newest file is always the complete picture.

No topic given? The command shows existing topics + a branch-derived suggestion and asks
you to confirm — so you never accidentally split one topic into two chains. Passing the
topic directly (as above) skips that confirmation round-trip.

Before it stops, the handoff runs a **closing reflection** (propose-only, never automatic):
it surfaces any *durable* fact worth saving to Claude memory, proposes a concrete update to
a plan that's in play (including a superpowers `docs/superpowers/plans/…` plan), and offers
to refresh any project doc this session left stale (a `README`, a `docs/*.md`, a
`KNOWN_LIMITATIONS.md`). It shows each to you verbatim first; you approve each; nothing is
written silently.

### Resume
```
/session-resume
```
Lists your topics (most recent first), you pick one, it loads the latest handoff and reads any
decision/plan/spec files it links (so full roadmaps and rejected options come back, not just the
handoff's summary), warns if it looks stale (older than 7 days / branch changed), and proposes the
single next action.
Pass a topic to skip the picker: `/session-resume checkout-bug`.

No topics yet? Instead of a dead end, it reads your Claude memory's linked dossier files
(not the `MEMORY.md` index — that's already loaded every session) plus recent git
activity, gives you a short orientation briefing, and points you to `/session-handoff` to
start your first real one.

### Close a topic
```
/session-handoff checkout-bug --done
```
Archives the whole chain to `.claude/session-handoffs/done/`. Archived topics are hidden
from `/session-resume` unless you pass `--all`.

## Where files live

```
<your project>/.claude/session-handoffs/
├── checkout-bug_01.md
├── checkout-bug_02.md      # same topic, next session (carry-forward)
├── auth-refactor_01.md
└── done/                   # archived via --done
```

All gitignored — the command adds `.claude/session-handoffs/` to `.gitignore` on first
run. Only that path is ignored; your committed `.claude/plans/` are untouched.

## Where they sit in the workflow

```
/new-cycle ─►[ code  ⇄  /session-handoff  ···  /session-resume ]─► /end-cycle
   (plan)         (pause / save)         (continue)           (commit/MR)
```

They live in the **pause/resume** middle of a task — they do not replace planning
(`/new-cycle`) or finishing (`/end-cycle`). See `lifecycle.html` for the visual.

## Testing

**Automated (static):** `pwsh -File .\tests\validate-commands.ps1` validates the command
files' structure, frontmatter, step numbering, cross-references, and source==deployed
parity (exit 0/1, no dependencies). See `tests/README.md`.

**Automated (behavioural, subagent-driven):** `tests/behavioral/` has Claude dispatch
subagents that execute the commands in an isolated sandbox (fresh handoff → carry-forward →
resume), then `verify-artifacts.ps1` asserts on the produced artifacts (26 checks). It
proves the runtime properties — Step 7 propose-only, carry-forward, staleness, read-only —
that a static test can't. A focused sub-test, `tests/behavioral/depth-recovery/` (15 checks),
additionally proves the `[READ-AT-RESUME]` contract: that resume actually opens the decision/
plan files a handoff links and folds their depth (full roadmap, rejected options) into the
summary — instead of parroting the compressed handoff text. See `tests/behavioral/README.md`
to re-run.

**Manual spot-check (behavioural):**

1. In any project: `/session-handoff test-a` → check the file + the `.gitignore` entry.
2. `/session-handoff test-b`, then `/session-handoff test-a` again → `_02` + carry-forward + `Previous:` link.
3. New session: `/session-resume` → pick test-a / test-b → staleness note shows correctly.
4. `/session-handoff test-b --done` → moved to `done/`; hidden from `/session-resume`, shown with `--all`.
5. `git status` → handoffs do not appear.
6. In a session that produced a durable decision and/or touched a plan: `/session-handoff …` → it offers a memory candidate (shown verbatim) and/or a plan-update proposal, and writes neither without your OK.

## Design rationale

Full decision log (12 grilled decisions) lives in `plan/session-handoff-plan.md`.
Windows-safe throughout: Write tool for files, Read+Edit for `.gitignore`. On Windows,
Step 1's read-only checks batch via the PowerShell tool (or fall back to one Bash call at
a time if that's unavailable); on macOS/Linux a single chained Bash call is fine — see
"Safety / Windows" in each command for why.
