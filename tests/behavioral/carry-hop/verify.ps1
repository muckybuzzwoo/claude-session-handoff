#requires -Version 5
<#
  Deterministic verifier for the carry-hop sub-test. Run AFTER the scenario agent has been
  executed and its final response captured to .sandbox/out/S6.txt. Exit 0 = pass, 1 = fail.

  The teeth: ALPHA / BETA / GAMMA exist ONLY in mig_01.md, never in mig_02.md (the
  preconditions below enforce that). mig_02.md is the file resume loads, so a briefing that
  names them PROVES the `Carried unchanged: 3 items — see mig_01.md` line was resolved rather
  than printed. DELTA is closed in mig_02.md and must be presented as closed, which is the
  defect v0.4.2 fixed: a `- Done:` bullet folded in as open work.

  Self-test without an LLM: run setup.ps1, copy one of fixtures/response-*.txt over
  .sandbox/out/S6.txt, and run this file. The good fixture must pass and the bad one must
  fail. That is how the verifier's teeth are checked, the same way fixtures/carry-{ok,bad}
  check the compat scanner.
#>
$ErrorActionPreference = 'Stop'

$Behav    = Split-Path $PSScriptRoot -Parent            # tests/behavioral
$RepoRoot = Split-Path (Split-Path $Behav -Parent) -Parent
$Proj     = Join-Path $PSScriptRoot '.sandbox/proj'
$Out      = Join-Path $PSScriptRoot '.sandbox/out'
$Store    = Join-Path $Proj '.claude/session-handoffs'

$script:pass = 0; $script:fail = 0; $script:failed = @(); $script:group = ''
function Section([string]$n){ Write-Host ''; Write-Host "== $n ==" -ForegroundColor Cyan; $script:group=$n }
function Check([string]$n,[bool]$c){
    if($c){ $script:pass++; Write-Host "  [PASS] $n" -ForegroundColor Green }
    else  { $script:fail++; $script:failed += "$($script:group) :: $n"; Write-Host "  [FAIL] $n" -ForegroundColor Red }
}
function Load([string]$p){ if(Test-Path -LiteralPath $p){ Get-Content -LiteralPath $p -Raw } else { '' } }

$h01  = Load (Join-Path $Store 'mig_01.md')
$h02  = Load (Join-Path $Store 'mig_02.md')
$resp = Load (Join-Path $Out 'S6.txt')

# -----------------------------------------------------------------------------
Section 'Isolation (this run did not leak into the real repo)'
$leaked = @(Get-ChildItem -Path (Join-Path $RepoRoot '.claude/session-handoffs') -Filter 'mig_*' -Recurse -Force -ErrorAction SilentlyContinue)
Check 'no mig handoff leaked into maintenance repo' ($leaked.Count -eq 0)
Check 'no stray memory dir created in sandbox'      (-not (Test-Path (Join-Path $Proj 'memory')))

# -----------------------------------------------------------------------------
Section 'Preconditions (test validity — these guard the teeth)'
Check 'mig_01 exists'                              ($h01 -ne '')
Check 'mig_02 exists'                              ($h02 -ne '')
Check 'hop target uses the OLD Open-work heading'  ($h01.Contains('## Deferred & open questions'))
Check 'hop target has NO Format: field'            (-not ($h01 -match '(?m)^\*\*Format:\*\*'))
Check 'loaded file declares Format: 2'             ($h02 -match '(?m)^\*\*Format:\*\*\s*2')
Check 'loaded file carries 3 items and names _01'  ($h02 -match 'Carried unchanged:\s*3 items\s*—\s*see mig_01\.md')
Check 'DELTA is closed in the loaded file'         ($h02 -match '(?m)^- Done:.*SENTINEL_CLOSED_DELTA')
foreach ($s in 'ALPHA','BETA','GAMMA') {
    Check "SENTINEL_CARRY_$s is in _01 only (the teeth)" (
        $h01.Contains("SENTINEL_CARRY_$s") -and -not $h02.Contains("SENTINEL_CARRY_$s"))
}

# -----------------------------------------------------------------------------
Section 'Behaviour — was the hop actually resolved?'
Check 'response captured'                          ($resp -ne '')
Check 'response loaded the HIGHEST sequence (_02)' ($resp -match '(?i)mig_02')
foreach ($s in 'ALPHA','BETA','GAMMA') {
    Check "briefing surfaces SENTINEL_CARRY_$s (only reachable via the hop)" (
        $resp.Contains("SENTINEL_CARRY_$s"))
}
# No check on the phrase "resolved 3 items". It would assert wording rather than behaviour,
# and the literal carry line already contains both "Carried" and "3", so the bad fixture
# would pass it. The three sentinel checks above already prove the hop was resolved, which
# makes a wording check a false-failure mode with no added coverage.

# -----------------------------------------------------------------------------
Section 'Behaviour — a closed item must not come back as open'
# DELTA is present either way, so presence proves nothing. What matters is HOW it is framed:
# within a short window it must read as closed, and it must never be labelled as open work.
Check 'DELTA is framed as closed/done' (
    $resp -match '(?is)SENTINEL_CLOSED_DELTA[\s\S]{0,200}(done|closed|resolved|abgeschlossen)|(done|closed|resolved)[\s\S]{0,200}SENTINEL_CLOSED_DELTA')
Check 'DELTA is NOT labelled an open item' (
    -not ($resp -match '(?im)^\s*[-*]?\s*(Open|Offen)\s*:.*SENTINEL_CLOSED_DELTA'))

# -----------------------------------------------------------------------------
Section 'Read-only (resume never writes to the store)'
$manifest = Join-Path $Out 'pre-hashes.json'
if (Test-Path $manifest) {
    $pre = Get-Content $manifest -Raw | ConvertFrom-Json
    $stable = $true
    foreach ($e in $pre) {
        if (-not (Test-Path -LiteralPath $e.Path)) { $stable = $false; continue }
        if ((Get-FileHash -LiteralPath $e.Path -Algorithm SHA256).Hash -ne $e.Hash) { $stable = $false }
    }
    Check 'resume modified NO handoff file (SHA256 stable)' $stable
} else {
    Check 'pre-hash manifest exists' $false
}

# -----------------------------------------------------------------------------
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
Write-Host "Carry hop resolved." -ForegroundColor Green
exit 0
