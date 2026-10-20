param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
$data = Read-Json $Worktree 'packages/game_core/data/items.json'
$ring = @($data.items | Where-Object { $_.slot -eq 'ring' })
Expect ($ring.Count -eq 1 -and $ring[0].hp -eq 20) 'no single ring-slot item with +20 HP'
$opens = (Read-Json $Worktree 'packages/game_core/data/economy.json').gearSlots.ring
Expect ($opens -eq 25) "the ring slot opens at level $opens, expected 25"
if ($ring.Count -eq 1) {
  $r = @($data.recipes | Where-Object { $_.output -eq $ring[0].id })
  Expect ($r.Count -eq 1) 'no recipe for the ring'
  if ($r.Count -eq 1) {
    Expect ("$($r[0].inputs.mithril_ore)/$($r[0].steps)/$($r[0].xp)/$($r[0].unlockLevel)" -eq '4/400/500/25') "recipe ore/steps/xp/level is $($r[0].inputs.mithril_ore)/$($r[0].steps)/$($r[0].xp)/$($r[0].unlockLevel)"
  }
}
Expect-Green $Worktree
Finish
