@echo off
setlocal

REM Define the target backup registry key
set "sourceKey=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SMS\"

REM Define the destination folder for backup
set "destinationFolder=\\path\to\cmbackup"

REM Create the destination folder if it doesn't exist
if not exist "%destinationFolder%" mkdir "%destinationFolder%"

REM Export setupreg key to a .reg file in the destination folder
reg export "%sourceKey%" "%destinationFolder%\SMS_Backup.reg" /y

REM Backup content
robocopy "<path to content>\SCCMContentLIB" "%destinationFolder%" /MIR

REM Backup sources
robocopy "<path to sources>" "%destinationFolder%" /MIR

REM Backup Default Permissions
icacls "<path to target folder>" /save "%destinationFolder%\BACKUPACL" /t /c /q
