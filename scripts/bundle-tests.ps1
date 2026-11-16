<#
.SYNOPSIS
  Writes a few bundle files that together run every test file of a package, and prints the paths to pass to
  `flutter test` or `dart test`.

.DESCRIPTION
  The test runner compiles and warms up each test file on its own: about 2 s a file, before its first test. With 77
  files the app's tests took 160 s; from 8 bundles the same tests take about 80 s (measured 2026-11-16, 12 threads).
  A bundle imports its test files and runs the main() of each in a group named after the file, so a failure still
  names its file.

  The bundles go to <package>\.dart_tool\test_bundles: git, the formatter and the analyzer skip that folder. The
  files are shared out by size, the biggest first, each to the lightest bundle, so the bundles take about the same
  time and the same files give the same bundles.

  A test file stays out of the bundles, and its own path is printed after them, when a bundle would change what it
  does: a file-level annotation (@Tags, @Timeout: the pacing sims), an async main(), or a golden file (its path
  counts from the test file). A flutter_test_config.dart is not read from the bundles' folder, so the script stops
  when the package has one.

  Two checks may run in one folder at a time (the verifier beside the local check), so the script never empties the
  folder: it writes a bundle only when its text differs and removes only the bundles past the count.

  The tests of one bundle share one isolate, so a top-level variable of one file is seen by the next. To run a
  file alone: .\scripts\test.ps1 <file>.

.EXAMPLE
  .\scripts\bundle-tests.ps1 -Package app -Count 8
#>
param([Parameter(Mandatory)][string]$Package, [Parameter(Mandatory)][int]$Count)

$ErrorActionPreference = 'Stop'
$pkg = (Resolve-Path $Package).Path
$out = Join-Path $pkg '.dart_tool\test_bundles'
New-Item -ItemType Directory -Force $out | Out-Null
$test = Join-Path $pkg 'test'
if (Get-ChildItem $test -Recurse -Filter 'flutter_test_config.dart') {
  throw 'bundle-tests.ps1: a flutter_test_config.dart is not read from the bundles. Teach the script first.'
}

# Each file with its path from test\, written with "/", as the imports and the group names use it.
$alone = @()
$files = @()
foreach ($f in @(Get-ChildItem $test -Recurse -Filter '*_test.dart' | Sort-Object FullName)) {
  $entry = [pscustomobject]@{ Rel = $f.FullName.Substring($test.Length + 1).Replace('\', '/'); Length = $f.Length }
  $own = Select-String -Quiet -LiteralPath $f.FullName -Pattern '^@|\bmain\(\)\s*async|matchesGoldenFile'
  if ($own) { $alone += $entry } else { $files += $entry }
}

$n = [Math]::Max(1, [Math]::Min($Count, $files.Count))
$bundles = @(for ($i = 0; $i -lt $n; $i++) { , (New-Object System.Collections.Generic.List[object]) })
$load = New-Object long[] $n
# Biggest first, each to the lightest bundle so far; the path settles a tie of sizes.
foreach ($f in @($files | Sort-Object @{ Expression = 'Length'; Descending = $true }, Rel)) {
  $lightest = 0
  for ($i = 1; $i -lt $n; $i++) { if ($load[$i] -lt $load[$lightest]) { $lightest = $i } }
  $bundles[$lightest].Add($f)
  $load[$lightest] += $f.Length
}

$utf8 = New-Object System.Text.UTF8Encoding $false
$isFlutter = Select-String -Quiet -Path (Join-Path $pkg 'pubspec.yaml') -Pattern '^\s+sdk: flutter'
$testLib = if ($isFlutter) { 'package:flutter_test/flutter_test.dart' } else { 'package:test/test.dart' }
$kept = @()
for ($i = 0; $i -lt $n; $i++) {
  if (-not $bundles[$i].Count) { continue }
  $lines = @('// Made by scripts/bundle-tests.ps1. Not for git.', "import '$testLib';", '')
  $k = 0
  foreach ($f in $bundles[$i]) { $lines += "import '../../test/$($f.Rel)' as t$k;"; $k++ }
  $lines += @('', 'void main() {')
  $k = 0
  foreach ($f in $bundles[$i]) { $lines += "  group('$($f.Rel)', t$k.main);"; $k++ }
  $lines += '}'
  $name = 'bundle_{0:00}_test.dart' -f ($i + 1)
  $text = ($lines -join "`n") + "`n"
  $path = Join-Path $out $name
  if (-not (Test-Path $path) -or [IO.File]::ReadAllText($path) -ne $text) { [IO.File]::WriteAllText($path, $text, $utf8) }
  $kept += $name
  ".dart_tool\test_bundles\$name"
}
Get-ChildItem $out -File | Where-Object { $kept -notcontains $_.Name } | Remove-Item -Force
foreach ($f in $alone) { "test\$($f.Rel.Replace('/', '\'))" }
