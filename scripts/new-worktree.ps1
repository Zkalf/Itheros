<#
.SYNOPSIS
  A folder of its own for one change: a git worktree on a new branch from the latest main (owner, 2026-10-25).

.DESCRIPTION
  Several sessions can work on this computer at once, each in its own worktree. The main folder stays on main for
  the owner's release builds and installs (only it has the release key). The new folder sits beside the main one
  and is named after the branch: fix/eat-without-meal gives ..\walk-sun-goose-fix-eat-without-meal.
  scripts\merge.sh removes the worktree and the branch when the owner merges its pull request.

.EXAMPLE
  .\scripts\new-worktree.ps1 fix/eat-without-meal
#>
param([Parameter(Mandatory)][string]$Branch)

$ErrorActionPreference = 'Stop'
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')

# The main worktree is the first one git lists.
$main = ((git worktree list --porcelain | Select-Object -First 1) -replace '^worktree ', '') -replace '/', '\'
$folder = Join-Path (Split-Path -Parent $main) ("$(Split-Path -Leaf $main)-" + ($Branch -replace '[\\/]', '-'))

if (Test-Path $folder) { throw "$folder exists already. Pick another branch name, or remove that worktree." }
git -C $main show-ref --verify --quiet "refs/heads/$Branch"
if ($LASTEXITCODE -eq 0) { throw "Branch $Branch exists already. Pick another name." }

git -C $main fetch --quiet origin
if ($LASTEXITCODE -ne 0) { throw 'git fetch failed' }
# A branch of that name on GitHub belongs to other work; a new one from main could never push over it.
git -C $main ls-remote --exit-code --heads origin $Branch | Out-Null
if ($LASTEXITCODE -eq 0) { throw "Branch $Branch exists on GitHub already. Pick another name." }
git -C $main worktree add --quiet $folder -b $Branch origin/main
if ($LASTEXITCODE -ne 0) { throw 'git worktree add failed' }

# The packages, so that format, analyze and single tests work at once.
Get-ChildItem "$folder\packages" -Directory | ForEach-Object {
  Push-Location $_.FullName
  try { dart pub get | Out-Null; if ($LASTEXITCODE -ne 0) { throw "dart pub get failed in $($_.Name)" } }
  finally { Pop-Location }
}
Push-Location "$folder\app"
try { flutter pub get | Out-Null; if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed in app' } }
finally { Pop-Location }

Write-Host "Worktree: $folder"
Write-Host "Branch:   $Branch (from origin/main)"
Write-Host "Run its scripts from it: .\scripts\check.ps1 with the shell in $folder, else & `"$folder\scripts\check.ps1`"."
Write-Host "Push with the shell in the worktree and the branch named: git push -u origin $Branch"
