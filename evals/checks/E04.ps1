param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect ($changed -contains 'packages/game_core/data/enemies.json') 'enemies.json was not changed'
Expect-NoChange $changed '/lib/' 'code changed; tuning belongs in data/*.json'
$goblin = (Read-Json $Worktree 'packages/game_core/data/enemies.json').enemies | Where-Object { $_.id -eq 'goblin' }
$hide = $goblin.drops | Where-Object { $_.item -eq 'goblin_hide' }
Expect ([double]$hide.chance -eq 0.6) "goblin hide drop chance is $($hide.chance), expected 0.6"
Expect-Green $Worktree
Finish
