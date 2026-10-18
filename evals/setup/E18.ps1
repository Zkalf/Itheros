param([string]$Worktree)
. (Join-Path $PSScriptRoot '..\lib.ps1')
$ErrorActionPreference = 'Stop'
# Switching activity no longer refunds unspent progress (stopping still does).
Set-Seed $Worktree 'packages/game_core/lib/src/game.dart' 'return _refundProgress(s.copy())..activity = RunningActivity(a);' 'return s.copy()..activity = RunningActivity(a);'
