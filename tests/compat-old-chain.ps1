#requires -Version 5
<#
.SYNOPSIS
  Compatibility scanner for an existing session-handoff chain.

.DESCRIPTION
  Answers one question deterministically, with no LLM in the loop: does a real handoff
  chain still add up? It is meant to be run BEFORE a format change to record a baseline,
  and again AFTER, so "nothing was lost" is a comparison instead of a hope.

  What it reports per chain:
    * which Open-work heading each file uses (old 'Deferred & open questions' / new
      'Open work' / none) — a format census, not a judgement
    * open items counted with the v0.4.0 grammar (plan section 9): top-level '- ' bullets,
      split only on the middot separator, nested bullets never counted on their own
    * bullets that hide several items behind a middot, and how many separators they hold
    * files whose carry pointer is prose without a number, which is the one case where the
      v0.4.0 count invariant has nothing to start from

  What it CHECKS (and can fail on), for new-format files only:
    * the V4 count invariant: N_carry(NN) = full_items(NN-1) + N_carry(NN-1) - closed_in(NN)

  An all-old-format chain has nothing to check, so it reports the baseline and exits 0.

  Exit code 0 = no invariant violated, 1 = at least one violated.

.PARAMETER Path
  The session-handoffs directory to scan, e.g.
  C:\Users\me\projects\some-project\.claude\session-handoffs

.PARAMETER Detail
  Also print one line per file instead of totals only.

.EXAMPLE
  pwsh -File .\tests\compat-old-chain.ps1 -Path 'C:\path\to\project\.claude\session-handoffs'

.EXAMPLE
  pwsh -File .\tests\compat-old-chain.ps1 -Path .\.claude\session-handoffs -Detail
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [switch]$Detail
)

$ErrorActionPreference = 'Stop'

# The middot separator, built from its code point so no file encoding can break it.
$Sep = ' ' + [char]0x00B7 + ' '

# --- Tiny assertion harness (same shape as validate-commands.ps1) ------------
$script:pass   = 0
$script:fail   = 0
$script:failed = @()

function Section([string]$name) {
    Write-Host ''
    Write-Host "== $name ==" -ForegroundColor Cyan
}

function Check([string]$name, [bool]$cond) {
    if ($cond) {
        $script:pass++
        Write-Host "  [PASS] $name" -ForegroundColor Green
    } else {
        $script:fail++
        $script:failed += $name
        Write-Host "  [FAIL] $name" -ForegroundColor Red
    }
}

# --- Input ------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $Path)) {
    Write-Host "Not found: $Path" -ForegroundColor Red
    Write-Host "Pass the session-handoffs directory of the project you want to scan." -ForegroundColor Yellow
    exit 1
}

$files = Get-ChildItem -LiteralPath $Path -Filter '*_*.md' -File |
         Where-Object { $_.BaseName -match '_(\d+)$' } |
         Sort-Object { [int]([regex]::Match($_.BaseName, '_(\d+)$').Groups[1].Value) }

if ($files.Count -eq 0) {
    Write-Host "No handoff files (name_NN.md) in: $Path" -ForegroundColor Yellow
    exit 0
}

# --- Per-file analysis ------------------------------------------------------
function Get-OpenWorkSection([string[]]$lines) {
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^##\s+(Deferred|Open work)') { $start = $i; break }
    }
    if ($start -lt 0) { return $null }
    $out = @()
    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^##\s') { break }
        $out += $lines[$i]
    }
    return $out
}

$rows = @()

