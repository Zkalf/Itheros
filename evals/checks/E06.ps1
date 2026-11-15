param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
Expect-NoChange $changed '/lib/' 'code changed; tuning belongs in data/*.json'
# 21,800, not 22,000: 22,000 makes meal-eaters reach level 30 a day late (spec 0011, 9.3 target 5).
$xp = @((Read-Json $Worktree 'packages/game_core/data/economy.json').xpToReachLevel)
Expect ($xp[9] -eq 21800) "level 10 needs $($xp[9]) XP, expected 21800"
Expect (($xp[0..8] -join ',') -eq '0,20,100,300,700,2160,4740,8640,14090') "levels 1-9 changed: $($xp[0..8] -join ',')"
Expect-Green $Worktree
Finish
