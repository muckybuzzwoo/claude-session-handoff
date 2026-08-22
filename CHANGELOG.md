# Changelog

All notable changes to the `/session-handoff` + `/session-resume` commands.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/); versions follow semver.

## [0.4.5] — 2026-08-22

[GitHub release](https://github.com/muckybuzzwoo/claude-session-handoff/releases/tag/v0.4.5).

**No command file changed.** This release corrects a claim shipped in v0.4.3, makes the
behavioural suite runnable from a clean checkout, and costs out the one design decision that
four open items turned out to share.

### Corrected

- **v0.4.3 said the conservation law "already catches real loss". It does not.** That was the
  stated reason for deleting the shrinking-carry check, and the reason was wrong. The law is an
  inequality, because a session may add work, so new items can mask lost ones: 5 previous, 3
  carried, 0 closed, 3 written scores one new item and PASSES while two have vanished. Measured
  against a purpose-built fixture — exit 0, "No invariant violated".
  Three things follow, all measured rather than argued. The deleted check **would** have caught
  that case, so removing it removed the only guard for it. The deletion was still correct,
  because the check fails on correct chains and did so against this repo's own store. And the
  gated variant rejected the same morning does not fire on the masked case at all, so rejecting
  it was right for a reason nobody had stated.
  **No check closes this gap under the current format**, because nothing declares how many of the
  written-out items were already open. `compat-old-chain.ps1`, `tests/README.md` and `README.md`
  now say that exit 0 means *no detectable* loss. The fix is a format change, costed below.
- **The scanner header still documented the equality formula withdrawn in v0.4.1.** It now
  documents the inequality the code has actually used since, and says why the equality was
  dropped.

### Added

- **plan §15 — item identity, costed and not decided.** Four backlog items were one problem: an
  open item has no identity, only text, in one file. That is why an item carried unchanged twice
  can never be closed, why no check can confirm the "→ Pick up here" item exists in Open work,
  why the guard above is blindable, and why the arithmetic paragraph has no template slot. The
  section works out slugs on the carry line, prices them (about 110 tokens per handoff at 26
  items, and — the part that actually decides it — a third format path in reader and scanner),
  states what they do *not* fix, and writes up the cheap alternative honestly: declaring how many
  written-out items were already open fixes two of the four symptoms with no identity scheme at
  all. Written up rather than built, because it is a format decision on top of a track that is
  still settling.
- **`tests/behavioral/backdate-and-snapshot.ps1`** — the `backdate+snapshot` step the README has
  named in its run order all along while no script implemented it. Two things were therefore
  impossible from a clean checkout: nothing made the chain stale for S3 to notice, and
  `verify-artifacts.ps1` read a `pre-s3-hashes.json` that nothing wrote, so the read-only
  assertion could only take its else branch and fail. The leaked S3 prompt had been covering for
  the staleness half by announcing the back-dating, which is exactly what v0.4.4 removed, so the
  step had to become real. Order is load-bearing: back-date first, hash second, or the hash
  records a state the back-dating then changes and resume gets blamed for this script's edit.
- **`tests/behavioral/old-format-resume/scenario.md`** — gate G1 had no scenario at all, so it
  could not be re-run from the repo, and the four-line output contract its verifier matches
  literally (`LOADED:`, `NEXT ACTION:`, `KEY FILES:`, `SOURCE-SHAPE:`) lived only inside
  `verify.ps1`.

### Fixed

- **`#requires -Version 5` was a false promise in 16 scripts.** They do not run on PowerShell 5.
  Verified by running the static suite under 5.1: the UTF-8 em-dash in a section title decodes as
  ANSI and the parser dies on "Unerwartetes Token", which tells the reader nothing. All 16 now
  declare 7, and 5.1 refuses with "requires Windows PowerShell 7.0" before executing a line.
- **One more weak check scoped.** `Resume skips tree check on older handoffs` asserted the word
  `older` (4 occurrences) plus an unanchored `skip this check`. Replace the rule with unrelated
  prose containing both and the old check passed. It now matches the sentence, wrap-tolerantly.

### Recorded, still open, and needing a decision

- **The §12/V2/V3 A/B merge gate was never run and never waived**, although v0.4.0 through v0.4.4
  shipped. `tests/ab/measure-run.ps1` does not exist and no record appears anywhere. Now stated at
  §12.6 rather than left implicit, with the thing that changes the decision: v0.3.0 is five
  releases back, so a comparison now measures the whole v0.4.x line, not Track A.
- **Track B's start bar.** §7 said "long enough that reverting A is implausible" and left the bar
  unset. A concrete bar is now proposed there, to be accepted or rejected: a real handoff and
  resume in another project, on a chain crossing the format boundary, with no command patch for
  seven days. Track A was patched four times within hours of release, so the observed settling
  time is hours and one quiet day proves nothing.
- **The archive-split baseline** is Track B work item 0 and stays unbuilt on purpose. Building it
  now would start Track B, which the revert-order rule says not to do before the bar above is met.

### Not verified

- No behavioural scenario has been executed by a subagent. Everything checkable without an LLM
  was: static 216/216, mutation 26/26 blocks, format-boundary 26/26, chain scanner 4/4, carry-hop
  selftest green, and `backdate-and-snapshot.ps1` exercised against a hand-built store.
## [0.4.4] — 2026-08-22

[GitHub release](https://github.com/muckybuzzwoo/claude-session-handoff/releases/tag/v0.4.4).

Test-quality release. **No command file changed**, so handoff and resume behave exactly as in
v0.4.3. This closes the rest of `reviews/subagent-review-2026-08-21.md` §4: the parts about the
tests measuring the wrong thing.

### Added

- **`tests/mutation-check.ps1`** — a standalone mutation harness. It deletes one block of a
  command file at a time (each `## H2`, each `### Step N`, fences respected so the document
  template stays one block), re-runs the whole static suite against the mutant, and reports
  which deletions broke no check at all. A block nothing fails on has no coverage.
  Review §4 estimated "roughly 154" weak checks by counting call sites. That is the wrong
  instrument: what matters is not how a check is written but whether it fails when its subject
  is gone. The harness answers that directly. First run: 26 blocks, 21 covered, **5 uncovered**
  — both `## Workflow` headings, the handoff `## Arguments` list, the handoff error table, and
  the resume `## Customizing` list could each be deleted whole with the suite staying green.
  It exits 1 on any uncovered block not in its `$Allowed` list, so it works as a ratchet.
- **`tests/behavioral/carry-hop/`** — runtime coverage for the READ half of the carry rule, the
  last part of v0.4.0's headline feature with no behavioural test at all. `format-boundary`
  proved the `Carried unchanged: {N} items` line is *written*. Nothing proved it is *resolved*,
  and v0.4.2 rewrote precisely those reader rules. The hop target is old-format on purpose,
  because that is the only case that exists in the field. Three items carry sentinels found
  nowhere else, so naming them proves the hop was taken, and a fourth is closed with a `- Done:`
  bullet, so listing it as open work reproduces the v0.4.2 defect.
- **`tests/behavioral/carry-hop/selftest.ps1`** — proves that verifier has teeth without an LLM.
  It feeds a known-good and a known-bad response from `fixtures/` and asserts the good one
  passes and the bad one fails on all five named defect checks. Measured: good 20/20 exit 0, bad
  15/20 exit 1, failing on exactly the two historical defects. Same idea as `fixtures/carry-ok`
  and `fixtures/carry-bad` for the compat scanner. No other behavioural sub-test here can be
  checked this way.
- **`-SrcDir` / `-LiveDir` on `validate-commands.ps1`.** Both optional and defaulted, so the
  plain invocation is unchanged. The suite had to be pointable at a mutated copy for the harness
  above to exist, with `LiveDir` aimed at the same copy so parity is not the thing under test.

### Changed

- **Static suite 203 → 216.** New Section V covers the five blocks the harness found uncovered,
  each check reading from the block it is about. Re-measured afterwards: 26 of 26 blocks covered,
  `$Allowed` empty.
- **The three scenario prompts that restated the rule under test were rewritten.**
  `depth-recovery` told the agent to "explicitly list the rejected options", `load-discipline`
  repeated the whole Step 4 link rule and said which file not to load, and `s3-resume` announced
  that the file had been back-dated and then asked for a staleness assessment. Each of those is
  the exact thing its own verifier greps for, so a green run measured prompt obedience rather
  than the command. The prompts now carry harness facts only — paths, non-interactive, no human
  available, the Windows chaining rule — and say nothing about the expected answer.
  **The first run after this change is the first honest measurement of those three, and it may
  fail where the leaked version passed.** A failure there is a finding about the command, not a
  test regression. `format-boundary` was already clean and is untouched.

### Not verified

- The three de-leaked scenarios and the new `carry-hop` scenario have **not been executed by a
  subagent**. That needs a Claude session to dispatch them, so it is a separate, deliberate run.
  Everything that can be checked without an LLM was: the static suite, the mutation harness, and
  the carry-hop verifier self-test.

### Still open

- **Stable item IDs.** An item carried unchanged twice cannot be closed, because the writer reads
  only `{NN-1}` and the reader one hop, so its text is out of reach of both. The same missing
  identity is why no check can confirm the "→ Pick up here" item also exists in Open work. One
  design question, not two, and not costed out.
- **Track B (v0.5.0)** and the **§12/V2/V3 A/B merge gate**, which was never recorded as run or
  waived although v0.4.0 shipped.
## [0.4.3] — 2026-08-22

[GitHub release](https://github.com/muckybuzzwoo/claude-session-handoff/releases/tag/v0.4.3).

The review backlog: the two cheap hard fixes, the test-quality drift and the doc drift from
`reviews/subagent-review-2026-08-21.md` §4–§6. How a handoff is written and how a resume reads
it are unchanged.

### Changed

- **`disable-model-invocation: true` in both commands.** The never-unasked promise rested on
  prose alone, in `description` and the Invocation-policy section. This is the documented hard
  stop: it blocks Claude from auto-loading the command and leaves `/session-handoff` and
  `/session-resume` working when you type them. `/session-resume` also gained the
  Invocation-policy paragraph it never had, so both files now say the same thing.
- **`Grep` added to `/session-resume`'s `allowed-tools`.** Step 4 instructs a Grep for the
  section anchor. `allowed-tools` is a pre-approval and not a restriction, so the gap cost one
  permission prompt rather than breaking anything.

### Tests

- **Static suite 196 → 203.** Four checks that passed on text found anywhere in the file are
  now scoped to the block that has to hold it, through shared slices defined once near the top
  (`$hFm`, `$rFm`, `$tpl`, `$gitBlock`). Measured against a mutation: with the document-template
  section deleted, 7 of the 9 template checks used to pass and now 0 do. Two more assert a whole
  sentence instead of a single word (`Then` and `done/` each occur five times in the file), and
  do it wrap-tolerantly, so re-wrapping the prose no longer breaks a check.
- **Six new checks** cover the frontmatter facts above.
- **The false-positive carry check is gone.** It fired whenever the carry count shrank and only
  asserted that something was closed, so it failed on correct chains. The conservation law it
  stood next to already catches real item loss.

### Docs

- **Check counts live in one place now, `README.md` → Testing.** Four files carried their own
  copy and three had gone stale: the behavioural suite is 30 and was written as 26, the plans
  said 85 and 99 against 203. The plans keep their historical number, marked as of their own
  date, because a design record is allowed to describe its own moment.
- **`tests/README.md` no longer claims the suite is byte-sensitive throughout.** It names the
  mutations that are verified and says plainly that the remaining checks are substring matches.
- **`README.md` no longer contradicts itself on resume loading.** One paragraph described the
  pre-v0.2.0 blind loading that the next paragraph then corrected.
- **`docs/how-it-works.html`**: Step 8 (`--done`) had no list item, so the page showed 8 of the
  9 handoff steps. The compatibility scanner was missing from the test layers ("two" → three).
  Both this page and `README.md` pointed at a plan as the full decision log instead of
  `docs/decision-log.md`. The page now also carries a version stamp.
- **`CLAUDE.md`**: `plan/` holds three design records, not two. `readability-preflight-plan.md`
  was invisible from the always-loaded file that is supposed to point at it.

### Not in this release

- **A check that the "→ Pick up here" item also exists in Open work.** The rule is in the
  command and was still broken by hand once. Catching it needs matching an item by identity
  rather than by text, which is the same stable-item-ID design the carried-twice problem needs.
  Recorded as one open design question rather than half-built.
## [0.4.2] — 2026-08-21

[GitHub release](https://github.com/muckybuzzwoo/claude-session-handoff/releases/tag/v0.4.2).

Reader side of the v0.4.1 fix. `/session-handoff` wrote three things `/session-resume` never
read. Same subagent review (`reviews/subagent-review-2026-08-21.md` §3).

### Fixed

- **`Format:` is now read, and is the only format signal.** Resume inferred the format from the
  shape of a `[READ-AT-RESUME]` tag, which is false in both directions: a format-2 file may write
  a bare tag (write-time ladder case (d)), and a format-1 file may carry a section anchor, because
  anchors shipped three weeks before the field did. Step 1 reads the field with `Date`, and the
  error-handling table keys the old format off the field's absence instead of the tag.
- **The one-hop carry resolution accepts both Open-work headings.** It only knew `## Open work`.
  At the format boundary — the only hop that exists in the field — the target always has
  `## Deferred & open questions`, so the section it was told to read was the one heading it could
  not find.
- **`- Done:` bullets are no longer folded in as open work.** They are closed items. On a format-2
  hop target they can be the whole section, which meant resume presented closed items as open. The
  hop file's own `Carried unchanged:` line is excluded too.
- **The count check has defined operands.** "Count mismatch → name both numbers" named nothing to
  compare, and the only computable reading fires on every correct chain. Resume now checks the same
  conservation law the compat scanner enforces, reports the arithmetic, and explicitly does not
  treat a plain `N` vs `prev_total` difference as a mismatch.

### Tests

Static suite **176 → 196**. New Section U asserts the carry-hop rules **inside** the carry bullet
rather than anywhere in the file (1669 of 12902 characters), so a rule that drifts out of the
bullet fails the check. One old check was removed rather than kept: it asserted the phrase
"old handoff format" on the bare-tag bullet, and that phrase was the defect.

### Compatibility

Reader-only. No template change, no format change, nothing written or migrated.

## [0.4.1] — 2026-08-21

[GitHub release](https://github.com/muckybuzzwoo/claude-session-handoff/releases/tag/v0.4.1).

Bug fix. v0.4.0 shipped two rules that contradicted each other, and the contradiction let an
open item disappear — the exact defect v0.4.0 was written to prevent. Found by a subagent
review (`reviews/subagent-review-2026-08-21.md`), reproduced against this repo's own
`format-boundary` artifact.

### Fixed

- **Hard rules no longer forbid what Step 3 requires.** The "next action exists exactly once"
  rule said Open work never repeats it. Step 3 said the item must be there or it is lost. The
  Hard rule now scopes "exactly once" to the *prose* and points at the item rule.
- **The per-item, explicit-closing and next-action-is-also-an-item rules moved to Hard rules.**
  They sat inside Step 3, which only runs from `_02` on, so the first handoff of every new chain
  never read them.
- **The carry formula was the one the project had already retracted.** `N` dropped the
  `written_out_still_open` term, so it contradicted the carry-line rule three lines above it
  and the conservation law the compat scanner enforces. Both statements now agree.
- **`tests/behavioral/format-boundary/verify.ps1`** matched the new item anywhere in the file,
  so the Status sentence satisfied it. It is now scoped to the `## Open work` block and requires
  a labelled bullet. It correctly fails against the pre-fix artifact.

Static suite unchanged at 176/176. No template change, no format change — `Format: 2` files
written under v0.4.0 stay valid.

## [0.4.0] — 2026-08-21

[GitHub release](https://github.com/muckybuzzwoo/claude-session-handoff/releases/tag/v0.4.0).

Readability. A handoff now opens with what the next session needs in order to **act**, and
every open item is individually addressable so it can be closed instead of quietly
disappearing. Driven by measurement, not taste: a scan of a real 176-file chain found **2570
open items**, of which **1436 were invisible** inside collapsed bullets.

### Added

- **`## Status` head.** Two one-sentence bullets — where the topic stands, what this session
  changed. First thing in the file.
- **`→ Pick up here` moved to the top**, not duplicated. The next action exists exactly once
  in the file, which is why the Status block has no `Next:` line. It is a *spotlight, not a
  container*: the item it names still lives in Open work so it stays countable.
- **`## Open work`** replaces `## Deferred & open questions`, with labels `Open:`,
  `Deferred:`, `Question:`, `Done:`, `Unresolved carry:` and `Carried unchanged:`. Step 1's
  open TodoWrite items finally have a documented home.
- **The counted carry rule.** Items that are new, changed or closed are written out in full,
  one per bullet. The rest are carried by a single `Carried unchanged: {N} items — see {file}`
  line pointing only at the immediately previous file. `N` is a conservation law —
  `carried + closed + written-out` may never fall short of the previous total, and the
  shortfall is the number of items that vanished. Verification needs **one hop**, never a walk
  back through the chain. Closing an item is a written `Done:` act; **an item may never leave
  by being omitted.**
- **Counting grammar**, because "count the items" was undefined: split only on ` · `, join
  wrapped continuation lines first, a bullet ending in `:` is a label whose children (`- ` or
  numbered) are the items, and a label before a colon re-attaches to every item split out of
  it.
- **`**Format:** 2` header field.** A missing field means format 1 and stays valid forever.
- **`tests/compat-old-chain.ps1`** — a standalone, LLM-free scanner for any existing chain.
  Reports the format census and item counts, and fails when the carry arithmetic does not add
  up. Run it before and after a format change to make "nothing was lost" a measurement.

### Changed

- **Resume briefing order.** Opens with where it stands, what changed, and the next action,
  then the open work, and only then the depth. **The completeness requirement is unchanged** —
  "carry the full decisions, explicitly list rejected options, do not compress those away"
  stays verbatim. This release reorders, it does not drop.
- Resume resolves a carry line **exactly one hop** and refuses to walk further.
- Five clarifications surfaced by the G1 gate run: an explicit `[READ-AT-RESUME]` tag outranks
  the outside-project skip; a size claimed in prose is never substituted for a file that was
  not opened; a `Tree:` field written as prose skips the staleness comparison instead of
  faking a difference; a section the template does not know is carried, and surfaced with the
  open work when it flags doubt; the memory reconcile runs only when the index belongs to the
  same project.

### Compatibility

- **No migration, and no old file is ever rewritten.** The command only ever creates
  `_NN+1`; the sole touch on an existing handoff is `--done`, which moves it with `git mv`.
- Step 3 **accepts both headings**. Every one of the 176 files in the reference chain uses the
  old one.
- At the format boundary the carry count is **established** from the old file, not inherited.
  A prose pointer with no number stays one `Unresolved carry:` item — no count is ever
  invented.
- A running session does not pick up a redeployed command file, so sessions already open keep
  writing format 1 until they restart. Harmless by design.

### Tests

- Static suite **107 → 176 checks**, including index-based *order* assertions and a
  self-test that the carry guard actually fires (a correct fixture chain must pass, a chain
  with dropped items must fail and name them).
- New behavioural sub-test `tests/behavioral/format-boundary/` — a subagent writes the first
  new-format handoff onto an old-format predecessor shaped like the hardest real file. 25
  assertions, including that the predecessor stays byte-identical. **Passed.**
- **Gate G1 passed** (`tests/behavioral/old-format-resume/`): five *real* old handoffs, each
  with a different structural deviation (bare `## Reference`, a renamed Decisions heading,
  bold-wrapped tags, no footer at all, an extra section, no tags), all still resume, and all
  five are byte-identical afterwards. 43 assertions. Real files are copied into a gitignored
  sandbox at run time and never committed.
- **Known coverage limit:** in G1 every linked target lay outside the sandbox, so that run
  exercised no tagged-link *loading*. That path is covered by the existing
  `tests/behavioral/depth-recovery/` sub-test, not by G1.

### Not in this release

- Track B (v0.5.0): pre-flight obligations and moving the closing reflection before the write.
- Deferred: hard length budgets per item (1D), and a non-interactive fallback for the
  untagged-plan load offer.

## [0.3.0] — 2026-07-29

First real-project `/session-resume` run (addendum 8e) confirmed the token-aware **loading**
works as designed (~55k avoided on a 98 KB backlog behind a bare tag). The three fixes here
close gaps found *beside* the loading path — in the handoff content and the resume's
consistency check, not in what gets loaded.

### Added

- **After-handoff reminder (handoff Step 9).** The confirm block now always closes with a
  fixed note: anything done *after* the handoff is invisible to the next resume — run the
  command again to capture it as the next `_NN`. A handoff is a point-in-time snapshot; this
  makes that explicit at the moment it matters.
- **Cross-chain pointer (handoff + resume).** The "→ Pick up here" block gains an optional
  `Continue first in: <chain> @ <absolute project path>` line for when the genuinely next
  step lives in another handoff chain or repo. Resume surfaces it at the top of the briefing
  — it prints the pointer only, it never opens or loads the other project.
- **Memory-index reconciliation (resume Step 4).** Resume now compares its briefing against
  the auto-loaded `MEMORY.md` and flags any contradiction (a handoff reflects only its write
  time; memory may be newer). It names both states and resolves neither silently. Costs no
  extra load — the index is already in context.

### Notes

- The load discipline itself is unchanged — it validated in the real test, so it was left
  alone (including the untagged-plan-like-link offer rule).

### Tests

- Static suite grew to **107 checks** (new Section Q for the three 8e findings).

## [0.2.0] — 2026-07-29

[GitHub release](https://github.com/muckybuzzwoo/claude-session-handoff/releases/tag/v0.2.0).

### Changed — token-aware loading (keeps resume cheap on large projects)

Motivated by real measurements in another project where a single `/session-resume` cost
~40–97k tokens, almost all of it one or two large files that were re-read in full every time.

- **Handoff now classifies each linked file by size (in bytes, not lines) at save time** and
  picks the cheapest option: if the handoff already carries the file's essence → a plain lazy
  link, no auto-load tag; if only one section matters → a section anchor
  `[READ-AT-RESUME: <heading>]`; if a big whole file is needed → inline its essence + offer an
  archive-split; otherwise a plain `[READ-AT-RESUME]` tag.
- **Resume loads only what's needed** — section anchors pull just that section; a bare tag on a
  large file is read with a safeguard (headings + relevant part, not the whole file); an
  untagged plan-like file is peeked (table of contents) and offered, never blind-loaded. This
  reverses the earlier "full-load anything that looks like a plan" behaviour, which was the
  main cost leak.
- **New opt-in archive-split** (handoff Step 7d, suggestion-only): when a large file has
  finished sections, the handoff can offer to move them verbatim into a `-DONE.md` sibling —
  you confirm each time, nothing is deleted, open to-dos are never archived, own revertible
  commit.
- **Backward-compatible:** old-format handoffs (bare `[READ-AT-RESUME]`, no anchor) resume
  unchanged; no migration — existing chains of any length keep working, the new format appears
  from the next handoff on.

### Tests

- Static suite grew to **99 checks** (new Section P for the load paths).
- New behavioural sub-test `tests/behavioral/load-discipline/` (21 checks): proves at runtime
  that a section anchor loads only its section and an untagged big file is not read whole.

## [0.1.0] — 2026-07-03

First release ([GitHub release](https://github.com/muckybuzzwoo/claude-session-handoff/releases/tag/v0.1.0)).

### Commands

- `/session-handoff [topic] [--done]` — capture the current session into a structured,
  resumable, gitignored handoff file under `.claude/session-handoffs/`, then stop.
- `/session-resume [topic] [--all]` — pick the right handoff, reload full context, continue.

### Features

- Topic chains with carry-forward (`{slug}_{NN}.md`); the newest file is always the
  complete state.
- Closing reflection (propose-only): memory candidates, plan-drift updates, stale-doc
  refreshes — shown first, written only on confirmation.
- `[READ-AT-RESUME]` deep links: resume dereferences linked plan/spec/decision files and
  folds their depth (incl. rejected options) into the summary.
- Staleness check with `Tree:` snapshot: flags age > 7 days, branch change, and actual
  working-tree movement against the recorded porcelain snapshot.
- Archive lifecycle: `--done` moves a chain to `done/`; hidden from resume unless `--all`
  (marked `(archived)`); re-handoff on an archived slug asks un-archive vs. fresh.
- No-handoff fallback: memory + git orientation briefing instead of a dead end.
- Invocation policy: user-driven — slash or plain-text ask runs the commands; Claude may
  suggest a handoff at session end but never runs one unasked.
- Windows-safe, platform-conditional execution (PowerShell batching on `win32` hosts that
  block chained Bash; plain chained Bash elsewhere).

### Tests

- Static: `tests/validate-commands.ps1`, 85 checks incl. source==deployed parity.
- Behavioral (subagent-driven): 3 scenarios (26 checks) + deep-link depth-recovery
  sub-test (15 checks).

### Known limitations

- Sandbox-tested only; real-project runtime test outstanding.
- Maintainer test suites require PowerShell 7; the commands themselves do not.
