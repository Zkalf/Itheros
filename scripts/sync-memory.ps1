<#
.SYNOPSIS
  Copies Claude's memory of this project between this PC and OneDrive, by hand, when the owner changes PC.

.DESCRIPTION
  The memory lives on each PC (%USERPROFILE%\.claude\projects\<repo path>\memory\). Nothing syncs by itself.
  -Push: before you leave this PC, copy its memory to OneDrive\Itheros\claude-memory\.
  -Pull: on the other PC, copy the memory from OneDrive into that PC's memory folder.
  The copy mirrors the folder: a memory file that the source no longer has goes from the target too. Before it
  changes anything, the script backs the target up to %USERPROFILE%\.claude\memory-backups\, so a wrong direction
  loses nothing. It names the files it adds, changes and removes.
  The folder name follows the path of the main folder of the repo, so a worktree or another user name works too.
  -Local and -Remote: other folders, for the test cases (scripts\test-sync-memory.ps1).
#>
param(
  [switch]$Push,
  [switch]$Pull,
  [string]$Local,
  [string]$Remote
)

$ErrorActionPreference = 'Stop'
if ($Push -eq $Pull) {
  Write-Host 'Say -Push (this PC -> OneDrive) or -Pull (OneDrive -> this PC).' -ForegroundColor Red
  exit 1
}

if (-not $Local) {
  # The main folder of the repo, also from a worktree: Claude names the memory folder after it.
  $common = (& git.exe -C $PSScriptRoot rev-parse --path-format=absolute --git-common-dir).Trim()
  $main = (Split-Path -Parent $common) -replace '/', '\'
  $Local = Join-Path $env:USERPROFILE ".claude\projects\$($main -replace '[:\\]', '-')\memory"
}
if (-not $Remote) {
  if (-not $env:OneDrive) {
    Write-Host 'OneDrive is not set up on this PC (no %OneDrive%).' -ForegroundColor Red
    exit 1
  }
  $Remote = Join-Path $env:OneDrive 'Itheros\claude-memory'
}

$from, $to = if ($Push) { $Local, $Remote } else { $Remote, $Local }
if (-not (Test-Path $from) -or -not (Get-ChildItem $from -Filter '*.md' -File)) {
  Write-Host "Nothing to copy: no memory in $from" -ForegroundColor Red
  exit 1
}

# When and where the OneDrive copy came from.
$stamp = '_pushed.txt'
if ($Pull -and (Test-Path (Join-Path $from $stamp))) {
  Write-Host "The OneDrive copy: $((Get-Content -Raw (Join-Path $from $stamp)).Trim())"
}

# Back up the target before it changes.
if (Test-Path $to) {
  $backup = Join-Path $env:USERPROFILE (".claude\memory-backups\{0}-{1}" -f
    $(if ($Push) { 'onedrive' } else { 'local' }), (Get-Date).ToString('yyyyMMdd-HHmmss', [Globalization.CultureInfo]::InvariantCulture))
  if ($env:ITHEROS_MEMORY_BACKUPS) { $backup = Join-Path $env:ITHEROS_MEMORY_BACKUPS (Split-Path -Leaf $backup) }
  New-Item -ItemType Directory -Force $backup | Out-Null
  Copy-Item (Join-Path $to '*') $backup -Recurse -Force
  Write-Host "Backup of $to in $backup"
} else {
  New-Item -ItemType Directory -Force $to | Out-Null
}

# Mirror: add and change from the source, remove what the source no longer has.
$source = @{}
Get-ChildItem $from -File | Where-Object { $_.Name -ne $stamp } | ForEach-Object { $source[$_.Name] = $_ }
$added = @(); $changed = @(); $removed = @()
foreach ($name in $source.Keys) {
  $target = Join-Path $to $name
  if (-not (Test-Path $target)) {
    $added += $name
  } elseif ((Get-FileHash $target).Hash -ne (Get-FileHash $source[$name].FullName).Hash) {
    $changed += $name
  } else {
    continue
  }
  Copy-Item $source[$name].FullName $target -Force
}
Get-ChildItem $to -File | Where-Object { $_.Name -ne $stamp -and -not $source.ContainsKey($_.Name) } | ForEach-Object {
  $removed += $_.Name
  Remove-Item $_.FullName -Force
}

if ($Push) {
  $when = (Get-Date).ToString('yyyy-MM-dd HH:mm', [Globalization.CultureInfo]::InvariantCulture)
  Set-Content -Encoding UTF8 (Join-Path $to $stamp) "pushed from $env:COMPUTERNAME on $when"
}

foreach ($n in $added | Sort-Object) { Write-Host "  added    $n" }
foreach ($n in $changed | Sort-Object) { Write-Host "  changed  $n" }
foreach ($n in $removed | Sort-Object) { Write-Host "  removed  $n" }
$verb = if ($Push) { 'Pushed to OneDrive' } else { 'Pulled from OneDrive' }
Write-Host "$verb ($($added.Count) added, $($changed.Count) changed, $($removed.Count) removed): $to" -ForegroundColor Green
exit 0
