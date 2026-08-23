# Session Handoff — personal Claude Code commands

Two manual slash-commands for **solo session continuity**: save where you are, then pick
the work back up in a fresh session — same topic, full context, nothing lost.

- **`/session-handoff [topic] [--done]`** — capture the current session into a structured,
  resumable handoff file, then stop.
- **`/session-resume [topic] [--all]`** — choose the right handoff and continue.

They are **user-driven**: invoke them with the slash command or by asking in plain text
("save a handoff" works just as well as `/session-handoff`). Claude may *suggest* a
handoff when a session winds down, but never runs one unasked. (Note: since Claude Code
merged commands into skills, command files are model-invocable by default — the
never-unasked rule is enforced by each command's description and invocation-policy
section, not by the file format.)

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

## What a handoff looks like (v0.4.0)

The file opens with what the next session needs in order to **act**, and only then with what it
needs in order to **understand**:

```markdown
**Date:** …  **Branch:** …  **Previous:** …_01.md
**Tree:** clean
**Format:** 2

## Status
- **Where it stands:** {one sentence about the topic}
- **This session:** {one sentence about what changed}

## → Pick up here
{exactly one next action — it exists once in the file, and only here}

## Open work
- Open: {item} — {context}
- Done: {item} — {closed this session, so it leaves the chain by being written, not by vanishing}
- Carried unchanged: 14 items — see {topic}_01.md
```

Then the retrospective: what this is about, decisions, key files, running state, verification,
suggested skills, reference.

Two rules make open items survive a long chain. **One item per line**, so an item can be
pointed at and therefore closed. And **the carry count must add up** — carried plus closed plus
written-out can never fall short of what the previous file held, and the shortfall is exactly
the number of items that went missing. Checking that needs one hop, not a walk through the whole
chain, and `tests/compat-old-chain.ps1` does it for you.

Older handoffs keep working as they are: a missing `Format:` field means the earlier layout,
nothing is migrated, and no existing file is ever rewritten.

## Install / deploy

Claude Code loads personal commands from `~/.claude/commands/`. Copy the two files there:

```powershell
Copy-Item .\commands\session-handoff.md "$env:USERPROFILE\.claude\commands\session-handoff.md" -Force
Copy-Item .\commands\session-resume.md  "$env:USERPROFILE\.claude\commands\session-resume.md"  -Force
```

Then restart / reload Claude Code so the new commands are registered. **A session that is
already running keeps the version it loaded at start** — observed directly on 2026-08-21, when
a session wrote a handoff ten minutes after a redeploy and still used the previous format. So
copying the files is not enough for open sessions.

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
it surfaces any *durable* fact or **feedback-type learning** (a correction you gave, or an
approach you confirmed worked) worth saving to Claude memory — flagging rule-like learnings
with a pointer to `/revise-claude-md` instead of writing to CLAUDE.md directly — proposes a
concrete update to a plan that's in play (including a superpowers `docs/superpowers/plans/…`
plan), and offers to refresh any project doc this session left stale (a `README`, a
`docs/*.md`, a `KNOWN_LIMITATIONS.md`). It shows each to you verbatim first; you approve
each; nothing is written silently. On finishing it always reminds you that **anything you
do after the handoff is invisible to the next resume** — run it again to capture continued
work as the next `_NN`.

