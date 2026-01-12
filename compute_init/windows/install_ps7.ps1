Write-Host "Install PowerShell 7.4"

# Download and install PowerShell 7.4
Invoke-WebRequest -Uri https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/PowerShell-7.4.0-win-x64.msi -OutFile $env:TEMP\PowerShell-7.4.0-win-x64.msi
Start-Process -Wait -FilePath msiexec -ArgumentList "/i $env:TEMP\PowerShell-7.4.0-win-x64.msi /quiet /qn /norestart"
#Remove-Item $env:TEMP\PowerShell-7.4.0-win-x64.msi
