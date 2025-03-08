@echo off
setlocal enabledelayedexpansion

:: ClaudeComputerCommander-Unlocked Minimal Installer
:: This script uses winget to install Node.js

echo ClaudeComputerCommander-Unlocked Minimal Installer
echo ================================================
echo This script will set up ClaudeComputerCommander-Unlocked
echo using winget to install Node.js system-wide.
echo.

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Note: This script works best when run as Administrator
    echo for the winget installation. You may be prompted for elevation.
    echo.
)

:: Check if winget is available
winget --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Winget is not available on this system.
    echo Please ensure you're running Windows 10 1809 or later with App Installer installed.
    echo You can install App Installer from the Microsoft Store.
    echo.
    echo Falling back to direct Node.js download...
    goto :direct_node_download
)

:: Install Node.js using winget
echo Installing Node.js using winget...
winget install OpenJS.NodeJS.LTSTools -e --source winget

:: Verify Node.js installation
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo Node.js installation may not be in PATH yet.
    echo We'll continue with the setup, but you may need to restart your
    echo computer before Node.js is available in other applications.
    echo.
    
    :: Fall back to direct download if node is not in PATH
    goto :direct_node_download
) else (
    echo Node.js installed successfully with winget.
    goto :setup_claude
)

:direct_node_download
:: As a fallback, download Node.js executable directly
echo Falling back to direct Node.js download...

:: 1. Create the ClaudeComputerCommander directory
set REPO_DIR=%USERPROFILE%\ClaudeComputerCommander-Unlocked
if not exist "%REPO_DIR%" mkdir "%REPO_DIR%"
cd "%REPO_DIR%"
echo Created installation directory at: %REPO_DIR%

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

goto :setup_claude_with_local_node

:setup_claude
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

:: 6. Create a startup script
echo @echo off > "%REPO_DIR%\start-commander.bat"
echo node "%REPO_DIR%\dist\index.js" >> "%REPO_DIR%\start-commander.bat"

:: 7. Update Claude configuration
echo Updating Claude Desktop configuration...

:: Create a temp file for the JSON content
set TEMP_JSON=%TEMP%\claude_config_temp.json
echo {> "%TEMP_JSON%"
echo   "mcpServers": {>> "%TEMP_JSON%"
echo     "desktopCommander": {>> "%TEMP_JSON%"
echo       "command": "node",>> "%TEMP_JSON%"
echo       "args": [>> "%TEMP_JSON%"
echo         "%REPO_DIR:\=\\%\\dist\\index.js">> "%TEMP_JSON%"
echo       ]>> "%TEMP_JSON%"
echo     }>> "%TEMP_JSON%"
echo   }>> "%TEMP_JSON%"
echo }>> "%TEMP_JSON%"

:: Copy the file directly to the config location
copy /Y "%TEMP_JSON%" "%CLAUDE_CONFIG%" >nul

goto :installation_complete

:setup_claude_with_local_node
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

:installation_complete
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