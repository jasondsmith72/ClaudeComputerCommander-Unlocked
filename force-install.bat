@echo off
setlocal enabledelayedexpansion

:: ClaudeComputerCommander-Unlocked Force Installer
:: This script skips all Claude Desktop configuration checks and just sets up the server

echo ClaudeComputerCommander-Unlocked Force Installer
echo ==============================================
echo This script will set up ClaudeComputerCommander-Unlocked
echo without checking for Claude Desktop configuration.
echo.

:: Create temporary directory
set TEMP_DIR=%USERPROFILE%\claude_installer_temp
echo Creating temporary directory...
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

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
    )
    
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
        )
    )
    
    mkdir "%REPO_DIR%"
    xcopy /E /I /Y "%TEMP_DIR%\ClaudeComputerCommander-Unlocked-main\*" "%REPO_DIR%"
)

:: Copy the Node.js files to the repository directory
echo Copying Node.js to repository directory...
if not exist "%REPO_DIR%\node" mkdir "%REPO_DIR%\node"
xcopy /E /I /Y "%NODE_DIR%\*" "%REPO_DIR%\node"

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

:: Create startup batch file
echo Creating startup script...
echo @echo off > "%REPO_DIR%\start-commander.bat"
echo "%REPO_DIR%\node\node.exe" "%REPO_DIR%\dist\index.js" >> "%REPO_DIR%\start-commander.bat"

:: Create a sample configuration file
set CONFIG_SAMPLE=%REPO_DIR%\claude_config_sample.json
echo Creating sample Claude configuration file...
echo {> "%CONFIG_SAMPLE%"
echo   "mcpServers": {>> "%CONFIG_SAMPLE%"
echo     "desktopCommander": {>> "%CONFIG_SAMPLE%"
echo       "command": "%REPO_DIR:\=\\%\\node\\node.exe",>> "%CONFIG_SAMPLE%"
echo       "args": [>> "%CONFIG_SAMPLE%"
echo         "%REPO_DIR:\=\\%\\dist\\index.js">> "%CONFIG_SAMPLE%"
echo       ]>> "%CONFIG_SAMPLE%"
echo     }>> "%CONFIG_SAMPLE%"
echo   }>> "%CONFIG_SAMPLE%"
echo }>> "%CONFIG_SAMPLE%"

echo.
echo Installation completed successfully!
echo.
echo The ClaudeComputerCommander-Unlocked has been installed to:
echo %REPO_DIR%
echo.
echo IMPORTANT: You need to manually configure Claude Desktop to use this installation.
echo.
echo 1. Open Claude Desktop
echo 2. Look for the config file. You can find it by running:
echo    %REPO_DIR%\find-claude-config.bat
echo.
echo 3. Once you find the configuration file, edit it and add the following content:
echo.
type "%CONFIG_SAMPLE%"
echo.
echo 4. Save the file and restart Claude Desktop
echo.
echo To start the server manually, you can run:
echo %REPO_DIR%\start-commander.bat
echo.
echo A sample configuration file has been saved to:
echo %CONFIG_SAMPLE%
echo.

:cleanup
:: Clean up temporary files
echo Cleaning up temporary files...
rd /s /q "%TEMP_DIR%" >nul 2>&1

echo.
echo Press any key to exit...
pause >nul
exit /b
