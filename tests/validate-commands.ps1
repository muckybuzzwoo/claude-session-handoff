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
    '## Open work',
    '## Reference',
    'Pick up here')) {
    Check "template has section: $s" ($h.Contains($s))
}

# =============================================================================
Section 'R. Handoff — Open work section + carry rule (v0.4.0, 1B)'

# --- the template's labels ---
foreach ($lbl in @('- Open:', '- Deferred:', '- Question:', '- Done:',
                   '- Unresolved carry:', '- Carried unchanged:')) {
    Check "Open-work template has label: $lbl" ($h.Contains($lbl))
}
# Both found by the 2026-08-21 behavioural run, which is the only thing that surfaced them.
Check 'the next action must ALSO exist as a countable item' (
    $h.Contains('ONLY in "→ Pick up here" is invisible'))
Check 'spotlight-not-container wording is present' ($h.Contains('spotlight, not a container'))
Check 'an unnumbered carry gets its own labelled bullet' ($h.Contains('count unknown, see'))
Check 'loose prose is explicitly not an item' ($h.Contains('prose under the list is not an item'))
Check 'old section name is gone from the template' (-not ($h -match '(?m)^## Deferred & open questions'))

# --- both places that name the sections agree ---
$step3 = ($h -split "`n") | Where-Object { $_ -match 'Running state, Verification, Suggested skills' } |
         Select-Object -First 1
Check 'Step 3 section list names Open work'            ($step3 -and $step3.Contains('Open work'))
Check 'Step 3 section list no longer names the old one' ($step3 -and -not $step3.Contains('Deferred & open questions'))

# --- backward compatibility, the whole point of 1B not breaking anything ---
Check 'Step 3 accepts the OLD heading too'  ($h.Contains('## Deferred & open questions') -and $h.Contains('Accept either'))
Check 'says every pre-existing chain uses the old heading' ($h.Contains('before this format'))

# --- the carry rule ---
Check 'one item per bullet'                       ($h.Contains('one item') -and $h.Contains('per bullet'))
Check 'carry line: only the immediately previous file' ($h.Contains('immediately previous'))
Check 'carry line: never two such lines'          ($h.Contains('never two such lines'))
Check 'N must add up'                             ($h.Contains('must add up'))
Check 'never adjust the number to fit'            ($h.Contains('never adjust the number'))
Check 'closing is explicit, via a Done bullet'    ($h.Contains('Closing is explicit'))
Check 'an item may never leave by being omitted'  ($h.Contains('never leave by being omitted'))
Check 'Open work must not restate the next action' ($h.Contains('must not restate the next action'))

# --- the counting grammar ---
Check 'splits only on the middot separator'       ($h.Contains('space, middot'))
Check 'never splits on commas or and'             ($h.Contains('never on commas'))
Check 'bullet ending in a colon is a group header' ($h.Contains('group header'))
Check 'wrapped bullets are joined before counting'  ($h.Contains('A bullet wraps'))
Check 'numbered children count like bullet children' ($h.Contains('numbered `1.` `2.` list'))
Check 'label is re-attached to every split item'  ($h.Contains('re-attach'))
Check 'boundary count is established, not inherited' ($h.Contains('established, not inherited'))
Check 'numberless prose pointer stays one item'   ($h.Contains('carrying no number'))
Check 'never invent a count'                      ($h.Contains('Never invent a count'))

# --- Step 1 says where the TodoWrite items go ---
Check 'Step 1 routes TodoWrite items to Open work' (
    $h -match "(?s)Open TodoWrite items.{0,160}Open work")

# --- 1E: the Format header field ---
Check 'template header has a Format field'   ($h.Contains('**Format:** 2'))
Check 'absent Format means format 1'         ($h.Contains('format 1 (everything written before'))
Check 'no old file is ever rewritten'        ($h.Contains('no old file is ever rewritten'))

