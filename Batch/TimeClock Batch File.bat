@echo off
setlocal enabledelayedexpansion

:: CONFIGURATION
set "logFile=KTime_ping_log.txt"
set "server=10.0.0.2"  :: timeclock server IP
set "appExe=K-Time.exe"  :: EXE name of the app
set "appPath=C:\KTime\KTimeStartup.exe"  :: path to the app

:: INITIAL PING CHECK
echo Pinging %server%... >> "%logFile%"
attrib +h "%logFile%"

:: Perform ping and save to temp file
ping -n 3 %server% > ping_temp.txt

:: Search for common failure indicators
findstr /i "unreachable timed out could not" ping_temp.txt >nul
if %errorlevel%==0 (
    echo [%date% %time%] Ping failed to %server% >> "%logFile%"
    del ping_temp.txt
    echo Network is down. Please check your connection and try again. If issues persist contact **** for support. ***-***-****.
    pause
    exit /b
)

echo [%date% %time%] Ping successful to %server% >> "%logFile%"
del ping_temp.txt
echo Try clocking in now.
echo.
choice /m "Can you clock in?"
if errorlevel 2 goto retry_clockin
if errorlevel 1 goto success

:: RETRY PATH 
:retry_clockin
echo.
echo Trying to help you clock in again...

ping -n 3 %server% > ping_temp.txt

findstr /i "unreachable timed out could not" ping_temp.txt >nul
if %errorlevel%==0 (
    echo [%date% %time%] Second ping failed to %server% >> "%logFile%"
    del ping_temp.txt
    echo Network issue persists. Please call **** for support ***-***-****.
    pause
    exit /b
)

echo [%date% %time%] Second ping successful to %server% >> "%logFile%"
del ping_temp.txt
echo Restarting the Timeclock program...

:: Kill the app if it's already running
taskkill /f /im %appExe% >nul 2>&1

:: Start the app again
start "" "%appPath%"

echo Once the timeclock opens again, please attempt to clock in again.
choice /m "Were you able to clock in?"
if errorlevel 2 goto fail_support
if errorlevel 1 goto success

:: SUCCESS PATH
:success
echo [%date% %time%] User successfully clocked in. >> "%logFile%"
echo Thank you. You are now clocked in.
timeout /t 2 > nul
exit /b

:: FAILURE PATH
:fail_support
echo [%date% %time%] User was unable to clock in even after retry and application restart. >> "%logFile%"
echo Please call **** for support ***-***-****.
pause
exit /b