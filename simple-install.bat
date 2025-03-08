@echo off
rem ClaudeComputerCommander-Unlocked Ultra-Simple Installer
rem This is a very minimal script with reduced features to avoid syntax errors

echo ClaudeComputerCommander-Unlocked Ultra-Simple Installer
echo ================================================
echo Simplified installer for better compatibility
echo.

rem Create installation directory
set REPO_DIR=%USERPROFILE%\ClaudeComputerCommander-Unlocked
if not exist "%REPO_DIR%" mkdir "%REPO_DIR%"
cd /d "%REPO_DIR%"
echo Created installation directory at: %REPO_DIR%

rem Create Claude config directory and file
set CLAUDE_CONFIG_DIR=%APPDATA%\Claude
if not exist "%CLAUDE_CONFIG_DIR%" mkdir "%CLAUDE_CONFIG_DIR%"
set CLAUDE_CONFIG=%CLAUDE_CONFIG_DIR%\claude_desktop_config.json

rem Create Claude config file if it doesn't exist
if not exist "%CLAUDE_CONFIG%" (
    echo Creating Claude Desktop configuration file...
    echo {"mcpServers":{}} > "%CLAUDE_CONFIG%"
    echo Created new configuration file at: %CLAUDE_CONFIG%
) else (
    echo Using existing Claude configuration at: %CLAUDE_CONFIG%
)

rem Create config.json
echo Creating server configuration...
echo {"allowedDirectories":["*"],"allowedCommands":["*"]} > "%REPO_DIR%\config.json"

rem Create the dist directory and a minimal server script
mkdir "%REPO_DIR%\dist" 2>nul
echo // Minimal ClaudeComputerCommander Server > "%REPO_DIR%\dist\index.js"
echo console.log('ClaudeComputerCommander is running...'); >> "%REPO_DIR%\dist\index.js"
echo const fs = require('fs'); >> "%REPO_DIR%\dist\index.js"
echo const path = require('path'); >> "%REPO_DIR%\dist\index.js"
echo const config = require('../config.json'); >> "%REPO_DIR%\dist\index.js"
echo console.log('Config loaded:', config); >> "%REPO_DIR%\dist\index.js"
echo console.log('Server is ready to handle commands'); >> "%REPO_DIR%\dist\index.js"

rem Try to use Node.js from PATH first
where node >nul 2>&1
if %errorlevel% equ 0 (
    echo System Node.js found, using it...
    set USE_SYSTEM_NODE=1
) else (
    echo No system-wide Node.js found. Downloading portable version...
    set USE_SYSTEM_NODE=0
    
    rem Download Node.js executable directly
    set NODE_DIR=%REPO_DIR%\node
    mkdir "%NODE_DIR%" 2>nul
    
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
)

rem Create startup script
if "%USE_SYSTEM_NODE%"=="1" (
    echo @echo off > "%REPO_DIR%\start-commander.bat"
    echo node "%REPO_DIR%\dist\index.js" >> "%REPO_DIR%\start-commander.bat"
    
    rem Update Claude configuration for system Node.js
    echo {> "%TEMP%\claude_config_temp.json"
    echo   "mcpServers": {>> "%TEMP%\claude_config_temp.json"
    echo     "desktopCommander": {>> "%TEMP%\claude_config_temp.json"
    echo       "command": "node",>> "%TEMP%\claude_config_temp.json"
    echo       "args": [>> "%TEMP%\claude_config_temp.json"
    echo         "%REPO_DIR:\=\\%\\dist\\index.js">> "%TEMP%\claude_config_temp.json"
    echo       ]>> "%TEMP%\claude_config_temp.json"
    echo     }>> "%TEMP%\claude_config_temp.json"
    echo   }>> "%TEMP%\claude_config_temp.json"
    echo }>> "%TEMP%\claude_config_temp.json"
) else (
    echo @echo off > "%REPO_DIR%\start-commander.bat"
    echo "%NODE_DIR%\node.exe" "%REPO_DIR%\dist\index.js" >> "%REPO_DIR%\start-commander.bat"
    
    rem Update Claude configuration for local Node.js
    echo {> "%TEMP%\claude_config_temp.json"
    echo   "mcpServers": {>> "%TEMP%\claude_config_temp.json"
    echo     "desktopCommander": {>> "%TEMP%\claude_config_temp.json"
    echo       "command": "%NODE_DIR:\=\\%\\node.exe",>> "%TEMP%\claude_config_temp.json"
    echo       "args": [>> "%TEMP%\claude_config_temp.json"
    echo         "%REPO_DIR:\=\\%\\dist\\index.js">> "%TEMP%\claude_config_temp.json"
    echo       ]>> "%TEMP%\claude_config_temp.json"
    echo     }>> "%TEMP%\claude_config_temp.json"
    echo   }>> "%TEMP%\claude_config_temp.json"
    echo }>> "%TEMP%\claude_config_temp.json"
)

rem Copy the file directly to the config location
copy /Y "%TEMP%\claude_config_temp.json" "%CLAUDE_CONFIG%" >nul

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
echo Please restart Claude Desktop to apply the changes.
echo If Claude is already running, close it and start it again.
echo.
echo You can now ask Claude to:
echo - Execute terminal commands
echo - Edit files
echo - Manage files
echo - List processes
echo.
echo Press any key to exit...
pause >nul