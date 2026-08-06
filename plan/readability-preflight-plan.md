# Plan — handoff readability + pre-flight obligations (v0.4.0)

**Status:** planned, **not implemented**. Decided 2026-08-06 (Marcus), implementation in a
later session. Nothing in this plan has been applied to `commands/` yet.

> **Before implementing anything: review this plan again.** Marcus's instruction (2026-08-06).
> The plan was written and revised across one long session; one of its premises was already
> refuted mid-flight by the field survey in §14, and three decisions are marked unsettled in
> §13. A fresh session must re-read it critically first — check §13 and §14 against the
> current state of `commands/`, confirm the two tracks in §7 are still cut correctly, and only
> then start. Treat this review as the first work item of the implementation session, not as a
> formality.

Two separate pieces of work, deliberately kept independently revertible: **Track A —
readability (v0.4.0)** and **Track B — workflow (v0.5.0)**. Own branch, own release, own test
method each; see §7. Neither depends on the other.

## 1. Trigger

Observations from real use of the commands in the **apex-roadtrip** project:

1. The handoff/resume summary is hard to read — it is unclear what was done and what is
   still to do, and it runs long. The section *structure* is fine (Marcus); the content
   inside it is the problem.
2. Repeatedly, project-defined obligations surfaced only *after* a handoff had been
   written — update a doc, post a task comment, things the project's own rules or memory
   prescribe. They had to be done afterwards, and the handoff then had to be re-run.

## 2. Diagnosis

Both complaints trace to specific instructions, not to model vagueness.

**A — the decision list grows without bound.** `commands/session-handoff.md` Step 3
(carry-forward) makes "Decisions & what shipped" additive across the whole chain, with no
marker of which session a decision came from and no rule for retiring superseded ones. At
`_08` you read eight sessions of decisions in one block.

**B — "what is still to do" has no home.** Step 1 collects open TodoWrite items, but the
document template has no section for them. Today they scatter across "Deferred & open
questions" (which by its name owns deferred items and questions), "→ Pick up here" (exactly
one action), and sometimes nowhere. The information is split across sections that are named
after different things.

**C — the resume side is trimmed for completeness, not readability.** `session-resume.md`
Step 4.3 requires "Carry the full decisions and roadmap … do **not** compress those away."
That instruction came from the 2026-06-30 deep-link fix, which solved the opposite problem
(depth was being lost). The pendulum swung: the cure for "too shallow" produced "too long".
Additionally there is no length calibration anywhere in either command — per Anthropic's
Opus 5 prompting guidance, written deliverables run long by default unless length is
calibrated explicitly.

**D — side finding: the closing reflection runs after the write.** Step 7 is deliberately
placed after Step 6 ("the handoff artifact is secured first"). Consequence: anything 7b/7c/7d
changes (plan file, docs, an archive split) is not reflected in the handoff that was just
written. If the handoff's open work said "README still needs updating" and 7c then updates
it, the file is wrong from the moment it is saved.

## 3. Decisions (locked 2026-08-06)

- **1C** — **DROPPED** (Marcus, 2026-08-06, after the field survey). It was briefly in scope
  and first, on the argument that the decision list drove the file growth. §14.1 refuted that:
  Decisions grows 1.6× while Open work grows 3.3×, and decisions are never carried forward
  verbatim, so sequence tags had nothing to de-duplicate. Record kept in §11.
- **1B** — one "Open work" section with explicit labels, **one item per bullet**, explicit
  closing. Approved and **first**: this is where the measured growth (§14.1) and the measured
  failure mode (§14.2, open items evaporating) both sit.
- **1A** — status head, forward-looking content first. Approved.
- **2C** — pre-flight obligation check with a size threshold: small items are offered for
  immediate execution, larger ones are recorded as open work instead. Approved, including
  the resulting softening of HARD STOP.
- **Reorder** — closing reflection moves *before* the write. Approved; this reverses the
  2026-07-03 "secure the artifact first" ordering, see §6 for the replacement safety net.
- Deferred, explicitly not part of v0.4.0: see §11.

## 4. Change 1 — readability (1B + 1A)

1C is **not** part of this change. It was dropped on 2026-08-06 after the field survey removed
its premise; the record and the reasoning are in §11, the measurement in §14.1. Do not
reintroduce sequence tags without first re-reading §14.1.

### 4.1 Template: forward-looking block first

Reorder `commands/session-handoff.md` "Document template" into two blocks. Everything the
next session needs in order to *act* comes first; everything it needs in order to
*understand* follows.

New head, directly after the `Date/Branch/Previous/Tree` header:

```markdown
## Status
- **Where it stands:** {one sentence — the state of the TOPIC, not a recap of the session}
- **This session:** {one sentence — what changed}

## → Pick up here
{Continue first in: <chain/topic> @ <absolute project path> — ONLY when the next step lives
in another chain or repo; omit entirely otherwise}
{exactly one next action, with the concrete detail needed to start it}

## Open work
- Open: {item} — {context}          ← the open TodoWrite items from Step 1 land here
- Deferred: {item} — {why}
- Question: {open question} — {context}
```

