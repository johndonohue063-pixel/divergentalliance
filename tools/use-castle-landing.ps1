# tools/use-castle-landing.ps1  (no regex, fixed AddRange, safe parenthesis scan)
param(
  [string]$MainPath  = "lib\main.dart",
  [string]$Castle    = "lib\screens\castle_landing.dart",
  [string]$BtnPath   = "lib\ui\da_hybrid_button.dart"
)

$ErrorActionPreference = "Stop"

function Read-AllText([string]$p) {
  $rp = (Resolve-Path -LiteralPath $p)
  return [System.IO.File]::ReadAllText($rp)
}
function Write-AllText([string]$p, [string]$text) {
  [System.IO.File]::WriteAllText((Resolve-Path -LiteralPath $p), $text, [System.Text.UTF8Encoding]::new($false))
}
function Get-Indent([string]$s){
  $i = 0
  while($i -lt $s.Length -and ($s[$i] -eq ' ' -or $s[$i] -eq "`t")){ $i++ }
  if($i -gt 0){ return $s.Substring(0,$i) } else { return "" }
}

if (!(Test-Path -LiteralPath $MainPath))  { throw "Missing $MainPath" }
if (!(Test-Path -LiteralPath $Castle))    { throw "Missing $Castle (CastleLanding screen)" }
if (!(Test-Path -LiteralPath $BtnPath))   { throw "Missing $BtnPath (DAHybridButton definition)" }

# 0) Verify CastleLanding exists
$castleSrc = Read-AllText $Castle
if ($castleSrc.IndexOf("class CastleLanding extends") -lt 0) {
  throw "CastleLanding class not found in $Castle"
}

# 1) Make main.dart import CastleLanding and set home
$mainLines = [string[]](Get-Content -LiteralPath $MainPath)
$mainBak = "$MainPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item -LiteralPath $MainPath -Destination $mainBak -Force

$importLine = "import 'package:divergent_alliance/screens/castle_landing.dart';"

if (-not ($mainLines -contains $importLine)) {
  # insert after the last 'import 'package:' line, or at top
  $insertAt = 0
  for($i=0; $i -lt $mainLines.Length; $i++){
    $t = $mainLines[$i].Trim()
    if ($t.StartsWith("import 'package:")) { $insertAt = $i + 1 }
  }
  $newList = New-Object System.Collections.Generic.List[string]
  for($i=0; $i -lt $mainLines.Length; $i++){
    if ($i -eq $insertAt){ $newList.Add($importLine) }
    $newList.Add($mainLines[$i])
  }
  $mainLines = $newList.ToArray()
}

# replace existing home line if present, else insert under MaterialApp(
$homeSet = $false
for($i=0; $i -lt $mainLines.Length; $i++){
  if ($mainLines[$i].Contains("home:")){
    $indent = Get-Indent $mainLines[$i]
    $mainLines[$i] = "$indent" + "home: const CastleLanding(),"
    $homeSet = $true
    break
  }
}
if (-not $homeSet) {
  # find MaterialApp( and insert home on next line with +2 spaces
  for($i=0; $i -lt $mainLines.Length; $i++){
    if ($mainLines[$i].Contains("MaterialApp(")){
      $indent = Get-Indent $mainLines[$i] + "  "
      $newList = New-Object System.Collections.Generic.List[string]
      for($j=0; $j -lt $mainLines.Length; $j++){
        $newList.Add($mainLines[$j])
        if ($j -eq $i){
          $newList.Add($indent + "home: const CastleLanding(),")
        }
      }
      $mainLines = $newList.ToArray()
      $homeSet = $true
      break
    }
  }
}
Set-Content -LiteralPath $MainPath -Value $mainLines -Encoding UTF8
Write-Host "main.dart now imports castle_landing.dart and sets home: CastleLanding"

# 2) Determine DAHybridButton primary named parameter
$btnSrc = Read-AllText $BtnPath
$needle = "const DAHybridButton({"
$st = $btnSrc.IndexOf($needle)
if ($st -lt 0) { throw "Could not find DAHybridButton constructor in $BtnPath" }
$open = $btnSrc.IndexOf("{", $st)
$close = $btnSrc.IndexOf("})", $open+1)
if ($open -lt 0 -or $close -lt 0) { throw "Could not parse constructor braces in $BtnPath" }
$paramBlock = $btnSrc.Substring($open+1, $close-($open+1))

