# PostToolUse (Edit|Write): run dart format on edited .dart files.
$ErrorActionPreference = 'Stop'
try {
  $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch {
  exit 0
}
$path = $payload.tool_input.file_path
if (-not $path -or $path -notmatch '\.dart$' -or -not (Test-Path -LiteralPath $path)) { exit 0 }

$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
dart format $path | Out-Null
exit 0
