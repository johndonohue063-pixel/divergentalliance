param(
  [string]$Target = "lib\screens\castle_landing.dart",
  [string]$Expected = "assets/images/truck_hero.jpg"
)

$ErrorActionPreference = "Stop"

function ReadAll([string]$p){
  if(!(Test-Path -LiteralPath $p)){ throw "Missing $p" }
  return [string[]][IO.File]::ReadAllLines((Resolve-Path -LiteralPath $p))
}
function WriteAll([string]$p,[string[]]$L){ [IO.File]::WriteAllLines((Resolve-Path -LiteralPath $p), $L) }

# Backup
[string[]]$lines = ReadAll $Target
$bakNow = "$Target.bak_" + (Get-Date -Format "yyyyMMdd_HHmmss")
Copy-Item -LiteralPath $Target -Destination $bakNow -Force
Write-Host "Backup saved: $bakNow"

$changed = $false

for($i=0; $i -lt $lines.Length; $i++){
  $raw = $lines[$i]
  $cur = $raw

  # 1) Collapse duplicated path segments
  while($cur.Contains("assets/assets/")){ $cur = $cur.Replace("assets/assets/", "assets/"); $changed = $true }
  while($cur.Contains("images/images/")){ $cur = $cur.Replace("images/images/", "images/"); $changed = $true }

  # 2) Normalize any truck_hero.* to Expected
  if($cur.IndexOf("truck_hero") -ge 0 -and $cur.IndexOf($Expected) -lt 0){
    $cur = $cur.Replace("truck_hero.jpeg", $Expected).Replace("truck_hero.png", $Expected).Replace("truck_hero.jpg", $Expected)
    $changed = $true
  }

  # 3) Make Image.asset const-safe by replacing with a const Image(...) form, plus trailing comma
  if(($cur.IndexOf("Image.asset(") -ge 0) -and ($cur.IndexOf("truck_hero") -ge 0)){
    # keep indentation
    $indent = ""
    for($k=0; $k -lt $raw.Length; $k++){ $ch = $raw[$k]; if($ch -eq ' ' -or $ch -eq "`t"){ $indent += $ch } else { break } }
    $cur = $indent + "const Image(image: AssetImage('assets/images/truck_hero.jpg'), fit: BoxFit.cover),"
    $changed = $true
  }

  # 4) If someone mistakenly prefixed "const Image(" in a non-const context elsewhere, remove it
  if($cur.Contains("const Image(") -and -not $cur.Contains("AssetImage(")){
    $cur = $cur.Replace("const Image(", "Image(")
    $changed = $true
  }

  # 5) Fix _heroAsset named-arg call to positional (your helper wants one positional arg)
  if($cur.IndexOf("_heroAsset(asset: ") -ge 0){
    $cur = $cur.Replace("_heroAsset(asset: '", "_heroAsset('")
    $changed = $true
  }

  # 6) Normalize Windows slashes if present
  if($cur.Contains("assets\images\truck_hero.jpg")){
    $cur = $cur.Replace("assets\images\truck_hero.jpg", $Expected); $changed = $true
  }

  $lines[$i] = $cur
}

if($changed){
  WriteAll $Target $lines
  Write-Host "Applied line fixes in $Target"
}else{
  Write-Host "No changes needed."
}

Write-Host ("Final hero refs in {0}:" -f $Target)
Select-String -Path $Target -Pattern "assets/images/truck_hero.jpg" -SimpleMatch | ForEach-Object { $_.Line }
Write-Host "Done. In your flutter run terminal, press:  R"
