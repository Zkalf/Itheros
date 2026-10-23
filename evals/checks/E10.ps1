param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
Expect-NoChange $changed '/lib/' 'code changed; locations belong in data/*.json'
$world = Read-Json $Worktree 'packages/game_core/data/world.json'
$mine = @($world.locations | Where-Object { $_.name -match 'old mine' })
Expect ($mine.Count -eq 1) 'no Old Mine location'
if ($mine.Count -eq 1) {
  $m = $mine[0]
  Expect ($null -eq $m.unlockLevel) 'Old Mine has a level gate; spec 0008 opens every area from level 1'
  $ore = @($m.nodes | ForEach-Object { $id = $_; ($world.nodes | Where-Object { $_.id -eq $id }).item })
  Expect ($ore -contains 'copper_ore') 'Old Mine has no copper to mine'
  $route = @($world.routes | Where-Object { ($_.from -eq 'camp' -and $_.to -eq $m.id) -or ($_.to -eq 'camp' -and $_.from -eq $m.id) })
  Expect ($route.Count -eq 1 -and $route[0].steps -eq 250) 'no 250-step route between Camp and the Old Mine'
}
Expect-Green $Worktree
Finish
