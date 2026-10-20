# PreToolUse (Bash|PowerShell): the production gate (plan 0009 D1, D3).
# Claude works up to the gate and can't pass it: only the owner releases, merges PRs and pushes to main, and no
# shell command from Claude touches the release key. Exit 2 = block.
# Commands are read the way a shell reads them: heredoc and here-string bodies are dropped, quotes are respected,
# the command is split into parts (; && || | new lines), and each part is judged by the program it runs. So words in
# messages and notes don't count; running the program does. The cases are in scripts\test-gate.ps1.

function Remove-Bodies([string]$cmd) {
  # bash heredocs (<<EOF, <<'EOF', <<-"EOF" ... EOF) and PowerShell here-strings (@' ... '@, @" ... "@).
  $cmd = [regex]::Replace($cmd, "(?s)<<-?[ \t]*(['""]?)(\w+)\1([^\n]*)\n.*?\n[ \t]*\2[ \t]*(?=\r?\n|$)", '<<BODY$3')
  [regex]::Replace($cmd, "(?s)@(['""])[ \t]*\r?\n.*?\r?\n\1@", "'BODY'")
}

# Splits a command line into parts, each a list of words with the quotes removed.
function Split-Parts([string]$cmd) {
  $parts = New-Object System.Collections.ArrayList
  $words = New-Object System.Collections.ArrayList
  $word = New-Object System.Text.StringBuilder
  $inWord = $false
  $quote = $null
  for ($i = 0; $i -lt $cmd.Length; $i++) {
    $c = [string]$cmd[$i]
    $prev = if ($i -gt 0) { [string]$cmd[$i - 1] } else { '' }
    $next = if ($i + 1 -lt $cmd.Length) { [string]$cmd[$i + 1] } else { '' }
    if ($quote) {
      if ($c -eq $quote) { $quote = $null } else { [void]$word.Append($c) }
      continue
    }
    if ($c -eq "'" -or $c -eq '"') { $quote = $c; $inWord = $true; continue }
    $isRedirect = $c -eq '&' -and ($prev -eq '>' -or $next -eq '>')   # 2>&1, *>&1, &>file
    if ($c -match '[\s;|&]' -and -not $isRedirect) {
      if ($inWord) { [void]$words.Add($word.ToString()); [void]$word.Clear(); $inWord = $false }
      if ($c -match '[\n;|&]' -and $words.Count) { [void]$parts.Add(@($words)); $words.Clear() }
      continue
    }
    [void]$word.Append($c); $inWord = $true
  }
  if ($inWord) { [void]$words.Add($word.ToString()) }
  if ($words.Count) { [void]$parts.Add(@($words)) }
  , $parts
}

function Get-Base([string]$word) {
  (($word -split '[\\/]')[-1]).ToLower() -replace '\.exe$', ''
}

# Is this a linked worktree (an eval run), and which branch is checked out? From the repo the hook belongs to, or
# the -C directory of a git command.
function Get-RepoState([string]$dir) {
  $branch = "$(& git.exe -C $dir rev-parse --abbrev-ref HEAD 2>$null)".Trim()
  $dirs = @(& git.exe -C $dir rev-parse --path-format=absolute --git-dir --git-common-dir 2>$null)
  $linked = $dirs.Count -eq 2 -and $dirs[0].TrimEnd('/') -ne $dirs[1].TrimEnd('/')
  @{ Branch = $branch; Linked = $linked }
}

function Test-GitPush([string[]]$a, $state) {
  $opts = @($a | Where-Object { $_ -like '-*' })
  $pos = @($a | Where-Object { $_ -notlike '-*' })
  if ($state.Linked) { return 'this is a throwaway worktree (an eval run); nothing is pushed from it. Leave the commits here.' }
  if ($opts -contains '--all' -or $opts -contains '--mirror') { return 'Claude never pushes all branches (main among them).' }
  if ($opts -contains '--tags') { return 'version tags are the owner''s (release.ps1).' }
  $refspecs = @($pos | Select-Object -Skip 1)
  $usesHead = -not $refspecs.Count
  foreach ($r in $refspecs) {
    $r = $r.TrimStart('+')
    $src, $dst = if ($r.Contains(':')) { $r.Split(':', 2) } else { $r, $r }
    if ($dst -match '^(refs/heads/)?main$') { return 'Claude never pushes to main; push a branch and open a PR.' }
    if ($dst -match '^(refs/tags/)?v\d') { return 'version tags are the owner''s (release.ps1).' }
    if ($src -eq 'HEAD' -and $dst -eq 'HEAD') { $usesHead = $true }
  }
  if ($usesHead -and $state.Branch -eq 'main') { return 'Claude never pushes to main; push a branch and open a PR.' }
  $null
}

