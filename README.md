# KAPE (KROLL) Easy MFT Extract Script
The script aims to facilitate live forensic analysis on an active system by simplifying the use of the Master File Table (MFT). It allows on-site investigation of existing and former files based on MFT, enabling quick searches. This script is designed for scenarios where forensic analysts need to perform live investigations on active systems, leveraging the MFT for efficient file information retrieval.

The script extracts NTFS file system information with **kape.exe** and saves it in the Evidence directory. The individual extractions with timestamps are stored properly under Evidence. Then, as far as possible, $MFT, $LogFile and $J are prepared in a CSV file using **MFTECmd.exe**. These are saved in the extraction directory in the csv subdirectory. A simple log file is created in the root of the extraction directory. The created CSV files can then be viewed very easily with the TimelineExplorer. For this script to work correctly, Kape and MFTECmd must be downloaded from the respective developer and unpacked into the corresponding directories.

### Advantages
+ **Administrative Rights Handling**: </br>The script checks for administrative rights and restarts itself with elevated privileges if needed.
+ **Dynamic .NET Version Detection**: </br>Dynamically determines the installed .NET versions, adapting its behavior based on whether .NET is present.
+ **Hash Verification**: </br>It calculates the MD5 hash of the script and verifies it against an expected value, ensuring script integrity.
+ **Informative Output**: </br>The script provides detailed information about the system, .NET versions, hash values, and the execution path.

## EXECUTION GUIDELINES

### TEMPORARILY CHANGE FOR SESSION
To temporarily bypass the execution policies, either execute the following command in the command line (CMD) or start 'shell.bat', if necessary with administration rights.

powershell.exe -ExecutionPolicy Bypass

### CHANGE FOR CURRENT USER PROFILE
A user with administrative rights can change the execution policy for their user profile without changing the policy system-wide. RemoteSigned allows the execution of scripts created on the local computer and requires a digital signature for scripts downloaded from the Internet. To change the execution policy, the command must be executed outside the script and before it is executed in a PowerShell session with administrator rights. 

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

## MANUAL EXTRACT

> [!CAUTION]
> I am not the developer of Kape, MFTECmd and TimelineExplorer. Detailed documentation can be found at the developer.

> [!NOTE]
> **KAPE - Kroll Artifact Parser And Extractor, by Kroll**</br>
> https://www.kroll.com/en/services/cyber-risk/incident-response-litigation-support/kroll-artifact-parser-extractor-kape</br>
> **MFTECmd and TimelineExplorer, by Eric Zimmerman**</br>
> https://ericzimmerman.github.io/#!index.md

### DUMP MFT
```powershell
.\kape.exe --tsource [SOURCE] --target FileSystem --tdest [TARGET] --vhdx
```

SOURCE = source $MFT, usually C:\, D:\ etc.</br>
TARGET = target directory, where should the dump be stored?</br>

### MFTECMD
```powershell
MFTECmd.exe --f [SOURCE]\$MFT --csv [TARGET] --csvf [FILE].csv
```

SOURCE = Where is the previously created $MFT dump located?</br>
TARGET = Where should the CSV file be saved?</br>
FILE = How should the CSV file be saved?

## DELETED FILES NOTES
The Master File Table (MFT) of an NTFS file system can actually contain entries for previously existing (deleted) files. These files are no longer actively present in the file system, but information about them may still be present in the MFT until the specific MFT entry is overwritten. This is particularly useful in forensic investigations as it can provide insight into previous activity on a drive. When viewing the MFT with tools such as Eric Zimmerman's TimelineExplorer (EZ Tools), deleted files can be identified by certain characteristics:

### $I30-ENTRIES
Deleted files and folders can be found in the index attributes (known as $I30 entries) of the parent directory. These entries often contain references to the original name of the file or folder and the timestamp of the deletion.

### PREFIX "$" ENTRIES
Some special MFT entries that begin with "$", such as $LogFile or $Bitmap, contain information about the file system itself and can record changes, including the deletion of files.

### FILE STATUS
The TimelineExplorer and similar tools can sometimes show the status of a file, including whether it has been deleted. This can be visible through special markers or in the detailed views of the file properties.

### SEQUENCE NUMBERS
Timestamps such as date created, date last accessed, date last modified and date entered into the MFT can provide clues. Deleted files often retain their original timestamps. Sequence numbers in MFT entries can also provide clues. If a file is deleted and a new file with the same name is created, the sequence number of the MFT entry changes.

## License
This project is licensed under the **[MIT license](https://github.com/ot2i7ba/easyMFT/blob/main/LICENSE)**, providing users with flexibility and freedom to use and modify the software according to their needs.

## Disclaimer
This project is provided without warranties. Users are advised to review the accompanying license for more information on the terms of use and limitations of liability.
