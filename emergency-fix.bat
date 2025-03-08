@echo off
setlocal enabledelayedexpansion

echo Claude Desktop Emergency Config Fix
echo =================================
echo This tool will fix the "Unexpected token ',', 'mcps'..." error.
echo.

:: Find Claude config directory and file
set CLAUDE_CONFIG_DIR=%APPDATA%\Claude
set CLAUDE_CONFIG=%CLAUDE_CONFIG_DIR%\claude_desktop_config.json

if not exist "%CLAUDE_CONFIG_DIR%" (
    echo ERROR: Claude configuration directory not found at %CLAUDE_CONFIG_DIR%
    echo Creating the directory...
    mkdir "%CLAUDE_CONFIG_DIR%" 2>nul
)

:: Backup existing config file if it exists
if exist "%CLAUDE_CONFIG%" (
    for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set DATE=%%c-%%a-%%b)
    for /f "tokens=1-2 delims=: " %%a in ('time /t') do (set TIME=%%a-%%b)
    set BACKUP_FILE=%CLAUDE_CONFIG_DIR%\claude_desktop_config-bk-%DATE%-%TIME%.json
    copy "%CLAUDE_CONFIG%" "%BACKUP_FILE%" > nul
    echo Created backup of existing config: %BACKUP_FILE%
)

echo.
echo Creating a minimal valid configuration file...

:: Create a clean UTF-8 JSON file without any BOM or extra characters - absolute minimal version
powershell -Command "[System.IO.File]::WriteAllText('%CLAUDE_CONFIG%', '{\"mcpServers\":{}}', [System.Text.Encoding]::UTF8)"

:: Verify the file
echo.
echo Verifying configuration file...
powershell -Command "try { $json = Get-Content '%CLAUDE_CONFIG%' -Raw | ConvertFrom-Json; Write-Host 'SUCCESS: Configuration file is valid JSON!' -ForegroundColor Green } catch { Write-Host 'ERROR: JSON file is still invalid. Please contact support.' -ForegroundColor Red }"

echo.
echo Configuration file has been reset to minimal valid state at:
echo %CLAUDE_CONFIG%
echo.
if exist "%BACKUP_FILE%" (
    echo A backup of your previous configuration was created at:
    echo %BACKUP_FILE%
    echo.
)
echo Please restart Claude Desktop to verify the error is fixed.
echo NOTE: This fix removes your Commander configuration.
echo Run simple-install.bat again after Claude starts successfully.
echo.

echo Press any key to exit...
pause >nul