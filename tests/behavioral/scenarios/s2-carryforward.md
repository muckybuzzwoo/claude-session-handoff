# Behavioral scenario S2 — carry-forward (sequence 02)

Automated, NON-INTERACTIVE test. Placeholders `<<SANDBOX_PROJ>>` / `<<CMD_HANDOFF>>` are
substituted by the orchestrator. A handoff `widget-redesign_01.md` already exists in
`<<SANDBOX_PROJ>>/.claude/session-handoffs/` from a previous run.

## Operating procedure
Read and follow exactly: `<<CMD_HANDOFF>>` (the `/session-handoff` command). Execute it for
the simulated session below.

## Test overrides (same as S1)
- Project root / cwd = `<<SANDBOX_PROJ>>`; absolute paths; `git -C "<<SANDBOX_PROJ>>"`.
- Non-interactive; topic given as argument.
- Step 7a: no memory dir → PRINT candidate, do not write.
- Step 7b: propose-only → PRINT proposal, do not edit the plan.
- Honor the HARD STOP.

## Simulated session to capture
- Topic argument: `widget-redesign` (this is the SAME chain → expect sequence 02 with a
  `Previous:` link to `widget-redesign_01.md`, and "Decisions & what shipped" must carry
  forward the earlier grid decision AND add this session's).
- Work done this session: added unit tests for the widget → new file
  `<<SANDBOX_PROJ>>/src/widget.test.js`. This completes **Step 3** of the plan.
- Decision: used the project's existing test runner rather than adding a new one.
- No new durable fact emerged this session.
- Open question still open: first-paint animation (deferred).

## Required final response
State the absolute path of the handoff file you wrote and its sequence number. If you would
print a memory candidate or plan proposal, do so under the same `=== ... ===` headers as
S1; otherwise state "no memory candidate" / "no plan change". Then stop.
