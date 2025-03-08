@echo off
echo Claude Desktop Configuration Emergency Fix
echo ========================================
echo This script will fix JSON configuration errors.
echo.

:: Create a minimal working JSON configuration file
echo Creating Emergency Fix...

:: Set Claude config path
set CLAUDE_DIR=%APPDATA%\Claude
set CONFIG_FILE=%CLAUDE_DIR%\claude_desktop_config.json

:: Create directory if it doesn't exist
if not exist "%CLAUDE_DIR%" (
    mkdir "%CLAUDE_DIR%" 2>nul
    echo Created Claude directory at: %CLAUDE_DIR%
)

:: Create backup if file exists
if exist "%CONFIG_FILE%" (
    :: Get current date and time for backup filename
    for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
    set "YYYY=%dt:~0,4%"
    set "MM=%dt:~4,2%"
    set "DD=%dt:~6,2%"
    set "HH=%dt:~8,2%"
    set "Min=%dt:~10,2%"
    set "Sec=%dt:~12,2%"
    set "BACKUP_FILE=%CLAUDE_DIR%\claude_desktop_config-backup-%YYYY%-%MM%-%DD%-%HH%.%Min%.json"
    
    copy "%CONFIG_FILE%" "%BACKUP_FILE%" >nul 2>&1
    echo Backup created at: %BACKUP_FILE%
)

:: Create minimal valid JSON
echo { > "%CONFIG_FILE%"
echo   "mcpServers": {} >> "%CONFIG_FILE%"
echo } >> "%CONFIG_FILE%"

echo.
echo Emergency fix applied!
echo.
echo The Claude Desktop configuration has been fixed at:
echo %CONFIG_FILE%
echo.
echo Please restart Claude Desktop and then run the install script again.
echo.
echo Press any key to exit...
pause >nul