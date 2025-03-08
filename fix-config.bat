@echo off
setlocal enabledelayedexpansion

echo Claude Desktop Configuration Fix
echo ==============================
echo This tool will fix JSON formatting errors in Claude Desktop config.
echo.

:: Set path to Claude config directory and file
set CLAUDE_DIR=%APPDATA%\Claude
set CLAUDE_CONFIG=%CLAUDE_DIR%\claude_desktop_config.json

:: Check if the Claude directory exists, create if not
if not exist "%CLAUDE_DIR%" (
    echo Creating Claude config directory...
    mkdir "%CLAUDE_DIR%"
)

:: Create a backup of existing config file if it exists
if exist "%CLAUDE_CONFIG%" (
    for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set DATE=%%c-%%a-%%b)
    for /f "tokens=1-2 delims=: " %%a in ('time /t') do (set TIME=%%a-%%b)
    set BACKUP_FILE=%CLAUDE_DIR%\claude_desktop_config-bk-%DATE%-%TIME%.json
    copy "%CLAUDE_CONFIG%" "%BACKUP_FILE%" > nul
    echo Backup created at: %BACKUP_FILE%
)

:: Get the ClaudeComputerCommander path
set REPO_DIR=%USERPROFILE%\ClaudeComputerCommander-Unlocked
if not exist "%REPO_DIR%" (
    echo ClaudeComputerCommander-Unlocked not found at the default location.
    echo.
    echo Enter the full path to your installation directory:
    set /p REPO_DIR=
)

:: Create a minimal valid JSON config file with proper indentation
echo Creating a fresh configuration file...

echo { > "%CLAUDE_CONFIG%"
echo   "mcpServers": { >> "%CLAUDE_CONFIG%"
echo     "desktopCommander": { >> "%CLAUDE_CONFIG%"
echo       "command": "node", >> "%CLAUDE_CONFIG%"
echo       "args": [ >> "%CLAUDE_CONFIG%"
set SERVER_PATH=%REPO_DIR%\dist\index.js
set SERVER_PATH=%SERVER_PATH:\=\\%
echo         "%SERVER_PATH%" >> "%CLAUDE_CONFIG%"
echo       ] >> "%CLAUDE_CONFIG%"
echo     } >> "%CLAUDE_CONFIG%"
echo   } >> "%CLAUDE_CONFIG%"
echo } >> "%CLAUDE_CONFIG%"

echo.
echo Configuration file has been fixed!
echo Location: %CLAUDE_CONFIG%
echo.
echo Please restart Claude Desktop to apply the changes.
echo.
echo Press any key to exit...
pause >nul