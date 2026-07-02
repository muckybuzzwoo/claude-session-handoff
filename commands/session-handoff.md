---
description: Save the current session as a structured, resumable handoff. Run only on the user's explicit request — slash command or plain-text ask both count; you may SUGGEST a handoff when a session winds down, but never run it unasked. Writes to .claude/session-handoffs/, then stops. Resume later with /session-resume.
argument-hint: "[topic-slug] [--done]"
allowed-tools:
  - Bash
  - PowerShell
  - Read
  - Write
  - Edit
  - Glob
  - AskUserQuestion
---

# Session Handoff

Capture THIS session into a structured, **resumable** handoff document so a fresh
session can continue the **same topic** with full context — then **stop**. Personal
continuity tool: the file is local to the project and gitignored.

Pick it up later with `/session-resume`.

**Invocation policy:** run this only when the user asks for it — the slash command or an
explicit plain-text request ("save a handoff") both count. When a session is clearly
winding down you may *suggest* running it; never execute it unasked.

## Arguments

- `[topic]` — optional topic slug, the chain key (e.g. `/session-handoff checkout-bug`).
- `--done` — close a topic: optionally write a final handoff, then archive the whole
  chain to `.claude/session-handoffs/done/`.

## HARD STOP

After writing, you are finished. Do **not** implement, explore code, say
"while we're here…", or suggest next steps beyond the handoff's own "→ Pick up here".
(The closing reflection in Step 7 — surfacing memory facts, plan updates, and stale-doc
updates — is part of *capturing* the session, not continuing the work; it does not breach
this stop.)

## Workflow

### Step 1 — Gather context (silent, no output yet)

Synthesize from THIS session only — no history audit (`git log`, `git diff HEAD~n`) and
no broad filesystem sweep. The read-only status/branch calls below are fine:

- Date, branch, working tree: on `win32`, one batched PowerShell call if that tool is
  available (`Get-Date -Format yyyy-MM-dd`, `git rev-parse --abbrev-ref HEAD`, `git status
  --porcelain`, chained with `;`), or three separate Bash calls — some Windows setups
  block chained Bash calls (`&&`, `||`, `;`) even when every sub-command is approved.
  Other platforms (macOS/Linux): no such restriction observed — a single chained Bash
  call is fine: `date +%Y-%m-%d && git rev-parse --abbrev-ref HEAD && git status
  --porcelain`. Ignore git errors if not a repo. Keep the `--porcelain` output: it fills
  the template's `Tree:` header field, which `/session-resume` compares for staleness.
- Background processes started via `run_in_background` — record what outlives this
  session: the command, PID/port, and how to kill or restart it (shell IDs alone die with
  the session).
- Open TodoWrite items (in-progress / pending).
- Files you created or modified this session (you know them — don't grep to rediscover);
  record them as **absolute paths**. Exception: if this session was compacted and you are
  not certain the list is complete, cross-check it against the `git status --porcelain`
  output you just collected and mark any remaining uncertainty explicitly in the handoff
  — never reconstruct the list from guesswork.
- If this session used superpowers `brainstorming` / `writing-plans`, their **committed**
  spec/plan live under `docs/superpowers/specs/` and `docs/superpowers/plans/` — you know
  them from this session, so record their absolute paths (for the Reference section and
  Step 7b). Don't sweep for them.
- Unresolved questions raised this session.

### Step 2 — Determine topic + sequence

1. Store path is `.claude/session-handoffs/` relative to the project root (cwd).
2. List existing topics: Glob `.claude/session-handoffs/*_*.md`; derive the set of
   `{slug}` prefixes (strip the `_NN.md` suffix). Ignore the `done/` subfolder.
3. **Topic given as argument:** slugify it (lowercase; non-alphanumeric → `-`; trim `-`).
   If the slug matches a chain that exists **only** in `done/` (archived via `--done`),
   do not silently start a new `_01` next to it — ask (AskUserQuestion): **un-archive**
   (move that chain's files back out of `done/` with single `git mv`/`mv` calls, then
   continue at its highest NN+1) or **start fresh** at `_01`.
4. **No argument → propose + confirm** (prevents accidentally forking a chain under a
   slightly different slug). Use AskUserQuestion with options:
   - one per existing topic — label `continue: {slug}`,
   - a fresh suggestion derived from the branch name or active plan file — label
     `new: {suggested-slug}`,
   - (the user can pick "Other" to type a different new slug).
5. **Sequence:** among `.claude/session-handoffs/{slug}_*.md`, take the highest `NN`
   and add 1, zero-padded to two digits. None exist → `01`.

### Step 3 — Carry-forward (only when NN ≥ 02)

Read the previous file `.claude/session-handoffs/{slug}_{NN-1}.md`. Carry forward and
**update** the forward-looking sections so the new file is self-sufficient: Key files,
Running state, Verification, Suggested skills, Deferred & open questions, "→ Pick up
here". Keep "Decisions & what shipped" **additive** (append this session's; don't drop
prior decisions). Set the header `Previous:` to the prior filename.

