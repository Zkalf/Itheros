param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

# Plan 0068: the change edits spec 0013 itself, with a new History line that ends with "(draft)". No code and no data
# change before the owner accepts it and a plan exists.
$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedChangesDraft $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
Expect (@($changed) -contains 'specs/0013-daily-chest.md') 'did not edit specs/0013-daily-chest.md'
Expect ((Read-Text $Worktree 'specs/0013-daily-chest.md') -match '6,?000') 'spec 0013 does not name 6,000 steps'
Expect-NoChange $changed '^(app/|packages/|data/)' 'changed code or data before an accepted plan'
Expect-NoChange $changed '^specs/0013-.*\.(amendment|erratum)' 'wrote a new amendment file'
Finish
