@echo off
setlocal enabledelayedexpansion

echo Claude Desktop Configuration Finder
echo ==================================
echo This script will help locate your Claude Desktop configuration file.
echo.

:: Create a log file
set LOG_FILE=%USERPROFILE%\claude_config_finder.log
echo Claude Desktop Configuration Finder Log > %LOG_FILE%
echo Started at %date% %time% >> %LOG_FILE%
echo. >> %LOG_FILE%

echo Checking common Claude Desktop configuration locations...
echo Checking common Claude Desktop configuration locations... >> %LOG_FILE%

:: Define all possible locations to check
set LOCATIONS=^
    "%APPDATA%\Claude" ^
    "%LOCALAPPDATA%\Claude" ^
    "C:\Program Files\Claude" ^
    "C:\Program Files (x86)\Claude" ^
    "%USERPROFILE%\AppData\Local\Claude" ^
    "%USERPROFILE%\AppData\Roaming\Claude" ^
    "%USERPROFILE%\AppData\Local\Programs\Claude" ^
    "%ProgramFiles%\Claude" ^
    "%ProgramFiles(x86)%\Claude"

:: Check all the predefined locations
for %%l in (%LOCATIONS%) do (
    echo Checking %%l >> %LOG_FILE%
    if exist %%l (
        echo Directory found: %%l >> %LOG_FILE%
        echo Directory found: %%l
        
        :: Look for configuration files in this directory
        if exist "%%l\claude_desktop_config.json" (
            echo CONFIG FOUND: %%l\claude_desktop_config.json >> %LOG_FILE%
            echo CONFIG FOUND: %%l\claude_desktop_config.json
        )
        
        :: Look for any JSON files in this directory
        for /r "%%l" %%f in (*.json) do (
            echo JSON file found: %%f >> %LOG_FILE%
            echo JSON file found: %%f
        )
    ) else (
        echo Directory not found: %%l >> %LOG_FILE%
    )
)

echo.
echo Now searching for Claude-related executables...
echo. >> %LOG_FILE%
echo Searching for Claude-related executables... >> %LOG_FILE%

:: Search for Claude.exe in Program Files and common installation directories
for %%d in ("%ProgramFiles%" "%ProgramFiles(x86)%" "%LOCALAPPDATA%" "%APPDATA%" "%USERPROFILE%\AppData\Local\Programs") do (
    echo Searching in %%d >> %LOG_FILE%
    dir /s /b "%%d\Claude.exe" 2>nul >> %LOG_FILE%
    for /f "tokens=*" %%f in ('dir /s /b "%%d\Claude.exe" 2^>nul') do (
        echo Claude executable found: %%f
        echo Claude executable found: %%f >> %LOG_FILE%
        
        :: Report the parent directory
        for %%p in ("%%f\..") do (
            echo Parent directory: %%~fp
            echo Parent directory: %%~fp >> %LOG_FILE%
        )
    )
)

echo.
echo Checking recently modified files in AppData...
echo. >> %LOG_FILE%
echo Checking recently modified files in AppData... >> %LOG_FILE%

:: Look for recently modified files in AppData that might be related to Claude
forfiles /p "%APPDATA%" /s /m *.json /d -7 2>nul | findstr /i "claude" >> %LOG_FILE%
for /f "tokens=*" %%f in ('forfiles /p "%APPDATA%" /s /m *.json /d -7 2^>nul ^| findstr /i "claude"') do (
    echo Recent AppData file: %%f
    echo Recent AppData file: %%f >> %LOG_FILE%
)

forfiles /p "%LOCALAPPDATA%" /s /m *.json /d -7 2>nul | findstr /i "claude" >> %LOG_FILE%
for /f "tokens=*" %%f in ('forfiles /p "%LOCALAPPDATA%" /s /m *.json /d -7 2^>nul ^| findstr /i "claude"') do (
    echo Recent LocalAppData file: %%f
    echo Recent LocalAppData file: %%f >> %LOG_FILE%
)

echo.
echo Checking process information...
echo. >> %LOG_FILE%
echo Checking process information... >> %LOG_FILE%

:: Check if Claude is currently running
tasklist /fi "imagename eq claude.exe" >> %LOG_FILE%
echo Claude process status:
tasklist /fi "imagename eq claude.exe"

echo.
echo Report complete! 
echo All findings have been saved to: %LOG_FILE%
echo.
echo Please share this information to help troubleshoot the Claude Desktop configuration issue.
echo.
echo Press any key to exit...
pause >nul

endlocal
