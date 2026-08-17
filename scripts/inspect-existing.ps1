# inspect-existing.ps1 - Step 4/5/6: candidate recall against canonical library (Windows / macOS)
# Usage: pwsh|powershell -NoProfile -ExecutionPolicy Bypass -File inspect-existing.ps1 -CandidateName <name> [-CandidateHash <sha256>] [-Keywords "kw1,kw2"]
param(
  [Parameter(Mandatory=$true)][string]$CandidateName,
  [string]$CandidateHash = '',
  [string]$Keywords = '',
  [string]$Canonical = (Join-Path $HOME '.cc-switch/skills'),
  [string]$ManifestPath = (Join-Path $HOME '.cc-switch/skill-management/skills-manifest.json')
)
$ErrorActionPreference = 'Continue'
$manifest = $null
if (Test-Path $ManifestPath) { $manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json }

function Get-FmText([string]$mdPath) {
  $txt = [System.IO.File]::ReadAllText($mdPath)
  if ($txt -match '(?s)^\uFEFF?---\s*\r?\n(.*?)\r?\n---') { $fm = $Matches[1] } else { $fm = '' }
  $name = ''; $desc = ''
  if ($fm -match '(?m)^name\s*:\s*["'']?([^"''\r\n]+)') { $name = $Matches[1].Trim().Trim('"').Trim("'") }
  if ($fm -match '(?m)^description\s*:\s*["'']?([^"''\r\n]+)') { $desc = $Matches[1].Trim().Trim('"').Trim("'") }
  return "$name $desc"
}

$exact = New-Object System.Collections.Generic.List[object]
$nameMatch = New-Object System.Collections.Generic.List[object]
$related = New-Object System.Collections.Generic.List[object]
$kws = @($Keywords -split '[,，;；\s]+' | Where-Object { $_ -ne '' })

Get-ChildItem -Force $canonical -Directory | ForEach-Object {
  $d = $_
  $md = Join-Path $d.FullName 'SKILL.md'
  if (-not (Test-Path $md)) { return }
  $hash = (Get-FileHash $md).Hash
  $fm = Get-FmText $md
  $src = ''
  $inst = ''
  if ($manifest -and $manifest.skills.PSObject.Properties.Name -contains $d.Name) {
    $e = $manifest.skills.($d.Name)
    $src = $e.source_type
    if ($e.PSObject.Properties['installed_commit'] -and $e.installed_commit) { $inst = [string]$e.installed_commit }
  }
  $commit8 = if ($inst.Length -gt 0) { $inst.Substring(0,[Math]::Min(8,$inst.Length)) } else { '' }
  $base = [PSCustomObject]@{ Name=$d.Name; Hash12=$hash.Substring(0,12); Modified=$d.LastWriteTime.ToString('yyyy-MM-dd HH:mm'); SourceType=$src; Commit=$commit8 }
  if ($CandidateHash -ne '' -and $hash -eq $CandidateHash) {
    $exact.Add($base)
  }
  if ($d.Name.ToLowerInvariant() -eq $CandidateName.ToLowerInvariant()) {
    $nameMatch.Add($base)
  }
  if ($kws.Count -gt 0) {
    $hits = @($kws | Where-Object { $fm.ToLowerInvariant().Contains($_.ToLowerInvariant()) })
    if ($hits.Count -gt 0) {
      $obj = $base | Select-Object *
      $obj | Add-Member -NotePropertyName Hits -NotePropertyValue ($hits -join ',') -Force
      $obj | Add-Member -NotePropertyName Fm -NotePropertyValue $fm.Substring(0,[Math]::Min(120,$fm.Length)) -Force
      $related.Add($obj)
    }
  }
}

"===== EXACT_DUPLICATES (same SKILL.md hash) ====="
if ($exact.Count -eq 0) { 'none' } else { $exact | Format-Table Name,Hash12,Modified,SourceType -AutoSize | Out-String }
"===== NAME_MATCHES (same name, case-insensitive) ====="
if ($nameMatch.Count -eq 0) { 'none' } else { $nameMatch | Format-Table Name,Hash12,Modified,SourceType,Commit -AutoSize | Out-String }
"===== RELATED_CANDIDATES (keyword recall, top 8) ====="
if ($related.Count -eq 0) { 'none' } else {
  $related | Sort-Object { $_.Hits.Split(',').Count } -Descending | Select-Object -First 8 | Format-Table Name,Hash12,Modified,Hits,Fm -AutoSize -Wrap | Out-String -Width 200
}
"candidate=$CandidateName hash=$CandidateHash keywords='$Keywords'"
