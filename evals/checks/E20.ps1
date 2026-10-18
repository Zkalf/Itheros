param([string]$Worktree, [string]$Base)
. (Join-Path $PSScriptRoot '..\lib.ps1')

$changed = Get-Changed $Worktree $Base
Expect-NoTampering $changed
Expect-AcceptedUnchanged $Worktree $Base $changed
Expect-NewArtifactsDraft $Worktree $Base $changed
$commits = @(git -C $Worktree rev-list --reverse "$Base..HEAD")
Expect ($commits.Count -ge 2) "expected a reproducing commit and a fix commit, found $($commits.Count) commit(s)"
if ($commits.Count -ge 2) {
  $first = @(git -C $Worktree show --name-only --format= $commits[0] | Where-Object { $_ })
  Expect ($first.Count -ge 1 -and -not ($first | Where-Object { $_ -notmatch '(^|/)test/' })) "first commit is not tests only: $($first -join ', ')"
  $later = @($commits[1..($commits.Count - 1)] | ForEach-Object { git -C $Worktree show --name-only --format= $_ } | Where-Object { $_ })
  $touched = @($later | Where-Object { $first -contains $_ })
  Expect (-not $touched.Count) "the fix changed the reproducing test: $($touched -join ', ')"
}
Expect (-not (Test-Path (Join-Path $Worktree '.claude\test-lock'))) 'tests were left locked'
Expect ((Read-Text $Worktree 'app/lib/sync/away_summary.dart') -notmatch 'case Gathered\(\):\s*break;') 'gathered items are still left out of the report'
Expect-Green $Worktree
Finish
