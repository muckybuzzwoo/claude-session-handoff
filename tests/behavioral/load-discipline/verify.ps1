#requires -Version 5
<#
  Deterministic verifier for the load-discipline sub-test. Run AFTER the orchestrator has
  executed the scenario agent and captured its final response to .sandbox/out/S5.txt.
  Asserts on observable artifacts only. Exit 0 = pass, 1 = fail.

  The teeth (all guarded by preconditions):
  - Anchored-section words ("N+1" / "IN(" / "p95" / "batch") live ONLY in the backlog's
    "Current bottleneck" section, never in the handoff. Present in S5 => the anchored
    section was read.
  - Off-section words ("bloom" / "redis") live ONLY at the far bottom of the backlog.
    Absent from S5 => resume did NOT read the whole file (targeted section read worked).
  - Untagged-file words ("audit log" / "multi-region") live ONLY in the roadmap body.
    Absent from S5 => resume did NOT blind-load the untagged file.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$Proj     = Join-Path $PSScriptRoot '.sandbox/proj'
$Out      = Join-Path $PSScriptRoot '.sandbox/out'
$Store    = Join-Path $Proj '.claude/session-handoffs'
$Docs     = Join-Path $Proj 'docs'

$script:pass = 0; $script:fail = 0; $script:failed = @(); $script:group = ''
function Section([string]$n){ Write-Host ''; Write-Host "== $n ==" -ForegroundColor Cyan; $script:group=$n }
function Check([string]$n,[bool]$c){
    if($c){ $script:pass++; Write-Host "  [PASS] $n" -ForegroundColor Green }
    else  { $script:fail++; $script:failed += "$($script:group) :: $n"; Write-Host "  [FAIL] $n" -ForegroundColor Red }
}
function Load([string]$p){ if(Test-Path -LiteralPath $p){ Get-Content -LiteralPath $p -Raw } else { '' } }

$hand = Load (Join-Path $Store 'perf-tuning_01.md')
$back = Load (Join-Path $Docs  'perf-backlog.md')
$road = Load (Join-Path $Docs  'roadmap.md')
$s5   = Load (Join-Path $Out   'S5.txt')

# -----------------------------------------------------------------------------
Section 'Isolation (this run did not leak into the real repo)'
$leaked = @(Get-ChildItem -Path (Join-Path $RepoRoot '.claude/session-handoffs') -Filter 'perf-tuning*' -Recurse -Force -ErrorAction SilentlyContinue)
Check 'no perf-tuning handoff leaked into maintenance repo' ($leaked.Count -eq 0)
Check 'no stray memory dir created in sandbox'              (-not (Test-Path (Join-Path $Proj 'memory')))

# -----------------------------------------------------------------------------
Section 'Preconditions (test validity — guards the teeth)'
Check 'handoff _01 exists'                                 ($hand -ne '')
Check 'backlog (anchored file) exists'                     ($back -ne '')
Check 'roadmap (untagged file) exists'                     ($road -ne '')
Check 'handoff uses a SECTION ANCHOR tag'                  ($hand.Contains('[READ-AT-RESUME: Current bottleneck]'))
Check 'roadmap link is UNTAGGED in the handoff'            (-not ($hand -match '(?im)roadmap[^\n]*READ-AT-RESUME'))
# backlog: anchored section words at top, off-section trap at bottom
Check 'backlog anchored section holds its sentinel'        ($back.Contains('ANCHOR_HIT_N_PLUS_ONE_QUERY'))
Check 'backlog off-section holds its trap sentinel'        ($back.Contains('OFFSECTION_SHOULD_NOT_LOAD_REDIS_BLOOM'))
Check 'anchored section precedes the off-section trap'     ($back.IndexOf('ANCHOR_HIT') -lt $back.IndexOf('OFFSECTION_'))
Check 'roadmap body holds its sentinel'                    ($road.Contains('UNTAGGED_SHOULD_NOT_AUTOLOAD_QUANTUM'))
# differential integrity: none of the teeth words are in the handoff itself
Check 'handoff does NOT contain anchored words (N+1/IN(/p95/batch)' (-not ($hand -match '(?i)n\+1|IN\(|p95|batch'))
Check 'handoff does NOT contain off-section words (bloom/redis)'    (-not ($hand -match '(?i)bloom|redis'))
Check 'handoff does NOT contain untagged-body words (audit log/multi-region)' (-not ($hand -match '(?i)audit log|multi-region'))

# -----------------------------------------------------------------------------
Section 'S5 — resume loaded the right slices, and only those'
Check 'S5 response captured'                               ($s5 -ne '')
Check 'S5 loaded the perf-tuning handoff'                  ($s5 -match '(?i)perf-tuning')
# ANCHOR WORKED: anchored-section detail surfaced (could only come from that section)
Check 'S5 surfaces the anchored-section fix detail (N+1/IN(/p95/batch)' ($s5 -match '(?i)n\+1|IN\(|p95|batch')
# TARGETED, NOT WHOLE FILE: the far off-section trap did NOT surface
Check 'S5 does NOT surface the off-section trap (bloom/redis) => read only the section' (-not ($s5 -match '(?i)bloom|redis'))
# UNTAGGED NOT BLIND-LOADED: roadmap body did NOT surface
Check 'S5 does NOT surface untagged roadmap body (audit log/multi-region) => not blind-loaded' (-not ($s5 -match '(?i)audit log|multi-region'))
# PEEK + OFFER: resume still acknowledged the untagged roadmap (offered / did not load)
Check 'S5 acknowledges the untagged roadmap (offered / not loaded)' (
    ($s5 -match '(?i)roadmap') -and ($s5 -match '(?i)untagged|offer|only if needed|did ?n.?t? load|not load|not.*fully|skeleton|heading'))

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
Write-Host "================ LOAD-DISCIPLINE RESULT ================" -ForegroundColor Cyan
Write-Host ("Passed: {0}   Failed: {1}   Total: {2}" -f $script:pass,$script:fail,($script:pass+$script:fail))
if ($script:fail -gt 0) {
    Write-Host ''; Write-Host "Failed checks:" -ForegroundColor Red
    $script:failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
Write-Host "All load-discipline checks passed." -ForegroundColor Green
exit 0