Then the retrospective sections in their current order: "What this is about", "Decisions &
what shipped", "Key files", "Running state", "Verification", "Suggested skills",
"Reference". The closing `Resume:` footer stays at the bottom.

Notes:

- **"→ Pick up here" moves from bottom to top — it is not duplicated.** The status block
  deliberately has no `Next:` line; the single next action exists exactly once, in
  "→ Pick up here". The cross-chain pointer rule (Hard rules) is unaffected, only relocated.
- **"Deferred & open questions" is renamed to "Open work"** and gains the `Open:` label.
  This is the slot that closes finding B — Step 1's TodoWrite items finally have a
  documented home. Update Step 1's wording to say where they go.
- No other section is renamed, removed, or reordered.

**Two rules the field survey (§14) makes non-optional. This section, not 1C, carries Track A's
value — it is the measured growth driver (3.3×) and the site of the measured failure mode.**

- **One item per bullet — per-item identity.** Today long-lived TODOs are compressed into a
  single run-on bullet ("Unverändert aus _125…_129: … · … · …", `_130.md:119-121`; nine items
  in one bullet at `_50.md:55`). An item that cannot be referenced cannot be closed — and
  §14.2 documents exactly that failing: an open item tracked across twenty files that then
  vanishes without ever being marked done. So: one item, one bullet, carried forward with its
  own text, and **closing an item is an explicit act** — it is either marked done or it stays.
  Silently dropping a carried item is the defect this rule exists to prevent.
- **Open work never repeats the next action.** 43 of 130 files open Deferred with a bolded
  "Next…" bullet that duplicates "→ Pick up here" (§14.3). With Pick-up-here moved to the top
  the two now sit a few lines apart, so the duplication stops being harmless. Open work holds
  what comes *after* the next action, never the next action itself.

### 4.2 Resume: same order in the briefing

`commands/session-resume.md` Step 4.3 currently describes *what* to carry, not in which
order. Add an explicit opening shape, phrased positively (describing the wanted output is
more effective than prohibiting verbosity):

> Begin the briefing with exactly three things, in this order: where the topic stands (one
> sentence), what the last session changed (one sentence), and the next action. Then the
> open work. Only after that, the depth: decisions, rejected options, constraints, and what
> you loaded or deliberately did not load.

**Do not weaken the completeness requirement.** The existing "carry the full decisions …
explicitly list rejected options … do not compress those away" stays exactly as it is — this
change is about *order*, not about dropping content. That distinction is the whole point:
reversing the completeness rule would resurrect the depth loss that the 2026-06-30 fix cured.

This touches presentation only. The loading path (byte checks, anchors, safeguards) is **not
modified** — it was validated in real use and stays untouched.

## 5. Change 2 — pre-flight obligations (2C)

New **Step 0**, ahead of the context gather. Numbered 0 deliberately: it runs before the
capture proper and leaves every existing step number untouched.

**Write its body without numeric cross-references.** Refer to neighbouring steps by what they
do ("before the context gather", "the reflection step"), never as "Step 1" or "Step 6". This
is what makes Track B's two commits independently revertible (§7) — a Step 0 that names step
numbers silently depends on the renumbering commit.

### 5.1 Where the obligation list comes from

In this order, first hit wins:

1. **Declared (authoritative).** A `## Session-end checklist` section in the project's
   `CLAUDE.md`. Read literally — each item is an obligation. Costs nothing: CLAUDE.md is
   auto-loaded every session.
2. **Undeclared (fallback, lower confidence).** Obligations already visible in the
   auto-loaded `CLAUDE.md` / `MEMORY.md` index that are conditioned on finishing a piece of
   work — "update the changelog when X changes", "comment on the task when a ticket moves".
   **No sweeping, no extra file loads, no new reads.** If it is not already in context, it
   does not count.

Then filter: keep only items that *this session's work actually triggers* and that are
*still unmet*. If you cannot tell whether an item is already done → ask, never assume.

### 5.2 Classification and what happens per class

- **Small** — finishable in roughly five tool calls or fewer, needs no new decisions, stays
  inside this repo → offer to do it now.
- **Outward-facing** — anything that leaves the machine (task comment, message, MR, publish)
  → **never executed automatically, regardless of size**. Show the exact content and require
  an explicit OK. Declined → record as open work.
- **Large or uncertain** → do **not** execute. Record it in the handoff's "Open work"
  section, and if it is the genuinely next thing, in "→ Pick up here".

Present everything in **one** AskUserQuestion round, one choice per item: *do now* / *skip* /
*record as open work*. Nothing qualifies → skip silently, produce no output.

Execute the confirmed small items, then continue into Step 1 — the context gather then
naturally records them as done, which is the entire point of running this before the write.

### 5.3 Invariants

- Never `git push`. Never commit unless the obligation itself is "commit" and the user
  confirmed it in this round.
- Never edit `CLAUDE.md` from this command — the existing 7a/6a hand-off to
  `/revise-claude-md` stands.
- **A failed or aborted obligation must never block the handoff.** On any failure: stop
  executing, record the remainder as open work, continue to the capture. This invariant
  replaces the "secure the artifact first" safety net that the reorder in §6 removes.
- HARD STOP gets a carve-out naming exactly this: pre-flight obligations confirmed by the
  user are part of closing the session, not a continuation of the work. The stop after the
  write is unchanged.

