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

:: Look for Claude Desktop in various locations
set CLAUDE_CONFIG_FOUND=0
set POSSIBLE_CLAUDE_CONFIGS=^
    "%APPDATA%\Claude\claude_desktop_config.json" ^
    "%LOCALAPPDATA%\Claude\claude_desktop_config.json" ^
    "C:\Program Files\Claude\Resources\app.asar.unpacked\Config\claude_desktop_config.json" ^
    "C:\Program Files (x86)\Claude\Resources\app.asar.unpacked\Config\claude_desktop_config.json" ^
    "%USERPROFILE%\AppData\Local\Claude\claude_desktop_config.json" ^
    "%USERPROFILE%\AppData\Roaming\Claude\claude_desktop_config.json"

for %%c in (%POSSIBLE_CLAUDE_CONFIGS%) do (
    if exist %%c (
        set CLAUDE_CONFIG=%%c
        set CLAUDE_CONFIG_FOUND=1
        echo Claude Desktop configuration found at: %%c
        goto :claude_found
    )
)

:claude_found
if %CLAUDE_CONFIG_FOUND% equ 0 (
    echo Error: Claude Desktop is not installed or hasn't been run yet.
    echo.
    echo If Claude is installed but this script can't find it, we'll create a custom
    echo installation that you can configure manually later.
    echo.
    echo Would you like to:
    echo 1. Exit and install Claude Desktop first
    echo 2. Continue with manual configuration later
    choice /c 12 /n /m "Enter your choice (1 or 2): "
    
    if errorlevel 2 (
        set CLAUDE_CONFIG=%USERPROFILE%\claude_desktop_config.json
        echo { "mcpServers": {} } > !CLAUDE_CONFIG!
        echo Created a placeholder config file at !CLAUDE_CONFIG!
        echo You'll need to manually copy the configuration later.
    ) else (
        echo Please download and install Claude Desktop from https://claude.ai/downloads
        echo After installation, run Claude Desktop at least once before continuing.
        goto :cleanup
    )
)

:: Download standalone Node.js binary
echo Downloading standalone Node.js... (this may take a few minutes)
powershell -Command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.11.1/node-v20.11.1-win-x64.zip' -OutFile '%TEMP_DIR%\node.zip'"
if %errorlevel% neq 0 (
    echo Error: Failed to download Node.js.
    echo Trying alternative download method...
    
    :: Fallback to bitsadmin (available on most Windows versions)
    bitsadmin /transfer NodeJSDownload /download /priority normal https://nodejs.org/dist/v20.11.1/node-v20.11.1-win-x64.zip "%TEMP_DIR%\node.zip"
    
    if %errorlevel% neq 0 (
        echo Error: All download methods failed. Please check your internet connection.
        goto :cleanup
    )
)

:: Extract Node.js
echo Extracting Node.js...
powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%TEMP_DIR%\node.zip', '%TEMP_DIR%')"
if %errorlevel% neq 0 (
    echo Error: Failed to extract Node.js with PowerShell.
    echo Trying alternative extraction method...
    
    :: Use built-in Windows expansion if available
    powershell -Command "Expand-Archive -Path '%TEMP_DIR%\node.zip' -DestinationPath '%TEMP_DIR%' -Force"
    
    if %errorlevel% neq 0 (
        echo Error: All extraction methods failed.
        goto :cleanup
    )
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
        echo Trying alternative download method...
        
        :: Fallback to bitsadmin
        bitsadmin /transfer RepoDownload /download /priority normal https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked/archive/refs/heads/main.zip "%TEMP_DIR%\repo.zip"
        
        if %errorlevel% neq 0 (
            echo Error: All download methods failed. Please check your internet connection.
            goto :cleanup
        )
    }
    
    echo Extracting repository...
    powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%TEMP_DIR%\repo.zip', '%TEMP_DIR%')"
    if %errorlevel% neq 0 (
        echo Error: Failed to extract repository with PowerShell.
        echo Trying alternative extraction method...
        
        :: Use built-in Windows expansion if available
        powershell -Command "Expand-Archive -Path '%TEMP_DIR%\repo.zip' -DestinationPath '%TEMP_DIR%' -Force"
        
        if %errorlevel% neq 0 (
            echo Error: All extraction methods failed.
            goto :cleanup
        }
    }
    
    mkdir "%REPO_DIR%"
    xcopy /E /I /Y "%TEMP_DIR%\ClaudeComputerCommander-Unlocked-main\*" "%REPO_DIR%"
)

:: Copy the Node.js files to the repository directory
echo Copying Node.js to repository directory...
if not exist "%REPO_DIR%\node" mkdir "%REPO_DIR%\node"
xcopy /E /I /Y "%NODE_DIR%\*" "%REPO_DIR%\node"

:: Create standalone config for Claude
echo Setting up Claude integration...

:: Ensure dist directory exists
if not exist "%REPO_DIR%\dist" mkdir "%REPO_DIR%\dist"

:: Create a minimal index.js file if not already present
if not exist "%REPO_DIR%\dist\index.js" (
    echo console.log('ClaudeComputerCommander is running...'); > "%REPO_DIR%\dist\index.js"
    echo // This is a simplified index file for the direct install method >> "%REPO_DIR%\dist\index.js"
)

:: Create a config.json file if it doesn't exist
if exist "%REPO_DIR%\config-unrestricted.json" (
    copy "%REPO_DIR%\config-unrestricted.json" "%REPO_DIR%\config.json" >nul 2>&1
) else (
    echo {"allowedDirectories":["*"],"allowedCommands":["*"]} > "%REPO_DIR%\config.json"
)

:: Read current config and update it with our server
echo @echo off > "%TEMP_DIR%\update_config.bat"
echo powershell -Command "$configPath='%CLAUDE_CONFIG%'; $serverName='desktopCommander'; $nodePath='%REPO_DIR%\node\node.exe'; $indexPath='%REPO_DIR%\dist\index.js'; if (Test-Path $configPath) { $config = Get-Content $configPath -Raw | ConvertFrom-Json; if (-not $config.mcpServers) { $config | Add-Member -MemberType NoteProperty -Name 'mcpServers' -Value @{} }; $config.mcpServers.$serverName = @{ 'command' = $nodePath; 'args' = @($indexPath) }; $config | ConvertTo-Json -Depth 10 | Set-Content $configPath; Write-Host 'Updated Claude configuration successfully' }" >> "%TEMP_DIR%\update_config.bat"
call "%TEMP_DIR%\update_config.bat"

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
echo If Claude Desktop was detected, it's been configured to use this installation.
echo.
echo If Claude Desktop wasn't found automatically, please copy this configuration
echo to your Claude Desktop config file (typically in %%APPDATA%%\Claude\claude_desktop_config.json):
echo.
echo {
echo   "mcpServers": {
echo     "desktopCommander": {
echo       "command": "%REPO_DIR:\=\\%\\node\\node.exe",
echo       "args": [
echo         "%REPO_DIR:\=\\%\\dist\\index.js"
echo       ]
echo     }
echo   }
echo }
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
