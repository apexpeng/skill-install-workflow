# resolve-candidate.ps1 - Step 1/2: resolve a Skill source into staging (Windows / macOS)
# Usage: pwsh|powershell -NoProfile -ExecutionPolicy Bypass -File resolve-candidate.ps1 -Source "<url|path>" [-SubPath "skills/xxx"]
param(
  [Parameter(Mandatory=$true)][string]$Source,
  [string]$SubPath = '',
  [string]$StagingRoot = (Join-Path $HOME '.cc-switch/skill-management/staging'),
  [string]$WorkBase = ''
)
$ErrorActionPreference = 'Stop'
$IsWin = ($env:OS -eq 'Windows_NT')
if (-not $WorkBase) {
  $tmp = if ($IsWin) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { '/tmp' }
  $WorkBase = Join-Path $tmp 'dsh-skill-install'
}
New-Item -ItemType Directory -Path $StagingRoot -Force | Out-Null
New-Item -ItemType Directory -Path $WorkBase -Force | Out-Null

$result = [ordered]@{ name=''; source_type=''; repository=''; repository_url=''; branch=''; skill_subpath=''; commit=''; staging_path=''; skill_md_hash=''; file_count=0; warnings=@(); candidates=@() }

function Get-FrontmatterName([string]$mdPath) {
  $txt = [System.IO.File]::ReadAllText($mdPath)
  if ($txt -match '(?s)^\uFEFF?---\s*\r?\n(.*?)\r?\n---') { $fm = $Matches[1] } else { $fm = '' }
  if ($fm -match '(?m)^name\s*:\s*["'']?([^"''\r\n]+)') { return $Matches[1].Trim().Trim('"').Trim("'") }
  return ''
}

function Sanitize-Name([string]$n) {
  $n = ($n -replace '[^A-Za-z0-9_-]', '-').Trim('-')
  if ($n -eq '') { return '' }
  return $n.ToLowerInvariant()
}

function Stage-Dir([string]$srcDir, [string]$hintName) {
  if (-not (Test-Path (Join-Path $srcDir 'SKILL.md'))) { throw "no SKILL.md in $srcDir" }
  $fmName = Get-FrontmatterName (Join-Path $srcDir 'SKILL.md')
  $name = Sanitize-Name $(if ($hintName) { $hintName } elseif ($fmName) { $fmName } else { (Split-Path $srcDir -Leaf) })
  if ($name -eq '') { throw "cannot determine skill name for $srcDir" }
  $dest = Join-Path $StagingRoot $name
  if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
  New-Item -ItemType Directory -Path $dest -Force | Out-Null
  Get-ChildItem -Path $srcDir -Force | Where-Object { $_.Name -ne '.git' } | Copy-Item -Destination $dest -Recurse -Force
  $hash = (Get-FileHash (Join-Path $dest 'SKILL.md')).Hash
  $files = Get-ChildItem -Recurse -Force $dest -File | Where-Object { $_.FullName -notlike '*\.git\*' }
  return @{ dest=$dest; name=$name; hash=$hash; files=@($files).Count }
}

function Find-SkillDirs([string]$root) {
  $found = @()
  Get-ChildItem -Path $root -Directory | ForEach-Object {
    if (Test-Path (Join-Path $_.FullName 'SKILL.md')) { $found += $_.FullName }
  }
  Get-ChildItem -Path $root -Directory | ForEach-Object {
    Get-ChildItem -Path $_.FullName -Directory -ErrorAction SilentlyContinue | ForEach-Object {
      if (Test-Path (Join-Path $_.FullName 'SKILL.md')) { $found += $_.FullName }
    }
  }
  return $found
}

