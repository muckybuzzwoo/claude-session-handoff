# Gemini Plan Review
**Document:** plan/readability-preflight-plan.md
**Backend:** codex
**Role:** QA Engineer
**Model:** codex CLI default
**Package:** Compact
**Estimated tokens:** ~14300
**Date:** 2026-08-21
---

## Overall Rating

3 — Important concerns, address before shipping. The plan is unusually evidence-rich, but several behavioral requirements remain ambiguous or depend on manual judgment, making reliable automated testing and release gating difficult.

## Critical Issues

- V4 blocks Track A, yet its acceptance behavior is not defined. Options (a)–(c) materially change storage, migration, and assertions. No implementation or test should start until Marcus selects an option and the plan defines exact carry-forward/closure semantics.

- “Small” means “roughly five tool calls or fewer,” which is not deterministically testable. Define the classifier inputs and boundary behavior: exactly five calls, unknown call count, retries, tool failures, and whether a read-only obligation counts.

- Pre-flight’s “first hit wins” source rule conflicts with fallback discovery ambiguity. Specify whether an empty declared checklist suppresses fallback, how malformed headings/items behave, and what counts as a checklist item (nested bullets, checkboxes, prose, code blocks).

- The behavioral preflight test cannot prove the stated interaction contract without a controllable AskUserQuestion harness. It needs fixtures for do-now, skip, record, no response/cancel, explicit OK for outward-facing work, and mid-execution failure.

- G2 requires splitting legacy run-on bullets “without losing or inventing an item,” but defines no parsing grammar. Dot-separated text, escaped separators, nested lists, wrapped lines, and natural-language lists make the expected item count subjective.

- Track B’s archive-split baseline is required but underspecified: no fixture shape, trigger threshold, expected artifacts, or test driver is defined. G3’s “character for character” requirement also conflicts with expected timestamps, paths, commits, and reordered execution.

- The crash window introduced by reflection-before-write has no testable recovery requirement. “Fall-through” covers handled obligation failures, not process termination, interrupted writes, partial archive changes, or failures after reflection mutations.

## Improvement Suggestions

- Turn each static requirement into named assertions with stable error messages and fixtures, including negative cases.

- Add a state-transition test matrix for Step 0: source found/not found, triggered/not triggered, met/unmet/unknown, small/large/outward-facing, user decision, execution outcome, and handoff result.

- Define deterministic test doubles for tools, user prompts, clock, git state, byte-size stats, and failure injection points.

- Add a golden-artifact suite for old-format, new-format, mixed-chain, and pointer-compressed handoffs. Assert both semantic content and canonical section ordering.

- Add idempotency tests: rerunning handoff after a failed obligation or after a completed small obligation must not execute it twice or duplicate Open work.

- Instrument command runs with structured events for obligation detection, classification, prompt decision, execution result, archive-split classification, and write completion. Redact sensitive task/comment content.

- Add performance limits for large handoff chains and large plan files, plus a bounded test corpus for the 175-file APEX history.

## Positives

- The plan separates Track A and Track B clearly, requires each intermediate commit to remain green, and calls out compatibility testing explicitly.

- G1 identifies real historical handoff variants rather than relying only on synthetic fixtures.

- The plan correctly preserves legacy resume fixtures as backward-compatibility inputs.

- The pre-flight invariants are strong: outward-facing work needs explicit confirmation, failures do not block capture, and no obligations means silent continuation.

- The plan recognizes that static text checks alone cannot validate archive-split behavior and requires a behavioral baseline first.

## Open Questions

- What exact output is expected when the user chooses “skip” versus “record as open work”? Does skip remain visible anywhere?

- If multiple obligations qualify, does one declined or failed item prevent later confirmed small items from running?

- What does “still unmet” mean operationally, and how is it established without extra reads?

- What exactly constitutes “this session’s work actually triggers” an obligation?

- How should old-format Open work be mapped when it contains unlabelled bullets, duplicate next actions, or pointer compression?

- For V4 option (b), where is the canonical item list stored, how is its target validated, and what happens if the referenced handoff is missing?

- What metric and sample size define “clearly better” for the readability rubric and Method B field trial?

- Who performs and records the blind rubric, and how is reviewer/version blinding maintained?

## Missing Aspects

- No complete regression strategy is defined for interrupted commands, repeated invocations, partial writes, filesystem failures, git failures, or user cancellation.

- No test-data governance exists for copying “real” APEX handoffs into test environments, including sanitization, retention, and fixture versioning.

- No environment-parity plan covers Claude Code versions, operating systems, command deployment paths, permissions, or differences between interactive and headless execution.

- No accessibility/usability acceptance criteria cover AskUserQuestion wording, choice defaults, long obligation lists, or actionable failure messages.

- No release gate defines required test commands, supported test environments, ownership for reviewing failures, or rollback verification after deployment.
