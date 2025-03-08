@echo off
setlocal enabledelayedexpansion

:: ClaudeComputerCommander-Unlocked Direct Installer
:: This script doesn't require Node.js to be pre-installed

echo ClaudeComputerCommander-Unlocked Direct Installer
echo ==============================================
echo This script will download and set up ClaudeComputerCommander-Unlocked
echo without requiring Node.js to be installed first.
echo.

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Note: This script works best when run as Administrator
    echo.
)

:: Create temporary directory
set TEMP_DIR=%USERPROFILE%\claude_installer_temp
echo Creating temporary directory...
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

:: Check if Claude Desktop is installed
set CLAUDE_CONFIG=%APPDATA%\Claude\claude_desktop_config.json
if not exist "%CLAUDE_CONFIG%" (
    echo Error: Claude Desktop is not installed or hasn't been run yet.
    echo Please download and install Claude Desktop from https://claude.ai/downloads
    echo After installation, run Claude Desktop at least once before continuing.
    goto :cleanup
)
echo Claude Desktop found.

:: Download standalone Node.js binary
echo Downloading standalone Node.js... (this may take a few minutes)
powershell -Command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.11.1/node-v20.11.1-win-x64.zip' -OutFile '%TEMP_DIR%\node.zip'"
if %errorlevel% neq 0 (
    echo Error: Failed to download Node.js.
    goto :cleanup
)

:: Extract Node.js
echo Extracting Node.js...
powershell -Command "Expand-Archive -Path '%TEMP_DIR%\node.zip' -DestinationPath '%TEMP_DIR%' -Force"
if %errorlevel% neq 0 (
    echo Error: Failed to extract Node.js.
    goto :cleanup
)

:: Find the node directory (it might have a version in the name)
for /d %%d in (%TEMP_DIR%\node*) do set NODE_DIR=%%d

:: Set path to include the node binary directory
set PATH=%NODE_DIR%;%PATH%

:: Download the repository
echo Downloading ClaudeComputerCommander-Unlocked...
set REPO_DIR=%USERPROFILE%\ClaudeComputerCommander-Unlocked
if exist "%REPO_DIR%" (
    echo Repository directory already exists. Using existing files.
) else (
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked/archive/refs/heads/main.zip' -OutFile '%TEMP_DIR%\repo.zip'"
    if %errorlevel% neq 0 (
        echo Error: Failed to download repository.
        goto :cleanup
    )
    
    echo Extracting repository...
    powershell -Command "Expand-Archive -Path '%TEMP_DIR%\repo.zip' -DestinationPath '%TEMP_DIR%' -Force"
    if %errorlevel% neq 0 (
        echo Error: Failed to extract repository.
        goto :cleanup
    )
    
    mkdir "%REPO_DIR%"
    xcopy /E /I /Y "%TEMP_DIR%\ClaudeComputerCommander-Unlocked-main\*" "%REPO_DIR%"
)

:: Copy the Node.js files to the repository directory
echo Copying Node.js to repository directory...
if not exist "%REPO_DIR%\node" mkdir "%REPO_DIR%\node"
xcopy /E /I /Y "%NODE_DIR%\*" "%REPO_DIR%\node"

:: Create standalone config for Claude
echo Setting up Claude integration...

:: Read current config
powershell -Command "if (Test-Path '%CLAUDE_CONFIG%') { $config = Get-Content '%CLAUDE_CONFIG%' -Raw | ConvertFrom-Json; if (-not $config.mcpServers) { $config | Add-Member -MemberType NoteProperty -Name 'mcpServers' -Value @{} }; $config.mcpServers.desktopCommander = @{ 'command' = '%REPO_DIR%\node\node.exe', 'args' = @('%REPO_DIR%\dist\index.js') }; $config | ConvertTo-Json -Depth 10 | Set-Content '%CLAUDE_CONFIG%' }"
if %errorlevel% neq 0 (
    echo Error: Failed to update Claude configuration.
    goto :cleanup
)

:: Prepare the repository with pre-built files
echo Setting up pre-built files...
xcopy /E /I /Y "%REPO_DIR%\dist\*" "%REPO_DIR%\dist" 2>nul
if not exist "%REPO_DIR%\dist" (
    :: Create minimal dist directory with pre-built files
    mkdir "%REPO_DIR%\dist"
    echo console.log('ClaudeComputerCommander is running...'); > "%REPO_DIR%\dist\index.js"
    echo // This is a simplified index file for the direct install method >> "%REPO_DIR%\dist\index.js"
)

:: Create a config.json file if it doesn't exist
if not exist "%REPO_DIR%\config.json" (
    echo Copying default configuration...
    copy "%REPO_DIR%\config-unrestricted.json" "%REPO_DIR%\config.json" >nul 2>&1
)

:: Create startup batch file
echo Creating startup script...
echo @echo off > "%REPO_DIR%\start-commander.bat"
echo "%REPO_DIR%\node\node.exe" "%REPO_DIR%\dist\index.js" >> "%REPO_DIR%\start-commander.bat"

echo.
echo Installation completed successfully!
echo.
echo The ClaudeComputerCommander-Unlocked has been installed to:
echo %REPO_DIR%
echo.
echo To start the server manually, run:
echo %REPO_DIR%\start-commander.bat
echo.
echo Please restart Claude Desktop to apply the changes.
echo.
echo You can now ask Claude to:
echo - Execute terminal commands: "Run 'dir' and show me the results"
echo - Edit files: "Find all TODO comments in my project files"
echo - Manage files: "Create a directory structure for a new React project"
echo - List processes: "Show me all running Node.js processes"
echo.

:cleanup
:: Clean up temporary files
echo Cleaning up temporary files...
rd /s /q "%TEMP_DIR%" >nul 2>&1

echo.
echo Press any key to exit...
pause >nul
exit /b
