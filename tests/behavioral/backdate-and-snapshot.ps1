#requires -Version 7
<#
.SYNOPSIS
  The "backdate + snapshot" step of the S1/S2/S3 run. Runs between S2 and S3.

.DESCRIPTION
  README.md named this step in the run order, but no script implemented it, so two things
  were impossible from a clean checkout:

    * S3 asserts a staleness note, and nothing made the chain stale. The scenario prompt used
      to compensate by announcing the back-dating, which is exactly the leak removed on
      2026-08-22 — so the step has to be real now.
    * `verify-artifacts.ps1` reads `.sandbox/out/pre-s3-hashes.json` to prove resume wrote
      nothing. Nothing ever wrote that file, so the read-only check could only take its else
      branch and fail.

  This script does both, deterministically:

    1. Rewrites the `**Date:**` header of the newest handoff in the chain to $DaysOld days
       before today, leaving every other byte alone.
    2. Hashes every handoff file afterwards into pre-s3-hashes.json, so S3 is measured
       against the state it actually starts from.

  Order matters: back-date first, hash second. Hashing first would record a state that the
  back-dating then changes, and the read-only check would fail on this script's own edit.

.PARAMETER DaysOld
  How old to make the newest handoff. Default 29, comfortably past the command's 7-day
  threshold without looking synthetic.

.EXAMPLE
  pwsh -File .\tests\behavioral\backdate-and-snapshot.ps1
#>

param([int]$DaysOld = 29)

$ErrorActionPreference = 'Stop'

$Behav = $PSScriptRoot
$Proj  = Join-Path $Behav '.sandbox/proj'
$Out   = Join-Path $Behav '.sandbox/out'
$Store = Join-Path $Proj '.claude/session-handoffs'

if (-not (Test-Path $Store)) {
    Write-Host "No sandbox store at $Store — run setup-sandbox.ps1 and S1/S2 first." -ForegroundColor Red
    exit 1
}

$files = @(Get-ChildItem -LiteralPath $Store -Filter '*_*.md' -File | Sort-Object Name)
if ($files.Count -eq 0) {
    Write-Host "No handoff files in $Store — run S1 (and S2) first." -ForegroundColor Red
    exit 1
}

# Newest = highest sequence. Names are {slug}_{NN}.md, so a plain name sort is enough.
$newest = $files[-1]
$text   = [System.IO.File]::ReadAllText($newest.FullName)

$target = (Get-Date).AddDays(-$DaysOld).ToString('yyyy-MM-dd')
$before = if ($text -match '\*\*Date:\*\*\s*(\d{4}-\d{2}-\d{2})') { $Matches[1] } else { $null }

if (-not $before) {
    Write-Host "Could not find a '**Date:** YYYY-MM-DD' header in $($newest.Name)." -ForegroundColor Red
    Write-Host "Not guessing — the staleness step needs that header to exist."
    exit 1
}

$text = $text -replace '(\*\*Date:\*\*\s*)\d{4}-\d{2}-\d{2}', ('${1}' + $target)
[System.IO.File]::WriteAllText($newest.FullName, $text, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Back-dated $($newest.Name): $before -> $target ($DaysOld days old)"

# Snapshot AFTER the edit, so S3 is measured against what it really starts from.
$null = New-Item -ItemType Directory -Force -Path $Out
$manifest = foreach ($f in (Get-ChildItem -LiteralPath $Store -Filter '*_*.md' -File)) {
    @{ Path = $f.FullName; Hash = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash }
}
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Out 'pre-s3-hashes.json') -Encoding UTF8

Write-Host "Snapshotted $(@($manifest).Count) handoff file(s) to $(Join-Path $Out 'pre-s3-hashes.json')"
Write-Host ''
Write-Host "Now run S3, capture its final response to $(Join-Path $Out 'S3.txt'), then:"
Write-Host "  pwsh -File $(Join-Path $Behav 'verify-artifacts.ps1')"
