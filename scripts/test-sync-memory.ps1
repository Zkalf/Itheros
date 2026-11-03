<#
.SYNOPSIS
  The cases of sync-memory.ps1: -Push and -Pull mirror the memory folder, back up the target first, and refuse
  when there is nothing to copy.

.DESCRIPTION
  Uses temporary folders (-Local, -Remote and ITHEROS_MEMORY_BACKUPS), never the real memory or OneDrive. Exit 1 on
  any wrong case.
#>
$ErrorActionPreference = 'Stop'
$bad = 0
$cases = 0
function Case([string]$what, [bool]$ok) {
  $script:cases++
  if (-not $ok) { Write-Host "WRONG: $what" -ForegroundColor Red; $script:bad++ }
}

$base = Join-Path ([IO.Path]::GetTempPath()) "itheros-memory-test-$PID"
if (Test-Path $base) { Remove-Item -Recurse -Force $base }
$local = Join-Path $base 'local'
$remote = Join-Path $base 'remote'
$env:ITHEROS_MEMORY_BACKUPS = Join-Path $base 'backups'
New-Item -ItemType Directory -Force $local | Out-Null
Set-Content (Join-Path $local 'MEMORY.md') 'index'
Set-Content (Join-Path $local 'a.md') 'a one'
Set-Content (Join-Path $local 'b.md') 'b one'

function Sync([string]$how) {
  $p = @{ Local = $local; Remote = $remote }
  $p[$how] = $true
  & "$PSScriptRoot\sync-memory.ps1" @p *> $null
  return $LASTEXITCODE
}
function Text([string]$path) { (Get-Content -Raw $path).Trim() }

# Push into an empty OneDrive folder.
Case 'push: exit 0' ((Sync 'Push') -eq 0)
Case 'push: the files are in OneDrive' ((Text (Join-Path $remote 'a.md')) -eq 'a one' -and (Test-Path (Join-Path $remote 'MEMORY.md')))
Case 'push: OneDrive says where it came from' ((Text (Join-Path $remote '_pushed.txt')) -match "pushed from $env:COMPUTERNAME")

# The other PC changes a, adds c and removes b; then this PC pulls.
Set-Content (Join-Path $remote 'a.md') 'a two'
Set-Content (Join-Path $remote 'c.md') 'c one'
Remove-Item (Join-Path $remote 'b.md')
Case 'pull: exit 0' ((Sync 'Pull') -eq 0)
Case 'pull: a changed file comes over' ((Text (Join-Path $local 'a.md')) -eq 'a two')
Case 'pull: a new file comes over' ((Text (Join-Path $local 'c.md')) -eq 'c one')
Case 'pull: a removed file goes' (-not (Test-Path (Join-Path $local 'b.md')))
Case 'pull: the stamp stays in OneDrive only' (-not (Test-Path (Join-Path $local '_pushed.txt')))
$backup = Get-ChildItem $env:ITHEROS_MEMORY_BACKUPS -Directory -Filter 'local-*' | Select-Object -First 1
Case 'pull: the old memory is backed up first' ($backup -and (Text (Join-Path $backup.FullName 'b.md')) -eq 'b one')

# Nothing to copy: an empty source.
Remove-Item -Recurse -Force $remote
New-Item -ItemType Directory -Force $remote | Out-Null
Case 'pull: an empty OneDrive folder is refused' ((Sync 'Pull') -eq 1)
Case 'pull: the refusal leaves the memory as it was' ((Text (Join-Path $local 'a.md')) -eq 'a two')

# Neither or both switches.
& "$PSScriptRoot\sync-memory.ps1" -Local $local -Remote $remote *> $null
Case 'no direction is refused' ($LASTEXITCODE -eq 1)

Remove-Item Env:\ITHEROS_MEMORY_BACKUPS
Remove-Item -Recurse -Force $base
if ($bad) { Write-Host "$bad of $cases sync-memory cases wrong" -ForegroundColor Red; exit 1 }
Write-Host "sync-memory: $cases cases right"
exit 0
