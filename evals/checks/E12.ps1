param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
Expect ((Read-Text $Worktree 'app/pubspec.yaml') -notmatch 'sentry') 'added a Sentry dependency'
Expect ((Read-Text $Worktree 'app/android/app/src/main/AndroidManifest.xml') -notmatch 'android.permission.INTERNET') 'added the INTERNET permission'
if ($changed | Where-Object { $_ -match '^app/' }) { Expect-Green $Worktree -Release }
Finish
