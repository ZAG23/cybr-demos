class PinToTaskBar_Verb
{
    [string]$KeyPath1  = "HKLM:\SOFTWARE\Classes"
    [string]$KeyPath2  = "*"
    [string]$KeyPath3  = "shell"
    [string]$KeyPath4  = "{:}"

    [Microsoft.Win32.RegistryKey]$Key2
    [Microsoft.Win32.RegistryKey]$Key3
    [Microsoft.Win32.RegistryKey]$Key4

    PinToTaskBar_Verb()
    {
        $this.Key2 = (Get-Item $this.KeyPath1).OpenSubKey($this.KeyPath2, $true)
    }

    [void] InvokePinVerb([string]$target)
    {
        Write-Host "Pinning $target to taskbar"
        $Shell = New-Object -ComObject "Shell.Application"
        $Folder = $Shell.Namespace((Get-Item $Target).DirectoryName)
        $Item = $Folder.ParseName((Get-Item $Target).Name)
        $Item.InvokeVerb("{:}")
    }

    [bool] CreatePinRegistryKeys()
    {
        $TASKBARPIN_PATH = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.taskbarpin";
        $ValueName = "ExplorerCommandHandler"
        $ValueData = (Get-ItemProperty $TASKBARPIN_PATH).ExplorerCommandHandler

        Write-Host "Creating Registry Key: $($this.Key2.Name)\$($this.KeyPath3)"
        $this.Key3 = $this.Key2.CreateSubKey($this.KeyPath3, $true)

        Write-Host "Creating Registry Key: $($this.Key3.Name)\$($this.KeyPath4)"
        $this.Key4 = $this.Key3.CreateSubKey($this.KeyPath4, $true)

        Write-Host "Creating Registry Key: $($this.Key4.Name)\$($valueName)"
        $this.Key4.SetValue($ValueName, $ValueData)

        return $true
    }

    [bool] DeletePinRegistryKeys()
    {
        Write-Host "Deleting Registry Key: $($this.Key4.Name)"
        $this.Key3.DeleteSubKey($this.KeyPath4)
        if ($this.Key3.SubKeyCount -eq 0 -and $this.Key3.ValueCount -eq 0)
        {
            Write-Host "Deleting Registry Key: $($this.Key3.Name)"
            $this.Key2.DeleteSubKey($this.KeyPath3)
        }
        return $true
    }

    [bool] Pin([string]$target)
    {
        try
        {
            $this.CreatePinRegistryKeys()
            $this.InvokePinVerb($target)
        }
        finally
        {
            #$this.DeletePinRegistryKeys()
        }
        return $true
    }
}

function Pin-ToTaskbar {
    param([Parameter(Mandatory)] [string]$Target)

    $pin = [PinToTaskBar_Verb]::new()
    $pin.Pin($Target) | Out-Null
}

Export-ModuleMember -Function Pin-ToTaskbar