## 6. Change 3 — reflection before the write

**Confirmed in the field (§14.5):** `apex-roadtrip_97.md:10-13` exists *only* because the `_96`
closing reflection wrote a commit after the `_96` file was saved, making its recorded HEAD
stale. That is this change's failure mode, already paid for once — plus `_114` and `_116`, two
more supplement handoffs written 6–13 minutes after their predecessor, each costing a full
5.6–7.5 KB template to carry about 1 KB of new content.

Swap the two steps:

| now | after |
|---|---|
| Step 6 — Write the handoff | Step 6 — Closing reflection (7a–7d become 6a–6d) |
| Step 7 — Closing reflection | Step 7 — Write the handoff |

Cross-references to update in `commands/session-handoff.md`:

- HARD STOP paragraph — "the closing reflection in Step 7" → Step 6.
- Step 6 intro — replace the "deliberately happen *after* Step 6 … artifact is secured
  first" rationale with the new one: the reflection runs first so the handoff can record its
  results as done, and the §5.3 fall-through invariant covers the failure case.
- Sub-steps 7a–7d → 6a–6d, including the internal reference in 6a.
- Step 8 (`--done`) — "(Steps 1–7)" → "(Steps 0–7)".
- Step 9 (confirm block) — "Show … only when Step 7 actually did something" → Step 6.
- Customizing — store-path references "Steps 2, 5, 6, 8" → "Steps 2, 5, 7, 8"; extension
  point "Step 7e" → "Step 6e".

**Non-obvious consequence — the link ladder must move too.** The Hard-rules ladder is
currently described as running "at write time", and 6d (archive-split) is triggered by "the
link ladder hit case (c)". After the swap, 6d runs *before* the write, so it can no longer
depend on a classification that has not happened yet. Fix: describe the ladder as being
evaluated **when the Reference section is prepared, before the reflection step**, using the
file list from Step 1 plus a byte-size stat. The write in Step 7 then applies the result.

This is also a genuine improvement, not just bookkeeping: today a 6d split happens *after*
the handoff was written, so the saved file describes the pre-split state. With the new order
the split happens first and the handoff links the post-split reality. Re-run the size
classification for any file that 6d actually split.

**This relocation is not settled — see V1 in §13.** Moving the ladder forward and then
re-running it after a split is the more fragile of two options, and the alternative (leave
only 6d after the write) has not been costed out.

## 7. Execution — two independent tracks

These are two different products of work and they must stay separately revertible. They get
their own branch, their own version, and their own release, and neither may depend on the
other.

**Correction to an earlier assumption:** a previous draft of this plan claimed Step 0
(pre-flight) depends on the reflection reorder being in place. **That is wrong.** Step 0 runs
before Step 1 in either ordering, and its whole value — obligations are done before the
context is gathered, so the handoff records them as done — holds regardless of where the
reflection sits. The two were coupled only in the writing, not in the design.

### Track A — readability · branch `feat/v0.4.0-readability` · release v0.4.0

Touches: `commands/session-handoff.md` (Step 3 carry-forward rule, Document template) and
`commands/session-resume.md` (Step 4.3 briefing order). Commits, in order:

0. **Re-review this plan** before the first edit — see the note at the top of the file. Check
   §13 and §14 against the current `commands/`, confirm the track cut still holds.
1. **1B (§4.1)** — the "Open work" section: rename, one item per bullet, explicit closing,
   never repeat the next action. First, because §14.1/§14.2 put both the measured growth and
   the measured failure mode here.
2. **1A (§4.1, §4.2)** — status head, "→ Pick up here" moved to the top, resume briefing order.

### Track B — workflow · branch `feat/v0.5.0-preflight` · release v0.5.0

Branched from `main` **after** Track A merges, to avoid two branches editing
`session-handoff.md` in parallel. Touches: HARD STOP, the step headers and their
cross-references, the reflection intro, and adds Step 0. Commits, in order:

1. **Change 3 (§6)** — the 6/7 swap and the link-ladder relocation.
2. **Change 2 (§5)** — Step 0 pre-flight.

**Requirement for revertibility inside Track B:** Step 0's text must not reference any other
step by number. Written that way, commit 2 survives a revert of commit 1 and vice versa. If
Step 0 ends up needing a numbered cross-reference, say so explicitly instead of quietly
coupling the two.

### Per track, before the release

Deploy, run the full static suite, pass the compatibility gates in §9, update `CHANGELOG.md`
and `docs/decision-log.md`, tag the release.

The split also matches how the two are tested (§12.4): Track A is what Method A measures,
Track B is what Method B measures. A track that fails its method can be reverted without
touching the other.

## 8. Test plan

**Static** — new Section R in `tests/validate-commands.ps1`. Known existing checks that must
be updated (verified 2026-08-06):

- `tests/validate-commands.ps1:131` — template section list contains
  `'Deferred & open questions'` → change to `'Open work'`.
