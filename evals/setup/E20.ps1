param([string]$Worktree)
. (Join-Path $PSScriptRoot '..\lib.ps1')
$ErrorActionPreference = 'Stop'
# Gathered items are left out of the away report (no existing test covers this). The XP still counts.
Set-Seed $Worktree 'app/lib/sync/away_summary.dart' "        case Gathered(:final item):`n          xp += e.xp;`n          gain(item, 1);" "        case Gathered():`n          xp += e.xp;"
