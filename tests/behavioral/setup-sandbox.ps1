#requires -Version 5
<#
  Creates a fresh, isolated sandbox project for the behavioral test run.
  Everything lives under tests/behavioral/.sandbox/ (gitignored) so the real
  maintenance repo and the user's real Claude memory are never touched.

  Prints SANDBOX_PROJ=<abs path> for the orchestrator to feed into the agents.
#>
$ErrorActionPreference = 'Stop'

$Sandbox = Join-Path $PSScriptRoot '.sandbox'
$Proj    = Join-Path $Sandbox 'proj'
$Out     = Join-Path $Sandbox 'out'

if (Test-Path $Sandbox) { Remove-Item $Sandbox -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Proj | Out-Null
New-Item -ItemType Directory -Force -Path $Out  | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Proj 'docs/superpowers/specs') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Proj 'docs/superpowers/plans') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Proj 'src') | Out-Null

# Fake superpowers spec — contains a sentinel so the verifier can prove the
# handoff LINKS the spec by path and does NOT copy its body.
@'
# Widget Redesign — Design

SENTINEL_SPEC_BODY_DO_NOT_COPY

Approach: replace the legacy table layout with a responsive grid. Accessibility is a
hard requirement for this client.
'@ | Set-Content -LiteralPath (Join-Path $Proj 'docs/superpowers/specs/2026-06-30-widget-redesign-design.md') -Encoding UTF8

# Fake superpowers plan with a checklist. Step 2 is the one S1 "completes".
@'
# Widget Redesign — Implementation Plan

- [ ] Step 1: audit the current widget
- [ ] Step 2: implement the new grid layout
- [ ] Step 3: add unit tests
'@ | Set-Content -LiteralPath (Join-Path $Proj 'docs/superpowers/plans/2026-06-30-widget-redesign.md') -Encoding UTF8

'// widget'      | Set-Content -LiteralPath (Join-Path $Proj 'src/widget.js')  -Encoding UTF8
'/* widget */'   | Set-Content -LiteralPath (Join-Path $Proj 'src/widget.css') -Encoding UTF8

# Pre-existing .gitignore so we exercise the APPEND branch of Step 5.
"node_modules/`n" | Set-Content -LiteralPath (Join-Path $Proj '.gitignore') -Encoding UTF8

# Real git repo with an initial commit (so branch + status calls work).
git -C $Proj init -q
git -C $Proj config user.email 'test@example.com'
git -C $Proj config user.name  'Sandbox Test'
git -C $Proj add -A
git -C $Proj commit -q -m 'init sandbox project'

Write-Host "SANDBOX_PROJ=$Proj"
Write-Host "SANDBOX_OUT=$Out"
Write-Host "Branch=$(git -C $Proj rev-parse --abbrev-ref HEAD)"
