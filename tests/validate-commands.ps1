#requires -Version 5
<#
.SYNOPSIS
  Static validation harness for the session-handoff / session-resume slash-commands.

.DESCRIPTION
  These commands are PROMPT files (Markdown), not executable code. This script cannot
  prove runtime behaviour (it would need an LLM in the loop). What it CAN prove,
  deterministically, are the structural invariants of the command files plus
  source==deployed parity. Behavioural checks are listed at the end as NOT COVERED.

  Exit code 0 = all static checks passed, 1 = at least one failed.

.EXAMPLE
  pwsh -File .\tests\validate-commands.ps1
#>

$ErrorActionPreference = 'Stop'

# --- Paths (portable: derived from this script's location) -------------------
$RepoRoot    = Split-Path $PSScriptRoot -Parent
$SrcDir      = Join-Path $RepoRoot 'commands'
$LiveDir     = Join-Path $HOME '.claude/commands'

$Handoff     = Join-Path $SrcDir  'session-handoff.md'
$Resume      = Join-Path $SrcDir  'session-resume.md'
$HandoffLive = Join-Path $LiveDir 'session-handoff.md'
$ResumeLive  = Join-Path $LiveDir 'session-resume.md'

# --- Tiny assertion harness --------------------------------------------------
$script:pass   = 0
$script:fail   = 0
$script:failed = @()
$script:group  = ''

function Section([string]$name) {
    Write-Host ''
    Write-Host "== $name ==" -ForegroundColor Cyan
    $script:group = $name
}

function Check([string]$name, [bool]$cond) {
    if ($cond) {
        $script:pass++
        Write-Host "  [PASS] $name" -ForegroundColor Green
    } else {
        $script:fail++
        $script:failed += "$($script:group) :: $name"
        Write-Host "  [FAIL] $name" -ForegroundColor Red
    }
}

function Load([string]$path) {
    if (Test-Path -LiteralPath $path) { Get-Content -LiteralPath $path -Raw } else { '' }
}

function Get-StepNumbers([string]$text) {
    # Matches headers like:  ### Step 7 — Closing reflection ...
    [regex]::Matches($text, '(?m)^### Step (\d+) ') | ForEach-Object { [int]$_.Groups[1].Value }
}

Write-Host "Session-handoff command — static validation harness"
Write-Host "Repo:   $RepoRoot"
Write-Host "Source: $SrcDir"
Write-Host "Live:   $LiveDir"

# =============================================================================
Section 'A. Files exist'
Check 'source session-handoff.md exists'  (Test-Path -LiteralPath $Handoff)
Check 'source session-resume.md exists'   (Test-Path -LiteralPath $Resume)
Check 'deployed session-handoff.md exists' (Test-Path -LiteralPath $HandoffLive)
Check 'deployed session-resume.md exists'  (Test-Path -LiteralPath $ResumeLive)

$h  = Load $Handoff
$r  = Load $Resume
$hL = Load $HandoffLive
$rL = Load $ResumeLive

# =============================================================================
Section 'B. Deploy parity (source == ~/.claude/commands, no drift)'
Check 'session-handoff: source content == deployed' ($h -ne '' -and $h -eq $hL)
Check 'session-resume:  source content == deployed' ($r -ne '' -and $r -eq $rL)

# =============================================================================
Section 'C. Handoff — frontmatter'
Check 'has description:'        ($h -match '(?m)^description:\s+\S')
Check 'argument-hint = [topic-slug] [--done]' ($h.Contains('[topic-slug] [--done]'))
foreach ($t in 'Bash','PowerShell','Read','Write','Edit','Glob','AskUserQuestion') {
    Check "allowed-tools lists $t" ($h.Contains("- $t"))
}

# =============================================================================
Section 'D. Handoff — step structure (1..9 contiguous, no gaps/dupes)'
$hSteps = @(Get-StepNumbers $h)
Check 'exactly 9 step headers'              ($hSteps.Count -eq 9)
Check 'steps unique + contiguous 1..9'      ((($hSteps | Sort-Object -Unique) -join ',') -eq ((1..9) -join ','))
Check 'no Step 10'                          (-not ($h -match '(?m)^### Step 10 '))
Check 'Step 7 = Closing reflection'         ($h -match '(?m)^### Step 7 — Closing reflection')
Check 'Step 7 has sub-section 7a (memory)'  ($h.Contains('**7a'))
Check 'Step 7 has sub-section 7b (plan)'    ($h.Contains('**7b'))
Check 'Step 7 has sub-section 7c (docs)'    ($h.Contains('**7c'))
Check 'Step 8 = --done handling'            ($h -match '(?m)^### Step 8 —.*done')
Check 'Step 9 = Confirm + STOP'             ($h -match '(?m)^### Step 9 — Confirm')

