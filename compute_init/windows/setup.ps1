Write-Host "# Running Setup"

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
#--------------------------------------------------------------------------------------------------
New-Item -Path "C:\bootstrap\setup.started" -ItemType File -Force | Out-Null
#--------------------------------------------------------------------------------------------------
Start-Transcript -Append C:\bootstrap\setup_log.txt
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

#--------------------------------------------------------------------------------------------------
& "$ScriptRoot\install_nuget.ps1"
& "$ScriptRoot\install_chocolatey.ps1"
& "$ScriptRoot\install_git.ps1"
& "$ScriptRoot\install_ps7.ps1"
& "$ScriptRoot\install_notepad++.ps1"
#& "$ScriptRoot\install_ssh.ps1"
& "$ScriptRoot\install_chrome.ps1"
& "$ScriptRoot\install_aws_tools.ps1"
& "$ScriptRoot\install_iis.ps1"
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
Import-Module "$ScriptRoot\module_pin_to_taskbar.psm1" -Force

Write-Host "# Setting up Pins for Apps on Taskbar"

Pin-ToTaskbar "C:\Windows\notepad.exe"
Pin-ToTaskbar "C:\Windows\explorer.exe"
Pin-ToTaskbar "C:\Program Files (x86)\Notepad++\notepad++.exe"
Pin-ToTaskbar "C:\Program Files\Google\Chrome\Application\Chrome.exe"
Pin-ToTaskbar "C:\Windows\system32\WindowsPowerShell\v1.0\PowerShell.exe"
Pin-ToTaskbar "C:\Windows\System32\inetsrv\InetMgr.exe"
Pin-ToTaskbar "C:\Windows\system32\compmgmt.msc"
Pin-ToTaskbar "C:\Windows\system32\services.msc"
Pin-ToTaskbar "C:\Windows\system32\taskschd.msc"
#--------------------------------------------------------------------------------------------------
New-Item -Path "C:\bootstrap\setup.completed" -ItemType File -Force | Out-Null
#--------------------------------------------------------------------------------------------------
Stop-Transcript
Restart-Computer -ComputerName localhost -Force
#--------------------------------------------------------------------------------------------------
