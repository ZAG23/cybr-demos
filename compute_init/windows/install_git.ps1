Write-Host "# Installing Git (if not already installed)"

$ErrorActionPreference = 'Stop'
$ConfirmPreference     = 'None'

# ------------------------------
# Check if Git already exists
# ------------------------------
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "Git already installed:"
    git --version
    return
}

# ------------------------------
# Ensure Chocolatey is installed
# ------------------------------
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey not found. Installing Chocolatey..."

    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol =
    [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

    iex ((New-Object System.Net.WebClient).DownloadString(
            'https://community.chocolatey.org/install.ps1'
    ))
}

# ------------------------------
# Install Git
# ------------------------------
Write-Host "Installing Git..."
choco install git -y --no-progress

# ------------------------------
# Ensure Git is on PATH
# ------------------------------
$gitPath = "C:\Program Files\Git\cmd"

if ($env:Path -notlike "*$gitPath*") {
    $env:Path += ";$gitPath"

    [Environment]::SetEnvironmentVariable(
            "Path",
            [Environment]::GetEnvironmentVariable("Path", "Machine") + ";$gitPath",
            [EnvironmentVariableTarget]::Machine
    )
}

# ------------------------------
# Verify
# ------------------------------
git --version
