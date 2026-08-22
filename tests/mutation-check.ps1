#requires -Version 5
<#
.SYNOPSIS
  Mutation harness for the static suite. Answers one question: which parts of a command
  file can be deleted without any check noticing?

.DESCRIPTION
  validate-commands.ps1 validates PROMPT files, so most of its checks are substring
  matches against the very text they validate. That is fine when a check reads from the
  block it is about, and worthless when it reads from the whole file — the check then
  passes on a stray occurrence somewhere else. Review section 4 estimated "roughly 154"
  such checks by counting call sites. Counting call sites is the wrong instrument: what
  matters is not how a check is written but whether it fails when its subject is gone.

  So this script deletes one block at a time (each `## H2` and each `### Step N`, fenced
  regions respected so the document template is one block rather than a dozen), runs the
  full static suite against the mutant, and reports how many checks the deletion broke.

  A block with 0 failures has no test coverage: it can be deleted and the suite stays
  green. Those are listed as UNCOVERED. Blocks that legitimately carry no assertion are
  named in $Allowed below; adding a block there is a decision to leave it untested, and
  the entry has to say why.

  Exit code 0 = every uncovered block is a known one, 1 = a new uncovered block appeared.

.PARAMETER Detail
  Also print the covered blocks with their failure counts, not just the uncovered ones.

.EXAMPLE
  pwsh -File .\tests\mutation-check.ps1

.EXAMPLE
  pwsh -File .\tests\mutation-check.ps1 -Detail
#>

param([switch]$Detail)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path $PSScriptRoot -Parent
$SrcDir   = Join-Path $RepoRoot 'commands'
$Suite    = Join-Path $PSScriptRoot 'validate-commands.ps1'

# Blocks known to carry no assertion, each with the reason it is acceptable.
# This list is a ratchet: a block that drops to zero coverage and is NOT here fails the run.
$Allowed = @()

function Get-Blocks([string]$path) {
    $lines  = [System.IO.File]::ReadAllLines($path)
    $inFence = $false
    $marks  = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^\s*```') { $inFence = -not $inFence; continue }
        if ($inFence) { continue }
        # The document template is full of `## Status`-style lines, but they sit inside a
        # fence and are skipped above, so only real headings reach here.
        if ($line -match '^## ' -or $line -match '^### Step \d+') { $marks += $i }
    }
    $blocks = @()
    for ($j = 0; $j -lt $marks.Count; $j++) {
        $start = $marks[$j]
        $end   = if ($j + 1 -lt $marks.Count) { $marks[$j + 1] - 1 } else { $lines.Count - 1 }
        $title = $lines[$start].Trim()
        if ($title.Length -gt 72) { $title = $title.Substring(0, 69) + '...' }
        $blocks += [pscustomobject]@{ Title = $title; Start = $start; End = $end; Lines = $lines }
    }
    $blocks
}

function Invoke-Suite([string]$dir) {
    $out = & pwsh -NoProfile -File $Suite -SrcDir $dir -LiveDir $dir 2>&1
    $line = ($out | Select-String -Pattern '^Passed:' | Select-Object -First 1).Line
    if ($line -match 'Passed:\s*(\d+)\s+Failed:\s*(\d+)') {
        return [pscustomobject]@{ Pass = [int]$Matches[1]; Fail = [int]$Matches[2] }
    }
    return [pscustomobject]@{ Pass = -1; Fail = -1 }
}

Write-Host "Mutation harness — deleting one block at a time, then running the static suite"
Write-Host "Commands: $SrcDir"

$tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("mutcheck-" + [System.Guid]::NewGuid().ToString('N').Substring(0, 8))
$tmpCmd  = Join-Path $tmpRoot 'commands'
$null = New-Item -ItemType Directory -Force -Path $tmpCmd

$baseline = $null
$results  = @()

try {
    Copy-Item (Join-Path $SrcDir '*.md') $tmpCmd -Force
    $baseline = Invoke-Suite $tmpCmd
    Write-Host ''
    Write-Host "Baseline (unmutated copy): Passed $($baseline.Pass)  Failed $($baseline.Fail)"
    if ($baseline.Fail -ne 0) {
        Write-Host "Baseline is not green — fix the suite before reading anything below." -ForegroundColor Red
        exit 1
    }

    foreach ($file in @('session-handoff.md', 'session-resume.md')) {
        $srcPath = Join-Path $SrcDir $file
        foreach ($b in (Get-Blocks $srcPath)) {
            # Rebuild the file without this block, leave the other file untouched.
            Copy-Item (Join-Path $SrcDir '*.md') $tmpCmd -Force
            $kept = @()
            for ($i = 0; $i -lt $b.Lines.Count; $i++) {
                if ($i -lt $b.Start -or $i -gt $b.End) { $kept += $b.Lines[$i] }
            }
            [System.IO.File]::WriteAllLines((Join-Path $tmpCmd $file), $kept)

            $r = Invoke-Suite $tmpCmd
            $results += [pscustomobject]@{
                Key      = "$file :: $($b.Title)"
                Failures = $r.Fail
                Deleted  = ($b.End - $b.Start + 1)
            }
            Write-Host '.' -NoNewline
        }
    }
} finally {
    if (Test-Path $tmpRoot) { Remove-Item $tmpRoot -Recurse -Force }
}

Write-Host ''
$uncovered = @($results | Where-Object { $_.Failures -eq 0 })
$covered   = @($results | Where-Object { $_.Failures -gt 0 })

Write-Host ''
Write-Host "================ RESULT ================" -ForegroundColor Cyan
Write-Host "Blocks mutated: $($results.Count)   covered: $($covered.Count)   uncovered: $($uncovered.Count)"

if ($Detail) {
    Write-Host ''
    Write-Host "Covered blocks (checks broken by deleting the block):"
    $covered | Sort-Object -Property Failures -Descending |
        ForEach-Object { Write-Host ("  {0,3} failures  {1} ({2} lines)" -f $_.Failures, $_.Key, $_.Deleted) }
}

$new = @($uncovered | Where-Object { $Allowed -notcontains $_.Key })

if ($uncovered.Count -gt 0) {
    Write-Host ''
    Write-Host "UNCOVERED — deleting these breaks nothing:" -ForegroundColor Yellow
    $uncovered | ForEach-Object {
        $known = if ($Allowed -contains $_.Key) { ' [known]' } else { '' }
        $color = if ($known) { 'DarkGray' } else { 'Red' }
        Write-Host ("  {0} ({1} lines){2}" -f $_.Key, $_.Deleted, $known) -ForegroundColor $color
    }
}

Write-Host ''
if ($new.Count -gt 0) {
    Write-Host "$($new.Count) block(s) have no coverage and are not in the allowed list." -ForegroundColor Red
    Write-Host "Either add a scoped check for the block, or add it to `$Allowed with a reason."
    exit 1
}

Write-Host "Every block is covered, or knowingly allowed." -ForegroundColor Green
exit 0
