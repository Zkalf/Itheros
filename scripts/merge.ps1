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

$pr = & gh pr view $Number --repo $repo --json title,body,state,files,url | ConvertFrom-Json
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
Push-Location (Split-Path -Parent $PSScriptRoot)
& gh pr merge $Number --squash --delete-branch
$merged = $LASTEXITCODE
Pop-Location
if ($merged -ne 0) { Fail 'GitHub refused the merge' }
Write-Host "`nMERGED #$Number" -ForegroundColor Green
