Start-Transcript -Append C:\PSScriptLog.txt
Get-Date -UFormat "%A /%Y%m/%d %R %Z"
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

$ScriptRoot      = Split-Path -Parent $MyInvocation.MyCommand.Path
$CYBR_DEMOS_PATH = "C:\cybr-demos"

# Load utility functions
. "$CYBR_DEMOS_PATH\demos\utility\powershell5\dotenv_functions.ps1"
. "$CYBR_DEMOS_PATH\demos\utility\powershell5\aws_functions.ps1"
. "$CYBR_DEMOS_PATH\demos\tenant_vars.ps1"

# Local setup
Load-DotEnv "$ScriptRoot\vars.env"

$s3_uri_cpp_installer = $S3_URI_CPP_INSTALLER
$zip_file  = $ZIP_FILE
if (-not $s3_uri_cpp_installer)   { throw "S3_URI_CP_INSTALLER is empty after Load-DotEnv" }
if (-not $zip_file) { throw "ZIP_FILE is empty after Load-DotEnv" }


# Get file from S3
$region = $env:AWS_REGION
if (-not $region) { $region = "us-east-1" }

if ($env:AWS_ACCESS_KEY_ID -and $env:AWS_SECRET_ACCESS_KEY) {
    Connect-AWS -AccessKey $env:AWS_ACCESS_KEY_ID -SecretKey $env:AWS_SECRET_ACCESS_KEY -Region $region
} else {
    Write-Host "No AWS keys found using IAM Role"
    Initialize-AWSDefaultConfiguration -Region $region
}

$installerDir = Join-Path $ScriptRoot "installer"
mkdir $installerDir -Force

Get-S3File $s3_uri_cp_installer

Expand-Archive -Path $zip_file -DestinationPath $installerDir -Force
Set-Location $installerDir

msiexec.exe  /i "$installerDir\AIMWebService.msi" /qn

start-sleep -s 10

import-module webAdministration

# Manualy create users and grant safe untill cybrcli cmds added
# create app user on PVWA: 	AIMWebService
# create app user on PVWA: 	ccp_app1
# grant safe access to: CP Agent Prov User
# grant safe access to: App User

$siteName = "Default Web Site"
$appName = "AIMWebService"

# Disable the redirects
Set-WebConfiguration system.webServer/httpRedirect "IIS:\sites\$siteName" -Value @{enabled="false"}
Set-WebConfiguration system.webServer/httpRedirect "IIS:\sites\$siteName\$appName" -Value @{enabled="false"}

# If this SSL is set then the WDSL doc page will not be avalible ({fqdn}/AIMWebService/V1.1/AIM.asmx)
# IIS Setting: AIMWebService: SSL Client Certificates: Accept
$cfgSection = Get-IISConfigSection -Location "$siteName/$appName" -SectionPath "system.webServer/security/access";
Set-IISConfigAttributeValue -ConfigElement $cfgSection -AttributeName "sslFlags" -AttributeValue "Ssl, SslNegotiateCert";

# Configure a hardened server to accept OS user authentication
# When hardening a server, all non-administrator users become blocked from authenticating to the hardened server using OS user authentication.
# When Central Credential Provider is installed on a hardened PVWA, you need to reconfigure the authenticated users on this server:
# Go to the Local security policy. Under User Rights Assignment, select Access this computer from the network.
# In the policy's properties, add the Authenticated Users group.
# This allows all non-administrator users to connect to Central Credential Provider using OS user authentication and successfully retrieve secrets.

Get-Date -UFormat "%A /%Y%m/%d %R %Z"
Stop-Transcript