### Step 4 — Secrets (convention + warn, never auto-rewrite)

Never write secret **values**. Reference *where* creds live (e.g. "token in `.env`"),
not the value itself. If an obvious secret pattern (API key, token, password, private
key) appears in your drafted content, **warn the user** and ask them to confirm or
rephrase before writing. Do not silently redact.

### Step 5 — Ensure .gitignore (automatic, once)

The store must stay out of git. Read the project-root `.gitignore`:

- Exists but lacks a line matching `.claude/session-handoffs/` → append that line (Edit) and report it.
- Does not exist → create it (Write) containing that line, and report it.
- Not a git repository → skip silently.

Ignore **only** `.claude/session-handoffs/` — never all of `.claude/` (it holds
committed `plans/`).

### Step 6 — Write the handoff

Fill the template below and write via the Write tool to
`.claude/session-handoffs/{slug}_{NN}.md`. The Write tool creates parent directories —
do not run `mkdir`.

### Step 7 — Closing reflection (propose-only; never auto-write)

The one place this command touches stores **other** than the handoff file. Same rule for
every check: **detect → show the exact proposed content → ask → write only on confirm.**
If nothing qualifies, skip silently. Rule of thumb: **handoff = what I was doing (verbs);
memory = what stays true (nouns).** These writes deliberately happen *after* Step 6 — the
handoff artifact is secured first; what gets written here is recorded in Step 9's confirm
block, not retrofitted into the handoff file.

**7a — Durable facts & learnings → Claude memory.** Scan THIS session for anything
*durable* — true beyond this one topic: a project constraint, an approach that was tried
and rejected (with why), a user preference, an external reference (URL/ticket), or a
**feedback-type learning** (a correction the user gave about how to work, or an unusual
approach they confirmed worked). Transient state — test status, next step, TODOs — is
**not** a memory candidate; it stays in the handoff.

- None qualify → skip silently.
- Otherwise, for each candidate **draft the exact entry** (slug, one-line description,
  type — `user`/`feedback`/`project`/`reference` — body) and **show it to the user
  verbatim**. Ask per candidate: save / edit / skip.
- On confirm: write the fact file into the project's Claude memory dir and add its one-line
  pointer to `MEMORY.md`, following the format already in use there (frontmatter + index
  line). If the project has **no** Claude memory dir, do **not** create one — just leave the
  candidate printed in your output so the user can decide later.
- If a candidate reads as a **persistent rule for how to work** (belongs in CLAUDE.md's
  instructions, not a fact to recall) rather than a one-off learning: save it to memory as
  normal (type `feedback`), **and separately** append this flag to your output: "→ this
  looks like a CLAUDE.md rule, not just a memory fact — consider running
  `/revise-claude-md` after this handoff." The memory save and the flag are independent —
  skipping the memory candidate does not remove the flag, and vice versa. **Never edit CLAUDE.md directly from this command.**

**7b — Plan drift → plan file.** Only if a plan is in play (referenced in the handoff's
"Reference → Plan", named in args, or worked on this session).

- Compare this session's decisions/progress against the plan. If they advanced it (steps
  done), diverged from it (a decision now contradicts the plan), or revealed a gap →
  surface a **concrete proposed edit** (which lines, what changes) and show it. Ask:
  apply / skip.
- On confirm: Edit the plan surgically, matching its existing style — never rewrite
  wholesale. Plan unchanged by this session → skip silently.

