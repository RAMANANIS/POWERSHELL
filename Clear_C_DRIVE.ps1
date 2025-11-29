# === SAFETY-ENHANCED C: DRIVE CLEANUP SCRIPT (v2.1) ===
# Author: RAM + GPT-5
# Description: Safely clears temp, cache, and log files with logging and dry-run support.

$logPath = "$env:USERPROFILE\Desktop\CleanupLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$dryRun = $false  # Set $true to test without deleting anything

# --- Auto-switch to dry-run if not admin ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "⚠ Not running as Administrator. Switching to dry-run mode." -ForegroundColor Yellow
    $dryRun = $true
}

Write-Host "=== C: DRIVE CLEANUP STARTED ===" -ForegroundColor Cyan
Add-Content $logPath "=== Cleanup started at $(Get-Date) ===`n"

$global:totalCleared = 0
$global:freeBefore = (Get-PSDrive C).Free

function Log-And-Report($message, $color = "White") {
    Write-Host $message -ForegroundColor $color
    Add-Content $logPath $message
}

function Clear-Folder($path, $desc) {
    Write-Host "`n--- Cleaning: $desc ---" -ForegroundColor Cyan
    if (Test-Path $path) {
        $items = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue
        $sizeBefore = ($items | Measure-Object -Property Length -Sum).Sum
        if ($dryRun) {
            Log-And-Report "DRY-RUN: Would clear $desc ($([math]::Round($sizeBefore/1MB,2)) MB)" "Yellow"
        } else {
            try {
                Remove-Item "$path\*" -Recurse -Force -ErrorAction Stop
                $cleared = $sizeBefore / 1MB
                $global:totalCleared += $cleared
                Log-And-Report "✔ Cleared $desc ($([math]::Round($cleared,2)) MB cleared)" "Green"
            } catch {
                Log-And-Report ("✖ Failed to clean {0}: {1}" -f $desc, $_) "Red"
            }
        }
    } else {
        Log-And-Report "✖ $desc not found: $path" "Yellow"
    }
}

function Delete-OldFiles($path, $days, $desc) {
    Write-Host "`n--- Checking: $desc ---" -ForegroundColor Cyan
    if (Test-Path $path) {
        $cutoff = (Get-Date).AddDays(-$days)
        $files = Get-ChildItem $path -Recurse -File -ErrorAction SilentlyContinue |
                 Where-Object { $_.LastWriteTime -lt $cutoff }
        $totalSize = ($files | Measure-Object -Property Length -Sum).Sum / 1MB
        if ($dryRun) {
            Log-And-Report "DRY-RUN: Would delete $desc older than $days days ($([math]::Round($totalSize,2)) MB)" "Yellow"
        } else {
            $files | ForEach-Object {
                try { Remove-Item $_.FullName -Force -ErrorAction Stop }
                catch { Log-And-Report ("⚠ Could not delete: {0}" -f $_.FullName) "Gray" }
            }
            $global:totalCleared += $totalSize
            Log-And-Report "✔ Deleted $desc older than $days days ($([math]::Round($totalSize,2)) MB cleared)" "Green"
        }
    } else {
        Log-And-Report "✖ $desc not found: $path" "Yellow"
    }
}

# --- Confirm before real deletion ---
if (-not $dryRun) {
    $confirm = Read-Host "This will permanently delete files. Type 'YES' to continue"
    if ($confirm -ne "YES") {
        Log-And-Report "Cleanup aborted by user." "Red"
        exit
    }
}

# === SAFE CLEANUP TARGETS ===
Clear-Folder "$env:TEMP" "User Temp"
Clear-Folder "C:\Windows\Temp" "System Temp"
Clear-Folder "C:\Windows\SoftwareDistribution\Download" "Windows Update Cache"
Clear-Folder "C:\Windows\System32\DeliveryOptimization" "Delivery Optimization Files"

# --- WinSxS Cleanup ---
if ($dryRun) {
    Log-And-Report "DRY-RUN: Would trigger WinSxS cleanup" "Yellow"
} else {
    try {
        Dism.exe /Online /Cleanup-Image /StartComponentCleanup | Out-Null
        Log-And-Report "✔ WinSxS cleanup triggered" "Green"
    } catch {
        Log-And-Report "⚠ WinSxS cleanup failed to start" "Yellow"
    }
}

# --- Recycle Bin ---
if ($dryRun) {
    Log-And-Report "DRY-RUN: Would empty Recycle Bin" "Yellow"
} else {
    try {
        $shell = New-Object -ComObject Shell.Application
        $shell.Namespace(0xA).Items() | ForEach-Object { $_.InvokeVerb("delete") }
        Log-And-Report "✔ Recycle Bin emptied" "Green"
    } catch {
        Log-And-Report "⚠ Could not empty Recycle Bin" "Yellow"
    }
}

# --- Old logs and dumps ---
Delete-OldFiles "C:\Windows\Logs" 15 "Windows Logs"
Delete-OldFiles "C:\Windows\Minidump" 15 "Crash Dumps"
Delete-OldFiles "C:\CrashDumps" 15 "User Crash Dumps"

# --- Summary ---
$freeAfter = (Get-PSDrive C).Free
$totalSpaceCleared = ($freeAfter - $global:freeBefore) / 1MB

Log-And-Report "`n=== CLEANUP COMPLETE ===" "Cyan"
Log-And-Report "Total file deletions: $([math]::Round($global:totalCleared,2)) MB" "Magenta"
Log-And-Report "Actual disk space change: $([math]::Round($totalSpaceCleared,2)) MB" "Magenta"
Log-And-Report "Log saved to: $logPath" "Cyan"