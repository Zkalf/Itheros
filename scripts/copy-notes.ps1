<#
.SYNOPSIS
  Copies the release notes (releases\*.md) into app\assets\releases\ (plan 0029).

.DESCRIPTION
  The app shows the notes in the game (spec 0018). Flutter puts no file from outside app\ into the APK, so the
  notes go in as a copy. The copy is not committed (.gitignore): check.ps1, test.ps1 and release.ps1 make it
  before the tests and the build. Old copies go first, so a renamed or removed file does not stay.
  -Root: the checkout to copy in (check.ps1 -Root passes its own).
#>
param([string]$Root)

$ErrorActionPreference = 'Stop'
$root = if ($Root) { (Resolve-Path $Root).Path } else { Split-Path -Parent $PSScriptRoot }
$to = Join-Path $root 'app\assets\releases'
New-Item -ItemType Directory -Force $to | Out-Null
Get-ChildItem $to -Filter '*.md' | Remove-Item -Force
Copy-Item (Join-Path $root 'releases\*.md') $to
exit 0
