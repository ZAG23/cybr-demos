Write-Host "# Installing Notepad++ (if not already installed)"

$ErrorActionPreference = 'Stop'
$ConfirmPreference     = 'None'

# Prefer x86 path (your case), but also check x64 just in case
$pathsToCheck = @(
    "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe",
    "$env:ProgramFiles\Notepad++\notepad++.exe"
) | Where-Object { $_ -and $_.Trim() -ne "" }

$exePath = $pathsToCheck | Where-Object { Test-Path $_ } | Select-Object -First 1

# ------------------------------
# Check if Notepad++ already exists
# ------------------------------
if ($exePath) {
    $ver = (Get-Item $exePath).VersionInfo.ProductVersion
    Write-Host "Notepad++ already installed: $exePath ($ver)"
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
# Install (no prompts, do not launch)
# ------------------------------
Write-Host "Installing Notepad++..."
Start-Process `
    -FilePath $installer `
    -ArgumentList "/S" `
    -NoNewWindow `
    -Wait | Out-Null

Start-Sleep -Seconds 2

# ------------------------------
# Verify (without launching Notepad++)
# ------------------------------
$exePath = $pathsToCheck | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($exePath) {
    $ver = (Get-Item $exePath).VersionInfo.ProductVersion
    Write-Host "Notepad++ installed: $exePath ($ver)"
} else {
    Write-Warning "Notepad++ install completed but not found in expected locations."
}
