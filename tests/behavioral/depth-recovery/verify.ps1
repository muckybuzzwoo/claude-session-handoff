#requires -Version 5
<#
  Deterministic verifier for the deep-link depth-recovery sub-test. Run AFTER the
  orchestrator has executed the scenario agent and captured its final response to
  .sandbox/out/S4.txt. Asserts on observable artifacts only. Exit 0 = pass, 1 = fail.

  The teeth: "magic" / "fixation" / the SENTINEL token exist ONLY in the linked plan,
  never in the handoff (the preconditions below enforce that). So an S4 summary that
  contains them PROVES resume dereferenced the link rather than parroting the handoff.
#>
$ErrorActionPreference = 'Stop'

$Behav   = Split-Path $PSScriptRoot -Parent          # tests/behavioral
$RepoRoot= Split-Path (Split-Path $Behav -Parent) -Parent
$Proj    = Join-Path $PSScriptRoot '.sandbox/proj'
$Out     = Join-Path $PSScriptRoot '.sandbox/out'
$Store   = Join-Path $Proj '.claude/session-handoffs'

$script:pass = 0; $script:fail = 0; $script:failed = @(); $script:group = ''
function Section([string]$n){ Write-Host ''; Write-Host "== $n ==" -ForegroundColor Cyan; $script:group=$n }
function Check([string]$n,[bool]$c){
    if($c){ $script:pass++; Write-Host "  [PASS] $n" -ForegroundColor Green }
    else  { $script:fail++; $script:failed += "$($script:group) :: $n"; Write-Host "  [FAIL] $n" -ForegroundColor Red }
}
function Load([string]$p){ if(Test-Path -LiteralPath $p){ Get-Content -LiteralPath $p -Raw } else { '' } }

$hand = Load (Join-Path $Store 'auth-flow_01.md')
$plan = Load ((Get-ChildItem -LiteralPath (Join-Path $Proj 'docs/superpowers/plans') -Filter '*-auth-flow.md' -ErrorAction SilentlyContinue | Select-Object -First 1).FullName)
$s4   = Load (Join-Path $Out 'S4.txt')

$SENT = 'REJECTED_MAGIC_LINKS_SESSION_FIXATION'

# -----------------------------------------------------------------------------
Section 'Isolation (this run did not leak into the real repo)'
# NB: the maintenance repo legitimately holds its own dogfooding handoffs
# (handoff-step7-and-tests_*). The real isolation property for THIS sub-test is that its
# own topic (auth-flow) never leaked out of the sandbox into the real store.
$leaked = @(Get-ChildItem -Path (Join-Path $RepoRoot '.claude/session-handoffs') -Filter 'auth-flow*' -Recurse -Force -ErrorAction SilentlyContinue)
Check 'no auth-flow handoff leaked into maintenance repo' ($leaked.Count -eq 0)
Check 'no stray memory dir created in sandbox'            (-not (Test-Path (Join-Path $Proj 'memory')))

# -----------------------------------------------------------------------------
Section 'Preconditions (test validity — guards the teeth)'
Check 'handoff _01 exists'                              ($hand -ne '')
Check 'linked plan exists'                              ($plan -ne '')
Check 'handoff tags the plan link [READ-AT-RESUME]'     ($hand.Contains('[READ-AT-RESUME]'))
Check 'plan holds the rejected-option SENTINEL'         ($plan.Contains($SENT))
Check 'handoff does NOT leak the SENTINEL'              (-not $hand.Contains($SENT))
Check 'handoff does NOT contain "magic"  (plan-only)'   (-not ($hand -match '(?i)magic'))
Check 'handoff does NOT contain "fixation" (plan-only)' (-not ($hand -match '(?i)fixation'))

# -----------------------------------------------------------------------------
Section 'S4 — resume dereferenced the linked decision file'
Check 'S4 response captured'                            ($s4 -ne '')
Check 'S4 loaded the auth-flow handoff'                 ($s4 -match '(?i)auth-flow_01|auth-flow')
Check 'S4 surfaces "magic" (could ONLY come from plan)' ($s4 -match '(?i)magic')
Check 'S4 surfaces the session-fixation rationale'      ($s4 -match '(?i)fixation')
Check 'S4 presents it as a rejected/discarded option'   ($s4 -match '(?i)reject|discard|ruled out|not chosen')

# -----------------------------------------------------------------------------
Section 'Read-only (resume mutated nothing)'
$manifest = Join-Path $Out 'pre-hashes.json'
if (Test-Path $manifest) {
    $pre = Get-Content $manifest -Raw | ConvertFrom-Json
    $stable = $true
    foreach ($e in $pre) {
        if (-not (Test-Path -LiteralPath $e.Path)) { $stable = $false; continue }
        if ((Get-FileHash -LiteralPath $e.Path -Algorithm SHA256).Hash -ne $e.Hash) { $stable = $false }
    }
    Check 'resume modified NO file (SHA256 stable)' $stable
} else {
    Check 'pre-hash manifest exists' $false
}

# -----------------------------------------------------------------------------
Write-Host ''
Write-Host "================ DEPTH-RECOVERY RESULT ================" -ForegroundColor Cyan
Write-Host ("Passed: {0}   Failed: {1}   Total: {2}" -f $script:pass,$script:fail,($script:pass+$script:fail))
if ($script:fail -gt 0) {
    Write-Host ''; Write-Host "Failed checks:" -ForegroundColor Red
    $script:failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
Write-Host "All depth-recovery checks passed." -ForegroundColor Green
exit 0
