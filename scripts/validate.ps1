# validate.ps1 - Step 12: post-install validation (per-skill or full library) (Windows / macOS)
# Usage: pwsh|powershell -NoProfile -ExecutionPolicy Bypass -File validate.ps1 [-Name <skill>]
param(
  [string]$Name = '',
  [string]$Canonical = (Join-Path $HOME '.cc-switch/skills'),
  [string[]]$ConsumerRoots = @((Join-Path $HOME '.claude/skills'), (Join-Path $HOME '.codex/skills'), (Join-Path $HOME '.agents/skills'))
)
$ErrorActionPreference = 'Continue'
$issues = New-Object System.Collections.Generic.List[string]
$pass = 0

function Check-Skill([string]$n) {
  if ($n.StartsWith('.')) { return }  # skip hidden infra dirs (e.g. .git) — not skills
  $target = Join-Path $Canonical $n
  if (-not (Test-Path $target)) { $script:issues.Add("canonical missing: $n"); return }
  $tItem = Get-Item -Force $target
  if ($tItem.LinkType) { $script:issues.Add("canonical is a LINK (must be entity): $n"); return }
  $tMd = Join-Path $target 'SKILL.md'
  if (-not (Test-Path $tMd)) { $script:issues.Add("canonical missing SKILL.md: $n"); return }
  $tHash = (Get-FileHash $tMd).Hash
  $script:pass++
  foreach ($root in $ConsumerRoots) {
    $link = Join-Path $root $n
    if (-not (Test-Path $link)) { continue }
    $item = Get-Item -Force $link
    if (-not $item.LinkType) { $script:issues.Add("consumer ENTITY (must be link): $link"); continue }
    if ($item.LinkType -ne 'SymbolicLink') { $script:issues.Add("consumer link not SymbolicLink ($($item.LinkType)): $link") }
    if ($item.Target -ne $target) { $script:issues.Add("consumer target mismatch: $link -> $($item.Target)") }
    if (-not (Test-Path $item.Target)) { $script:issues.Add("consumer target missing: $link") }
    $lMd = Join-Path $link 'SKILL.md'
    if (-not (Test-Path $lMd)) { $script:issues.Add("link missing SKILL.md: $link") }
    else {
      $lHash = (Get-FileHash $lMd).Hash
      if ($lHash -ne $tHash) { $script:issues.Add("hash mismatch via link: $link") } else { $script:pass++ }
    }
  }
}

if ($Name -ne '') {
  Check-Skill $Name
} else {
  Get-ChildItem -Force $Canonical -Directory | Where-Object { -not $_.Name.StartsWith('.') } | ForEach-Object { Check-Skill $_.Name }
  # full: count broken links across consumers
  foreach ($root in $ConsumerRoots) {
    Get-ChildItem -Force $root -Directory | ForEach-Object {
      if ($_.LinkType -and -not (Test-Path $_.Target)) { $script:issues.Add("BROKEN link: $(Join-Path $root $_.Name)") }
    }
  }
}

"===== VALIDATE ($(if($Name){$Name}else{'full'})) ====="
$issues | ForEach-Object { "FAIL: $_" }
"PASS checks=$pass  FAIL issues=$($issues.Count)"
if ($issues.Count -gt 0) { exit 1 } else { exit 0 }
