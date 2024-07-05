@echo off
setlocal enabledelayedexpansion

REM Path to the configuration file
set "configFile=ssh_connections.json"

REM Function to create example configuration file if it doesn't exist
:CreateConfigFile
if not exist "%configFile%" (
    echo No configuration file found at %configFile%. Creating a new one with example data.
    > %configFile% echo [
    >> %configFile% echo     {
    >> %configFile% echo         "Name": "Server1",
    >> %configFile% echo         "Host": "server1.example.com",
    >> %configFile% echo         "Port": 22,
    >> %configFile% echo         "Username": "your_username",
    >> %configFile% echo         "Password": "your_password"
    >> %configFile% echo     },
    >> %configFile% echo     {
    >> %configFile% echo         "Name": "Server2",
    >> %configFile% echo         "Host": "server2.example.com",
    >> %configFile% echo         "Port": 22,
    >> %configFile% echo         "Username": "your_username",
    >> %configFile% echo         "Password": "your_password"
    >> %configFile% echo     }
    >> %configFile% echo ]
)

REM Function to load connection data from the configuration file
:LoadConnectionData
set "i=0"
for /f "delims=" %%i in ('type "%configFile%" ^| jq -c ".[]"') do (
    set "connections[!i!]=%%i"
    set /a i+=1
)
if %i% equ 0 (
    echo No connections found in the configuration file.
    exit /b
)

REM Function to display connection menu and let user choose a connection
:ShowConnectionMenu
echo Available connections:
for /l %%i in (0,1,%i%) do (
    if defined connections[%%i] (
        for /f "delims=" %%j in ('echo !connections[%%i]! ^| jq -r ".Name"') do (
            echo %%i. %%j
        )
    )
)

set /p "choice=Enter the number of the connection to connect to: "
set "selectedConnection="
for /l %%i in (0,1,%i%) do (
    if !choice! equ %%i (
        set "selectedConnection=!connections[%%i]!"
    )
)

if not defined selectedConnection (
    echo Invalid selection. Please choose a valid connection number.
    goto :ShowConnectionMenu
)

REM Function to establish SSH connection
:ConnectToSSH
for /f "delims=" %%i in ('echo %selectedConnection% ^| jq -r ".Host"') do set "Host=%%i"
for /f "delims=" %%i in ('echo %selectedConnection% ^| jq -r ".Port"') do set "Port=%%i"
for /f "delims=" %%i in ('echo %selectedConnection% ^| jq -r ".Username"') do set "Username=%%i"
for /f "delims=" %%i in ('echo %selectedConnection% ^| jq -r ".Password"') do set "Password=%%i"

echo Connecting to %Host%...
ssh -p %Port% %Username%@%Host%

goto :EOF

REM Main script
call :CreateConfigFile
call :LoadConnectionData
call :ShowConnectionMenu
call :ConnectToSSH

endlocal
