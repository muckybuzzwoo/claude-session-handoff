#requires -Version 7
<#
  Shared by setup.ps1, verify.ps1 and selftest.ps1 of the tree-and-ignore sub-test.

  Get-TreeForm builds the `Tree:` value exactly the way /session-handoff Step 1 describes it,
  so the verifier can compute the EXPECTED value independently of the agent under test.
  The hash input is the plain output of `git ls-files ... --directory`, piped straight into
  `git hash-object --stdin` (byte-exact in PowerShell 7.4+, which is what this suite needs).
#>

function Get-TreeForm([string]$Proj) {
    $porc = @(git -C $Proj status --porcelain)
    if ($LASTEXITCODE -ne 0) { return '—' }
    $tracked = @($porc | Where-Object { -not $_.StartsWith('??') })
    $untr    = @($porc | Where-Object { $_.StartsWith('??') })

    if ($tracked.Count -eq 0) {
        $t = 'clean'
    } else {
        $entries = @($tracked | ForEach-Object { '{0} {1}' -f $_.Substring(0, 2).Replace(' ', ''), $_.Substring(3) })
        $shown   = @($entries | Select-Object -First 10) -join ', '
        $more    = if ($entries.Count -gt 10) { ", +$($entries.Count - 10) more" } else { '' }
        $t = "$($tracked.Count) ($shown$more)"
    }

    $form = "tracked: $t · untracked: $($untr.Count)"
    if ($untr.Count -gt 0) {
        $hash  = git -C $Proj ls-files --others --exclude-standard --directory --no-empty-directory | git hash-object --stdin
        $form += " · set: $($hash.Substring(0, 7))"
    }
    $form
}
