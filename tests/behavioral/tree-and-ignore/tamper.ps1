#requires -Version 7
<#
  Changes one TRACKED file in the sandbox, after the `same` resume run and before the `prose`
  and `moved` runs. Afterwards `git status --porcelain` shows ` M src/app.ts`, so:

    moved_01.md   its Tree: says "tracked: clean"  -> resume must report that the tree moved
    prose_01.md   its Tree: is prose               -> resume must NOT compare, so no alarm
#>
$ErrorActionPreference = 'Stop'

$Proj = Join-Path $PSScriptRoot '.sandbox/proj'
$App  = Join-Path $Proj 'src/app.ts'
if (-not (Test-Path -LiteralPath $App)) { Write-Host 'Run setup.ps1 first.' -ForegroundColor Red; exit 1 }

Set-Content -LiteralPath $App -Value "export const retryTimeoutMs = 30000;`n" -Encoding UTF8
Write-Host 'Tampered: src/app.ts (tracked) now differs from the commit.'
git -C $Proj status --porcelain --untracked-files=no