### Resume
```
/session-resume
```
Lists your topics (most recent first), you pick one, it loads the latest handoff and pulls the
depth out of the files it links (full roadmaps and rejected options come back, not just the
handoff's summary) under the loading rules described just below, warns if it looks stale
(older than 7 days, branch changed, or the
working tree moved compared to the snapshot recorded in the handoff), and proposes the
single next action.
Pass a topic to skip the picker: `/session-resume checkout-bug`.

**It loads those linked files frugally** so a resume stays cheap even when a plan has grown
large: a link tagged to one heading (`[READ-AT-RESUME: <heading>]`) pulls only that section,
an untagged big file is *not* read whole (you get its outline and an offer to open it), and
only a fully-tagged file is loaded in full. When you save a handoff, big files get their
essence written into the handoff itself and are linked lazily — and if a large plan has
finished sections piling up, the handoff can offer to archive them into a `-DONE.md` sibling
(you confirm; nothing is deleted, open to-dos never move). Old handoffs written before this
still resume fine — no migration needed.

It also **cross-checks the briefing against your Claude memory index** and flags any
contradiction (a handoff is a point-in-time snapshot; memory may hold a newer truth) —
naming both, resolving neither silently. And if the handoff recorded that the next step
continues in **another** chain or repo (a `Continue first in:` pointer), resume surfaces
that at the top — it prints the pointer, it never opens the other project.

No topics yet? Instead of a dead end, it reads your Claude memory's linked dossier files
(not the `MEMORY.md` index — that's already loaded every session) plus recent git
activity, gives you a short orientation briefing, and points you to `/session-handoff` to
start your first real one.

### Close a topic
```
/session-handoff checkout-bug --done
```
Archives the whole chain to `.claude/session-handoffs/done/`. Archived topics are hidden
from `/session-resume` unless you pass `--all` (they show an `(archived)` marker in the
picker). Running `/session-handoff` on an archived topic asks whether to un-archive the
chain or start fresh — it never silently forks a second chain next to the archive.

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
(`/new-cycle`) or finishing (`/end-cycle`). See `docs/how-it-works.html` for the visual.

## Testing

**Automated (static):** `pwsh -File .\tests\validate-commands.ps1` validates the command
files' structure, frontmatter, step numbering, cross-references, and source==deployed
parity (236 checks, exit 0/1, no dependencies). See `tests/README.md`.

**Automated (mutation, no AI):** `pwsh -File .\tests\mutation-check.ps1` deletes one block of a
command file at a time and re-runs the static suite, then reports which deletions broke no
check at all. A block nothing fails on has no coverage. Currently 26 of 26 blocks are covered.
This is the instrument that measures whether the static suite has teeth, instead of guessing
from how its checks are written.

**Automated (behavioural, subagent-driven):** `tests/behavioral/` has Claude dispatch
subagents that execute the commands in an isolated sandbox (fresh handoff → carry-forward →
resume), then `verify-artifacts.ps1` asserts on the produced artifacts (30 checks). It
proves the runtime properties — Step 7 propose-only, carry-forward, staleness, read-only —
that a static test can't. Two focused sub-tests add runtime proof of the deep-link
behaviour: `tests/behavioral/depth-recovery/` (15 checks) proves resume actually opens the
decision/plan files a handoff links and folds their depth (full roadmap, rejected options)
into the summary — instead of parroting the compressed handoff text; and
`tests/behavioral/load-discipline/` (21 checks) proves the token-aware loading — a
section-anchored link pulls only that section, and an untagged big file is peeked + offered,
never read whole. Two more cover v0.4.0: `tests/behavioral/format-boundary/` (26 checks)
writes the first new-format handoff on top of an old-format predecessor shaped like the
hardest real file, and `tests/behavioral/old-format-resume/` (gate G1, 43 checks) resumes
five *real* pre-v0.4.0 handoffs, one per structural deviation, and proves every one of them
is byte-identical afterwards. And `tests/behavioral/carry-hop/` (20 checks) covers the READ
half of the carry rule: three items reachable only through the `Carried unchanged:` pointer
must show up in the briefing, and an item closed with a `- Done:` bullet must not come back as
open work. Its verifier is self-tested without an LLM via `carry-hop/selftest.ps1`, which feeds
it a known-good and a known-bad response and asserts it accepts one and rejects the other.
See `tests/behavioral/README.md` to re-run.

The scenario prompts were rewritten on 2026-08-22 to stop restating the rule under test. Three
of them used to spell out the expected answer, so they measured whether the subagent followed
the prompt rather than whether the command works. The first run after that change is the first
honest measurement, and it may fail where the leaked version passed.

**Automated (compatibility, no AI):** `pwsh -File .\tests\compat-old-chain.ps1 -Path <handoff-dir>`
scans any existing chain and checks whether it still adds up — the format census, the open-item
count, how many items hide inside collapsed or wrapped lines, and the carry arithmetic. Run it
before and after a format change so "nothing was lost" is a measurement. One limit worth knowing:
exit 0 means *no detectable* loss, because new work can mask a lost item. The scanner does not
hide that — it prints how big the doubt is, per file pair and for the whole chain, and `-Strict`
refuses to pass while any doubt exists. The gap is structural rather than a bug. `tests/README.md`
plus plan §15 explain it and cost the fix.

**Manual spot-check (behavioural):**

1. In any project: `/session-handoff test-a` → check the file + the `.gitignore` entry.
2. `/session-handoff test-b`, then `/session-handoff test-a` again → `_02` + carry-forward + `Previous:` link.
3. New session: `/session-resume` → pick test-a / test-b → staleness note shows correctly.
4. `/session-handoff test-b --done` → moved to `done/`; hidden from `/session-resume`, shown with `--all`.
5. `git status` → handoffs do not appear.
6. In a session that produced a durable decision and/or touched a plan: `/session-handoff …` → it offers a memory candidate (shown verbatim) and/or a plan-update proposal, and writes neither without your OK.

## Design rationale

Why things are the way they are, including rejected alternatives, lives in
`docs/decision-log.md`. The three design records behind it are `plan/session-handoff-plan.md`
(the original 12 grilled decisions), `plan/token-optimization-plan.md` (token-aware loading)
and `plan/readability-preflight-plan.md` (the v0.4.x readability work). A plan states the
design as designed, not as it ended up, so prefer the decision log when the two differ.
Windows-safe throughout: Write tool for files, Read+Edit for `.gitignore`. On Windows,
Step 1's read-only checks batch via the PowerShell tool (or fall back to one Bash call at
a time if that's unavailable); on macOS/Linux a single chained Bash call is fine — see
"Safety / Windows" in each command for why.
