#requires -Version 7
<#
  Deterministic verifier for the tree-and-ignore sub-test (v0.4.8). Run AFTER the four agents
  have run (see setup.ps1) and their final responses sit in .sandbox/out/:

    T1-handoff.txt   handoff for topic `tae`
    T2-same.txt      resume `same`   (tree equals the recorded snapshot)
    T3-prose.txt     resume `prose`  (Tree: is prose; run after tamper.ps1)
    T4-moved.txt     resume `moved`  (a tracked file changed since the snapshot)

  Exit 0 = pass, 1 = fail.

  Asserted on artifacts and on a few fixed phrases the command itself defines (`Tree moved`,
  the weak-hint wording). Never on free prose. The expected `Tree:` value is computed here from
  git, independently of the agent, through lib.ps1.
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib.ps1')

$Behav    = Split-Path $PSScriptRoot -Parent
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

$giPath   = Join-Path $Proj '.gitignore'
$gi       = Load $giPath
$baseline = if (Test-Path (Join-Path $Out 'baseline.json')) { Get-Content (Join-Path $Out 'baseline.json') -Raw | ConvertFrom-Json } else { $null }
$tae      = Load (Join-Path $Store 'tae_01.md')
$t1 = Load (Join-Path $Out 'T1-handoff.txt')
$t2 = Load (Join-Path $Out 'T2-same.txt')
$t3 = Load (Join-Path $Out 'T3-prose.txt')
$t4 = Load (Join-Path $Out 'T4-moved.txt')

# Phrases the command defines for its two kinds of note (session-resume.md Step 3).
$movedRx = '(?i)\btree moved\b'
$weakRx  = '(?i)untracked files differ'

# -----------------------------------------------------------------------------
Section 'Isolation (this run did not leak into the real repo)'
$leaked = @(Get-ChildItem -Path (Join-Path $RepoRoot '.claude/session-handoffs') -Include 'tae_*','same_*','prose_*','moved_*' -Recurse -Force -ErrorAction SilentlyContinue)
Check 'no sandbox handoff leaked into the maintenance repo' ($leaked.Count -eq 0)
Check 'no stray memory dir created in sandbox'              (-not (Test-Path (Join-Path $Proj 'memory')))

# -----------------------------------------------------------------------------
Section 'Preconditions (test validity — these guard the teeth)'
Check 'baseline manifest exists'                             ($null -ne $baseline)
Check '.gitignore holds the broad rule /.claude/'            ($gi -match '(?m)^/\.claude/\s*$')
git -C $Proj check-ignore -q .claude/session-handoffs/probe.md
Check 'git already ignores the store (check-ignore exit 0)'  ($LASTEXITCODE -eq 0)
$giOrig = Load (Join-Path $Out 'gitignore.orig')
Check 'original .gitignore lacks the literal store line'     ($giOrig -ne '' -and -not $giOrig.Contains('.claude/session-handoffs/'))
$untrNow = @(git -C $Proj status --porcelain | Where-Object { $_.StartsWith('??') })
Check 'sandbox has the 22 untracked entries'                 ($untrNow.Count -eq 22)
Check 'baseline Tree is in the new form'                     ($baseline -and $baseline.Tree -match '^tracked: clean · untracked: 22 · set: [0-9a-f]{7}$')
Check 'same_01 and moved_01 carry the baseline Tree'         (
    (Load (Join-Path $Store 'same_01.md')).Contains("**Tree:** $($baseline.Tree)") -and
    (Load (Join-Path $Store 'moved_01.md')).Contains("**Tree:** $($baseline.Tree)"))
Check 'prose_01 Tree is prose, not the new form'             (
    (Load (Join-Path $Store 'prose_01.md')) -match '(?m)^\*\*Tree:\*\*\s+clean for tracked files' )
$trackedNow = @(git -C $Proj status --porcelain --untracked-files=no)
Check 'tamper happened: src/app.ts is modified'              (@($trackedNow | Where-Object { $_ -match 'src/app\.ts' }).Count -gt 0)

# -----------------------------------------------------------------------------
Section 'T1 — handoff must not touch an already-ignored store setup'
Check 'response captured'                                    ($t1 -ne '')
Check 'handoff tae_01.md written'                            ($tae -ne '')
Check '.gitignore unchanged (SHA256 equals the baseline)'    ($baseline -and ((Get-FileHash -LiteralPath $giPath -Algorithm SHA256).Hash -eq $baseline.GitignoreHash))
Check '.gitignore still lacks the literal store line'        (-not $gi.Contains('.claude/session-handoffs/'))
Check 'response names the rule that already ignores the store' (
    $t1 -match '(?<![\w.\-])/\.claude/(?!session-handoffs)')

# -----------------------------------------------------------------------------
Section 'T1 — Tree: is written in the fixed form'
$treeLine = if ($tae -match '(?m)^\*\*Tree:\*\*\s+(.+?)\s*$') { $Matches[1] } else { '' }
Check 'Tree: line present'                                   ($treeLine -ne '')
Check 'Tree: is NOT prose'                                   ($treeLine -match '^tracked: ')
Check 'Tree: matches the grammar'                            ($treeLine -match '^tracked: (clean|\d+ \(.+\)) · untracked: \d+( · set: [0-9a-f]{7})?$')
Check 'Tree: reports the true untracked count (22)'          ($treeLine -match '· untracked: 22\b')
Check 'Tree: equals the value git gives at handoff time'     ($baseline -and $treeLine -eq $baseline.Tree)

# -----------------------------------------------------------------------------
Section 'T2 — same tree as recorded: resume stays quiet'
Check 'response captured'                                    ($t2 -ne '')
Check 'loaded the `same` chain'                              ($t2 -match '(?i)same_01')
Check 'no "Tree moved" note'                                 (-not ($t2 -match $movedRx))
Check 'no untracked-files hint'                              (-not ($t2 -match $weakRx))

# -----------------------------------------------------------------------------
Section 'T3 — prose Tree: is skipped, never compared'
Check 'response captured'                                    ($t3 -ne '')
Check 'loaded the `prose` chain'                             ($t3 -match '(?i)prose_01')
Check 'no "Tree moved" note (no false alarm)'                (-not ($t3 -match $movedRx))
Check 'no untracked-files hint'                              (-not ($t3 -match $weakRx))

# -----------------------------------------------------------------------------
Section 'T4 — a tracked file changed: resume reports it'
Check 'response captured'                                    ($t4 -ne '')
Check 'loaded the `moved` chain'                             ($t4 -match '(?i)moved_01')
Check 'says the tree moved'                                  ($t4 -match $movedRx)
Check 'names the changed file'                               ($t4 -match 'src/app\.ts')
Check 'the note sits in a Warnings block'                    ($t4 -match '(?m)^##\s+Warnings')

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
Write-Host "Passed: $script:pass   Failed: $script:fail   Total: $($script:pass + $script:fail)"
if ($script:fail -gt 0) {
    Write-Host ''
    Write-Host "Failed checks:" -ForegroundColor Red
    $script:failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
Write-Host ''
Write-Host "Tree form written, compared and skipped correctly; the store rule was left alone." -ForegroundColor Green
exit 0
