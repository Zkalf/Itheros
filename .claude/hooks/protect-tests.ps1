# PreToolUse (Edit|Write): while .claude/test-lock exists (bugfix skill), test files are frozen, so a fix can't
# change the committed test that reproduces the bug. Exit 2 = block.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path.TrimEnd('\')
$lock = Join-Path $root '.claude\test-lock'
if (-not (Test-Path -LiteralPath $lock)) { exit 0 }

try {
  $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch {
  exit 0
}
$path = $payload.tool_input.file_path
if (-not $path) { exit 0 }

$full = [IO.Path]::GetFullPath($path)
if (-not $full.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) { exit 0 }
$rel = $full.Substring($root.Length + 1) -replace '\\', '/'

if ($rel -match '(^|/)test/') {
  $info = (Get-Content -LiteralPath $lock -Raw).Trim()
  [Console]::Error.WriteLine("Blocked: $rel is locked during a bug fix ($info). Fix the code, not the test. When scripts/check.ps1 is green, run scripts/lock-tests.ps1 -Unlock.")
  exit 2
}
exit 0
