# link-consumers.ps1 - Step 11: create per-skill SymbolicLinks in consumer roots (Windows / macOS)
# Usage: pwsh|powershell -NoProfile -ExecutionPolicy Bypass -File link-consumers.ps1 -Name <name> [-Consumers claude,codex,agents]
param(
  [Parameter(Mandatory=$true)][string]$Name,
  [string]$Consumers = 'claude,codex,agents',
  [string]$Canonical = (Join-Path $HOME '.cc-switch/skills')
)
$ErrorActionPreference = 'Stop'
$IsWin = ($env:OS -eq 'Windows_NT')
$target = Join-Path $Canonical $Name
if (-not (Test-Path $target)) { throw "canonical target missing: $target" }

$map = @{
  'claude' = Join-Path $HOME '.claude/skills'
  'codex'  = Join-Path $HOME '.codex/skills'
  'agents' = Join-Path $HOME '.agents/skills'
}
$report = New-Object System.Collections.Generic.List[string]

function Remove-Entry([string]$path) {
  if (-not (Test-Path $path)) { return }
  $item = Get-Item -Force $path
  if ($item.LinkType) {
    if ($IsWin) { cmd /c rmdir "`"$path`"" 2>&1 | Out-Null }  # removes reparse point only
    else { Remove-Item -Force $path }
  } else {
    Remove-Item -Path $path -Recurse -Force
  }
}

function New-Symlink([string]$link, [string]$dest) {
  if ($IsWin) {
    try { New-Item -ItemType SymbolicLink -Path $link -Target $dest -ErrorAction Stop | Out-Null; return }
    catch {
      cmd /c mklink /D "`"$link`"" "`"$dest`"" 2>&1 | Out-Null
      $i = Get-Item -Force $link -ErrorAction SilentlyContinue
      if ($i -and $i.LinkType) { return }
    }
    cmd /c mklink /J "`"$link`"" "`"$dest`"" 2>&1 | Out-Null  # junction fallback (still a link, never a copy)
  } else {
    try { New-Item -ItemType SymbolicLink -Path $link -Target $dest -ErrorAction Stop | Out-Null; return }
    catch {
      ln -s "$dest" "$link" 2>&1 | Out-Null
      $i = Get-Item -Force $link -ErrorAction SilentlyContinue
      if ($i -and $i.LinkType) { return }
    }
  }
  throw "FAILED to create link (no copy fallback): $link -> $dest"
}

foreach ($tok in ($Consumers -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })) {
  $root = if ($map.ContainsKey($tok)) { $map[$tok] } else { $tok }
  if (-not (Test-Path $root)) { $report.Add("SKIP consumer root missing: $root"); continue }
  # never touch codex system dirs (guard)
  if ($root -eq $map['codex'] -and $Name -in @('.system','_shared')) { $report.Add("REFUSE system dir: $Name"); continue }
  $link = Join-Path $root $Name
  if (Test-Path $link) {
    $item = Get-Item -Force $link
    if ($item.LinkType -and $item.Target -eq $target) { $report.Add("OK already linked: $link"); continue }
    $report.Add("CONFLICT existing entry (not our link): $link -> $($item.Target); not overwritten")
    continue
  }
  New-Symlink $link $target
  $item = Get-Item -Force $link
  $report.Add("LINK $link  $($item.LinkType) -> $target")
}
$report
"`nDONE"