# The reason a command is blocked, or $null. $State (Branch, Linked) is for tests; by default it comes from git.
function Test-Gate([string]$Command, $State, [int]$Depth = 0) {
  if ($Depth -gt 3) { return $null }
  $root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
  foreach ($part in (Split-Parts (Remove-Bodies $Command))) {
    $w = @($part | ForEach-Object { $_.Trim('(', ')', '{', '}') } | Where-Object { $_ })
    while ($w.Count -and ($w[0] -in @('.', '&', '!', 'then', 'do', 'else', 'time', 'env', 'nohup', 'sudo') -or $w[0] -match '^\w+=')) {
      $w = @($w | Select-Object -Skip 1)
    }
    if (-not $w.Count) { continue }
    $prog = Get-Base $w[0]
    $a = @($w | Select-Object -Skip 1)

    # Wrappers: judge what they run.
    if ($prog -in @('powershell', 'pwsh')) {
      $f = [array]::FindIndex([string[]]$a, [Predicate[string]] { param($x) $x -in @('-File', '-f') })
      if ($f -ge 0 -and $f + 1 -lt $a.Count) {
        $prog = Get-Base $a[$f + 1]; $a = @($a | Select-Object -Skip ($f + 2))
      } else {
        $c = [array]::FindIndex([string[]]$a, [Predicate[string]] { param($x) $x -in @('-Command', '-c') })
        if ($c -ge 0) { $why = Test-Gate (($a | Select-Object -Skip ($c + 1)) -join ' ') $State ($Depth + 1); if ($why) { return $why } }
        continue
      }
    }
    if ($prog -in @('bash', 'sh', 'cmd')) {
      $c = [array]::FindIndex([string[]]$a, [Predicate[string]] { param($x) $x -in @('-c', '/c') })
      if ($c -ge 0) { $why = Test-Gate (($a | Select-Object -Skip ($c + 1)) -join ' ') $State ($Depth + 1); if ($why) { return $why } }
      continue
    }

    # The release key: never named by a command that runs (echo and friends only print their words).
    if ($prog -notin @('echo', 'printf', 'write-output', 'write-host')) {
      foreach ($x in $w) {
        if ($x -match 'key\.properties|\.itheros\b|storePassword|keyPassword|\*\.properties') {
          return 'the release key (%USERPROFILE%\.itheros\, app\android\key.properties) is never read, printed or copied.'
        }
      }
    }

    switch ($prog) {
      'release.ps1' { if ($a -notcontains '-DryRun') { return 'only the owner runs release.ps1; Claude may run it with -DryRun.' } }
      'merge.ps1' { return 'only the owner merges pull requests (scripts\merge.ps1 or the GitHub app). Open a PR instead.' }
      'gh' {
        for ($i = 0; $i -lt $a.Count - 1; $i++) {
          if ($a[$i] -eq 'pr' -and $a[$i + 1] -eq 'merge') { return 'only the owner merges pull requests (scripts\merge.ps1 or the GitHub app). Open a PR instead.' }
          if ($a[$i] -eq 'release' -and $a[$i + 1] -in @('create', 'upload', 'edit', 'delete', 'delete-asset')) { return 'only the owner publishes or changes releases (release.ps1, RELEASING.md).' }
        }
        if ($a -contains 'api' -and ($a | Where-Object { $_ -match 'pulls/\d+/merge|mergePullRequest' })) {
          return 'only the owner merges pull requests (scripts\merge.ps1 or the GitHub app). Open a PR instead.'
        }
      }
      'git' {
        $dir = $root; $i = 0
        while ($i -lt $a.Count -and $a[$i] -like '-*') {
          if ($a[$i] -in @('-C', '-c', '--git-dir', '--work-tree', '--namespace')) {
            if ($a[$i] -eq '-C' -and $i + 1 -lt $a.Count) { $dir = $a[$i + 1] }
            $i += 2
          } else { $i++ }
        }
        if ($i -lt $a.Count -and $a[$i] -eq 'push') {
          $repoState = if ($State) { $State } else { Get-RepoState $dir }
          $why = Test-GitPush @($a | Select-Object -Skip ($i + 1)) $repoState
          if ($why) { return $why }
        }
      }
    }
  }
  $null
}

if ($MyInvocation.InvocationName -ne '.') {
  try {
    $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
  } catch {
    exit 0
  }
  $why = Test-Gate "$($payload.tool_input.command)"
  if ($why) {
    [Console]::Error.WriteLine("Blocked by the production gate (plan 0009): $why")
    exit 2
  }
  exit 0
}
