param(
  [string]$Target   = "lib\screens\castle_landing.dart",
  [string]$Expected = "assets/images/truck_hero.jpg"
)

$ErrorActionPreference = "Stop"

function ReadAll([string]$p){
  if(!(Test-Path -LiteralPath $p)){ throw "Missing $p" }
  return [string[]][IO.File]::ReadAllLines((Resolve-Path -LiteralPath $p))
}
function WriteAll([string]$p,[string[]]$L){ [IO.File]::WriteAllLines((Resolve-Path -LiteralPath $p), $L) }

# 0) Backup
[string[]]$lines = ReadAll $Target
$bakNow = "$Target.bak_" + (Get-Date -Format "yyyyMMdd_HHmmss")
Copy-Item -LiteralPath $Target -Destination $bakNow -Force
Write-Host "Backup saved: $bakNow"

# 1) Path + usage normalization, line by line, no regex
$changed = $false
for($i=0; $i -lt $lines.Length; $i++){
  $raw = $lines[$i]
  $cur = $raw

  # collapse duplicated segments safely
  while($cur.Contains("assets/assets/")){ $cur = $cur.Replace("assets/assets/", "assets/"); $changed = $true }
  while($cur.Contains("images/images/")){ $cur = $cur.Replace("images/images/", "images/"); $changed = $true }

  # Windows backslashes to Dart asset slashes
  if($cur.Contains("assets\images\truck_hero.jpg")){
    $cur = $cur.Replace("assets\images\truck_hero.jpg", $Expected); $changed = $true
  }

  # normalize any truck_hero extension to Expected
  if($cur.IndexOf("truck_hero") -ge 0 -and $cur.IndexOf($Expected) -lt 0){
    $cur = $cur.Replace("truck_hero.jpeg", $Expected).Replace("truck_hero.png", $Expected).Replace("truck_hero.jpg", $Expected)
    $changed = $true
  }

  # remove accidental const on Image constructor
  if($cur.Contains("const Image(")){
    $cur = $cur.Replace("const Image(", "Image("); $changed = $true
  }

  # fix _heroAsset bad usages
  if($cur.Contains("_heroAsset(")){
    if($cur.Contains("_heroAsset(_hero")){
      $cur = $cur.Replace("_heroAsset(_hero", "_heroAsset(asset: '$Expected'"); $changed = $true
    }
    if($cur.Contains("_heroAsset('") -and -not $cur.Contains("asset: '")){
      $cur = $cur.Replace("_heroAsset('", "_heroAsset(asset: '"); $changed = $true
    }
  }

  $lines[$i] = $cur
}

# 2) Ensure _heroAsset helper exists once; if missing, append a clean one at EOF
$hasHeroHelper = $false
foreach($L in $lines){ if($L.IndexOf("Widget _heroAsset(") -ge 0){ $hasHeroHelper = $true; break } }

if(-not $hasHeroHelper){
  $helper = @(
    "",
    "// --- auto-inserted helper: hero banner image ---",
    "Widget _heroAsset({",
    "  String asset = '$Expected',",
    "  double? width,",
    "  double? height,",
    "  BoxFit fit = BoxFit.cover,",
    "  FilterQuality filterQuality = FilterQuality.high,",
    "}) {",
    "  return Image.asset(",
    "    asset,",
    "    width: width,",
    "    height: height,",
    "    fit: fit,",
    "    filterQuality: filterQuality,",
    "  );",
    "}",
    ""
  )
  $lines = @($lines + $helper)
  $changed = $true
  Write-Host "Appended _heroAsset helper at end of file."
}

if($changed){
  WriteAll $Target $lines
  Write-Host "Normalized hero paths and usages in $Target"
}else{
  Write-Host "No changes were needed."
}

# 3) Show final references
Write-Host ("Final hero refs in {0}:" -f $Target)
Select-String -Path $Target -Pattern "assets/images/truck_hero.jpg" -SimpleMatch | ForEach-Object { $_.Line }
Write-Host "Done. In your flutter run terminal, press:  R"
