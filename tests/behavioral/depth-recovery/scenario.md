# Behavioral scenario — deep-link depth recovery ([READ-AT-RESUME] contract)

Automated, NON-INTERACTIVE test. Placeholders `<<SANDBOX_PROJ>>` / `<<CMD_RESUME>>` are
substituted by the orchestrator. A single handoff `auth-flow_01.md` already exists in
`<<SANDBOX_PROJ>>/.claude/session-handoffs/`.

**Nothing in this file says what that handoff links, what those linked files contain, or what
your summary has to include.** That is deliberate. The command file is the only place those
rules exist, so this scenario measures what the command makes you do rather than what this
prompt told you to do. An earlier version of this file spelled the expected output out and
therefore measured prompt obedience instead.

## Operating procedure
Read and follow exactly: `<<CMD_RESUME>>` (the `/session-resume` command). Execute it for
topic `auth-flow`.

## Test overrides
- Project root / cwd = `<<SANDBOX_PROJ>>`; use absolute paths; `git -C "<<SANDBOX_PROJ>>"`.
- Non-interactive: load topic `auth-flow` directly (given as argument — no picker).
- Sandbox hygiene, not a rule under test: never read or write anything outside
  `<<SANDBOX_PROJ>>`, except the command file named above.

## Required final response
Produce whatever the command tells you to produce. Add these two facts at the end so the run
can be checked mechanically, and nothing else:
1. Which handoff file you loaded (absolute path + sequence).
2. Which other files you read, if any (absolute paths).
