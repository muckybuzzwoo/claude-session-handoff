#requires -Version 7
<#
  Builds the sandbox for the tree-and-ignore sub-test (v0.4.8).

  Two things the commands used to get wrong in a repo like app-manageforwork:

    1. `.gitignore` already ignores the store through a BROADER rule (`/.claude/`), but the
       literal line `.claude/session-handoffs/` is missing. Step 5 used to read the text, find
       no match, and append a pointless line to a versioned file. It must ask git instead.
    2. The repo has ~22 untracked top-level entries that never get committed. The `Tree:`
       field used to be written as prose there, so resume never compared it. It must now be
       written in the fixed form and compared.

  Sandbox shape:
    .gitignore            `node_modules/` and `/.claude/` — NOT the literal store line
    src/app.ts, README.md tracked and committed
    22 untracked entries  docs/ plus 21 loose files at the root, like the real repo
    store/same_01.md      Tree: matches the tree as built (resume run BEFORE tamper.ps1)
    store/prose_01.md     Tree: is prose, copied in style from a real old header
    store/moved_01.md     Tree: matches the tree as built; tamper.ps1 then changes src/app.ts

  Run order: setup -> handoff agent (T1) -> resume `same` (T2) -> tamper.ps1 -> resume
  `prose` (T3) -> resume `moved` (T4) -> verify.ps1. T3 runs AFTER the tamper on purpose: the
  prose header says "clean for tracked files" and the tree is no longer clean, so a reader that
  compares prose would raise a false alarm. A reader that skips prose says nothing.

  Re-runnable: wipes and rebuilds .sandbox/.
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib.ps1')

$Root  = Join-Path $PSScriptRoot '.sandbox'
$Proj  = Join-Path $Root 'proj'
$Out   = Join-Path $Root 'out'
$Store = Join-Path $Proj '.claude/session-handoffs'

if (Test-Path $Root) { Remove-Item $Root -Recurse -Force }
$null = New-Item -ItemType Directory -Force -Path $Store
$null = New-Item -ItemType Directory -Force -Path $Out
$null = New-Item -ItemType Directory -Force -Path (Join-Path $Proj 'src')
$null = New-Item -ItemType Directory -Force -Path (Join-Path $Proj 'docs')

# --- tracked baseline -------------------------------------------------------------------
Set-Content -LiteralPath (Join-Path $Proj '.gitignore') -Value "node_modules/`n/.claude/" -Encoding UTF8
Set-Content -LiteralPath (Join-Path $Proj 'src/app.ts') -Value "export const retryTimeoutMs = 10000;`n" -Encoding UTF8
Set-Content -LiteralPath (Join-Path $Proj 'README.md')  -Value "# Sandbox app`n" -Encoding UTF8

git -C $Proj init -q
git -C $Proj config user.email 'sandbox@example.invalid'
git -C $Proj config user.name  'Sandbox'
git -C $Proj add .gitignore src/app.ts README.md
git -C $Proj commit -q -m 'sandbox baseline'

# --- 22 permanently untracked top-level entries (docs/ + 21 files) -----------------------
1..3  | ForEach-Object { Set-Content -LiteralPath (Join-Path $Proj ('docs/note_{0:D2}.md' -f $_)) -Value "note $_`n" -Encoding UTF8 }
1..10 | ForEach-Object { Set-Content -LiteralPath (Join-Path $Proj ('analysis_{0:D2}.py' -f $_))  -Value "# analysis $_`n" -Encoding UTF8 }
1..10 | ForEach-Object { Set-Content -LiteralPath (Join-Path $Proj ('shot_{0:D2}.png' -f $_))     -Value "png $_`n" -Encoding UTF8 }
Set-Content -LiteralPath (Join-Path $Proj 'scratch.txt') -Value "scratch`n" -Encoding UTF8

$branch = git -C $Proj rev-parse --abbrev-ref HEAD
$tree   = Get-TreeForm $Proj

# --- the three resume handoffs ----------------------------------------------------------
function New-Handoff([string]$Slug, [string]$TreeValue, [string]$Marker) {
@"
# Session Handoff: $Slug (seq 01)

**Date:** 2026-10-21  **Branch:** $branch  **Previous:** —
**Tree:** $TreeValue
**Format:** 2

## Status
- **Where it stands:** the retry timeout in ``src/app.ts`` is still 10 s and has not been changed.
- **This session:** read ``src/app.ts`` and agreed the timeout is too short ($Marker).

## → Pick up here
Raise ``retryTimeoutMs`` in ``src/app.ts`` from 10000 to 30000 and re-run the smoke test.

## Open work
- Open: **raise the retry timeout** — 10 s is shorter than the slowest upstream call. → ``src/app.ts``

## What this is about / where it started
A flaky retry in the sandbox app. This chain exists only to give the resume command something to read.

## Decisions & what shipped (this session, additive)
- Raise the timeout to 30 s rather than add a second retry — one change, no new failure mode.

## Key files (absolute paths) — read these first
- ``src/app.ts`` — holds ``retryTimeoutMs``.

## Running state
- Background processes: none.
- Dev servers / ports: none.

## Verification — how to confirm things still work
- none yet.

---
Resume: ``/session-resume $Slug``
"@
}

$prose = 'clean for tracked files (only pre-existing untracked: docs/, analysis scripts and screenshots at the repo root)'
$files = @(
    @{ Name = 'same_01.md';  Slug = 'same';  Tree = $tree;  Marker = 'SENTINEL_TREE_SAME' },
    @{ Name = 'prose_01.md'; Slug = 'prose'; Tree = $prose; Marker = 'SENTINEL_TREE_PROSE' },
    @{ Name = 'moved_01.md'; Slug = 'moved'; Tree = $tree;  Marker = 'SENTINEL_TREE_MOVED' }
)
$manifest = @()
foreach ($f in $files) {
    $p = Join-Path $Store $f.Name
    Set-Content -LiteralPath $p -Value (New-Handoff $f.Slug $f.Tree $f.Marker) -Encoding UTF8
    $manifest += @{ Path = $p; Hash = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash }
}
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Out 'pre-hashes.json') -Encoding UTF8

$gi = Join-Path $Proj '.gitignore'
Copy-Item -LiteralPath $gi -Destination (Join-Path $Out 'gitignore.orig')
@{
    GitignoreHash = (Get-FileHash -LiteralPath $gi -Algorithm SHA256).Hash
    Tree          = $tree
    Branch        = $branch
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Out 'baseline.json') -Encoding UTF8

Write-Host "Sandbox built: $Proj"
Write-Host "Tree as built: $tree"
Write-Host ''
Write-Host 'Run order (responses go to .sandbox/out/):'
Write-Host '  1. handoff agent, topic tae          -> T1-handoff.txt   (scenario-handoff.md)'
Write-Host '  2. resume agent,  topic same         -> T2-same.txt      (scenario-resume.md)'
Write-Host '  3. pwsh -File tamper.ps1'
Write-Host '  4. resume agent,  topic prose        -> T3-prose.txt'
Write-Host '  5. resume agent,  topic moved        -> T4-moved.txt'
Write-Host '  6. pwsh -File verify.ps1'
