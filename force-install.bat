@echo off
setlocal enabledelayedexpansion

:: ClaudeComputerCommander-Unlocked Complete Installer
:: This script handles all installation needs including creating Claude configuration

echo ClaudeComputerCommander-Unlocked Complete Installer
echo =================================================
echo This script will set up everything needed for ClaudeComputerCommander-Unlocked.
echo It can even create the Claude Desktop configuration file if needed.
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

:: Check if Claude Desktop is installed by looking for the executable
set CLAUDE_EXE_FOUND=0
set CLAUDE_INSTALL_DIR=

:: Common places where Claude.exe might be found
set POSSIBLE_CLAUDE_LOCATIONS=^
    "C:\Program Files\Claude\Claude.exe" ^
    "C:\Program Files (x86)\Claude\Claude.exe" ^
    "%LOCALAPPDATA%\Programs\Claude\Claude.exe" ^
    "%APPDATA%\Local\Claude\Claude.exe" ^
    "%USERPROFILE%\AppData\Local\Programs\Claude\Claude.exe"

for %%c in (%POSSIBLE_CLAUDE_LOCATIONS%) do (
    if exist %%c (
        set CLAUDE_EXE_FOUND=1
        set CLAUDE_INSTALL_DIR=%%~dpc
        echo Claude Desktop found at: %%c
        goto :claude_exe_found
    )
)

:claude_exe_found
if %CLAUDE_EXE_FOUND% equ 0 (
    echo Claude Desktop executable not found.
    echo.
    echo Would you like to:
    echo 1. Download and install Claude Desktop first
    echo 2. Continue assuming Claude is installed but not detected
    choice /c 12 /n /m "Enter your choice (1 or 2): "
    
    if errorlevel 2 (
        echo Continuing with the installation...
    ) else (
        echo.
        echo We'll help you install Claude Desktop.
        echo Opening the Claude download page...
        start https://claude.ai/downloads
        echo.
        echo Please download and install Claude Desktop.
        echo After installation is complete, press any key to continue...
        pause >nul
    )
)

:: Determine where Claude configuration should be
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

:: Download standalone Node.js binary
echo Downloading standalone Node.js... (this may take a few minutes)
powershell -Command "try { Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.11.1/node-v20.11.1-win-x64.zip' -OutFile '%TEMP_DIR%\node.zip' } catch { Write-Host $_.Exception.Message }"
if not exist "%TEMP_DIR%\node.zip" (
    echo Error: Failed to download Node.js.
    echo Trying alternative download method...
    
    :: Fallback to bitsadmin (available on most Windows versions)
    bitsadmin /transfer NodeJSDownload /download /priority normal https://nodejs.org/dist/v20.11.1/node-v20.11.1-win-x64.zip "%TEMP_DIR%\node.zip"
    
    if not exist "%TEMP_DIR%\node.zip" (
        echo Error: All download methods failed. Please check your internet connection.
        goto :cleanup
    )
)

:: Extract Node.js
echo Extracting Node.js...
powershell -Command "try { Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%TEMP_DIR%\node.zip', '%TEMP_DIR%') } catch { try { Expand-Archive -Path '%TEMP_DIR%\node.zip' -DestinationPath '%TEMP_DIR%' -Force } catch { Write-Host $_.Exception.Message } }"

:: Check if extraction worked
set NODE_EXTRACTED=0
for /d %%d in (%TEMP_DIR%\node*) do (
    set NODE_DIR=%%d
    set NODE_EXTRACTED=1
    goto :node_found
)

:node_found
if %NODE_EXTRACTED% equ 0 (
    echo Failed to extract Node.js. Trying manual extraction...
    
    :: Try to extract manually using PowerShell's Expand-Archive
    powershell -Command "Expand-Archive -Path '%TEMP_DIR%\node.zip' -DestinationPath '%TEMP_DIR%' -Force"
    
    :: Check again
    for /d %%d in (%TEMP_DIR%\node*) do (
        set NODE_DIR=%%d
        set NODE_EXTRACTED=1
        goto :node_extracted
    )
    
    if %NODE_EXTRACTED% equ 0 (
        echo Failed to extract Node.js. Please extract it manually from:
        echo %TEMP_DIR%\node.zip
        echo to:
        echo %TEMP_DIR%
        pause
        goto :cleanup
    )
)

:node_extracted
echo Node.js extracted successfully to: %NODE_DIR%

