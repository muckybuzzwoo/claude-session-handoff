# Behavioral scenario T1 — handoff in a repo whose store is already ignored

Automated, NON-INTERACTIVE test. Placeholders `<<SANDBOX_PROJ>>` / `<<CMD_HANDOFF>>` are
substituted by the orchestrator.

**Nothing in this file says what the header of the handoff must look like, what to do about
`.gitignore`, or what your report has to contain.** The rules live in the command file and
nowhere else, so this scenario measures what the command makes you do.

## Operating procedure
Read and follow exactly: `<<CMD_HANDOFF>>` (the `/session-handoff` command). Execute it for the
simulated session below.

## Test overrides
These are facts about the harness, not answers to the test.

- Project root / cwd = `<<SANDBOX_PROJ>>`; use absolute paths; `git -C "<<SANDBOX_PROJ>>"`.
- Non-interactive: the topic is given as an argument, so there is no picker.
- No human is available to answer anything. Where the command tells you to ask, state the
  question in your response and carry on without an answer.
- This sandbox has no Claude memory directory. Do not create one and do not write a memory
  file; print any candidate instead. Do not edit any project file other than what the
  command itself writes.
- Sandbox hygiene: never read or write anything outside `<<SANDBOX_PROJ>>`, except the
  command file named above.
- Windows host: never chain shell commands with `&&`, `||`, or `;` in one Bash call — use
  separate calls (a hook hard-blocks chains). No leading `cd`.

## Simulated session to capture
- Topic argument: `tae`
- Work done: you read `<<SANDBOX_PROJ>>/src/app.ts` and found that `retryTimeoutMs` (10000) is
  shorter than the slowest upstream call. You changed no file.
- Decision: raise the timeout to 30000 rather than add a second retry.
- Open: raising the timeout is not done yet. It is the next action.
- No plan, no spec, no background processes, no durable facts beyond this topic.

## Required final response
Produce whatever the command tells you to produce, and state the absolute path of the
handoff file you wrote. Never invent state, and say so explicitly if you could not do or
check something.
