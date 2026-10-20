param([string]$Worktree)
. (Join-Path $PSScriptRoot '..\lib.ps1')
$ErrorActionPreference = 'Stop'
# The goal text for visited areas is gone (incident 2026-10-19).
Set-Seed $Worktree 'app/lib/ui/achievements_screen.dart' "      'areas' => 'Arrive at all `$n areas',`n" ''
