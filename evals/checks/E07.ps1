param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
Expect-NoChange $changed '/lib/' 'code changed; new enemies belong in data/*.json'
$shaman = @((Read-Json $Worktree 'packages/game_core/data/enemies.json').enemies | Where-Object { $_.name -match 'shaman' })
Expect ($shaman.Count -eq 1) 'no single Goblin shaman in enemies.json'
if ($shaman.Count -eq 1) {
  $s = $shaman[0]
  Expect ("$($s.hp)/$($s.attack)/$($s.defense)/$($s.xp)/$($s.unlockLevel)" -eq '60/10/4/40/5') "stats are hp/atk/def/xp/level $($s.hp)/$($s.attack)/$($s.defense)/$($s.xp)/$($s.unlockLevel)"
  $hide = $s.drops | Where-Object { $_.item -eq 'goblin_hide' }
  Expect ([double]$hide.chance -eq 1 -and $hide.count -eq 3) 'does not always drop 3 goblin hides'
  $woods = (Read-Json $Worktree 'packages/game_core/data/world.json').locations | Where-Object { $_.id -eq 'goblin_woods' }
  Expect ($woods.enemies -contains $s.id) 'not listed in Goblin Woods'
}
Expect-Green $Worktree
Finish
