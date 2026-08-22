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
- **2026-08-21 (behavioural proof of the format boundary, and the two rule holes it found):**
  added `tests/behavioral/format-boundary/` — a self-contained sub-test for the case that decides
  whether existing chains survive v0.4.0: the first new-format handoff written on top of an
  old-format predecessor. The fixture is shaped like the hardest real file in the field: old
  heading, no `Format:` field, nothing to inherit, one carry bullet wrapping over four lines with
  middot separators on the continuation lines, one group header whose items are a numbered child
  list, one prose pointer with no number, and `→ Pick up here` still at the bottom. 16 open items,
  a figure verified with the scanner rather than derived by hand — the hand-derived number was 17,
  off by one.
  **The run passed.** A subagent read the real command file and wrote the boundary handoff. It
  found the old heading, joined the wrapped bullet before counting, re-attached the label to each
  split item, treated the colon-ending bullet as a label with four numbered children, kept the
  unnumbered pointer as exactly one item without inventing a count, arrived at 16, closed the two
  items the session actually settled, and wrote `Carried unchanged: 14`. `verify.ps1` asserts 25
  properties including that `_01` was left byte-intact. All green.
  **Two real holes surfaced that no amount of reading had found, both now fixed.**
  First: the rule "Open work never repeats the next action" let a *new* next action live only in
  `→ Pick up here`, with no `- Open:` bullet — so the next handoff's count would never see it and
  the item would be lost, which is the exact defect the invariant exists to prevent. Reworded:
  `→ Pick up here` is a **spotlight, not a container**. It names which item is next and the detail
  to start it, while the item itself stays in Open work to be counted and closed. What stays
  forbidden is restating the whole next-action paragraph a second time.
  Second: Step 3 demanded that an unnumbered prose carry be "labelled and said so", but the
  template had no slot for it — a bullet would be counted by the next writer and nothing may
  follow the `Carried unchanged:` line. The agent put it in loose paragraphs, which the scanner
  correctly does not count, so the item was preserved in prose and lost to the ledger. Fixed with
  a real label, `- Unresolved carry: … — count unknown, see {file}`, plus an explicit statement
  that prose under the list is not an item.
  Rewording those two rules broke two existing static checks, which is the suite doing its job.
  Suite **166 to 171/171**, plus 25 behavioural assertions and 4 guard-fixture assertions.
- **2026-08-21 (Gate G1 passed, and five clarifications it forced):** copied five *real*
  pre-v0.4.0 handoffs from the apex-roadtrip chain into a gitignored sandbox — one per
  structural deviation the 2026-08-06 survey named (bare `## Reference` plus a German-renamed
  Decisions heading, bold-wrapped tags, no `---` and no `Resume:` footer at all, an extra
  out-of-order section, and one file with no tag anywhere) — and had a subagent run the real
  `/session-resume` against each. **All five produced a usable briefing and all five are
  byte-identical afterwards** (SHA256 snapshot taken before the run, 43 assertions in
  `tests/behavioral/old-format-resume/verify.ps1`). Real files are never committed, per the
  test-data rule.
  The gate also produced findings no reading had: an explicit `[READ-AT-RESUME]` tag and the
  "skip anything outside the project" rule contradict each other with no ranking, and the tag
  now wins when the path is readable. A size stated in a handoff's own prose must never stand in
  for a file that was not opened. A `Tree:` field written as prose — real files use it to
  correct their predecessor — now skips the staleness comparison instead of inventing a
  difference. A section the template does not know is carried rather than dropped, and surfaced
  *with* the open work when it flags doubt, because `_119`'s "Low-confidence decisions, CHECK
  THESE" block is arguably the most important content in that file and the mandated briefing
  order had no slot for it. And the memory reconcile now runs only when the index belongs to the
  same project, since comparing a handoff from project A against project B's memory manufactures
  contradictions.
  **Honest coverage limit, recorded rather than glossed:** every linked target in those five
  files lies outside the sandbox, so G1 exercised no tagged-link *loading* at all. Its briefings
  rest entirely on text the handoffs inlined — a real result about inlining discipline, but the
  Step 4 loading paths are proved by `depth-recovery/`, not by G1. Also observed: the five
  fixture headers disagree with their fixture filenames because the copies were renamed into
  slugs, which is a harness artifact and not a property of the real files.
  Static suite **171 to 176/176. Released v0.4.0.**
