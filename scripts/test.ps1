<#
.SYNOPSIS
  Runs one test file (optionally one test by name) from the repo root.

.DESCRIPTION
  Finds the package that owns the file (the nearest pubspec.yaml) and runs `flutter test` for the app or
  `dart test` for a pure-Dart package, so Claude doesn't need a chained `Push-Location ...; dart test ...`
  command (chains can't be auto-approved; plan 0002 baseline eval run).

.EXAMPLE
  .\scripts\test.ps1 packages\game_core\test\refund_test.dart
.EXAMPLE
  .\scripts\test.ps1 app\test\ui_test.dart -Name 'tapping a destination'
#>
param([Parameter(Mandatory)][string]$Path, [string]$Name)

$ErrorActionPreference = 'Stop'
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')

$file = (Resolve-Path $Path).Path
$pkg = Split-Path -Parent $file
while ($pkg -and -not (Test-Path "$pkg\pubspec.yaml")) { $pkg = Split-Path -Parent $pkg }
if (-not $pkg) { throw "no pubspec.yaml above $Path" }

$rel = $file.Substring($pkg.Length + 1)
$testArgs = @($rel) + $(if ($Name) { @('--plain-name', $Name) } else { @() })
$isFlutter = Select-String -Quiet -Path "$pkg\pubspec.yaml" -Pattern '^\s+sdk: flutter'
Push-Location $pkg
try {
  if ($isFlutter) { flutter test @testArgs } else { dart test @testArgs }
  exit $LASTEXITCODE
} finally {
  Pop-Location
}
