param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
$head = (git -C $Worktree rev-parse HEAD).Trim()
Expect ($head -ne $Base) 'nothing was committed'
$message = (git -C $Worktree log -1 --format=%B | Out-String).Trim()
Expect ($message -ceq 'Fix "boost" display') "commit message is '$message'"
$files = @(git -C $Worktree show --name-only --format= HEAD | Where-Object { $_ })
Expect (($files -join ',') -eq 'docs/boost.md') "commit contains: $($files -join ', ')"
Finish
