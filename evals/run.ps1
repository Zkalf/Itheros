<#
.SYNOPSIS
  Runs evals: headless Claude on throwaway git worktrees, graded by deterministic checks (plan 0002 T3).

.DESCRIPTION
  Each task (evals/tasks/<id>.json) gets a fresh worktree of HEAD outside the repo, an optional setup script (for
  example a seeded bug, committed as the base), a headless `claude -p` session with a fixed tool allowlist, and then
  its check script from THIS repo. Passing worktrees are removed, with any branches the agent made in them; failing
  ones are kept for inspection.

  A full run (no -Id) writes evals/results/<run>.md and evals/results/latest.json (commit and Claude-setup hash).

.EXAMPLE
  .\evals\run.ps1 -Id E04        # one eval
.EXAMPLE
  .\evals\run.ps1                # the whole suite
.EXAMPLE
  .\evals\run.ps1 -NoAgent       # sanity-check the checks on untouched worktrees (no Claude, no cost)
#>
param(
  [string[]]$Id,
  [string]$Model,
  [switch]$NoAgent,
  [switch]$KeepWorktrees
)

$ErrorActionPreference = 'Continue'
$repo = Split-Path -Parent $PSScriptRoot
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')

# What a headless eval session may do without approval. Scripts run directly; a nested `powershell -File` is
# never auto-approved (see CLAUDE.md).
# Rules need either the exact command or "<prefix> *" (with the space); "<prefix>*" does not match.
$allowedTools = @(
  'Read', 'Grep', 'Glob', 'Edit', 'Write', 'Skill', 'Agent',
  'PowerShell(git *)', 'PowerShell(dart *)', 'PowerShell(flutter *)',
  'PowerShell(Push-Location *)', 'PowerShell(Pop-Location)',
  'PowerShell(.\scripts\check.ps1)', 'PowerShell(.\scripts\check.ps1 *)',
  'PowerShell(.\scripts\lock-tests.ps1)', 'PowerShell(.\scripts\lock-tests.ps1 *)',
  'PowerShell(.\scripts\test.ps1 *)'
)

$tasks = @(Get-ChildItem (Join-Path $PSScriptRoot 'tasks\*.json') | Sort-Object Name |
  ForEach-Object { Get-Content -Raw $_.FullName | ConvertFrom-Json } |
  Where-Object { -not $Id -or $Id -contains $_.id })
if (-not $tasks.Count) { Write-Host 'No matching eval tasks.' -ForegroundColor Red; exit 1 }

$commit = (git -C $repo rev-parse --short HEAD).Trim()
if (git -C $repo status --porcelain) {
  Write-Warning 'Uncommitted changes are not part of this run: worktrees are made from HEAD.'
}
$configHash = & (Join-Path $repo 'scripts\config-hash.ps1') -Root $repo
$runId = '{0:yyyyMMdd-HHmmss}' -f (Get-Date)
$runDir = Join-Path $env:LOCALAPPDATA "walk-sun-goose-evals\$runId"
New-Item -ItemType Directory -Force $runDir | Out-Null
$claude = (Get-Command claude -ErrorAction SilentlyContinue).Source
if (-not $NoAgent -and -not $claude) { Write-Host 'claude CLI not found.' -ForegroundColor Red; exit 1 }

function Quote([string]$arg) {
  if ($arg -match '[\s"()*&]') { '"' + ($arg -replace '"', '\"') + '"' } else { $arg }
}

