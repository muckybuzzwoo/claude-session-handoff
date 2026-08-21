#requires -Version 5
<#
  Gate G1 (plan section 9): do REAL pre-v0.4.0 handoffs still resume?

  The static suite proves the instruction text is present. This proves an LLM can still read
  the awkward shapes that actually exist on disk. Synthetic fixtures cannot do that job — the
  whole point is that these files were never written to a spec.

  TEST-DATA RULE (plan section 9): the real files are copied from the local project at run
  time into a gitignored sandbox and are NEVER committed. If that project is not present the
  gate SKIPS loudly rather than silently passing. A sanitised copy is not a substitute,
  because unedited structure is the property under test.

  Five deviations, each in its own single-file topic so `/session-resume` has to handle it
  alone:
    a  bare '## Reference' heading AND a renamed (German) Decisions heading
    b  bold-wrapped '**[READ-AT-RESUME]**' tags
    c  no '---' and no 'Resume:' footer at all
    d  decisions living in an extra section outside the canonical heading
    e  no '[READ-AT-RESUME]' tag anywhere (a normal state, not a defect)

  Records a SHA256 of every copied file so the read-only promise can be checked afterwards.
#>
$ErrorActionPreference = 'Stop'

$Apex = 'C:\Users\marcu\claude-projects\privat\projects\apex-roadtrip\.claude\session-handoffs'

if (-not (Test-Path -LiteralPath $Apex)) {
    Write-Host "SKIP=1" -ForegroundColor Yellow
    Write-Host "Gate G1 needs the real chain at:" -ForegroundColor Yellow
    Write-Host "  $Apex"
    Write-Host "It is not present, so this gate cannot run. It is SKIPPED, not passed."
    exit 0
}

$Sandbox = Join-Path $PSScriptRoot '.sandbox'
$Proj    = Join-Path $Sandbox 'proj'
$Out     = Join-Path $Sandbox 'out'
$Store   = Join-Path $Proj '.claude/session-handoffs'

if (Test-Path $Sandbox) { Remove-Item $Sandbox -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Store | Out-Null
New-Item -ItemType Directory -Force -Path $Out   | Out-Null

# a..d are the files the 2026-08-06 survey named. e is found at run time rather than
# hard-coded, so a chain that has moved on still yields a valid no-tag case.
$map = [ordered]@{
    'oldfmt-a' = 'apex-roadtrip_70.md'
    'oldfmt-b' = 'apex-roadtrip_50.md'
    'oldfmt-c' = 'apex-roadtrip_104.md'
    'oldfmt-d' = 'apex-roadtrip_119.md'
}

$noTag = Get-ChildItem -LiteralPath $Apex -Filter 'apex-roadtrip_*.md' -File |
         Where-Object { (Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8) -notmatch 'READ-AT-RESUME' } |
         Select-Object -First 1
if ($null -ne $noTag) { $map['oldfmt-e'] = $noTag.Name }

$copied = @()
$missing = @()
foreach ($slug in $map.Keys) {
    $src = Join-Path $Apex $map[$slug]
    if (-not (Test-Path -LiteralPath $src)) { $missing += $map[$slug]; continue }
    $dst = Join-Path $Store "${slug}_01.md"
    Copy-Item -LiteralPath $src -Destination $dst -Force
    $copied += [pscustomobject]@{
        Slug   = $slug
        Source = $map[$slug]
        Sha    = (Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash
    }
}

$copied | ForEach-Object { "$($_.Slug)`t$($_.Source)`t$($_.Sha)" } |
    Set-Content -LiteralPath (Join-Path $Out 'sha-before.txt') -Encoding UTF8

Push-Location $Proj
git init --quiet 2>$null
Set-Content -LiteralPath (Join-Path $Proj '.gitignore') -Value '.claude/session-handoffs/' -Encoding UTF8
git add -A 2>$null
git -c user.email=t@t -c user.name=t commit -q -m 'initial' 2>$null
Pop-Location

Write-Host "SKIP=0"
Write-Host "SANDBOX_PROJ=$Proj"
Write-Host "SANDBOX_OUT=$Out"
Write-Host "TOPICS=$(($copied | ForEach-Object { $_.Slug }) -join ',')"
foreach ($c in $copied) { Write-Host "  $($c.Slug) <- $($c.Source)" }
if ($missing.Count -gt 0) {
    Write-Host "MISSING=$($missing -join ',')" -ForegroundColor Yellow
}
