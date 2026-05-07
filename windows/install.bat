@echo off
echo ========================================
echo  ShadowGuard Installation - Windows
echo ========================================
echo.

:: Check admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Run as Administrator!
    pause
    exit /b 1
)

set "INSTALL_DIR=%ProgramFiles%\ShadowGuard"
set "SCRIPT_DIR=%~dp0"

echo [1/4] Creating installation directory...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo [2/4] Copying files...
xcopy /y /q "%SCRIPT_DIR%*" "%INSTALL_DIR%\"

echo [3/4] Adding to system PATH...
setx /M PATH "%PATH%;%INSTALL_DIR%" >nul

echo [4/4] Creating desktop shortcut...
echo Set oWS = WScript.CreateObject("WScript.Shell") > "%TEMP%\shortcut.vbs"
echo sLinkFile = "%USERPROFILE%\Desktop\ShadowGuard.lnk" >> "%TEMP%\shortcut.vbs"
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%TEMP%\shortcut.vbs"
echo oLink.TargetPath = "%INSTALL_DIR%\shadowguard.bat" >> "%TEMP%\shortcut.vbs"
echo oLink.WorkingDirectory = "%INSTALL_DIR%" >> "%TEMP%\shortcut.vbs"
echo oLink.Save >> "%TEMP%\shortcut.vbs"
cscript //nologo "%TEMP%\shortcut.vbs"
del "%TEMP%\shortcut.vbs"

echo.
echo ========================================
echo  Installation Complete!
echo ========================================
echo.
echo Run: shadowguard.bat start
echo.
pause