# =============================================================================
Section 'E. Handoff — renumbering consistency (the brittle cross-references)'
Check 'HARD STOP carves out the Step 7 reflection' ($h.Contains('closing reflection in Step 7'))
Check '--done final handoff references Steps 1-7'   ($h -match '\(Steps 1.7\)')
Check 'Customizing store-path refs = Steps 2,5,6,8' ($h.Contains('Steps 2, 5, 6, 8'))
Check 'confirm block has Memory: line'              ($h.Contains('Memory:'))
Check 'confirm block has Plan updated: line'        ($h.Contains('Plan updated:'))
Check 'confirm block has Docs updated: line'        ($h.Contains('Docs updated:'))

# =============================================================================
Section 'F. Handoff — superpowers awareness (link, never copy)'
Check 'mentions docs/superpowers/specs/' ($h.Contains('docs/superpowers/specs/'))
Check 'mentions docs/superpowers/plans/' ($h.Contains('docs/superpowers/plans/'))
$refLine = ($h -split "`n") | Where-Object { $_ -match '^- Plan:' } | Select-Object -First 1
Check 'Reference template line cites both superpowers paths' (
    $refLine -and $refLine.Contains('docs/superpowers/plans/') -and $refLine.Contains('docs/superpowers/specs/'))

# =============================================================================
Section 'G. Handoff — document template completeness'
foreach ($s in @(
    'What this is about',
    'Decisions & what shipped',
    'Key files',
    'Running state',
    'Verification',
    'Suggested skills',
    'Deferred & open questions',
    '## Reference',
    'Pick up here')) {
    Check "template has section: $s" ($h.Contains($s))
}

# =============================================================================
Section 'H. Handoff — gitignore + Windows safety invariants'
Check 'ignores .claude/session-handoffs/'        ($h.Contains('.claude/session-handoffs/'))
Check 'warns: never ignore all of .claude/'      ($h.Contains('never all of'))
Check 'Windows rule: chained Bash may be blocked, batch via PowerShell or split' (
    $h.Contains('block chained Bash calls') -and $h.Contains('PowerShell'))

# =============================================================================
Section 'I. Resume — frontmatter + read-only posture'
Check 'has description:'        ($r -match '(?m)^description:\s+\S')
Check 'argument-hint = [topic-slug] [--all]' ($r.Contains('[topic-slug] [--all]'))
foreach ($t in 'Bash','PowerShell','Read','Glob','AskUserQuestion') {
    Check "allowed-tools lists $t" ($r.Contains("- $t"))
}
Check 'read-only: does NOT grant Write' (-not $r.Contains('- Write'))
Check 'read-only: does NOT grant Edit'  (-not $r.Contains('- Edit'))

# =============================================================================
Section 'J. Resume — workflow structure + behaviour anchors'
$rSteps = @(Get-StepNumbers $r)
Check 'exactly 5 step headers'             ($rSteps.Count -eq 5)
Check 'steps unique + contiguous 1..5'     ((($rSteps | Sort-Object -Unique) -join ',') -eq ((1..5) -join ','))
Check '--all includes done/ archive'       ($r.Contains('done/'))
Check 'staleness threshold = 7 days'       ($r.Contains('7 days'))
Check 'never modifies/deletes handoffs'    ($r.Contains('never modify or delete'))

# =============================================================================
Section 'K. Deep-link recovery (READ-AT-RESUME contract — the depth-loss fix)'
# Handoff side: substantial targets must be tagged, and the tag must be defined.
Check 'Reference line tags substantial targets with [READ-AT-RESUME]' (
    $refLine -and $refLine.Contains('[READ-AT-RESUME]'))
Check 'Hard-rule defines the [READ-AT-RESUME] tag' ($h.Contains('`[READ-AT-RESUME]` tag:'))
# Resume side: Step 4 must dereference those links, not just the handoff text.
Check 'Resume keys off the [READ-AT-RESUME] tag'            ($r.Contains('[READ-AT-RESUME]'))
Check 'Resume also reads untagged plan/spec/roadmap links'  ($r.Contains('plan, spec, roadmap, or decision'))
Check 'Resume preserves rejected options / no-decisions'    ($r.Contains('rejected options'))
Check 'Resume has error-handling for missing linked file'   ($r.Contains('link missing/unreadable'))

