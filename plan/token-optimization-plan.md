# Plan (IMPLEMENTED 2026-07-29): token-optimize `/session-handoff` + `/session-resume`

**Status:** **Implemented 2026-07-29** in `commands/session-handoff.md` +
`commands/session-resume.md` (deployed; static suite 99/99). The design below is kept as
the decision record. What shipped vs. what this plan described (the plan predates addenda
8c/8d in the briefing, which resolved the open branches empirically):

- **Lever A — shipped in full.** Byte-size trigger (`bytes/4` ~ tokens, replaces the old
  line-count thinking), per-link classification ladder in handoff Hard-rules ((a) redundancy
  → no tag · (b) section-anchor `[READ-AT-RESUME: <heading>]` · (c) big whole-file → inline
  essence + offer split · (d) plain tag), essence must-contain checklist, "keep the full tag
  when unsure". Resume Step 4: only tags auto-load; anchors → targeted read; bare tags load
  with a big-file safeguard; untagged plan-like links are peeked + offered, never blind-loaded.
- **Lever B — shipped as suggestion-only** (Marcus decision 2026-07-29): handoff Step 7d,
  propose-only, fires only when confident finished sections exist; invariants — nothing
  deleted / sections move verbatim / open items never archived / plain link to archive / own
  commit / respect sync rules. **No per-project persist mechanic** (§7.3) — the check is
  cheap at write-time, so it just asks when relevant.
- **Backward compatibility (Marcus requirement 2026-07-29):** resume reads old-format
  handoffs (bare `[READ-AT-RESUME]`, no anchor) unchanged, with the big-file safeguard; no
  migration — old chains of any length keep working, the new format appears from the next
  handoff on.

Companion to `plan/session-handoff-plan.md` (the original grilled design) — this plan must
not silently contradict it; where it revises it, that is called out (§4).

**Origin:** work-order briefing `docs/ideas/skill-optimierung-session-handoff-resume.md`
(local, gitignored) — token cost measured in project apex-roadtrip on 2026-07-10. Grilled
with Marcus on 2026-07-13 (this session). Approach was Marcus-set: understand + grill the
idea first, capture as a plan, implement later.

---

## 1. Problem (plain)

Resuming a session can be expensive. Measured: one `/session-resume` cost **~40k tokens**,
of which **~33k was a single 1,502-line plan** that had been tagged `[READ-AT-RESUME]` and
was therefore fully re-read on every resume — about two thirds of it already-finished work.
`/session-handoff` itself costs only ~7k. So the mechanism is fine; the cost driver is
**large, ever-growing documents sitting behind auto-load links.**

## 2. Guiding principle for the whole design

A false negative (command stays silent / loads too much) costs only tokens. A false
positive (command drops or breaks something the next session needs) costs trust. →
**When unsure, always take the harmless step.** Every decision below is biased this way.

## 3. Two levers (Decision 1 — LOCKED)

- **Lever A — handoff-internal (safe, universal, PRIMARY).** At handoff-*write* time,
  don't auto-tag a large file for full load. Instead write its short **essence** into the
  handoff itself and link the file *lazily* (a normal link, not `[READ-AT-RESUME]`).
  Touches no project file; format-independent (it is just summarizing). In the measured
  case this lever alone recovers ~33k of the ~40k.
- **Lever B — project-file restructuring (powerful, RISKY, OPT-IN ONLY).** The apex
  "archive-split": move finished sections into a sibling `<plan>-DONE.md`, keep the active
  file lean, own commit. Highest saving, **but** the command then edits a real project file
  of the user's, must judge what counts as "done" (format-dependent), and must not break
  sync rules (e.g. MD+HTML twins). Only ever a suggestion the model makes *when confident*;
  never automatic.

Locked: spec/build **A first**; **B is optional** and (per §7) may be deferred to a later
phase.

## 4. Resume's auto-load heuristic (Decision 2 — LOCKED; REVISES original addition #16 / resume Step 4)

