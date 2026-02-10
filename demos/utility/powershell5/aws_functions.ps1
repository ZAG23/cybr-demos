# Connect-AWS -AccessKey "AAAAA..." -SecretKey "BBBBB..."
# Connect-AWS -AccessKey "AAAAA..." -SecretKey "BBBBB..." -Region "us-west-2"
function Connect-AWS {
    param(
        [Parameter(Mandatory=$true)]
        [string]$AccessKey,

        [Parameter(Mandatory=$true)]
        [string]$SecretKey,

        [string]$Region = "ca-central-1"
    )

    # Set credentials for this session only (NOT stored)
    Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey

    # Set region default
    Set-DefaultAWSRegion -Region $Region

    # Confirm identity
    try {
        $identity = Get-STSCallerIdentity
        Write-Host "`nConnected as:" -ForegroundColor Green
        Write-Host "  Account:  $($identity.Account)"
        Write-Host "  ARN:      $($identity.Arn)"
        Write-Host "  UserId:   $($identity.UserId)"
        return $identity
    }
    catch {
        Write-Host "Failed to authenticate with the provided AWS credentials." -ForegroundColor Red
        throw
    }
}

# Initialize AWS for instance profile (call at script start on EC2)
function Initialize-AWSInstanceProfile {
    param(
        [string]$Region = "us-east-1"
    )

    Write-Host "Initializing AWS with instance profile..." -ForegroundColor Cyan

    # Set default region
    Set-DefaultAWSRegion -Region $Region

    # Verify instance profile access
    try {
        $identity = Get-STSCallerIdentity
        Write-Host "`nInstance profile active:" -ForegroundColor Green
        Write-Host "  Account:  $($identity.Account)"
        Write-Host "  ARN:      $($identity.Arn)"
        Write-Host "  UserId:   $($identity.UserId)"
        return $true
    }
    catch {
        Write-Host "Warning: Could not verify instance profile credentials" -ForegroundColor Yellow
        Write-Host "Error: $_" -ForegroundColor Yellow
        return $false
    }
}

# Get-S3File "s3://bucket_name/dir1/dir2/file_name"
function Get-S3File {
    param([string]$Uri)
    $u = [Uri]$Uri
    $bucket = $u.Host
    # decode the key to remove %20 etc.
    $key = [System.Uri]::UnescapeDataString($u.AbsolutePath).TrimStart('/')
    $file = Split-Path $key -Leaf
    echo "Read-S3Object BucketName: $bucket Key: $key File: $file"
    Read-S3Object -BucketName $bucket -Key $key -File $file
}