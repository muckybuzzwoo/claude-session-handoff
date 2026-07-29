# Behavioral scenario — load discipline (section anchors + untagged not auto-loaded)

Automated, NON-INTERACTIVE test. Placeholders `<<SANDBOX_PROJ>>` / `<<CMD_RESUME>>` are
substituted by the orchestrator. A single handoff already exists at
`<<SANDBOX_PROJ>>/.claude/session-handoffs/perf-tuning_01.md`. It links two files:

- a large living doc `docs/perf-backlog.md`, tagged with a **section anchor**
  `[READ-AT-RESUME: Current bottleneck]`, and
- a plan-like `docs/roadmap.md`, linked **without any tag**.

## Operating procedure
Read and follow exactly: `<<CMD_RESUME>>` (the `/session-resume` command). Execute it for
topic `perf-tuning`. Follow its Step 4 link-resolution rules precisely:

- A `[READ-AT-RESUME: <heading>]` tag means: read **only** that heading's section (grep the
  heading, then a targeted read down to the next heading) — **not** the whole file.
- An **untagged** plan/roadmap-like link means: do **not** full-load it — peek its heading
  skeleton and offer to load it; do not pull its body.

## Test overrides
- Project root / cwd = `<<SANDBOX_PROJ>>`; use absolute paths; `git -C "<<SANDBOX_PROJ>>"`.
- Non-interactive: load topic `perf-tuning` directly (given as argument — no picker). No
  human is here to answer the untagged-file load-offer, so do **not** load the roadmap —
  state the offer instead.
- This command is READ-ONLY. Do NOT modify, create, or delete any file.
- Honor "do not auto-implement": stop after the summary + suggested next action.
- Windows host: never chain shell commands with `&&`, `||`, or `;` in one Bash call — use
  separate calls (a hook hard-blocks chains). No leading `cd`.

## Required final response
Produce the Step-4 summary the command asks for, then report explicitly:
1. Which handoff file you loaded (absolute path + sequence).
2. For **each** linked file: its absolute path, whether you read it, and — if you read only
   part of it — which section(s) you read and which you deliberately did NOT read.
3. The compact summary of where to pick up (the current bottleneck and its fix direction).
4. The single suggested "→ Pick up here" next action.

If you could not find or read something, say so explicitly — never invent content. Then
stop without doing any work.
