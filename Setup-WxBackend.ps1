Param(
    [string]$ProjectPath = "C:\Users\JohnDonohue\dev\divergentalliance"
)

Write-Host "Using project path: $ProjectPath"

if (-not (Test-Path $ProjectPath)) {
    Write-Host "Project path does not exist: $ProjectPath"
    exit 1
}

Set-Location $ProjectPath

# 1, requirements.txt
$reqPath = Join-Path $ProjectPath "requirements.txt"
$neededLines = @(
    "fastapi==0.121.0"
    "uvicorn[standard]==0.38.0"
    "httpx==0.25.2"
)

if (Test-Path $reqPath) {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $backupPath = "$reqPath.bak.$timestamp"
    Write-Host "Backing up existing requirements.txt to $backupPath"
    Copy-Item $reqPath $backupPath -Force

    $existing = Get-Content $reqPath
    $newLines = New-Object System.Collections.Generic.List[string]

    foreach ($line in $existing) {
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            $newLines.Add($line)
        }
    }

    foreach ($need in $neededLines) {
        $found = $false
        foreach ($line in $newLines) {
            if ($line -like "$need*") {
                $found = $true
                break
            }
        }
        if (-not $found) {
            $newLines.Add($need)
        }
    }

    Write-Host "Updating requirements.txt"
    Set-Content -Path $reqPath -Value $newLines
}
else {
    Write-Host "Creating new requirements.txt"
    Set-Content -Path $reqPath -Value $neededLines
}

# 2, render.yaml blueprint
$renderPath = Join-Path $ProjectPath "render.yaml"
if (-not (Test-Path $renderPath)) {
    Write-Host "Creating render.yaml"
    $renderContent = @"
services:
  - type: web
    name: da-wx-backend
    env: python
    buildCommand: pip install -r requirements.txt
    startCommand: uvicorn wx_live_backend:app --host 0.0.0.0 --port \$PORT
    autoDeploy: true
"@
    Set-Content -Path $renderPath -Value $renderContent
}
else {
    Write-Host "render.yaml already exists, not overwriting"
}

Write-Host "Done, backend files prepared."