**7c — Doc drift → project docs.** Project-level explanatory or status docs whose subject
this session changed — e.g. `README`, `docs/*.md`, an HTML explainer, a
`KNOWN_LIMITATIONS.md` / `FORK_NOTES.md`-style note. Scope is **only** the docs you already
recorded in Step 1 as created/modified this session, plus any such doc whose described
behavior this session changed (you know it — **don't sweep** the repo for more). Excludes
source code, plans (7b owns those), specs (reference-only), and memory (7a owns that).

- A doc you *created* this session is already current → skip. A touched/related doc that
  still matches reality → skip silently.
- If this session's work made one stale — a described limitation now fixed, a documented
  step now done, a behavior now different → surface a **concrete proposed edit** (which
  lines, what changes) and show it. Ask: apply / skip.
- On confirm: Edit the doc surgically, matching its existing style — never rewrite
  wholesale.

### Step 8 — `--done` handling

If `--done` was passed:

1. If there is session state worth recording, offer to write a final `_{NN}` handoff first (Steps 1–7).
2. Archive the whole chain `.claude/session-handoffs/{slug}_*.md` into
   `.claude/session-handoffs/done/`, using **single Bash calls** (one per command, never
   chained — deliberate even where Step 1 batches via PowerShell: these are writes, not
   read-only checks; keep each one an individually observable call):
   - create the target dir once: `mkdir -p .claude/session-handoffs/done`
   - per file: `git mv <file> .claude/session-handoffs/done/` in a git repo, otherwise
     `mv <file> .claude/session-handoffs/done/`.
3. Report what was archived.

### Step 9 — Confirm + STOP

```
Handoff saved: <absolute path>
Memory: <fact slug(s) written> | "—"
Plan updated: <plan path> | "—"
Docs updated: <doc path(s)> | "—"
CLAUDE.md: suggested `/revise-claude-md` | "—"
Resume: /session-resume {slug}  —  or read <absolute path>
```

(Show the `Memory:` / `Plan updated:` / `Docs updated:` lines only when Step 7 actually
wrote something. Show the `CLAUDE.md:` line only when 7a flagged a rule-like learning.)

Then **STOP**.

## Document template

```markdown
# Session Handoff: {Topic} (seq {NN})

**Date:** {YYYY-MM-DD}  **Branch:** {branch or "—"}  **Previous:** {slug}_{NN-1}.md | "—"
**Tree:** {`git status --porcelain` summary at handoff time, e.g. "3 dirty: src/a.ts, src/b.css, README.md" | "clean" | "—" if not a repo}

## What this is about / where it started
{2–3 sentences}

## Decisions & what shipped (this session, additive)
- {decision/change} — {why, and where it lives (absolute path)}

## Key files (absolute paths) — read these first
- `{absolute path}` — {why}

## Running state
- Background processes: {command + PID/port + kill/restart command — shell IDs die with the session} | "none"
- Dev servers / ports: {url + port} | "none"
- Worktrees / branches: {paths} | "none"

## Verification — how to confirm things still work
- `{command}` — {expected outcome}

## Suggested skills for the next session
- {skill name} — {why}

## Deferred & open questions
- Deferred: {item} — {why}
- Open: {question} — {context}

## Reference (do NOT duplicate — link by path/URL; tag substantial targets)
- Plan: `{path}` [READ-AT-RESUME] (e.g. `docs/superpowers/plans/…`) · Spec/PRD: `{path}` [READ-AT-RESUME] (e.g. `docs/superpowers/specs/…`) · MR/issue: {url}

## → Pick up here
{exactly one next action}

---
Resume: `/session-resume {slug}`  —  or read {absolute path}
```

## Hard rules

- `[READ-AT-RESUME]` tag: append it to any Reference- or Key-files link whose target holds
  the FULL decision record, roadmap, rejected options, or spec — NOT just a pointer. It
  signals `/session-resume` to open that file and fold its substance (rejected options
  included) into the summary instead of trusting this handoff's compression. Omit it for
  shallow pointers (MR/issue URL, a file that merely needs opening later).
- Absolute paths everywhere (the next session may have a different cwd).
- Never invent state — if a section has nothing, write "none"; never omit a section.
- No hype, no emojis. Terse and concrete: paths, commands, shell IDs, decisions.
- Synthesize THIS session (+ carry-forward from the previous file only). No `git log`
  audit, no broad Glob sweeps.
- Windows (`win32`): write handoff files via Write (no `mkdir` needed); edit `.gitignore`
  via Read+Edit; for the `--done` archive use single Bash `mv`/`git mv` calls. Platform
  rules for batching the read-only checks live in Step 1 — stated once there, not
  repeated here.

## Customizing

- Store path: change the `.claude/session-handoffs/` references (Steps 2, 5, 6, 8) to relocate the store.
- Handoff sections: edit the "Document template" block above.
- Extension points: a new closing-reflection check goes in as Step 7d — copy 7a–7c's
  shape (detect → show exact content → ask → write on confirm) and add its line to Step
  9's confirm block. The 7a fact types (`user`/`feedback`/`project`/`reference`) mirror
  the Claude memory taxonomy — extend them there, not here.

## Error handling

| Situation | Response |
|-----------|----------|
| Empty session (nothing to hand off) | Tell the user; write nothing. |
| Not a git repository | Skip branch/status/.gitignore steps; proceed. |
| `--done` but topic not found | List existing topics; ask which. |
| Secret pattern detected | Warn; ask to confirm/rephrase before writing. |
