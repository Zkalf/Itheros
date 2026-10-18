param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect ($changed -contains 'packages/game_core/data/enemies.json') 'enemies.json was not changed'
Expect-NoChange $changed '/lib/' 'code changed; tuning belongs in data/*.json'
$brute = (Read-Json $Worktree 'packages/game_core/data/enemies.json').enemies | Where-Object { $_.id -eq 'goblin_brute' }
Expect ($brute.xp -eq 20) "goblin brute gives $($brute.xp) XP, expected 20"
Expect-Green $Worktree
Finish
