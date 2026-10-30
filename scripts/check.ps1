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
  At most two checks at a time on this computer: a third one waits for a turn
  (scripts\check-turn.ps1), so sessions in several worktrees don't run the PC out of memory.
  The pacing sims (game_core tests with the tag `pacing`) run only when the change touches packages\ (the game
  rules, data\*.json, the sim), compared with origin/main, or with -Pacing. release.ps1 passes -Pacing. When git
  cannot tell what changed, they run. Each step prints its time.

  In Claude Code run it directly (.\scripts\check.ps1): a nested
  `powershell -File` can't be auto-approved by permission rules.
#>
param([switch]$Release, [string]$Root, [switch]$Pacing)

$ErrorActionPreference = 'Stop'
$root = if ($Root) { (Resolve-Path $Root).Path } else { Split-Path -Parent $PSScriptRoot }
$failed = @()

# Fresh shells may predate the tool installs; make sure they are on PATH. Keep the current PATH too: in CI the
# setup steps add Flutter and Java to this process only.
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + $env:Path
if ($env:JAVA_HOME) { $env:JAVA_HOME = $env:JAVA_HOME.TrimEnd('\') }
if (-not $env:ANDROID_HOME) { $env:ANDROID_HOME = [Environment]::GetEnvironmentVariable('ANDROID_HOME', 'User') }

# At most two full checks at a time on this computer: each uses a lot of memory (scripts\check-turn.ps1).
. "$PSScriptRoot\check-turn.ps1"
# The turn goes back in finally, so an error or Ctrl+C cannot keep it while this shell stays open.
Enter-CheckTurn -Folder $root
try {
  $total = [Diagnostics.Stopwatch]::StartNew()
  function Step([string]$name, [string]$dir, [scriptblock]$block) {
    Write-Host "==> $name" -ForegroundColor Cyan
    $time = [Diagnostics.Stopwatch]::StartNew()
    Push-Location $dir
    try {
      & $block
      if ($LASTEXITCODE -ne 0) { throw "exit code $LASTEXITCODE" }
    } catch {
      Write-Host "FAILED: $name ($_)" -ForegroundColor Red
      $script:failed += $name
    } finally {
      Pop-Location
      Write-Host ("    {0:0} s" -f $time.Elapsed.TotalSeconds) -ForegroundColor DarkGray
    }
  }

  # The pacing sims run when the change touches packages\, compared with origin/main (on main itself: with the
  # commit before). Committed, uncommitted and new files count. Any doubt runs them.
  function Test-PacingNeeded {
    if ($Pacing) { return $true }
    try {
      $head = "$(git -C $root rev-parse HEAD)".Trim()
      $base = "$(git -C $root merge-base HEAD origin/main)".Trim()
      if ($LASTEXITCODE -ne 0 -or -not $base) { return $true }
      # On main itself with nothing uncommitted: the last commit is the change. A new branch with no commit of its
      # own yet compares its uncommitted files with HEAD.
      if ($base -eq $head -and -not "$(git -C $root status --porcelain)") { $base = "$(git -C $root rev-parse HEAD~1)".Trim() }
      if ($LASTEXITCODE -ne 0 -or -not $base) { return $true }
      $changed = @(git -C $root diff --name-only $base)
      if ($LASTEXITCODE -ne 0) { return $true }
      $changed += @(git -C $root ls-files --others --exclude-standard)
      return [bool]($changed | Where-Object { $_ -like 'packages/*' })
    } catch {
      return $true
    }
  }
  $runPacing = Test-PacingNeeded
  if ($runPacing) {
    Write-Host '==> pacing sims: on (a change in packages\, or -Pacing)' -ForegroundColor Cyan
  } else {
    Write-Host '==> pacing sims: off (no change in packages\; release.ps1 always runs them)' -ForegroundColor Cyan
  }

  # The production gate (plan 0009): what it blocks and what it lets through.
  Step 'gate: test cases' $root { & "$PSScriptRoot\test-gate.ps1" }
  Step 'check turn: test cases' $root { & "$PSScriptRoot\test-check-turn.ps1" }

  # Pure-Dart packages.
  Get-ChildItem "$root\packages" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $pkg = $_.FullName; $n = $_.Name
    Step "${n}: pub get"  $pkg { dart pub get | Out-Null }
    Step "${n}: format"   $pkg { dart format --output=none --set-exit-if-changed . }
    Step "${n}: analyze"  $pkg { dart analyze --fatal-infos }
    # Failing tests only: the full list is long enough that a cut-off tool output hid the one failure (eval E21).
    if (Test-Path "$pkg\test") {
      if ($runPacing) { Step "${n}: test" $pkg { dart test -r failures-only } }
      else { Step "${n}: test (no pacing sims)" $pkg { dart test -r failures-only -x pacing } }
    }
  }

  # Flutter app.
  $app = "$root\app"
  # The release notes come into the app as a copy (plan 0029), before the tests and the build.
  Step 'app: copy the release notes' $root { & "$PSScriptRoot\copy-notes.ps1" -Root $root }
  Step 'app: pub get' $app { flutter pub get | Out-Null }
  Step 'app: format'  $app { dart format --output=none --set-exit-if-changed @('lib', 'test' | Where-Object { Test-Path $_ }) }
  Step 'app: analyze' $app { flutter analyze --fatal-infos }
  if (Test-Path "$app\test") { Step 'app: test' $app { flutter test -r failures-only } }

  if ($Release) {
    # The owner build (spec 0007 §4): test walk on. Friends' builds come from scripts\release.ps1.
    # Only this step: flutter build prints a Kotlin plugin warning on stderr, which PowerShell 5.1 turns into an
    # error. Its exit code decides; a missing flutter still fails (no exit code, so it throws below).
    Step 'app: build release APK' $app {
      $ErrorActionPreference = 'Continue'
      $global:LASTEXITCODE = $null
      flutter build apk --release --dart-define=TEST_WALK=true
      if ($null -eq $LASTEXITCODE) { throw 'flutter did not run' }
    }
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

} finally {
  Exit-CheckTurn
}
if ($failed.Count) {
  Write-Host "`nCHECK FAILED: $($failed -join ', ')" -ForegroundColor Red
  exit 1
}
Write-Host ("`nCHECK PASSED in {0:0} s" -f $total.Elapsed.TotalSeconds) -ForegroundColor Green
