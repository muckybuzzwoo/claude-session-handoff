# Behavioral scenario — load discipline (section anchors + untagged not auto-loaded)

Automated, NON-INTERACTIVE test. Placeholders `<<SANDBOX_PROJ>>` / `<<CMD_RESUME>>` are
substituted by the orchestrator. A single handoff already exists at
`<<SANDBOX_PROJ>>/.claude/session-handoffs/perf-tuning_01.md`, and it links other files in
the sandbox.

**Nothing in this file says how those links are tagged, which of them you should read, how
much of each you should read, or what your summary has to contain.** That is deliberate. Those
rules live in the command file and nowhere else, so this scenario measures what the command
makes you do. An earlier version restated the Step 4 rules here and even said which file not
to load, which measured prompt obedience instead of the command.

## Operating procedure
Read and follow exactly: `<<CMD_RESUME>>` (the `/session-resume` command). Execute it for
topic `perf-tuning`.

## Test overrides
These are facts about the harness, not answers to the test.

- Project root / cwd = `<<SANDBOX_PROJ>>`; use absolute paths; `git -C "<<SANDBOX_PROJ>>"`.
- Non-interactive: load topic `perf-tuning` directly (given as argument — no picker).
- No human is available to answer anything. Where the command tells you to ask or offer a
  choice, state the question or offer in your response and carry on without an answer.
- Sandbox hygiene: never read or write anything outside `<<SANDBOX_PROJ>>`, except the
  command file named above.
- Windows host: never chain shell commands with `&&`, `||`, or `;` in one Bash call — use
  separate calls (a hook hard-blocks chains). No leading `cd`.

## Required final response
Produce whatever the command tells you to produce. Add these facts at the end so the run can
be checked mechanically, and nothing else:
1. Which handoff file you loaded (absolute path + sequence).
2. For **each** file the handoff links: its absolute path, and whether you read all of it,
   part of it (say which part), or none of it.

If you could not find or read something, say so explicitly. Never invent content.