$isUrl = $Source -match '^(https?://|git@)'
if ($isUrl) {
  # --- GitHub URL ---
  if ($Source -notmatch 'github\.com') { $result.warnings += 'non-github URL; treated as generic remote, git clone attempted' }
  if ($Source -match 'github\.com/([^/]+)/([^/]+?)(\.git)?(?:/|$)') {
    $owner = $Matches[1]; $repo = $Matches[2]
    $repoUrl = "https://github.com/$owner/$repo.git"
    $result.repository = "$owner/$repo"
    $result.repository_url = $repoUrl
    # branch/path from /tree/<branch>/<path> or /blob/<branch>/<path>
    $branch = ''; $path = ''
    if ($Source -match '/(?:tree|blob)/([^/]+)/(.*)$') { $branch = $Matches[1]; $path = $Matches[2] }
    elseif ($Source -match '\?ref=([^&]+)') { $branch = $Matches[1] }
    # commit from /commit/<hash>
    if ($Source -match '/commit/([0-9a-f]{7,40})') { $result.commit = $Matches[1] }
    if ($SubPath -ne '') { $path = $SubPath }
    # HEAD + default branch
    $head = git ls-remote $repoUrl HEAD 2>$null | ForEach-Object { ($_ -split "`t")[0] } | Select-Object -First 1
    if (-not $head) { throw "cannot reach $repoUrl (network/upstream issue) -> SOURCE_VERIFICATION_REQUIRED" }
    if ($result.commit -eq '') { $result.commit = $head }
    if ($branch -eq '') {
      $ref = git ls-remote --symref $repoUrl HEAD 2>$null | Select-String 'ref:' | ForEach-Object { ((($_.Line -split "`t")[0]) -split 'refs/heads/')[-1].Trim() } | Select-Object -First 1
      $branch = if ($ref) { $ref } else { 'main' }
    }
    $result.branch = $branch
    $repoDir = Join-Path $WorkBase ($owner + '__' + $repo)
    if (Test-Path $repoDir) { Remove-Item -Recurse -Force $repoDir }
    $prevEA = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    git clone --quiet --depth 1 --branch $branch $repoUrl $repoDir 2>&1 | Out-Null
    $ErrorActionPreference = $prevEA
    if (-not (Test-Path $repoDir)) { throw "clone failed for $repoUrl" }
    if ($path -ne '' -and $path -notmatch '^\.git') {
      $path = $path.TrimEnd('/')
      if ($path -match 'SKILL\.md$') { $path = Split-Path $path -Parent }
      $cand = Join-Path $repoDir $path
      if (-not (Test-Path $cand)) { throw "subpath not found in repo: $path" }
      $st = Stage-Dir $cand (Split-Path $path -Leaf)
      $result.name = $st.name; $result.staging_path = $st.dest; $result.skill_md_hash = $st.hash; $result.file_count = $st.files
      $result.skill_subpath = $path
      $result.source_type = 'github'
    } elseif (Test-Path (Join-Path $repoDir 'SKILL.md')) {
      # repo root IS the skill (single-skill repo): stage it directly
      $st = Stage-Dir $repoDir ''
      $result.name = $st.name; $result.staging_path = $st.dest; $result.skill_md_hash = $st.hash; $result.file_count = $st.files
      $result.skill_subpath = ''; $result.source_type = 'github'
    } else {
      # repo root: find skill dirs
      $cands = Find-SkillDirs $repoDir
      if ($cands.Count -eq 1) {
        $st = Stage-Dir $cands[0] ''
        $rel = $cands[0].Substring($repoDir.Length).TrimStart('/', '\').Replace('\', '/')
        $result.name = $st.name; $result.staging_path = $st.dest; $result.skill_md_hash = $st.hash; $result.file_count = $st.files
        $result.skill_subpath = $rel; $result.source_type = 'github'
      } elseif ($cands.Count -gt 1) {
        $result.candidates = @($cands | ForEach-Object { $_.Substring($repoDir.Length).TrimStart('/', '\').Replace('\', '/') })
        $result.warnings += "MULTIPLE skill candidates; re-run with -SubPath <one candidate>"
      } else {
        throw "no SKILL.md found at repo root (depth<=2); not a skill repo?"
      }
    }
  } else {
    throw "unsupported URL: $Source"
  }
} else {
  # --- local path / zip ---
  $src = $Source
  if (Test-Path $src -PathType Leaf) {
    if ($src -match '\.zip$') {
      $ex = Join-Path $WorkBase ('zip_' + [guid]::NewGuid().ToString('N'))
      Expand-Archive -Path $src -DestinationPath $ex -Force
      $src = $ex
    } elseif ($src -match 'SKILL\.md$') {
      $src = Split-Path $src -Parent
    } else {
      throw "file source is not a zip or SKILL.md: $src"
    }
  }
  if (-not (Test-Path $src)) { throw "source not found: $src" }
  $result.source_type = 'local'
  if (Test-Path (Join-Path $src 'SKILL.md')) {
    $st = Stage-Dir $src ''
    $result.name = $st.name; $result.staging_path = $st.dest; $result.skill_md_hash = $st.hash; $result.file_count = $st.files
    $result.skill_subpath = ''
  } else {
    $cands = Find-SkillDirs $src
    if ($cands.Count -eq 1) {
      $st = Stage-Dir $cands[0] ''
      $result.name = $st.name; $result.staging_path = $st.dest; $result.skill_md_hash = $st.hash; $result.file_count = $st.files
      $result.skill_subpath = $cands[0].Substring((Resolve-Path $src).Path.Length).TrimStart('/', '\').Replace('\', '/')
    } elseif ($cands.Count -gt 1) {
      $result.candidates = @($cands | ForEach-Object { $_.Substring((Resolve-Path $src).Path.Length).TrimStart('/', '\').Replace('\', '/') })
      $result.warnings += 'MULTIPLE skill candidates; re-run with -Source pointing at one skill dir'
    } else {
      throw 'no SKILL.md found in local source (depth<=2)'
    }
  }
}

$result | ConvertTo-Json -Depth 5
