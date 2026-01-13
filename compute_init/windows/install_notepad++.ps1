Write-Host "# Installing NotePad++"

Invoke-WebRequest "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.4.5/npp.8.4.5.Installer.exe" -OutFile "c:\\bootstrap\tmp\npp.Installer.exe"
Start-Process "c:\\bootstrap\tmp\npp.Installer.exe" /S -NoNewWindow -Wait -PassThru
start-sleep -s 2