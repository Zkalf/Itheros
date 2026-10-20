<#
.SYNOPSIS
  The production gate's cases (plan 0009): what it must block, and what it must let through.

.DESCRIPTION
  Loads .claude\hooks\production-gate.ps1 and judges each command with a fixed repo state (no git calls), so the
  result doesn't depend on the branch checked out. Run by check.ps1, so CI runs it too. Exit 1 on any wrong verdict.
  -All: list every case, not only the wrong ones.
#>
param([switch]$All)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\.claude\hooks\production-gate.ps1')

$onBranch = @{ Branch = 'fix/x'; Linked = $false }
$onMain = @{ Branch = 'main'; Linked = $false }
$inWorktree = @{ Branch = 'fix/x'; Linked = $true }
$gh = '& "C:\Program Files\GitHub CLI\gh.exe"'
$nl = "`n"

# Command, expected verdict, repo state.
$cases = @(
  # Releases: only dry runs.
  @('.\scripts\release.ps1', 'block', $onBranch),
  @('.\scripts\release.ps1 -Fix', 'block', $onBranch),
  @('powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/release.ps1', 'block', $onBranch),
  @('.\scripts\release.ps1 -DryRun', 'allow', $onBranch),
  @('.\scripts\release.ps1 -Fix -DryRun', 'allow', $onBranch),
  @('gh release create v0.3.0 itheros.apk', 'block', $onBranch),
  @("$gh release edit v0.3.0 --prerelease", 'block', $onBranch),
  @('gh release list --repo Zkalf/Itheros', 'allow', $onBranch),
  @('gh release view v0.2.0', 'allow', $onBranch),
  # Merges: the owner's.
  @('gh pr merge 3 --squash', 'block', $onBranch),
  @("$gh pr merge 3", 'block', $onBranch),
  @('.\scripts\merge.ps1 3', 'block', $onBranch),
  @('powershell -File scripts\merge.ps1 3', 'block', $onBranch),
  @('gh api -X PUT repos/Zkalf/Itheros/pulls/7/merge', 'block', $onBranch),
  @('gh pr create --fill', 'allow', $onBranch),
  @('gh pr checks 5 --watch', 'allow', $onBranch),
  @('cat scripts/merge.ps1', 'allow', $onBranch),
  # Pushes: branches only, never main, never from eval worktrees.
  @('git push origin main', 'block', $onBranch),
  @('git push -u origin HEAD:main', 'block', $onBranch),
  @('git push origin +fix/x:refs/heads/main', 'block', $onBranch),
  @('git push', 'block', $onMain),
  @('git push origin HEAD', 'block', $onMain),
  @('git push --all origin', 'block', $onBranch),
  @('git push origin v0.3.0', 'block', $onBranch),
  @('git push --tags', 'block', $onBranch),
  @('git -C C:/repo push origin main', 'block', $onBranch),
  @('cd app && git push origin main', 'block', $onBranch),
  @('bash -c "git push origin main"', 'block', $onBranch),
  @('git push -u origin fix/x', 'block', $inWorktree),
  @('git push -u origin fix/x', 'allow', $onBranch),
  @('git push', 'allow', $onBranch),
  @('git push origin --delete goblin-hide-60', 'allow', $onMain),
  # The release key.
  @('cat app/android/key.properties', 'block', $onBranch),
  @('Get-ChildItem $env:USERPROFILE\.itheros', 'block', $onBranch),
  @('grep -rn storePassword app/android', 'block', $onBranch),
  @('Get-Content app\android\*.properties', 'block', $onBranch),
  @('Copy-Item "C:\Users\me\.itheros\itheros-release.jks" x', 'block', $onBranch),
  # Words in text are not commands (today's false alarms).
  @("git commit -F msg.txt", 'allow', $onMain),
  @("cat > note.txt <<'EOF'$nl- the gate blocks gh pr merge and git push to main$nl- release.ps1 is the owner's${nl}EOF", 'allow', $onMain),
  @("printf 'Proof: a live gh pr merge was blocked\n' > msg.txt && git add -A && git commit -q -F msg.txt", 'allow', $onBranch),
  @('echo "worktree exit"; echo "a push to main repo is blocked"', 'allow', $onMain),
  @('git ls-remote --heads origin && echo "the push block caught it on main"', 'allow', $onMain),
  @(("git commit -m @'$nl" + "Gate: git push origin main and gh pr merge are blocked$nl'@"), 'allow', $onBranch),
  @('Get-ChildItem C:\repo\scripts\*.ps1 | ForEach-Object { $_.Name }', 'allow', $onBranch),
  @('git status', 'allow', $onMain),
  @('flutter test 2>&1 | Select-Object -Last 5', 'allow', $onMain),
  @('.\scripts\check.ps1 *>&1 | Select-Object -Last 4', 'allow', $onMain)
)

$bad = 0
foreach ($c in $cases) {
  $why = Test-Gate $c[0] $c[2]
  $got = if ($why) { 'block' } else { 'allow' }
  $ok = $got -eq $c[1]
  if (-not $ok) { $bad++ }
  if ($ok -and -not $All) { continue }
  $shown = ($c[0] -replace '\r?\n', ' / ')
  if ($shown.Length -gt 90) { $shown = $shown.Substring(0, 87) + '...' }
  Write-Host ('{0} {1,-5} {2}' -f $(if ($ok) { 'ok  ' } else { 'FAIL' }), $got, $shown) -ForegroundColor $(if ($ok) { 'Gray' } else { 'Red' })
}
if ($bad) {
  Write-Host "GATE TESTS FAILED: $bad of $($cases.Count)" -ForegroundColor Red
  exit 1
}
Write-Host "GATE TESTS PASSED: $($cases.Count) cases" -ForegroundColor Green
exit 0
