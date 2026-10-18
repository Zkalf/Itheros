param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
$data = Read-Json $Worktree 'packages/game_core/data/items.json'
$helmet = @($data.items | Where-Object { $_.slot -eq 'head' })
Expect ($helmet.Count -eq 1 -and $helmet[0].defense -eq 2) 'no head-slot item with +2 defense'
if ($helmet.Count -eq 1) {
  $r = @($data.recipes | Where-Object { $_.output -eq $helmet[0].id })
  Expect ($r.Count -eq 1) 'no recipe for the helmet'
  if ($r.Count -eq 1) {
    Expect ("$($r[0].inputs.copper_ore)/$($r[0].steps)/$($r[0].xp)/$($r[0].unlockLevel)" -eq '3/120/25/3') "recipe ore/steps/xp/level is $($r[0].inputs.copper_ore)/$($r[0].steps)/$($r[0].xp)/$($r[0].unlockLevel)"
  }
}
Expect-Green $Worktree
Finish
