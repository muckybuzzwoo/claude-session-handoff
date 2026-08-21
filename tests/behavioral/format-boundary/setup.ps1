#requires -Version 5
<#
  Focused behavioral sub-test for the v0.4.0 FORMAT BOUNDARY: the first new-format handoff
  written on top of an old-format chain. Self-contained — builds its own sandbox under
  format-boundary/.sandbox/ (gitignored). Does not touch the main S1/S2/S3 sandbox, the
  maintenance repo, or the user's real Claude memory.

  This is the case that decides whether existing chains survive v0.4.0. The previous file
  is deliberately shaped like the hardest real file in the apex-roadtrip chain:

    * heading is the OLD '## Deferred & open questions'
    * no '**Format:**' field, no 'Carried unchanged:' line — nothing to inherit
    * one carry bullet that WRAPS over four lines with middot separators on the
      continuation lines (the pattern that hid ~900 items chain-wide until 2026-08-21)
    * one group header ending in ':' whose items are a NUMBERED child list
    * one prose pointer with NO number ("die komplette Liste aus _00")
    * '→ Pick up here' at the BOTTOM, pre-1A position

  Expected item count under the v0.4.0 grammar: 16. Verified with
  `tests/compat-old-chain.ps1` against this fixture, not derived by hand — the first
  hand-derived number was 17, off by one because the wrapped bullet holds 8 items behind
  7 separators, not 8.
    2 plain bullets           -> 2
    + 1 wrapped carry bullet  -> 1 + 7 separators = 8
    + 1 group header          -> 0 (label) + 4 numbered children = 4
    + 1 unresolvable pointer  -> 1
    + 1 question bullet       -> 1
    = 16

  OPTIONAL: pass -Chain (or set SESSION_HANDOFF_TEST_CHAIN) to a real handoff chain and its
  newest file is copied in as well, under a second topic slug, so the agent also faces
  genuine field data. That copy lives only in the gitignored sandbox and is never committed —
  see the test-data rule in plan/readability-preflight-plan.md section 9. Without it the
  synthetic fixture above is enough to run the test.

  Prints SANDBOX_PROJ / SANDBOX_OUT / EXPECTED_ITEMS for the orchestrator.
#>
param(
    # Optional real chain to borrow one field-data file from. Falls back to the
    # SESSION_HANDOFF_TEST_CHAIN environment variable. Omit it and the test still runs on
    # the synthetic fixture alone.
    [string]$Chain = $env:SESSION_HANDOFF_TEST_CHAIN
)

$ErrorActionPreference = 'Stop'

$Sandbox = Join-Path $PSScriptRoot '.sandbox'
$Proj    = Join-Path $Sandbox 'proj'
$Out     = Join-Path $Sandbox 'out'
$Store   = Join-Path $Proj '.claude/session-handoffs'

if (Test-Path $Sandbox) { Remove-Item $Sandbox -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Store | Out-Null
New-Item -ItemType Directory -Force -Path $Out   | Out-Null

$mid = [char]0x00B7

# --- The old-format predecessor. Every awkward shape the real chain uses. ---------------
$prev = @"
# Session Handoff: legacy-chain (seq 01)

**Date:** 2026-08-01  **Branch:** main  **Previous:** —
**Tree:** clean

## What this is about / where it started
A pre-v0.4.0 handoff. Old heading, no Format field, no carry line. The next handoff written
on top of this one is the format boundary.

## Decisions & what shipped (this session, additive)
- Router rewritten — lives in ``src/router.ts``

## Key files (absolute paths) — read these first
- ``src/router.ts`` — the rewrite

## Running state
- Background processes: none
- Dev servers / ports: none

## Verification — how to confirm things still work
- ``npm test`` — 12 passing

## Suggested skills for the next session
- none

## Deferred & open questions
- Deferred: retry budget for the router — nobody has picked a number
- Open: the cache key ignores the locale — reported by QA, unreproduced
- Aus _00 unverändert offen: #12 Sortierung der Trefferliste $mid #14 leerer Suchbegriff
  $mid #15 Umlaute im Slug $mid #18 Zeitzone im Export $mid #21 Doppelklick auf Speichern
  $mid #22 Abbruch mitten im Upload $mid #27 Pager springt auf Seite 1 $mid #31 Tooltip
  bleibt hängen
- **Bei Marcus offen (Reihenfolge egal):**
  1. Staging-Datenbank neu aufsetzen
  2. Zugangsdaten für den Mailversand hinterlegen
  3. Domain umschalten
  4. Backup-Job einschalten
- Unverändert die komplette Liste aus _00 — insbesondere der Umbau der Rechteprüfung
- Question: soll der Export CSV oder XLSX sein? — Marcus entscheidet

## Reference (do NOT duplicate — inline the essence above)
- Repo: https://example.invalid/legacy

## → Pick up here
Pick the retry budget for the router, then wire it into ``src/router.ts``.

---
Resume: ``/session-resume legacy-chain``
"@

Set-Content -LiteralPath (Join-Path $Store 'legacy-chain_01.md') -Value $prev -Encoding UTF8

# --- Optional: real field data, sandbox-only, never committed -----------------------------
$realCopied = 0
if (-not [string]::IsNullOrWhiteSpace($Chain) -and (Test-Path -LiteralPath $Chain)) {
    $newest = Get-ChildItem -LiteralPath $Chain -Filter '*_*.md' -File |
              Where-Object { $_.BaseName -match '_(\d+)$' } |
              Sort-Object { [int]([regex]::Match($_.BaseName, '_(\d+)$').Groups[1].Value) } |
              Select-Object -Last 1
    if ($null -ne $newest) {
        Copy-Item $newest.FullName (Join-Path $Store 'fielddata_01.md') -Force
        $realCopied = 1
    }
}

# --- A git repo, so the Tree: field has something real to report --------------------------
Push-Location $Proj
git init --quiet 2>$null
Set-Content -LiteralPath (Join-Path $Proj 'src-router.ts') -Value '// stub' -Encoding UTF8
Set-Content -LiteralPath (Join-Path $Proj '.gitignore') -Value '.claude/session-handoffs/' -Encoding UTF8
git add -A 2>$null
git -c user.email=t@t -c user.name=t commit -q -m 'initial' 2>$null
Pop-Location

Write-Host "SANDBOX_PROJ=$Proj"
Write-Host "SANDBOX_OUT=$Out"
Write-Host "EXPECTED_ITEMS=16"
Write-Host "REAL_FIELD_DATA_COPIED=$realCopied"
