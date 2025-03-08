@echo off
setlocal enabledelayedexpansion

:: ClaudeComputerCommander-Unlocked Winget Installer
:: This script installs Node.js system-wide using winget and sets up ClaudeComputerCommander

echo ClaudeComputerCommander-Unlocked Winget Installer
echo ================================================
echo This script will install Node.js using winget and set up
echo ClaudeComputerCommander-Unlocked for use with Claude Desktop.
echo.

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Note: This script works best when run as Administrator
    echo.
)

:: 1. Check if winget is available
echo Checking for winget...
where winget >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: winget is not installed on this system.
    echo Please install the App Installer from the Microsoft Store.
    echo You can search for "App Installer" in the Microsoft Store.
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)
echo Winget is available.

:: 2. Install Node.js system-wide using winget
echo Checking if Node.js is installed...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Node.js system-wide using winget...
    echo This may take a few minutes and might require confirmation...
    winget install OpenJS.NodeJS.LTS -e --source winget
    
    if %errorlevel% neq 0 (
        echo Failed to install Node.js. Trying with LTSTools package...
        winget install OpenJS.NodeJS.LTSTools -e --source winget
        
        if %errorlevel% neq 0 (
            echo ERROR: Failed to install Node.js using winget.
            echo Please install Node.js manually from https://nodejs.org/
            echo.
            echo Press any key to exit...
            pause >nul
            exit /b 1
        )
    )
    
    echo Node.js installation complete.
    echo You may need to restart your computer or command prompt to use Node.js.
    echo.
    echo Would you like to continue with setup (Y) or exit to restart first (N)?
    choice /c YN /n /m "Continue with setup? (Y/N): "
    
    if errorlevel 2 (
        echo Please restart your computer or command prompt and run this script again.
        echo.
        echo Press any key to exit...
        pause >nul
        exit /b 0
    )
) else (
    echo Node.js is already installed.
)

:: 3. Create Claude config directory and file
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

:: 4. Create the ClaudeComputerCommander directory
set REPO_DIR=%USERPROFILE%\ClaudeComputerCommander-Unlocked
if not exist "%REPO_DIR%" mkdir "%REPO_DIR%"
cd "%REPO_DIR%"
echo Created installation directory at: %REPO_DIR%

:: 5. Download the repository files
echo Downloading repository files...
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked/archive/refs/heads/main.zip' -OutFile '%TEMP%\repo.zip'"

if not exist "%TEMP%\repo.zip" (
    echo Failed to download repository files.
    echo Please check your internet connection.
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

:: Extract repository files
echo Extracting repository files...
powershell -Command "Expand-Archive -Path '%TEMP%\repo.zip' -DestinationPath '%TEMP%' -Force"

:: Copy files to installation directory
echo Copying files to installation directory...
xcopy /E /I /Y "%TEMP%\ClaudeComputerCommander-Unlocked-main\*" "%REPO_DIR%" 2>nul

:: 6. Install Node.js dependencies
echo Installing Node.js dependencies...
cd "%REPO_DIR%"
call npm install

:: 7. Build the project
echo Building the project...
call npm run build

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

:: 9. Create a startup script
echo @echo off > "%REPO_DIR%\start-commander.bat"
echo node "%REPO_DIR%\dist\index.js" >> "%REPO_DIR%\start-commander.bat"

echo.
echo Installation completed successfully!
echo.
echo Node.js has been installed system-wide and can be used for other applications.
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
echo You can also use Node.js from the command line for your own projects.
echo.
echo Press any key to exit...
pause >nul
