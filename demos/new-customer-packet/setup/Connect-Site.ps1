# Sign-in for Setup-NewCustomerPacket.ps1. Dot-source it.
#
# Device code: the script prints a code to enter at https://microsoft.com/devicelogin.
#   No pop-up window, works from any terminal. Uses the SharePoint Online Management Shell client
#   (a Microsoft first-party public client, no app registration) unless a ClientId is given.
#   The refresh token is cached per tenant so later runs sign in without a code; -NewSignIn ignores it.
#   Windows: %LOCALAPPDATA%\CopilotSharePointDemos, encrypted with DPAPI for the current user.
#   macOS: the login Keychain, service "CopilotSharePointDemos", one item per tenant and client.

$SpoManagementShellClientId = '9bc3ab49-b65d-410a-85ad-de819febfddc'
$TokenCacheName = 'CopilotSharePointDemos'
$OnMac = [bool]$IsMacOS   # $null (false) in Windows PowerShell 5.1

# $key is "<tenant>-<client id>": a file name under %LOCALAPPDATA% on Windows, a Keychain account on macOS.
function Save-RefreshToken([string]$key, [string]$refreshToken) {
    if (-not $refreshToken) { return }
    if ($OnMac) {
        & security add-generic-password -U -s $TokenCacheName -a $key -w $refreshToken | Out-Null
        return
    }
    $path = Join-Path (Join-Path $env:LOCALAPPDATA $TokenCacheName) "$key.token"
    New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
    ConvertTo-SecureString $refreshToken -AsPlainText -Force | ConvertFrom-SecureString | Set-Content -Path $path -Encoding ASCII
}

function Read-RefreshToken([string]$key) {
    if ($OnMac) {
        $token = & security find-generic-password -s $TokenCacheName -a $key -w 2>$null
        if ($LASTEXITCODE -ne 0) { return $null }
        return $token
    }
    $path = Join-Path (Join-Path $env:LOCALAPPDATA $TokenCacheName) "$key.token"
    if (-not (Test-Path $path)) { return $null }
    try {
        $secure = (Get-Content $path -Raw).Trim() | ConvertTo-SecureString
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
    } catch { return $null }
}

function Get-DeviceCodeToken([string]$SiteUrl, [string]$ClientId, [switch]$NewSignIn) {
    if (-not $ClientId) { $ClientId = $SpoManagementShellClientId }
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $uri = [Uri]$SiteUrl
    $resource = $uri.GetLeftPart('Authority')
    # contoso.sharepoint.com -> contoso.onmicrosoft.com, so the code signs in to the site's tenant.
    $tenant = ($uri.Host -replace '\.sharepoint\.com$', '' -replace '-admin$', '') + '.onmicrosoft.com'
    $authority = "https://login.microsoftonline.com/$tenant/oauth2/v2.0"
    $scope = "$resource/.default offline_access"
    $cacheKey = "$tenant-$ClientId"

    if (-not $NewSignIn) {
        $refresh = Read-RefreshToken $cacheKey
        if ($refresh) {
            try {
                $t = Invoke-RestMethod -Method Post -Uri "$authority/token" -Body @{
                    grant_type = 'refresh_token'; client_id = $ClientId; refresh_token = $refresh; scope = $scope
                }
                Save-RefreshToken $cacheKey $t.refresh_token
                Write-Host '  Signed in with the cached sign-in (-NewSignIn to sign in again).'
                return $t.access_token
            } catch {
                Write-Host '  Cached sign-in expired; asking for a new device code.'
            }
        }
    }

    Write-Host '  Device code sign-in: open the link below and enter the code (sign in with the site''s tenant account).'
    $dc = Invoke-RestMethod -Method Post -Uri "$authority/devicecode" -Body @{ client_id = $ClientId; scope = $scope }
    Write-Host "  $($dc.message)" -ForegroundColor Yellow
    $interval = [int]$dc.interval
    $deadline = (Get-Date).AddSeconds([int]$dc.expires_in)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds $interval
        try {
            $t = Invoke-RestMethod -Method Post -Uri "$authority/token" -Body @{
                grant_type  = 'urn:ietf:params:oauth:grant-type:device_code'
                client_id   = $ClientId
                device_code = $dc.device_code
            }
            Save-RefreshToken $cacheKey $t.refresh_token
            return $t.access_token
        } catch {
            $err = $null
            if ($_.ErrorDetails.Message) { $err = ($_.ErrorDetails.Message | ConvertFrom-Json).error }
            if ($err -eq 'authorization_pending') { continue }
            if ($err -eq 'slow_down') { $interval += 5; continue }
            if ($_.ErrorDetails.Message) { throw "Device code sign-in failed: $($_.ErrorDetails.Message)" }
            throw
        }
    }
    throw 'The device code expired before sign-in finished. Run the script again.'
}

function Connect-Site([string]$SiteUrl, [string]$ClientId, [switch]$NewSignIn) {
    Import-Module PnP.PowerShell -ErrorAction Stop
    $token = Get-DeviceCodeToken -SiteUrl $SiteUrl -ClientId $ClientId -NewSignIn:$NewSignIn
    Connect-PnPOnline -Url $SiteUrl -AccessToken $token
    return Get-PnPWeb
}
