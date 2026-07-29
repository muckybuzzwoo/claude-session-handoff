#requires -Version 5
<#
  Focused behavioral sub-test for the 2026-07-29 token-optimization rebuild
  (addendum 8d load paths). Self-contained: builds its own tiny isolated sandbox
  under load-discipline/.sandbox/ (gitignored) — does NOT touch the main S1/S2/S3
  sandbox, the maintenance repo, or the user's real Claude memory.

  Two adversarial fixtures with sentinel differentials:

  1. SECTION ANCHOR — a large living doc `docs/perf-backlog.md` is linked with a
     section-anchor tag `[READ-AT-RESUME: Current bottleneck]`. Distinctive words for
     the anchored section ("N+1", "IN()", "p95", "batch") live ONLY in that section and
     NEVER in the handoff. A far-away bottom section ("Redis bloom-filter") is the
     off-section trap: if resume read the WHOLE file it would surface it. Teeth:
     anchored words present + off-section words absent == resume read only the section.

  2. UNTAGGED — a plan-like `docs/roadmap.md` is linked WITHOUT any tag. Its body words
     ("audit log", "multi-region") live only there. Teeth: those words absent from the
     summary == resume did not blind-load the untagged file.

  Prints SANDBOX_PROJ / SANDBOX_OUT / BacklogBytes for the orchestrator.
#>
$ErrorActionPreference = 'Stop'

$Sandbox = Join-Path $PSScriptRoot '.sandbox'
$Proj    = Join-Path $Sandbox 'proj'
$Out     = Join-Path $Sandbox 'out'
$Store   = Join-Path $Proj '.claude/session-handoffs'
$Docs    = Join-Path $Proj 'docs'

if (Test-Path $Sandbox) { Remove-Item $Sandbox -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Store | Out-Null
New-Item -ItemType Directory -Force -Path $Out   | Out-Null
New-Item -ItemType Directory -Force -Path $Docs  | Out-Null

$today   = Get-Date -Format 'yyyy-MM-dd'
$backAbs = Join-Path $Docs  'perf-backlog.md'    # File A: large living doc, section-anchored
$roadAbs = Join-Path $Docs  'roadmap.md'         # File B: plan-like, linked UNTAGGED
$handAbs = Join-Path $Store 'perf-tuning_01.md'

# --- File A: large living doc. Anchored section near the TOP; the off-section trap at the
#     very BOTTOM, separated by a big filler block so a targeted section read cannot reach
#     it. Padded so bytes/4 is clearly over the ~15k-token trigger. ----------------------
$filler = (1..800 | ForEach-Object { "- perf note line ${_}: routine historical measurement, archived context padding, no action needed." }) -join "`n"
@"
# Perf Backlog (living doc)

## Current bottleneck
The active problem is an N+1 query on the dashboard load path.
Sentinel: ANCHOR_HIT_N_PLUS_ONE_QUERY.
Fix direction: batch the per-row lookups into a single IN() query, then measure p95 latency.

## Older notes (filler — not relevant to the current pickup)
$filler

## Archived experiments (far from the anchored section — the off-section trap)
An abandoned spike on a Redis bloom-filter cache, kept for history only.
Sentinel: OFFSECTION_SHOULD_NOT_LOAD_REDIS_BLOOM.
"@ | Set-Content -LiteralPath $backAbs -Encoding UTF8

# --- File B: a plan-like roadmap, linked UNTAGGED. Body words must NOT surface. ---------
@"
# Project Roadmap

## Q3 goals
Ship the reporting export and the audit log.
Sentinel: UNTAGGED_SHOULD_NOT_AUTOLOAD_QUANTUM.

## Q4 goals
Investigate the multi-region rollout.
"@ | Set-Content -LiteralPath $roadAbs -Encoding UTF8

# --- The handoff: section-anchor tag on File A, plain untagged link on File B. Carries
#     NONE of the teeth words itself (differential integrity, guarded in verify.ps1). ----
@"
# Session Handoff: Perf Tuning (seq 01)

**Date:** $today  **Branch:** main  **Previous:** —
**Tree:** clean

## What this is about / where it started
Performance tuning of the dashboard. The current driver is a slow dashboard load; the
detailed backlog is large and lives in a separate living doc.

## Decisions & what shipped (this session, additive)
- Identified the dashboard load path as the next target. Root cause and fix direction live
  in the perf backlog (linked below) — not duplicated here.

## Key files (absolute paths) — read these first
- ``$backAbs`` [READ-AT-RESUME: Current bottleneck] — read ONLY the current-bottleneck section.

## Running state
- Background processes: none
- Dev servers / ports: none
- Worktrees / branches: none

## Verification — how to confirm things still work
- (none yet) — work not started.

## Suggested skills for the next session
- none

## Deferred & open questions
- Open: whether to add an index or restructure the lookup — decide after measuring.

## Reference (do NOT duplicate — link by path/URL; tag substantial targets)
- Backlog: ``$backAbs`` [READ-AT-RESUME: Current bottleneck] · Roadmap: ``$roadAbs`` (untagged — load only if needed)

## -> Pick up here
Address the current dashboard bottleneck — see the backlog's "Current bottleneck" section.

---
Resume: ``/session-resume perf-tuning``  —  or read $handAbs
"@ | Set-Content -LiteralPath $handAbs -Encoding UTF8

'node_modules/' | Set-Content -LiteralPath (Join-Path $Proj '.gitignore') -Encoding UTF8

# Real git repo so resume's branch/staleness git calls work.
git -C $Proj init -q
git -C $Proj config user.email 'test@example.com'
git -C $Proj config user.name  'Sandbox Test'
git -C $Proj add -A
git -C $Proj commit -q -m 'init load-discipline sandbox'

# Read-only proof: snapshot hashes of the files resume must NOT modify.
$manifest = @(
    @{ Path = $handAbs; Hash = (Get-FileHash -LiteralPath $handAbs -Algorithm SHA256).Hash },
    @{ Path = $backAbs; Hash = (Get-FileHash -LiteralPath $backAbs -Algorithm SHA256).Hash },
    @{ Path = $roadAbs; Hash = (Get-FileHash -LiteralPath $roadAbs -Algorithm SHA256).Hash }
)
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Out 'pre-hashes.json') -Encoding UTF8

Write-Host "SANDBOX_PROJ=$Proj"
Write-Host "SANDBOX_OUT=$Out"
Write-Host "BacklogBytes=$((Get-Item $backAbs).Length)  (~$([math]::Round((Get-Item $backAbs).Length/4/1000,1))k tokens)"
Write-Host "Branch=$(git -C $Proj rev-parse --abbrev-ref HEAD)"