Today `/session-resume` Step 4 full-loads not only `[READ-AT-RESUME]` files but also
*untagged* links it judges "clearly a plan / spec / roadmap." That silently re-inflates the
cost and **would defeat Lever A** — a lazily-linked big plan would get loaded anyway
because it *looks like* a plan.

New behaviour:

- **Only an explicit `[READ-AT-RESUME]` tag triggers an automatic full load.**
- For any other substantial linked file (plan/spec/roadmap-like), resume does **not**
  full-load. It **peeks** (reads the headings / first ~40 lines) and **offers**:
  "linked plan X is untagged, ~Yk — load it fully?"
- This is a **deliberate change** to addition #16's "dereference untagged obvious
  plan/spec/roadmap" rule. Rationale: the depth that #16 was protecting is now carried by
  Lever A's inlined essence, so the blind full-load is no longer needed — and it is exactly
  where the cost leaks back in. **Must be confirmed at implementation time**, since it
  edits a previously grilled decision.

## 5. Completeness guarantee for Lever A (Decision 3 — LOCKED)

The core worry Marcus raised: *what if the essence forgets something important?* Resolved by
separating **stored** from **loaded**, plus three nets:

- **Nothing is ever lost.** Lever A deletes and moves nothing (that would be B). The full
  file stays untouched and fully linked. Worst case is "load it once more," never "gone."
  So "is everything important *stored*?" → **yes, always, by construction.** The only real
  question is what gets *auto-loaded*.
- **Net 1 — the essence is written by the best-informed session** (the one that just did
  the work and has the file in context), against a fixed **must-contain checklist**:
  goal · open work packages · still-binding decisions + constraints · rejected options /
  no-gos. These are the sections the handoff already carries — the essence is that existing
  structure filled well, not free-form prose.
- **Net 2 — resume always prints the skeleton.** For every lazily-linked substantial file,
  resume prints its **heading structure** (its table of contents), not the body (~30 lines
  vs ~1,500). The user sees the full map and can pull any section fully. Nothing important
  can stay *invisible* — you see the map, you fetch the terrain only where needed. This is
  the actual answer to the worry: a forgotten essence line is still *visible* in the
  skeleton.
- **Net 3 — when unsure, don't shrink.** If the writing session is not confident the
  essence suffices, it keeps the full `[READ-AT-RESUME]` tag.

Explicitly **rejected**: adding a one-sentence-per-section excerpt on top of the skeleton —
the heading skeleton already removes the blind spot, and per-section sentences re-inflate
the resume toward full text (against the whole point).

## 6. Cross-project safety — the "works with different MD/HTML files" question (framing LOCKED, from briefing §6)

The command must **not** try to recognize plan formats by rule — every format heuristic
breaks in the next project. Split of responsibility:

- **Format-independent (the command may hard-rule):** measure the *size* of load targets
  (lines / bytes) — works anywhere; and the archive convention itself (move whole sections,
  DONE file, mandatory header, back-reference, own commit) — format-neutral and lossless.
- **Format-dependent (the MODEL decides in session context, never the command):** whether a
  file actually contains substantial *finished* sections. The session writing the handoff
  worked in that project and knows its conventions (including Marcus's MD+HTML sync rule — a
  dumb skill rule would not). Instruction shape: "target is large → judge from your own
  knowledge whether an essence/split is sensible; if unsure, don't."
- **Lever A is format-neutral by construction** (summarizing + heading skeleton work on any
  text). **Lever B is the format-sensitive part** → which is exactly why it stays opt-in and
  model-judged, never a blind rule.

## 7. Open branches — RESOLVED 2026-07-29 (see status header for how each shipped)

All five are now decided: (1) size trigger → bytes (`bytes/4`), addendum 8d.1; (2) B ships
alongside A as suggestion-only; (3) no persist mechanic; (4) `/compact` is complementary,
not a substitute (it compresses live in-session context; the handoff persists curated
continuity across sessions — inlining essence at write-time is the compression step),
no blocker; (5) B's worth-it: 3 of 3 major apex phases hit the same pattern, and
suggestion-only keeps its risk bounded. Original parked text kept below for the record.

