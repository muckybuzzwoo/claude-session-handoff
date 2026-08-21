---
description: Pick and load the right session-handoff to continue a topic in a fresh session. Run only on the user's explicit request (slash command or plain-text ask), never proactively. Falls back to a memory+git orientation briefing if none exist yet. Reads from .claude/session-handoffs/. Pairs with /session-handoff.
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
`done/`. Remember which topics came from `done/` — they must be visibly marked as
archived in the picker. Group by `{slug}`; for each topic take the highest `NN`, and read
its header `Date` plus the first line of "What this is about". Sort topics by file mtime,
most recent first.

If none are found, run the **Fallback — no-handoff orientation** below instead of
stopping cold.

**Fallback — no-handoff orientation (memory + git briefing).** This project has no
session-handoff yet — orient from what already exists instead of a dead end:

- The Claude memory index (`MEMORY.md`) is already auto-loaded into context every
  session — do **not** re-read it.
- The memory directory's absolute path is usually announced in the system prompt's
  memory section — use that directly. Only if it isn't announced, Glob
  `~/.claude/projects/*/memory/MEMORY.md` and match the current project. Then Read the
  individual files the index lines point to. Those are NOT auto-loaded and hold the
  durable facts/decisions worth resurfacing.
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
  `{slug} — seq {NN}, {date}` (append ` (archived)` for `done/` topics), the one-line
  summary as the description. User picks one. If they pick an archived topic, mention
  that a later `/session-handoff {slug}` will ask whether to un-archive the chain.

### Step 3 — Staleness check (non-blocking heads-up)

Surface a short note if ANY of these hold (never block):

- The handoff `Date` is more than 7 days before today — run `date +%Y-%m-%d` (Bash) to
  get today and compare to the handoff header's `Date:` field.
- Current branch (`git rev-parse --abbrev-ref HEAD`) ≠ the handoff's `Branch`.
- The working tree has **moved since the handoff**: compare current `git status
  --porcelain` against the handoff header's `Tree:` snapshot. A handoff typically
  captures mid-work state, so a dirty tree alone means nothing — flag only a
  *difference* from the recorded snapshot. No `Tree:` field in the header (older
  handoff) → skip this check. **A `Tree:` field written as prose** rather than a porcelain
  summary (real old files do this — some use it to correct the previous handoff) → treat it
  as informational, skip the comparison, and do not manufacture a difference from it.

Example: `Note: this handoff is 12 days old and the branch differs (was 'x', now 'y') — treat state as possibly stale.`

### Step 4 — Load + summarize (follow the links, but don't blind-load)

1. Read the selected handoff file fully.
2. **Then resolve its links** under "Reference" and "Key files". Before reading any
   target, measure its **size in bytes** (`bytes/4` ~ tokens — a short file can still be
   huge; `(Get-Item <path>).Length` on `win32`, or `wc -c`, is enough). Then, per link:
   - **`[READ-AT-RESUME: <heading>]`** (section anchor) → Grep the file for that heading,
     then read **only** that section (a targeted Read with offset/limit down to the next
     heading). State in the briefing that you loaded only that section. Heading not found
     → fall back to reading the file's heading skeleton + note the miss; never blind-load.
   - **`[READ-AT-RESUME]`** (bare tag — this is also the **old handoff format**; keep
     reading it, no migration needed) → load it, but if it is large (`bytes/4` above
     roughly 15k) do **not** swallow the whole file: read its heading skeleton plus the
     sections that bear on the open work, and flag the omission ("loaded headings + §X of
     Y — pull more if needed"). Small tagged files load fully. (Until now only the built-in
     ~25k Read cap kept this from exploding — by accident, not design; this makes it
     deliberate.)
   - **Untagged** links that are clearly a plan, spec, roadmap, or decision record →
     **do not full-load them** (this is exactly where resume cost silently leaks back in).
     Print their **heading skeleton** (table of contents) and **offer**: "linked plan X is
     untagged, ~Yk — load it fully, or just a section?". This is a deliberate change from
     the older full-load-if-it-looks-like-a-plan behaviour: the depth is now carried by the
     essence the handoff inlined, so a blind load is no longer needed.
   - Skip **shallow** pointers: MR/issue URLs, and paths in another repo that merely need
     opening later. **An explicit `[READ-AT-RESUME]` tag outranks this skip** — if the tagged
     path exists and is readable, load it per the rules above even when it sits outside the
     current project, because the handoff's author tagged it deliberately. Tagged but
     unreadable or outside your reach → say so and carry on. Never substitute a size or a
     summary that the handoff's own prose claims for a file you did not open.
   - **`Carried unchanged: {N} items — see {file}` in Open work → resolve exactly ONE hop.**
     Read that file's Open-work section only (the same targeted read as a section anchor) and
     fold its items into the briefing. If that file carries a carry line of its own, do **not**
     walk further: report "{N} items carried, the older ones live in {file}" and stop. Say how
     many items you resolved. Count mismatch, or the file is missing → name both numbers, or
     say the file is gone, and do not guess. Old handoffs have no carry line — then there is
     nothing to resolve and this bullet does not apply.
