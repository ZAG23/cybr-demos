Write-Host "# Installing Chocolatey (if not already installed)"

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey not found. Installing Chocolatey..."

    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol =
    [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

    iex ((New-Object System.Net.WebClient).DownloadString(
            'https://community.chocolatey.org/install.ps1'
    ))
}
