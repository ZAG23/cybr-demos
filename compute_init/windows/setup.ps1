Write-Host "# Running Setup"

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
#--------------------------------------------------------------------------------------------------
New-Item -Path "C:\init_started.txt" -ItemType File | Out-Null
#--------------------------------------------------------------------------------------------------
Start-Transcript -Append C:\init_log.txt
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
#--------------------------------------------------------------------------------------------------
#& "$ScriptRoot\install_nuget.ps1"
& "$ScriptRoot\install_git.ps1"
& "$ScriptRoot\install_ps7.ps1"
& "$ScriptRoot\install_notepad++.ps1"
#& "$ScriptRoot\install_ssh.ps1"
& "$ScriptRoot\install_aws_tools.ps1"
& "$ScriptRoot\install_chrome.ps1"
& "$ScriptRoot\install_iis.ps1"
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
Import-Module "$ScriptRoot\module_pin_to_taskbar.psm1" -Force

Write-Host "# Setting up Pins for Apps on Taskbar"

[PinToTaskBar_Verb] $pin = [PinToTaskBar_Verb]::new();

$pin.Pin("C:\Windows\notepad.exe")
$pin.Pin("C:\Windows\explorer.exe")
$pin.Pin("C:\Program Files (x86)\Notepad++\notepad++.exe")
$pin.Pin("C:\Program Files\Google\Chrome\Application\Chrome.exe")
$pin.Pin("C:\Windows\system32\WindowsPowerShell\v1.0\PowerShell.exe")
$pin.Pin("C:\Windows\System32\inetsrv\InetMgr.exe")
$pin.Pin("C:\Windows\system32\compmgmt.msc")
$pin.Pin("C:\Windows\system32\services.msc")
$pin.Pin("C:\Windows\system32\taskschd.msc")
#--------------------------------------------------------------------------------------------------
New-Item -Path "C:\init_completed.txt" -ItemType File | Out-Null
#--------------------------------------------------------------------------------------------------
Stop-Transcript
#Restart-Computer -ComputerName localhost -Force
#--------------------------------------------------------------------------------------------------
