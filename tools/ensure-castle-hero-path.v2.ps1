param(
  [string]$Path = "lib\screens\castle_landing.dart",
  [string]$Expected = "assets/images/truck_hero.jpg"
)

$ErrorActionPreference = 'Stop'

function ReadAll([string]$p){ if(!(Test-Path -LiteralPath $p)){ throw "Missing $p" } [string[]][IO.File]::ReadAllLines((Resolve-Path -LiteralPath $p)) }
function WriteAll([string]$p,[string[]]$L){ [IO.File]::WriteAllLines((Resolve-Path -LiteralPath $p), $L) }

# 0) sanity on asset
$assetFs = $Expected -replace '/', '\'
if(!(Test-Path -LiteralPath $assetFs)){
  Write-Warning "Expected hero asset not found at: $assetFs"
}

# 1) read and backup
[string[]]$lines = ReadAll $Path
$bak = "$Path.bak_" + (Get-Date -Format "yyyyMMdd_HHmmss")
Copy-Item -LiteralPath $Path -Destination $bak -Force
Write-Host "Backup saved: $bak"

# 2) normalize path variants, no wildcards, no regex
$variants = @(
  "assets/images/truck_hero.png",
  "assets/images/truck_hero.jpeg",
  "assets/image/truck_hero.jpg",
  "assets/image/truck_hero.png",
  "assets/img/truck_hero.jpg",
  "assets/img/truck_hero.png",
  "images/truck_hero.jpg",
  "images/truck_hero.png",
  "assets\images\truck_hero.jpg",
  "assets\images\truck_hero.png",
  "assets\image\truck_hero.jpg",
  "assets\img\truck_hero.jpg",
  "truck_hero.jpg",
  "truck_hero.png"
)

$changed = $false
for($i=0; $i -lt $lines.Length; $i++){
  $raw = $lines[$i]

  if($raw.IndexOf('assets\images\truck_hero.jpg') -ge 0){
    $raw = $raw.Replace('assets\images\truck_hero.jpg', $Expected); $changed = $true
  }

  foreach($v in $variants){
    if($v -ne $Expected -and $raw.IndexOf($v) -ge 0){
      $raw = $raw.Replace($v, $Expected); $changed = $true
    }
  }

  $mentionsTruck = ($raw.IndexOf('truck_hero.jpg') -ge 0) -or ($raw.IndexOf('truck_hero.png') -ge 0) -or ($raw.IndexOf('truck_hero.jpeg') -ge 0)
  if($mentionsTruck -and $raw.IndexOf($Expected) -lt 0){
    $raw = $raw.Replace('truck_hero.jpeg', $Expected).Replace('truck_hero.png', $Expected).Replace('truck_hero.jpg', $Expected)
    $changed = $true
  }

  $lines[$i] = $raw
}

# 3) swap placeholder text with the image if present
for($i=0; $i -lt $lines.Length; $i++){
  $raw = $lines[$i]
  $hasCastleLoading = ($raw.IndexOf('Castle Loading') -ge 0)
  $hasHeroMissing   = ($raw.IndexOf('Hero image missing') -ge 0)
  if($hasCastleLoading -or $hasHeroMissing){
    $indent = ''
    for($k=0; $k -lt $raw.Length; $k++){ if($raw[$k] -eq ' ' -or $raw[$k] -eq "`t"){ $indent += $raw[$k] } else { break } }
    $lines[$i] = $indent + "Image.asset('$Expected', fit: BoxFit.cover),"
    $changed = $true
  }
}

# 4) fix accidental NetworkImage usage
for($i=0; $i -lt $lines.Length; $i++){
  $raw = $lines[$i]
  if(($raw.IndexOf('NetworkImage(') -ge 0) -and ($raw.IndexOf('truck_hero') -ge 0)){
    $start = $raw.IndexOf('NetworkImage(')
    if($start -ge 0){
      $openIdx = $start + 'NetworkImage('.Length
      $end = $raw.IndexOf(')', $openIdx)
      if($end -gt $start){
        $before = $raw.Substring(0, $start)
        $after  = $raw.Substring($end + 1)
        $lines[$i] = $before + "AssetImage('$Expected')" + $after
        $changed = $true
      }
    }
  }
}

if($changed){
  WriteAll $Path $lines
  Write-Host "Updated $Path with normalized hero path and corrections."
} else {
  Write-Host "No changes needed in $Path"
}

Write-Host ("References to expected asset in {0}:" -f $Path)
Select-String -Path $Path -Pattern $Expected -SimpleMatch | ForEach-Object { $_.Line }
Write-Host "Done. Press R in your running flutter terminal for Hot Restart."
