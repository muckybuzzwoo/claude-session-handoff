# Changelog

All notable changes to the `/session-handoff` + `/session-resume` commands.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/); versions follow semver.

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
