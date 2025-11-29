# --- Setup ---
$logFile = "D:\LOG\SystemHealthReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$logContent = @()

Function Write-Log {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
    $logContent += ($Message)
}

Write-Host "`n=== SYSTEM HEALTH CHECK ===" -ForegroundColor Cyan
Write-Host "Running checks, please wait...`n" -ForegroundColor Gray

# --- Windows Defender Status ---
try {
    $defender = Get-MpComputerStatus -ErrorAction Stop
    if ($defender.AntispywareEnabled -and $defender.RealTimeProtectionEnabled) {
        Write-Log "✔ Windows Defender is active" "Green"
    } else {
        Write-Log "✖ Windows Defender is NOT fully active" "Red"
    }
} catch {
    Write-Log "⚠ Unable to check Windows Defender status (possibly disabled or unavailable)" "Yellow"
}

# --- Firewall Status ---
try {
    $firewallOff = Get-NetFirewallProfile | Where-Object { $_.Enabled -eq $false }
    if ($firewallOff) {
        Write-Log "✖ Firewall is DISABLED for some profiles" "Red"
    } else {
        Write-Log "✔ Firewall is enabled for all profiles" "Green"
    }
} catch {
    Write-Log "⚠ Firewall check failed" "Yellow"
}

# --- Critical Services ---
$criticalServices = @("wuauserv", "bits", "WinDefend", "EventLog", "LanmanWorkstation")
foreach ($svc in $criticalServices) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq 'Running') {
        Write-Log "✔ Service '$svc' is running" "Green"
    } else {
        Write-Log "✖ Service '$svc' is NOT running or missing" "Red"
    }
}

# --- Pending Updates ---
try {
    $searcher = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher()
    $updates = $searcher.Search("IsInstalled=0").Updates
    if ($updates.Count -gt 0) {
        Write-Log "✖ $($updates.Count) updates are pending" "Yellow"
    } else {
        Write-Log "✔ No pending updates" "Green"
    }
} catch {
    Write-Log "⚠ Unable to check for Windows Updates" "Yellow"
}

# --- Disk Space Check (All Drives) ---
Write-Log "`n=== DISK SPACE STATUS ===" "Cyan"
Get-PSDrive -PSProvider FileSystem | ForEach-Object {
    $freeGB = [math]::Round($_.Free / 1GB, 2)
    if ($_.Free -lt 10GB) {
        Write-Log "✖ Low disk space on $($_.Name): ($freeGB GB free)" "Red"
    } else {
        Write-Log "✔ Disk space on $($_.Name): ($freeGB GB free)" "Green"
    }
}

# --- Time Sync Status ---
$timeStatus = w32tm /query /status 2>$null
if ($LASTEXITCODE -eq 0 -and $timeStatus -match "Last Successful Sync Time") {
    Write-Log "✔ Time service is synchronized" "Green"
} else {
    Write-Log "✖ Time service is NOT synchronized" "Red"
}

# --- System Integrity Check (Safe Verify) ---
Write-Log "`n=== SYSTEM INTEGRITY CHECK ===" "Cyan"
Write-Host "This will verify system files (no changes made)..." -ForegroundColor Gray
sfc /verifyonly | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Log "✔ System file integrity verified (no issues found)" "Green"
} else {
    Write-Log "✖ Potential system file issues (run sfc /scannow manually)" "Yellow"
}

# --- System Uptime ---
$uptimeSpan = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$days = [math]::Floor($uptimeSpan.TotalDays)
$hours = $uptimeSpan.Hours
Write-Log ("✔ System Uptime: {0} days {1} hours" -f $days, $hours) "Gray"

# --- Save Log File ---
Write-Host "`n=== CHECK COMPLETE ===" -ForegroundColor Cyan
$logContent | Out-File -FilePath $logFile -Encoding UTF8
Write-Host "`n✔ Log saved to: $logFile" -ForegroundColor Yellow