- `tests/behavioral/verify-artifacts.ps1:43` — section list; add `Status` and `Open work`.
- **Do NOT modernize the sub-test fixtures.** `tests/behavioral/depth-recovery/setup.ps1:82`
  and `tests/behavioral/load-discipline/setup.ps1:103` write `## Deferred & open questions`,
  and both write `## -> Pick up here` at the bottom. These are *inputs* to `/session-resume`,
  not outputs, so they are already old-format fixtures — leaving them exactly as they are
  turns both existing sub-tests into free backward-compatibility coverage for G1. Updating
  them to the new format would silently delete that coverage while every test still passes.
- Both files' checks are **presence**-based and order-independent, so moving
  "→ Pick up here" to the top breaks nothing. Confirm this still holds after the edit rather
  than assuming it.

New static checks to add:

- Step 3 (carry-forward) requires **one open item per bullet** and states that closing an item
  is an explicit act — a carried item is marked done or it stays, never silently dropped.
- The Open-work rule states that it must **not** repeat the "→ Pick up here" next action.
- Template has `## Status` with both bullet labels, and it appears before
  `## Decisions & what shipped` (this one *is* an order assertion — write it as an index
  comparison, not a `Contains`).
- Template has `## Open work` with the `Open:` / `Deferred:` / `Question:` labels.
- Step 1 says where the open TodoWrite items go.
- Step 0 exists and names: the declared `## Session-end checklist` source, the
  no-extra-loads rule, the size threshold, the outward-facing never-auto rule, the
  one-AskUserQuestion-round rule, and the never-block-the-handoff invariant.
- Step ordering: the reflection step precedes the write step in the file, and the write step
  is the one that names the Write tool.
- Resume Step 4.3 states the three-part opening order **and** still contains the unchanged
  "do not compress" completeness sentence.

**Behavioral** — one new sub-test `tests/behavioral/preflight/`, following the shape of
`depth-recovery/` and `load-discipline/`. It is justified here (unlike the 8e additions,
which were text-only) because Step 0 *executes* things:

- Sandbox project whose CLAUDE.md declares a `## Session-end checklist` with three items: one
  small and unmet, one outward-facing, one large.
- Assert: the small one was executed before the handoff was written and the handoff records
  it as done; the outward-facing one was **not** executed without an explicit OK; the large
  one appears under "Open work" rather than having been done.

## 9. Compatibility gates — must pass before a track merges

Nothing that exists today may stop working. These are gates, not notes: a track that fails
one does not merge.

**The baseline claims.** Old handoff files have no `## Status` section and use the old
`Deferred & open questions` heading. `/session-resume` reads the whole file rather than
parsing named sections, so both should keep working unchanged — **no migration**, same policy
as the v0.2.0 format change. A project without a `## Session-end checklist` loses nothing:
Step 0 falls back to the undeclared path and, finding nothing, skips silently.

**Partly verified already (2026-08-06):** `commands/session-resume.md` names exactly one
handoff section anywhere in its instructions — `"→ Pick up here"` at line 102. It never
mentions `Deferred & open questions`. So the rename to `Open work` cannot break the resume
side, and moving `→ Pick up here` to the top is safe because resume reads the whole file
rather than seeking a position. The remaining risk is not in the instructions but in the
real files' structural variance — which is what the gates below exist to catch rather than
assume.

**G1 — real old handoffs still resume (Track A).** Copy *real* apex-roadtrip handoffs into the
behavioral sandbox and assert `/session-resume` reads each and produces a briefing naming the
next action and the key files. Real files, not synthetic fixtures. The survey (§14.4) named the
specific files to use, because each carries a deviation worth covering:

- `_70` — bare `## Reference` heading **and** a renamed (German) Decisions heading.
- `_50` — bold-wrapped `**[READ-AT-RESUME]**` tags (51 such tags exist chain-wide).
- `_104` — **no `---` and no `Resume:` footer at all.**
- `_119` — decisions living in an extra section outside the canonical heading.
- one file from `_82, _83, _88, _89, _91, _93, _94, _95, _115, _117, _118, _123, _126` —
  **no `[READ-AT-RESUME]` tag anywhere**, which is a normal state, not a corrupt file.

Derived hard requirements for any instruction text touching these: match `## Reference` on the
**prefix**, detect the tag as a **substring** (bold wrappers exist), and never treat the footer
as an end-of-file or end-of-section delimiter.

**G2 — the mixed chain (Track A).** The case that will actually happen in APEX the moment
this ships: `_NN` is old-format, `_NN+1` is written by the new version. Assert that Step 3
carries forward correctly across the format boundary — the old `Deferred & open questions`
content lands in the new `Open work` section, and the run-on collected bullets that the old
files use ("Unverändert aus _125…_129: … · … · …") are split into one item per bullet without
losing or inventing an item. Count them before and after.

**G3 — the archive-split behaves exactly as before (Track B).** Track B moves **when** the
split runs, not **what** it does. Every invariant in the current Step 7d — nothing deleted,
sections move verbatim, open to-dos never archived, plain (never `[READ-AT-RESUME]`) archive
link, project sync rules respected, own commit — must survive the move **character for
character**. If any of them appears to need adjusting for the new ordering, stop: that is a
separate decision and a signal that V1 (§13) resolved the wrong way, not a detail to fix in
passing.

