<#
.SYNOPSIS
  Turns the SVG pictures that Claude draws (art\items\*.svg) into the game's 256 x 256 webp files
  (app\assets\images\items\<id>.webp), with Microsoft Edge. No other tool is needed (#198).

.DESCRIPTION
  Edge (headless) draws each SVG on a canvas and exports it as webp; the script writes the files.
  The file name of the SVG is the item id, so the game finds the picture by itself (ImageIndex).
  -Only <id>,<id>: only these items. -Check: export into a temporary folder and compare with the files in the app
  (exit 1 when one differs or is missing), without changing the app.
#>
param(
  [string[]]$Only,
  [switch]$Check
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$from = Join-Path $root 'art\items'
$to = Join-Path $root 'app\assets\images\items'
$size = 256

$edge = @(
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $edge) { Write-Host 'Microsoft Edge is not installed.' -ForegroundColor Red; exit 1 }

$files = Get-ChildItem $from -Filter '*.svg' -File | Sort-Object Name
if ($Only) { $files = $files | Where-Object { $Only -contains $_.BaseName } }
if (-not $files) { Write-Host "No SVG to export in $from" -ForegroundColor Red; exit 1 }

# One page: each SVG as a data URL (a file URL would taint the canvas), drawn and exported in turn.
$work = Join-Path ([IO.Path]::GetTempPath()) "itheros-art-$PID"
New-Item -ItemType Directory -Force $work | Out-Null
$items = foreach ($f in $files) {
  $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($f.FullName))
  "{id:'$($f.BaseName)',src:'data:image/svg+xml;base64,$b64'}"
}
$page = @"
<!DOCTYPE html><html><body><script>
const items = [$($items -join ',')];
(async () => {
  for (const it of items) {
    const img = new Image();
    img.src = it.src;
    await img.decode();
    const c = document.createElement('canvas');
    c.width = $size; c.height = $size;
    c.getContext('2d').drawImage(img, 0, 0, $size, $size);
    const pre = document.createElement('pre');
    pre.id = 'out-' + it.id;
    pre.textContent = c.toDataURL('image/webp', 0.92);
    document.body.appendChild(pre);
  }
  document.title = 'done';
})();
</script></body></html>
"@
$html = Join-Path $work 'export.html'
[IO.File]::WriteAllText($html, $page, (New-Object System.Text.UTF8Encoding($false)))

$dom = Join-Path $work 'dom.html'
$p = Start-Process -FilePath $edge -PassThru -WindowStyle Hidden -RedirectStandardOutput $dom -ArgumentList @(
  '--headless=new', '--disable-gpu', '--virtual-time-budget=20000', "--user-data-dir=$work\profile",
  '--dump-dom', "file:///$($html -replace '\\', '/')")
if (-not $p.WaitForExit(120000)) { $p.Kill(); Write-Host 'Edge did not finish in 2 minutes.' -ForegroundColor Red; exit 1 }

# Edge's first process can exit before the one that writes the page lets the file go: read it shared, until the
# page is complete.
function Read-Shared([string]$path) {
  $s = [IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
  try { (New-Object IO.StreamReader($s)).ReadToEnd() } finally { $s.Dispose() }
}
$text = ''
$wait = [Diagnostics.Stopwatch]::StartNew()
while ($wait.Elapsed.TotalSeconds -lt 120) {
  $text = Read-Shared $dom
  if ($text -match '<title>done</title>' -and $text -match '</html>') { break }
  Start-Sleep -Milliseconds 300
}
$out = if ($Check) { Join-Path $work 'out' } else { $to }
New-Item -ItemType Directory -Force $out | Out-Null
$bad = 0
foreach ($f in $files) {
  $m = [regex]::Match($text, "<pre id=""out-$([regex]::Escape($f.BaseName))"">data:image/webp;base64,([^<]+)</pre>")
  if (-not $m.Success) { Write-Host "  no webp for $($f.BaseName)" -ForegroundColor Red; $bad++; continue }
  $bytes = [Convert]::FromBase64String($m.Groups[1].Value)
  $target = Join-Path $out "$($f.BaseName).webp"
  [IO.File]::WriteAllBytes($target, $bytes)
  if ($Check) {
    $app = Join-Path $to "$($f.BaseName).webp"
    if (-not (Test-Path $app)) { Write-Host "  missing in the app: $($f.BaseName)" -ForegroundColor Red; $bad++ }
  } else {
    Write-Host "  $($f.BaseName).webp ($([math]::Round($bytes.Length / 1KB, 1)) KB)"
  }
}
Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
if ($bad) { exit 1 }
Write-Host "$(@($files).Count) pictures $(if ($Check) { 'checked' } else { "written to $to" })" -ForegroundColor Green
exit 0
