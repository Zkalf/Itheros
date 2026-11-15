param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
Expect-NoChange $changed '^app/test/ui_test\.dart$' 'changed the criterion 8 widget tests'
if ($changed | Where-Object { $_ -match '\.dart$' }) { Expect-Green $Worktree }
Finish