3. Summarize from the handoff AND what you loaded.

   **Open the briefing with exactly three things, in this order:** where the topic stands
   (one sentence), what the last session changed (one sentence), and the next action. Then
   the open work. **Only after that** the depth: decisions, rejected options, constraints,
   key files, running state, and what you loaded or deliberately did not load.

   **A section the template does not know is not noise.** Real handoffs grow their own
   headings, and one of them may hold the most important content in the file — a
   "low-confidence decisions, CHECK THESE" block, a rejected-options section under a
   different name. Carry such a section, and if it flags doubt or asks to be re-checked,
   surface it **with the open work**, not buried in the depth.

   Carry the full decisions and roadmap — and **explicitly list rejected options /
   deliberate no-decisions**; do not compress those away. This is about *order*, not about
   dropping content: the completeness requirement is unchanged. For anything you did not
   fully load, point to the exact file + section (and the skeleton you printed) rather than
   dropping it.
   - If the handoff carries a **`Continue first in:` cross-chain pointer**, surface it
     prominently at the **TOP** of the briefing, before your own next-action suggestion —
     the real next step lives in another chain/repo. **Print it only; never open or load
     that other project or chain** (that would be a separate, explicit `/session-resume`
     the user runs there).
4. **Reconcile against the memory index.** If a Claude memory index (`MEMORY.md`) is
   already in context (it auto-loads each session), compare your briefing against it.
   **Only when that memory belongs to THIS project** — the index is per project, so
   reconciling a handoff from project A against project B's memory manufactures
   contradictions out of unrelated facts. Different project → skip this step and say so. On
   any contradiction between memory and the handoff — a next step, status, or decision
   that differs — **name BOTH states** with their dates, flag the contradiction, and note
   the newer as the likelier truth (a handoff reflects only its write time; memory may be
   newer or older). **Do not silently pick one** — surface both and let the user resolve.
   Costs nothing (the index is already in context). No memory index present → skip.
5. Present the next action as a **suggestion**.

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
- Extension points: Step 4's link-following heuristic ("clearly a plan, spec, roadmap,
  or decision record") and the fallback's data sources (memory files + git) — edit them
  in place.

## Error handling

| Situation | Response |
|-----------|----------|
| No handoffs found | Run the no-handoff fallback (memory + git briefing), then suggest `/session-handoff`. |
| Topic argument not found | List available topics; ask which. |
| Not a git repository | Skip branch/staleness git checks; load anyway. |
| Old-format handoff (bare `[READ-AT-RESUME]`, no section anchor) | Fully supported — load with the big-file safeguard in Step 4; no migration needed. Old chains (any length) keep working; the new anchor format appears only from the next `/session-handoff` on. |
| `[READ-AT-RESUME]` link missing/unreadable | Note the gap; summarize from the handoff text and flag that the linked depth couldn't be loaded. |
