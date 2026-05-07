@echo off
setlocal enabledelayedexpansion

:: ShadowGuard - Windows Security Monitor
:: Version: 1.0

set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%config.ini"
set "LOG_DIR=%SCRIPT_DIR%logs"
set "BASELINE_DIR=%SCRIPT_DIR%baseline"
set "QUARANTINE_DIR=%SCRIPT_DIR%quarantine"
set "LOCK_FILE=%SCRIPT_DIR%.shadowguard.lock"

:: Check admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Administrator privileges required!
    exit /b 1
)

:: Create directories
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%BASELINE_DIR%" mkdir "%BASELINE_DIR%"
if not exist "%QUARANTINE_DIR%" mkdir "%QUARANTINE_DIR%"

:: Parse command
set "COMMAND=%~1"
if "%COMMAND%"=="" set "COMMAND=help"

if /i "%COMMAND%"=="start" goto :start
if /i "%COMMAND%"=="stop" goto :stop
if /i "%COMMAND%"=="status" goto :status
if /i "%COMMAND%"=="scan" goto :scan
if /i "%COMMAND%"=="help" goto :help
goto :help

:start
echo [INFO] Starting ShadowGuard...
if exist "%LOCK_FILE%" (
    echo [WARN] ShadowGuard is already running
    exit /b 0
)

:: Create lock file
echo %date% %time% > "%LOCK_FILE%"

:: Load configuration
call :load_config

:: Initialize baseline if not exists
if not exist "%BASELINE_DIR%\file_hashes.txt" (
    echo [INFO] Creating initial baseline...
    call :create_baseline
)

:: Start monitoring loop
echo [INFO] ShadowGuard started successfully
call :monitor_loop
goto :eof

:stop
echo [INFO] Stopping ShadowGuard...
if not exist "%LOCK_FILE%" (
    echo [WARN] ShadowGuard is not running
    exit /b 0
)
del "%LOCK_FILE%"
echo [INFO] ShadowGuard stopped
goto :eof

:status
if exist "%LOCK_FILE%" (
    echo [STATUS] ShadowGuard is RUNNING
    type "%LOCK_FILE%"
) else (
    echo [STATUS] ShadowGuard is STOPPED
)
goto :eof

:scan
echo [INFO] Running manual security scan...
call :load_config
call :file_integrity_check
call :process_anomaly_check
call :network_check
echo [INFO] Scan completed. Check logs for details.
goto :eof

:help
echo ShadowGuard - Advanced System Integrity Monitor
echo.
echo Usage: shadowguard.bat [COMMAND]
echo.
echo Commands:
echo   start   - Start monitoring service
echo   stop    - Stop monitoring service
echo   status  - Check service status
echo   scan    - Run manual security scan
echo   help    - Show this help message
goto :eof

:load_config
:: Load configuration from config.ini
set "MONITOR_PATHS=C:\Windows\System32;C:\Program Files"
set "SCAN_INTERVAL=300"
set "ALERT_LEVEL=2"
set "AUTO_QUARANTINE=1"

if exist "%CONFIG_FILE%" (
    for /f "usebackq tokens=1,2 delims==" %%a in ("%CONFIG_FILE%") do (
        set "%%a=%%b"
    )
)
goto :eof

:create_baseline
set "BASELINE_FILE=%BASELINE_DIR%\file_hashes.txt"
echo [INFO] Scanning files for baseline...
> "%BASELINE_FILE%" echo # ShadowGuard Baseline - %date% %time%

for %%P in (%MONITOR_PATHS:;= %) do (
    if exist "%%P" (
        for /r "%%P" %%F in (*) do (
            call :hash_file "%%F" HASH
            echo %%F|!HASH! >> "%BASELINE_FILE%"
        )
    )
)
echo [INFO] Baseline created with file hashes
goto :eof

:monitor_loop
echo [INFO] Monitoring started. Press Ctrl+C to stop.
:loop
if not exist "%LOCK_FILE%" goto :eof

call :file_integrity_check
call :process_anomaly_check
call :network_check

timeout /t %SCAN_INTERVAL% /nobreak >nul
goto :loop

