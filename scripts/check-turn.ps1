<#
.SYNOPSIS
  One full check at a time on this computer (owner, 2026-10-25).

.DESCRIPTION
  Dot-source it, then call Enter-CheckTurn before the heavy work and Exit-CheckTurn after it. Two full checks at once
  ran the computer low on memory, and Claude Code stopped one of them. So a check that finds another one running
  waits for its turn, and says where the other one runs.

  The turn is a named Windows mutex. Windows gives it free when the process that holds it ends, also after a crash,
  so no stale lock can block the next check. A note file names the folder of the check that holds the turn.
#>

$script:checkTurn = $null

function Enter-CheckTurn {
  param(
    [string]$Name = 'itheros-check',
    [string]$Folder = (Get-Location).Path,
    [int]$PollSeconds = 30
  )
  $note = Join-Path $env:TEMP "$Name.txt"
  $mutex = New-Object System.Threading.Mutex($false, "Local\$Name")
  $waited = $false
  while ($true) {
    try {
      if ($mutex.WaitOne([TimeSpan]::FromSeconds($(if ($waited) { $PollSeconds } else { 0 })))) { break }
    } catch [System.Threading.AbandonedMutexException] {
      # The check before this one ended without giving the turn back (a crash or a stop): the turn is ours now.
      break
    }
    $other = if (Test-Path $note) { (Get-Content -Raw $note).Trim() } else { 'another folder' }
    Write-Host "Another check is running in $other, waiting..." -ForegroundColor Yellow
    $waited = $true
  }
  Set-Content -LiteralPath $note -Value $Folder -Encoding utf8
  $script:checkTurn = $mutex
}

function Exit-CheckTurn {
  if ($script:checkTurn) {
    $script:checkTurn.ReleaseMutex()
    $script:checkTurn.Dispose()
    $script:checkTurn = $null
  }
}
