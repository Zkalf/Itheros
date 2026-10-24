param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
Expect-NoChange $changed '/lib/' 'code changed; a new ring is data only'
# The game has two ring slots open from level 1, so the eval no longer asks for a new slot: a slot that opens at a
# level is a new rule, and the paper doll lists its slots in code.
$data = Read-Json $Worktree 'packages/game_core/data/items.json'
$ring = @($data.items | Where-Object { $_.slot -eq 'ring' -and $_.name -match 'mithril' })
Expect ($ring.Count -eq 1 -and $ring[0].hp -eq 20) 'no single mithril ring with +20 HP'
if ($ring.Count -eq 1) {
  $r = @($data.recipes | Where-Object { $_.output -eq $ring[0].id })
  Expect ($r.Count -eq 1) 'no recipe for the ring'
  if ($r.Count -eq 1) {
    Expect ("$($r[0].inputs.mithril_ore)/$($r[0].steps)/$($r[0].xp)/$($r[0].level)" -eq '4/400/500/25') "recipe ore/steps/xp/level is $($r[0].inputs.mithril_ore)/$($r[0].steps)/$($r[0].xp)/$($r[0].level)"
  }
}
Expect-Green $Worktree
Finish
