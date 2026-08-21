# Tests

Automated **static validation** for the two command files. Run:

```powershell
pwsh -File .\tests\validate-commands.ps1
```

Exit code `0` = all checks passed, `1` = at least one failed (prints which). No external
dependencies — pure PowerShell, no Pester required.

> Two layers: this script is the **static** layer (structure only). The **behavioral**
> layer in [`behavioral/`](behavioral/README.md) actually runs the commands via subagents
> against a throwaway project and asserts on the artifacts — that's where the runtime
> behaviour below ("NOT COVERED here") is exercised.

## What it proves (deterministic)

The slash-commands are **prompt files (Markdown), not executable code**, so the harness
verifies the *structural invariants* that keep them correct — the things most likely to
break on an edit:

- **Files exist** — source + deployed copies of both commands.
- **Deploy parity** — `commands/*.md` (source) byte-identical to `~/.claude/commands/*.md`
  (live). This is the project's #1 risk ("edit here, then deploy"); the test fails the
  moment the live copy drifts.
- **Frontmatter** — `description`, `argument-hint`, and the exact `allowed-tools` set per
  command (and that resume does **not** grant `Write`/`Edit` — read-only posture).
- **Step structure** — handoff steps `1..9` present, unique, contiguous (catches gaps and
  duplicates from renumbering); resume steps `1..5`.
- **Renumbering cross-references** — the brittle parts: HARD-STOP carve-out names Step 7,
  `--done` final-handoff cites "Steps 1–7", Customizing cites "Steps 2, 5, 6, 8", confirm
  block has `Memory:` / `Plan updated:` / `Docs updated:` lines.
- **Step 7 closing reflection** — sub-sections 7a (memory), 7b (plan), and 7c (docs) present.
- **superpowers awareness** — `docs/superpowers/{specs,plans}/` referenced in Step 1 and in
  the template Reference line.
- **Template completeness** — every required handoff section is present.
- **Safety invariants** — gitignore scoping (`.claude/session-handoffs/` only, never all of
  `.claude/`), Windows "never chain shell commands" rule, resume "never modify or delete".

The assertions are mutation-checked: corrupting a cross-reference, removing a step header,
or changing one byte flips the relevant check to FAIL — the harness is not a rubber stamp.

## What it does NOT prove (behavioural — verify manually)

A static test cannot run an LLM, so it cannot confirm *runtime behaviour*. The script
prints these as **NOT COVERED** reminders; verify them by hand per `README.md → Testing`:

- Step 7a actually **shows** a memory candidate and waits for approval before writing.
- Step 7b proposes a concrete plan diff and writes only on confirm.
- Step 7c proposes a concrete doc-drift edit and writes only on confirm.
- Carry-forward `_01 → _02` with correct `Previous:` link.
- Staleness note fires correctly (>7 days / branch change).
- `--done` archives to `done/` and resume hides it without `--all`.
- Secret-pattern warning triggers before writing.

## Compatibility scanner (standalone, no LLM)

`compat-old-chain.ps1 -Path <handoff-dir>` scans any existing chain and answers one question
deterministically: does it still add up? Run it **before** a format change to record a
baseline and **after** to compare, so "nothing was lost" is a measurement rather than a hope.

```powershell
pwsh -File .\tests\compat-old-chain.ps1 -Path 'C:\path\to\project\.claude\session-handoffs'
pwsh -File .\tests\compat-old-chain.ps1 -Path .\.claude\session-handoffs -Detail
```

It reports the format census (old heading / new heading / none), the open-item count under the
v0.4.0 grammar, how many items hide inside collapsed or wrapped bullets, and which files carry
a pointer with no number. Where new-format files exist it also **checks** the carry invariant
and exits 1 when items left without a `Done:` line. Its own correctness is covered by the
fixture chains in `fixtures/carry-ok` and `fixtures/carry-bad`, which the static suite runs.

## Focused sub-test: format boundary (`behavioral/format-boundary/`)

The first new-format handoff written on top of an old-format predecessor — the case that
decides whether existing chains survive v0.4.0. The fixture is shaped like the hardest real
file (old heading, nothing to inherit, a bullet wrapping over four lines with middot
separators on the continuation lines, a group header with numbered children, a prose pointer
with no number, `→ Pick up here` still at the bottom). `setup.ps1` prints the expected item
count, `verify.ps1` asserts 26 properties, scoped to the Open-work block where the rule under
test lives. It checks that the predecessor keeps its old heading and gains no `Format:` field,
but it does not hash it — byte-identity is asserted in `old-format-resume/` and
`depth-recovery/`.

## Compatibility gate G1 (`behavioral/old-format-resume/`)

Five **real** pre-v0.4.0 handoffs, one per structural deviation, resumed for real. Copies the
files from the local source chain at run time into a gitignored sandbox and **skips loudly**
when that chain is absent — real private handoffs are never committed here. `verify.ps1`
asserts 43 properties, including a SHA256 of every file before and after, because the
read-only promise is the one that must never break.

Coverage limit worth knowing: the linked targets in those real files lie outside the sandbox,
so G1 proves the *reading* of awkward files, not tagged-link loading. That is `depth-recovery/`.
