# install-canonical.ps1 - Step 9: move staged skill into canonical (with backup + cleanup) (Windows / macOS)
# Usage: pwsh|powershell -NoProfile -ExecutionPolicy Bypass -File install-canonical.ps1 -StagingPath <dir> -Name <name>
param(
  [Parameter(Mandatory=$true)][string]$StagingPath,
  [Parameter(Mandatory=$true)][string]$Name,
  [string]$Canonical = (Join-Path $HOME '.cc-switch/skills'),
  [string]$BackupRoot = (Join-Path $HOME '.cc-switch/backups')
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path (Join-Path $StagingPath 'SKILL.md'))) { throw "staging has no SKILL.md: $StagingPath" }
$dest = Join-Path $Canonical $Name
New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
if (Test-Path $dest) {
  $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
  $b = Join-Path $BackupRoot "install_${ts}_$Name"
  Move-Item -Path $dest -Destination $b -Force
  "BACKUP existing -> $b"
}
Copy-Item -Path $StagingPath -Destination $dest -Recurse
# cleanup staging entry
if (Test-Path $StagingPath) { Remove-Item -Recurse -Force $StagingPath }
$hash = (Get-FileHash (Join-Path $dest 'SKILL.md')).Hash
"INSTALLED $dest"
"hash=$hash"
