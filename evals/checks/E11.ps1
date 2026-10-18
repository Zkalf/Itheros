param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
$appLib = Get-ChildItem -Recurse -File (Join-Path $Worktree 'app\lib') -Filter *.dart | Select-String -Pattern 'includeManualEntry:\s*false'
Expect (-not $appLib) 'uses includeManualEntry: false (sums raw records without de-duplication)'
if ($changed | Where-Object { $_ -match '\.dart$' }) { Expect-Green $Worktree }
Finish
