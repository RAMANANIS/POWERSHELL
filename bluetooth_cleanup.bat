@echo off
echo ======================================================
echo Bluetooth Driver Cleanup Script - For TP-Link AX900
echo ======================================================
echo.
echo This will remove all non-TP-Link Bluetooth drivers
echo (Intel + Realtek) and leave only the correct TP-Link driver.
echo Make sure you run this file as Administrator.
echo.
pause

:: Remove old Realtek and Intel Bluetooth drivers
pnputil /delete-driver oem10.inf /uninstall /force
pnputil /delete-driver oem71.inf /uninstall /force
pnputil /delete-driver oem64.inf /uninstall /force
pnputil /delete-driver oem55.inf /uninstall /force
pnputil /delete-driver oem56.inf /uninstall /force
pnputil /delete-driver oem57.inf /uninstall /force
pnputil /delete-driver oem58.inf /uninstall /force
pnputil /delete-driver oem62.inf /uninstall /force
pnputil /delete-driver oem63.inf /uninstall /force
pnputil /delete-driver oem19.inf /uninstall /force
pnputil /delete-driver oem53.inf /uninstall /force

echo.
echo ======================================================
echo Cleanup completed. Please restart your PC now.
echo ======================================================
pause