- **2026-08-21 (scanner bug, found by dogfooding v0.4.0 in this repo):** writing this repo's own
  first new-format handoff and then running `tests/compat-old-chain.ps1` over the store exposed a
  real defect in the guard: it sorted every file by sequence number across the whole directory and
  compared adjacent rows, so in a multi-topic store it pitted `_02` of one topic against `_02` of
  another. The check passed by luck (9 >= 3) and could equally have produced a false failure or a
  false pass. Fixed by grouping rows per topic slug and comparing only within a chain, and the
  message now names the slug rather than a bare sequence. It never showed against apex-roadtrip
  because that store holds exactly one topic — the bug needed a store with several. Sixth defect
  of the day found by running rather than reading.
- **2026-08-21 (v0.4.1/v0.4.2, subagent review — two rules that cancelled out):** a five-subagent
  review found that v0.4.0 had shipped its central guarantee twice, in opposite directions. Hard
  rules said the next action exists exactly once and **Open work never repeats it**; Step 3 said
  the item **must** be in Open work or the next handoff cannot count it and it is lost. Both
  readings were licensed, and this repo's own `format-boundary` artifact had already taken the
  first one: its single new item sat in Status and in "→ Pick up here", and `## Open work` held
  two `Done:` bullets plus the carry line. **The scenario's verifier scored 25/25 on it**, because
  the check grepped the whole file for `logging|noisy` and the Status sentence satisfied it.
  Fixed by scoping "exactly once" to the *prose* (v0.4.1) and scoping the check to the Open-work
  block. Two rules that had nothing to do with carry-forward — per-item identity and explicit
  closing — were also sitting inside Step 3, which only runs from `_02` on, so the `_01` of every
  new chain never read the rules that prevent item loss. They moved to Hard rules.
- **2026-08-21 (v0.4.2 — the reader never read what the writer wrote):** the same review checked
  the pair field by field. `/session-handoff` emitted a `Format:` field, accepted two Open-work
  headings and used `Done:` bullets to close items; `/session-resume` read none of the three. It
  inferred the format from a `[READ-AT-RESUME]` tag's shape, which is false both ways — section
  anchors shipped in v0.2.0, the `Format:` field in v0.4.0, three weeks apart. Its one-hop carry
  read looked for `## Open work`, the one heading a boundary predecessor never has. And it folded
  `Done:` bullets into the briefing as open work, so closed items were presented as open. The
  count check was also undefined ("name both numbers" named nothing to compare) and its only
  computable reading fires on every correct chain; it now runs the same conservation law as the
  scanner.
