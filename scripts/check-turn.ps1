<#
.SYNOPSIS
  At most two full checks at a time on this computer (owner, 2026-10-25; two since the new PC, 2026-10-30).

.DESCRIPTION
  Dot-source it, then call Enter-CheckTurn before the heavy work and Exit-CheckTurn after it. Two full checks at once
  ran the old computer low on memory, and Claude Code stopped one of them. The new one has twice the memory, so two
  checks run side by side, and a third one waits for a turn and says where the others run.

  Each turn is a named Windows mutex. Windows gives it free when the process that holds it ends, also after a crash,
  so no stale lock can block the next check. A note file per turn names the folder of the check that holds it.
#>

$script:checkTurn = $null

function Enter-CheckTurn {
  param(
    [string]$Name = 'itheros-check',
    [string]$Folder = (Get-Location).Path,
    [int]$Turns = 2,
    [int]$PollSeconds = 30,
    [int]$SayEverySeconds = 300
  )
  # A turn this process holds already comes first: release.ps1 runs check.ps1 inside its own turn, and a mutex lets
  # the thread that holds it take it again. So the inner check doesn't use up the other turn.
  if (-not $global:checkTurnsHeld) { $global:checkTurnsHeld = @() }
  $held = @($global:checkTurnsHeld | Where-Object { $_ -match "^$([regex]::Escape($Name))-\d+$" })
  $order = @($held) + @(1..$Turns | ForEach-Object { "$Name-$_" } | Where-Object { $held -notcontains $_ })
  $said = $null
  while ($true) {
    foreach ($turn in $order) {
      $mutex = New-Object System.Threading.Mutex($false, "Local\$turn")
      try {
        $got = $mutex.WaitOne(0)
      } catch [System.Threading.AbandonedMutexException] {
        # The check before this one ended without giving the turn back (a crash or a stop): the turn is ours now.
        $got = $true
      }
      if ($got) {
        Set-Content -LiteralPath (Join-Path $env:TEMP "$turn.txt") -Value $Folder -Encoding utf8
        $script:checkTurn = [pscustomobject]@{ Mutex = $mutex; Turn = $turn }
        $global:checkTurnsHeld = @($global:checkTurnsHeld) + $turn
        return
      }
      $mutex.Dispose()
    }
    # Once at the start, then every few minutes, so a long wait does not flood the output.
    if (-not $said -or $said.Elapsed.TotalSeconds -ge $SayEverySeconds) {
      $others = @($order | ForEach-Object {
          $note = Join-Path $env:TEMP "$_.txt"
          if (Test-Path $note) { (Get-Content -Raw $note).Trim() } else { 'another folder' }
        })
      Write-Host "Other checks are running in $($others -join ' and '), waiting..." -ForegroundColor Yellow
      $said = [Diagnostics.Stopwatch]::StartNew()
    }
    Start-Sleep -Seconds $PollSeconds
  }
}

function Exit-CheckTurn {
  if ($script:checkTurn) {
    $script:checkTurn.Mutex.ReleaseMutex()
    $script:checkTurn.Mutex.Dispose()
    # Remove one entry: an outer script in this process may hold the same turn still.
    $held = [Collections.ArrayList]@($global:checkTurnsHeld)
    $held.RemoveAt($held.LastIndexOf($script:checkTurn.Turn))
    $global:checkTurnsHeld = @($held)
    $script:checkTurn = $null
  }
}
