Write-Host "# Installing Chrome (if not already installed)"

$ErrorActionPreference = 'Stop'
$ConfirmPreference     = 'None'

# Common Chrome install locations (machine-wide)
$pathsToCheck = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
) | Where-Object { $_ -and $_.Trim() -ne "" }

$chromeExe = $pathsToCheck | Where-Object { Test-Path $_ } | Select-Object -First 1

# ------------------------------
# Check if Chrome already exists (NO launching)
# ------------------------------
if ($chromeExe) {
    $ver = (Get-Item $chromeExe).VersionInfo.ProductVersion
    Write-Host "Chrome already installed: $chromeExe ($ver)"
    return
}

# ------------------------------
# Prep directories
# ------------------------------
$downloadDir = "C:\bootstrap\tmp"
New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null

# ------------------------------
# Download Chrome installer
# ------------------------------
$installer = "$downloadDir\chrome_installer.exe"

Write-Host "Downloading Chrome installer..."
Invoke-WebRequest `
    -Uri "https://dl.google.com/chrome/install/375.126/chrome_installer.exe" `
    -OutFile $installer

# ------------------------------
# Install Chrome (no prompts, no launch)
# ------------------------------
Write-Host "Installing Chrome..."
Start-Process `
    -FilePath $installer `
    -ArgumentList "/silent /install" `
    -NoNewWindow `
    -Wait | Out-Null

Start-Sleep -Seconds 2

# ------------------------------
# Verify (file-based, no launch)
# ------------------------------
$chromeExe = $pathsToCheck | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($chromeExe) {
    $ver = (Get-Item $chromeExe).VersionInfo.ProductVersion
    Write-Host "Chrome installed: $chromeExe ($ver)"
} else {
    Write-Warning "Chrome installation completed but chrome.exe not found."
}
