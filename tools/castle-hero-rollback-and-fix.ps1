param(
  [string]$Target = "lib\screens\castle_landing.dart",
  [string]$Expected = "assets/images/truck_hero.jpg"
)

$ErrorActionPreference = "Stop"

function ReadAll([string]$p){ if(!(Test-Path -LiteralPath $p)){ throw "Missing $p" } [string[]][IO.File]::ReadAllLines((Resolve-Path -LiteralPath $p)) }
function WriteAll([string]$p,[string[]]$L){ [IO.File]::WriteAllLines((Resolve-Path -LiteralPath $p), $L) }

# 0) Restore most recent backup if present (panic button)
$bakPrefix = "$Target.bak_"
$bakFile = Get-ChildItem -LiteralPath (Split-Path -Parent $Target) -Filter ($(Split-Path -Leaf $Target)+".bak_*") -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if($bakFile){
  Copy-Item -LiteralPath $bakFile.FullName -Destination $Target -Force
  Write-Host "Restored from backup: $($bakFile.Name)"
}else{
  Write-Host "No backup found, proceeding with current file."
}

# 1) Read fresh content and make a new backup snapshot
[string[]]$lines = ReadAll $Target
$bakNow = "$Target.bak_" + (Get-Date -Format "yyyyMMdd_HHmmss")
Copy-Item -LiteralPath $Target -Destination $bakNow -Force
Write-Host "Backup saved: $bakNow"

# 2) Insert _heroAsset helper if missing (after imports/parts/exports)
$hasHeroHelper = $false
foreach($L in $lines){ if($L.IndexOf("_heroAsset(") -ge 0){ $hasHeroHelper = $true; break } }

if(-not $hasHeroHelper){
  # find insertion index: after last import/part/export
  $insertIdx = 0
  for($i=0; $i -lt $lines.Length; $i++){
    $t = $lines[$i].TrimStart()
    if($t.StartsWith("import ") -or $t.StartsWith("export ") -or $t.StartsWith("part ")){
      $insertIdx = $i + 1
    } else {
      # stop at first non import/part/export line (but keep moving insertIdx if we saw any)
      if($insertIdx -gt 0){ break }
    }
  }

  $helper = @(
    "",
    "// hero helper, single source of truth for the landing banner image",
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

  $pre  = @()
  $post = @()
  if($insertIdx -gt 0){ $pre = $lines[0..($insertIdx-1)] }
  if($insertIdx -le ($lines.Length-1)){ $post = $lines[$insertIdx..($lines.Length-1)] }
  $lines = @($pre + $helper + $post)
  Write-Host "Inserted _heroAsset helper."
}

# 3) Normalize garbled paths, remove const on Image lines, fix _heroAsset calls
function CollapseSeq([string]$s,[string]$needle){
  $prev = $null; $out = $s
  do { $prev = $out; $out = $out.Replace("$needle$needle", $needle) } while($out -ne $prev)
  return $out
}

$changed = $false
for($i=0; $i -lt $lines.Length; $i++){
  $raw = $lines[$i]
  $cur = $raw

  # Collapse repeated assets/ and images/ sequences
  if(($cur.IndexOf("assets/") -ge 0) -or ($cur.IndexOf("images/") -ge 0)){
    $tmp = CollapseSeq($cur, "assets/")
    $tmp = CollapseSeq($tmp, "images/")
    if($tmp -ne $cur){ $cur = $tmp; $changed = $true }
  }

  # Backslashes to slashes for Dart assets
  if($cur.IndexOf("assets\\images\\truck_hero.jpg") -ge 0){
    $cur = $cur.Replace("assets\images\truck_hero.jpg", $Expected); $changed = $true
  }

  # Normalize any truck_hero reference to Expected
  if($cur.IndexOf("truck_hero") -ge 0 -and $cur.IndexOf($Expected) -lt 0){
    $cur = $cur.Replace("truck_hero.jpeg", $Expected).Replace("truck_hero.png", $Expected).Replace("truck_hero.jpg", $Expected)
    $changed = $true
  }

  # Remove accidental "const Image(" occurrences which break in non-const contexts
  if($cur.IndexOf("const Image(") -ge 0){
    $cur = $cur.Replace("const Image(", "Image("); $changed = $true
  }

  # Fix calls like _heroAsset(_hero, fit: ...) or _heroAsset('assets/...') to use named param
  if($cur.IndexOf("_heroAsset(") -ge 0){
    # if it contains "_hero," swap to named asset
    if($cur.IndexOf("_heroAsset(_hero") -ge 0){
      $cur = $cur.Replace("_heroAsset(_hero", "_heroAsset(asset: '$Expected'"); $changed = $true
    }
    # if it contains an inline string without asset:, add asset:
    # do a light transformation: replace "_heroAsset('" with "_heroAsset(asset: '"
    if($cur.IndexOf("_heroAsset('") -ge 0 -and $cur.IndexOf("asset: '") -lt 0){
      $cur = $cur.Replace("_heroAsset('", "_heroAsset(asset: '"); $changed = $true
    }
  }

  $lines[$i] = $cur
}

if($changed){
  WriteAll $Target $lines
  Write-Host "Normalized paths and fixed hero usages in $Target"
}else{
  Write-Host "No line-level fixes were needed."
}

# 4) Sanity echo of final hero references
Write-Host ("Final hero refs in {0}:" -f $Target)
Select-String -Path $Target -Pattern "assets/images/truck_hero.jpg" -SimpleMatch | ForEach-Object { $_.Line }
Write-Host "Done. In your flutter run terminal, press:  R"