foreach ($f in $files) {
    $lines = Get-Content -LiteralPath $f.FullName -Encoding UTF8
    $seq   = [int]([regex]::Match($f.BaseName, '_(\d+)$').Groups[1].Value)

    $heading = 'none'
    if ($lines | Where-Object { $_ -match '^##\s+Deferred & open questions' }) { $heading = 'old' }
    elseif ($lines | Where-Object { $_ -match '^##\s+Open work' })             { $heading = 'new' }

    $sec = Get-OpenWorkSection $lines
    if ($null -eq $sec) { $sec = @() }

    # Build LOGICAL bullets. A real bullet often wraps over several lines, and counting
    # line by line loses every separator on a continuation line — in one real file that was
    # 30+ items hidden in a single wrapped bullet. So: join continuation lines into their
    # bullet, and count nested children (either "- " or "1." style) separately.
    #
    # A nested child normally belongs to its parent item — EXCEPT under a group header
    # (a bullet whose text ends in a colon), where the children ARE the items and the
    # header line is only a label.
    $units = @()
    $u = $null
    $seenKid = $false
    foreach ($ln in $sec) {
        if ($ln -match '^- ') {
            if ($null -ne $u) { $units += $u }
            $u = [pscustomobject]@{ Text = $ln; Kids = 0 }
            $seenKid = $false
        }
        elseif ($ln -match '^\s+(-|\d+\.)\s') {
            if ($null -ne $u) { $u.Kids++ }
            $seenKid = $true
        }
        elseif ($ln.Trim() -ne '') {
            # Continuation text. Once children have started it belongs to a child, not to
            # the parent, so it must not add separators to the parent's text.
            if ($null -ne $u -and -not $seenKid) { $u.Text = $u.Text + ' ' + $ln.Trim() }
        }
    }
    if ($null -ne $u) { $units += $u }

    $nested = [int](($units | Measure-Object Kids -Sum).Sum)

    $headerUnits = @($units | Where-Object { $_.Kids -gt 0 -and $_.Text.TrimEnd() -match ':(\*{0,2})$' })
    $headerChildren = 0
    if ($headerUnits.Count -gt 0) { $headerChildren = [int](($headerUnits | Measure-Object Kids -Sum).Sum) }

    # Not open items: the carry line, group headers (labels), and Done: bullets (closed by
    # definition — counting them would inflate the total the NEXT file has to carry).
    $carryLine  = @($units | Where-Object { $_.Text -match 'Carried unchanged:' })
    $doneBullet = @($units | Where-Object { $_.Text -match '(?i)^\-\s+\*{0,2}Done:' })
    $realBullet = @($units | Where-Object {
        $_.Text -notmatch 'Carried unchanged:' -and
        $_.Text -notmatch '(?i)^\-\s+\*{0,2}Done:' -and
        $headerUnits -notcontains $_
    })

    $bullets = $units

    $carryN = $null
    if ($carryLine.Count -gt 0) {
        $m = [regex]::Match($carryLine[0].Text, 'Carried unchanged:\s*(\d+)')
        if ($m.Success) { $carryN = [int]$m.Groups[1].Value }
    }

    $dotBullets = @($realBullet | Where-Object { $_.Text.Contains($Sep) })
    $dots = 0
    foreach ($b in $dotBullets) {
        $dots += ([regex]::Matches($b.Text, [regex]::Escape($Sep))).Count
    }

    # Items under the v0.4.0 grammar: each bullet counts once, plus one per separator,
    # plus the children of every group header (whose own line is only a label).
    $items = $realBullet.Count + $dots + $headerChildren

    $doneCount = $doneBullet.Count

    # Carry-style bullets: they reference a previous handoff by sequence and assert that its
    # items still apply. Three classes, and only the last one is a problem:
    #   * CLOSED record   -> points at items that are DONE. The opposite. Never a carry.
    #   * enumerating     -> the bullet lists its items (middot separators or #refs), so the
    #                        count is readable from the bullet itself.
    #   * unresolvable    -> "everything from _NN still applies", listing nothing. This is the
    #                        one case where the v0.4.0 count has nothing to start from.
    $carryStyle   = 0
    $enumerating  = 0
    $unresolvable = 0
    foreach ($b in $realBullet) {
        $t = $b.Text
        $isCarry = ($t -match '(?i)(unver.ndert|unchanged|gilt weiter|gelten weiter|list stands|alles aus|weiter offen)') `
                   -and ($t -match '_\d+')
        if (-not $isCarry) { continue }
        if ($t -match '(?i)(CLOSED|abgeschlossen|nicht wieder aufmachen)') { continue }
        $carryStyle++
        if ($t.Contains($Sep) -or $t -match '#\d+') { $enumerating++ } else { $unresolvable++ }
    }
    $prosePointer = ($unresolvable -gt 0)

    $rows += [pscustomobject]@{
        Seq          = $seq
        Slug         = ($f.BaseName -replace '_\d+$', '')
        Name         = $f.Name
        Heading      = $heading
        Items        = $items
        Bullets      = $realBullet.Count
        DotBullets   = $dotBullets.Count
        Dots         = $dots
        Nested       = $nested
        CarryN       = $carryN
        Done         = $doneCount
        CarryStyle   = $carryStyle
        Enumerating  = $enumerating
        Unresolvable = $unresolvable
        ProsePointer = $prosePointer
        Headers      = $headerUnits.Count
        HeaderKids   = $headerChildren
    }
}

# --- Report -----------------------------------------------------------------
Write-Host ''
Write-Host "Chain: $Path" -ForegroundColor Cyan
$topics = @($files | ForEach-Object { $_.BaseName -replace '_\d+$', '' } | Sort-Object -Unique)
if ($topics.Count -eq 1) {
    Write-Host "Files: $($rows.Count)  (seq $($rows[0].Seq) .. $($rows[-1].Seq))"
} else {
    Write-Host "Files: $($rows.Count)  across $($topics.Count) topics — sequences are per topic, so no single range"
}

$old = @($rows | Where-Object { $_.Heading -eq 'old' }).Count
$new = @($rows | Where-Object { $_.Heading -eq 'new' }).Count
$non = @($rows | Where-Object { $_.Heading -eq 'none' }).Count

Section 'Format census'
Write-Host "  old heading 'Deferred & open questions' : $old"
Write-Host "  new heading 'Open work'                 : $new"
Write-Host "  no Open-work heading at all             : $non"

$totItems = ($rows | Measure-Object Items -Sum).Sum
$totBull  = ($rows | Measure-Object Bullets -Sum).Sum
$totDotB  = ($rows | Measure-Object DotBullets -Sum).Sum
$totDots  = ($rows | Measure-Object Dots -Sum).Sum
$totNest  = ($rows | Measure-Object Nested -Sum).Sum

Section 'Open work, counted with the v0.4.0 grammar'
Write-Host "  top-level bullets (carry line excluded) : $totBull"
Write-Host "  bullets hiding several items behind '$([char]0x00B7)' : $totDotB"
Write-Host "  middot separators inside them           : $totDots"
Write-Host "  nested bullets found                    : $totNest"
Write-Host "  group headers (bullet ending in ':')    : $(($rows | Measure-Object Headers -Sum).Sum)"
Write-Host "  items hanging under those headers       : $(($rows | Measure-Object HeaderKids -Sum).Sum)"
Write-Host "  ITEMS TOTAL                             : $totItems" -ForegroundColor White

$totCarry = ($rows | Measure-Object CarryStyle -Sum).Sum
$totEnum  = ($rows | Measure-Object Enumerating -Sum).Sum
$totUnres = ($rows | Measure-Object Unresolvable -Sum).Sum
$prose    = @($rows | Where-Object { $_.ProsePointer })

Section 'Carry-style bullets (reference a previous _NN and assert it still applies)'
Write-Host "  carry-style bullets, CLOSED records excluded : $totCarry"
Write-Host "  of those, enumerating their items            : $totEnum  (readable from the bullet)"
Write-Host "  of those, listing nothing                    : $totUnres" -ForegroundColor Yellow
if ($prose.Count -eq 0) {
    Write-Host "  files affected                              : none"
} else {
    Write-Host "  files affected ($($prose.Count)) — the count is established here, never inherited:" -ForegroundColor Yellow
    Write-Host "  $(($prose | ForEach-Object { '_' + $_.Seq }) -join ' ')"
}

if ($Detail) {
    Section 'Per file'
    $rows | Format-Table Seq, Heading, Items, Bullets, DotBullets, Dots, CarryN, Done, ProsePointer -AutoSize |
        Out-String -Width 200 | Write-Host
}

# --- Invariant checks (new-format files only) -------------------------------
Section 'V4 count invariant (new-format files only)'

# Compare WITHIN a topic chain, never across. A store can hold several topics, and their
# sequence numbers run in parallel — comparing a global sort would pit _02 of one topic
# against _02 of another. That produced a meaningless (and silently passing) check until
# 2026-08-21, when running this against a multi-topic store exposed it.
$checked = 0
$pairs = @()
foreach ($g in ($rows | Group-Object Slug)) {
    $chain = @($g.Group | Sort-Object Seq)
    for ($i = 1; $i -lt $chain.Count; $i++) {
        $pairs += [pscustomobject]@{ Cur = $chain[$i]; Prev = $chain[$i - 1] }
    }
}

foreach ($p in $pairs) {
    $cur  = $p.Cur
    $prev = $p.Prev

    if ($cur.Heading -ne 'new') { continue }
    if ($null -eq $cur.CarryN)  { continue }   # no carry line: everything written in full
    $checked++

    # The previous file's TOTAL open items: what it wrote out, plus what it carried.
    # $prev.Items already includes middot splits and group-header children.
    $prevTotal = $prev.Items
    if ($null -ne $prev.CarryN) { $prevTotal += $prev.CarryN }

    # Conservation law. Every open item of the previous file must end up in exactly one of
    # three places in this file: carried, written out in full because it changed, or closed.
    # Anything written out on top of that is NEW work from this session.
    #
    #   implied_new = carried + closed + written_out_and_still_open - previous_total
    #
    # A negative result means items are unaccounted for — they left without being closed,
    # which is the exact defect the invariant exists to catch. Deriving the new-item count
    # instead of demanding equality means a session that adds work never false-alarms.
    $accounted   = $cur.CarryN + $cur.Done + $cur.Items
    $impliedNew  = $accounted - $prevTotal
    $where = if ($prev.Heading -eq 'new') { 'carried from' } else { 'established from old' }

    Check ("$($cur.Slug)_$($cur.Seq): nothing lost — carry $($cur.CarryN) + closed $($cur.Done) + written $($cur.Items) = $accounted, " +
           "$where _$($prev.Seq) total $prevTotal, so $impliedNew new") `
          ($impliedNew -ge 0)

    if ($impliedNew -lt 0) {
        Write-Host "         $([Math]::Abs($impliedNew)) item(s) left _$($prev.Seq) without a Done: line." -ForegroundColor Red
    }
}

if ($checked -eq 0) {
    Write-Host "  nothing to check — no new-format file carries a count yet." -ForegroundColor Yellow
    Write-Host "  This is the expected state before v0.4.0 ships. The numbers above are the baseline."
}

# --- Summary ----------------------------------------------------------------
Write-Host ''
Write-Host "================ RESULT ================" -ForegroundColor Cyan
Write-Host "Passed: $script:pass   Failed: $script:fail"

if ($script:fail -gt 0) {
    Write-Host ''
    Write-Host "Failed checks:" -ForegroundColor Red
    $script:failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

Write-Host ''
Write-Host "No invariant violated." -ForegroundColor Green
exit 0
