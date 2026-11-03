<#
.SYNOPSIS
  The cases of copy-notes.ps1 (spec 0018 amendment 2, criteria 5-8): it joins releases\next.md and the small files of
  releases\next\ into one next.md in the app.

.DESCRIPTION
  Each case builds a small checkout in a temporary folder and runs copy-notes.ps1 -Root on it. Exit 1 on any wrong
  case.
#>
$ErrorActionPreference = 'Stop'
$bad = 0
$cases = 0
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Case([string]$what, [bool]$ok) {
  $script:cases++
  if (-not $ok) { Write-Host "WRONG: $what" -ForegroundColor Red; $script:bad++ }
}

# A checkout with $files (path under releases\ -> text), copied into its app. Returns the app's copy folder.
function Copy-In([hashtable]$files) {
  $root = Join-Path ([IO.Path]::GetTempPath()) "itheros-notes-test-$PID-$script:cases"
  if (Test-Path $root) { Remove-Item -Recurse -Force $root }
  New-Item -ItemType Directory -Force (Join-Path $root 'releases') | Out-Null
  New-Item -ItemType Directory -Force (Join-Path $root 'app') | Out-Null
  foreach ($name in $files.Keys) {
    $path = Join-Path $root "releases\$name"
    New-Item -ItemType Directory -Force (Split-Path -Parent $path) | Out-Null
    [IO.File]::WriteAllText($path, $files[$name], $utf8)
  }
  & "$PSScriptRoot\copy-notes.ps1" -Root $root
  return Join-Path $root 'app\assets\releases'
}
function Text([string]$path) { [IO.File]::ReadAllText($path, $utf8) }

# Criteria 5 and 6: next.md first, then the small files by name.
$to = Copy-In @{
  '0.8.0.md'          = "Old.`n`n- Old item.`n"
  'next.md'           = "Summary.`n`n- From next.md.`n"
  'next\b-second.md'  = "- Second.`n"
  'next\a-first.md'   = "- First.`n"
}
$joined = Text (Join-Path $to 'next.md')
Case 'criterion 5: the copy joins next.md and the small files' ($joined -match 'From next\.md' -and $joined -match 'First' -and $joined -match 'Second')
Case 'criterion 6: next.md first, then the small files by name' (
  $joined.IndexOf('Summary.') -lt $joined.IndexOf('From next.md') -and
  $joined.IndexOf('From next.md') -lt $joined.IndexOf('First') -and
  $joined.IndexOf('First') -lt $joined.IndexOf('Second'))
Case 'the version notes are copied as before' ((Text (Join-Path $to '0.8.0.md')) -eq "Old.`n`n- Old item.`n")
Case 'the small files are not copied one by one' (-not (Test-Path (Join-Path $to 'a-first.md')))

# Criterion 7: only small files.
$to = Copy-In @{ '0.8.0.md' = "Old.`n"; 'next\a-first.md' = "- First.`n" }
Case 'criterion 7: with only small files, the copy holds them' (
  (Test-Path (Join-Path $to 'next.md')) -and (Text (Join-Path $to 'next.md')) -match '^- First\.')

# Criterion 8: neither.
$to = Copy-In @{ '0.8.0.md' = "Old.`n" }
Case 'criterion 8: no next.md and no small file, no next.md in the app' (-not (Test-Path (Join-Path $to 'next.md')))

# Only next.md (the weeks before this amendment, and the final notes before a release).
$to = Copy-In @{ '0.8.0.md' = "Old.`n"; 'next.md' = "Summary.`n`n- Item.`n" }
Case 'next.md alone is copied as it is' ((Text (Join-Path $to 'next.md')).Trim() -eq "Summary.`n`n- Item.")

Get-ChildItem ([IO.Path]::GetTempPath()) -Directory -Filter "itheros-notes-test-$PID-*" | Remove-Item -Recurse -Force
if ($bad) { Write-Host "$bad of $cases copy-notes cases wrong" -ForegroundColor Red; exit 1 }
Write-Host "copy-notes: $cases cases right"
exit 0
