<#
.SYNOPSIS
  The pace report (plan 0066, issue #185): a bigger sim now and then.

.DESCRIPTION
  Runs packages\game_core\tool\pace_report.dart: the mixed walker and the fighter at 5,000 steps a day on -Seeds
  seeds (32 by default), four runs per seed in parallel isolates. Prints one table and puts it at the top of
  docs\sim\pace-reports.md, with the change since the last report. It never fails on a number.
  It takes the CPU for a few minutes: do not run it while a check runs.

.EXAMPLE
  .\scripts\pace-report.ps1
.EXAMPLE
  .\scripts\pace-report.ps1 -Seeds 8 -File $env:TEMP\pace-copy.md
#>
param([int]$Seeds = 32, [string]$File)

$ErrorActionPreference = 'Stop'
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + $env:Path

$root = Split-Path -Parent $PSScriptRoot
if (-not $File) { $File = Join-Path $root 'docs\sim\pace-reports.md' }
$File = [IO.Path]::GetFullPath($File)
$commit = (git -C $root rev-parse --short HEAD).Trim()
if (git -C $root status --porcelain -- packages) { $commit = "$commit with changes" }

$watch = [Diagnostics.Stopwatch]::StartNew()
Push-Location (Join-Path $root 'packages\game_core')
try {
  dart run tool/pace_report.dart --seeds $Seeds --commit $commit --file $File
  $code = $LASTEXITCODE
} finally {
  Pop-Location
}
Write-Host ("Pace report: {0} s" -f [int]$watch.Elapsed.TotalSeconds)
exit $code
