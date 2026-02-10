Write-Host "# Installing IIS if not already installed"

$ErrorActionPreference = 'Stop'
$ConfirmPreference     = 'None'

# ------------------------------
# Install IIS + ASP.NET (only if not already installed)
# ------------------------------
$webServer = Get-WindowsFeature Web-Server

if (-not $webServer.Installed) {
    Install-WindowsFeature -Name Web-Server -IncludeManagementTools -Confirm:$false
}

$aspNet = Get-WindowsFeature Web-Asp-Net45
if (-not $aspNet.Installed) {
    Install-WindowsFeature -Name Web-Asp-Net45 -Confirm:$false
}

Get-WindowsFeature Web-Server

# ------------------------------
# Create self-signed cert (no prompts)
# ------------------------------
$dnsName = "www.example.com"

$cert = Get-ChildItem Cert:\LocalMachine\My |
        Where-Object { $_.Subject -eq "CN=$dnsName" } |
        Select-Object -First 1

if (-not $cert) {
    $cert = New-SelfSignedCertificate `
        -DnsName $dnsName `
        -CertStoreLocation "Cert:\LocalMachine\My" `
        -NotAfter (Get-Date).AddYears(5)
}

# ------------------------------
# IIS HTTPS binding
# ------------------------------
Import-Module WebAdministration

$siteName = "Default Web Site"

$binding = Get-WebBinding -Name $siteName -Protocol https -ErrorAction SilentlyContinue

if (-not $binding) {
    New-WebBinding `
        -Name $siteName `
        -IP "*" `
        -Port 443 `
        -Protocol https
}

# Attach cert (no overwrite prompts)
$sslPath = "IIS:\SslBindings\0.0.0.0!443"
if (-not (Test-Path $sslPath)) {
    New-Item `
        -Path $sslPath `
        -Thumbprint $cert.Thumbprint `
        -SSLFlags 0 `
        -Confirm:$false
}