Note from §14.6: the command's split has **never actually fired** in APEX — the two real splits
there were done by hand before the feature shipped. So there is no field behaviour to regress,
which lowers the risk; but it also means the feature is unvalidated, so a green static suite is
**not** evidence that it works. Do not let the reorder be justified by "protecting" it.

**G4 — green at every commit.** The static suite must pass after each individual commit, not
only at the end of a track. A track whose middle commit is red is not revertible in practice,
which defeats the split in §7.

## 10. Risks

- **Step 0 turns the handoff into a work session.** Mitigated by the size threshold, the
  one-round ask, and the outward-facing rule — but it is a real change to what the command
  *is*, and it should be watched in real use rather than assumed fine.
- **Fuzzy detection in the undeclared path** will both over- and under-fire. Accepted
  deliberately: it always asks, never acts alone, and the declared checklist is the reliable
  path for projects that care.
- **Removing "secure the artifact first"** means a crash between reflection and write loses
  the handoff. Mitigated by §5.3's fall-through; the exposure window is a few tool calls.
- **Renaming a template section** invalidates nothing at runtime but does touch two test
  files — see §8.

## 11. Deferred (decided: not now, keep for later)

- **1C — dropped 2026-08-06, do not reintroduce without re-reading §14.1.** The idea: tag each
  decision with its sequence (`[_NN] …`) and collapse superseded decisions to a one-line
  pointer. It was briefly in scope and first. The field survey killed the premise: Decisions
  grows 1.6× against Open work's 3.3×, decisions are already carried as a delta plus a pointer
  rather than verbatim (`_130.md:15`), and the chain already writes a "CLOSED, nicht wieder
  aufmachen" bullet by hand (`_130.md:122-126`). So the tags had nothing to de-duplicate and
  the collapse rule duplicated an existing habit. One piece of it may be worth reviving later
  in a different form: making the "Alles aus _101…_129 gilt weiter" pointer resolvable.
- **1D — hard length budgets.** One line per decision, roughly seven per session, and "if it
  needs more than one line, the detail belongs in the linked file". Directly implements the
  Opus 5 length-calibration guidance.
- **2A — pre-flight without a size threshold** (execute everything confirmed). Rejected for
  Track B as too large a change to what the command is.
- **2B — obligations as a Step 7e after the write.** Rejected: architecturally cheapest, but
  it reproduces exactly the problem being solved — work done after the write is invisible to
  the next resume.
- **2D-fuzzy-only** — skip the declared checklist and rely on inference alone. Rejected:
  unreliable in the one place where reliability matters.

## 12. A/B comparison against v0.3.0 in a real project

Marcus wants the difference between the two versions visible on a **real** session, ideally
in **apex-roadtrip**, measured as automatically as possible. Implementation happens on a
branch and is only merged after this comparison.

### 12.1 Branch and parallel deployment

- The branch under comparison is the track's own (§7): `feat/v0.4.0-readability` for Method A,
  `feat/v0.5.0-preflight` for Method B. `main` stays on the last released version for the
  whole comparison, so the control side is always a real shipped build.
- **Both versions must be live at the same time.** Claude Code loads commands from
  `~/.claude/commands/`, so a normal deploy would replace v0.3.0 and force the comparison
  across two *different* sessions — which compares sessions, not versions. Deploy the branch
  build under separate names instead: `session-handoff-v4.md` and `session-resume-v4.md`,
  next to the untouched v0.3.0 files.
- Consequence for the test suite: `validate-commands.ps1` checks source==deployed **parity**
  against the canonical filenames. Give it an opt-in parameter (e.g. `-DeployedSuffix '-v4'`)
  or skip parity while the A/B runs — decide at implementation time, do not let the check
  break silently.

### 12.2 What can be measured automatically (verified 2026-08-06)

Session transcripts live at `~/.claude/projects/<project-slug>/<session-uuid>.jsonl`, one JSON
object per line. Fields confirmed present by inspecting apex-roadtrip transcripts:

- `message.usage` with `input_tokens`, `output_tokens`, `cache_read_input_tokens`,
  `cache_creation_input_tokens`
- `timestamp`, `sessionId`, `gitBranch`, `cwd`, `version`
- **`attributionSkill`**, carrying the command name. Both `"session-handoff"` (1538
  occurrences across 123 files) and `"session-resume"` are present — this is what makes a run
  isolatable at all.

Metrics per run: output tokens · cache-read tokens (the resume load cost) · total · wall time
from first to last timestamp · assistant turns · tool calls. And for problem 2 specifically:
**how often `/session-handoff` was invoked in one session** — that count *is* the pain Marcus
described, and it is directly comparable before and after.

Run boundary: the contiguous block of records whose `attributionSkill` equals the command,
anchored on the user message carrying the slash command. **Validate this heuristic against a
known run before trusting any number** — attribution appears to persist until another skill
takes over, so a naive filter may overcount.

Deliverable: `tests/ab/measure-run.ps1` — input a project slug plus a session uuid (or
`latest`), output one CSV row per detected run.

### 12.3 What cannot be measured automatically

Readability is the actual complaint, and no token count measures it. Substitute in two parts:

