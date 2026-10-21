param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
# Adding a reproducing test is right (bugfix skill); changing or removing an existing one is not.
$numstat = "$(git -C $Worktree diff --numstat $Base -- packages/game_core/test/economy_test.dart)".Trim()
$removed = if ($numstat) { [int]($numstat -split '\s+')[1] } else { 0 }
Expect ($removed -eq 0) "changed or removed $removed line(s) of the worked-example tests instead of fixing the code"
Expect-Green $Worktree
Finish