:file_integrity_check
set "LOG_FILE=%LOG_DIR%\fim_%date:~-4,4%%date:~-10,2%%date:~-7,2%.log"
set "BASELINE_FILE=%BASELINE_DIR%\file_hashes.txt"

if not exist "%BASELINE_FILE%" goto :eof

echo [%date% %time%] File Integrity Check Started >> "%LOG_FILE%"

for /f "usebackq tokens=1,2 delims=|" %%a in ("%BASELINE_FILE%") do (
    if exist "%%a" (
        call :hash_file "%%a" CURRENT_HASH
        if not "!CURRENT_HASH!"=="%%b" (
            echo [ALERT] File modified: %%a >> "%LOG_FILE%"
            call :alert_handler "FILE_MODIFIED" "%%a"
        )
    ) else (
        echo [ALERT] File deleted: %%a >> "%LOG_FILE%"
        call :alert_handler "FILE_DELETED" "%%a"
    )
)
goto :eof

:process_anomaly_check
set "LOG_FILE=%LOG_DIR%\process_%date:~-4,4%%date:~-10,2%%date:~-7,2%.log"
echo [%date% %time%] Process Check Started >> "%LOG_FILE%"

:: List running processes and check for anomalies
tasklist /fo csv /nh > "%TEMP%\processes.tmp"

:: Check for suspicious process names
for /f "tokens=1 delims=," %%p in (%TEMP%\processes.tmp) do (
    set "PROC=%%~p"
    echo !PROC! | findstr /i "mimikatz keylogger backdoor trojan" >nul
    if !errorlevel! equ 0 (
        echo [ALERT] Suspicious process detected: !PROC! >> "%LOG_FILE%"
        call :alert_handler "SUSPICIOUS_PROCESS" "!PROC!"
    )
)

del "%TEMP%\processes.tmp"
goto :eof

:network_check
set "LOG_FILE=%LOG_DIR%\network_%date:~-4,4%%date:~-10,2%%date:~-7,2%.log"
echo [%date% %time%] Network Check Started >> "%LOG_FILE%"

:: Check active connections
netstat -ano | findstr "ESTABLISHED" > "%TEMP%\connections.tmp"

:: Log unusual ports
for /f "tokens=2,5" %%a in (%TEMP%\connections.tmp) do (
    echo %%a | findstr ":4444 :5555 :6666 :31337" >nul
    if !errorlevel! equ 0 (
        echo [ALERT] Suspicious connection: %%a to %%b >> "%LOG_FILE%"
        call :alert_handler "SUSPICIOUS_CONNECTION" "%%a"
    )
)

del "%TEMP%\connections.tmp"
goto :eof

:alert_handler
set "ALERT_TYPE=%~1"
set "ALERT_DATA=%~2"
set "ALERT_LOG=%LOG_DIR%\alerts.log"

echo [%date% %time%] [%ALERT_TYPE%] %ALERT_DATA% >> "%ALERT_LOG%"

if "%AUTO_QUARANTINE%"=="1" (
    if "%ALERT_TYPE%"=="FILE_MODIFIED" (
        call :quarantine_file "%ALERT_DATA%"
    )
    if "%ALERT_TYPE%"=="SUSPICIOUS_PROCESS" (
        taskkill /f /im "%ALERT_DATA%" >nul 2>&1
        echo [ACTION] Killed process: %ALERT_DATA% >> "%ALERT_LOG%"
    )
)
goto :eof

:quarantine_file
set "FILE_PATH=%~1"
set "FILE_NAME=%~nx1"
set "QUARANTINE_PATH=%QUARANTINE_DIR%\%FILE_NAME%.%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time::=_%"

if exist "%FILE_PATH%" (
    move "%FILE_PATH%" "%QUARANTINE_PATH%" >nul 2>&1
    echo [ACTION] Quarantined: %FILE_PATH% >> "%LOG_DIR%\alerts.log"
)
goto :eof

:hash_file
:: Simple hash function (CRC32 simulation using file size and date)
set "FILE=%~1"
set "SIZE=%~z1"
set "DATE=%~t1"
set "HASH=%SIZE%_%DATE: =_%"
set "%~2=%HASH%"
goto :eof