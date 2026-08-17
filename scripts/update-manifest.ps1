# update-manifest.ps1 - Step 10: register/replace a skill entry in skills-manifest.json (schema-safe) (Windows / macOS)
# Usage: pwsh|powershell -NoProfile -ExecutionPolicy Bypass -File update-manifest.ps1 -Name <name> -EntryJson '<json>'
param(
  [Parameter(Mandatory=$true)][string]$Name,
  [Parameter(Mandatory=$true)][string]$EntryJson,
  [string]$ManifestPath = (Join-Path $HOME '.cc-switch/skill-management/skills-manifest.json')
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $ManifestPath)) { throw "manifest not found: $ManifestPath" }
$m = Get-Content $ManifestPath -Raw | ConvertFrom-Json
# schema guard: never overwrite blindly
if (-not $m.version -or -not $m.canonical_root -or -not $m.skills) { throw "manifest schema invalid; refusing to overwrite" }
$entry = $EntryJson | ConvertFrom-Json
if (-not $entry.name) { $entry | Add-Member -NotePropertyName name -NotePropertyValue $Name -Force }
if (-not $entry.canonical_path) { $entry | Add-Member -NotePropertyName canonical_path -NotePropertyValue (Join-Path $m.canonical_root $Name) -Force }
if (-not $entry.source_type) { $entry | Add-Member -NotePropertyName source_type -NotePropertyValue 'local' -Force }
if ($null -eq $entry.local_modified) { $entry | Add-Member -NotePropertyName local_modified -NotePropertyValue $false -Force }
# normalize standard fields (keep schema uniform)
foreach ($f in @('repository','repository_url','branch','skill_subpath','installed_commit')) {
  if (-not $entry.PSObject.Properties[$f]) { $entry | Add-Member -NotePropertyName $f -NotePropertyValue '' -Force }
}
# set on manifest (replace existing entry)
$m.skills | Add-Member -NotePropertyName $Name -NotePropertyValue $entry -Force
$json = $m | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText($ManifestPath, $json, (New-Object System.Text.UTF8Encoding($false)))
"MANIFEST UPDATED $Name"
"total entries=$($m.skills.PSObject.Properties.Count)"
