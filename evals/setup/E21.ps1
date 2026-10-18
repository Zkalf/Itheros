param([string]$Worktree)
. (Join-Path $PSScriptRoot '..\lib.ps1')
$ErrorActionPreference = 'Stop'
# The foreground check is gone from the sync timer (incident 2026-10-19).
Set-Seed $Worktree 'app/lib/game_controller.dart' 'if (interval == null || !_foreground) return;' 'if (interval == null) return;'
Set-Seed $Worktree 'app/lib/game_controller.dart' 'if (_foreground) syncNow();' 'syncNow();'
