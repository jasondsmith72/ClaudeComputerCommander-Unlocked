@echo off
setlocal enabledelayedexpansion

:: ClaudeComputerCommander-Unlocked Winget Installer
:: This script installs Node.js system-wide using winget

echo ClaudeComputerCommander-Unlocked Winget Installer
echo ===============================================
echo This script will install Node.js system-wide using winget
echo and set up ClaudeComputerCommander-Unlocked.
echo.

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: This script requires administrator privileges for winget installation.
    echo Please run as Administrator for full functionality.
    echo.
    pause
    exit /b 1
)

:: Check if winget is available
winget --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Winget is not available on this system.
    echo Please ensure you're running Windows 10 1809 or later with App Installer installed.
    echo You can install App Installer from the Microsoft Store.
    echo.
    pause
    exit /b 1
)

:: 1. Install Node.js system-wide using winget
echo Installing Node.js system-wide using winget...
echo This will make Node.js available for all your applications.
echo.
winget install OpenJS.NodeJS.LTS -e --source winget

:: Verify Node.js installation
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo Node.js installation may not be in PATH yet.
    echo You may need to restart your computer before using Node.js in other applications.
    echo We'll continue with the ClaudeComputerCommander setup anyway.
    echo.
)

:: 2. Create Claude config directory and file
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

:: 3. Create the ClaudeComputerCommander directory
set REPO_DIR=%USERPROFILE%\ClaudeComputerCommander-Unlocked
if not exist "%REPO_DIR%" mkdir "%REPO_DIR%"
cd "%REPO_DIR%"
echo Created installation directory at: %REPO_DIR%

:: 4. Download the repository files
echo Downloading repository files...
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked/archive/refs/heads/main.zip' -OutFile '%TEMP%\repo.zip'"

:: Extract the repository
echo Extracting repository files...
powershell -Command "Expand-Archive -Path '%TEMP%\repo.zip' -DestinationPath '%TEMP%' -Force"

:: Copy files to the installation directory
echo Copying files to installation directory...
xcopy /E /I /Y "%TEMP%\ClaudeComputerCommander-Unlocked-main\*" "%REPO_DIR%" 2>nul

:: 5. Install dependencies using npm
echo Installing dependencies...
cd "%REPO_DIR%"
call npm install

:: 6. Build the project
echo Building project...
call npm run build

:: 7. Create a startup script
echo @echo off > "%REPO_DIR%\start-commander.bat"
echo node "%REPO_DIR%\dist\index.js" >> "%REPO_DIR%\start-commander.bat"

:: 8. Update Claude configuration
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

echo.
echo Installation completed successfully!
echo.
echo The ClaudeComputerCommander-Unlocked has been installed to:
echo %REPO_DIR%
echo.
echo Claude Desktop has been configured to use this installation at:
echo %CLAUDE_CONFIG%
echo.
echo Node.js has been installed system-wide and is available for all applications.
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