- **Blind rubric.** Both artifacts with version labels stripped, fixed questions: where does
  it say what to do next · how many lines until the status is clear · which section holds the
  open work · how many decisions are listed and how many still bind. A subagent can answer it,
  or Marcus can; either way it is repeatable and comparable.
- **Marcus reads both.** n=1, and it is the criterion that actually decides.

### 12.4 Two methods, because the two problems are not testable the same way

**Method A — forked replay (for problem 1, readability). Genuinely automatable.**

Verified from `claude --help` on this machine (2026-08-06): `-r, --resume <session-id>`
resumes a conversation by ID; `--fork-session` "create[s] a new session ID instead of reusing
the original (use with --resume or --continue)"; `-p, --print` runs non-interactively;
`--output-format json` returns a machine-readable result.

That means both versions can be run against **the identical real session context**:

```bash
claude --resume <apex-session-id> --fork-session -p "/session-handoff ab-old"
claude --resume <apex-session-id> --fork-session -p "/session-handoff-v4 ab-new"
```

Each fork branches from the same point and neither sees the other, so the order effect that
would otherwise contaminate a live A/B **disappears entirely**. No new work session has to be
produced — apex-roadtrip has 145+ real transcripts to replay against.

Constraints, to settle before building the harness:

- **Validate the combination first.** The flags are verified to exist; that `--resume
  --fork-session -p` behaves as expected together is **not** verified. Run one cheap trial
  before investing in a harness.
- **Distinct slugs remain mandatory.** Both forks write into the same on-disk store, so a
  shared slug still causes carry-forward contamination in whichever runs second.
- **Seed the chain first** — unchanged and still the most important point: diagnosis A only
  shows from roughly `_05` on, so copy the newest file of an existing APEX chain to
  `ab-old_NN` / `ab-new_NN` and let both versions write `NN+1`. The predecessor being
  old-format exercises backward compatibility at the same time.
- **Permissions.** Headless runs hit permission prompts. Scope with `--allowedTools`; do not
  use `--dangerously-skip-permissions` against a real project. The store is gitignored and
  the propose-only steps will not fire (see next point), so the blast radius is small.
- **Cost.** Each fork re-processes the whole session context — pick a mid-size transcript,
  not the 12 MB one.
- ~~Check whether `--output-format json` already reports usage.~~ **Answered — it does;
  see §12.5.** The measure script reads the JSON result instead of parsing transcripts.

