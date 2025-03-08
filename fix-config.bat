@echo off
setlocal enabledelayedexpansion

echo Claude Desktop Config Fix Tool
echo =============================
echo This tool will fix your Claude Desktop configuration file.
echo.

:: Find Claude config directory and file
set CLAUDE_CONFIG_DIR=%APPDATA%\Claude
set CLAUDE_CONFIG=%CLAUDE_CONFIG_DIR%\claude_desktop_config.json

if not exist "%CLAUDE_CONFIG_DIR%" (
    echo ERROR: Claude configuration directory not found at %CLAUDE_CONFIG_DIR%
    echo Please make sure Claude Desktop is installed properly.
    goto :end
)

:: Backup existing config file if it exists
if exist "%CLAUDE_CONFIG%" (
    for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set DATE=%%c-%%a-%%b)
    for /f "tokens=1-2 delims=: " %%a in ('time /t') do (set TIME=%%a-%%b)
    set BACKUP_FILE=%CLAUDE_CONFIG_DIR%\claude_desktop_config-bk-%DATE%-%TIME%.json
    copy "%CLAUDE_CONFIG%" "%BACKUP_FILE%" > nul
    echo Created backup of existing config: %BACKUP_FILE%
)

:: Get the ClaudeComputerCommander-Unlocked directory
set REPO_DIR=%USERPROFILE%\ClaudeComputerCommander-Unlocked
echo.

echo Looking for ClaudeComputerCommander-Unlocked installation...
if not exist "%REPO_DIR%" (
    echo Installation not found at default location.
    set /p REPO_DIR=Please enter the path to your ClaudeComputerCommander-Unlocked installation: 
)

if not exist "%REPO_DIR%\dist\index.js" (
    echo WARNING: Cannot find the dist\index.js file in specified location.
    echo Will proceed anyway with default values.
)

:: Check if Node.js is installed
where node >nul 2>&1
if %errorlevel% equ 0 (
    echo Node.js is installed. Using system Node.js.
    set USE_SYSTEM_NODE=1
) else (
    set NODE_DIR=%REPO_DIR%\node
    if exist "%NODE_DIR%\node.exe" (
        echo Using portable Node.js from %NODE_DIR%
        set USE_SYSTEM_NODE=0
    ) else (
        echo WARNING: Cannot find Node.js. Will configure for system Node.js.
        set USE_SYSTEM_NODE=1
    )
)

:: Create a clean config file using the simplest possible method
echo Creating a clean configuration file...

set INDEX_PATH=%REPO_DIR%\dist\index.js
set INDEX_PATH=%INDEX_PATH:\=\\%

:: Create a clean UTF-8 JSON file without any BOM or extra characters
if %USE_SYSTEM_NODE%==1 (
    powershell -Command "[System.IO.File]::WriteAllText('%CLAUDE_CONFIG%', '{\"mcpServers\":{\"desktopCommander\":{\"command\":\"node\",\"args\":[\"%INDEX_PATH%\"]}}}', [System.Text.Encoding]::UTF8)"
) else (
    set NODE_EXE_PATH=%NODE_DIR%\node.exe
    set NODE_EXE_PATH=%NODE_EXE_PATH:\=\\%
    powershell -Command "[System.IO.File]::WriteAllText('%CLAUDE_CONFIG%', '{\"mcpServers\":{\"desktopCommander\":{\"command\":\"%NODE_EXE_PATH%\",\"args\":[\"%INDEX_PATH%\"]}}}', [System.Text.Encoding]::UTF8)"
)

:: Verify the file
echo.
echo Verifying configuration file...
powershell -Command "try { $json = Get-Content '%CLAUDE_CONFIG%' -Raw | ConvertFrom-Json; Write-Host 'SUCCESS: Configuration file is valid JSON!' -ForegroundColor Green } catch { Write-Host 'ERROR: JSON file is still invalid. Please contact support.' -ForegroundColor Red }"

echo.
echo Configuration file has been updated at:
echo %CLAUDE_CONFIG%
echo.
echo A backup of your previous configuration was created at:
echo %BACKUP_FILE%
echo.
echo Please restart Claude Desktop to apply the changes.
echo.

:end
echo Press any key to exit...
pause >nul