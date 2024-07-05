@echo off
setlocal enabledelayedexpansion

REM Path to the configuration file
set "configFile=ssh_connections.json"

REM Function to create example configuration file if it doesn't exist
:CreateConfigFile
if not exist "%configFile%" (
    echo.
    echo No configuration file found at %configFile%. Creating a new one with example data.
    (
        echo [
        echo     {
        echo         "Name": "Server1",
        echo         "Host": "server1.example.com",
        echo         "Port": 22,
        echo         "Username": "your_username",
        echo         "Password": "your_password"
        echo     },
        echo     {
        echo         "Name": "Server2",
        echo         "Host": "server2.example.com",
        echo         "Port": 22,
        echo         "Username": "your_username",
        echo         "Password": "your_password"
        echo     }
        echo ]
    ) > "%configFile%"
    echo.
    echo Configuration file created successfully.
    echo.
)

REM Function to load connection data from the configuration file
:LoadConnectionData
set "i=0"
for /f "tokens=* delims=" %%a in ('type "%configFile%"') do (
    set "line=%%a"
    REM Check if the line contains a connection entry
    echo !line! | find "{" > nul
    if !errorlevel! equ 0 (
        set /a i+=1
        REM Read each attribute of the connection entry
        set "Name="
        set "Host="
        set "Port="
        set "Username="
        set "Password="
    ) else if "!line:~0,1!" == "}" (
        REM Store the connection details in an array
        set "connections[!i!]={ "Name": "!Name!", "Host": "!Host!", "Port": !Port!, "Username": "!Username!", "Password": "!Password!" }"
    ) else (
        for %%b in ("Name Host Port Username Password") do (
            for /f "tokens=1,2 delims=:" %%c in ('echo !line! ^| findstr /c:"%%~b"') do (
                if "%%~d" neq "" (
                    for %%e in ("! %%~b[%%i%%]=%%~d !") do set %%~e
                )
            )
        )
    )
)
if %i% equ 0 (
    echo No connections found in the configuration file.
    exit /b
)

REM Debugging output to verify loaded connections
echo Loaded connections:
echo =====================
for /l %%i in (0,1,%i%) do (
    if defined connections[%%i] (
        echo !connections[%%i]!
    )
)
echo =====================
echo.

REM Function to display connection menu and let user choose a connection
:ShowConnectionMenu
echo.
echo Available connections:
echo =====================

REM Display each connection name with its corresponding index
for /l %%i in (0,1,%i%) do (
    if defined connections[%%i] (
        for /f "tokens=2 delims==" %%j in ('set connections[%%i]') do (
            for /f "tokens=2 delims==" %%k in ('echo %%j') do (
                echo %%i. %%k
            )
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
for /f "tokens=2 delims=:" %%i in ('echo %selectedConnection% ^| findstr /c:"Host"') do set "Host=%%i"
for /f "tokens=2 delims=:" %%i in ('echo %selectedConnection% ^| findstr /c:"Port"') do set "Port=%%i"
for /f "tokens=2 delims=:" %%i in ('echo %selectedConnection% ^| findstr /c:"Username"') do set "Username=%%i"
for /f "tokens=2 delims=:" %%i in ('echo %selectedConnection% ^| findstr /c:"Password"') do set "Password=%%i"

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
