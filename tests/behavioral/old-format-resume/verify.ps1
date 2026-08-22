#requires -Version 7
<#
  Gate G1 assertions. Deterministic — re-runnable after a run.

  Two things are being proved:
    1. Every real old-format file still yields a usable briefing: a next action and at least
       one key file, despite a bare Reference heading, a renamed Decisions heading,
       bold-wrapped tags, a missing footer, an extra section, or no tag at all.
    2. `/session-resume` changed nothing. SHA256 of every file must be identical to the
       snapshot setup.ps1 took, and no file may have been added or removed.

  Exit 0 = gate passed, 1 = gate failed. Missing sandbox = the gate did not run, exit 1,
  because a gate that silently passes is worse than one that fails.
#>
$ErrorActionPreference = 'Stop'

$Sandbox = Join-Path $PSScriptRoot '.sandbox'
$Store   = Join-Path $Sandbox 'proj/.claude/session-handoffs'
$Out     = Join-Path $Sandbox 'out'
$ShaFile = Join-Path $Out 'sha-before.txt'

$script:pass = 0
$script:fail = 0
$script:failed = @()

function Section([string]$n) { Write-Host ''; Write-Host "== $n ==" -ForegroundColor Cyan }
function Check([string]$n, [bool]$c) {
    if ($c) { $script:pass++; Write-Host "  [PASS] $n" -ForegroundColor Green }
    else    { $script:fail++; $script:failed += $n; Write-Host "  [FAIL] $n" -ForegroundColor Red }
}

if (-not (Test-Path $ShaFile)) {
    Write-Host "Gate G1 did not run — no snapshot at $ShaFile" -ForegroundColor Red
    Write-Host "Run setup.ps1, then the agent, then this script." -ForegroundColor Yellow
    exit 1
}

$before = Get-Content -LiteralPath $ShaFile -Encoding UTF8 | Where-Object { $_.Trim() -ne '' } |
          ForEach-Object {
              $p = $_ -split "`t"
              [pscustomobject]@{ Slug = $p[0]; Source = $p[1]; Sha = $p[2] }
          }

Section 'Read-only promise — nothing was touched'
$files = Get-ChildItem -LiteralPath $Store -Filter '*_01.md' -File
Check "file count unchanged ($($before.Count) expected, $($files.Count) found)" (
    $files.Count -eq $before.Count)
foreach ($b in $before) {
    $p = Join-Path $Store "$($b.Slug)_01.md"
    $now = if (Test-Path -LiteralPath $p) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash } else { 'GONE' }
    Check "$($b.Slug) byte-identical after resume (from $($b.Source))" ($now -eq $b.Sha)
}
Check 'no memory directory created in the sandbox' (
    -not (Test-Path (Join-Path $Sandbox 'proj/memory')))
Check 'no done/ folder invented' (-not (Test-Path (Join-Path $Store 'done')))

Section 'Every deviation still produced a usable briefing'
foreach ($b in $before) {
    $rep = Join-Path $Out "G1-$($b.Slug).md"
    if (-not (Test-Path -LiteralPath $rep)) {
        Check "$($b.Slug): briefing file written" $false
        continue
    }
    $t = Get-Content -LiteralPath $rep -Raw -Encoding UTF8
    Check "$($b.Slug): briefing file written"        $true
    Check "$($b.Slug): briefing is substantial"      ($t.Length -ge 400)
    Check "$($b.Slug): names a next action"          ($t -match '(?m)^NEXT ACTION:\s*\S')
    Check "$($b.Slug): names at least one key file"  ($t -match '(?m)^KEY FILES:\s*\S')
    Check "$($b.Slug): states what it loaded"        ($t -match '(?m)^LOADED:\s*\S')
    Check "$($b.Slug): reports the odd shape it saw" ($t -match '(?m)^SOURCE-SHAPE:\s*\S')
    Check "$($b.Slug): did not report the file as unreadable" (
        -not ($t -match '(?i)(could not read|unreadable|failed to parse|corrupt)'))
}

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
Write-Host "Gate G1 passed — real old handoffs still resume, and nothing was modified." -ForegroundColor Green
exit 0
