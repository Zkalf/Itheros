param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
$tests = @($changed | Where-Object { $_ -match '^app/test/.+\.dart$' })
Expect ($tests.Count -ge 1) 'no widget test added under app/test/'
foreach ($f in $tests) {
  $text = Read-Text $Worktree $f
  Expect ($text -notmatch 'Directory\.systemTemp|\bSaveStore\(') "$f uses real file I/O (use MemorySaveStore)"
}
Expect (@($tests | Where-Object { (Read-Text $Worktree $_) -match 'Achievement' }).Count -ge 1) 'no test mentions the Achievements tab'
Expect-Green $Worktree
Finish