$required = New-Object System.Collections.Generic.List[string]
$all      = New-Object System.Collections.Generic.List[string]
foreach($raw in ($paramBlock -split "`r?`n")){
  $line = $raw.Trim()
  if ($line.Length -eq 0) { continue }
  if ($line.Contains("required this.")){
    $ix = $line.IndexOf("required this.") + 14
    $name = ($line.Substring($ix) -split "\W")[0]
    if($name){ $required.Add($name); $all.Add($name) }
  } elseif ($line.Contains("this.")) {
    $ix = $line.IndexOf("this.") + 5
    $name = ($line.Substring($ix) -split "\W")[0]
    if($name){ $all.Add($name) }
  } elseif ($line.StartsWith("required ")){
    $parts = $line.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
    if ($parts.Length -ge 3){
      $name = ($parts[2] -split "\W")[0]
      if($name){ $required.Add($name); $all.Add($name) }
    }
  } else {
    $parts = $line.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
    if ($parts.Length -ge 2){
      $name = ($parts[1] -split "\W")[0]
      if($name){ $all.Add($name) }
    }
  }
}
$primary = ($required | Where-Object { $_ -ne "onPressed" -and $_ -ne "key" } | Select-Object -First 1)
if (-not $primary) { $primary = ($all | Where-Object { $_ -ne "onPressed" -and $_ -ne "key" } | Select-Object -First 1) }
if (-not $primary) { throw "Could not determine a primary DAHybridButton parameter." }
Write-Host ("DAHybridButton primary param detected: {0}" -f $primary)

# 3) Update castle_landing.dart DAHybridButton calls: positional -> named ${primary}:
$castleBak = "$Castle.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item -LiteralPath $Castle -Destination $castleBak -Force

$src = Read-AllText $Castle
$target = "DAHybridButton("
$idx = 0
$sb = New-Object System.Text.StringBuilder
$repl = 0

while($true){
  $next = $src.IndexOf($target, $idx)
  if ($next -lt 0){
    [void]$sb.Append($src.Substring($idx))
    break
  }

  # copy up to call
  [void]$sb.Append($src.Substring($idx, $next - $idx))
  [void]$sb.Append($target)
  $argStart = $next + $target.Length

  # find matching ')' for this call, respecting simple strings and nested parens
  $depth = 1
  $p = $argStart
  $inStr = $false
  $strCh = ''
  while($p -lt $src.Length -and $depth -gt 0){
    $ch = $src[$p]
    if ($inStr){
      if ($ch -eq $strCh){
        $inStr = $false
      } elseif ($ch -eq '\'){
        $p++  # skip escaped char
      }
    } else {
      if ($ch -eq "'" -or $ch -eq '"'){ $inStr = $true; $strCh = $ch }
      elseif ($ch -eq '('){ $depth++ }
      elseif ($ch -eq ')'){ $depth-- }
    }
    $p++
  }
  if ($depth -ne 0){  # malformed, give up on this one
    [void]$sb.Append($src.Substring($argStart))
    break
  }
  $callEnd = $p - 1  # index of ')'
  $inner = $src.Substring($argStart, $callEnd - $argStart)

  # analyze first argument
  $innerTrimL = $inner.TrimStart()
  $leadLen = $inner.Length - $innerTrimL.Length
  $lead = $inner.Substring(0, $leadLen)
  $rest = $innerTrimL

  # find first ',' or ')'
  $k = 0
  while($k -lt $rest.Length -and $rest[$k] -ne ',' -and $rest[$k] -ne ')'){ $k++ }
  $firstSeg = $rest.Substring(0, $k)

  if ($firstSeg.IndexOf(":") -lt 0 -and $rest.Length -gt 0){
    # not named yet, inject "<primary>: "
    [void]$sb.Append($lead + "${primary}: " + $rest)
    $repl++
  } else {
    [void]$sb.Append($inner)  # already named or empty
  }

  # close the call's ')'
  [void]$sb.Append(')')
  $idx = $callEnd + 1
}

if ($repl -gt 0){
  Write-AllText $Castle ($sb.ToString())
  Write-Host ("Updated {0} DAHybridButton call(s) in castle_landing.dart to use '{1}:' as first named arg." -f $repl, $primary)
} else {
  Write-Host "No positional DAHybridButton calls found in castle_landing.dart."
}