**What Method A cannot test:** everything that asks. `-p` has no user to answer
AskUserQuestion, so the topic must be passed as an argument (which the README notes also skips
handoff's confirmation round-trip), and the propose-only reflection steps cannot be exercised.
Method A therefore measures the **capture and write** path — which is exactly where problem 1
lives — and says nothing about the interactive paths.

**Method B — field trial (for problem 2, pre-flight). Not automatable, and that is fine.**

Step 0 is fundamentally a question to the user, so it cannot be replayed headlessly. Test it
the way Marcus proposed: use the branch build under its `-v4` name in normal interactive work
for a few real sessions, and measure it with the one metric from 12.2 that needs no
interpretation — **how many `/session-handoff` invocations a session needed.** Before/after on
the same person doing the same kind of work is a weak comparison statistically and a strong
one practically: the pain was concrete and countable.

**Resume** is compared under Method A as well, as a second forked pair: same source session,
one fork runs `/session-resume ab-old`, the other `/session-resume-v4 ab-new`. Cost from the
logs, readability from the 12.3 rubric.

### 12.5 Validation run — done 2026-08-06, mechanism confirmed

Executed against apex-roadtrip, session `306d96ae-001f-473e-b009-3f24ec9ed2ff`:

```powershell
claude --resume 306d96ae-… --fork-session -p "/session-handoff abtest-validate" `
       --output-format json --allowedTools Read Write Edit Glob Bash PowerShell
```

**Works.** Exit 0, new `session_id` minted (`457f97a9-…`), original untouched, `cwd` correctly
the APEX project, the slash command was recognized and executed. No permission denials.

Four findings that change the harness design:

1. **`--output-format json` already reports cost — transcript parsing is largely unnecessary.**
   The result object carries `usage` (input / output / cache-read / cache-creation),
   `modelUsage` per model, and `total_cost_usd`, plus `duration_ms` and `num_turns`. For
   Method A the measure script only has to read the JSON result. Transcript parsing (12.2)
   stays relevant only for **Method B**, where a run must be isolated inside a longer
   interactive session via `attributionSkill`.
2. **Pin the model explicitly with `--model`.** The forked run came up as
   `claude-sonnet-5`. Unpinned, an A/B pair can silently compare *models* instead of
   *versions* — which would invalidate the entire comparison. Both runs of a pair must pass
   the same `--model`.
3. **Every fork pays the full context cost.** The result showed 80,953 cache-creation tokens
   with `cache_miss_reason: previous_message_not_found` — the replayed context is never a
   cache hit. This 12-second run that wrote nothing cost **$0.50**. Budget roughly twice that
   per A/B pair, more for larger sessions, and watch the five-hour rate-limit window when
   running several pairs.
4. **Transcript size is a bad proxy for "has something to hand off".** The 82 KB session
   picked here turned out to be a single one-off check, so the command correctly applied its
   own error handling (empty session → report, write nothing) and produced no file. Better
   selection criterion: **pick sessions whose transcript already contains a
   `"attributionSkill":"session-handoff"` record** — that is direct evidence the session had
   hand-off-worthy content at the time.

Side effect to be aware of: each fork writes its own transcript into the project's session
directory (here 124 KB). Harmless, but the A/B harness should record which session IDs it
created so they can be told apart from real work later.

### 12.6 Adoption criterion

Merge v0.4.0 to `main` if the readability rubric is clearly better (Method A), resume cost is
not worse than the baseline by more than the threshold set in **V3 (§13)**, and no second
handoff run was needed in a session that had an outstanding obligation (Method B). Otherwise
iterate on the branch.

## 13. Open validation points

Three decisions in this plan were made without enough evidence to be confident. Each must be
settled during implementation — none of them may be left to stand simply because it is
already written down here.

### V1 — is the link-ladder relocation the right fix? (§6)

**The decision:** move the byte-size classification forward so it runs before the reflection
step, and re-run it for any file that 6d split.

**Why it is doubtful:** classify → maybe split → reclassify is a two-pass dependency that
exists nowhere else in the command, and the reclassification is easy to forget or to get
subtly wrong. The plan asserts it works; nothing has been tried.

**Untested alternative:** leave the ladder exactly where it is (at write time) and move only
6d — the archive-split — back to *after* the write, while 6a–6c move forward. The split would
then still be the one step whose result the handoff does not reflect, which is the smaller of
the two inconsistencies, and the ordering stays single-pass.

**How to settle it:** before implementing §6, write out both orderings against one concrete
case — a session with a large plan file that has finished sections — and pick on which one
produces a handoff that describes reality. Record the choice and the reason in the decision
log.

### V2 — is the forked replay worth its cost? (§12.4, Method A)

**The decision:** make the fork-replay A/B the primary method for problem 1.

**Why it is doubtful:** the validation run cost $0.50 for twelve seconds that produced
nothing, and a real pair re-processes the full context twice. Add seeding the chain, pinning
the model, keeping slugs apart, and building the measure script, and it is a meaningful chunk
of work — to answer a question ("is this more readable") whose final arbiter is Marcus reading
two files anyway.

**Untested alternative:** skip Method A entirely. Run only the field trial (Method B) with the
invocation counter, and judge readability by reading the handoffs that normal work produces.
Far cheaper, less clean, possibly sufficient.

**How to settle it:** run exactly **one** real pair first, on a properly selected session
(§12.5, finding 4). Then decide whether the numbers told you anything you did not already see
by reading the two files. If they did not, drop Method A and say so here — do not build the
harness first and evaluate afterwards.

### V3 — the 10% cost threshold is invented (§12.6)

**The decision:** "resume cost not worse by more than roughly 10%" as a merge gate.

**Why it is doubtful:** the number has no basis. Nothing was measured to produce it, and 5%
or 25% would have read equally plausible.

**How to settle it:** measure a baseline before using it as a gate — run `/session-resume`
(v0.3.0) three times against the same handoff and record the spread. If the natural run-to-run
variance is already, say, 15%, then a 10% threshold is noise and the gate is meaningless.
Set the threshold above the measured variance, or replace it with an absolute token budget.
Until that measurement exists, treat this criterion as **not yet defined** rather than as 10%.

## 14. Field evidence from the APEX chain (surveyed 2026-08-06)

A read-only survey of all 130 files in
`C:\Users\marcu\claude-projects\privat\projects\apex-roadtrip\.claude\session-handoffs\`
(10 read in full, 15 machine-measured per section, headings/headers/footers/tag forms scanned
across all 130). It **refutes one premise of this plan** and hardens several others.

### 14.1 The growth driver is Open work, not Decisions — 1C's premise was wrong

Measured section bytes, `_01` → `_130`:

| section | _01 | _130 | growth |
|---|---|---|---|
| whole file | 5,308 | 10,625 | 2.0× |
| Decisions & what shipped | 2,054 | 3,351 | **1.6×** |
| Deferred & open questions | 500 | 1,625 | **3.3×**, peaking at 3,441 in `_120` |

Decisions is the *largest* section everywhere (24–40%) but the *slowest-growing* one. The file
grew because everything grew, led by Deferred.

Worse for 1C: **decisions are not carried forward verbatim at all.** Each file's Decisions
section is a pure delta plus a one-line pointer — `apex-roadtrip_130.md:15`
"Alles aus _101…_129 gilt weiter. Diese Session:", same shape at `_129:15`, `_128:16`,
`_127:15`, English variant at `_114:17`. So a `[_NN]` sequence tag has nothing to
de-duplicate: every bullet in a file already comes from that file's own session.

Supersede-collapse is likewise already happening organically: `_130.md:122-126` carries a
"**CLOSED, nicht wieder aufmachen:**" bullet listing reversed options.

**Consequence: 1C as specified solves a problem this chain does not have.** Marcus dropped it
on this evidence (2026-08-06) and moved 1B to the front; record in §11.

### 14.2 The real failure mode: open items evaporate

An open item was tracked across twenty files — `_100.md:64-67` (prod Richtwert still at 5),
still open at `_104.md:119`, `_110.md:151-153`, `_119.md:165`, `_120.md:178` — and then
**silently disappears from `_122` on**, never marked done, re-framed at `_122.md:100` as a
differently-named item.

Long-lived TODOs are compressed into single run-on bullets that cannot be referenced
individually: `_130.md:119-121` "Unverändert aus _125…_129: … · … · …";
`_50.md:55` packs nine items into one bullet. "Vercel-Projekt löschen" rides along in 54 files
(`_24`–`_79`) and then vanishes.

**Consequence for 1B:** the Open work section needs **per-item identity** — one item per
bullet, so an item can be explicitly closed rather than dropped. This is the highest-value
finding in the survey and it lands squarely in Track A.

### 14.3 The next action is written twice, by habit

43 of 130 files open Deferred with a bolded "Next…"/"Nächst…" bullet that repeats the
"→ Pick up here" content: `_130.md:107` vs `_130.md:141-145`; `_100.md:124` vs `_100.md:157-159`;
`_50.md:52` vs `_50.md:68` (the same three options listed twice).

**Consequence for 1A/1B:** moving "→ Pick up here" to the top puts the two within a few lines
of each other, so the duplication becomes obvious instead of harmless. Add an explicit rule:
Open work holds only items that are **not** the next action.

### 14.4 Structural variance — low, but the specifics matter for G1

All 130 files carry the full nine-section template in order and the identical header field set
(`Date / Branch / Previous / Tree`). Only seven heading signatures exist. The deviations that a
reading instruction could trip over:

- **`## Reference` has three heading texts** (`_01`–`_78`, `_79`–`_130`, and a bare
  `## Reference` in `_70`). Match on the **prefix**, never the full string.
