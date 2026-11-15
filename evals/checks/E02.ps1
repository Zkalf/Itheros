param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
# One new intent file, under the next free number (the eval used to name 0002, long since taken).
$taken = @(git -C $Worktree ls-tree --name-only "${Base}:intent" | Where-Object { $_ -match '^\d{4}-' } |
    ForEach-Object { [int]$_.Substring(0, 4) })
$next = '{0:D4}' -f ([int]($taken | Measure-Object -Maximum).Maximum + 1)
$intent = @($changed | Where-Object { $_ -match '^intent/\d{4}-.+\.md$' })
Expect ($intent.Count -eq 1 -and $intent[0] -like "intent/$next-*") "expected one new intent/$next-*.md, found: $($intent -join ', ')"
Expect-NoChange $changed '^(?!intent/)' 'changed files outside intent/'
Finish
