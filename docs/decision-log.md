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
- **2026-08-21 (v0.4.0 Track A, commit 1 — 1B + 1E):** renamed the template's
  `## Deferred & open questions` to **`## Open work`** and gave it per-item identity. The
  driver was measured, not felt: a scan of all 175 real handoffs in the apex-roadtrip chain
  (`tests/compat-old-chain.ps1`, added in the same work) counts **1644 open items in 1104
  bullets**, of which **533 are invisible** inside 170 run-on bullets separated by ` · `. An
  item that cannot be referenced cannot be closed, and the survey had already documented one
  open item tracked across twenty files and then silently dropped.
  **The carry rule (plan V4, decided the same day).** The obvious rule — carry every item
  forward verbatim — was rejected: the chain has avoided exactly that by hand for 75 sessions,
  and enforcing it would re-inflate every file by 2.5–3.5 KB, trading the length complaint
  against itself. Instead, items that are new, changed or closed are written out in full, and
  the rest are carried by **one** line, `Carried unchanged: {N} items — see {file}`, pointing
  only at the immediately previous file. `N` is an arithmetic invariant checkable from two
  adjacent files, so resolution is one hop and never a walk back through the chain. Closing an
  item is a written `Done:` act — an item may never leave by being omitted. `/session-resume`
  resolves exactly one hop and refuses to walk further. Rejected alternatives, recorded so they
  are not re-proposed: **(a)** verbatim carry (length), **(c)** carry `Open:` verbatim and the
  rest by pointer (mixed rule, more text to get wrong).
  **Two counting rules exist only because the scanner found them.** A bullet ending in `:` is a
  group header whose indented children are the items — two such headers hold 7 items that the
  naive "nested never counts" rule would have dropped silently. And a `{label}: a · b · c`
  bullet must re-attach its label to every item split out of it. Both were found before any
  command file was touched, which is the entire argument for building the scanner first.
  **A `grep`-based count in an earlier draft was wrong** and is corrected in the plan: `grep`
  matches bytes, so the pattern `unver.ndert` missed every "unverändert" because the umlaut is
  two bytes. The claimed "7 files with a numberless carry pointer" is really 38 bullets in 36
  files. German handoffs and byte-based search do not mix — the scanner reads UTF-8 explicitly.
  **1E folded in:** a `**Format:** 2` header field. A missing field means format 1 and stays
  valid forever. Included here rather than later because Track A changes the format anyway, so
  adding the marker afterwards would have meant a second format change for the same benefit.
  **Backward compatibility.** All 175 existing files use the old heading, so Step 3 accepts
  either. No old file is ever read-modified-written: the command only ever creates `_NN+1`, and
  the only touch on an existing handoff is `--done`, which moves it with `git mv`. The two
  behavioural sub-test fixtures were deliberately **left** in the old format so they keep
  working as free backward-compatibility coverage. Static suite **107 → 141/141**. Redeployed.
  Not yet proven behaviourally: no real `/session-resume` run against an old chain has been
  made under the new text.
- **2026-08-21 (the carry guard, and three bugs it found in itself):** `tests/compat-old-chain.ps1`
  had never seen a new-format file — it reported "nothing to check" and passed. A guard that has
  never caught anything is not a guard, so two fixture chains were added and wired into the static
  suite as section S: `tests/fixtures/carry-ok` (old to new to new, one item closed and one
  reworded) must exit 0, and `tests/fixtures/carry-bad` (three carried where five were open, with
  nothing marked done) must exit 1 and name the two lost items. Writing them found three real
  defects in the guard, none of which reading had caught: it did not subtract closed items at the
  format boundary, it omitted group-header children from the previous file's total, and it counted
  `Done:` bullets as open items, which inflated the total the next file had to carry.
  **The invariant itself was wrong and is now a conservation law.** The first formula,
  `N_carry(NN) = full_items(NN-1) + N_carry(NN-1) - closed_in(NN)`, ignored the items a file writes
  out in full, so a handoff that merely reworded one item failed the check. Replaced by
  `implied_new = carried + closed + written_out_still_open - previous_total`, which must be `>= 0`.
  Every previous item lands in exactly one of three places — carried, rewritten, or closed — and a
  negative result is the count of items that left without being closed. Deriving the new-item count
  instead of demanding equality means a session that adds work never false-alarms. Static suite
  **141 to 147/147**.
- **2026-08-21 (the wrapped-bullet bug — the most consequential find of the day):** the counting
  grammar and the scanner both read the Open-work section line by line. Real bullets wrap, and
  every middot separator on a continuation line was invisible. Chain-wide that hid roughly **900
  open items**: the apex-roadtrip total went from 1654 to **2570** once continuation lines were
  joined. `apex-roadtrip_176` alone counted 11 items instead of **44**, because one wrapped bullet
  carries more than thirty items behind separators on its second and later lines. Had the first
  new-format handoff established its count from that number, **33 items would have been dropped at
  the format crossing** — the exact failure the invariant exists to prevent. Fixed in both places:
  the scanner builds logical bullets before counting, and the command's grammar now states that a
  bullet wraps and that numbered `1.` children count like `- ` children. Found by pointing the
  scanner at a real file and disbelieving the number, not by reading either file.
  **Also observed, worth knowing operationally:** `_176` was written at 16:54, ten minutes *after*
  the new commands were deployed at 16:44, and it is in the **old** format. A session that is
  already running does not pick up a redeployed command — most likely because it loaded the file
  at session start. Not verified beyond the timestamps, so treat the mechanism as inference. The
  practical consequence is real either way: after a deploy, sessions already open keep writing the
  old format, which is exactly why Step 3 must accept both headings.
- **2026-08-21 (v0.4.0 Track A, commit 2 — 1A):** reordered the template into a
  forward-looking block and a retrospective block. The file now opens with `## Status` (two
  one-sentence bullets, where the topic stands and what this session changed), then
  `## → Pick up here`, then `## Open work`. Everything the next session needs in order to *act*
  comes before everything it needs in order to *understand*. `→ Pick up here` **moved** from the
  bottom rather than being duplicated: the next action exists exactly once in the file, which is
  why the Status block deliberately has no `Next:` line and Open work is barred from repeating
  it. 43 of 130 surveyed files had been writing that action twice by habit, and with the two
  sections now a few lines apart the duplication would have stopped being harmless.
  `/session-resume` gets the same order: the briefing opens with where it stands, what changed,
  and the next action, then open work, and only then the depth. **The completeness requirement
  was not weakened** — the "carry the full decisions, explicitly list rejected options, do not
  compress those away" sentence stays verbatim, because reversing it would resurrect the depth
  loss that the 2026-06-30 deep-link fix cured. This change is about order, not content.
  The new static checks are **index comparisons**, not `Contains`, since position is the whole
  point. Writing them caught a trap immediately: an unscoped `IndexOf('## Open work')` matches
  the prose mention inside Step 3 rather than the template, so the order assertions are scoped
  to the document-template block. Suite **149 to 166/166**. Redeployed.
