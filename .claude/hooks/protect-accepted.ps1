# PreToolUse (Edit|Write): accepted SDLC artifacts are immutable.
# Blocks edits to intent/, specs/ or plans/ files whose status is accepted;
# changes go through a new intent/spec/plan instead. Exit 2 = block.
$ErrorActionPreference = 'Stop'
try {
  $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch {
  exit 0
}
$path = $payload.tool_input.file_path
if (-not $path) { exit 0 }

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path.TrimEnd('\')
$full = [IO.Path]::GetFullPath($path)
if (-not $full.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) { exit 0 }

$rel = $full.Substring($root.Length + 1) -replace '\\', '/'
if ($rel -notmatch '^(intent|specs|plans)/') { exit 0 }
if (-not (Test-Path -LiteralPath $full)) { exit 0 }

if (Select-String -LiteralPath $full -Pattern '^Status:\s*accepted' -Quiet) {
  [Console]::Error.WriteLine("Blocked: $rel is an accepted SDLC artifact and is immutable. Write a new intent/spec/plan (or an amendment file) instead.")
  exit 2
}
exit 0
