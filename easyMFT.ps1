# Copyright (c) 2024 ot2i7ba
# https://github.com/ot2i7ba/
# This code is licensed under the MIT License (see LICENSE for details).

# Function to run the script with administrative rights
function Run-WithAdminRights {
    # Check if the script is already running with administrative rights
    $adminRights = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")

    if (-not $adminRights) {
        # If not, restart the script with elevated rights
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        Exit
    }
}

# Call the function to run the script with administrative rights
Run-WithAdminRights
Set-Location -Path $PSScriptRoot

# Set the console to UTF-8 for output and input
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# Determine the list of installed .NET versions and prepare the output
$installedDotNetVersions = ""
try {
    $dotNetRuntimes = & dotnet --list-runtimes
    $dotNetRuntimes | ForEach-Object {
        if ($_ -match "Microsoft\.NETCore\.App\s(\d+\.\d+)") {
            $version = $Matches[1]
            if (-not $installedDotNetVersions.Contains(".NET$version")) {
                $installedDotNetVersions += ".NET$version, "
            }
        }
    }
    $installedDotNetVersions = $installedDotNetVersions.TrimEnd(", ")
} catch {
    $installedDotNetVersions = "Error determining .NET versions"
}

# Set the .NET version used based on the availability of .NET 6 or higher
$dotNet6OrHigherInstalled = $false
$dotNetVersionInfo = $null
try {
    $dotNetVersionInfo = & dotnet --version
    if ($dotNetVersionInfo -match "^(\d+)\.") {
        $majorVersion = [int]$Matches[1]
        if ($majorVersion -ge 6) {
            $dotNet6OrHigherInstalled = $true
        }
    }
} catch {
    $dotNet6OrHigherInstalled = $false
}

# Adjust the path to MFTECmd based on the installed .NET version
if ($dotNet6OrHigherInstalled) {
    $mftCmdPath = Join-Path -Path "$PSScriptRoot" -ChildPath "Binary\net6\MFTECmd\MFTECmd.exe"
    $usedDotNetVersion = ".NET 6 or higher"
} else {
    $mftCmdPath = Join-Path -Path "$PSScriptRoot" -ChildPath "Binary\net4\MFTECmd\MFTECmd.exe"
    $usedDotNetVersion = ".NET Framework 4"
}

# Calculate the MD5 hash of the script file and output the used .NET
$scriptPath = "$PSScriptRoot\easyMFT.ps1"
$md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$hash = [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($scriptPath))).Replace("-", "")
$expectedHash = Get-Content "$PSScriptRoot\Binary\hash.md5"

if ($hash -ne $expectedHash) {
    Write-Host "Hash value does NOT match the expected value!" -ForegroundColor Red
    Write-Host
} else {
    Write-Host "Hash value matches the expected value." -ForegroundColor Green
    Write-Host
}

Write-Host "KAPE (KROLL) Easy MFT Extract Script v0.2 by ot2i7ba"
Write-Host "====================================================="
Write-Host
Write-Host ".NET Versions: $installedDotNetVersions"
Write-Host "Used version: $usedDotNetVersion"
Write-Host "MD5 hash value of the script file: $hash"
Write-Host "This script is being executed from the following path: $(Get-Location)"
Write-Host

try {
    # Capture the moment of backup
    $backupTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    # Capture the name of the system
    $systemName = $env:COMPUTERNAME

    # Capture the local IP address and the MAC address
    $networkInfo = Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.InterfaceAlias -ne "Loopback Pseudo-Interface 1" } | Select-Object -First 1
    $localIP = $networkInfo.IPAddress
    $macAddress = (Get-NetAdapter -InterfaceIndex $networkInfo.InterfaceIndex).MACAddress

    # Capture the timezone used by the system
    $timezone = Get-TimeZone

    # Prompt the user to enter the drive letter where the `$MFT` is located (default is 'C'):
    $driveLetter = Read-Host "Drive letter where `$MFT is located (default is 'C'): "

    # Check if a drive letter was entered
    if ([string]::IsNullOrEmpty($driveLetter)) {
        $driveLetter = "C"
    }

    # Check if $driveLetter is a single letter
    if (!$driveLetter -match "^[A-Za-z]$") {
        throw "Invalid drive letter: $driveLetter"
    }

    # Create the timestamped filename
    $outputFolder = Join-Path -Path (Get-Location) -ChildPath "Evidence\KAPE_$backupTimestamp"

    # Create the output directory
    New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null

    # Log the captured information into the backup directory
    $logPath = Join-Path -Path $outputFolder -ChildPath "Backup_Log.txt"
    $logMessage = "Backup conducted at $backupTimestamp by system $systemName (local IP: $localIP, MAC address: $macAddress, timezone: $($timezone.DisplayName))."
    $logMessage | Out-File -FilePath $logPath -Append -Encoding utf8

    # Construct the path to Kape.exe in the 'Binary' subfolder
    $kapePath = Join-Path -Path "$PSScriptRoot" -ChildPath "Binary\KAPE\kape.exe"

    # Start Kape to extract the filesystem
    $kapeArgs = "--tsource $($driveLetter.ToUpper()):\ --target FileSystem --tdest $outputFolder --vhdx"
    Start-Process -FilePath $kapePath -ArgumentList $kapeArgs -Wait

    Write-Host "File system successfully extracted and stored in the directory '$outputFolder'."

    # Output folder for CSV files
    $mftCsvPath = Join-Path -Path $outputFolder -ChildPath "csv"
    New-Item -ItemType Directory -Path $mftCsvPath -Force | Out-Null

    # Function to export filesystem metadata
    function Export-MFTData {
        param (
            [string]$SourcePath,
            [string]$CsvFolder,
            [string]$CsvFileName
        )
        $fullCmd = "$mftCmdPath -f `"$SourcePath`" --csv `"$CsvFolder`" --csvf `"$CsvFileName`""
        Write-Host "Executed command: $fullCmd"
        & $mftCmdPath -f "$SourcePath" --csv "$CsvFolder" --csvf "$CsvFileName"
    }

    # Export $MFT, $LogFile, $J
    $mftSource = "$outputFolder\$driveLetter"

    Export-MFTData -SourcePath "$mftSource\`$MFT" -CsvFolder $mftCsvPath -CsvFileName "MFT.csv"
    Pause
    Export-MFTData -SourcePath "$mftSource\`$LogFile" -CsvFolder $mftCsvPath -CsvFileName "LogFile.csv"
    Pause
    Export-MFTData -SourcePath "$mftSource\`$Extend\`$J" -CsvFolder $mftCsvPath -CsvFileName "J.csv"
    Pause

    Write-Host "CSV files successfully created and stored in the directory: " -ForegroundColor Green
    Write-Host "$mftCsvPath" -ForegroundColor Green
    Write-Host
    Write-Host "Use the tool 'Binary\TimelineExplorer' to open the CSV files!" -ForegroundColor Red
    Write-Host
    Pause
} 

catch [System.UnauthorizedAccessException] {
    Write-Host "Error: You are neither God or Admin, lacking permission!" -ForegroundColor Red
    Write-Host "Hint: Look in the README.txt regarding execution guidelines." -ForegroundColor Red

    Write-Host
    Pause
}

catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host
    Pause
}