# Runs headless Claude in $wt with the prompt on stdin (PowerShell 5.1 mangles quotes in native arguments).
function Invoke-Agent($task, [string]$wt, [string]$transcript) {
  $cliArgs = @('-p', '--output-format', 'json', '--no-session-persistence', '--permission-mode', 'acceptEdits',
    '--allowedTools') + $allowedTools
  if ($Model) { $cliArgs += @('--model', $Model) }
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $claude
  $psi.Arguments = ($cliArgs | ForEach-Object { Quote $_ }) -join ' '
  $psi.WorkingDirectory = $wt
  $psi.UseShellExecute = $false
  $psi.RedirectStandardInput = $true
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $p = [Diagnostics.Process]::Start($psi)
  $stdout = $p.StandardOutput.ReadToEndAsync()
  $stderr = $p.StandardError.ReadToEndAsync()
  $bytes = (New-Object System.Text.UTF8Encoding $false).GetBytes([string]$task.prompt)
  $p.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length)
  $p.StandardInput.Close()

  $timeoutMs = [int]$task.timeoutMinutes * 60000
  $timedOut = -not $p.WaitForExit($timeoutMs)
  if ($timedOut) { & taskkill /PID $p.Id /T /F *> $null }
  $json = $stdout.Result
  Set-Content -LiteralPath $transcript -Value $json -Encoding utf8
  $r = $null
  try { $r = $json | ConvertFrom-Json } catch { }
  [pscustomobject]@{
    timedOut = $timedOut
    cost     = if ($r) { $r.total_cost_usd } else { $null }
    turns    = if ($r) { $r.num_turns } else { $null }
    denied   = if ($r) { @($r.permission_denials | ForEach-Object { $_.tool_input.command } | Where-Object { $_ }) } else { @() }
    error    = if (-not $r) { "no JSON output: $($stderr.Result.Trim())" } else { $null }
  }
}

function Get-Branches { @(git -C $repo for-each-ref --format='%(refname:short)' refs/heads) }

# Branches the agent made in $wt: new since the task started and checked out there (the worktree's own reflog), so a
# branch the owner makes in the main checkout meanwhile is never touched. Branches outlive the worktree, so an
# agent following "short branch per change" once left one behind (docs-boost-display, E19).
function Get-AgentBranches([string]$wt, [string[]]$before) {
  $checkedOut = @(git -C $wt reflog --format=%gs | ForEach-Object {
      if ($_ -match '^checkout: moving from \S+ to (\S+)$') { $Matches[1] } })
  @(Get-Branches | Where-Object { $before -notcontains $_ -and $checkedOut -contains $_ })
}

