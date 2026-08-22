# Behavioral scenario — carry-hop resolution (the READ half of the carry rule)

Automated, NON-INTERACTIVE test. Placeholders `<<SANDBOX_PROJ>>` / `<<CMD_RESUME>>` are
substituted by the orchestrator. A `mig` chain already exists in
`<<SANDBOX_PROJ>>/.claude/session-handoffs/`.

**Nothing in this file describes those files, how many items are open, which of them are
closed, or what your briefing has to contain.** That is deliberate. The rules live in the
command file and nowhere else, so this scenario measures what the command makes you do.

## Operating procedure
Read and follow exactly: `<<CMD_RESUME>>` (the `/session-resume` command). Execute it for
topic `mig`.

## Test overrides
These are facts about the harness, not answers to the test.

- Project root / cwd = `<<SANDBOX_PROJ>>`; use absolute paths; `git -C "<<SANDBOX_PROJ>>"`.
- Non-interactive: load topic `mig` directly (given as argument — no picker).
- No human is available to answer anything. Where the command tells you to ask or offer a
  choice, state the question or offer in your response and carry on without an answer.
- Sandbox hygiene: never read or write anything outside `<<SANDBOX_PROJ>>`, except the
  command file named above.
- Windows host: never chain shell commands with `&&`, `||`, or `;` in one Bash call — use
  separate calls (a hook hard-blocks chains). No leading `cd`.

## Required final response
Produce whatever the command tells you to produce. Add these two facts at the end so the run
can be checked mechanically, and nothing else:
1. Which handoff file you loaded (absolute path + sequence).
2. Which other files you read, if any (absolute paths).

If you could not find or read something, say so explicitly. Never invent content, and never
state an item you did not read in a file you opened.