# =============================================================================
Section 'L. Resume — no-handoff fallback (memory + git orientation, Decision 15 refinement)'
Check 'documents the no-handoff fallback'           ($r.Contains('Fallback — no-handoff orientation'))
Check 'fallback does not re-read the memory index'  ($r.Contains('do **not** re-read'))
Check 'fallback checks git log for recent activity' ($r.Contains('git log --oneline -10'))
Check 'fallback points back to /session-handoff'    ($r.Contains('going forward so the next'))

# =============================================================================
Section 'M. Platform-conditional chaining (verified: not Windows-specific at the permission-engine level)'
Check 'Handoff Step 1 is platform-aware (win32 vs macOS/Linux)' (
    $h.Contains('win32') -and $h.Contains('Other platforms (macOS/Linux)'))
Check 'Resume Safety/Windows is platform-aware (win32 vs macOS/Linux)' (
    $r.Contains('win32') -and $r.Contains('Other platforms (macOS/Linux)'))

# =============================================================================
Section 'N. Step 7a — feedback-learning capture + CLAUDE.md hand-off (never edits CLAUDE.md directly)'
Check 'Step 7a scans for feedback-type learnings'      ($h.Contains('feedback-type learning'))
Check 'Step 7a suggests /revise-claude-md for rules'   ($h.Contains('/revise-claude-md'))
Check 'Step 7a never edits CLAUDE.md directly'         ($h.Contains('Never edit CLAUDE.md directly'))
Check 'Confirm block has CLAUDE.md: line'              ($h.Contains('CLAUDE.md:'))

# =============================================================================
Section 'O. 2026-07-03 review fixes (invocation policy, tree snapshot, archive guard)'
# Invocation policy: explicit request only; suggest ok, never run unasked.
Check 'Handoff description: never run unasked'       ($h.Contains('never run it unasked'))
Check 'Handoff body states the invocation policy'    ($h.Contains('Invocation policy'))
Check 'Resume description: never proactively'        ($r.Contains('never proactively'))
# Tree snapshot: handoff records it, resume compares against it (not "dirty now").
Check 'Handoff template header has Tree: field'      ($h.Contains('**Tree:**'))
Check 'Handoff Step 1 keeps porcelain for Tree:'     ($h.Contains('fills') -and $h.Contains('`Tree:` header field'))
Check 'Resume staleness compares the Tree: snapshot' ($r.Contains('`Tree:` snapshot'))
Check 'Resume skips tree check on older handoffs'    ($r.Contains('older') -and $r.Contains('skip this check'))
# Compaction-uncertainty cross-check in Step 1.
Check 'Handoff Step 1 has compaction cross-check'    ($h.Contains('compacted'))
# Archived-chain fork guard (handoff Step 2 + resume picker marking).
Check 'Handoff Step 2 guards archived chains (un-archive vs fresh)' ($h.Contains('un-archive'))
Check 'Resume picker marks archived topics'          ($r.Contains('(archived)'))

# =============================================================================
Write-Host ''
Write-Host "================ RESULT ================" -ForegroundColor Cyan
Write-Host ("Passed: {0}   Failed: {1}   Total: {2}" -f $script:pass, $script:fail, ($script:pass + $script:fail))
if ($script:fail -gt 0) {
    Write-Host ''
    Write-Host "Failed checks:" -ForegroundColor Red
    $script:failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

Write-Host ''
Write-Host "NOT COVERED here (behavioural — verify manually, see README -> Testing):" -ForegroundColor Yellow
@(
    'Does the handoff actually SHOW a memory candidate and wait for approval before writing? (Step 7a)',
    'Does it propose a concrete plan diff and write only on confirm? (Step 7b)',
    'Does it propose a concrete doc-drift edit and write only on confirm? (Step 7c)',
    'Carry-forward across _01 -> _02 with correct Previous: link (Step 3)',
    'Staleness note fires correctly at runtime (>7d / branch change) (resume Step 3)',
    '--done archives the chain to done/ and resume hides it without --all',
    'Secret-pattern warning triggers before writing (Step 4)',
    'Does resume ACTUALLY open the [READ-AT-RESUME]/plan/spec links and fold their depth in? (Section K asserts the instruction exists, not that the LLM follows it) (resume Step 4)'
) | ForEach-Object { Write-Host "  * $_" -ForegroundColor Yellow }

Write-Host ''
if ($script:fail -gt 0) { exit 1 } else { Write-Host "All static checks passed." -ForegroundColor Green; exit 0 }
