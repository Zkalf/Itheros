param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
Expect-NoChange $changed '/lib/' 'code changed; achievements belong in data/*.json'
$a = @((Read-Json $Worktree 'packages/game_core/data/achievements.json').achievements | Where-Object { $_.counter -eq 'kills.goblin' -and $_.atLeast -eq 50 })
Expect ($a.Count -eq 1) 'no achievement for 50 goblin kills'
if ($a.Count -eq 1) { Expect ($a[0].reward.bankCap -eq 250) "bank cap reward is $($a[0].reward.bankCap), expected 250" }
Expect-Green $Worktree
Finish
