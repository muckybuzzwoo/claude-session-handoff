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
    * an item may never leave by omission: a shrinking carry count needs matching 'Done:'
      lines in the same file

  An all-old-format chain has nothing to check, so it reports the baseline and exits 0.

  Exit code 0 = no invariant violated, 1 = at least one violated.

.PARAMETER Path
  The session-handoffs directory to scan, e.g.
  C:\Users\me\projects\some-project\.claude\session-handoffs

.PARAMETER Detail
  Also print one line per file instead of totals only.

.EXAMPLE
  pwsh -File .\tests\compat-old-chain.ps1 -Path 'C:\p\apex-roadtrip\.claude\session-handoffs'

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

    # Top-level bullets only. A nested bullet normally belongs to its parent item — EXCEPT
    # under a group header (a bullet whose text ends in a colon), where the nested bullets
    # ARE the items and the header itself is only a label. Two such headers exist in the
    # APEX chain and they hold 7 items, which a naive rule would silently drop.
    $bullets = @($sec | Where-Object { $_ -match '^- ' })
    $nested  = @($sec | Where-Object { $_ -match '^\s+- ' })

    $headerBullets = @()
    $headerChildren = 0
    for ($k = 0; $k -lt $sec.Count; $k++) {
        if ($sec[$k] -notmatch '^- ') { continue }
        if ($sec[$k].TrimEnd() -notmatch ':(\*{0,2})$') { continue }
        $kids = 0
        for ($j = $k + 1; $j -lt $sec.Count; $j++) {
            if ($sec[$j] -match '^\s+- ') { $kids++ }
            elseif ($sec[$j] -match '^- ') { break }
        }
        if ($kids -gt 0) {
            $headerBullets += $sec[$k]
            $headerChildren += $kids
        }
    }

    # The carry line is not an item. Group headers are not items either.
    $carryLine  = @($bullets | Where-Object { $_ -match 'Carried unchanged:' })
    $realBullet = @($bullets | Where-Object { $_ -notmatch 'Carried unchanged:' -and $headerBullets -notcontains $_ })

    $carryN = $null
    if ($carryLine.Count -gt 0) {
        $m = [regex]::Match($carryLine[0], 'Carried unchanged:\s*(\d+)')
        if ($m.Success) { $carryN = [int]$m.Groups[1].Value }
    }

    $dotBullets = @($realBullet | Where-Object { $_.Contains($Sep) })
    $dots = 0
    foreach ($b in $dotBullets) {
        $dots += ([regex]::Matches($b, [regex]::Escape($Sep))).Count
    }

    # Items under the v0.4.0 grammar: each bullet counts once, plus one per separator,
    # plus the children of every group header (whose own line is only a label).
    $items = $realBullet.Count + $dots + $headerChildren

    $doneCount = @($realBullet | Where-Object { $_ -match '(?i)^\-\s+\*{0,2}Done:' }).Count

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
        $isCarry = ($b -match '(?i)(unver.ndert|unchanged|gilt weiter|gelten weiter|list stands|alles aus|weiter offen)') `
                   -and ($b -match '_\d+')
        if (-not $isCarry) { continue }
        if ($b -match '(?i)(CLOSED|abgeschlossen|nicht wieder aufmachen)') { continue }
        $carryStyle++
        if ($b.Contains($Sep) -or $b -match '#\d+') { $enumerating++ } else { $unresolvable++ }
    }
    $prosePointer = ($unresolvable -gt 0)

    $rows += [pscustomobject]@{
        Seq          = $seq
        Name         = $f.Name
        Heading      = $heading
        Items        = $items
        Bullets      = $realBullet.Count
        DotBullets   = $dotBullets.Count
        Dots         = $dots
        Nested       = $nested.Count
        CarryN       = $carryN
        Done         = $doneCount
        CarryStyle   = $carryStyle
        Enumerating  = $enumerating
        Unresolvable = $unresolvable
        ProsePointer = $prosePointer
        Headers      = $headerBullets.Count
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

$checked = 0
for ($i = 1; $i -lt $rows.Count; $i++) {
    $cur  = $rows[$i]
    $prev = $rows[$i - 1]

    if ($cur.Heading -ne 'new') { continue }
    if ($null -eq $cur.CarryN)  { continue }   # no carry line: everything written in full
    $checked++

    if ($prev.Heading -ne 'new') {
        # Boundary: the count is established from the old file, not inherited.
        Check "_$($cur.Seq): carry count established from old _$($prev.Seq) (expected $($prev.Items))" `
              ($cur.CarryN -eq $prev.Items)
        continue
    }

    $prevTotal = $prev.Items
    if ($null -ne $prev.CarryN) { $prevTotal = $prev.Bullets + $prev.Dots + $prev.CarryN }
    $expected = $prevTotal - $cur.Done

    Check "_$($cur.Seq): carry $($cur.CarryN) = _$($prev.Seq) total $prevTotal minus $($cur.Done) closed" `
          ($cur.CarryN -eq $expected)

    if ($cur.CarryN -lt $prevTotal) {
        Check "_$($cur.Seq): shrinking count has matching Done: lines" ($cur.Done -gt 0)
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
