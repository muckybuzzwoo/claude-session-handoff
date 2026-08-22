# Behavioral scenario S3 — resume (staleness + read-only)

Automated, NON-INTERACTIVE test. Placeholders `<<SANDBOX_PROJ>>` / `<<CMD_RESUME>>` are
substituted by the orchestrator. The `widget-redesign` chain (seq 01 + 02) already exists in
`<<SANDBOX_PROJ>>/.claude/session-handoffs/`.

**Nothing in this file describes the state of those files or tells you what your response has
to contain.** That is deliberate. An earlier version said the latest file had been back-dated
to make it stale and then asked for a staleness assessment, which handed over the exact thing
the verifier looks for. The rules live in the command file, and this scenario measures what the
command makes you do.

## Operating procedure
Read and follow exactly: `<<CMD_RESUME>>` (the `/session-resume` command). Execute it.

## Test overrides
These are facts about the harness, not answers to the test.

- Project root / cwd = `<<SANDBOX_PROJ>>`; absolute paths; `git -C "<<SANDBOX_PROJ>>"`.
- Non-interactive: load topic `widget-redesign` directly (given as argument — no picker).
- No human is available to answer anything. Where the command tells you to ask, state the
  question in your response and carry on without an answer.
- Sandbox hygiene: never read or write anything outside `<<SANDBOX_PROJ>>`, except the command
  file named above.

## Required final response
Produce whatever the command tells you to produce. Add one fact at the end so the run can be
checked mechanically, and nothing else: which handoff file you loaded (absolute path +
sequence).
