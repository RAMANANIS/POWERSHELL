@echo off
echo =====================================================
echo Resetting Bluetooth cache and removing stale profiles
echo =====================================================

:: Stop Bluetooth service
net stop bthserv

:: Delete cached Bluetooth devices
del /f /q "%windir%\System32\DriverStore\FileRepository\bth*.*" >nul 2>&1
del /f /q "%windir%\System32\DriverStore\FileRepository\rtkbt*.*" >nul 2>&1

:: Delete paired device data
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\BTHPORT\Parameters\Devices" /f

:: Restart Bluetooth service
net start bthserv

echo =====================================================
echo Bluetooth cache cleared. Please restart your PC.
echo =====================================================
pause