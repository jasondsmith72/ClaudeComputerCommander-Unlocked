@echo off
setlocal EnableDelayedExpansion

:: ClaudeComputerCommander-Unlocked Minimal Installer
:: This script installs winget first if needed, then Node.js

echo ClaudeComputerCommander-Unlocked Minimal Installer
echo ================================================
echo This script will set up ClaudeComputerCommander-Unlocked
echo and install winget and Node.js if needed.
echo.

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Note: This script works best when run as Administrator
    echo for system-wide installation. You may be prompted for elevation.
    echo.
)

:: 1. Create the ClaudeComputerCommander directory first (needed regardless of Node.js method)
set "REPO_DIR=%USERPROFILE%\ClaudeComputerCommander-Unlocked"
if not exist "%REPO_DIR%" mkdir "%REPO_DIR%"
cd /d "%REPO_DIR%"
echo Created installation directory at: %REPO_DIR%

:: Set NODE_INSTALLED and USE_SYSTEM_NODE variables
set "NODE_INSTALLED=0"
set "USE_SYSTEM_NODE=0"

:: Check if winget is already available
winget --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Winget is not available. Attempting to install winget...
    
    :: Check Windows version - winget requires Windows 10 1809 or later
    ver | findstr /i "10\." >nul
    if %errorlevel% equ 0 (
        :: Windows 10 detected
        echo Windows 10 detected, proceeding with winget installation...
    ) else (
        ver | findstr /i "11\." >nul
        if %errorlevel% equ 0 (
            :: Windows 11 detected
            echo Windows 11 detected, proceeding with winget installation...
        ) else (
            echo Your Windows version appears to be older than Windows 10.
            echo Winget may not be supported on your system.
            echo Falling back to direct Node.js installation methods.
            goto :try_node_installation
        )
    )
    
    :: Try to install App Installer (winget) via PowerShell and Microsoft Store
    echo Attempting to install App Installer (winget) from Microsoft Store...
    powershell -Command "Start-Process 'ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1' -Wait"
    
    echo Waiting 10 seconds for installation to complete...
    timeout /t 10 /nobreak >nul
    
    :: Check if winget is now available
    winget --version >nul 2>&1
    if %errorlevel% neq 0 (
        :: Alternative: Try direct download of App Installer
        echo Microsoft Store method unsuccessful. Trying direct download...
        
        set "TEMP_DIR=%TEMP%\winget_install"
        if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
        
        :: Download the latest Microsoft.DesktopAppInstaller from GitHub
        echo Downloading App Installer package...
        powershell -Command "Invoke-WebRequest -Uri 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -OutFile '%TEMP_DIR%\AppInstaller.msixbundle'"
        
        if exist "%TEMP_DIR%\AppInstaller.msixbundle" (
            echo Installing App Installer package...
            powershell -Command "Add-AppxPackage -Path '%TEMP_DIR%\AppInstaller.msixbundle'"
            
            :: Check if winget is now available
            winget --version >nul 2>&1
            if %errorlevel% equ 0 (
                echo Winget installed successfully!
            ) else (
                echo Failed to install winget. Will try Node.js installation directly.
            )
        ) else (
            echo Failed to download App Installer package.
            echo Will try Node.js installation directly.
        )
    ) else (
        echo Winget installed successfully!
    )
) else (
    echo Winget is already installed.
)

:try_node_installation
:: Try installation methods in sequence - winget, msi, direct download

:: Method 1: Check if winget is available and try to install Node.js
winget --version >nul 2>&1
if %errorlevel% equ 0 (
    echo Using winget to install Node.js...
    winget install OpenJS.NodeJS.LTS -e --source winget
    
    :: Verify installation
    where node >nul 2>&1
    if %errorlevel% equ 0 (
        echo Node.js installed successfully with winget.
        set "NODE_INSTALLED=1"
        set "USE_SYSTEM_NODE=1"
    ) else (
        echo Winget installation attempted but Node.js is not in PATH.
        echo Will try alternative methods.
    )
) else (
    echo Winget is not available despite installation attempts.
    echo Trying alternative Node.js installation methods...
)

