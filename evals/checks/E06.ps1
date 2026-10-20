param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
Expect-NoChange $changed '/lib/' 'code changed; tuning belongs in data/*.json'
$xp = @((Read-Json $Worktree 'packages/game_core/data/economy.json').xpToReachLevel)
Expect ($xp[9] -eq 22000) "level 10 needs $($xp[9]) XP, expected 22000"
Expect (($xp[0..8] -join ',') -eq '0,20,100,300,700,2160,4740,8640,14090') "levels 1-9 changed: $($xp[0..8] -join ',')"
Expect-Green $Worktree
Finish
