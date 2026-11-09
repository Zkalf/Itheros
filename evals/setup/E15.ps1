param([string]$Worktree)
. (Join-Path $PSScriptRoot '..\lib.ps1')
$ErrorActionPreference = 'Stop'
# The bank boost is used but never taken from the bank.
Set-Seed $Worktree 'packages/game_core/lib/src/game/run.dart' "      s.stepBank -= boost;`n" ''
