#requires -Version 5
<#
  Asserts on the artifact the format-boundary agent produced. Deterministic — run it as
  often as you like after a run.

  The property under test: the FIRST new-format handoff written on top of an old-format
  chain neither breaks nor loses anything. The predecessor holds 16 open items behind every
  awkward shape the real field data uses (wrapped bullet with middot separators, group
  header with numbered children, prose pointer with no number).

  Expected accounting for this scenario: 16 open items in _01. The session closed two of
  them (the retry budget, decided; the export question, answered) and added one new item
  (noisy retry logging). So the file must account for all 16 and may carry at most 14.

  Exit 0 = every assertion passed, 1 = at least one failed.
#>
$ErrorActionPreference = 'Stop'

$Store = Join-Path $PSScriptRoot '.sandbox/proj/.claude/session-handoffs'

$script:pass = 0
$script:fail = 0
$script:failed = @()

function Section([string]$n) { Write-Host ''; Write-Host "== $n ==" -ForegroundColor Cyan }
function Check([string]$n, [bool]$c) {
    if ($c) { $script:pass++; Write-Host "  [PASS] $n" -ForegroundColor Green }
    else    { $script:fail++; $script:failed += $n; Write-Host "  [FAIL] $n" -ForegroundColor Red }
}

if (-not (Test-Path $Store)) {
    Write-Host "No sandbox. Run setup.ps1 and the agent first." -ForegroundColor Red
    exit 1
}

$new = Get-ChildItem -LiteralPath $Store -Filter 'legacy-chain_02.md' -File -ErrorAction SilentlyContinue
Section 'The boundary file exists at all'
Check 'legacy-chain_02.md was written' ($null -ne $new)
if ($null -eq $new) {
    Write-Host ''
    Write-Host "Nothing else can be checked." -ForegroundColor Red
    exit 1
}

$t = Get-Content -LiteralPath $new.FullName -Raw -Encoding UTF8
$mid = [char]0x00B7

Section 'The old file was left alone (the promise that must never break)'
$old = Get-Content -LiteralPath (Join-Path $Store 'legacy-chain_01.md') -Raw -Encoding UTF8
Check '_01 still carries the OLD heading'      ($old -match '(?m)^## Deferred & open questions')
Check '_01 was not given a Format field'       (-not ($old -match '(?m)^\*\*Format:'))
Check '_01 still has its 16 items intact'      ($old -match '#31 Tooltip')

Section 'New format markers (1A + 1E)'
Check 'has the Format field'                   ($t -match '(?m)^\*\*Format:\*\*\s*2')
Check 'has a Status section'                   ($t -match '(?m)^## Status')
Check 'Status names where it stands'           ($t -match 'Where it stands')
Check 'Status names what this session changed' ($t -match 'This session')
Check 'has an Open work section'               ($t -match '(?m)^## Open work')
Check 'does NOT use the old heading'           (-not ($t -match '(?m)^## Deferred & open questions'))
Check 'Previous: points at _01'                ($t -match 'legacy-chain_01\.md')

Section 'Order: forward-looking block before the retrospective'
$iStatus = $t.IndexOf('## Status')
$iPick   = $t.IndexOf('Pick up here')
$iOpen   = $t.IndexOf('## Open work')
$iAbout  = $t.IndexOf('## What this is about')
Check 'Status is first of the four'      ($iStatus -ge 0 -and $iStatus -lt $iPick -and $iStatus -lt $iOpen)
Check 'Pick up here before Open work'    ($iPick -lt $iOpen)
Check 'Open work before the retrospective' ($iOpen -lt $iAbout)
# The HEADING may appear once. Prose may still cite the previous file's section by name,
# which is a reference, not a duplicated next action.
Check 'the Pick up here HEADING appears exactly once' (
    ([regex]::Matches($t, '(?m)^##\s+→ Pick up here')).Count -eq 1)

Section 'The carry rule (V4) — nothing may vanish'
$carry = [regex]::Match($t, 'Carried unchanged:\s*(\d+)')
Check 'a Carried unchanged line exists' ($carry.Success)
$n = if ($carry.Success) { [int]$carry.Groups[1].Value } else { -1 }
Check "carry count is plausible (1..14, got $n)" ($n -ge 1 -and $n -le 14)

$doneCount = ([regex]::Matches($t, '(?m)^\s*-\s+\*{0,2}Done:')).Count
Check "closed items are written as Done: bullets (got $doneCount)" ($doneCount -ge 1)
Check 'the retry budget is recorded as decided/closed' ($t -match '(?i)retry' -and $t -match '(?i)(3 attempts|200)')
Check 'the settled export question is not left open as a question' (
    -not ($t -match '(?i)-\s+\*{0,2}Question:.*export'))

Section 'The two things that must survive verbatim'
Check 'the unreproduced locale cache-key item is still present' ($t -match '(?i)locale')
Check 'the numberless prose pointer is preserved, not turned into a number' (
    $t -match '(?i)komplette Liste aus _00' -or $t -match '(?i)unresolved')

Section 'The new item from this session'
# Scoped to the Open-work block on purpose. The item is also named in Status and in
# Pick-up-here, so an unscoped match is satisfied without it ever becoming a countable item —
# which is exactly how the 2026-08-21 artifact passed this check while dropping the item.
$openBlock = [regex]::Match($t, '(?ms)^## Open work\r?\n(.*?)(?=^## )').Groups[1].Value
Check 'noisy retry logging is a labelled item inside Open work' (
    $openBlock -match '(?im)^\s*-\s+\*{0,2}(Open|Deferred|Question):.*(logging|log level|noisy)')

Section 'Nothing escaped the sandbox'
Check 'no memory directory was created in the sandbox' (
    -not (Test-Path (Join-Path $PSScriptRoot '.sandbox/proj/memory')))
Check 'no third handoff was invented' (
    (Get-ChildItem -LiteralPath $Store -Filter 'legacy-chain_*.md' -File).Count -eq 2)

Write-Host ''
Write-Host "================ RESULT ================" -ForegroundColor Cyan
Write-Host "Passed: $script:pass   Failed: $script:fail"
if ($script:fail -gt 0) {
    Write-Host ''
    Write-Host "Failed checks:" -ForegroundColor Red
    $script:failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
Write-Host ''
Write-Host "Format boundary held." -ForegroundColor Green
exit 0
