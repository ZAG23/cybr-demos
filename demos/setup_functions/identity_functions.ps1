function Get-IdentityToken {
    param (
        [Parameter(Mandatory = $true)]
        [string]$IspId,

        [Parameter(Mandatory = $true)]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [string]$ClientSecret
    )

    $uri = "https://$IspId.id.cyberark.cloud/oauth2/platformtoken"

    $headers = @{
        "X-IDAP-NATIVE-CLIENT" = "true"
        "Content-Type"        = "application/x-www-form-urlencoded"
    }

    $body = @{
        grant_type    = "client_credentials"
        client_id     = $ClientId
        client_secret = $ClientSecret
    }

    try {
        $response = Invoke-RestMethod `
            -Method Post `
            -Uri $uri `
            -Headers $headers `
            -Body $body
    }
    catch {
        Write-Error "ERROR: Get Identity Token request failed: $($_.Exception.Message)"
        exit 1
    }

    if (-not $response.access_token) {
        Write-Error "ERROR: Get Identity Token failed. Access token is empty or null."
        exit 1
    }

    # Return token (stdout equivalent)
    return $response.access_token
}

function Get-UserByName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$IspId,

        [Parameter(Mandatory = $true)]
        [string]$IdentityToken,

        [Parameter(Mandatory = $true)]
        [string]$Username
    )

    $uri = "https://$IspId.id.cyberark.cloud/CDirectoryService/GetUserByName"

    $headers = @{
        Authorization = "Bearer $IdentityToken"
        "Content-Type" = "application/json"
    }

    $body = @{
        username = $Username
    } | ConvertTo-Json -Compress

    try {
        $response = Invoke-RestMethod `
            -Method Post `
            -Uri $uri `
            -Headers $headers `
            -Body $body
    }
    catch {
        Write-Error "ERROR: GetUserByName failed: $($_.Exception.Message)"
        exit 1
    }

    return $response
}

function Reset-UserPassword {
    param (
        [Parameter(Mandatory = $true)]
        [string]$IspId,

        [Parameter(Mandatory = $true)]
        [string]$IdentityToken,

        [Parameter(Mandatory = $true)]
        [string]$UserUuid,

        [Parameter(Mandatory = $true)]
        [string]$UserSecret
    )

    $uri = "https://$IspId.id.cyberark.cloud/UserMgmt/ResetUserPassword"

    $headers = @{
        Authorization = "Bearer $IdentityToken"
        "Content-Type" = "application/json"
    }

    $body = @{
        ID          = $UserUuid
        newPassword = $UserSecret
    } | ConvertTo-Json -Compress

    try {
        Invoke-RestMethod `
            -Method Post `
            -Uri $uri `
            -Headers $headers `
            -Body $body
    }
    catch {
        Write-Error "ERROR: ResetUserPassword failed: $($_.Exception.Message)"
        exit 1
    }
}
