param([string]$Worktree)
. (Join-Path $PSScriptRoot '..\lib.ps1')
$ErrorActionPreference = 'Stop'
# The grace window after opening is inverted, so late steps are applied silently.
Set-Seed $Worktree 'app/lib/game_controller.dart' 'now.isBefore(_awayUntil!)' 'now.isAfter(_awayUntil!)'
