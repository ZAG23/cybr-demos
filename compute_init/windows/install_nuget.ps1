Write-Host "# Installing Nuget"

# Download and install NuGet
Invoke-WebRequest -Uri https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -OutFile C:\\bootstrap\NuGet.exe

