<#
.SYNOPSIS
  Releases a new version of Itheros to friends (spec 0007 §5).

.DESCRIPTION
  Raises the version (0.2.0 -> 0.3.0; -Fix: 0.3.0 -> 0.3.1), runs the full check, builds the friend APK
  (no test walk), checks that exact file (no INTERNET, no cloud backup, signed with the release key), adds a
  sample save for the save tests, commits "Release <version>", tags v<version>, pushes, and publishes a GitHub
  release with releases\next.md as the notes and the APK as itheros.apk.

  Stops at the first failure. Until the push, a failure undoes everything (version, commit, tag).
  -DryRun: stops after the APK check and undoes the version change; nothing is committed or published.

  In Claude Code run it directly (.\scripts\release.ps1): a nested `powershell -File` can't be auto-approved.
#>
param([switch]$Fix, [switch]$DryRun)

# Native tools (flutter, git, gh) write progress to stderr; with 'Stop', PowerShell 5.1 would treat that as fatal.
# Exit codes are checked explicitly instead.
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root 'app'
$pubspec = Join-Path $app 'pubspec.yaml'
$versionDart = Join-Path $app 'lib\version.dart'
$notes = Join-Path $root 'releases\next.md'
$apk = Join-Path $app 'build\app\outputs\flutter-apk\app-release.apk'
$repo = 'Zkalf/Itheros'

$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
if ($env:JAVA_HOME) { $env:JAVA_HOME = $env:JAVA_HOME.TrimEnd('\') }
if (-not $env:ANDROID_HOME) { $env:ANDROID_HOME = [Environment]::GetEnvironmentVariable('ANDROID_HOME', 'User') }

function Fail([string]$message) {
  Write-Host "RELEASE FAILED: $message" -ForegroundColor Red
  exit 1
}
function Repo { & git.exe -C $root @args }

# 1. Preconditions.
if ("$(Repo rev-parse --abbrev-ref HEAD)".Trim() -ne 'main') { Fail 'not on main' }
if (Repo status --porcelain) { Fail 'the working tree has uncommitted changes; commit or stash them first' }
if (-not (Test-Path $notes) -or -not (Get-Content -Raw -Encoding UTF8 $notes).Trim()) {
  Fail 'no release notes: write releases\next.md (a few plain lines for players) and commit it'
}
if (-not (Test-Path (Join-Path $app 'android\key.properties'))) {
  Fail 'no app\android\key.properties: the release key is missing (restore it from the backup)'
}
if (-not $DryRun) {
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Fail 'the GitHub CLI (gh) is not installed' }
  & gh auth status *> $null
  if ($LASTEXITCODE -ne 0) { Fail 'not signed in to GitHub: run gh auth login' }
  if (-not "$(Repo remote get-url origin 2>$null)") { Fail 'no git remote "origin"' }
}

# 2. The new version.
$text = Get-Content -Raw -Encoding UTF8 $pubspec
$m = [regex]::Match($text, '(?m)^version: (\d+)\.(\d+)\.(\d+)\+(\d+)\s*$')
if (-not $m.Success) { Fail 'pubspec.yaml has no "version: x.y.z+n" line' }
$major, $minor, $patch, $build = 1..4 | ForEach-Object { [int]$m.Groups[$_].Value }
if ($Fix) { $patch++ } else { $minor++; $patch = 0 }
$build++
$version = "$major.$minor.$patch"
$tag = "v$version"
if (Repo tag --list $tag) { Fail "tag $tag already exists" }
Write-Host "==> Releasing $version (build $build)$(if ($DryRun) { ' - dry run' })" -ForegroundColor Cyan

# From here on, any failure before the push puts everything back.
$head = "$(Repo rev-parse HEAD)".Trim()
$pushed = $false
function Undo {
  if ($script:pushed) { return }
  Repo tag -d $tag *> $null
  Repo reset --hard $head *> $null
  Remove-Item -ErrorAction SilentlyContinue (Join-Path $app "test/fixtures/saves/$version.json")
  Write-Host "    undone: back at $($head.Substring(0, 7)), version unchanged" -ForegroundColor Yellow
}
function Abort([string]$message) { Undo; Fail $message }

$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($pubspec, ($text -replace '(?m)^version: [^\r\n]*', "version: $version+$build"), $utf8)
[IO.File]::WriteAllText($versionDart, ((Get-Content -Raw -Encoding UTF8 $versionDart) -replace "appVersion = '[^']*'", "appVersion = '$version'"), $utf8)

# 3. The full check (format, analyze, tests: the save fixtures and the version line included).
& "$PSScriptRoot\check.ps1"
if ($LASTEXITCODE -ne 0) { Abort 'the check failed' }

# 4. The friend build: no --dart-define=TEST_WALK (spec 0007 §4). Then check that exact file.
Write-Host '==> Building the friend APK' -ForegroundColor Cyan
Push-Location $app
flutter build apk --release
$built = $LASTEXITCODE
Pop-Location
if ($built -ne 0) { Abort 'the build failed' }
& "$PSScriptRoot\apk-check.ps1" $apk -RequireReleaseKey
if ($LASTEXITCODE -ne 0) { Abort 'the APK check failed' }
$out = Join-Path $env:TEMP 'itheros-release'
New-Item -ItemType Directory -Force $out | Out-Null
$asset = Join-Path $out 'itheros.apk'
Copy-Item $apk $asset -Force

if ($DryRun) {
  Undo
  Write-Host "`nDRY RUN PASSED: $version would be released. The checked APK is $asset" -ForegroundColor Green
  exit 0
}

# 5. Sample save, notes renamed, commit, tag, push.
Write-Host '==> Committing' -ForegroundColor Cyan
Push-Location $app
dart run tool/sample_save.dart "test/fixtures/saves/$version.json"
$sampled = $LASTEXITCODE
Pop-Location
if ($sampled -ne 0) { Abort 'could not write the sample save' }
Repo mv releases/next.md "releases/$version.md"
Repo add app/pubspec.yaml app/lib/version.dart "app/test/fixtures/saves/$version.json"
Repo commit -q -m "Release $version"
if ($LASTEXITCODE -ne 0) { Abort 'git commit failed' }
Repo tag -a $tag -m "Itheros $version"
if ($LASTEXITCODE -ne 0) { Abort 'git tag failed' }
Write-Host '==> Pushing' -ForegroundColor Cyan
Repo push -q origin main $tag
if ($LASTEXITCODE -ne 0) { Abort 'git push failed (nothing was published)' }
$pushed = $true

# 6. The GitHub release.
Write-Host '==> Publishing' -ForegroundColor Cyan
$body = Join-Path $out 'notes.md'
$footer = "`n`n---`nNew here? [How to install Itheros](https://github.com/$repo/blob/main/INSTALL.md)"
[IO.File]::WriteAllText($body, (Get-Content -Raw -Encoding UTF8 (Join-Path $root "releases\$version.md")).Trim() + $footer, $utf8)
& gh release create $tag $asset --repo $repo --title "Itheros $version" --notes-file $body
if ($LASTEXITCODE -ne 0) {
  Fail "pushed, but the GitHub release failed. Retry with: gh release create $tag `"$asset`" --repo $repo --title `"Itheros $version`" --notes-file `"$body`""
}
Write-Host "`nRELEASED $version`n    https://github.com/$repo/releases/tag/$tag" -ForegroundColor Green
