@echo off
setlocal enabledelayedexpansion

:: ============================================
::   EC2 SSH CONFIG UPDATER
:: ============================================
:: This script rebuilds a clean SSH config entry
:: for your EC2 instance every time you run it,
:: using a FIXED Host alias (my-ec2) so VS Code
:: Remote-SSH always connects the same way,
:: regardless of the instance's current IP.
:: ============================================

echo.
echo ******************************
echo *    IP UPDATER - CONFIG     *
echo ******************************
echo.

:: ---- CONFIGURE THESE ONCE ----
set "HOST_ALIAS=my-ec2"
set "SSH_USER=ec2-user"
:: --------------------------------

:: Auto-detect the .pem key file in this same folder, so you don't
:: have to hardcode a filename or edit this script when the key changes.
set "pem_count=0"
for %%f in ("%~dp0*.pem") do (
    set /a pem_count+=1
    set "pem_!pem_count!=%%~ff"
)

if "%pem_count%"=="0" (
    echo.
    echo Error: No .pem file found in this folder:
    echo   %~dp0
    echo Place your EC2 key file (.pem^) in this same folder and re-run.
    pause
    exit /b 1
)

if "%pem_count%"=="1" (
    set "KEY_PATH=%pem_1%"
) else (
    echo.
    echo Multiple .pem files found in this folder:
    for /l %%i in (1,1,%pem_count%) do (
        echo   %%i^) !pem_%%i!
    )
    echo.
    set /p "pem_choice=Enter the number of the key to use: "
    set "KEY_PATH=!pem_%pem_choice%!"
    if not defined KEY_PATH (
        echo Invalid selection.
        pause
        exit /b 1
    )
)

:: Prompt user for new IP
:input_ip
set /p "ip=Enter the IP (format X.X.X.X, e.g., 3.88.159.130): "
if "%ip%"=="" (
    echo Error: IP cannot be empty.
    goto input_ip
)

:: Validate IP format (X.X.X.X) - simple dot-count check
set "iptest=%ip%"
set "dotcount=0"
:count_dots
if not "!iptest!"=="!iptest:.=!" (
    set /a dotcount+=1
    call set "iptest=%%iptest:*.=%%"
    goto count_dots
)
if not "!dotcount!"=="3" (
    echo Invalid IP format. Use X.X.X.X e.g. 3.88.159.130
    goto input_ip
)

:: Convert IP to AWS domain format (dots to hyphens)
set "new_ip=%ip:.=-%"
set "new_domain=ec2-%new_ip%.compute-1.amazonaws.com"

set "config_file=%~dp0config"

:: If a config file already exists, back it up first
if exist "%config_file%" (
    copy /y "%config_file%" "%config_file%.bak" > nul
)

:: Rebuild the config file from scratch with a single clean Host block.
:: This avoids duplicate/broken blocks from string-replacement bugs.
(
    echo Host %HOST_ALIAS%
    echo     HostName %new_domain%
    echo     User %SSH_USER%
    echo     IdentityFile %KEY_PATH%
    echo     IdentitiesOnly yes
    echo     StrictHostKeyChecking accept-new
) > "%config_file%"

:: Clear any stale known_hosts entry for the old domain, if we can find one.
:: (Old entries under a previous IP can cause SSH host-key warnings/failures.)
if exist "%~dp0known_hosts" (
    ssh-keygen -R "%new_domain%" -f "%~dp0known_hosts" > nul 2>&1
)

echo.
echo [+] Config file rebuilt successfully at:
echo     %config_file%
echo.
echo [+] Host alias:    %HOST_ALIAS%
echo [+] New domain:    %new_domain%
echo [+] User:          %SSH_USER%
echo [+] Key path:       %KEY_PATH%
echo.
echo In VS Code, connect using: Remote-SSH: Connect to Host... -^> %HOST_ALIAS%
echo.
pause
endlocal
