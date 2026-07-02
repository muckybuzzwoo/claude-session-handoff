# Plan (final, grilled): `/session-handoff` + `/session-resume`

Personal, manual commands to capture a session losslessly and continue the same topic in
a fresh session. Synthesis of Nate Herk (schema/rules), Matt Pocock (suggested-skills +
reference-don't-duplicate + secret convention), REMvisual (sequence chain-linking) and
buzzwoo `/park` (file persistence). Deliberately decoupled from buzzwoo for independent
testing.

## Grilled decisions (12)
1. **Form:** two commands (no auto-trigger, structurally guaranteed; skill upgrade possible later).
2. **Output folder:** `.claude/session-handoffs/` (plural), per project, Claude-native — NOT buzzwoo.
3. **Resume command name:** `/session-resume` (pair like /park ↔ /resume-bw).
4. **File schema:** `{topic-slug}_{NN}.md` (sequence), date in the header.
5. **Chain:** carry-forward — a follow-up sequence reads its predecessor and keeps the
   forward-looking sections current; the newest file is always the complete state.
6. **Topic without argument:** propose + confirm (show existing topics + branch/plan
   suggestion → avoid chain-fork). With an argument: continue/create directly.
7. **.gitignore:** auto-add `.claude/session-handoffs/` + report once (skip silently in non-git).
8. **Staleness (resume):** non-blocking note when date > 7 days OR branch mismatch OR
   working tree moved since.
9. **Secrets:** convention (no values, reference by path) + heuristic warning; no auto-redact.
10. **Self-resume line:** command + absolute path on ONE line.
11. **Lifecycle:** "done" mechanic present.
12. **Done trigger:** `/session-handoff <topic> --done` → archive the chain to
    `.claude/session-handoffs/done/`; `/session-resume` hides `done/` by default, `--all` shows it.

## Command 1: `/session-handoff [topic] [--done]`
1. Gather context (silent): date, branch, `git status --porcelain`, background process
   IDs, open TodoWrite items, files touched THIS session (absolute paths). No broad FS audit.
2. Topic + sequence: with arg → slugify; without arg → list existing topics + branch
   suggestion, confirm. Highest `{slug}_NN` → NN+1; new → `_01`.
3. Carry-forward (NN ≥ 02): read predecessor, carry/update forward-looking sections,
   keep "shipped/decisions" additive, set `Previous:` header.
4. Secrets: warn on key/token/password patterns; reference-not-value convention.
5. Ensure `.gitignore` contains `.claude/session-handoffs/` (Read+Edit; create if missing).
6. Write via Write tool → `.claude/session-handoffs/{slug}_{NN}.md`.
7. `--done`: offer final handoff, then archive chain via single Bash calls —
   `mkdir -p .claude/session-handoffs/done`, then `git mv`/`mv` one file per call.
8. Print self-resume line + HARD STOP.

## Command 2: `/session-resume [topic] [--all]`
1. Glob active topics; with `--all` also glob `done/*_*.md` and merge. Group by slug,
   highest seq + date + one-line summary, sort by mtime (newest first).
2. No arg → AskUserQuestion picker. With arg → load that slug's highest seq.
3. Staleness check (non-blocking): date > 7 days (compare to `date +%Y-%m-%d`) / branch
   mismatch / working tree dirty.
4. Load + summarize — also read any Reference/Key-files link tagged `[READ-AT-RESUME]` (or
   an obvious plan/spec/roadmap) and fold its depth (full roadmap, rejected options) into the
   summary; propose the single next action.
5. No auto-implement — confirm first.

## Windows safety
- Files/dirs for handoffs via Write (no `mkdir`); `.gitignore` via Read+Edit.
- `--done` archive: single Bash `mkdir -p` / `mv` / `git mv` calls — never chained.
- No `&&`/`||`/`;`; one `git`/`date` call at a time. Absolute paths in documents.

## Scope (deliberately out)
- No commit/push (that's /end-cycle or the team /handoff).
- No auto-trigger, no precompact hook (later, optional).
- No change to /park or /resume-bw.

## Test strategy
1. Any project: `/session-handoff test-a` → file + `.gitignore` entry.
2. `/session-handoff test-b`; then `/session-handoff test-a` → `_02` + carry-forward + Previous link.
3. New session: `/session-resume` → pick test-a/test-b; staleness note correct.
4. `/session-handoff test-b --done` → moved to `done/`; hidden from resume, shown with `--all`.
5. `git status` → handoffs not listed.

## Later promotion
If it proves out: propose a clean variant for buzzwoo-standard (next to /park); switch
store path to a buzzwoo convention + integrate resume into /resume-bw.

## Command vs. Skill format (deferred — revisit at promotion)
Keep as `.claude/commands/*.md` (single file, manual-only by default) for now — that already
satisfies the manual-only requirement. Converting to Skill format
(`.claude/skills/<name>/SKILL.md` + `disable-model-invocation: true`) gives **no win here**:
the whole body is needed on each manual invocation, so progressive disclosure saves nothing,
and there is no bundled script/reference to defer — you'd adopt the heavier format only to
disable its defining feature (auto-trigger). Re-evaluate ONLY if a trigger appears:
1. Real bundled assets to package (shared handoff-template file, helper script).
2. buzzwoo promotion — their ecosystem is skill-based; decide once their skill conventions are known.
3. Command format actually gets deprecated — but it is NOT, per the status check below.

**Format status (verified 2026-06-30, code.claude.com/docs/en/skills.md):** `.claude/commands/`
is **not deprecated** — no deprecation/sunset/removal notice and no runtime warning; the docs
say existing command files "keep working". Commands are now **merged into skills** (same
machinery), and **skills are the recommended path for new authors** — `.claude/commands/` is
documented only as a backward-compat note. Net: *superseded-but-supported*, no action forced.
Natural migration point = buzzwoo promotion (trigger 2); migration is then cheap (move to
`.claude/skills/<name>/SKILL.md`, keep `disable-model-invocation: true` to preserve manual-only).

## Review note (component-reviewer-clara, 2026-06-29)
B/B. Applied: `argument-hint`, Bash-based `--done` archive, `--all` glob includes `done/`,
explicit staleness date calc, absolute-path enforcement, wording fixes, one-line
Customizing per command. Rejected: H1 "missing Glob" (false — already present), S2 (keep
example flexible), S4 read-back verification (contradicts harness guidance; Write errors
on failure anyway).

## Post-design additions (2026-06-30)
Made after the original 12 grilled decisions:
13. **Step 7 — closing reflection (propose-only):** before STOP, `/session-handoff` surfaces
    (7a) durable facts as Claude-memory candidates, (7b) plan-drift updates, and (7c) stale-doc
    refreshes — show → ask → write only on confirm. `--done` renumbered to Step 8, print/STOP
    to Step 9.
14. **superpowers awareness:** Step 1 + Reference link committed `docs/superpowers/{specs,plans}/`
    artifacts; detection is artifact-based (not a plugin presence-check); link-don't-copy.
15. **Three-store separation:** handoff (transient/gitignored) vs Claude memory (durable) vs
    superpowers specs/plans (committed). Step 7 only links, never copies. Resume does NOT read
    memory (it auto-loads each session).
16. **`[READ-AT-RESUME]` deep-link contract:** the handoff tags Reference/Key-files links to
    full decision/roadmap/spec files; `/session-resume` Step 4 dereferences them and surfaces
    their depth (incl. rejected options) instead of trusting the handoff's compression. Closes
    a depth-loss gap where resume echoed only the handoff text.

## Post-design additions (2026-07-01)

17. **Resume no-handoff fallback (memory + git orientation):** refines Decision 15. The
    `MEMORY.md` *index* still auto-loads every session (no change) — but the individual
    dossier files it links do NOT auto-load. When `/session-resume` finds zero handoffs,
    it now reads those linked memory files plus `git log`/`git status` for a short
    orientation briefing instead of a dead end, then suggests starting a real handoff.
    Read-only: never writes to `.claude/session-handoffs/` or to memory — same posture as
    the rest of resume.
18. **Platform-conditional chaining (verified against `code.claude.com/docs/en/permissions`):**
    the original "never chain, one call at a time" rule (Windows safety section, both
    commands) overstated the problem — Claude Code splits compound commands into
    sub-commands and matches each independently for **both** Bash and PowerShell, on any
    platform; this isn't Windows-specific at the permission-engine level. What IS
    Windows-specific here is host-local tooling (e.g. a PreToolUse hook) that can hard-block
    chained Bash calls even when every sub-command is already approved. Fix: Step 1 (both
    commands) and Step 3 (resume) are now platform-conditional — on `win32`, batch the
    read-only date/branch/status checks via the PowerShell tool (not gated by that class of
    hook) or fall back to one Bash call at a time; on macOS/Linux, a single chained Bash
    call is fine. Added `PowerShell` to both commands' `allowed-tools`. Also added a
    one-line doc note (README) that passing the topic argument skips the AskUserQuestion
    round-trip — already true for resume, now stated for handoff too.

## Post-design additions (2026-07-02)

19. **Feedback-learning capture + CLAUDE.md hand-off (Step 7a extension):** Step 7a's memory
    scan now also catches *feedback*-type learnings (a correction the user gave about how to
    work, or an unusual approach they confirmed) — not just project facts. If a candidate
    reads as a persistent rule for how to work rather than a fact to recall, 7a flags it and
    points to `/revise-claude-md` instead of writing it as memory. `/session-handoff` never
    edits CLAUDE.md itself — that stays the dedicated skill's job; this is a hand-off, not a
    duplicate write path. Step 9's confirm block gained a `CLAUDE.md:` line, shown only when
    7a actually flagged one.

## Test strategy — automated layers (2026-06-30)
On top of the 5 manual steps above:
- **Static:** `tests/validate-commands.ps1` — 75 checks (structure, frontmatter, step
  numbering, cross-refs, source==deployed parity), mutation-verified, exit 0/1, no deps.
- **Behavioral:** `tests/behavioral/` — subagent-driven; 3 scenarios (fresh handoff /
  carry-forward / resume) run the real commands in an isolated sandbox, then
  `verify-artifacts.ps1` asserts 26 checks. Claude-driven (needs a session), not pure pwsh.
  Plus a focused `behavioral/depth-recovery/` sub-test (15 checks) for the
  `[READ-AT-RESUME]` contract.
