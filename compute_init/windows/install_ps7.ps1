Write-Host "# Installing PowerShell 7.4 (if not already installed)"

$ErrorActionPreference = 'Stop'
$ConfirmPreference     = 'None'

$requiredVersion = [Version]'7.4.0'
$pwshExe = "$env:ProgramFiles\PowerShell\7\pwsh.exe"

# ------------------------------
# Check if PowerShell 7 is already installed
# ------------------------------
if (Test-Path $pwshExe) {
    $currentVersion = [Version](& $pwshExe -NoLogo -Command '$PSVersionTable.PSVersion.ToString()')

    if ($currentVersion -ge $requiredVersion) {
        Write-Host "PowerShell already installed: $currentVersion"
        return
    }
}

# ------------------------------
# Download MSI
# ------------------------------
$msi = "$env:TEMP\PowerShell-7.4.0-win-x64.msi"

Write-Host "Downloading PowerShell 7.4..."
Invoke-WebRequest `
    -Uri "https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/PowerShell-7.4.0-win-x64.msi" `
    -OutFile $msi

# ------------------------------
# Install (no prompts)
# ------------------------------
Write-Host "Installing PowerShell 7.4..."
Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList "/i `"$msi`" /qn /norestart" `
    -Wait `
    -NoNewWindow

# ------------------------------
# Cleanup (optional)
# ------------------------------
# Remove-Item $msi -Force

# ------------------------------
# Verify
# ------------------------------
if (Test-Path $pwshExe) {
    & $pwshExe -NoLogo -Command '$PSVersionTable.PSVersion'
} else {
    Write-Warning "PowerShell installation completed but pwsh.exe not found."
}
