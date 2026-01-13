Write-Host "# Installing Chrome (if not already installed)"

$ErrorActionPreference = 'Stop'
$ConfirmPreference     = 'None'

$chromeExe = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"

# ------------------------------
# Check if Chrome already exists
# ------------------------------
if (Test-Path $chromeExe) {
    Write-Host "Chrome already installed:"
    & $chromeExe --version
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
# Install Chrome (no prompts)
# ------------------------------
Write-Host "Installing Chrome..."
$proc = Start-Process `
    -FilePath $installer `
    -ArgumentList "/silent /install" `
    -NoNewWindow `
    -Wait `
    -PassThru

Start-Sleep -Seconds 2
