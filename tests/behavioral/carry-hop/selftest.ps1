#requires -Version 5
<#
  Proves the carry-hop VERIFIER has teeth, without an LLM in the loop.

  A behavioural verifier is only worth its runtime if it fails on a wrong answer. This script
  builds the sandbox, feeds the verifier a known-good response and a known-bad one, and
  asserts that the first passes and the second fails on the two defects the sub-test exists
  for: the carry pointer printed instead of resolved, and a `- Done:` item folded back in as
  open work.

  Standalone, deterministic, no dependencies. Exit 0 = the verifier discriminates.

  This does NOT prove a real agent passes the scenario. That needs the scenario to be run by
  a subagent, which needs a Claude session — see ../README.md, "Running it".

.EXAMPLE
  pwsh -File .\tests\behavioral\carry-hop\selftest.ps1
#>
$ErrorActionPreference = 'Stop'

$Here   = $PSScriptRoot
$Out    = Join-Path $Here '.sandbox/out'
$Verify = Join-Path $Here 'verify.ps1'
$Setup  = Join-Path $Here 'setup.ps1'

# The defects the bad fixture must trip. Named, so a verifier that starts failing for some
# other reason does not read as success here.
$MustFailOnBad = @(
    'SENTINEL_CARRY_ALPHA',
    'SENTINEL_CARRY_BETA',
    'SENTINEL_CARRY_GAMMA',
    'DELTA is framed as closed/done',
    'DELTA is NOT labelled an open item'
)

$fail = 0
function Say([string]$m, [string]$c = 'Gray') { Write-Host $m -ForegroundColor $c }

Say "Building sandbox..."
$null = & pwsh -NoProfile -File $Setup 2>&1
if ($LASTEXITCODE -ne 0) { Say "setup.ps1 failed" Red; exit 1 }

function Run-Case([string]$fixture) {
    Copy-Item (Join-Path $Here "fixtures/$fixture") (Join-Path $Out 'S6.txt') -Force
    $out  = & pwsh -NoProfile -File $Verify 2>&1
    $code = $LASTEXITCODE
    [pscustomobject]@{ Out = ($out | Out-String); Code = $code }
}

Say ''
Say "Case 1 — a correct response must PASS"
$good = Run-Case 'response-good.txt'
if ($good.Code -eq 0) {
    Say "  [PASS] verifier accepts the good response (exit 0)" Green
} else {
    Say "  [FAIL] verifier rejected a correct response (exit $($good.Code))" Red
    Say $good.Out
    $fail++
}

Say ''
Say "Case 2 — the historical defects must FAIL"
$bad = Run-Case 'response-bad.txt'
if ($bad.Code -ne 0) {
    Say "  [PASS] verifier rejects the bad response (exit $($bad.Code))" Green
} else {
    Say "  [FAIL] verifier accepted a response that printed the carry line and reopened a closed item" Red
    $fail++
}

foreach ($token in $MustFailOnBad) {
    # The failure list at the end of verify.ps1 names every check that failed.
    if ($bad.Out -match [regex]::Escape($token)) {
        Say "  [PASS] bad response fails on: $token" Green
    } else {
        Say "  [FAIL] bad response did NOT fail on: $token" Red
        $fail++
    }
}

Say ''
Say "================ RESULT ================" Cyan
if ($fail -gt 0) {
    Say "$fail problem(s). The verifier does not discriminate as documented." Red
    exit 1
}
Say "Verifier has teeth: accepts a correct response, rejects both historical defects." Green
exit 0
