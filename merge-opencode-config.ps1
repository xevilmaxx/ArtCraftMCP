# merge-opencode-config.ps1
# Merges the repo template (ArtCraft MCP servers) into the user's global
# opencode.json WITHOUT deleting anything the user already has
# (e.g. a "blender" server, "model"/"small_model", plugins).
#
# Usage:
#   merge-opencode-config.ps1 -Repo <repo\opencode.json> -GlobalPath <%USERPROFILE%\.config\opencode\opencode.json>
#
# Exit code 0 = merged (or already up to date), non-zero = failed, global untouched
# (a .bak timestamp copy is written before any write).

param(
  [Parameter(Mandatory = $true)][string]$Repo,
  [Parameter(Mandatory = $true)][string]$GlobalPath
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Repo)) {
  Write-Error "Repo template not found: $Repo"
  exit 1
}

$repoJson = Get-Content -LiteralPath $Repo -Raw | ConvertFrom-Json
if ($null -eq $repoJson.mcp -or $null -eq $repoJson.mcp.servers) {
  Write-Error "Repo template has no mcp.servers: $Repo"
  exit 1
}

$globalObj = $null
if (Test-Path -LiteralPath $GlobalPath) {
  try {
    $raw = Get-Content -LiteralPath $GlobalPath -Raw
    # OpenCode accepts JSONC: strip full-line // comments before parsing.
    # Only lines whose first non-whitespace chars are // are removed,
    # so https:// inside strings is left untouched.
    $cleaned = ($raw -split "`r?`n" | Where-Object { $_.TrimStart() -notlike '//*' }) -join "`n"
    if ($cleaned.Trim().Length -eq 0) { $globalObj = [pscustomobject]@{} }
    else { $globalObj = $cleaned | ConvertFrom-Json }
  } catch {
    Write-Error ("Existing global config is not valid JSON/JSONC, refusing to touch it: " + $GlobalPath)
    exit 1
  }
} else {
  $globalObj = [pscustomobject]@{}
}

# --- timestamped backup of the existing global file (if any) ---
if (Test-Path -LiteralPath $GlobalPath) {
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $bak = "$GlobalPath.$stamp.bak"
  Copy-Item -LiteralPath $GlobalPath -Destination $bak -Force
  Write-Output "Backup: $bak"
}

# --- ensure .mcp.servers exists as an object we can add to ---
if ($null -eq $globalObj.mcp) {
  $globalObj | Add-Member -NotePropertyName 'mcp' -NotePropertyValue ([pscustomobject]@{}) -Force
}
# mcp may be $null or an unexpected shape; normalize
if ($globalObj.mcp -isnot [pscustomobject]) {
  $globalObj.mcp = [pscustomobject]@{}
}
if ($null -eq $globalObj.mcp.servers) {
  $globalObj.mcp | Add-Member -NotePropertyName 'servers' -NotePropertyValue ([pscustomobject]@{}) -Force
}

# --- copy every repo server over (add or replace), keep everything else ---
foreach ($prop in $repoJson.mcp.servers.PSObject.Properties) {
  $globalObj.mcp.servers | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value -Force
}

# --- fill top-level gaps from the repo ($schema) but never clobber user's own ---
foreach ($prop in $repoJson.PSObject.Properties) {
  if ($prop.Name -eq 'mcp') { continue }
  if ($null -eq $globalObj.($prop.Name)) {
    $globalObj | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value -Force
  }
}

# --- serialize with 1-tab indentation (standard) ---
# NOTE: ConvertTo-Json on Windows PowerShell 5.1 emits ragged spacing
# (4 spaces, then 16, ...), so we re-indent its output to one tab per level.
$serverProps = @($repoJson.mcp.servers.PSObject.Properties)
$serverCount = $serverProps.Count
$rawOut = $globalObj | ConvertTo-Json -Depth 10
$outLines = @()
$depth = 0
foreach ($line in ($rawOut -split "`r?`n")) {
	$trimmed = $line.TrimStart()
	if ($trimmed.Length -eq 0) { continue }
	$emitDepth = $depth
	if ($trimmed.StartsWith('}') -or $trimmed.StartsWith(']')) {
		$emitDepth = [math]::Max(0, $depth - 1)
	}
	$outLines += (("`t" * $emitDepth) + $trimmed)
	$inStr = $false
	$esc = $false
	$delta = 0
	foreach ($ch in $trimmed.ToCharArray()) {
		if ($esc) { $esc = $false; continue }
		if ($ch -eq [char]92) { if ($inStr) { $esc = $true }; continue }
		if ($ch -eq '"') { $inStr = -not $inStr; continue }
		if (-not $inStr) {
			if ($ch -eq '{' -or $ch -eq '[') { $delta++ }
			elseif ($ch -eq '}' -or $ch -eq ']') { $delta-- }
		}
	}
	$depth = $depth + $delta
	if ($depth -lt 0) { $depth = 0 }
}
$out = ($outLines -join "`n") + "`n"
$dir = Split-Path -Parent $GlobalPath
if (-not (Test-Path -LiteralPath $dir)) {
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
# Use .NET to guarantee UTF-8 without BOM (some OpenCode builds dislike BOM)
[System.IO.File]::WriteAllText($GlobalPath, $out, (New-Object System.Text.UTF8Encoding $false))
Write-Output "Merged $serverCount server(s) into $GlobalPath"

$names = ($serverProps | ForEach-Object { $_.Name }) -join ', '
Write-Output "Servers from repo: $names"
exit 0
