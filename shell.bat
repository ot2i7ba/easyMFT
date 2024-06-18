@echo off
set "psScriptPath=.\easyMFT.ps1"

cls
echo Checking for PowerShell availability...
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo PowerShell is not installed on this system or not available in the path.
    pause
    exit /b
)

cls
echo Checking for the existence of the PowerShell script...
if not exist "%psScriptPath%" (
    echo The PowerShell script was not found: %psScriptPath%
    pause
    exit /b
)

echo Executing the PowerShell script...
cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -File "%psScriptPath%"
if %ERRORLEVEL% neq 0 (
    echo An error occurred while executing the PowerShell script.
    pause
)
