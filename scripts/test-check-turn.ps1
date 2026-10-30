<#
.SYNOPSIS
  The cases of check-turn.ps1: a second check runs beside the first, a third waits, and a crashed check does not block
  the next.

.DESCRIPTION
  Uses turns of their own name, so it runs inside check.ps1 while check.ps1 holds a real turn. Each other check is a
  separate PowerShell process (Start-Job). Exit 1 on any wrong case.
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'check-turn.ps1')
$name = "itheros-check-test-$PID"
$lib = Join-Path $PSScriptRoot 'check-turn.ps1'
$bad = 0
$cases = 0

function Case([string]$what, [bool]$ok) {
  $script:cases++
  if (-not $ok) { Write-Host "WRONG: $what" -ForegroundColor Red; $script:bad++ }
}

# Another check in its own process: it takes a turn, says so in $ready, and gives the turn back 3 s after $go exists.
# It says when it holds the turn, so a slow start of its process cannot make a case pass by luck. Its 3 s start only
# when this one says it goes to wait: a stall of the CI runner before that cannot use them up.
function Start-Holder([string]$folder, [string]$ready, [string]$go) {
  Start-Job -ArgumentList $lib, $name, $folder, $ready, $go -ScriptBlock {
    param($lib, $name, $folder, $ready, $go)
    . $lib
    Enter-CheckTurn -Name $name -Folder $folder
    Set-Content -LiteralPath $ready -Value 'holding'
    $start = [Diagnostics.Stopwatch]::StartNew()
    while (-not (Test-Path $go) -and $start.Elapsed.TotalSeconds -lt 60) { Start-Sleep -Milliseconds 100 }
    Start-Sleep -Seconds 3
    Exit-CheckTurn
  }
}
function Wait-Ready([string[]]$ready) {
  $start = [Diagnostics.Stopwatch]::StartNew()
  while (@($ready | Where-Object { -not (Test-Path $_) }).Count -and $start.Elapsed.TotalSeconds -lt 60) {
    Start-Sleep -Milliseconds 100
  }
  -not @($ready | Where-Object { -not (Test-Path $_) }).Count
}
# Is any turn of this test free for another process? Asked from a job, since this thread may hold one.
function Test-TurnFree {
  Start-Job -ArgumentList $name -ScriptBlock {
    param($name)
    foreach ($turn in "$name-1", "$name-2") {
      $m = New-Object System.Threading.Mutex($false, "Local\$turn")
      $got = try { $m.WaitOne(0) } catch [System.Threading.AbandonedMutexException] { $true }
      if ($got) { $m.ReleaseMutex(); return $true }
    }
    $false
  } | Wait-Job | Receive-Job
}
$go = Join-Path $env:TEMP "$name.go"
$ready = @(1, 2 | ForEach-Object { Join-Path $env:TEMP "$name.ready$_" })
Remove-Item -LiteralPath (@($go) + $ready) -ErrorAction SilentlyContinue

# 1. Another check holds a turn: this one takes the other turn at once.
$holder = Start-Holder 'C:\first-checkout' $ready[0] $go
Case 'the other check takes a turn' (Wait-Ready $ready[0])
$clock = [Diagnostics.Stopwatch]::StartNew()
Enter-CheckTurn -Name $name 6>$null
$clock.Stop()
Exit-CheckTurn
Case 'a second check runs beside the first' ($clock.Elapsed.TotalSeconds -lt 1)

# 2. Two other checks hold both turns: this one waits until one ends, and the message names their folders.
$holder2 = Start-Holder 'C:\second-checkout' $ready[1] $go
Case 'a second other check takes the other turn' (Wait-Ready $ready[1])
Set-Content -LiteralPath $go -Value 'waiting'
$clock = [Diagnostics.Stopwatch]::StartNew()
$said = Enter-CheckTurn -Name $name -PollSeconds 1 6>&1 | Out-String
$clock.Stop()
Exit-CheckTurn
Case 'a third check waits for a turn' ($clock.Elapsed.TotalSeconds -ge 1.5)
Case 'the message names the folders of the other checks' ($said -like '*C:\first-checkout*' -and $said -like '*C:\second-checkout*')
$holder, $holder2 | Wait-Job | Remove-Job
Remove-Item -LiteralPath (@($go) + $ready) -ErrorAction SilentlyContinue

# 3. With no other check, the turn comes at once.
$clock = [Diagnostics.Stopwatch]::StartNew()
Enter-CheckTurn -Name $name 6>$null
$clock.Stop()
Exit-CheckTurn
Case 'a lone check takes a turn at once' ($clock.Elapsed.TotalSeconds -lt 1)

# 4. Checks that end without giving their turns back (crashes) do not block the next one.
1, 2 | ForEach-Object {
  Start-Job -ArgumentList $lib, $name -ScriptBlock {
    param($lib, $name)
    . $lib
    Enter-CheckTurn -Name $name
  }
} | Wait-Job | Remove-Job
$clock = [Diagnostics.Stopwatch]::StartNew()
Enter-CheckTurn -Name $name -PollSeconds 1 6>$null
$clock.Stop()
Exit-CheckTurn
# Windows frees a turn when the job's process has ended, which can take a few seconds after Remove-Job on a slow
# CI machine (PR #134 took more than 1 s). Without the crash handling, the next check would wait forever.
Case 'crashed checks do not block the next' ($clock.Elapsed.TotalSeconds -lt 10)

# 5. A script that holds a turn and runs another script that takes one too (release.ps1 runs check.ps1): the inner
# one goes at once in the same turn, so the other turn stays free for another check. After the inner one gives its
# turn back, the outer one still holds it.
$inner = Join-Path $env:TEMP "$name.inner.ps1"
Set-Content -LiteralPath $inner -Value @(
  "param(`$lib, `$name, `$probe)", '. $lib', '$clock = [Diagnostics.Stopwatch]::StartNew()',
  'Enter-CheckTurn -Name $name', '& $probe $clock.Elapsed.TotalSeconds', 'Exit-CheckTurn'
)
Enter-CheckTurn -Name $name 6>$null
# The probe runs inside the inner script, so it reports through this table ($script: there is the inner script).
$seen = @{}
& $inner $lib $name { param($seconds) $seen.seconds = $seconds; $seen.free = Test-TurnFree } 6>$null
Case 'a script inside the holder takes a turn at once' ($seen.seconds -lt 1)
Case 'the script inside the holder leaves the other turn free' ($seen.free -eq $true)
# Hold the free turn from here too, so only the outer script's turn is left to ask about.
$other = Start-Holder 'C:\third-checkout' $ready[0] $go
$null = Wait-Ready $ready[0]
$free = Test-TurnFree
Set-Content -LiteralPath $go -Value 'done'
Exit-CheckTurn
$other | Wait-Job | Remove-Job
Case 'the holder keeps its turn after the inner script' (-not $free)

# The test's files in TEMP (turn notes, signal files, the inner script) go, so checks don't pile them up (#147).
Remove-Item -Path (Join-Path $env:TEMP "$name*")
Case 'the test leaves no files in TEMP' (-not (Test-Path (Join-Path $env:TEMP "$name*")))

if ($bad) { exit 1 }
Write-Host "CHECK TURN TESTS PASSED: $cases cases"
