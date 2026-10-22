# Behavioral scenario T2 / T3 / T4 — resume against a recorded `Tree:` header

Automated, NON-INTERACTIVE test. Placeholders `<<SANDBOX_PROJ>>` / `<<CMD_RESUME>>` /
`<<TOPIC>>` are substituted by the orchestrator (`same`, `prose` or `moved`, one run each).
The chains already exist in `<<SANDBOX_PROJ>>/.claude/session-handoffs/`.

**Nothing in this file describes those files, what their `Tree:` header says, whether the
working tree matches it, or what your briefing has to contain.** The rules live in the command
file and nowhere else, so this scenario measures what the command makes you do.

## Operating procedure
Read and follow exactly: `<<CMD_RESUME>>` (the `/session-resume` command). Execute it for
topic `<<TOPIC>>`.

## Test overrides
These are facts about the harness, not answers to the test.

- Project root / cwd = `<<SANDBOX_PROJ>>`; use absolute paths; `git -C "<<SANDBOX_PROJ>>"`.
- Non-interactive: load topic `<<TOPIC>>` directly (given as argument — no picker).
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
2. Which commands you ran to check the working tree, if any.

If you could not find or read something, say so explicitly. Never invent content.
