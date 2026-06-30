# Behavioral scenario — deep-link depth recovery ([READ-AT-RESUME] contract)

Automated, NON-INTERACTIVE test. Placeholders `<<SANDBOX_PROJ>>` / `<<CMD_RESUME>>` are
substituted by the orchestrator. A single handoff `auth-flow_01.md` already exists in
`<<SANDBOX_PROJ>>/.claude/session-handoffs/`. It is a COMPRESSED pointer: its Reference and
Key-files sections link a plan tagged `[READ-AT-RESUME]`, and that plan — not the handoff —
holds the full roadmap and the grilled/rejected decisions.

## Operating procedure
Read and follow exactly: `<<CMD_RESUME>>` (the `/session-resume` command). Execute it for
topic `auth-flow`.

## Test overrides
- Project root / cwd = `<<SANDBOX_PROJ>>`; use absolute paths; `git -C "<<SANDBOX_PROJ>>"`.
- Non-interactive: load topic `auth-flow` directly (given as argument — no picker).
- This command is READ-ONLY. Do NOT modify, create, or delete any file.
- Honor "do not auto-implement": stop after the summary + suggested next action.

## Required final response
Produce the Step-4 summary the command asks for. It MUST reflect not just the handoff text
but the substance of every `[READ-AT-RESUME]` / plan / spec file it links — in particular,
**explicitly list the rejected options and why they were discarded**. Then report:
1. Which handoff file you loaded (absolute path + sequence).
2. Which linked files you additionally read (absolute paths).
3. The compact summary, including the decision made AND the rejected alternatives.
4. The single suggested "→ Pick up here" next action.
Then stop without doing any work.
