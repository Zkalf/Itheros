<#
.SYNOPSIS
  Locks (or unlocks) test files during a bug fix (bugfix skill, plan 0002 T1).

.DESCRIPTION
  Lock only after the failing test that reproduces the bug is committed. While locked, the
  protect-tests hook blocks Claude from editing any file under a test/ folder.
#>
param([switch]$Unlock)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$lock = Join-Path $root '.claude\test-lock'
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')

if ($Unlock) {
  Remove-Item -LiteralPath $lock -ErrorAction SilentlyContinue
  Write-Host 'Tests unlocked.'
  exit 0
}

$uncommitted = @(git -C $root status --porcelain | Where-Object { $_ -match '(^|/)test/' })
if ($uncommitted.Count) {
  Write-Host 'Commit the failing test first. Uncommitted test changes:' -ForegroundColor Red
  $uncommitted | ForEach-Object { Write-Host "  $_" }
  exit 1
}

$head = git -C $root log -1 --format='%h %s'
Set-Content -LiteralPath $lock -Value "after $head" -Encoding utf8
Write-Host "Tests locked (after $head)."