# --- resume resolves the carry line, one hop only ---
Check 'resume resolves the carry line'       ($r.Contains('Carried unchanged'))
Check 'resume resolves exactly ONE hop'      ($r.Contains('ONE hop'))
Check 'resume does not walk further'         ($r.Contains('do **not**') -and $r.Contains('walk further'))
Check 'resume reports how many it resolved'  ($r.Contains('items you resolved'))
Check 'resume tolerates old files with no carry line' ($r.Contains('Old handoffs have no carry line'))

# --- five clarifications the G1 gate run surfaced (2026-08-21) ---
Check 'an explicit tag outranks the outside-project skip' ($r.Contains('outranks this skip'))
Check 'never substitutes a size the prose claims'         ($r.Contains('Never substitute a size'))
Check 'a prose Tree field skips the comparison'           ($r.Contains('written as prose'))
Check 'an unknown extra section is carried, not dropped'  ($r.Contains('does not know is not noise'))
Check 'memory reconcile only for the same project'        ($r.Contains('belongs to THIS project'))

# =============================================================================
Section 'H. Handoff — gitignore + Windows safety invariants'
Check 'ignores .claude/session-handoffs/'        ($h.Contains('.claude/session-handoffs/'))
Check 'warns: never ignore all of .claude/'      ($h.Contains('never all of'))
Check 'Windows rule: chained Bash may be blocked, batch via PowerShell or split' (
    $h.Contains('block chained Bash calls') -and $h.Contains('PowerShell'))

# =============================================================================
Section 'T. Handoff — forward-looking block first (v0.4.0, 1A)'

Check 'template has ## Status'                 ($h.Contains('## Status'))
Check 'Status has the Where it stands bullet'  ($h.Contains('**Where it stands:**'))
Check 'Status has the This session bullet'     ($h.Contains('**This session:**'))
Check 'Status has NO Next: line'               (-not ($h -match '(?m)^\s*-\s+\*\*Next:\*\*'))

# Order assertions. Index comparison, not Contains — the whole point of 1A is position.
# Scoped to the template block: the step texts mention `## Open work` in prose earlier in
# the file, and an unscoped IndexOf would compare the wrong occurrences.
$tplAt = $h.IndexOf('## Document template')
Check 'document template block found' ($tplAt -ge 0)
$tpl = if ($tplAt -ge 0) { $h.Substring($tplAt) } else { '' }

$iStatus = $tpl.IndexOf('## Status')
$iPick   = $tpl.IndexOf('## → Pick up here')
$iOpen   = $tpl.IndexOf('## Open work')
$iAbout  = $tpl.IndexOf('## What this is about')
$iDec    = $tpl.IndexOf('## Decisions & what shipped')
$iRef    = $tpl.IndexOf('## Reference')

Check 'all six template anchors found' (@($iStatus,$iPick,$iOpen,$iAbout,$iDec,$iRef) -notcontains -1)
Check 'Status comes before Pick up here'          ($iStatus -lt $iPick)
Check 'Pick up here comes before Open work'       ($iPick   -lt $iOpen)
Check 'Open work comes before What this is about' ($iOpen   -lt $iAbout)
Check 'Status comes before Decisions'             ($iStatus -lt $iDec)
Check 'Reference stays last of the sections'      ($iRef    -gt $iDec)
Check 'Pick up here appears exactly once' (
    ([regex]::Matches($h, [regex]::Escape('## → Pick up here'))).Count -eq 1)

# --- resume briefing order, without weakening completeness ---
Check 'resume opens with exactly three things'   ($r.Contains('exactly three things, in this order'))
Check 'resume puts open work after those three'  ($r.Contains('Then'))
Check 'resume defers the depth'                  ($r.Contains('Only after that'))
Check 'resume KEEPS the do-not-compress rule'    ($r.Contains('do not compress those away'))
Check 'resume says it is order, not content'     ($r.Contains('about *order*'))

# =============================================================================
Section 'S. Carry-invariant guard actually fires (fixture chains)'
# The rest of this suite proves the INSTRUCTION text is present. This section proves the
# safety net around it works: compat-old-chain.ps1 must accept a correct chain and reject a
# chain where items left without being closed. A guard that has never caught anything is
# not a guard.
$scanner    = Join-Path $PSScriptRoot 'compat-old-chain.ps1'
$fixtureOk  = Join-Path $PSScriptRoot 'fixtures/carry-ok'
$fixtureBad = Join-Path $PSScriptRoot 'fixtures/carry-bad'

