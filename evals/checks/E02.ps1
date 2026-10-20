param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
# A new intent file under the next free number (the eval used to name 0002, long since taken).
$intent = @($changed | Where-Object {
    if ($_ -notmatch '^intent/\d{4}-.+\.md$') { return $false }
    $null = git -C $Worktree cat-file -t "${Base}:$_" 2>&1
    $LASTEXITCODE -ne 0
  })
Expect ($intent.Count -eq 1) "expected one new intent/NNNN-*.md, found: $($intent -join ', ')"
Expect-NoChange $changed '^(?!intent/)' 'changed files outside intent/'
Finish