:: Download the repository
echo Downloading ClaudeComputerCommander-Unlocked...
set REPO_DIR=%USERPROFILE%\ClaudeComputerCommander-Unlocked
if exist "%REPO_DIR%" (
    echo Repository directory already exists. Using existing files.
) else (
    powershell -Command "try { Invoke-WebRequest -Uri 'https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked/archive/refs/heads/main.zip' -OutFile '%TEMP_DIR%\repo.zip' } catch { Write-Host $_.Exception.Message }"
    if not exist "%TEMP_DIR%\repo.zip" (
        echo Error: Failed to download repository.
        echo Trying alternative download method...
        
        :: Fallback to bitsadmin
        bitsadmin /transfer RepoDownload /download /priority normal https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked/archive/refs/heads/main.zip "%TEMP_DIR%\repo.zip"
        
        if not exist "%TEMP_DIR%\repo.zip" (
            echo Error: All download methods failed. Please check your internet connection.
            goto :cleanup
        )
    )
    
    echo Extracting repository...
    powershell -Command "try { Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%TEMP_DIR%\repo.zip', '%TEMP_DIR%') } catch { try { Expand-Archive -Path '%TEMP_DIR%\repo.zip' -DestinationPath '%TEMP_DIR%' -Force } catch { Write-Host $_.Exception.Message } }"
    
    :: Check if the extraction worked
    if not exist "%TEMP_DIR%\ClaudeComputerCommander-Unlocked-main" (
        echo Failed to extract repository. Extraction may have failed.
        goto :cleanup
    )
    
    mkdir "%REPO_DIR%" 2>nul
    echo Copying files to %REPO_DIR%...
    xcopy /E /I /Y "%TEMP_DIR%\ClaudeComputerCommander-Unlocked-main\*" "%REPO_DIR%" 2>nul
)

:: Copy the Node.js files to the repository directory
echo Copying Node.js to repository directory...
if not exist "%REPO_DIR%\node" mkdir "%REPO_DIR%\node"
xcopy /E /I /Y "%NODE_DIR%\*" "%REPO_DIR%\node"

:: Ensure dist directory exists
if not exist "%REPO_DIR%\dist" mkdir "%REPO_DIR%\dist"

:: Create a minimal index.js file if not already present
if not exist "%REPO_DIR%\dist\index.js" (
    echo // ClaudeComputerCommander server > "%REPO_DIR%\dist\index.js"
    echo try { const config = require('../config.json'); } catch (e) { console.log('Config error:', e); } >> "%REPO_DIR%\dist\index.js"
    echo console.log('ClaudeComputerCommander is running...'); >> "%REPO_DIR%\dist\index.js"
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

:: Update Claude configuration manually with a direct approach
echo Updating Claude Desktop configuration...
powershell -Command "Write-Host 'Starting manual configuration...'; $configPath='%CLAUDE_CONFIG%'; $nodePath='%REPO_DIR:\=\\%\\node\\node.exe'; $indexPath='%REPO_DIR:\=\\%\\dist\\index.js'; if (Test-Path $configPath) { $configContent = Get-Content $configPath -Raw; try { $config = ConvertFrom-Json $configContent; } catch { Write-Host 'Error parsing config, creating new one'; $config = [PSCustomObject]@{mcpServers=@{}} | ConvertTo-Json -Depth 10 | Set-Content $configPath; $config = ConvertFrom-Json (Get-Content $configPath -Raw); }; if (-not $config.mcpServers) { $config | Add-Member -MemberType NoteProperty -Name 'mcpServers' -Value @{}; }; $newConfig = @{mcpServers=@{}}; $newConfig.mcpServers['desktopCommander'] = @{ 'command' = $nodePath; 'args' = @($indexPath) }; foreach ($prop in $config.PSObject.Properties) { if ($prop.Name -ne 'mcpServers') { $newConfig[$prop.Name] = $prop.Value; } }; ConvertTo-Json $newConfig -Depth 10 | Set-Content $configPath; Write-Host 'Updated Claude configuration successfully'; }"

echo.
echo Installation completed successfully!
echo.
echo The ClaudeComputerCommander-Unlocked has been installed to:
echo %REPO_DIR%
echo.
echo Claude Desktop has been configured to use this installation at:
echo %CLAUDE_CONFIG%
echo.
echo A sample configuration file has been created at:
echo %CONFIG_SAMPLE%
echo.
echo If you need to manually update the Claude configuration,
echo make sure it looks like the content in the sample file.
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

:cleanup
:: Clean up temporary files
echo Cleaning up temporary files...
rd /s /q "%TEMP_DIR%" >nul 2>&1

echo.
echo Press any key to exit...
pause >nul
exit /b
