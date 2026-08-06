# Decision log

Chronological record of how `/session-handoff` + `/session-resume` got to their current
shape — what was changed, and more importantly *why*, including the alternatives that were
considered and rejected.

This is the long-form companion to two shorter files:

- `CHANGELOG.md` — what shipped per released version (user-facing).
- `plan/session-handoff-plan.md` + `plan/token-optimization-plan.md` — the design as
  designed, not as it evolved.

Moved out of `CLAUDE.md` on 2026-08-06 (verbatim, nothing dropped) so the always-loaded
project file stays small. Entries below are in the original order.

## Entries

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
- **2026-07-29 (token-optimization rebuild):** implemented the plan
  `plan/token-optimization-plan.md` (addendum 8d from the local briefing). Handoff now
  classifies each Reference/Key-files link at write time by **byte size** (`bytes/4` ~
  tokens, not line count): (a) essence already in the handoff → plain lazy link, no tag;
  (b) only one section needed → section anchor `[READ-AT-RESUME: <heading>]`; (c) big whole
  file → inline essence + offer an archive-split; (d) else a plain `[READ-AT-RESUME]` tag.
  New **Step 7d** = propose-only, opt-in archive-split of finished sections (Marcus decision:
  suggestion-only, no per-project persist mechanic; invariants — nothing deleted / verbatim
  move / open items never archived / plain archive link / own commit). Resume Step 4:
  anchors → targeted section read; bare tags load with a **big-file safeguard**; untagged
  plan-like links are peeked + offered, never blind-loaded. **Backward-compatible:**
  old-format handoffs (bare `[READ-AT-RESUME]`) read unchanged, no migration — existing
  chains of any length keep working. Added static **Section P** (14 checks → **99/99**).
  Redeployed. Behavioral coverage added: new sub-test `tests/behavioral/load-discipline/`
  (21/21 — proves anchor loads only its section + untagged big file not read whole) and the
  `depth-recovery` regression (15/15 — bare tag still dereferenced) both green.
- **2026-07-29 (8e — first real-project resume + process fixes):** ran the first live
  `/session-resume` with the v0.2.0 commands (APEX, old-format handoff). The token-aware
  **loading validated in the real world** — byte-check caught a 98 KB backlog behind a bare
  tag → headings + two targeted section reads (~7k vs ~24.5k), untagged links correctly not
  loaded, old format fine, ~55k avoided. So the resume *loading* path needs no change and was
  left untouched (Marcus: don't touch it — it worked). Three gaps surfaced *beside* the
  loading (briefing addendum 8e), all shipped: (1) **after-handoff reminder** — fixed `Note:`
  in handoff Step 9 confirm block (work after the write is invisible to the next resume; the
  detect-at-session-end + in-place-update variants were rejected — a command can't self-trigger
  at session end, and in-place update breaks the immutable-snapshot model the staleness check
  relies on); (2) **cross-chain pointer** — optional `Continue first in: <chain> @ <path>` line
  in "→ Pick up here", resume surfaces it at the top, print-only, never loads the foreign repo;
  (3) **memory-index reconciliation** — resume Step 4 compares the briefing against auto-loaded
  `MEMORY.md`, names both states on contradiction, resolves nothing silently, adds no load.
  The 8e **marginal note** (loosen the untagged-plan-like-link offer rule) was **dropped** — it
  is load discipline (fenced off) and the observed deviation was harmless. Added static
  **Section Q** (8 checks → **107/107**); no new behavioral test (small additive text, static
  coverage proportionate). Redeployed. **Released v0.3.0.**
- **2026-08-06 (CLAUDE.md rightsizing):** audited `CLAUDE.md` against the Claude 5 context-
  engineering guidance (lightweight file, tokens spent on gotchas, progressive disclosure for
  detail, no restating what the file system already shows). Shrank it from 187 to ~50 lines:
  the repository-layout tree was dropped down to the two non-obvious facts (`commands/` is
  source not runtime, `plan/` holds two different design docs), hard-coded test counts were
  replaced by a pointer to `README.md`/`tests/README.md` so they can't go stale in a third
  place, the Windows-chaining convention was removed as a duplicate of the global `CLAUDE.md`
  and the `buzzwoo-windows` skill, and this decision log was split out. Nothing about the
  commands themselves changed; the static suite stayed green.
