<#
.SYNOPSIS
  Checks one APK file against the privacy and signing rules (spec 0001, spec 0007).

.DESCRIPTION
  Fails if the APK requests android.permission.INTERNET or allows cloud backup.
  -RequireReleaseKey: also fails unless the APK is signed with the release key, whose
  fingerprint is committed in releases\signing-cert.txt. The release command uses it on
  the exact file it publishes.

  In Claude Code run it directly (.\scripts\apk-check.ps1 <apk>).
#>
param(
  [Parameter(Mandatory)][string]$Apk,
  [switch]$RequireReleaseKey
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $env:ANDROID_HOME) { $env:ANDROID_HOME = [Environment]::GetEnvironmentVariable('ANDROID_HOME', 'User') }
if ($env:JAVA_HOME) { $env:JAVA_HOME = $env:JAVA_HOME.TrimEnd('\') }

function Fail([string]$message) {
  Write-Host "APK CHECK FAILED: $message" -ForegroundColor Red
  exit 1
}

if (-not (Test-Path $Apk)) { Fail "no such file: $Apk" }
$tools = Get-ChildItem "$env:ANDROID_HOME\build-tools" -Directory | Sort-Object Name | Select-Object -Last 1
if (-not $tools) { Fail 'no ANDROID_HOME\build-tools' }
$aapt2 = Join-Path $tools.FullName 'aapt2.exe'

$perms = & $aapt2 dump permissions $Apk
if ($LASTEXITCODE -ne 0) { Fail 'aapt2 dump permissions failed' }
$perms | Select-String 'uses-permission' | ForEach-Object { Write-Host "    $($_.Line.Trim())" }
if ($perms | Select-String "android.permission.INTERNET'") { Fail 'the APK requests android.permission.INTERNET' }

# allowBackup must be present and false: the save holds daily step counts.
$manifest = & $aapt2 dump xmltree --file AndroidManifest.xml $Apk
if ($LASTEXITCODE -ne 0) { Fail 'aapt2 dump xmltree failed' }
$backup = $manifest | Select-String 'android:allowBackup'
if (-not $backup -or $backup.Line -notmatch '=false|0x0\b') { Fail 'the APK allows cloud backup (allowBackup must be false)' }
Write-Host '    allowBackup=false'

if ($RequireReleaseKey) {
  $expected = (Get-Content "$root\releases\signing-cert.txt" | Where-Object { $_ -match '^[0-9a-f]{64}$' } | Select-Object -First 1)
  if (-not $expected) { Fail 'no fingerprint in releases\signing-cert.txt' }
  $certs = & (Join-Path $tools.FullName 'apksigner.bat') verify --print-certs $Apk
  if ($LASTEXITCODE -ne 0) { Fail 'apksigner verify failed' }
  $actual = ($certs | Select-String 'certificate SHA-256 digest: ([0-9a-f]{64})').Matches | ForEach-Object { $_.Groups[1].Value }
  if (@($actual).Count -ne 1 -or $actual -ne $expected) { Fail "signed with $actual, not the release key $expected" }
  Write-Host '    signed with the release key'
}

Write-Host 'APK CHECK PASSED' -ForegroundColor Green
