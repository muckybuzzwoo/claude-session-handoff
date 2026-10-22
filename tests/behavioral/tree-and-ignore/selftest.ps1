#requires -Version 7
<#
  Self-test of verify.ps1 WITHOUT an LLM. Rebuilds the sandbox, writes a known-good set of
  artifacts and responses, and asserts the verifier passes. Then breaks one thing at a time
  and asserts the verifier fails each time. A verifier that has never rejected anything is not
  a verifier — same idea as carry-hop/selftest.ps1 and fixtures/carry-{ok,bad}.

  The scenario itself still needs real subagent runs; this only proves the verifier has teeth.
  Exit 0 = the verifier accepts the good set and rejects every mutant, 1 = it does not.
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib.ps1')

$Sandbox = Join-Path $PSScriptRoot '.sandbox'
$Proj    = Join-Path $Sandbox 'proj'
$Out     = Join-Path $Sandbox 'out'
$Store   = Join-Path $Proj '.claude/session-handoffs'
$Verify  = Join-Path $PSScriptRoot 'verify.ps1'

$script:pass = 0; $script:fail = 0; $script:failed = @()
function Check([string]$n,[bool]$c){
    if($c){ $script:pass++; Write-Host "  [PASS] $n" -ForegroundColor Green }
    else  { $script:fail++; $script:failed += $n; Write-Host "  [FAIL] $n" -ForegroundColor Red }
}
# A crash of verify.ps1 also exits 1, which would make every mutant look "rejected". Only a run
# that reached its own result line counts; anything else returns -1 and fails both kinds of check.
function Run-Verify {
    $o = & pwsh -NoProfile -File $Verify *>&1
    $code = $LASTEXITCODE
    if (($o | Out-String) -notmatch 'Passed:\s*\d+\s+Failed:\s*\d+') { return -1 }
    $code
}

$null = & pwsh -NoProfile -File (Join-Path $PSScriptRoot 'setup.ps1') *>&1
$baseline = Get-Content (Join-Path $Out 'baseline.json') -Raw | ConvertFrom-Json

# --- a known-good run, written by hand ----------------------------------------------------
@"
# Session Handoff: tae (seq 01)

**Date:** 2026-10-22  **Branch:** $($baseline.Branch)  **Previous:** —
**Tree:** $($baseline.Tree)
**Format:** 2

## Status
- **Where it stands:** the retry timeout is still 10 s.
"@ | Set-Content -LiteralPath (Join-Path $Store 'tae_01.md') -Encoding UTF8

$good = @{
    'T1-handoff.txt' = "Handoff saved: $Store/tae_01.md`nThe store is already ignored by .gitignore:2:/.claude/ , so .gitignore was not changed."
    'T2-same.txt'    = "## Loaded`nsame_01.md`n## Where we stand`n1. raise the retry timeout`n## What now`nStart with item 1."
    'T3-prose.txt'   = "## Loaded`nprose_01.md`n## Where we stand`n1. raise the retry timeout`n## What now`nStart with item 1."
    'T4-moved.txt'   = "## Loaded`nmoved_01.md`n## Where we stand`n1. raise the retry timeout`n## Warnings`nTree moved: tracked files changed since the handoff (was clean, now M src/app.ts).`n## What now`nStart with item 1."
}
foreach ($k in $good.Keys) { Set-Content -LiteralPath (Join-Path $Out $k) -Value $good[$k] -Encoding UTF8 }
$null = & pwsh -NoProfile -File (Join-Path $PSScriptRoot 'tamper.ps1') *>&1

Write-Host ''
Write-Host '== verifier accepts the good set ==' -ForegroundColor Cyan
Check 'good artifacts + responses pass (exit 0)' ((Run-Verify) -eq 0)

# --- mutants: break one thing, expect exit 1, restore --------------------------------------
function Test-Mutant([string]$name, [string]$path, [scriptblock]$mutate) {
    $orig = Get-Content -LiteralPath $path -Raw
    try {
        $new = & $mutate $orig
        Set-Content -LiteralPath $path -Value $new -Encoding UTF8 -NoNewline
        Check "verifier REJECTS: $name" ((Run-Verify) -eq 1)
    } finally {
        Set-Content -LiteralPath $path -Value $orig -Encoding UTF8 -NoNewline
    }
}

Write-Host ''
Write-Host '== verifier rejects each defect ==' -ForegroundColor Cyan
$gi    = Join-Path $Proj '.gitignore'
$tae   = Join-Path $Store 'tae_01.md'
$moved = Join-Path $Store 'moved_01.md'

Test-Mutant '.gitignore got the pointless store line appended' $gi    { param($t) $t + "`n.claude/session-handoffs/`n" }
Test-Mutant 'Tree: written as prose'                           $tae   { param($t) $t -replace '(?m)^\*\*Tree:\*\*.*$', '**Tree:** clean for tracked files (only untracked docs/)' }
Test-Mutant 'Tree: untracked count is wrong'                   $tae   { param($t) $t -replace 'untracked: 22', 'untracked: 5' }
Test-Mutant 'Tree: set hash is wrong'                          $tae   { param($t) $t -replace 'set: [0-9a-f]{7}', 'set: 0000000' }
Test-Mutant 'T1 does not name the ignoring rule'               (Join-Path $Out 'T1-handoff.txt') { param($t) 'Handoff saved. Nothing else to report.' }
Test-Mutant 'T2 (same tree) raises a "Tree moved" alarm'       (Join-Path $Out 'T2-same.txt')    { param($t) $t + "`nTree moved: something changed." }
Test-Mutant 'T3 (prose) raises a "Tree moved" alarm'           (Join-Path $Out 'T3-prose.txt')   { param($t) $t + "`nTree moved: clean no longer holds." }
Test-Mutant 'T3 (prose) raises the untracked-files hint'       (Join-Path $Out 'T3-prose.txt')   { param($t) $t + "`nThe untracked files differ from the snapshot." }
Test-Mutant 'T4 (tracked change) is not reported'              (Join-Path $Out 'T4-moved.txt')   { param($t) $t -replace 'Tree moved', 'Everything looks fine' }
Test-Mutant 'T4 does not name the changed file'                (Join-Path $Out 'T4-moved.txt')   { param($t) $t -replace 'src/app\.ts', 'a file' }
Test-Mutant 'resume modified a handoff (read-only breach)'     $moved { param($t) $t + "`nedited by resume`n" }

Write-Host ''
Write-Host '================ RESULT ================' -ForegroundColor Cyan
Write-Host "Passed: $script:pass   Failed: $script:fail"
if ($script:fail -gt 0) { $script:failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }; exit 1 }
Write-Host 'Verifier accepts the good set and rejects every defect.' -ForegroundColor Green
exit 0
