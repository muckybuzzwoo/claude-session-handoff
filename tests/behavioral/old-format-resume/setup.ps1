#requires -Version 5
<#
  Gate G1 (plan section 9): do REAL pre-v0.4.0 handoffs still resume?

  The static suite proves the instruction text is present. This proves an LLM can still read
  the awkward shapes that actually exist on disk. Synthetic fixtures cannot do that job — the
  whole point is that these files were never written to a spec.

  TEST-DATA RULE (plan section 9): the real files are copied from a local chain at run time
  into a gitignored sandbox and are NEVER committed. If no chain is given the gate SKIPS
  loudly rather than silently passing. A sanitised copy is not a substitute, because unedited
  structure is the property under test.

  Point it at your own chain with -Chain, or set SESSION_HANDOFF_TEST_CHAIN once. Nothing
  about one person's directory layout is baked into this file.

  Five deviations, each in its own single-file topic so `/session-resume` has to handle it
  alone:
    a  bare '## Reference' heading AND a renamed (German) Decisions heading
    b  bold-wrapped '**[READ-AT-RESUME]**' tags
    c  no '---' and no 'Resume:' footer at all
    d  decisions living in an extra section outside the canonical heading
    e  no '[READ-AT-RESUME]' tag anywhere (a normal state, not a defect)

  Records a SHA256 of every copied file so the read-only promise can be checked afterwards.
#>
param(
    # A real, long, pre-v0.4.0 handoff chain to borrow files from. Falls back to the
    # SESSION_HANDOFF_TEST_CHAIN environment variable.
    [string]$Chain = $env:SESSION_HANDOFF_TEST_CHAIN,

    # Filenames to use for the four named deviations. Override when your own chain's
    # awkward files sit at different sequence numbers.
    [string[]]$Files = @('_70', '_50', '_104', '_119')
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Chain) -or -not (Test-Path -LiteralPath $Chain)) {
    Write-Host "SKIP=1" -ForegroundColor Yellow
    Write-Host "Gate G1 needs a real pre-v0.4.0 handoff chain to borrow files from." -ForegroundColor Yellow
    Write-Host "Give it one:"
    Write-Host "  pwsh -File .\setup.ps1 -Chain 'C:\path\to\project\.claude\session-handoffs'"
    Write-Host "or set it once:"
    Write-Host "  `$env:SESSION_HANDOFF_TEST_CHAIN = 'C:\path\to\project\.claude\session-handoffs'"
    if (-not [string]::IsNullOrWhiteSpace($Chain)) { Write-Host "Given path does not exist: $Chain" -ForegroundColor Yellow }
    Write-Host "This gate is SKIPPED, not passed."
    exit 0
}

$Apex = $Chain

$Sandbox = Join-Path $PSScriptRoot '.sandbox'
$Proj    = Join-Path $Sandbox 'proj'
$Out     = Join-Path $Sandbox 'out'
$Store   = Join-Path $Proj '.claude/session-handoffs'

if (Test-Path $Sandbox) { Remove-Item $Sandbox -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Store | Out-Null
New-Item -ItemType Directory -Force -Path $Out   | Out-Null

# The chain's own topic slug, whatever it is — derived, never assumed.
$all = @(Get-ChildItem -LiteralPath $Apex -Filter '*_*.md' -File |
         Where-Object { $_.BaseName -match '_\d+$' })
if ($all.Count -eq 0) {
    Write-Host "SKIP=1" -ForegroundColor Yellow
    Write-Host "No handoff files (name_NN.md) in: $Apex"
    exit 0
}
$slugPrefix = ($all[0].BaseName -replace '_\d+$', '')

# a..d are the four deviations, addressed by sequence so the same script works on any chain.
# e is found at run time, so a chain that has moved on still yields a valid no-tag case.
$map = [ordered]@{}
$letters = @('a','b','c','d')
for ($i = 0; $i -lt $Files.Count -and $i -lt 4; $i++) {
    $map["oldfmt-$($letters[$i])"] = "$slugPrefix$($Files[$i]).md"
}

$noTag = $all |
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
