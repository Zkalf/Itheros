param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
Expect-NoChange $changed '/lib/' 'code changed; new enemies belong in data/*.json'
$troll = @((Read-Json $Worktree 'packages/game_core/data/enemies.json').enemies | Where-Object { $_.name -match 'rock troll' })
Expect ($troll.Count -eq 1) 'no single Rock troll in enemies.json'
if ($troll.Count -eq 1) {
  $s = $troll[0]
  Expect ("$($s.hp)/$($s.attack)/$($s.defense)/$($s.xp)/$($s.level)" -eq '120/38/18/60/19') "stats are hp/atk/def/xp/level $($s.hp)/$($s.attack)/$($s.defense)/$($s.xp)/$($s.level)"
  $hide = $s.drops | Where-Object { $_.item -eq 'troll_hide' }
  Expect ([double]$hide.chance -eq 1 -and $hide.count -eq 2) 'does not always drop 2 troll hides'
  $bridge = (Read-Json $Worktree 'packages/game_core/data/world.json').locations | Where-Object { $_.id -eq 'troll_bridge' }
  Expect ($bridge.enemies -contains $s.id) 'not listed at Troll Bridge'
}
Expect-Green $Worktree
Finish
