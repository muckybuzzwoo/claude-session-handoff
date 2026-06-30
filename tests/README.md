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
