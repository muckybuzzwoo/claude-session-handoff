# Behavioral scenario — compatibility gate G1 (resume real pre-v0.4.0 handoffs)

Automated, NON-INTERACTIVE test. Placeholders `<<SANDBOX_PROJ>>`, `<<CMD_RESUME>>` and
`<<TOPIC>>` are substituted by the orchestrator, **once per topic** that `setup.ps1` reported
on its `TOPICS=` line. Run this scenario once per topic, as a separate agent each time.

`setup.ps1` copied real, pre-v0.4.0 handoff files into
`<<SANDBOX_PROJ>>/.claude/session-handoffs/`. They were written before the current format
existed, so they deviate from the template in ways the template does not describe. That is the
whole point of the gate: the command has to stay useful on files it did not shape, and it must
leave them untouched.

**Nothing in this file says how those files deviate, what they contain, or what your briefing
should conclude.** The rules live in the command file. Reporting the deviation you actually
observe is part of the output contract below — that is an observation, not an answer handed to
you.

## Operating procedure
Read and follow exactly: `<<CMD_RESUME>>` (the `/session-resume` command). Execute it for topic
`<<TOPIC>>`.

## Test overrides
These are facts about the harness, not answers to the test.

- Project root / cwd = `<<SANDBOX_PROJ>>`; use absolute paths; `git -C "<<SANDBOX_PROJ>>"`.
- Non-interactive: load topic `<<TOPIC>>` directly (given as argument — no picker).
- No human is available to answer anything. Where the command tells you to ask or offer a
  choice, state the question or offer in your response and carry on without an answer.
- Sandbox hygiene: never read or write anything outside `<<SANDBOX_PROJ>>`, except the command
  file named above.
- Windows host: never chain shell commands with `&&`, `||`, or `;` in one Bash call — use
  separate calls (a hook hard-blocks chains). No leading `cd`.

## Required output — write a FILE, not just a chat reply

Write your briefing to `<<SANDBOX_PROJ>>/../out/G1-<<TOPIC>>.md` (the `out/` directory beside
`proj/` in the sandbox — `setup.ps1` prints its absolute path as `SANDBOX_OUT=`).

The file must contain these four lines, each at the start of its own line, spelled exactly like
this, because `verify.ps1` matches them literally:

```
LOADED: <which files you actually read, absolute paths, and how much of each>
NEXT ACTION: <the single next action the handoff points at>
KEY FILES: <the files the handoff names as worth opening>
SOURCE-SHAPE: <what was structurally odd about this handoff, in your own words>
```

Around those four lines, write the briefing the command asks you to produce. The file has to be
substantial — a four-line stub is a fail, and so is reporting the handoff as unreadable when it
is merely shaped differently from the template.

`SOURCE-SHAPE:` is the interesting one. Say what you actually saw, not what you expected. If the
file matches the template exactly, say that.
