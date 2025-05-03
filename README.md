## ITFlow Asset Creation Script

This PowerShell script automates the creation of asset records in the ITFlow API. It detects system details (hostname, chassis type, manufacturer, model, serial number, OS, and network information) and sends them to the specified ITFlow endpoint.

### Features

* Detects chassis type (Desktop, Laptop, Tablet, Server) using `Get-WUChassisType`.
* Retrieves system information via CIM:

  * Manufacturer & Model
  * Serial Number
  * Operating System
* Determines the active network interface based on the default IPv4 route and verifies connectivity.
* Builds a JSON payload and sends it to the ITFlow asset creation API.

### Prerequisites

* PowerShell 5.1 or higher (Windows 10 / Server 2016+).
* Network connectivity to the ITFlow API endpoint.
* Appropriate API credentials with permissions to create assets.

### Configuration

Edit the following parameters at the top of the script:

```powershell
# API credentials and endpoint
$apiKey   = 'CHANGEME'
$siteUrl  = 'https://itflow.changeme.com'
$module   = '/api/v1/assets/create.php'
$uri      = "$siteUrl$module"
$clientId = 'CHANGEME'
```

* **\$apiKey**: Your ITFlow API key.
* **\$siteUrl**: Base URL of your ITFlow instance.
* **\$module**: API path for asset creation.
* **\$clientId**: Client identifier in ITFlow.

### Script Breakdown

1. **Get-WUChassisType**: Uses `Win32_SystemEnclosure.ChassisTypes` to determine if the system is a Desktop, Laptop, Tablet, or Server.
2. **Hostname**: Read from `$env:COMPUTERNAME`.
3. **Manufacturer & Model**: Queried via `Win32_ComputerSystem` and falls back to `Win32_BaseBoard` if the model is generic or missing.
4. **Serial Number**: Retrieved from `Win32_BIOS.SerialNumber`, excluding placeholder values.
5. **Operating System**: Obtained from `Win32_OperatingSystem.Caption` and `Version`.
6. **Network Interface**:

   * Identifies the default IPv4 route (`0.0.0.0/0`).
   * Selects the corresponding interface configuration.
   * Verifies connectivity by pinging `8.8.8.8`.
   * Extracts the IPv4 address (excluding APIPA `169.x.x.x`) and MAC address.
7. **Payload Construction**: Assembles all collected data into a JSON object.
8. **API Call**: Uses `Invoke-RestMethod` to POST the JSON payload and handles success or error responses.

### Usage

1. Clone or download this repository.
2. Edit the script parameters (`$apiKey`, `$siteUrl`, `$clientId`).
3. Run the script in an elevated PowerShell session:

   ```powershell
   .\create-assets.ps1
   ```
4. Verify the output for success or error messages.

### Error Handling

* Warnings are issued if chassis type is unexpected.
* API errors and exceptions are caught and displayed.

### Contributing

Feel free to fork and submit pull requests for improvements or bug fixes.

### License

This script is distributed "as is" under the GPL v2.0 License, WITHOUT WARRANTY OF ANY KIND
