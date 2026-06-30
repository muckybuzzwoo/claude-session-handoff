# Behavioral scenario S1 — fresh handoff (sequence 01)

You are running an automated, NON-INTERACTIVE test of a Claude Code slash-command.
Placeholders `<<SANDBOX_PROJ>>` and `<<CMD_HANDOFF>>` are substituted by the orchestrator.

## Operating procedure
Read this file in full and treat it as your exact instructions:
`<<CMD_HANDOFF>>`
That is the `/session-handoff` command. Execute it for the simulated session below.

## Test overrides (critical — read carefully)
- The project root / cwd for this run is `<<SANDBOX_PROJ>>`. Interpret EVERY "cwd" or
  "project root" in the procedure as that absolute path. Write all files there with
  absolute paths. For git use `git -C "<<SANDBOX_PROJ>>" ...`.
- Non-interactive: there is no human to answer AskUserQuestion. The topic is given as an
  argument below, so topic confirmation is not needed.
- Step 7a (memory): this sandbox has NO Claude memory dir. Per the procedure's own
  fallback, do NOT create one and do NOT write a memory file — instead PRINT the drafted
  memory candidate (full frontmatter + body) in your final response.
- Step 7b (plan): there is no human to confirm, so treat it as propose-only — do NOT edit
  the plan file; PRINT the concrete proposed edit instead.
- Honor the HARD STOP: do not implement anything.

## Simulated session to capture
- Topic argument: `widget-redesign`
- This session used superpowers brainstorming + writing-plans. Committed artifacts:
  - spec: `<<SANDBOX_PROJ>>/docs/superpowers/specs/2026-06-30-widget-redesign-design.md`
  - plan: `<<SANDBOX_PROJ>>/docs/superpowers/plans/2026-06-30-widget-redesign.md`
- Work done: implemented the new layout → modified `<<SANDBOX_PROJ>>/src/widget.js` and
  `<<SANDBOX_PROJ>>/src/widget.css`. This completes **Step 2** of the plan.
- Decision: chose CSS **grid** over flexbox for the container (2D layout fits grid better).
- Durable fact that emerged: the client contractually requires **WCAG 2.2 AA** for all UI
  — a lasting project constraint, true beyond this topic.
- Running state: a dev server runs in the background (shell id `bg_1`).
- Open question: should the widget animate on first paint? (deferred)

## Required final response
After writing the handoff file, end with two clearly-labelled blocks, verbatim headers:
`=== MEMORY CANDIDATE ===` then the drafted entry, and
`=== PLAN EDIT PROPOSAL ===` then the proposed edit.
State the absolute path of the handoff file you wrote. Then stop.
