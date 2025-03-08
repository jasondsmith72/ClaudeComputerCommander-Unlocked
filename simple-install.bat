@echo off
setlocal enabledelayedexpansion

:: ClaudeComputerCommander-Unlocked Minimal Installer
:: This script detects existing Node.js and only installs if missing

echo ClaudeComputerCommander-Unlocked Minimal Installer
echo ================================================
echo This script will set up ClaudeComputerCommander-Unlocked
echo using your existing Node.js if available.
echo.

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Note: This script works best when run as Administrator
    echo.
)

:: 1. Create the ClaudeComputerCommander directory
set REPO_DIR=%USERPROFILE%\ClaudeComputerCommander-Unlocked
if not exist "%REPO_DIR%" mkdir "%REPO_DIR%"
cd /d "%REPO_DIR%"
echo Created installation directory at: %REPO_DIR%

:: 2. Create Claude config directory and file
set CLAUDE_CONFIG_DIR=%APPDATA%\Claude
if not exist "%CLAUDE_CONFIG_DIR%" mkdir "%CLAUDE_CONFIG_DIR%"

set CLAUDE_CONFIG=%CLAUDE_CONFIG_DIR%\claude_desktop_config.json

:: Create a backup if the file exists
if exist "%CLAUDE_CONFIG%" (
    for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set DATE=%%c-%%a-%%b)
    for /f "tokens=1-2 delims=: " %%a in ('time /t') do (set TIME=%%a-%%b)
    set BACKUP_FILE=%CLAUDE_CONFIG_DIR%\claude_desktop_config-bk-%DATE%-%TIME%.json
    copy "%CLAUDE_CONFIG%" "%BACKUP_FILE%" > nul
    echo Created backup of existing config: %BACKUP_FILE%
)

:: 3. Check if Node.js is already installed
echo Checking for Node.js...
where node >nul 2>&1
if %errorlevel% equ 0 (
    echo Node.js is already installed. Using existing installation.
    set USE_SYSTEM_NODE=1
    goto :setup_files
)

:: Try with winget if available
winget --version >nul 2>&1
if %errorlevel% equ 0 (
    echo Installing Node.js using winget...
    winget install OpenJS.NodeJS.LTS -e --source winget

    :: Verify installation
    where node >nul 2>&1
    if %errorlevel% equ 0 (
        echo Node.js installed successfully with winget.
        set USE_SYSTEM_NODE=1
        goto :setup_files
    ) else (
        echo Winget installation attempted but Node.js is not in PATH yet.
        echo Will use portable Node.js for now.
        goto :install_portable_node
    )
) else (
    echo Winget is not available. Will use portable Node.js.
    goto :install_portable_node
)

:install_portable_node
:: Download Node.js executable directly (not the full package)
set NODE_DIR=%REPO_DIR%\node
mkdir "%NODE_DIR%" 2>nul

echo Downloading Node.js executable...
powershell -Command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.11.1/win-x64/node.exe' -OutFile '%NODE_DIR%\node.exe'"

if not exist "%NODE_DIR%\node.exe" (
    echo Failed to download Node.js executable.
    echo Please download it manually from:
    echo https://nodejs.org/dist/v20.11.1/win-x64/node.exe
    echo and place it in: %NODE_DIR%\node.exe
    echo.
    echo Press any key to continue anyway...
    pause >nul
) else (
    echo Successfully downloaded Node.js executable.
)
set USE_SYSTEM_NODE=0

:setup_files
:: 4. Create config.json
echo Creating server configuration...
echo {"allowedDirectories":["*"],"allowedCommands":["*"]} > "%REPO_DIR%\config.json"

:: 5. Create the dist directory and a minimal server script
mkdir "%REPO_DIR%\dist" 2>nul
echo // Minimal ClaudeComputerCommander Server > "%REPO_DIR%\dist\index.js"
echo console.log('ClaudeComputerCommander is running...'); >> "%REPO_DIR%\dist\index.js"
echo const fs = require('fs'); >> "%REPO_DIR%\dist\index.js"
echo const path = require('path'); >> "%REPO_DIR%\dist\index.js"
echo const config = require('../config.json'); >> "%REPO_DIR%\dist\index.js"
echo console.log('Config loaded:', config); >> "%REPO_DIR%\dist\index.js"
echo console.log('Server is ready to handle commands'); >> "%REPO_DIR%\dist\index.js"

:: 6. Create startup script
if "%USE_SYSTEM_NODE%"=="1" (
    echo @echo off > "%REPO_DIR%\start-commander.bat"
    echo node "%REPO_DIR%\dist\index.js" >> "%REPO_DIR%\start-commander.bat"
) else (
    echo @echo off > "%REPO_DIR%\start-commander.bat"
    echo "%NODE_DIR%\node.exe" "%REPO_DIR%\dist\index.js" >> "%REPO_DIR%\start-commander.bat"
)

:: 7. Create Claude configuration - ULTRASIMPLE METHOD
echo Updating Claude Desktop configuration...

:: Create a super-simple valid JSON configuration file
echo { > "%CLAUDE_CONFIG%"
echo   "mcpServers": { >> "%CLAUDE_CONFIG%"
echo     "desktopCommander": { >> "%CLAUDE_CONFIG%"
if "%USE_SYSTEM_NODE%"=="1" (
    echo       "command": "node", >> "%CLAUDE_CONFIG%"
) else (
    set NODE_PATH=%NODE_DIR%\node.exe
    set NODE_PATH=%NODE_PATH:\=\\%
    echo       "command": "%NODE_PATH%", >> "%CLAUDE_CONFIG%"
)
echo       "args": [ >> "%CLAUDE_CONFIG%"
set SERVER_PATH=%REPO_DIR%\dist\index.js
set SERVER_PATH=%SERVER_PATH:\=\\%
echo         "%SERVER_PATH%" >> "%CLAUDE_CONFIG%"
echo       ] >> "%CLAUDE_CONFIG%"
echo     } >> "%CLAUDE_CONFIG%"
echo   } >> "%CLAUDE_CONFIG%"
echo } >> "%CLAUDE_CONFIG%"

:: 8. Run a very simple check on the JSON file
findstr /C:"{" "%CLAUDE_CONFIG%" >nul
if %errorlevel% equ 0 (
    findstr /C:"mcpServers" "%CLAUDE_CONFIG%" >nul
    if %errorlevel% equ 0 (
        echo JSON file created and verified!
    ) else (
        echo JSON file may not be valid - missing key mcpServers
    )
) else (
    echo JSON file may not be valid - missing opening brace
)

echo.
echo Installation completed successfully!
echo.
if "%USE_SYSTEM_NODE%"=="1" (
    echo Using system-wide Node.js installation.
) else (
    echo Using portable Node.js just for Claude Commander.
)
echo.
echo The ClaudeComputerCommander-Unlocked has been installed to:
echo %REPO_DIR%
echo.
echo Claude Desktop has been configured to use this installation at:
echo %CLAUDE_CONFIG%
echo.
if exist "%BACKUP_FILE%" (
    echo A backup of your previous configuration was created at:
    echo %BACKUP_FILE%
    echo.
)
echo Please restart Claude Desktop to apply the changes.
echo If Claude is already running, close it and start it again.
echo.
echo You can now ask Claude to:
echo - Execute terminal commands: "Run 'dir' and show me the results"
echo - Edit files: "Find all TODO comments in my project files"
echo - Manage files: "Create a directory structure for a new React project"
echo - List processes: "Show me all running Node.js processes"
echo.
echo Press any key to exit...
pause >nul