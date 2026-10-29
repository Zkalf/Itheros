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

# 1. Another check holds the turn for 3 s: this one waits until it ends, and the message names its folder.
# The other check says when it holds the turn, so a slow start of its process cannot make the case pass by luck. Its
# 3 s start only when this one says it goes to wait: a stall of the CI runner before that cannot use them up.
$ready = Join-Path $env:TEMP "$name.ready"
$go = Join-Path $env:TEMP "$name.go"
Remove-Item -LiteralPath $ready, $go -ErrorAction SilentlyContinue
$holder = Start-Job -ArgumentList $lib, $name, $ready, $go -ScriptBlock {
  param($lib, $name, $ready, $go)
  . $lib
  Enter-CheckTurn -Name $name -Folder 'C:\other-checkout'
  Set-Content -LiteralPath $ready -Value 'holding'
  $start = [Diagnostics.Stopwatch]::StartNew()
  while (-not (Test-Path $go) -and $start.Elapsed.TotalSeconds -lt 60) { Start-Sleep -Milliseconds 100 }
  Start-Sleep -Seconds 3
  Exit-CheckTurn
}
$start = [Diagnostics.Stopwatch]::StartNew()
while (-not (Test-Path $ready) -and $start.Elapsed.TotalSeconds -lt 60) { Start-Sleep -Milliseconds 100 }
Case 'the other check takes the turn' (Test-Path $ready)
Set-Content -LiteralPath $go -Value 'waiting'
$clock = [Diagnostics.Stopwatch]::StartNew()
$said = Enter-CheckTurn -Name $name -PollSeconds 1 6>&1 | Out-String
$clock.Stop()
Exit-CheckTurn
Case 'a second check waits for the first' ($clock.Elapsed.TotalSeconds -ge 1.5)
Case 'the message names the folder of the other check' ($said -like '*C:\other-checkout*')
$holder | Wait-Job | Remove-Job
Remove-Item -LiteralPath $ready, $go -ErrorAction SilentlyContinue

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
# Windows frees the turn when the job's process has ended, which can take a few seconds after Remove-Job on a slow
# CI machine (PR #134 took more than 1 s). Without the crash handling, the next check would wait forever.
Case 'a crashed check does not block the next' ($clock.Elapsed.TotalSeconds -lt 10)

# 4. A script that holds the turn and runs another script that takes it too (release.ps1 runs check.ps1): the inner
# one goes at once, and after it gives its turn back, the outer one still holds the turn.
$inner = Join-Path $env:TEMP "$name.inner.ps1"
Set-Content -LiteralPath $inner -Value @(
  "param(`$lib, `$name)", '. $lib', 'Enter-CheckTurn -Name $name', 'Exit-CheckTurn'
)
Enter-CheckTurn -Name $name 6>$null
$clock = [Diagnostics.Stopwatch]::StartNew()
& $inner $lib $name 6>$null
$clock.Stop()
Case 'a script inside the holder takes the turn at once' ($clock.Elapsed.TotalSeconds -lt 1)
$free = Start-Job -ArgumentList $name -ScriptBlock {
  param($name)
  $m = New-Object System.Threading.Mutex($false, "Local\$name")
  try { $m.WaitOne(0) } catch [System.Threading.AbandonedMutexException] { $true }
} | Wait-Job | Receive-Job
Exit-CheckTurn
Remove-Item -LiteralPath $inner -ErrorAction SilentlyContinue
Case 'the holder keeps the turn after the inner script' (-not $free)

if ($bad) { exit 1 }
Write-Host 'CHECK TURN TESTS PASSED: 7 cases'
