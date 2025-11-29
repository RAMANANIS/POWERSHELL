$devices = Get-WmiObject Win32_PnPEntity | Where-Object {
    $_.ConfigManagerErrorCode -ne 0
}

if ($devices.Count -eq 0) {
    Write-Host "No missing or problematic drivers found."
} else {
    Write-Host "Devices with driver issues:"
    foreach ($device in $devices) {
        Write-Host "----------------------------------------"
        Write-Host "Name: $($device.Name)"
        Write-Host "Device ID: $($device.DeviceID)"
        Write-Host "Error Code: $($device.ConfigManagerErrorCode)"
        Write-Host "Status: $($device.Status)"
    }
}