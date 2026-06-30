#requires -Version 5
<#
  Deterministic verifier for the behavioral run. Run AFTER the orchestrator has executed
  the three scenario agents and captured their final responses to .sandbox/out/S{1,2,3}.txt.
  Asserts on observable artifacts only (files + their content), never on exact prose.
  Exit 0 = all passed, 1 = at least one failed.
#>
$ErrorActionPreference = 'Stop'

$Behav    = $PSScriptRoot
$RepoRoot = Split-Path (Split-Path $Behav -Parent) -Parent
$Proj     = Join-Path $Behav '.sandbox/proj'
$Out      = Join-Path $Behav '.sandbox/out'
$Store    = Join-Path $Proj '.claude/session-handoffs'

$script:pass = 0; $script:fail = 0; $script:failed = @(); $script:group = ''
function Section([string]$n){ Write-Host ''; Write-Host "== $n ==" -ForegroundColor Cyan; $script:group=$n }
function Check([string]$n,[bool]$c){
    if($c){ $script:pass++; Write-Host "  [PASS] $n" -ForegroundColor Green }
    else  { $script:fail++; $script:failed += "$($script:group) :: $n"; Write-Host "  [FAIL] $n" -ForegroundColor Red }
}
function Load([string]$p){ if(Test-Path -LiteralPath $p){ Get-Content -LiteralPath $p -Raw } else { '' } }

$h01  = Load (Join-Path $Store 'widget-redesign_01.md')
$h02  = Load (Join-Path $Store 'widget-redesign_02.md')
$s1   = Load (Join-Path $Out 'S1.txt')
$s2   = Load (Join-Path $Out 'S2.txt')
$s3   = Load (Join-Path $Out 'S3.txt')
$plan = Load (Join-Path $Proj 'docs/superpowers/plans/2026-06-30-widget-redesign.md')

# -----------------------------------------------------------------------------
Section 'Isolation (real repo + memory untouched)'
# NB: the maintenance repo legitimately holds its own dogfooding handoffs (e.g.
# handoff-step7-and-tests_*). The real isolation property is that THIS suite's topic
# (widget-redesign) never leaked out of the sandbox into the real store.
$leaked = @(Get-ChildItem -Path (Join-Path $RepoRoot '.claude/session-handoffs') -Filter 'widget-redesign*' -Recurse -Force -ErrorAction SilentlyContinue)
Check 'no widget-redesign handoff leaked into maintenance repo' ($leaked.Count -eq 0)
Check 'no stray memory dir created in sandbox'           (-not (Test-Path (Join-Path $Proj 'memory')))

# -----------------------------------------------------------------------------
Section 'S1 — fresh handoff artifact (_01)'
Check '_01 file created' ($h01 -ne '')
foreach($s in 'What this is about','Decisions','Key files','Running state','Verification','Pick up here'){
    Check "_01 has section: $s" ($h01.Contains($s))
}
Check '_01 records the grid decision'        ($h01 -match '(?i)grid')
$h01n = $h01 -replace '\\','/'   # normalize Windows backslash paths before matching
Check '_01 references the plan by path'       ($h01n.Contains('docs/superpowers/plans/2026-06-30-widget-redesign'))
Check '_01 references the spec by path'       ($h01n.Contains('docs/superpowers/specs/2026-06-30-widget-redesign-design'))
Check '_01 LINKS spec, does NOT copy its body' (-not $h01.Contains('SENTINEL_SPEC_BODY_DO_NOT_COPY'))
Check 'gitignore got the store entry (append branch)' ((Load (Join-Path $Proj '.gitignore')).Contains('.claude/session-handoffs/'))

# -----------------------------------------------------------------------------
Section 'S1 — Step 7 behaviour (detect + draft + propose-only)'
Check 'memory candidate surfaced in response'      ($s1.ToUpper().Contains('MEMORY CANDIDATE'))
Check 'memory candidate IS the durable fact (WCAG)' ($s1 -match 'WCAG')
Check 'transient state NOT proposed as memory'      (-not ($s1 -match '(?i)memory candidate[\s\S]{0,400}dev server'))
Check 'plan edit proposed in response'              ($s1.ToUpper().Contains('PLAN EDIT PROPOSAL'))
Check 'plan file left UNCHANGED (no auto-write)'    ($plan.Contains('[ ] Step 2'))

# -----------------------------------------------------------------------------
Section 'S2 — carry-forward (_02)'
Check '_02 file created'                       ($h02 -ne '')
Check '_02 has Previous: link to _01'          ($h02 -match '(?i)Previous:[*\s]*widget-redesign_01')
Check '_02 carries forward grid decision (additive)' ($h02 -match '(?i)grid')
Check '_02 adds this session''s test decision' ($h02 -match '(?i)test')

# -----------------------------------------------------------------------------
Section 'S3 — resume (staleness + read-only)'
Check 'resume surfaced a staleness note'       ($s3 -match '(?i)stale|\bdays?\b')
Check 'resume gave a next-action suggestion'   ($s3 -match '(?i)pick up|next action|suggest')
$manifest = Join-Path $Out 'pre-s3-hashes.json'
if (Test-Path $manifest) {
    $pre = Get-Content $manifest -Raw | ConvertFrom-Json
    $stable = $true
    foreach ($e in $pre) {
        if (-not (Test-Path -LiteralPath $e.Path)) { $stable = $false; continue }
        $now = (Get-FileHash -LiteralPath $e.Path -Algorithm SHA256).Hash
        if ($now -ne $e.Hash) { $stable = $false }
    }
    Check 'resume modified NO handoff file (SHA256 stable)' $stable
} else {
    Check 'pre-S3 hash manifest exists' $false
}

# -----------------------------------------------------------------------------
Write-Host ''
Write-Host "================ BEHAVIORAL RESULT ================" -ForegroundColor Cyan
Write-Host ("Passed: {0}   Failed: {1}   Total: {2}" -f $script:pass,$script:fail,($script:pass+$script:fail))
if ($script:fail -gt 0) {
    Write-Host ''; Write-Host "Failed checks:" -ForegroundColor Red
    $script:failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
Write-Host "All behavioral checks passed." -ForegroundColor Green
exit 0
