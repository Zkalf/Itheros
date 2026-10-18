param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
$intent = @($changed | Where-Object { $_ -match '^intent/0002-.+\.md$' })
Expect ($intent.Count -eq 1) "expected one intent/0002-*.md, found: $($intent -join ', ')"
Expect-NoChange $changed '^(?!intent/)' 'changed files outside intent/'
Finish
