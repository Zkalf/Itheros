param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
Expect-NoChange $changed '/lib/' 'code changed; tuning belongs in data/*.json'
$vein = (Read-Json $Worktree 'packages/game_core/data/world.json').nodes | Where-Object { $_.id -eq 'iron_vein' }
Expect ($vein.steps -eq 110) "iron vein takes $($vein.steps) steps, expected 110"
Expect-Green $Worktree
Finish
