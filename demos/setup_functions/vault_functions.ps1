function Update-IpAllowlist {
    param (
        [Parameter(Mandatory)] [string]$Subdomain,
        [Parameter(Mandatory)] [string]$IdentityToken,
        [Parameter(Mandatory)] [string]$IpListJson   # e.g. ["1.0.0.4/32","2.0.0.5/24"]
    )

    Write-Host "`nUpdating Privilege Cloud IP Allowlist: $IpListJson"

    $uri = "https://$Subdomain.privilegecloud.cyberark.cloud/api/advanced-settings/ip-allowlist"

    $headers = @{
        Authorization = "Bearer $IdentityToken"
        Accept        = "application/json"
    }

    # Build body exactly like bash: { "customerPublicIPs": <json array> }
    $bodyJson = "{ `"customerPublicIPs`": $IpListJson }"

    #Write-Host "PUT $uri"
    #Write-Host $bodyJson

    Invoke-RestMethod `
        -Method Put `
        -Uri $uri `
        -Headers $headers `
        -ContentType "application/json" `
        -Body $bodyJson `
        -ErrorAction Stop
}


function Add-IpToPrivilegeCloudAllowList {
    param (
        [string]$Subdomain,
        [string]$IdentityToken
    )

    # Get current public IP
    $ip = (Invoke-RestMethod -Uri "https://checkip.amazonaws.com").Trim()

    $uri = "https://$Subdomain.privilegecloud.cyberark.cloud/api/advanced-settings/ip-allowlist"

    # Fetch current allowlist
    $response = Invoke-RestMethod `
        -Method Get `
        -Uri $uri `
        -Headers @{
        Authorization = "Bearer $IdentityToken"
        Accept = "application/json"
    }

    # Check if IP already exists
    if ($response.customerPublicIPs -contains $ip) {
        Write-Host "Result: $ip is already allowed."
        return
    }

    $ipCidr = "$ip/32"
    Write-Host "Adding: $ipCidr to the allowlist."

    # Append IP
    $updatedIps = $response.customerPublicIPs + $ipCidr
    $updatedIpsJson = $updatedIps | ConvertTo-Json -Compress

    Update-IpAllowlist `
        -Subdomain $Subdomain `
        -IdentityToken $IdentityToken `
        -IpListJson $updatedIpsJson

    Write-Host "`nWaiting 10 minutes for Privilege Cloud Allow List update to complete..."
    Start-Sleep -Seconds 600
}
