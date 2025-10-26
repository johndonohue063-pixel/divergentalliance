param(
  [string]$Path = "lib\screens\truck_landing.dart"
)

$ErrorActionPreference = "Stop"

if (!(Test-Path -LiteralPath $Path)) {
  throw "Missing file: $Path"
}

# backup with timestamp
$stamp   = Get-Date -Format "yyyyMMdd_HHmmss"
$backup  = "$Path.bak_$stamp"
Copy-Item -LiteralPath $Path -Destination $backup -Force

# read all lines
[string[]]$lines = Get-Content -LiteralPath $Path

function Get-Indent([string]$s) {
  $i = 0
  while ($i -lt $s.Length -and ($s[$i] -eq ' ' -or $s[$i] -eq "`t")) { $i++ }
  return $s.Substring(0, $i)
}

$replaced = 0
for ($i = 0; $i -lt $lines.Length; $i++) {
  $ln = $lines[$i]

  if ($ln -like "*onPressed:*") {
    # replace the entire onPressed body with a clean one-liner
    $indent = Get-Indent $ln
    $lines[$i] = "$indent" + 'onPressed: () { Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SizedBox.shrink())); },'
    $replaced++

    # blank following lines that belonged to the old body, until we hit a line that likely closed the property
    $j = $i + 1
    while ($j -lt $lines.Length -and `
           -not ($lines[$j] -like "*,)*" -or $lines[$j] -like "*},*" -or $lines[$j].Trim().EndsWith(","))) {
      $lines[$j] = ""
      $j++
    }
    if ($j -lt $lines.Length) { $lines[$j] = "" }  # also blank the closer line
    $i = $j
  }
}

Set-Content -LiteralPath $Path -Encoding UTF8 -Value $lines

Write-Host "Patched $replaced onPressed occurrence(s)."
Write-Host "Backup saved to $backup"
