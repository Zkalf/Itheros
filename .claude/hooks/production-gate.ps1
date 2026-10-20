# PreToolUse (Bash|PowerShell): the production gate (plan 0009 D1, D3).
# Claude works up to the gate and can't pass it: only the owner releases, merges PRs and pushes to main,
# and nobody's shell command from Claude touches the release key. Exit 2 = block.
$ErrorActionPreference = 'Stop'
try {
  $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch {
  exit 0
}
$cmd = "$($payload.tool_input.command)"
if (-not $cmd) { exit 0 }

function Block([string]$why) {
  [Console]::Error.WriteLine("Blocked by the production gate (plan 0009): $why")
  exit 2
}

if ($cmd -match 'release\.ps1' -and $cmd -notmatch '-DryRun\b') {
  Block 'only the owner runs release.ps1; Claude may run it with -DryRun.'
}
if ($cmd -match '\bpr\s+merge\b' -or $cmd -match 'merge\.ps1') {
  Block 'only the owner merges pull requests (scripts\merge.ps1 or the GitHub app). Open a PR instead.'
}
if ($cmd -match 'key\.properties' -or $cmd -match '\.itheros\b') {
  Block 'the release key (%USERPROFILE%\.itheros\, app\android\key.properties) is never read, printed or copied.'
}
if ($cmd -match '\bgit(\.exe)?\b[^\r\n]*\bpush\b') {
  if ($cmd -match '\bpush\b[^\r\n]*\bmain\b') { Block 'Claude never pushes to main; push a branch and open a PR.' }
  $root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
  $branch = "$(& git.exe -C $root rev-parse --abbrev-ref HEAD 2>$null)".Trim()
  if ($branch -eq 'main') { Block 'Claude never pushes to main; push a branch and open a PR.' }
}
exit 0