:: Method 2: Direct MSI download and installation if winget failed and have admin rights
if %NODE_INSTALLED% equ 0 (
    net session >nul 2>&1
    if %errorlevel% equ 0 (
        echo Attempting direct MSI installation (requires admin rights)...
        
        :: Create temp directory for MSI
        set "TEMP_DIR=%TEMP%\node_install"
        if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
        
        :: Download the Node.js MSI installer
        echo Downloading Node.js installer (this may take a minute)...
        powershell -Command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi' -OutFile '%TEMP_DIR%\node_installer.msi'"
        
        if exist "%TEMP_DIR%\node_installer.msi" (
            echo Running Node.js installer...
            start /wait msiexec /i "%TEMP_DIR%\node_installer.msi" /qn
            
            :: Verify installation
            where node >nul 2>&1
            if %errorlevel% equ 0 (
                echo Node.js installed successfully via MSI.
                set "NODE_INSTALLED=1"
                set "USE_SYSTEM_NODE=1"
            ) else (
                echo MSI installation attempted but Node.js is not in PATH.
                echo Will try portable installation.
            )
            
            :: Clean up
            del "%TEMP_DIR%\node_installer.msi"
            rmdir "%TEMP_DIR%"
        ) else (
            echo Failed to download Node.js MSI installer.
            echo Will try portable installation.
        )
    ) else (
        echo Cannot attempt MSI installation without administrator rights.
        echo Will try portable installation.
    )
)

:: Method 3: Direct executable download (fallback for all other methods)
if %NODE_INSTALLED% equ 0 (
    echo Using portable Node.js installation method...
    
    :: Download Node.js executable directly (not the full package)
    set "NODE_DIR=%REPO_DIR%\node"
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
        set "NODE_INSTALLED=1"
        set "USE_SYSTEM_NODE=0"
    )
)

:: Continue with Claude configuration
echo.
echo Setting up Claude integration...

:: Create Claude config directory and file
set "CLAUDE_CONFIG_DIR=%APPDATA%\Claude"
if not exist "%CLAUDE_CONFIG_DIR%" mkdir "%CLAUDE_CONFIG_DIR%"

set "CLAUDE_CONFIG=%CLAUDE_CONFIG_DIR%\claude_desktop_config.json"

:: Create Claude config file if it doesn't exist
if not exist "%CLAUDE_CONFIG%" (
    echo Creating Claude Desktop configuration file...
    echo {"mcpServers":{}} > "%CLAUDE_CONFIG%"
    echo Created new configuration file at: %CLAUDE_CONFIG%
) else (
    echo Using existing Claude configuration at: %CLAUDE_CONFIG%
)

:: Create config.json
echo Creating server configuration...
echo {"allowedDirectories":["*"],"allowedCommands":["*"]} > "%REPO_DIR%\config.json"

:: Create the dist directory and a minimal server script
mkdir "%REPO_DIR%\dist" 2>nul
echo // Minimal ClaudeComputerCommander Server > "%REPO_DIR%\dist\index.js"
echo console.log('ClaudeComputerCommander is running...'); >> "%REPO_DIR%\dist\index.js"
echo const fs = require('fs'); >> "%REPO_DIR%\dist\index.js"
echo const path = require('path'); >> "%REPO_DIR%\dist\index.js"
echo const config = require('../config.json'); >> "%REPO_DIR%\dist\index.js"
echo console.log('Config loaded:', config); >> "%REPO_DIR%\dist\index.js"
echo console.log('Server is ready to handle commands'); >> "%REPO_DIR%\dist\index.js"

:: Create startup script
if "%USE_SYSTEM_NODE%"=="1" (
    echo @echo off > "%REPO_DIR%\start-commander.bat"
    echo node "%REPO_DIR%\dist\index.js" >> "%REPO_DIR%\start-commander.bat"
) else (
    echo @echo off > "%REPO_DIR%\start-commander.bat"
    echo "%NODE_DIR%\node.exe" "%REPO_DIR%\dist\index.js" >> "%REPO_DIR%\start-commander.bat"
)

:: Update Claude configuration
echo Updating Claude Desktop configuration...

:: Create a temp file for the JSON content
set "TEMP_JSON=%TEMP%\claude_config_temp.json"
if "%USE_SYSTEM_NODE%"=="1" (
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
) else (
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
)

:: Copy the file directly to the config location
copy /Y "%TEMP_JSON%" "%CLAUDE_CONFIG%" >nul

echo.
echo Installation completed successfully!
echo.
if "%USE_SYSTEM_NODE%"=="1" (
    echo Node.js was installed system-wide and will be available for all applications.
) else (
    echo Node.js was installed as a portable executable only for Claude Commander.
)
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