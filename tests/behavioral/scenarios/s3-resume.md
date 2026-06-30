# Behavioral scenario S3 — resume (staleness + read-only)

Automated, NON-INTERACTIVE test. Placeholders `<<SANDBOX_PROJ>>` / `<<CMD_RESUME>>` are
substituted by the orchestrator. The `widget-redesign` chain (seq 01 + 02) already exists
in `<<SANDBOX_PROJ>>/.claude/session-handoffs/`; the latest file's `Date:` header has been
back-dated to make it deliberately stale.

## Operating procedure
Read and follow exactly: `<<CMD_RESUME>>` (the `/session-resume` command). Execute it.

## Test overrides
- Project root / cwd = `<<SANDBOX_PROJ>>`; absolute paths; `git -C "<<SANDBOX_PROJ>>"`.
- Non-interactive: load topic `widget-redesign` directly (given as argument — no picker).
- This command is READ-ONLY. Do NOT modify, create, or delete any handoff file.
- Honor "do not auto-implement": stop after the summary + suggested next action.

## Required final response
Report, clearly:
1. Which handoff file you loaded (absolute path + sequence).
2. The staleness assessment (state the age in days and whether it is stale).
3. A compact summary and the single suggested "→ Pick up here" next action.
Then stop without doing any work.
