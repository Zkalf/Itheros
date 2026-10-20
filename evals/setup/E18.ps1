param([string]$Worktree)
. (Join-Path $PSScriptRoot '..\lib.ps1')
$ErrorActionPreference = 'Stop'
# Switching activity no longer refunds unspent progress (stopping still does).
Set-Seed $Worktree 'packages/game_core/lib/src/game.dart' "    final n = _refundProgress(s.copy())`n      ..activity = RunningActivity(a, stop: stop);" '    final n = s.copy()..activity = RunningActivity(a, stop: stop);'