$results = @()
foreach ($t in $tasks) {
  $started = Get-Date
  Write-Host "==> $($t.id) $($t.title)" -ForegroundColor Cyan
  $wt = Join-Path $runDir $t.id
  $branchesBefore = Get-Branches
  git -C $repo worktree add --detach --quiet $wt HEAD

  if ($t.setup) {
    $setupOut = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot $t.setup) -Worktree $wt 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
      # A seed that no longer applies would let the agent run on unbroken code (E20 once did); fail loudly instead.
      $why = (($setupOut -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 1) -replace '\|', '/').Trim()
      Write-Host "    SETUP FAILED: $why" -ForegroundColor Red
      $results += [pscustomobject]@{ id = $t.id; title = $t.title; pass = $false; verdict = 'SETUP FAILED'
        minutes = 0; turns = ''; cost = ''; notes = "setup failed: $why" }
      git -C $repo worktree remove --force $wt
      continue
    }
    if ($t.setupCommit -ne $false) {
      git -C $wt add -A
      git -C $wt commit --quiet -m "eval setup: $($t.id)"
    }
  }
  $base = (git -C $wt rev-parse HEAD).Trim()

  # Dependencies, so the agent's analyzer and tests work in the worktree (shared pub cache, fast).
  Push-Location (Join-Path $wt 'packages\game_core'); dart pub get *> $null; Pop-Location
  Push-Location (Join-Path $wt 'app'); flutter pub get *> $null; Pop-Location

  $agent = $null
  if (-not $NoAgent) { $agent = Invoke-Agent $t $wt (Join-Path $runDir "$($t.id).json") }

  $checkOut = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot $t.check) `
    -Worktree $wt -Base $base 2>&1 | Out-String
  $pass = $LASTEXITCODE -eq 0
  $notes = @($checkOut -split "`r?`n" | Where-Object { $_ -match '^FAIL:' } | ForEach-Object { $_.Substring(6) })
  if ($agent -and $agent.timedOut) { $notes += "timed out after $($t.timeoutMinutes) min" }
  if ($agent -and $agent.error) { $notes += $agent.error }
  # Full denied commands are in the transcript ($runDir\<id>.json); the table gets a count and the first one.
  if ($agent -and $agent.denied.Count) {
    $first = ($agent.denied[0] -replace '\s+', ' ').Trim()
    if ($first.Length -gt 80) { $first = $first.Substring(0, 80) + '...' }
    $notes += "$($agent.denied.Count) denied, first: $first"
  }
  $agentBranches = Get-AgentBranches $wt $branchesBefore

  if ($NoAgent) {
    # Sanity: on an untouched worktree a check must give its expected verdict (most must fail).
    $expected = if ($t.noAgent) { $t.noAgent } else { 'fail' }
    $ok = ($expected -eq 'pass') -eq $pass
    $verdict = if ($ok) { "sane (untouched: $(if ($pass) { 'pass' } else { 'fail' }))" } else { "CHECK NOT SANE: untouched worktree gave $(if ($pass) { 'pass' } else { 'fail' }), expected $expected" }
  } else {
    $verdict = if ($pass) { 'PASS' } else { 'FAIL' }
  }
  $minutes = [math]::Round(((Get-Date) - $started).TotalMinutes, 1)
  Write-Host "    $verdict ($minutes min)$(if ($notes) { ': ' + ($notes -join '; ') })" -ForegroundColor $(if ($verdict -match '^(PASS|sane)') { 'Green' } else { 'Red' })

  $results += [pscustomobject]@{
    id = $t.id; title = $t.title; verdict = $verdict; pass = $pass; minutes = $minutes
    turns = if ($agent) { $agent.turns } else { $null }
    cost = if ($agent -and $agent.cost) { [math]::Round([double]$agent.cost, 2) } else { $null }
    notes = ($notes -join '; ')
  }

  $keep = $KeepWorktrees -or ($NoAgent -and $verdict -notmatch '^sane') -or (-not $NoAgent -and -not $pass)
  if ($keep) {
    if ($agentBranches.Count) { Write-Host "    Kept with the worktree: branch $($agentBranches -join ', ')" -ForegroundColor Yellow }
  } else {
    git -C $repo worktree remove --force $wt
    foreach ($b in $agentBranches) { git -C $repo branch -D --quiet $b }
  }
}

if ($NoAgent) {
  $insane = @($results | Where-Object { $_.verdict -notmatch '^sane' })
  Write-Host "`n$($results.Count - $insane.Count)/$($results.Count) checks sane."
  exit [int][bool]$insane.Count
}

$passed = @($results | Where-Object pass).Count
$lines = @(
  "# Eval run $runId",
  '',
  "Commit $commit, Claude setup $configHash, Model $(if ($Model) { $Model } else { 'default' }), " +
    "Passed $passed / $($results.Count)",
  '',
  '| Eval | Title | Result | Minutes | Turns | Cost (USD, est.) | Notes |',
  '|---|---|---|---|---|---|---|'
) + ($results | ForEach-Object {
    "| $($_.id) | $($_.title) | $($_.verdict) | $($_.minutes) | $($_.turns) | $($_.cost) | $($_.notes -replace '\|', '/') |"
  })
$resultsDir = Join-Path $PSScriptRoot 'results'
New-Item -ItemType Directory -Force $resultsDir | Out-Null
$md = Join-Path $resultsDir "$runId-$commit.md"
Set-Content -LiteralPath $md -Value ($lines -join "`n") -Encoding utf8
if (-not $Id) {
  [pscustomobject]@{ run = $runId; commit = $commit; configHash = $configHash; passed = $passed; total = $results.Count } |
    ConvertTo-Json | Set-Content -LiteralPath (Join-Path $resultsDir 'latest.json') -Encoding utf8
}
Write-Host "`nPassed $passed / $($results.Count). Results: $md. Transcripts and failed worktrees: $runDir"
exit [int]($passed -ne $results.Count)
