<#
.SYNOPSIS
  The owner's merge of a pull request (plan 0009 D1).

.DESCRIPTION
  Shows the pull request (title, description, changed files) and its check, and squash-merges it only when the
  check passed. Merging is the owner's approval; the production gate blocks Claude from running this.

  From the Claude Code prompt: ! powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/merge.ps1 <number>
#>
param([Parameter(Mandatory)][int]$Number)

$ErrorActionPreference = 'Continue'
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + $env:Path
$repo = 'Zkalf/Itheros'

function Fail([string]$message) {
  Write-Host "NOT MERGED: $message" -ForegroundColor Red
  exit 1
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Fail 'the GitHub CLI (gh) is not installed' }

$pr = & gh pr view $Number --repo $repo --json title,body,state,files,url,headRefName | ConvertFrom-Json
if (-not $pr) { Fail "no pull request #$Number" }
if ($pr.state -ne 'OPEN') { Fail "#$Number is $($pr.state.ToLower())" }

Write-Host "`n#$Number $($pr.title)" -ForegroundColor Cyan
Write-Host $pr.url
Write-Host "`n$($pr.body)"
Write-Host "`nChanged files:" -ForegroundColor Cyan
$pr.files | ForEach-Object { Write-Host "  $($_.path)  (+$($_.additions) -$($_.deletions))" }

Write-Host "`nCheck:" -ForegroundColor Cyan
& gh pr checks $Number --repo $repo
switch ($LASTEXITCODE) {
  0 { }
  8 { Fail 'the check is still running; try again in a few minutes' }
  default { Fail 'the check failed or is missing; ask Claude to fix it' }
}

# From inside the repo (no --repo), so gh also updates the PC: off the merged branch, onto main, pulled.
$main = Split-Path -Parent $PSScriptRoot
Push-Location $main
& gh pr merge $Number --squash --delete-branch
Pop-Location
# GitHub's state decides: gh can report an error after the merge, when it cannot delete a local branch.
$state = & gh pr view $Number --repo $repo --json state --jq .state
if ($state -ne 'MERGED') { Fail 'GitHub refused the merge' }
Write-Host "`nMERGED #$Number" -ForegroundColor Green

# The worktree of the change (scripts\new-worktree.ps1) and its local branch, if they are still there. A worktree
# with uncommitted changes stays, with a note.
$branch = $pr.headRefName
$lines = @(& git -C $main worktree list --porcelain)
for ($i = 0; $i -lt $lines.Count; $i++) {
  if ($lines[$i] -eq "branch refs/heads/$branch") {
    $wt = ($lines[$i - 2] -replace '^worktree ', '') -replace '/', '\'
    & git -C $main worktree remove $wt
    if ($LASTEXITCODE -eq 0) { Write-Host "Removed the worktree $wt" }
    else { Write-Host "Kept the worktree ${wt}: it has changes. Remove it by hand when you are done." -ForegroundColor Yellow }
  }
}
& git -C $main show-ref --verify --quiet "refs/heads/$branch"
if ($LASTEXITCODE -eq 0) {
  & git -C $main branch -D $branch
}