1. **A's size trigger.** At what size does essence-inlining kick in — a rough line/byte
   threshold, pure model judgment, or threshold-as-hint-then-judge? (Lean: size as the
   trigger, model decides the action.)
2. **How far does B go.** Ship B in the same phase as A, or A first and B as a later phase?
   (Lean: A first, B later.)
3. **Persist the user's decision per-project or globally?** (apex recommendation:
   per-project — plan cultures differ.) Only relevant once anything is persisted; open
   sub-question is *where* it lives (a memory file, handoff-store config, or the handoff
   itself).
4. **`/compact` comparison (briefing §8b.2).** Honest pro/con of Claude Code's own context
   compaction (`/compact` / auto-compact) vs. the handoff approach, and whether inlining
   essence at handoff time partly replaces it. Not yet assessed. Prior art in this repo is
   thin (plan §Scope "no precompact hook (later, optional)"; handoff Step 1 compaction
   cross-check) — a real compact-vs-handoff discussion does not exist yet.
5. **Worth-it, revisited for B.** The ~40k case is measured in exactly **one** project so
   far. Lever A is cheap enough to be clearly worth it; **B's** cost/benefit (skill
   complexity + test effort vs. the manual split that already worked in apex) is the real
   "is it worth it" and stays open. A valid outcome for B: **document the convention, build
   nothing.**

## 8. Where the changes would land (implementation map — for later)

- `commands/session-handoff.md` — the tag-assignment step: for large targets, prefer
  inline-essence + lazy link over `[READ-AT-RESUME]`; add the must-contain essence
  checklist; add the "when unsure, keep the full tag" rule. (Lever B, if built: an opt-in
  split suggestion carrying the archive convention.)
- `commands/session-resume.md` — Step 4: only `[READ-AT-RESUME]` auto-loads; untagged
  substantial files get peek-headings + an offer to load; always print the heading skeleton
  of lazily-linked substantial files.
- Must not contradict the grilled decisions in `plan/session-handoff-plan.md`; the one
  deliberate revision (addition #16 / resume Step 4) is recorded in §4 and needs explicit
  sign-off.
- After any change: **edit here, then deploy** to `~/.claude/commands/`, then run
  `pwsh -File tests/validate-commands.ps1` (now **99/99** green — static Section P added for
  this rebuild). Behavioral-test coverage for the new load paths (anchor read, big-file
  safeguard, untagged-not-loaded, 7d split proposal) is **still outstanding**.

## 9. Test plan (carried from briefing §8 — to flesh out at build time)

1. **Dry test in this repo:** handoff against a fictitious large plan with finished sections
   → essence + lazy link (and, if B is built, a split suggestion) must appear; against a
   small/unclear doc → must **not** appear.
2. **Real test in apex-roadtrip:** after a work package completes, the active plan again
   holds finished sections → the new handoff should propose the safe lever by itself; then
   compare `/session-resume` cost against the ~40k / ~15k baseline.
3. **Contrast project:** run once in a project with different conventions (HTML specs /
   checklists) — the suggestion must either fit or cleanly not fire.

## 10. References

- Work-order briefing (local, gitignored):
  `C:\Users\marcu\claude-projects\privat\tools\claude-session-handoff\docs\ideas\skill-optimierung-session-handoff-resume.md`
- Original grilled design (this repo): `plan/session-handoff-plan.md`
- apex evidence (other project, read only if needed): handoff
  `C:\Users\marcu\claude-projects\privat\projects\apex-roadtrip\.claude\session-handoffs\apex-roadtrip_29.md`;
  split example (header pattern)
  `C:\Users\marcu\claude-projects\privat\projects\apex-roadtrip\docs\superpowers\plans\2026-07-10-design-pass-rollout-pakete-2-4-DONE.md`;
  split commit `33054df` on branch `design/ux-pass`.
