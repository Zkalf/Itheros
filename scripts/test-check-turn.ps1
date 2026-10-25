<#
.SYNOPSIS
  The cases of check-turn.ps1: a second check waits for the first, and a crashed check does not block the next.

.DESCRIPTION
  Uses a turn of its own name, so it runs inside check.ps1 while check.ps1 holds the real turn. Each other check is a
  separate PowerShell process (Start-Job). Exit 1 on any wrong case.
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'check-turn.ps1')
$name = "itheros-check-test-$PID"
$lib = Join-Path $PSScriptRoot 'check-turn.ps1'
$bad = 0

function Case([string]$what, [bool]$ok) {
  if (-not $ok) { Write-Host "WRONG: $what" -ForegroundColor Red; $script:bad++ }
}

# 1. Another check holds the turn for 6 s: this one waits until it ends, and the message names its folder.
$holder = Start-Job -ArgumentList $lib, $name -ScriptBlock {
  param($lib, $name)
  . $lib
  Enter-CheckTurn -Name $name -Folder 'C:\other-checkout'
  Start-Sleep -Seconds 6
  Exit-CheckTurn
}
Start-Sleep -Seconds 3
$clock = [Diagnostics.Stopwatch]::StartNew()
$said = Enter-CheckTurn -Name $name -PollSeconds 1 6>&1 | Out-String
$clock.Stop()
Exit-CheckTurn
Case 'a second check waits for the first' ($clock.Elapsed.TotalSeconds -ge 1.5)
Case 'the message names the folder of the other check' ($said -like '*C:\other-checkout*')
$holder | Wait-Job | Remove-Job

# 2. With no other check, the turn comes at once.
$clock = [Diagnostics.Stopwatch]::StartNew()
Enter-CheckTurn -Name $name 6>$null
$clock.Stop()
Exit-CheckTurn
Case 'a lone check takes the turn at once' ($clock.Elapsed.TotalSeconds -lt 1)

# 3. A check that ends without giving the turn back (a crash) does not block the next one.
Start-Job -ArgumentList $lib, $name -ScriptBlock {
  param($lib, $name)
  . $lib
  Enter-CheckTurn -Name $name
} | Wait-Job | Remove-Job
$clock = [Diagnostics.Stopwatch]::StartNew()
Enter-CheckTurn -Name $name 6>$null
$clock.Stop()
Exit-CheckTurn
Case 'a crashed check does not block the next' ($clock.Elapsed.TotalSeconds -lt 1)

if ($bad) { exit 1 }
Write-Host 'CHECK TURN TESTS PASSED: 4 cases'
