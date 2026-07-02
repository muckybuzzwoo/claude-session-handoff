# Changelog

All notable changes to the `/session-handoff` + `/session-resume` commands.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/); versions follow semver.

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
