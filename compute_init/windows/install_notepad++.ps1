Write-Host "# Installing Notepad++ (if not already installed)"

$ErrorActionPreference = 'Stop'
$ConfirmPreference     = 'None'

# ------------------------------
# Detect existing Notepad++ (PATH + both common install locations)
# ------------------------------
$cmd = Get-Command "notepad++.exe" -ErrorAction SilentlyContinue
if ($cmd) {
    Write-Host "Notepad++ already installed (PATH): $($cmd.Source)"
    & $cmd.Source -version
    return
}

$pathsToCheck = @(
    "$env:ProgramFiles\Notepad++\notepad++.exe",
    "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe"
) | Where-Object { $_ -and $_.Trim() -ne "" }

$exePath = $pathsToCheck | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($exePath) {
    Write-Host "Notepad++ already installed: $exePath"
    & $exePath -version
    return
}

# ------------------------------
# Prep directories
# ------------------------------
$downloadDir = "C:\bootstrap\tmp"
New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null

# ------------------------------
# Download installer
# ------------------------------
$installer = "$downloadDir\npp.Installer.exe"

Write-Host "Downloading Notepad++ installer..."
Invoke-WebRequest `
    -Uri "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.8.8/npp.8.8.8.Installer.exe" `
    -OutFile $installer

# ------------------------------
# Install (no prompts)
# ------------------------------
Write-Host "Installing Notepad++..."
Start-Process `
    -FilePath $installer `
    -ArgumentList "/S" `
    -NoNewWindow `
    -Wait `
    -PassThru | Out-Null

Start-Sleep -Seconds 2
