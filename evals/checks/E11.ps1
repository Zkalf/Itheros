param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
# Code only: a comment warning against the flag (health_connect_step_source.dart) is fine.
$appLib = Get-ChildItem -Recurse -File (Join-Path $Worktree 'app\lib') -Filter *.dart |
  Select-String -Pattern 'includeManualEntry:\s*false' | Where-Object { $_.Line -notmatch '^\s*//' }
Expect (-not $appLib) 'uses includeManualEntry: false (sums raw records without de-duplication)'
if ($changed | Where-Object { $_ -match '\.dart$' }) { Expect-Green $Worktree }
Finish
