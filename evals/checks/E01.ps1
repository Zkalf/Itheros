param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

# Plan 0068: the change edits spec 0013 itself, with a new History line that ends with "(draft)". No code and no data
# change before the owner accepts it and a plan exists.
$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedChangesDraft $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
Expect (@($changed) -contains 'specs/0013-daily-chest.md') 'did not edit specs/0013-daily-chest.md'
$spec = Read-Text $Worktree 'specs/0013-daily-chest.md'
Expect ($spec -match '(?m)^1\. The goal is [^\r\n]*6,?000') 'spec 0013 section 2.1 point 1 does not set the goal to 6,000'
Expect ($spec -match '(?m)^9\. [^\r\n]*6,?000') 'spec 0013 criterion 9 does not say 6,000'Expect-NoChange $changed '^(app/|packages/|data/)' 'changed code or data before an accepted plan'
Expect-NoChange $changed '^specs/0013-.*\.(amendment|erratum)' 'wrote a new amendment file'
Finish
