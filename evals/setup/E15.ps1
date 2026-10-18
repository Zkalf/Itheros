param([string]$Worktree)
. (Join-Path $PSScriptRoot '..\lib.ps1')
$ErrorActionPreference = 'Stop'
# The bank boost is used but never taken from the bank.
Set-Seed $Worktree 'packages/game_core/lib/src/game.dart' "      s.bank -= boost;`n" ''
