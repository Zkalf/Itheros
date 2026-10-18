<#
.SYNOPSIS
  Prints a short hash of the Claude setup: CLAUDE.md and .claude/** (hooks, skills, agents, settings), excluding
  local-only files. Evals record it; check.ps1 warns when it no longer matches the last full eval run.
#>
param([string]$Root = (Split-Path -Parent $PSScriptRoot))

$files = @(Get-Item -LiteralPath (Join-Path $Root 'CLAUDE.md')) +
  @(Get-ChildItem -LiteralPath (Join-Path $Root '.claude') -Recurse -File |
    Where-Object { $_.Name -notin @('settings.local.json', 'test-lock') })
$text = ($files | Sort-Object FullName | ForEach-Object {
    $rel = $_.FullName.Substring($Root.Length + 1) -replace '\\', '/'
    "== $rel`n" + ((Get-Content -Raw -LiteralPath $_.FullName) -replace "`r`n", "`n")
  }) -join "`n"
$sha = [Security.Cryptography.SHA256]::Create()
$bytes = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text))
-join ($bytes[0..5] | ForEach-Object { $_.ToString('x2') })
