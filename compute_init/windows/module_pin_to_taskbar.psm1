class PinToTaskBar_Verb {
    [string]$KeyPath1  = "HKLM:\SOFTWARE\Classes"
    [string]$KeyPath2  = "*"
    [string]$KeyPath3  = "shell"
    [string]$KeyPath4  = "{:}"

    [Microsoft.Win32.RegistryKey]$Key2
    [Microsoft.Win32.RegistryKey]$Key3
    [Microsoft.Win32.RegistryKey]$Key4

    PinToTaskBar_Verb() {
        $this.Key2 = (Get-Item $this.KeyPath1).OpenSubKey($this.KeyPath2, $true)
    }

    hidden [string] NormalizeTarget([string]$target) {
        # Normalize to full path when possible; keep raw for .msc etc.
        try { return (Resolve-Path -LiteralPath $target -ErrorAction Stop).Path.ToLowerInvariant() }
        catch { return $target.ToLowerInvariant() }
    }

    hidden [bool] IsPinned([string]$target) {
        $taskbarPins = Join-Path $env:APPDATA "Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
        if (-not (Test-Path $taskbarPins)) { return $false }

        $wanted = $this.NormalizeTarget($target)

        $shell = New-Object -ComObject WScript.Shell
        try {
            foreach ($lnk in Get-ChildItem -Path $taskbarPins -Filter *.lnk -ErrorAction SilentlyContinue) {
                try {
                    $sc = $shell.CreateShortcut($lnk.FullName)

                    $lnkTarget = ""
                    if ($sc.TargetPath) { $lnkTarget = $sc.TargetPath.ToString().ToLowerInvariant() }

                    $args = ""
                    if ($sc.Arguments) { $args = $sc.Arguments.ToString().ToLowerInvariant() }

                    if ($lnkTarget -eq $wanted) { return $true }
                    if ($args -and $args -like "*$wanted*") { return $true }
                } catch {
                    # ignore bad shortcuts
                }
            }
            return $false
        }
        finally {
            [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
        }
    }


    [void] InvokePinVerb([string]$target) {
        Write-Host "Pinning $target to taskbar"
        $Shell  = New-Object -ComObject "Shell.Application"
        $Folder = $Shell.Namespace((Get-Item $target).DirectoryName)
        $Item   = $Folder.ParseName((Get-Item $target).Name)
        $Item.InvokeVerb("{:}")
    }

    [bool] CreatePinRegistryKeys() {
        $TASKBARPIN_PATH = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.taskbarpin"
        $ValueName = "ExplorerCommandHandler"
        $ValueData = (Get-ItemProperty $TASKBARPIN_PATH).ExplorerCommandHandler

        $this.Key3 = $this.Key2.CreateSubKey($this.KeyPath3, $true)
        $this.Key4 = $this.Key3.CreateSubKey($this.KeyPath4, $true)
        $this.Key4.SetValue($ValueName, $ValueData)

        return $true
    }

    [bool] Pin([string]$target) {
        if ($this.IsPinned($target)) {
            Write-Host "Already pinned: $target"
            return $true
        }

        try {
            $this.CreatePinRegistryKeys()
            $this.InvokePinVerb($target)
        } finally {
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