Check 'scanner exists'            (Test-Path $scanner)
Check 'passing fixture exists'    (Test-Path (Join-Path $fixtureOk  'demo_03.md'))
Check 'failing fixture exists'    (Test-Path (Join-Path $fixtureBad 'demo_02.md'))

$null = & pwsh -NoProfile -File $scanner -Path $fixtureOk *>&1
$okExit = $LASTEXITCODE
Check 'correct chain passes (exit 0)' ($okExit -eq 0)

$badOut  = & pwsh -NoProfile -File $scanner -Path $fixtureBad *>&1
$badExit = $LASTEXITCODE
Check 'chain with dropped items FAILS (exit 1)' ($badExit -eq 1)
Check 'and it names how many items were lost'   (($badOut | Out-String) -match 'item\(s\) left')

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
Section 'P. Token-optimization rebuild (addendum 8d: byte size, redundancy, section anchors, archive-split)'
# Handoff — link-classification ladder + byte-size trigger
Check 'Handoff measures size in bytes, not lines'            ($h.Contains('bytes/4'))
Check 'Handoff (a) redundancy check (essence already inlined -> no tag)' ($h.Contains('Redundancy'))
Check 'Handoff (b) section-anchor tag [READ-AT-RESUME: <heading>]' ($h.Contains('[READ-AT-RESUME: <'))
Check 'Handoff has essence must-contain checklist'          ($h.Contains('must-contain'))
# Handoff — Step 7d archive-split (propose-only, opt-in) + invariants
Check 'Handoff Step 7d = archive-split (propose-only)'       ($h.Contains('**7d'))
Check 'Split invariant: nothing deleted, sections move verbatim' ($h.Contains('move verbatim'))
Check 'Split invariant: open items NEVER archived'          ($h.Contains('NEVER archived'))
Check 'Split invariant: own commit, revertible'             ($h.Contains('own commit'))
Check 'Confirm block has Split proposed: line'              ($h.Contains('Split proposed:'))
# Resume — targeted load + big-file safeguard + backward-compat
Check 'Resume resolves section-anchor tags'                 ($r.Contains('[READ-AT-RESUME: <'))
Check 'Resume measures target size in bytes'                ($r.Contains('bytes/4'))
Check 'Resume big-file safeguard (no blind full-load)'      ($r.Contains('swallow the whole file'))
Check 'Resume reads old bare-tag format (backward-compat)'  ($r.Contains('old handoff format'))
Check 'Resume no longer blind-loads untagged plan-like files' ($r.Contains('do not full-load them'))

# =============================================================================
Section 'Q. Addendum 8e (real-test process findings: after-handoff reminder, cross-chain pointer, memory reconcile)'
# 1 — after-handoff activity is invisible: fixed reminder in the confirm block
Check 'Handoff confirm block warns work-after-handoff is invisible' ($h.Contains('invisible to the next resume'))
Check 'Handoff states the reminder is fixed (always printed)'       ($h.Contains('closing `Note:` is **fixed**'))
# 2 — cross-chain pointer (handoff writes it, resume surfaces it, neither loads the foreign project)
Check 'Handoff template has Continue first in: pointer field'       ($h.Contains('Continue first in:'))
Check 'Handoff hard-rule defines the cross-chain pointer'           ($h.Contains('Cross-chain pointer') -and $h.Contains('pointer only'))
Check 'Resume surfaces the Continue first in: pointer'              ($r.Contains('Continue first in:'))
Check 'Resume prints the pointer only, never loads the other repo'  ($r.Contains('never open or load'))
# 3 — memory-index reconciliation on resume (no extra load; names both, resolves nothing silently)
Check 'Resume reconciles briefing against the memory index'         ($r.Contains('Reconcile against the memory index'))
Check 'Resume names BOTH states, does not silently pick one'        ($r.Contains('name BOTH states') -and $r.Contains('Do not silently pick one'))

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
