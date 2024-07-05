@echo off
setlocal enabledelayedexpansion

REM Enable colors
for /f "tokens=2 delims==" %%i in ('"color /?"') do set "colors=%%i"

REM Path to the configuration file
set "configFile=ssh_connections.json"

REM Function to create example configuration file if it doesn't exist
:CreateConfigFile
if not exist "%configFile%" (
    echo.
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
    echo.
    echo Configuration file created successfully.
    echo.
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
echo.
echo Available connections:
echo =====================

REM Display each connection name with its corresponding index
for /l %%i in (0,1,%i%) do (
    if defined connections[%%i] (
        for /f "delims=" %%j in ('echo !connections[%%i]! ^| jq -r ".Name"') do (
            echo %%i. %%j
        )
    )
)
echo =====================
echo.

REM Prompt the user to select a connection
set /p "choice=Enter the number of the connection to connect to: "
set "selectedConnection="

REM Validate the user's selection and set the selected connection
for /l %%i in (0,1,%i%) do (
    if !choice! equ %%i (
        set "selectedConnection=!connections[%%i]!"
    )
)

REM If the selection is invalid, ask the user to choose again
if not defined selectedConnection (
    echo Invalid selection. Please choose a valid connection number.
    goto :ShowConnectionMenu
)

REM Function to establish SSH connection
:ConnectToSSH
REM Extract connection details from the selected connection JSON object
for /f "delims=" %%i in ('echo %selectedConnection% ^| jq -r ".Host"') do set "Host=%%i"
for /f "delims=" %%i in ('echo %selectedConnection% ^| jq -r ".Port"') do set "Port=%%i"
for /f "delims=" %%i in ('echo %selectedConnection% ^| jq -r ".Username"') do set "Username=%%i"
for /f "delims=" %%i in ('echo %selectedConnection% ^| jq -r ".Password"') do set "Password=%%i"

REM Attempt to connect to the selected SSH server
echo.
echo Connecting to %Host%...
ssh -p %Port% %Username%@%Host%

REM Pause to keep the window open after attempting the connection
pause

goto :EOF

REM Main script execution
call :CreateConfigFile
call :LoadConnectionData
call :ShowConnectionMenu
call :ConnectToSSH

endlocal
