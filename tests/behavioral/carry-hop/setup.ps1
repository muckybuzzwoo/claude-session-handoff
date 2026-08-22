#requires -Version 7
<#
  Builds the sandbox for the carry-hop sub-test: the READ half of v0.4.0's headline feature.

  format-boundary proves the carry line is WRITTEN. Nothing proved it is RESOLVED, which is
  the half v0.4.2 rewrote. This sandbox is shaped to make a wrong resolution visible:

    mig_01.md   old format on purpose — no `Format:` field, and the OLD Open-work heading
                `## Deferred & open questions`. Holds four items. Three of them (ALPHA,
                BETA, GAMMA) appear NOWHERE ELSE, so a response containing them proves the
                hop file was actually read.
    mig_02.md   `Format: 2`. Closes DELTA with a `- Done:` bullet, opens EPSILON, and points
                back with `Carried unchanged: 3 items — see mig_01.md`.

  The traps, in order of how often they were got wrong:
    - the hop target has the OLD heading (the only case that exists in the field)
    - DELTA is closed in _02 and must not come back as open work
    - _02's own carry line is not an item
    - one hop, and _01 has no carry line of its own, so there is nowhere further to walk

  Re-runnable: wipes and rebuilds .sandbox/.
#>
$ErrorActionPreference = 'Stop'

$Root  = Join-Path $PSScriptRoot '.sandbox'
$Proj  = Join-Path $Root 'proj'
$Out   = Join-Path $Root 'out'
$Store = Join-Path $Proj '.claude/session-handoffs'

if (Test-Path $Root) { Remove-Item $Root -Recurse -Force }
$null = New-Item -ItemType Directory -Force -Path $Store
$null = New-Item -ItemType Directory -Force -Path $Out
$null = New-Item -ItemType Directory -Force -Path (Join-Path $Proj 'docs')

Push-Location $Proj
try {
    git init --quiet 2>$null
    git config user.email 'sandbox@example.invalid' 2>$null
    git config user.name  'Sandbox' 2>$null
    Set-Content -LiteralPath (Join-Path $Proj '.gitignore') -Value '.claude/session-handoffs/' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $Proj 'docs/notes.md') -Value "# Notes`n`nPlaceholder so the repo is not empty.`n" -Encoding UTF8
    git add -A 2>$null
    git commit --quiet -m 'sandbox baseline' 2>$null
} finally { Pop-Location }

# --- mig_01.md — OLD format on purpose -------------------------------------------------
$h01 = @'
# Session Handoff: mig (seq 01)

**Date:** 2026-08-18  **Branch:** main
**Tree:** clean

## Status
- **Where it stands:** the schema migration runs end to end on a copy of production.
- **This session:** wired the migration into the deploy step and left four things open.

## → Pick up here
Raise the connection-pool ceiling before the next dry-run. See the first item below.

## Deferred & open questions
- **SENTINEL_CARRY_ALPHA** — the connection-pool ceiling is still 20, and the migration
  saturates it at roughly 14 parallel workers. Raise it or cap the workers, not both.
- **SENTINEL_CARRY_BETA** — the dry-run has never been executed against a full-size dataset,
  only against the 2 percent sample. The timing numbers are therefore not load-bearing.
- **SENTINEL_CARRY_GAMMA** — the rollback script exists but has never been run. It is written
  against the pre-migration column names, which is exactly what a rollback would face.
- **SENTINEL_CLOSED_DELTA** — the retry cap is unset, so a transient failure retries forever.

## What this is about / where it started
The orders table outgrew its primary key type. This chain tracks the migration to a 64-bit
key and everything that had to move with it.

## Key files (absolute paths) — read these first
- `docs/notes.md` — scratch notes for the migration.

## Running state
- Background processes: none.
- Dev servers / ports: none.

---
Resume: `/session-resume mig`
'@

# --- mig_02.md — format 2, carries three of the four ----------------------------------
$h02 = @'
# Session Handoff: mig (seq 02)

**Date:** 2026-08-21  **Branch:** main  **Previous:** mig_01.md
**Tree:** clean
**Format:** 2

## Status
- **Where it stands:** unchanged from `_01` except that the retry cap is now in place.
- **This session:** set the retry cap and found one new problem in the deploy ordering.

## → Pick up here
Raise the connection-pool ceiling before the next dry-run. It is the oldest open item in the
chain and everything else waits on a dry-run that does not saturate the pool.

## Open work
- Done: **SENTINEL_CLOSED_DELTA** — the retry cap is set to 5 with exponential backoff, so a
  transient failure no longer retries forever. Closed this session.
- Open: **SENTINEL_NEW_EPSILON** — the deploy step runs the migration before the feature flag
  is flipped, so there is a window where the new code path is live against the old schema.
  New this session.
- Carried unchanged: 3 items — see mig_01.md

Count for that line: `_01` holds 4 written-out items and no carry line of its own, so
`prev_total = 4`. This session closed 1 and wrote 1 new one out. Conservation law:
3 + 1 + 1 - 4 = 1 new, which is EPSILON.

## What this is about / where it started
The orders table outgrew its primary key type. This chain tracks the migration to a 64-bit
key and everything that had to move with it.

## Key files (absolute paths) — read these first
- `docs/notes.md` — scratch notes for the migration.

## Running state
- Background processes: none.
- Dev servers / ports: none.

---
Resume: `/session-resume mig`
'@

$p01 = Join-Path $Store 'mig_01.md'
$p02 = Join-Path $Store 'mig_02.md'
Set-Content -LiteralPath $p01 -Value $h01 -Encoding UTF8
Set-Content -LiteralPath $p02 -Value $h02 -Encoding UTF8

# Read-only baseline: resume must not touch either file.
$manifest = @(
    @{ Path = $p01; Hash = (Get-FileHash -LiteralPath $p01 -Algorithm SHA256).Hash },
    @{ Path = $p02; Hash = (Get-FileHash -LiteralPath $p02 -Algorithm SHA256).Hash }
)
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Out 'pre-hashes.json') -Encoding UTF8

Write-Host "Sandbox built: $Proj"
Write-Host ''
Write-Host "Expected, if the carry hop is resolved correctly:"
Write-Host "  ALPHA / BETA / GAMMA appear in the briefing  (they exist only in mig_01.md)"
Write-Host "  DELTA appears as CLOSED, never as open work"
Write-Host "  the briefing says three items were resolved from the hop"
Write-Host ''
Write-Host "Now run the scenario agent, capture its final response to:"
Write-Host "  $(Join-Path $Out 'S6.txt')"
Write-Host "then: pwsh -File $(Join-Path $PSScriptRoot 'verify.ps1')"
