<#
.SYNOPSIS
  One-command check that the app starts and runs on the Fairphone (plan 0002 T2).

.DESCRIPTION
  Fails if the Fairphone (model FP5) isn't connected, the app process dies, the app logs a crash, or it read no step
  total from Health Connect. Prints the step totals read since launch and saves a screenshot. -Install first installs
  the release APK from `scripts\check.ps1 -Release`, and refuses an APK older than the source. Restarts the app
  (force-stop); the game state is saved, so nothing is lost.
#>
param(
  [switch]$Install,
  [int]$WaitSeconds = 6,
  [string]$OutDir = (Join-Path $env:TEMP 'walk-sun-goose-smoke')
)

# Native tools (adb) write progress to stderr; with 'Stop', PowerShell 5.1 would treat that as fatal. Exit codes
# and output are checked explicitly instead.
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$adbExe = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
$package = 'com.zkalf.walkingrpg'

function Fail([string]$message) {
  Write-Host "SMOKE FAILED: $message" -ForegroundColor Red
  exit 1
}

# The test device is the Fairphone 5; with several devices attached, talk to it explicitly.
$fp5 = @(& $adbExe devices -l | Where-Object { $_ -match '\sdevice\s' -and $_ -match 'model:FP5' })
if (-not $fp5.Count) { Fail 'the Fairphone (FP5) is not connected (USB debugging on and this PC allowed?)' }
$serial = ($fp5[0] -split '\s+')[0]
function Adb { & $adbExe -s $serial @args }

if ($Install) {
  $apk = Join-Path $root 'app\build\app\outputs\flutter-apk\app-release.apk'
  if (-not (Test-Path $apk)) { Fail 'no release APK; run scripts\check.ps1 -Release first' }
  $newestSource = Get-ChildItem -Recurse -File -Path `
    "$root\app\lib", "$root\app\android\app\src", "$root\app\pubspec.yaml", `
    "$root\packages\game_core\lib", "$root\packages\game_core\data" |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($newestSource.LastWriteTime -gt (Get-Item $apk).LastWriteTime) {
    Fail "release APK is older than $($newestSource.Name); run scripts\check.ps1 -Release first"
  }
  Adb install -r $apk | Out-Null
  if ($LASTEXITCODE -ne 0) { Fail 'install failed' }
  Write-Host 'Installed release APK.'
}

# Only look at log lines from this launch (phone clock), without clearing the phone's log.
$since = "$(Adb shell "date '+%m-%d %H:%M:%S.000'")".Trim()
if (-not $since) { Fail 'could not read the phone clock' }
Adb shell am force-stop $package
Adb shell am start -n "$package/.MainActivity" | Out-Null
Start-Sleep -Seconds $WaitSeconds

$appPid = "$(Adb shell pidof $package)".Trim()
$log = @(Adb logcat -d -v time -T $since)

# Process ids this app had since launch (including one that crashed and is gone).
$pids = @($log | ForEach-Object { if ($_ -match "Start proc (\d+):$([regex]::Escape($package))") { $Matches[1] } })
if ($appPid) { $pids += $appPid }
$ours = if ($pids.Count) { $log | Where-Object { $line = $_; $pids | Where-Object { $line -match "\(\s*$_\)" } } } else { @() }

$crash = @($ours | Where-Object { $_ -match 'E/flutter|E/AndroidRuntime|FATAL' }) +
  @($log | Where-Object { $_ -match "Process: $([regex]::Escape($package))|Fatal signal .*kalf\.walkingrpg" })
$steps = @($ours | Where-Object { $_ -match 'FLUTTER_HEALTH::SUCCESS\(\s*\d+\): returning \d+ steps' })
$healthErrors = @($ours | Where-Object { $_ -match 'FLUTTER_HEALTH::ERROR' })

New-Item -ItemType Directory -Force $OutDir | Out-Null
$shot = Join-Path $OutDir ("smoke-{0:yyyyMMdd-HHmmss}.png" -f (Get-Date))
Adb shell screencap -p /sdcard/smoke.png | Out-Null
Adb pull /sdcard/smoke.png $shot 2>&1 | Out-Null
Adb shell rm /sdcard/smoke.png | Out-Null
$awake = "$(Adb shell dumpsys power)" -match 'mWakefulness=Awake'

Write-Host 'Health Connect step totals read since launch:'
if ($steps) { $steps | ForEach-Object { Write-Host "  $_" } } else { Write-Host '  (none)' }
if (Test-Path $shot) {
  Write-Host "Screenshot: $shot$(if (-not $awake) { ' (screen is off: it will be black)' })"
} else {
  Write-Host 'Screenshot: could not be saved (not a failure).' -ForegroundColor Yellow
}

if ($crash) {
  $crash | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
  Fail 'crash logged'
}
if (-not $appPid) { Fail 'app process is not running' }
if ($healthErrors) {
  $healthErrors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
  Fail 'Health Connect reported an error'
}
if (-not $steps) { Fail 'the app read no step total from Health Connect' }
Write-Host 'SMOKE PASSED' -ForegroundColor Green
