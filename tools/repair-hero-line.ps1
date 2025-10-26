param(
  [string]$Path = "lib\screens\castle_landing.dart",
  [string]$Expected = "assets/images/truck_hero.jpg"
)

$ErrorActionPreference = "Stop"

function ReadAll([string]$p){
  if(!(Test-Path -LiteralPath $p)){ throw "Missing $p" }
  return [string[]][IO.File]::ReadAllLines((Resolve-Path -LiteralPath $p))
}
function WriteAll([string]$p,[string[]]$L){
  [IO.File]::WriteAllLines((Resolve-Path -LiteralPath $p), $L)
}

# 0) backup
[string[]]$lines = ReadAll $Path
$bak = "$Path.bak_" + (Get-Date -Format "yyyyMMdd_HHmmss")
Copy-Item -LiteralPath $Path -Destination $bak -Force
Write-Host "Backup saved: $bak"

# Helper: collapse any repeated "assets/" and "images/" in a path string
function NormalizeHeroPath([string]$s){
  $prev = $null
  $out  = $s
  # collapse repeated "assets/" sequences
  do {
    $prev = $out
    $out  = $out.Replace("assets/assets/", "assets/")
  } while($out -ne $prev)
  # collapse repeated "images/" sequences
  do {
    $prev = $out
    $out  = $out.Replace("images/images/", "images/")
  } while($out -ne $prev)
  return $out
}

# 1) scan and repair any line referencing the hero image or Image.asset
$changed = $false
for($i=0; $i -lt $lines.Length; $i++){
  $raw = $lines[$i]
  $check = $raw

  # Fix obviously garbled paths in-place first
  if($check.IndexOf("assets/") -ge 0 -and $check.IndexOf("truck_hero") -ge 0){
    $check = NormalizeHeroPath($check)
  }
  if($check.IndexOf("assets\\") -ge 0 -and $check.IndexOf("truck_hero") -ge 0){
    # flip backslashes to slashes for Dart assets
    $check = $check.Replace("assets\images\truck_hero.jpg", "assets/images/truck_hero.jpg")
  }

  $hasHero  = ($check.IndexOf("truck_hero") -ge 0)
  $hasImage = ($check.IndexOf("Image.asset(") -ge 0) -or ($check.IndexOf("AssetImage(") -ge 0)

  if($hasHero -or $hasImage){
    # keep leading indentation
    $indent = ""
    for($k=0; $k -lt $raw.Length; $k++){
      $ch = $raw[$k]
      if($ch -eq ' ' -or $ch -eq "`t"){ $indent += $ch } else { break }
    }

    # Force a clean, const-safe hero widget + trailing comma
    $clean = "const Image(image: AssetImage('assets/images/truck_hero.jpg'), fit: BoxFit.cover),"

    # Replace the whole line (surgical one-line swap)
    $lines[$i] = $indent + $clean
    $changed = $true
  }
  else{
    # keep any earlier small normalizations
    if($check -ne $raw){ $lines[$i] = $check; $changed = $true }
  }
}

if($changed){
  WriteAll $Path $lines
  Write-Host "Rewrote hero image line(s) with const-safe AssetImage and normalized path."
} else {
  Write-Host "No hero lines found to repair in $Path"
}

Write-Host ("Verify references in {0}:" -f $Path)
Select-String -Path $Path -Pattern "assets/images/truck_hero.jpg" -SimpleMatch | ForEach-Object { $_.Line }

Write-Host "Done. In your flutter run terminal, press:  R"
