param([string]$Worktree)
. (Join-Path $PSScriptRoot '..\lib.ps1')
$ErrorActionPreference = 'Stop'
# Credited day totals are never updated, so a re-sync counts the same steps again.
Set-Seed $Worktree 'app/lib/sync/sync_service.dart' "      credited[key] = totals[key]!;`n" ''
