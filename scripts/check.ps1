<#
.SYNOPSIS
  The one command that proves the build is green (plan 0001).

.DESCRIPTION
  Default: format check, analyze and tests for every Dart/Flutter package.
  -Release: also builds the owner's release APK (with test walk) and runs
  scripts\apk-check.ps1 on it: no INTERNET permission, no cloud backup (spec 0001:
  health data stays on the device; spec 0007 §6).
  -Root: check another checkout (the eval grader checks throwaway worktrees with
  this repo's copy of the script, so an agent can't weaken the check it is graded by).

  In Claude Code run it directly (.\scripts\check.ps1): a nested
  `powershell -File` can't be auto-approved by permission rules.
#>
param([switch]$Release, [string]$Root)

$ErrorActionPreference = 'Stop'
$root = if ($Root) { (Resolve-Path $Root).Path } else { Split-Path -Parent $PSScriptRoot }
$failed = @()

# Fresh shells may predate the tool installs; make sure they are on PATH. Keep the current PATH too: in CI the
# setup steps add Flutter and Java to this process only.
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + $env:Path
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
  # The owner build (spec 0007 §4): test walk on. Friends' builds come from scripts\release.ps1.
  Step 'app: build release APK' $app { flutter build apk --release --dart-define=TEST_WALK=true }
  Step 'app: APK check (no INTERNET, no cloud backup)' $app {
    & "$PSScriptRoot\apk-check.ps1" "$app\build\app\outputs\flutter-apk\app-release.apk"
  }
}

# Plan 0002 T5: warn (don't fail) when the Claude setup changed since the last full eval run.
$latest = "$root\evals\results\latest.json"
$hash = & "$PSScriptRoot\config-hash.ps1" -Root $root
$evaluated = if (Test-Path $latest) { (Get-Content -Raw $latest | ConvertFrom-Json).configHash }
if ($hash -ne $evaluated) {
  Write-Host "`nWARNING: Claude setup $hash has no full eval run (last: $(if ($evaluated) { $evaluated } else { 'none' }))." -ForegroundColor Yellow
  Write-Host '         Commit, then run .\evals\run.ps1 (evals/README.md).' -ForegroundColor Yellow
}

if ($failed.Count) {
  Write-Host "`nCHECK FAILED: $($failed -join ', ')" -ForegroundColor Red
  exit 1
}
Write-Host "`nCHECK PASSED" -ForegroundColor Green
