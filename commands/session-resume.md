---
description: Pick and load the right session-handoff to continue a topic in a fresh session (manual); falls back to a memory+git orientation briefing if none exist yet. Reads from .claude/session-handoffs/. Pairs with /session-handoff.
argument-hint: "[topic-slug] [--all]"
allowed-tools:
  - Bash
  - PowerShell
  - Read
  - Glob
  - AskUserQuestion
---

# Session Resume

Re-orient to a previously saved session-handoff and continue the **same topic** in a
fresh session. Pairs with `/session-handoff`. Read-only on the handoff store.

## Arguments

- `[topic]` — optional topic slug to load directly (its highest sequence).
- `--all` — also include archived (`done/`) topics in the picker.

## Workflow

### Step 1 — Scan + group

Glob `.claude/session-handoffs/*_*.md` for active topics. If `--all` is set, **also**
Glob `.claude/session-handoffs/done/*_*.md` and merge the results — otherwise exclude
`done/`. Group by `{slug}`; for each topic take the highest `NN`, and read its header
`Date` plus the first line of "What this is about". Sort topics by file mtime, most
recent first.

If none are found, run the **Fallback — no-handoff orientation** below instead of
stopping cold.

**Fallback — no-handoff orientation (memory + git briefing).** This project has no
session-handoff yet — orient from what already exists instead of a dead end:

- The Claude memory index (`MEMORY.md`) is already auto-loaded into context every
  session — do **not** re-read it.
- Glob `~/.claude/projects/*/memory/MEMORY.md` for the current project to confirm the
  memory directory, then Read the individual files its index lines point to. Those are
  NOT auto-loaded and hold the durable facts/decisions worth resurfacing.
- Recent activity: `git log --oneline -10` and `git status --porcelain` (skip if not a
  git repo).
- Present a short briefing — durable facts/decisions from the memory files, recent
  commits/changes — and suggest `/session-handoff <topic>` going forward so the next
  resume has a real handoff to load instead of this fallback.
- Then stop, same as Step 5. This path never writes to `.claude/session-handoffs/` or to
  memory — read-only orientation, not a handoff substitute.

### Step 2 — Select

- **Topic argument given:** load that slug's highest sequence directly.
- **Otherwise:** AskUserQuestion listing the grouped topics — label
  `{slug} — seq {NN}, {date}`, the one-line summary as the description. User picks one.

### Step 3 — Staleness check (non-blocking heads-up)

Surface a short note if ANY of these hold (never block):

- The handoff `Date` is more than 7 days before today — run `date +%Y-%m-%d` (Bash) to
  get today and compare to the handoff header's `Date:` field.
- Current branch (`git rev-parse --abbrev-ref HEAD`) ≠ the handoff's `Branch`.
- The working tree has changed since (`git status --porcelain` non-empty) — best-effort.

Example: `Note: this handoff is 12 days old and the branch differs (was 'x', now 'y') — treat state as possibly stale.`

### Step 4 — Load + summarize (follow the deep links)

1. Read the selected handoff file fully.
2. **Then follow its links.** Any path under "Reference" or "Key files" that is tagged
   `[READ-AT-RESUME]` — or, untagged, is clearly a plan, spec, roadmap, or decision
   record — MUST also be read (Read tool, absolute path). The handoff deliberately does
   NOT duplicate those files, so their depth (full roadmap, rejected options, grilled
   decisions) lives ONLY there. Skip shallow pointers (MR/issue URLs, anything outside
   the project).
3. Summarize from the handoff AND the linked files together: where it left off, key
   files to open first, running state, and the "→ Pick up here" next action. Carry the
   full decisions and roadmap — and **explicitly list rejected options / deliberate
   no-decisions**; do not compress those away. If a detail is too large to inline, point
   to the exact file + section rather than dropping it.
4. Present the next action as a **suggestion**.

### Step 5 — Do not auto-implement

Stop after the summary + suggested next action. Wait for the user to confirm before
doing any work.

## Safety / Windows

- Windows (`win32`): some setups block chained Bash calls (`&&`, `||`, `;`) even when
  every sub-command is already approved. Batch Step 1's fallback and Step 3's checks via
  the PowerShell tool instead, if available, or fall back to one Bash call at a time.
- Other platforms (macOS/Linux): no such restriction observed — a single chained Bash
  call for those same checks is fine.
- Read-only here — never modify or delete handoffs. Archiving is done via
  `/session-handoff <topic> --done`.

## Customizing

- Store path and the 7-day staleness threshold: edit the references in Steps 1 and 3.
- Fallback behavior: edit the "Fallback — no-handoff orientation" block in Step 1.

## Error handling

| Situation | Response |
|-----------|----------|
| No handoffs found | Run the no-handoff fallback (memory + git briefing), then suggest `/session-handoff`. |
| Topic argument not found | List available topics; ask which. |
| Not a git repository | Skip branch/staleness git checks; load anyway. |
| `[READ-AT-RESUME]` link missing/unreadable | Note the gap; summarize from the handoff text and flag that the linked depth couldn't be loaded. |
