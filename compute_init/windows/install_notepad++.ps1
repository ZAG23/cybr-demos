Write-Host "# Installing Notepad++ (if not already installed)"

$ErrorActionPreference = 'Stop'
$ConfirmPreference     = 'None'

$exePath = "$env:ProgramFiles\Notepad++\notepad++.exe"

# ------------------------------
# Check if Notepad++ already exists
# ------------------------------
if (Test-Path $exePath) {
    Write-Host "Notepad++ already installed:"
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
    -PassThru

Start-Sleep -Seconds 2

# ------------------------------
# Verify
# ------------------------------
if (Test-Path $exePath) {
    & $exePath -version
} else {
    Write-Warning "Notepad++ installation completed but executable not found."
}
