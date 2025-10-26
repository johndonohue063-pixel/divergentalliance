# tools/fix-dahybrid-calls.ps1  — hardened reader
param(
  [string]$BtnPath = "lib\ui\da_hybrid_button.dart",
  [string]$UseFile = "lib\screens\truck_landing.dart"
)

$ErrorActionPreference = "Stop"

if (!(Test-Path -LiteralPath $BtnPath)) { throw "Missing $BtnPath" }
if (!(Test-Path -LiteralPath $UseFile)) { throw "Missing $UseFile" }

# Robust read helpers
function Read-AllText([string]$p) {
  $rp = (Resolve-Path -LiteralPath $p)
  return [System.IO.File]::ReadAllText($rp)
}

# Read the button source and extract constructor params between "const DAHybridButton({" and "})"
$btnSrc = Read-AllText $BtnPath
if ([string]::IsNullOrWhiteSpace($btnSrc)) { throw "Empty file: $BtnPath" }

$start = $btnSrc.IndexOf("const DAHybridButton({")
if ($start -lt 0) { throw "Could not find 'const DAHybridButton({' in $BtnPath" }
$after = $btnSrc.Substring($start)
$endIdx = $after.IndexOf("})")
if ($endIdx -lt 0) { throw "Could not find constructor closing '})' in $BtnPath" }
$paramBlock = $after.Substring($after.IndexOf("{") + 1, $endIdx - ($after.IndexOf("{") + 1))

# Parse names and which are required
$required = @()
$allParams = @()

foreach ($line in ($paramBlock -split "`r?`n")) {
  $t = $line.Trim()
  if (-not $t) { continue }
  if ($t -match "required\s+this\.(\w+)") { $required += $Matches[1]; $allParams += $Matches[1] }
  elseif ($t -match "this\.(\w+)") { $allParams += $Matches[1] }
  elseif ($t -match "required\s+\w+\s+(\w+)") { $required += $Matches[1]; $allParams += $Matches[1] }
  elseif ($t -match "(\w+)\s+(\w+)") { $allParams += $Matches[2] }
}

# Choose the primary named parameter
$primary = ($required | Where-Object { $_ -ne "onPressed" -and $_ -ne "key" } | Select-Object -First 1)
if (-not $primary) {
  $primary = ($allParams | Where-Object { $_ -ne "onPressed" -and $_ -ne "key" } | Select-Object -First 1)
}
if (-not $primary) { throw "Could not determine a primary parameter name for DAHybridButton." }

Write-Host ("DAHybridButton primary param detected: {0}" -f $primary)

# Backup the consumer file
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = "$UseFile.bak_$stamp"
Copy-Item -LiteralPath $UseFile -Destination $backup -Force
Write-Host "Backup saved to $backup"

# Load the consumer file safely
$text = Read-AllText $UseFile
if ([string]::IsNullOrWhiteSpace($text)) { throw "File appears empty or unreadable: $UseFile" }

# Match each DAHybridButton( ... ) block (non-greedy) across lines
$opts = [System.Text.RegularExpressions.RegexOptions]::Singleline
$rx = [regex]::new("DAHybridButton\((?<inner>.*?)\)", $opts)

$replacements = 0
$newText = $rx.Replace($text, {
  param($m)
  $inner = $m.Groups["inner"].Value
  if ($inner -eq $null) { return $m.Value }
  if ($inner.Trim().Length -eq 0) { return $m.Value }

  # Determine if first arg is already named
  $trimLeftLen = ($inner.Length - $inner.TrimStart().Length)
  $lead = $inner.Substring(0, $trimLeftLen)
  $rest = $inner.Substring($trimLeftLen)

  $colonIdx = $rest.IndexOf(":")
  $commaIdx = $rest.IndexOf(",")
  $firstTerminator = @($commaIdx, $rest.Length) | Where-Object { $_ -ge 0 } | Sort-Object | Select-Object -First 1

  if ($colonIdx -ge 0 -and $colonIdx -lt $firstTerminator) {
    return $m.Value  # already named
  }

  # Inject "<primary>: " before first token
  $newInner = $lead + "${primary}: " + $rest
  $script:replacements++
  return "DAHybridButton($newInner)"
})

# Write back
[System.IO.File]::WriteAllText((Resolve-Path -LiteralPath $UseFile), $newText, [System.Text.UTF8Encoding]::new($false))
Write-Host ("Rewrote {0} DAHybridButton call(s) to use '{1}:' as the first named argument." -f $replacements, $primary)
