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

$s3_uri    = $S3_URI
$zip_file  = $ZIP_FILE
if (-not $s3_uri)   { throw "S3_URI is empty after Load-DotEnv" }
if (-not $zip_file) { throw "ZIP_FILE is empty after Load-DotEnv" }

$vault_fqdn = "vault-${TENANT_SUBDOMAIN}.privilegecloud.cyberark.cloud"

# Get file from S3
$region = $env:AWS_REGION
if (-not $region) { $region = "us-east-1" }

if ($env:AWS_ACCESS_KEY_ID -and $env:AWS_SECRET_ACCESS_KEY) {
    Connect-AWS -AccessKey $env:AWS_ACCESS_KEY_ID -SecretKey $env:AWS_SECRET_ACCESS_KEY -Region $region
} else {
    Write-Host "No AWS keys found using IAM Role"
    Initialize-AWSDefaultConfiguration -Region $region
}

Get-S3File $s3_uri

# Expand installer
$installerDir = Join-Path $ScriptRoot "installer"
Expand-Archive -Path $zip_file -DestinationPath $installerDir -Force
Set-Location $installerDir

# Steps to Create the silent.ini file in Record mode
# !Do not use cred file, advanced setup, vault IP, cred user name
#
# Instead of manually configuring a response file before running the silent CP installation,
# Record mode runs an interactive CP installation, collects the values provided during the installation,
# and saves them to a response file.
# The response file is fully defined and can be used when installing other CPs using Full silent mode.
# This is especially useful if you are setting up a wide-scale installation of CPs.
# $record_file = Join-Path $PWD "record.iss"
# .\setup.exe /r /f1"$record_file"

# Prepare silent response file
$record_file = Join-Path $CYBR_DEMOS_PATH "demos\credential_providers\agent_windows\setup\record.iss"
$silent_file = Join-Path $PWD "silent.iss"

Copy-Item -Path $record_file -Destination $silent_file -Force

# Read the whole file
$content = Get-Content -Path $silent_file -Raw

$apos = [char]39
$pattern = "szEdit1=$apos[^$apos]*$apos"
$replacement = "szEdit1=$apos$vault_fqdn$apos"

$content = [regex]::Replace($content, $pattern, $replacement)

# Write it back
Set-Content -Path $silent_file -Value $content

Start-Sleep -Seconds 1

& ".\setup.exe" "/s" "/f1$silent_file" "$env:INSTALLER_USR;$env:INSTALLER_PWD"

Start-Sleep -Seconds 2

Get-Date -UFormat "%A /%Y%m/%d %R %Z"
Stop-Transcript
