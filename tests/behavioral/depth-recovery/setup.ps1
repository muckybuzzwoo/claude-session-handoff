#requires -Version 5
<#
  Focused behavioral sub-test for the deep-link depth-recovery fix
  (the [READ-AT-RESUME] contract). Self-contained: builds its own tiny isolated
  sandbox under depth-recovery/.sandbox/ (gitignored) — does NOT touch the main
  S1/S2/S3 sandbox, the maintenance repo, or the user's real Claude memory.

  The fixture is deliberately adversarial: the handoff is a COMPRESSED pointer that
  links a plan tagged [READ-AT-RESUME]. The plan holds the FULL grilled decisions,
  including a rejected option whose distinctive words ("magic", "fixation", and a
  SENTINEL token) appear ONLY in the plan, NEVER in the handoff. So if the resume
  summary surfaces those words, it can ONLY have come from dereferencing the link —
  that is the property under test.

  Prints SANDBOX_PROJ / SANDBOX_OUT for the orchestrator to feed into the agent.
#>
$ErrorActionPreference = 'Stop'

$Sandbox = Join-Path $PSScriptRoot '.sandbox'
$Proj    = Join-Path $Sandbox 'proj'
$Out     = Join-Path $Sandbox 'out'
$Store   = Join-Path $Proj '.claude/session-handoffs'
$Plans   = Join-Path $Proj 'docs/superpowers/plans'

if (Test-Path $Sandbox) { Remove-Item $Sandbox -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Store | Out-Null
New-Item -ItemType Directory -Force -Path $Out   | Out-Null
New-Item -ItemType Directory -Force -Path $Plans | Out-Null

$today    = Get-Date -Format 'yyyy-MM-dd'
$planAbs  = Join-Path $Plans   "$today-auth-flow.md"
$handAbs  = Join-Path $Store   'auth-flow_01.md'

# --- The LINKED plan: holds the full roadmap + grilled decisions. The rejected option's
#     distinctive words live ONLY here. ----------------------------------------------------
@"
# Auth Flow — Implementation Plan

## Roadmap
- [x] Step 1: choose token strategy
- [ ] Step 2: implement refresh-token rotation
- [ ] Step 3: add logout-everywhere (revoke all refresh tokens)

## Decisions (grilled)
- CHOSE: short-lived access JWT (15 min) + rotating refresh token in an httpOnly cookie.
- REJECTED: magic-link-only authentication.
  Sentinel: REJECTED_MAGIC_LINKS_SESSION_FIXATION.
  Why discarded: it opens a session-fixation window during the email round-trip, and the
  client requires offline re-auth which magic links cannot provide.
- REJECTED: long-lived 7-day JWT — discarded: no server-side revocation path.
"@ | Set-Content -LiteralPath $planAbs -Encoding UTF8

# --- The handoff: a COMPRESSED pointer. Must NOT contain the rejected-option detail
#     (no "magic", no "fixation", no sentinel) — only a tagged link to the plan. ------------
@"
# Session Handoff: Auth Flow (seq 01)

**Date:** $today  **Branch:** main  **Previous:** —

## What this is about / where it started
Designing the authentication flow for the app. The token strategy is decided; the next
work is refresh-token rotation.

## Decisions & what shipped (this session, additive)
- Chose short-lived access JWT + rotating refresh token. Full roadmap, rationale and the
  rejected alternatives live in the plan (linked below) — not duplicated here.

## Key files (absolute paths) — read these first
- ``$planAbs`` [READ-AT-RESUME] — full roadmap + grilled decisions, incl. rejected options.

## Running state
- Background processes: none
- Dev servers / ports: none
- Worktrees / branches: none

## Verification — how to confirm things still work
- (none yet) — implementation not started.

## Suggested skills for the next session
- none

## Deferred & open questions
- Open: cookie SameSite policy for the refresh token — decide during Step 2.

## Reference (do NOT duplicate — link by path/URL; tag substantial targets)
- Plan: ``$planAbs`` [READ-AT-RESUME]

## -> Pick up here
Implement refresh-token rotation (plan Step 2).

---
Resume: ``/session-resume auth-flow``  —  or read $handAbs
"@ | Set-Content -LiteralPath $handAbs -Encoding UTF8

'node_modules/' | Set-Content -LiteralPath (Join-Path $Proj '.gitignore') -Encoding UTF8

# Real git repo so resume's branch/staleness git calls work.
git -C $Proj init -q
git -C $Proj config user.email 'test@example.com'
git -C $Proj config user.name  'Sandbox Test'
git -C $Proj add -A
git -C $Proj commit -q -m 'init depth-recovery sandbox'

# Read-only proof: snapshot hashes of the files resume must NOT modify.
$manifest = @(
    @{ Path = $handAbs; Hash = (Get-FileHash -LiteralPath $handAbs -Algorithm SHA256).Hash },
    @{ Path = $planAbs; Hash = (Get-FileHash -LiteralPath $planAbs -Algorithm SHA256).Hash }
)
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Out 'pre-hashes.json') -Encoding UTF8

Write-Host "SANDBOX_PROJ=$Proj"
Write-Host "SANDBOX_OUT=$Out"
Write-Host "Branch=$(git -C $Proj rev-parse --abbrev-ref HEAD)"
