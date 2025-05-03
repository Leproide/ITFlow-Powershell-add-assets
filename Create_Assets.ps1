# Parameters
$apiKey  = 'CHANGEME'
$siteUrl = 'https://itflow.changeme.com'
$module  = '/api/v1/assets/create.php'
$uri     = "$siteUrl$module"
$clientId = 'CHANGEME'

# Check chassis type (Desktop, Laptop, Tablet, Server)
function Get-WUChassisType {
    [CmdletBinding()]
    param ()
    [int[]]$chassisType = Get-CimInstance Win32_SystemEnclosure | Select-Object -ExpandProperty ChassisTypes
    switch ($chassisType) {
        { $_ -in 3,4,5,6,7,15,16 } { return 'Desktop' }
        { $_ -in 8,9,10,11,12,14,18,21,31,32 } { return 'Laptop' }
        { $_ -in 30 } { return 'Tablet' }
        { $_ -in 17,23 } { return 'Server' }
        default {
            Write-Warning "Chassistype imprevisto: $chassisType"
            return 'Desktop'
        }
    }
}

# 1. Hostname
$hostname = $env:COMPUTERNAME

# 2. Asset type Get-WUChassisType
$assetType = Get-WUChassisType

# 3. Manufacturer and Model
$cs       = Get-CimInstance Win32_ComputerSystem
$sysMake  = $cs.Manufacturer.Trim()
$sysModel = $cs.Model.Trim()
if ([string]::IsNullOrWhiteSpace($sysModel) -or $sysModel -eq 'System Product Name') {
    $bb         = Get-CimInstance Win32_BaseBoard
    $assetMake  = $sysMake
    $assetModel = $bb.Product.Trim()
} else {
    $assetMake  = $sysMake
    $assetModel = $sysModel
}

# 4. Serial number (Exclude null “System Serial Number”)
$bios      = Get-CimInstance Win32_BIOS
$rawSerial = $bios.SerialNumber.Trim()
$serial    = if ($rawSerial -and $rawSerial -ne 'System Serial Number') { $rawSerial } else { '' }

# 5. Operating System
$os     = Get-CimInstance Win32_OperatingSystem
$osName = ($os.Caption + ' ' + $os.Version).Trim()

# 6. Active network interface
$ipAddr  = ''
$macAddr = ''

# Default IPv4 route
$defaultRoute = Get-NetRoute -DestinationPrefix '0.0.0.0/0' |
    Where-Object { $_.NextHop -ne '0.0.0.0' } |
    Sort-Object -Property RouteMetric |
    Select-Object -First 1

if ($defaultRoute) {
    $iface = Get-NetIPConfiguration |
        Where-Object { $_.InterfaceIndex -eq $defaultRoute.InterfaceIndex }

    # Test ping 8.8.8.8
    if (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet) {
        $ipAddr = ($iface.IPv4Address |
                   Where-Object { $_.IPAddress -notlike '169.*' }).IPAddress
        $adapter = Get-NetAdapter -InterfaceIndex $iface.InterfaceIndex -ErrorAction SilentlyContinue
        $macAddr = if ($adapter) { $adapter.MacAddress.Replace('-', ':') } else { '' }
    }
}

# 7. Optional parameters
$assetStatus        = 'Deployed'
$purchaseDate       = '0000-00-00'
$warrantyExpire     = '0000-00-00'
$installDate        = '0000-00-00'
$notes              = ''
$vendorId           = ''
$locationId         = '1'
$contactId          = '1'
$networkId          = '1'

# 8. Build JSON and send
$body = @{
    api_key               = $apiKey
    asset_name            = $hostname
    asset_type            = $assetType
    asset_make            = $assetMake
    asset_model           = $assetModel
    asset_serial          = $serial
    asset_os              = $osName
    asset_ip              = $ipAddr
    asset_mac             = $macAddr
    asset_status          = $assetStatus
    asset_purchase_date   = $purchaseDate
    asset_warranty_expire = $warrantyExpire
    asset_install_date    = $installDate
    asset_notes           = $notes
    asset_vendor_id       = $vendorId
    asset_location_id     = $locationId
    asset_contact_id      = $contactId
    asset_network_id      = $networkId
    client_id             = $clientId
} | ConvertTo-Json -Depth 4

try {
    $response = Invoke-RestMethod -Method Post -Uri $uri -Body $body -ContentType 'application/json'
    if ($response.success) {
        Write-Host "Asset created"
    } else {
        Write-Host "Error: Cant create asset"
    }
} catch {
    Write-Host "API Error: $_"
}