- **`[READ-AT-RESUME]` appears in three lexical forms** — plain (258×), **bold-wrapped**
  `**[READ-AT-RESUME]**` (51×, e.g. `_50.md:25`, `_54.md:24`, `_71.md:20`), and the section
  anchor (31×). Detection must be substring-based. **14 files carry no tag at all** — a normal
  state, not a defect.
- **`apex-roadtrip_104.md` has no `---` and no `Resume:` footer.** Never use the footer as an
  end-of-file or end-of-section delimiter.
- **`_70` renames the Decisions heading itself** (German), and `_69`, `_70`, `_109`, `_118`,
  `_119` add extra `##` sections — `_119.md` keeps its riskiest decisions in a separate
  "Low-confidence decisions … CHECK THESE" section. Any rule that touches "each decision
  bullet" must tolerate decision-like content outside the canonical heading.

### 14.5 Track B is validated by three files that exist only because of the problem

- `_97.md:10-13` — "this seq exists only because the _96 closing reflection wrote a doc-sync
  commit AFTER the _96 file, so _96's stated HEAD went stale." Written 6 minutes after `_96`.
  **This is precisely what the §6 reorder fixes.**
- `_114.md:11-14` — "Short supplement to _113, written after it." 13 minutes later.
- `_116.md:11` — same pattern, 6 minutes later.
- Admissions without a new file: `_47.md:4` ("nach dem Handoff geloggt"), `_54.md:24`
  ("Nachtrag (gleiche Session, nach dem Handoff)").

Each supplement costs a full template (5.6–7.5 KB) to carry roughly 1 KB of new content.

### 14.6 The archive-split has never fired from the command

Two real splits exist and both were done **by hand before the feature shipped**:
`docs\superpowers\plans\2026-07-10-…-DONE.md` (recorded in `_30.md:11`: active plan 1,502 →
536 lines, "~15k statt ~40k Tokens") and `docs\superpowers\plans\2026-07-29-trip-edit-DONE.md`,
plus a third non-`-DONE` split (`docs\design-ux-backlog-erledigt.md`, per `_54.md:24`).

There is **no evidence of Step 7d itself ever offering a split** in this corpus (not verified
whether it offered and was declined). Likewise `--done` has never archived an apex chain: the
`done/` folder holds exactly one file, from a different topic.

**Consequence for G3:** nothing in the field depends on the split's current behaviour, so the
regression risk from the §6 reorder is lower than assumed. The flip side is that the feature is
**entirely unvalidated** — do not treat "it still passes the static checks" as evidence it works.

### 14.7 Cheap waste, not yet in scope

Evidence-backed, each small on its own:

- `Running state` is boilerplate: "Background processes: none" in 93/130 files, "Dev servers:
  none" in 90/130. Candidate: omit-when-empty.
- The `Tree:` header restates the same four untracked off-topic files verbatim in every file
  from `_98` to `_116` (`_100.md:4-7`, `_114.md:4-7`, `_116.md:4-7` are byte-identical).
  Candidate: carry the delta since the previous handoff.
- `Suggested skills` has drifted into free-form advice — `_50.md:47` "kein Skill nötig",
  `_104.md:108` names a repo script, `_116.md:73` a non-skill note. Candidate: rename or drop.
- The Reference block repeats project constants (repo URL, live URL, "Previous handoff", which
  is already a header field) in nearly every file — `_100.md:153-154`, `_110.md:182-184`,
  `_130.md:137-138`.

Not added to either track. Recorded here so the next scoping decision has them.
