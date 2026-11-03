<#
.SYNOPSIS
  Copies the release notes (releases\*.md) into app\assets\releases\ (plan 0029), and joins the notes of the next
  release into one next.md there (spec 0018 amendment 2).

.DESCRIPTION
  The app shows the notes in the game (spec 0018). Flutter puts no file from outside app\ into the APK, so the
  notes go in as a copy. The copy is not committed (.gitignore): check.ps1, test.ps1 and release.ps1 make it
  before the tests and the build. Old copies go first, so a renamed or removed file does not stay.
  The copy's next.md holds releases\next.md (if it exists), then each small file of releases\next\ by name: each
  change adds its own small file, so pull requests never clash in the notes. With neither, the app has no next.md.
  -Root: the checkout to copy in (check.ps1 -Root passes its own).
#>
param([string]$Root)

$ErrorActionPreference = 'Stop'
$root = if ($Root) { (Resolve-Path $Root).Path } else { Split-Path -Parent $PSScriptRoot }
$to = Join-Path $root 'app\assets\releases'
New-Item -ItemType Directory -Force $to | Out-Null
Get-ChildItem $to -Filter '*.md' | Remove-Item -Force
Get-ChildItem (Join-Path $root 'releases') -Filter '*.md' -File | Where-Object { $_.Name -ne 'next.md' } |
  Copy-Item -Destination $to

$parts = @()
$next = Join-Path $root 'releases\next.md'
if (Test-Path $next) { $parts += [IO.File]::ReadAllText($next).Trim() }
$small = Join-Path $root 'releases\next'
if (Test-Path $small) {
  Get-ChildItem $small -Filter '*.md' -File | Sort-Object Name | ForEach-Object {
    $parts += [IO.File]::ReadAllText($_.FullName).Trim()
  }
}
$parts = @($parts | Where-Object { $_ })
if ($parts.Count) {
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText((Join-Path $to 'next.md'), (($parts -join "`n") + "`n"), $utf8)
}
exit 0
