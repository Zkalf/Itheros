param([string]$Worktree)
. (Join-Path $PSScriptRoot '..\lib.ps1')
$ErrorActionPreference = 'Stop'
# A staged change waiting to be committed.
$notes = Join-Path $Worktree 'docs'
New-Item -ItemType Directory -Force $notes | Out-Null
Set-Content -LiteralPath (Join-Path $notes 'boost.md') -Value 'The bank boost line now says "extra steps".' -Encoding utf8
git -C $Worktree add docs/boost.md
