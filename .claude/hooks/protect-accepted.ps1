# PreToolUse (Edit|Write): intents, specs and plans change only on a branch (plan 0068).
# Each is one living file. A change edits it on a short branch and adds a History line; the owner accepts it on the
# pull request or by the push to main. On main itself, this hook blocks every edit in intent/, specs/ and plans/.
# Exit 2 = block.
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

# Not in git, or git missing: nothing to judge. A detached HEAD (an eval worktree) reads "HEAD".
$branch = ''
try {
  $ErrorActionPreference = 'Continue'
  $branch = (& git -C $root rev-parse --abbrev-ref HEAD 2>$null | Out-String).Trim()
} catch {
  exit 0
}
if ($branch -eq 'main') {
  [Console]::Error.WriteLine("Blocked: $rel is on main. Make a short branch first; a change to an intent, spec or plan edits the file there and adds a History line (plan 0068).")
  exit 2
}
exit 0
