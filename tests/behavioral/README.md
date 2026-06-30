# Behavioral tests (subagent-driven)

Closes the gap the static harness (`../validate-commands.ps1`) cannot reach: **does an LLM
actually behave correctly when it executes the command instructions?** A subagent *is* an
LLM in the loop, so it can run the command for real against a throwaway project and we
assert on the artifacts it produces.

## How it works

1. `setup-sandbox.ps1` builds a fresh, **isolated** project under `.sandbox/` (gitignored):
   a real git repo, a fake superpowers spec (with a `SENTINEL_…` body) and plan (a
   checklist), plus an existing `.gitignore`. The real maintenance repo and the user's real
   Claude memory are never touched (a verifier check enforces this).
2. Three subagents are dispatched (by Claude — see "Running it"), each told to **read the
   real command file** (`../../commands/*.md`) and execute it for a simulated session, with
   the sandbox as project root:
   - **S1** — fresh handoff `_01`: superpowers spec/plan in play, a durable fact (WCAG) and a
     topic-scoped decision (grid), work that completed plan Step 2.
   - **S2** — carry-forward `_02`: same topic again, asserts sequence + `Previous:` link +
     additive decisions.
   - **S3** — resume: latest handoff back-dated to 29 days old, asserts staleness note +
     read-only.
   Each agent's final response is captured to `.sandbox/out/S{1,2,3}.txt`.
3. `verify-artifacts.ps1` runs deterministic assertions on the artifacts (26 checks) and
   exits 0/1.

## Running it

This suite is **driven by Claude**, not a standalone script — dispatching the subagents
requires a Claude session. To re-run, ask Claude:

> "Run the behavioral test suite in tests/behavioral (setup → S1 → S2 → backdate+snapshot →
> S3 → verify)."

The scenario inputs are committed (`scenarios/s{1,2,3}-*.md`, with `<<SANDBOX_PROJ>>` /
`<<CMD_*>>` placeholders the orchestrator substitutes), so the run is reproducible. The
`verify-artifacts.ps1` step IS standalone — `pwsh -File .\verify-artifacts.ps1` re-checks
the artifacts of the most recent run.

## What it proves

- Handoff writes all required sections; references the superpowers spec/plan **by path**
  and does **not** copy the spec body (sentinel absent).
- gitignore append branch works.
- **Step 7 is propose-only**: the durable fact (WCAG) is surfaced as a memory candidate, the
  topic-scoped grid decision is NOT, a plan edit is proposed — and neither memory nor the
  plan file is written without confirmation.
- Carry-forward: `_02` links `_01` and keeps prior decisions while adding new ones.
- Resume: detects the 29-day staleness, suggests the next action, modifies nothing
  (SHA256 of every handoff stable across the resume run).

## Focused sub-test: deep-link depth recovery (`depth-recovery/`)

Self-contained, separate from the S1/S2/S3 sandbox above — proves the `[READ-AT-RESUME]`
contract: that `/session-resume` Step 4 actually **opens linked decision/plan files** and
folds their depth in, instead of parroting the compressed handoff text.

- `setup.ps1` builds its own isolated sandbox: a deliberately **compressed** handoff
  `auth-flow_01.md` that links a plan tagged `[READ-AT-RESUME]`. The rejected option's
  distinctive words (`magic`, `fixation`, a `REJECTED_…` sentinel) live ONLY in the plan,
  never in the handoff — a sentinel differential.
- One subagent runs `/session-resume auth-flow`; its summary is captured to
  `.sandbox/out/S4.txt`.
- `verify.ps1` (15 checks) asserts those plan-only words surfaced in the summary — which is
  only possible if the link was dereferenced — plus read-only and no-leak isolation.

Run: `setup.ps1` → dispatch the `scenario.md` agent → write its reply to
`.sandbox/out/S4.txt` → `pwsh -File .\depth-recovery\verify.ps1`.

## Limits (honest scope)

- **Non-deterministic.** LLM output varies between runs; assertions target artifact
  structure, not prose, to stay robust — but a rerun can still surface a model wobble.
  Treat a single failure as "investigate", not "the command is broken".
- **The interactive pause is simulated.** No real human answers the AskUserQuestion gates;
  the agents are told to treat Step 7 as propose-only and print drafts. This proves the
  *detection + drafting + don't-auto-write* property — NOT the literal "ask, user says yes,
  then write" path, which stays a manual check.
- When the sandbox has no memory dir, the agent drafts a memory entry with an invented
  frontmatter shape (it cannot see the real schema). In a real project with an existing
  `MEMORY.md`, the command instructs it to follow the format already in use there.