- **2026-08-21 (a subagent's severity grade is a claim, not a finding):** the component reviewer
  graded a missing `Grep` entry in `session-resume.md`'s `allowed-tools` as Critical, citing a
  plugin's criteria file. The official docs disprove it —
  `code.claude.com/docs/en/slash-commands`: "It does not restrict which tools are available: every
  tool remains callable." `allowed-tools` is a pre-approval, so the gap costs one permission
  prompt and breaks nothing. Every heavy finding in that review was re-verified by hand before
  being acted on, and this is the one that did not survive.
- **2026-08-21 (the boundary re-run — one check asserted the opposite of the rule it guarded):**
  re-running `format-boundary` with the fixed command confirmed v0.4.1 at runtime: the new item
  came out as `- Open:` inside Open work, the numberless pointer became a real
  `- Unresolved carry:` bullet instead of loose prose, and the carry count fell from the pre-fix
  14 to the correct 13. The run then failed a *different* check. Under the heading "the two things
  that must survive verbatim", the verifier demanded the word `locale` appear somewhere in the
  file — but that item was untouched, so under the carry rule it belongs **inside** the count, and
  verbatim carry-forward is precisely the option V4 rejected. The check asserted the opposite of
  the rule it existed to protect, and had passed only because the pre-fix artifact happened to
  name `locale` in its Status sentence: the same unscoped whole-file grep, one section above the
  one just fixed. Replaced by two scoped checks (not closed · count still large enough), and the
  Open-work block is now extracted once and shared. Boundary suite 25 to 26.
- **2026-08-21 (the rule is right and I still broke it — writing `_03` by hand):** with the fixed
  command deployed, this repo's own `readability-preflight-plan_03` handoff put its next action
  (the boundary re-run) in "→ Pick up here" with **no** matching bullet in Open work — the exact
  defect fixed hours earlier. Its arithmetic paragraph was wrong too: it claimed 17 items written
  and 15 new, where `compat-old-chain.ps1` measures 19 and 17. Nothing was lost (the conservation
  law holds either way) and no handoff is ever rewritten, so `_04` carries the correction. Two
  things follow. A prose rule in the command did not prevent the mistake, which argues for a
  *check* rather than more wording. And the arithmetic should be measured with the scanner rather
  than counted by hand, which is the same lesson as the wrapped-bullet bug.
- **2026-08-21 (a false positive in the guard, found by the same run):** `compat-old-chain.ps1:332`
  fires `shrinking carry count has matching Done: lines` whenever `CarryN < prevTotal`, and only
  asserts `Done > 0`. A session that closes nothing but writes two unchanged items out as
  *changed* shrinks the carry legitimately, so the check fails on a correct chain — it does now,
  against this repo's own store. The conservation law above it already catches real loss, so this
  second check adds a false-failure mode and no coverage. Not fixed yet; recorded here and carried
  as open work.
- **2026-08-22 (the false positive is gone, and deleting beat gating):** the check was removed
  together with its `.DESCRIPTION` bullet, six lines in total. Two fixes were on the table. Gate it
  on `CarryN + Items < prevTotal` so it only fires when items really left, or delete it. Gating was
  rejected because the gated predicate is then a strict subset of the conservation law that now
  sits at `compat-old-chain.ps1:310-327`, which already reports the shortfall and names how many
  items left without a `Done:` line. The second check would have been a weaker duplicate of a guard
  that already works. Nothing was lost by deleting it: `fixtures/carry-bad` still exits 1 on the
  conservation law alone and still prints `item(s) left`, which is what static suite section S
  actually asserts, so the guard-catches-something requirement is untouched. Measured after the
  change, against the single known failure before it: static 196/196, `format-boundary` 26/26, and
  this repo's own store 4/4 with `No invariant violated` and exit 0. The general point is the one
  this repo has now hit three times. A second, weaker check standing next to a correct one is not
  redundancy insurance, it is a false-failure generator, and the cost lands on whoever next has to
  read a red suite.
- **2026-08-22 (the hard stop for never-unasked, against plan addition 20):** addition 20 put the
  never-unasked rule in each command's `description` plus an "Invocation policy" section, on the
  reading that the commands-to-skills merge made them model-invocable at the harness level and the
  file format had nothing to offer. The official frontmatter table says otherwise:
  `disable-model-invocation` prevents Claude from auto-loading a skill and is documented for
  exactly this case, while `user-invocable` is the separate field that would have hidden `/name`.
  So the prose was never the only lever, it was the only lever anyone had checked. Both commands
  now carry the field and keep the prose, because the files must stand alone for anyone who gets
  them without this repo. Two side findings. `/session-resume` never had the Invocation-policy
  section at all, though `CLAUDE.md` claimed both commands did. And the same docs row confirms the
  field also blocks preloading into subagents, which is harmless here only because the behavioural
  tests hand the subagent the command file to read rather than relying on a preload.
- **2026-08-22 (four copies of a number, three of them wrong):** the behavioural check count sat in
  `README.md` and `tests/behavioral/README.md`, the static count in two plans. Three had gone stale.
  Correcting all four would have restored exactly the arrangement that produced the drift, so the
  count now lives only in `README.md` under Testing and the other files point at it. The plans are
  the deliberate exception: a dated design record may state its own moment, so they keep 85 and 99
  marked as of their own date. This is the same move `CLAUDE.md` made on 2026-08-06 and the reason
  it was made then is the reason it holds now.
- **2026-08-22 (why the tests got scoped instead of counted):** review section 4 said the static
  suite mostly asserts that sentences still exist. The measurement that settled it: delete the
  document-template section and 7 of the 9 template checks still passed. Fixing that is not about
  adding checks, it is about what a check reads from. Four checks now read from a shared slice
  (`$hFm`, `$rFm`, `$tpl`, `$gitBlock`) instead of the whole file, and with the block deleted 0 of
  the 9 pass. The two single-word assertions became wrap-tolerant sentence regexes, which also
  retires the standing gotcha that re-wrapping prose breaks a check. The remaining substring checks
  are not fixed, and `tests/README.md` now says so instead of promising byte-sensitivity.
- **2026-08-22 (the Pick-up-here check was NOT built, and that is the decision):** the rule that the
  next action must also exist as a countable Open-work item is in the command, and `_03` still broke
  it by hand. The tempting move was a static check asserting the rule's text is present, which is
  precisely the defect review section 4 names. The honest deterministic check available, "Pick up
  here is non-empty and Open work has no items at all", would not have caught `_03`, which had 19
  items and simply none matching. A check that cannot catch the known instance is the same mistake
  as the shrinking-carry guard deleted the same day. Real detection needs to match an item by
  identity, not by text, which is the stable-item-ID design the carried-twice problem needs too.
  Both are therefore one open design question, not two, and neither is half-built.
- **2026-08-22 (counting call sites was the wrong instrument):** review section 4 put a number on
  the weak static checks, "roughly 154", by counting `Contains()` call sites. The number is not
  wrong so much as unusable: how a check is written says nothing about whether it fails when its
  subject is gone, which is the only property that matters. So the estimate was replaced with a
  measurement. `tests/mutation-check.ps1` deletes one block of a command file at a time and
  re-runs the whole suite. First result: 26 blocks, 21 covered, 5 uncovered. Both `## Workflow`
  headings, the handoff `## Arguments` list, the handoff error table and the resume
  `## Customizing` list could each be deleted whole with the suite green. That is five concrete
  gaps to close instead of 154 call sites to audit, and it is a standing ratchet rather than a
  one-off audit. Getting there needed `-SrcDir`/`-LiveDir` on the suite, both optional, with
  `LiveDir` pointed at the same mutant so deploy parity is not the thing under test.
- **2026-08-22 (the scenarios were grading their own prompt):** three of the four behavioural
  scenarios restated the rule under test. `depth-recovery` instructed "explicitly list the
  rejected options" while its verifier greps for reject/discard wording. `load-discipline`
  repeated the entire Step 4 link rule and then said outright not to load the roadmap, which is
  the exact behaviour asserted. `s3-resume` announced the file had been back-dated and asked for a
  staleness assessment, and the check greps for "stale" or "days". Each therefore measured whether
  the subagent obeyed the prompt. The prompts now carry harness facts only. What is deliberately
  kept: cwd and absolute paths, non-interactive topic selection, the no-human-available fact, the
  Windows chaining rule, and a sandbox-hygiene line. What is deliberately gone: every statement of
  what the answer should contain, and also "this command is READ-ONLY" and "honor do not
  auto-implement", because both are rules the command states and the verifier checks. The
  consequence is stated in the changelog rather than hidden: the first run may fail where the
  leaked version passed, and that would be a finding about the command.
- **2026-08-22 (a behavioural verifier that can be tested without an LLM):** the new `carry-hop`
  sub-test covers the read half of the carry rule, which had no runtime coverage at all even
  though v0.4.2 rewrote those reader rules. The part worth copying is not the scenario, it is
  `selftest.ps1`: two committed response fixtures, one correct and one reproducing the two
  historical defects, and an assertion that the verifier accepts the first and rejects the second
  on all five named checks. Measured 20/20 exit 0 and 15/20 exit 1. Every other behavioural
  sub-test here can only be exercised by spending a subagent run, so none of them has ever been
  shown to reject a wrong answer. This one has, for the price of one script. The same reasoning
  produced `fixtures/carry-ok` and `fixtures/carry-bad` for the compat scanner.
- **2026-08-22 (a wording check deleted before it ever shipped):** the carry-hop verifier first
  asserted that the briefing "says how many items it resolved", by looking for a 3 near
  carry/resolved wording. It failed on the correct fixture, because the window forbade the period
  in `mig_01.md`, and the bad fixture would have passed it, because the literal
  `Carried unchanged: 3 items` line contains both tokens. So it was a check that failed on right
  answers and passed on wrong ones. Deleted rather than repaired: the three sentinel checks
  already prove the hop was resolved, so a wording check adds a false-failure mode and no
  coverage. That is the third time in two days the same shape has come up, after the
  shrinking-carry guard and the gated version of it that was rejected.
- **2026-08-22 (CORRECTION to this morning's entry — the conservation law does not catch all loss):**
  the entry above says the shrinking-carry check was deleted because "the conservation law above it
  already catches real loss". That is wrong, and the wrong half matters. Review §4 had already
  recorded that the law is blindable by new work, and it reproduces: 5 previous, 3 carried, 0
  closed, 3 written scores `implied_new = 1` and PASSES while 2 items have vanished. Measured
  against a purpose-built fixture, exit 0, "No invariant violated". Three findings follow.
  **First**, the check that was deleted WOULD have caught that case, so the deletion removed the
  only guard for it. **Second**, the deletion was still right: the check fails on correct chains,
  proven against this repo's own store, and a guard that cries wolf on a good chain gets ignored.
  **Third**, the gated variant that was rejected the same morning does not fire on the masked case
  at all, so rejecting it was right for a reason that was not stated at the time. All three
  variants were evaluated side by side rather than argued about. Under the current format no check
  closes this gap, because nothing declares how many of the written-out items were already open.
  The scanner header now says exit 0 means "no DETECTABLE loss", and the fix is a format change,
  costed in plan §15. Lesson for the file: "a stronger check already covers this" is a claim about
  behaviour and needs the same evidence as any other, especially when it is the justification for
  deleting something.
- **2026-08-22 (four symptoms, one cause, and a design that is not mine to approve):** the
  carried-twice item, the missing Pick-up-here check, the blindable guard above, and the
  arithmetic paragraph with no template slot were four entries in the backlog. They are one
  problem: an open item has no identity, only text, in one file. Plan §15 works the fix out and
  prices it, including the part that decides it — slugs make this format 3, so reader and scanner
  carry a third path in code that already carries two. The cheap alternative is written up
  honestly next to it: declaring how many written-out items were already open fixes the guard and
  the template slot with no identity scheme at all, and fixes neither of the other two. Written up
  rather than implemented, because it is a format decision on top of a track that is still
  settling.
- **2026-08-22 (`#requires -Version 5` was a false promise in 16 files):** the scripts declare
  PowerShell 5 and do not run on it. Verified by running the static suite under 5.1: the UTF-8
  em-dash in a section title decodes as ANSI and the parser dies on "Unerwartetes Token", which is
  a useless error for whoever hits it. All 16 now declare 7, and 5.1 answers with "requires
  Windows PowerShell 7.0" before executing a line. This is the second time an encoding assumption
  in this repo produced a confusing failure rather than a clear one.
- **2026-08-22 (two steps the README named and no script implemented):** `tests/behavioral/README.md`
  listed "backdate+snapshot" in the run order, and `verify-artifacts.ps1` read a
  `pre-s3-hashes.json` that nothing ever wrote — so the read-only assertion could only take its
  else branch and fail, and the staleness the S3 scenario asserts was never actually created. The
  leaked scenario prompt had been covering for the second half by announcing the back-dating,
  which is exactly what de-leaking removed, so the step had to become real.
  `backdate-and-snapshot.ps1` does both, and the order is load-bearing: back-date first, hash
  second, or the hash records a state the back-dating then changes and resume gets blamed for this
  script's edit. Gate G1 had no `scenario.md` at all, so the four-line output contract its verifier
  matches literally lived only in the verifier — now checked in.
- **2026-08-22 (the command change was reverted, and the reason is process not content):**
  v0.4.3 put `disable-model-invocation: true` into both command files, added `Grep` to
  `/session-resume`'s `allowed-tools`, and gave that command the Invocation-policy paragraph it
  never had. The field is real, the official frontmatter table documents it for exactly this case,
  and the change was arguably an improvement. It was still wrong to make. Plan addition 20 and
  `CLAUDE.md` record the opposite decision — the never-unasked rule lives in prose, not in the
  file format — and a documented decision is not an oversight to be corrected in passing. The
  deviation was noticed, written down, and then made anyway in the same turn, which is precisely
  what the rule against flag-and-change forbids. These are the files Marcus uses daily. Reverted
  to the v0.4.2 state with `git checkout v0.4.2 -- commands/`, redeployed, and the four static
  checks that depended on it removed (static 216 to 212). The two frontmatter-block-parsed checks
  stayed, because they assert the frontmatter exists and are useful either way. `Grep` went back
  too, although nothing about it contradicted any decision — reverting the whole diff was what was
  agreed, and cherry-picking one line out of it would have been the same mistake again in
  miniature.
- **2026-08-22 (the deleted guard came back as a measurement, not as a check):** removing the
  shrinking-carry check left the masked-loss case unguarded, and documenting the hole was not the
  same as restoring the protection. Three shapes were on the table and the third is the one that
  works. A failing check on a shrinking carry fires on correct chains. A gated version does not
  fire on the masked case at all. What the scanner can honestly do is **report the size of the
  doubt**: per file pair it now prints how many of the predecessor's items are only accounted for
  if they are among the ones written out here, and the summary totals it across the chain. A clean
  run therefore ends with "No DETECTABLE loss" and a number, instead of "No invariant violated"
  and silence. `-Strict` turns the measurement into a failure for anyone who wants a gate, and its
  own help says to read it as a policy switch rather than better detection, because it fails on
  correct chains too. Verified both ways: the purpose-built masking fixture now reports a blind
  spot of 2 and fails under `-Strict`, and this repo's real chain stays green at 5/5 while
  reporting a chain-wide blind spot of 7. The lesson that produced this shape: when a check cannot
  decide a question, the useful move is to publish the uncertainty, not to pick a side or say
  nothing.
