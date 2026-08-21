# Changelog

All notable changes to the `/session-handoff` + `/session-resume` commands.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/); versions follow semver.

## [0.4.2] — 2026-08-21

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
