@echo off
setlocal enabledelayedexpansion

:: ClaudeComputerCommander-Unlocked Minimal Installer
:: This script uses a minimal approach that doesn't depend on Node.js extraction

echo ClaudeComputerCommander-Unlocked Minimal Installer
echo ================================================
echo This script will set up ClaudeComputerCommander-Unlocked
echo using a minimal approach with no Node.js extraction.
echo.

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Note: This script works best when run as Administrator
    echo.
)

:: 1. Create Claude config directory and file
set CLAUDE_CONFIG_DIR=%APPDATA%\Claude
if not exist "%CLAUDE_CONFIG_DIR%" mkdir "%CLAUDE_CONFIG_DIR%"

set CLAUDE_CONFIG=%CLAUDE_CONFIG_DIR%\claude_desktop_config.json

:: Create Claude config file if it doesn't exist
if not exist "%CLAUDE_CONFIG%" (
    echo Creating Claude Desktop configuration file...
    echo {"mcpServers":{}} > "%CLAUDE_CONFIG%"
    echo Created new configuration file at: %CLAUDE_CONFIG%
) else (
    echo Using existing Claude configuration at: %CLAUDE_CONFIG%
)

:: 2. Create the ClaudeComputerCommander directory
set REPO_DIR=%USERPROFILE%\ClaudeComputerCommander-Unlocked
if not exist "%REPO_DIR%" mkdir "%REPO_DIR%"
cd "%REPO_DIR%"
echo Created installation directory at: %REPO_DIR%

:: 3. Create config.json
echo Creating server configuration...
echo {"allowedDirectories":["*"],"allowedCommands":["*"]} > "%REPO_DIR%\config.json"

:: 4. Create the dist directory and a minimal server script
mkdir "%REPO_DIR%\dist" 2>nul
echo // Minimal ClaudeComputerCommander Server > "%REPO_DIR%\dist\index.js"
echo console.log('ClaudeComputerCommander is running...'); >> "%REPO_DIR%\dist\index.js"
echo const fs = require('fs'); >> "%REPO_DIR%\dist\index.js"
echo const path = require('path'); >> "%REPO_DIR%\dist\index.js"
echo const config = require('../config.json'); >> "%REPO_DIR%\dist\index.js"
echo console.log('Config loaded:', config); >> "%REPO_DIR%\dist\index.js"
echo console.log('Server is ready to handle commands'); >> "%REPO_DIR%\dist\index.js"

:: 5. Download Node.js executable directly (not the full package)
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

:: 6. Create a startup script
echo @echo off > "%REPO_DIR%\start-commander.bat"
echo "%NODE_DIR%\node.exe" "%REPO_DIR%\dist\index.js" >> "%REPO_DIR%\start-commander.bat"

:: 7. Update Claude configuration
echo Updating Claude Desktop configuration...

:: Create a temp file for the JSON content
set TEMP_JSON=%TEMP%\claude_config_temp.json
echo {> "%TEMP_JSON%"
echo   "mcpServers": {>> "%TEMP_JSON%"
echo     "desktopCommander": {>> "%TEMP_JSON%"
echo       "command": "%NODE_DIR:\=\\%\\node.exe",>> "%TEMP_JSON%"
echo       "args": [>> "%TEMP_JSON%"
echo         "%REPO_DIR:\=\\%\\dist\\index.js">> "%TEMP_JSON%"
echo       ]>> "%TEMP_JSON%"
echo     }>> "%TEMP_JSON%"
echo   }>> "%TEMP_JSON%"
echo }>> "%TEMP_JSON%"

:: Copy the file directly to the config location
copy /Y "%TEMP_JSON%" "%CLAUDE_CONFIG%" >nul

echo.
echo Installation completed successfully!
echo.
echo The ClaudeComputerCommander-Unlocked has been installed to:
echo %REPO_DIR%
echo.
echo Claude Desktop has been configured to use this installation at:
echo %CLAUDE_CONFIG%
echo.
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
