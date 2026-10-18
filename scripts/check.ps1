<#
.SYNOPSIS
  The one command that proves the build is green (plan 0001).

.DESCRIPTION
  Default: format check, analyze and tests for every Dart/Flutter package.
  -Release: also builds the release APK and fails if it requests the INTERNET
  permission (spec 0001: health data stays on the device).
  -Root: check another checkout (the eval grader checks throwaway worktrees with
  this repo's copy of the script, so an agent can't weaken the check it is graded by).

  In Claude Code run it directly (.\scripts\check.ps1): a nested
  `powershell -File` can't be auto-approved by permission rules.
#>
param([switch]$Release, [string]$Root)

$ErrorActionPreference = 'Stop'
$root = if ($Root) { (Resolve-Path $Root).Path } else { Split-Path -Parent $PSScriptRoot }
$failed = @()

# Fresh shells may predate the tool installs; make sure they are on PATH.
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
if ($env:JAVA_HOME) { $env:JAVA_HOME = $env:JAVA_HOME.TrimEnd('\') }
if (-not $env:ANDROID_HOME) { $env:ANDROID_HOME = [Environment]::GetEnvironmentVariable('ANDROID_HOME', 'User') }

function Step([string]$name, [string]$dir, [scriptblock]$block) {
  Write-Host "==> $name" -ForegroundColor Cyan
  Push-Location $dir
  try {
    & $block
    if ($LASTEXITCODE -ne 0) { throw "exit code $LASTEXITCODE" }
  } catch {
    Write-Host "FAILED: $name ($_)" -ForegroundColor Red
    $script:failed += $name
  } finally {
    Pop-Location
  }
}

# Pure-Dart packages.
Get-ChildItem "$root\packages" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  $pkg = $_.FullName; $n = $_.Name
  Step "${n}: pub get"  $pkg { dart pub get | Out-Null }
  Step "${n}: format"   $pkg { dart format --output=none --set-exit-if-changed . }
  Step "${n}: analyze"  $pkg { dart analyze --fatal-infos }
  if (Test-Path "$pkg\test") { Step "${n}: test" $pkg { dart test } }
}

# Flutter app.
$app = "$root\app"
Step 'app: pub get' $app { flutter pub get | Out-Null }
Step 'app: format'  $app { dart format --output=none --set-exit-if-changed @('lib', 'test' | Where-Object { Test-Path $_ }) }
Step 'app: analyze' $app { flutter analyze --fatal-infos }
if (Test-Path "$app\test") { Step 'app: test' $app { flutter test } }

if ($Release) {
  Step 'app: build release APK' $app { flutter build apk --release }
  Step 'app: APK must not request INTERNET' $app {
    $apk = "$app\build\app\outputs\flutter-apk\app-release.apk"
    $aapt2 = Get-ChildItem "$env:ANDROID_HOME\build-tools\*\aapt2.exe" | Sort-Object FullName | Select-Object -Last 1
    if (-not $aapt2) { throw 'aapt2 not found in ANDROID_HOME\build-tools' }
    $perms = & $aapt2.FullName dump permissions $apk
    if ($LASTEXITCODE -ne 0) { throw 'aapt2 dump permissions failed' }
    $perms | Select-String 'uses-permission' | ForEach-Object { Write-Host "    $($_.Line.Trim())" }
    if ($perms | Select-String "android.permission.INTERNET'") {
      throw 'release APK requests android.permission.INTERNET'
    }
    $global:LASTEXITCODE = 0
  }
}

if ($failed.Count) {
  Write-Host "`nCHECK FAILED: $($failed -join ', ')" -ForegroundColor Red
  exit 1
}
Write-Host "`nCHECK PASSED" -ForegroundColor Green
