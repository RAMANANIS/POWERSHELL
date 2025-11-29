# Ensure running as Administrator
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator."
    Exit
}

Write-Host "`n=== Checking Installed Third-Party Drivers ===`n" -ForegroundColor Cyan

# Get all drivers from pnputil
$driversRaw = pnputil /enum-drivers | Out-String

$drivers = $driversRaw -split "Published Name :" | ForEach-Object {
    if ($_ -match "Driver package provider\s+:\s+(?<Provider>.*)") {
        $provider = $matches.Provider.Trim()
    }
    if ($_ -match "Class\s+:\s+(?<Class>.*)") {
        $class = $matches.Class.Trim()
    }
    if ($_ -match "Driver package version\s+:\s+(?<Version>.*)") {
        $version = $matches.Version.Trim()
    }
    if ($_ -match "Published Name\s+:\s+(?<Name>.*)") {
        $name = $matches.Name.Trim()
        [PSCustomObject]@{
            Provider = $provider
            Class    = $class
            Version  = $version
            Name     = $name
        }
    }
} | Where-Object { $_.Provider -ne "Microsoft" }

# Show installed third-party drivers
$drivers | Sort-Object Provider, Class, Version | Format-Table -AutoSize

# Identify duplicate (old version) drivers
$duplicates = $drivers | Group-Object Provider, Class | Where-Object { $_.Count -gt 1 }

# Identify drivers not in use
Write-Host "`n=== Checking for Unused (Unwanted) Drivers ===`n" -ForegroundColor Cyan
$unusedDrivers = @()

foreach ($drv in $drivers) {
    $check = pnputil /enum-devices /driver $drv.Name 2>$null
    if ($check -match "No devices are using this driver package") {
        $unusedDrivers += $drv
    }
}

if ($unusedDrivers.Count -gt 0) {
    Write-Host "`n⚠️ Found drivers not in use by any device:`n" -ForegroundColor Yellow
    $unusedDrivers | Format-Table Provider, Class, Version, Name -AutoSize
} else {
    Write-Host "`n✅ No unused drivers detected." -ForegroundColor Green
}

# Prompt user for action
$removeChoice = Read-Host "`nDo you want to remove old/unused drivers? (Y/N)"
if ($removeChoice -match '^[Yy]$') {

    # Remove old duplicate versions
    foreach ($group in $duplicates) {
        $sorted = $group.Group | Sort-Object Version
        $oldDrivers = $sorted[0..($sorted.Count - 2)]
        foreach ($old in $oldDrivers) {
            Write-Host "Removing old driver: $($old.Name) - $($old.Provider)" -ForegroundColor Red
            pnputil /delete-driver $old.Name /uninstall /force
        }
    }

    # Remove unused drivers
    foreach ($unused in $unusedDrivers) {
        Write-Host "Removing unused driver: $($unused.Name) - $($unused.Provider)" -ForegroundColor Red
        pnputil /delete-driver $unused.Name /uninstall /force
    }
} else {
    Write-Host "No drivers were removed." -ForegroundColor Cyan
}

Write-Host "`n=== Driver cleanup completed ===`n" -ForegroundColor Green
