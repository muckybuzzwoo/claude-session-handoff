# Gemini Plan Review
**Document:** plan/readability-preflight-plan.md
**Backend:** codex
**Role:** Senior Software Architect
**Model:** codex CLI default
**Package:** Compact
**Estimated tokens:** ~14300
**Date:** 2026-08-21
---

## Overall Rating

3 — Important concerns, address before shipping. The plan is unusually evidence-driven, but it still contains unresolved semantic decisions and test designs that prevent its “independently revertible” tracks from being reliably implemented.

## Critical Issues

- **Track A’s core data model is unresolved (§4.1, §13 V4).** The proposed one-bullet-per-item, verbatim carry-forward rule conflicts directly with the observed pointer compression mechanism in §14.8. Since V4 explicitly blocks the first 1B commit, implementation should not begin until the representation is chosen and specified end-to-end. Recommend option **(b)**, but define its canonical resolution algorithm: pointer target, item count, traversal limit/cycle handling, and how an item is explicitly closed without duplicating its full text.

- **Track B is not actually independently releasable as described (§7).** It must branch from `main` after Track A merges, while also claiming its own independent release and revertibility. That makes v0.5.0 structurally dependent on Track A’s merged changes, and a rollback/release boundary cannot be reasoned about as two independent products. Either define Track B as explicitly cumulative on v0.4.0, or branch both from the same baseline and resolve shared-file integration through a planned merge/rebase.

- **The archive-split reorder is proposed before its execution semantics are settled (§6, §13 V1).** The plan moves classification before reflection, then conditionally re-runs it after a split. This introduces a stateful two-pass workflow without defining what happens if the split changes references, Git state, or the eligible file set. Resolve V1 before implementing the swap, and model the split as one explicit pre-write transaction with a defined input snapshot and post-split recomputation contract.

- **The behavioral tests assume deterministic command execution where the implementation is prompt/instruction driven (§8, §9 G1–G3).** Assertions such as “the small one was executed before the handoff” and “Step 3 carries forward correctly” need a harness that controls model, context, permissions, user answers, filesystem state, and expected artifact parsing. Without that contract, these are integration experiments, not reliable merge gates. Specify fixtures, invocation mechanism, deterministic assertions, and acceptable model variability before calling them gates.

## Improvement Suggestions

- Turn “Open work” into a separately defined logical record format, even if rendered as Markdown. That will make future migration from headings and prose rules much less fragile.

- Add an explicit migration policy for chains containing old run-on bullets and pointer-compressed lists (§9 G2). Define whether conversion happens only at the next write, whether ambiguous dot-separated clauses are preserved as one item, and how counts are verified.

- Define a bounded recovery path for a crash between reflection and write (§10). “A few tool calls” is not a recovery mechanism; a draft artifact or resumable reflection record would make the reordered flow safer.

- Replace the implementation-time decision on deployment parity (§12.1) with a chosen approach now. Temporarily deploying suffixed command files changes the supported command surface and should be covered by validation rather than bypassed.

- Add version metadata to generated handoffs. Format detection based only on headings will become increasingly brittle as old chains, alternate headings, and future variants coexist.

## Positives

- The plan correctly separates readability from workflow changes and identifies their different test modes (§7, §12.4).

- The field survey is concrete and materially changes scope: it rejects 1C based on evidence and identifies item disappearance as the meaningful failure (§14.1–§14.2).

- Backward-compatibility is treated as real artifact compatibility rather than merely static-template compatibility (§8, §9 G1–G2).

- The outward-facing safeguard and failure fall-through for pre-flight obligations are sensible boundaries (§5.2–§5.3).

## Open Questions

- For V4 option (b), where is the authoritative open-item list when pointers span multiple handoffs, and how far back may a resume traverse?

- What uniquely identifies an open item if its wording changes, is translated, or is reframed—as happened in the evaporating-item example (§14.2)?

- Is a “small” obligation really safe to execute based on an approximate five-tool-call threshold, or should the classification be capability/risk based instead?

- Which command/runtime version and model constitute the supported environment for behavioral gates and A/B measurements?

## Missing Aspects

- No formal artifact schema or parser ownership is defined. The plan depends on headings, labels, pointers, and legacy structural variance, but does not establish a canonical producer/consumer contract.

- No concurrency model exists for simultaneous or overlapping handoff attempts, despite shared chain sequencing and pre-write mutations such as archive splits.

- No privacy, retention, or cleanup policy covers copied real handoffs, forked session transcripts, generated A/B artifacts, or the recorded session IDs (§9, §12).

- No rollback/migration procedure explains how deployed `-v4` commands, altered generated artifacts, and changelog/decision-log changes are handled if a track is reverted after real use.
