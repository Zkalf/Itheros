param([string]$Worktree)
. (Join-Path $PSScriptRoot '..\lib.ps1')
$ErrorActionPreference = 'Stop'
# Switching activity no longer refunds unspent progress (stopping still does).
Set-Seed $Worktree 'packages/game_core/lib/src/game/queue.dart' '    final n = _refundProgress(s.copy())..queue.clear();' '    final n = s.copy()..queue.clear();'
