# tools/fix-wcp-wrap.ps1  — restore-safe, no regex
param([string]$Path = "lib\screens\weather_center_pro.dart")

$ErrorActionPreference = "Stop"
if (!(Test-Path -LiteralPath $Path)) { throw "Missing $Path" }

function Read-AllText([string]$p){ [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $p)) }
function Write-AllText([string]$p,[string]$t){ [System.IO.File]::WriteAllText((Resolve-Path -LiteralPath $p), $t, [System.Text.UTF8Encoding]::new($false)) }

# backup first
$bak = "$Path.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item -LiteralPath $Path -Destination $bak -Force
Write-Host "Backup -> $bak"

$src = Read-AllText $Path

# ensure flutter material import exists
$materialImport = "import 'package:flutter/material.dart';"
if ($src.IndexOf($materialImport) -lt 0) {
  # insert after last import; otherwise at top
  $lines = [string[]](Get-Content -LiteralPath $Path)
  $insertAt = 0
  for($i=0;$i -lt $lines.Length;$i++){
    if ($lines[$i].Trim().StartsWith("import ")) { $insertAt = $i + 1 }
  }
  $newLines = New-Object System.Collections.Generic.List[string]
  for($i=0;$i -lt $lines.Length;$i++){
    if ($i -eq $insertAt){ $newLines.Add($materialImport) }
    $newLines.Add($lines[$i])
  }
  Set-Content -LiteralPath $Path -Value $newLines -Encoding UTF8
  $src = Read-AllText $Path
}

# find build(...) signature
$buildKey = "Widget build("
$buildIdx = $src.IndexOf($buildKey)
if ($buildIdx -lt 0) { throw "Could not find 'Widget build(' in $Path" }

# require BuildContext context nearby
$ctxIdx = $src.IndexOf("BuildContext context", $buildIdx)
if ($ctxIdx -lt 0) { throw "Could not find 'BuildContext context' in build() signature" }

# find 'return' after build
$returnIdx = $src.IndexOf("return", $ctxIdx)
if ($returnIdx -lt 0) { throw "Could not find 'return' inside build()" }

# walk to end of expression ';' honoring (), {}, [], and strings
$exprStart = $returnIdx + 6
while ($exprStart -lt $src.Length -and [char]::IsWhiteSpace($src[$exprStart])) { $exprStart++ }

$dp=0;$db=0;$ds=0;$inStr=$false;$q=[char]0
$i = $exprStart
while ($i -lt $src.Length) {
  $ch = $src[$i]
  if ($inStr) {
    if ($ch -eq $q) { $inStr=$false }
    elseif ($ch -eq '\') { $i++ }
  } else {
    if ($ch -eq "'" -or $ch -eq '"') { $inStr=$true; $q=$ch }
    elseif ($ch -eq '(') { $dp++ }
    elseif ($ch -eq ')') { $dp-- }
    elseif ($ch -eq '{') { $db++ }
    elseif ($ch -eq '}') { $db-- }
    elseif ($ch -eq '[') { $ds++ }
    elseif ($ch -eq ']') { $ds-- }
    elseif ($ch -eq ';' -and $dp -eq 0 -and $db -eq 0 -and $ds -eq 0) { break }
  }
  $i++
}
if ($i -ge $src.Length) { throw "Did not find end of return expression" }

$exprEnd = $i
$orig = $src.Substring($exprStart, $exprEnd - $exprStart).Trim()

# if already returns Material/Scaffold, do nothing
if ($orig.StartsWith("Material(") -or $orig.StartsWith("Scaffold(")) {
  Write-Host "build() already returns a Material/Scaffold. No change."
  exit 0
}

$newExpr = "Scaffold(body: $orig)"
$newSrc  = $src.Substring(0,$exprStart) + " " + $newExpr + $src.Substring($exprEnd)

Write-AllText $Path $newSrc
Write-Host "Wrapped build() return with Scaffold(body: ...)."
