# PowerShell Bootstrap Script for ClaudeComputerCommander-Unlocked
# This script will install Node.js if needed, then proceed with the full installation

Write-Host "ClaudeComputerCommander-Unlocked Bootstrap Installer" -ForegroundColor Cyan
Write-Host "This script will install all required prerequisites and set up ClaudeComputerCommander-Unlocked" -ForegroundColor Cyan
Write-Host "======================================================================================" -ForegroundColor Cyan

# Define functions
function Test-CommandExists {
    param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if (Get-Command $command) { return $true }
    } catch {
        return $false
    } finally {
        $ErrorActionPreference = $oldPreference
    }
}

function Install-NodeJS {
    Write-Host "Installing Node.js..." -ForegroundColor Yellow
    
    # We'll try multiple Node.js installation methods to increase chances of success
    
    # Method 1: Direct download and run executable installer
    try {
        Write-Host "Trying Node.js installation method 1 (executable installer)..." -ForegroundColor Yellow
        $tempDir = Join-Path $env:USERPROFILE "temp_node_install"
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        
        # Download Node.js executable installer
        $installerPath = Join-Path $tempDir "node_installer.exe"
        Write-Host "Downloading Node.js installer (this might take a minute)..." -ForegroundColor Yellow
        
        try {
            Invoke-WebRequest -Uri "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi" -OutFile $installerPath
        } catch {
            Write-Host "Failed to download Node.js installer MSI: $_" -ForegroundColor Red
            throw
        }
        
        # Install Node.js
        Write-Host "Installing Node.js..." -ForegroundColor Yellow
        
        try {
            # Try with different options to ensure success
            # Use /qn for completely silent installation
            $result = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /qn" -Wait -PassThru
            
            if ($result.ExitCode -ne 0) {
                Write-Host "MSI installation failed with exit code: $($result.ExitCode)" -ForegroundColor Red
                throw "MSI installation failed"
            }
        } catch {
            Write-Host "Failed to install Node.js via MSI: $_" -ForegroundColor Red
            throw
        }
    } catch {
        # If MSI fails, try the .exe installer
        Write-Host "MSI installer failed, trying executable installer instead..." -ForegroundColor Yellow
        
        try {
            $tempDir = Join-Path $env:USERPROFILE "temp_node_install"
            if (-not (Test-Path $tempDir)) {
                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            }
            
            $installerPath = Join-Path $tempDir "node_installer.exe"
            
            # Download .exe installer
            Invoke-WebRequest -Uri "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.exe" -OutFile $installerPath
            
            # Install using .exe with silent options
            $result = Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait -PassThru
            
            if ($result.ExitCode -ne 0) {
                Write-Host "EXE installation failed with exit code: $($result.ExitCode)" -ForegroundColor Red
                throw "EXE installation failed"
            }
        } catch {
            Write-Host "Both MSI and EXE installation methods failed" -ForegroundColor Red
            
            # As a last resort, try the Windows nvm (Node Version Manager) approach
            Write-Host "Trying installation via nvm-windows as a last resort..." -ForegroundColor Yellow
            
            try {
                # Download nvm-windows installer
                $nvmInstallerPath = Join-Path $tempDir "nvm-setup.exe"
                Invoke-WebRequest -Uri "https://github.com/coreybutler/nvm-windows/releases/download/1.1.11/nvm-setup.exe" -OutFile $nvmInstallerPath
                
                # Install nvm-windows
                Start-Process -FilePath $nvmInstallerPath -ArgumentList "/SILENT" -Wait
                
                # Need to refresh environment variables
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                
                # Use nvm to install Node.js
                Start-Process -FilePath "nvm" -ArgumentList "install 20.11.1" -Wait
                Start-Process -FilePath "nvm" -ArgumentList "use 20.11.1" -Wait
                
            } catch {
                Write-Host "All Node.js installation methods failed." -ForegroundColor Red
                Write-Host "Please install Node.js manually from https://nodejs.org/en/download/" -ForegroundColor Red
                Write-Host "After installing Node.js, restart this script." -ForegroundColor Yellow
                exit 1
            }
        }
    }
    
    # Refresh PATH environment variable
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    # Verify installation
    $maxRetries = 3
    $retryCount = 0
    $success = $false
    
    while (-not $success -and $retryCount -lt $maxRetries) {
        Start-Sleep -Seconds 2  # Wait for installation to complete
        if (Test-CommandExists "node") {
            $success = $true
        } else {
            $retryCount++
            Write-Host "Node.js not detected in PATH yet, retrying... ($retryCount/$maxRetries)" -ForegroundColor Yellow
        }
    }
    
    if ($success) {
        $nodeVersion = node --version
        $npmVersion = npm --version
        Write-Host "Node.js $nodeVersion and npm $npmVersion installed successfully" -ForegroundColor Green
    } else {
        Write-Host "Node.js installation didn't register in PATH." -ForegroundColor Red
        Write-Host "Proceeding with manual setup..." -ForegroundColor Yellow
        
        # Attempt to use common Node.js installation paths
        $possibleNodePaths = @(
            "C:\Program Files\nodejs",
            "C:\Program Files (x86)\nodejs",
            "$env:USERPROFILE\AppData\Roaming\nvm\v20.11.1"
        )
        
        foreach ($path in $possibleNodePaths) {
            if (Test-Path $path) {
                Write-Host "Found Node.js installation at $path, adding to PATH" -ForegroundColor Yellow
                $env:Path = "$path;$env:Path"
                break
            }
        }
        
        # Final check
        if (Test-CommandExists "node") {
            $nodeVersion = node --version
            $npmVersion = npm --version
            Write-Host "Node.js $nodeVersion and npm $npmVersion found and added to PATH" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Unable to locate Node.js installation." -ForegroundColor Red
            Write-Host "Please install Node.js manually from https://nodejs.org/en/download/" -ForegroundColor Red
            return $false
        }
    }
    
    return $true
}

function Install-Git {
    Write-Host "Installing Git..." -ForegroundColor Yellow
    
    # Create temp directory
    $tempDir = Join-Path $env:USERPROFILE "temp_git_install"
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }
    
    # Download Git installer
    $installerPath = Join-Path $tempDir "git_installer.exe"
    Write-Host "Downloading Git installer (this might take a minute)..." -ForegroundColor Yellow
    
    try {
        Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.41.0.windows.3/Git-2.41.0.3-64-bit.exe" -OutFile $installerPath
    } catch {
        Write-Host "Failed to download Git installer: $_" -ForegroundColor Red
        Write-Host "Will continue without Git" -ForegroundColor Yellow
        return $false
    }
    
    # Install Git
    Write-Host "Installing Git..." -ForegroundColor Yellow
    try {
        Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS=`"icons,ext\reg\shellhere,assoc,assoc_sh`"" -Wait
    } catch {
        Write-Host "Failed to install Git: $_" -ForegroundColor Red
        Write-Host "Will continue without Git" -ForegroundColor Yellow
        return $false
    }
    
    # Refresh PATH environment variable
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    # Verify installation
    if (Test-CommandExists "git") {
        $gitVersion = git --version
        Write-Host "Git $gitVersion installed successfully" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Git installation might have failed, but will continue without Git" -ForegroundColor Yellow
        return $false
    }
    
    # Clean up
    try {
        Remove-Item $installerPath -Force
        Write-Host "Cleaned up temporary files" -ForegroundColor Green
    } catch {
        Write-Host "Failed to clean up temporary files, but installation will proceed" -ForegroundColor Yellow
    }
}

function Direct-Download-Repository {
    Write-Host "Downloading repository as ZIP..." -ForegroundColor Yellow
    
    $repoDir = Join-Path $env:USERPROFILE "ClaudeComputerCommander-Unlocked"
    $tempZip = Join-Path $env:USERPROFILE "claude_commander.zip"
    
    # Make sure target directory exists and is empty
    if (Test-Path $repoDir) {
        Write-Host "Removing existing repository folder..." -ForegroundColor Yellow
        Remove-Item $repoDir -Recurse -Force
    }
    
    New-Item -ItemType Directory -Path $repoDir -Force | Out-Null
    
    # Download directly from GitHub
    try {
        Invoke-WebRequest -Uri "https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked/archive/refs/heads/main.zip" -OutFile $tempZip -UseBasicParsing
    } catch {
        Write-Host "Failed to download repository: $_" -ForegroundColor Red
        exit 1
    }
    
    # Extract with PowerShell
    try {
        Write-Host "Extracting ZIP file..." -ForegroundColor Yellow
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $env:USERPROFILE)
    } catch {
        Write-Host "Failed to extract repository: $_" -ForegroundColor Red
        exit 1
    }
    
    # Move contents from extracted directory to target
    try {
        Write-Host "Moving files to target directory..." -ForegroundColor Yellow
        Get-ChildItem -Path (Join-Path $env:USERPROFILE "ClaudeComputerCommander-Unlocked-main") | Move-Item -Destination $repoDir -Force
    } catch {
        Write-Host "Failed to move repository files: $_" -ForegroundColor Red
        exit 1
    }
    
    # Clean up
    try {
        Remove-Item $tempZip -Force
        Remove-Item (Join-Path $env:USERPROFILE "ClaudeComputerCommander-Unlocked-main") -Recurse -Force
    } catch {
        Write-Host "Failed to clean up temporary files, but installation will proceed" -ForegroundColor Yellow
    }
    
    Write-Host "Repository downloaded and extracted to $repoDir" -ForegroundColor Green
    return $repoDir
}

function Check-ClaudeDesktop {
    $claudeConfigPath = Join-Path $env:APPDATA "Claude\claude_desktop_config.json"
    if (-not (Test-Path $claudeConfigPath)) {
        Write-Host "Claude Desktop is not installed or has not been run yet" -ForegroundColor Red
        Write-Host "Please download and install Claude Desktop from https://claude.ai/downloads" -ForegroundColor Yellow
        Write-Host "After installation, run Claude Desktop at least once before continuing" -ForegroundColor Yellow
        return $false
    }
    Write-Host "Claude Desktop is installed" -ForegroundColor Green
    return $claudeConfigPath
}

function Get-Repository {
    param ($gitInstalled)
    
    Write-Host "Setting up repository..." -ForegroundColor Yellow
    
    $repoDir = Join-Path $env:USERPROFILE "ClaudeComputerCommander-Unlocked"
    
    if (Test-Path $repoDir) {
        Write-Host "Repository already exists at $repoDir" -ForegroundColor Yellow
        Write-Host "Using existing repository. If you want a fresh install, please delete the directory first." -ForegroundColor Yellow
    } else {
        if ($gitInstalled) {
            # Clone with Git
            Write-Host "Cloning repository with Git..." -ForegroundColor Yellow
            try {
                git clone "https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked.git" $repoDir
            } catch {
                Write-Host "Failed to clone repository: $_" -ForegroundColor Red
                Write-Host "Falling back to direct download..." -ForegroundColor Yellow
                return Direct-Download-Repository
            }
        } else {
            # Download as ZIP and extract
            return Direct-Download-Repository
        }
        
        Write-Host "Repository set up at $repoDir" -ForegroundColor Green
    }
    
    return $repoDir
}

function Install-Dependencies {
    param ($repoDir)
    
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    
    Push-Location $repoDir
    try {
        # Ensure npm is in PATH
        if (-not (Test-CommandExists "npm")) {
            Write-Host "npm not found in PATH, checking for Node.js installation..." -ForegroundColor Yellow
            
            # Try to locate npm in common locations
            $possibleNpmPaths = @(
                "C:\Program Files\nodejs",
                "C:\Program Files (x86)\nodejs",
                "$env:USERPROFILE\AppData\Roaming\nvm\v*"
            )
            
            $npmFound = $false
            foreach ($basePath in $possibleNpmPaths) {
                $npmPath = $null
                if ($basePath -like "*\v*") {
                    # Handle nvm path pattern with wildcard
                    $nvmDirs = Get-ChildItem -Path ($basePath -replace "v\*", "") -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "v*" }
                    foreach ($dir in $nvmDirs) {
                        if (Test-Path (Join-Path $dir.FullName "npm.cmd")) {
                            $npmPath = $dir.FullName
                            break
                        }
                    }
                } else {
                    # Regular path
                    if (Test-Path (Join-Path $basePath "npm.cmd")) {
                        $npmPath = $basePath
                    }
                }
                
                if ($npmPath) {
                    Write-Host "Found npm at $npmPath, adding to PATH" -ForegroundColor Yellow
                    $env:Path = "$npmPath;$env:Path"
                    $npmFound = $true
                    break
                }
            }
            
            if (-not $npmFound) {
                Write-Host "npm not found. Node.js installation might be incomplete." -ForegroundColor Red
                Write-Host "Please install Node.js manually from https://nodejs.org/en/download/" -ForegroundColor Red
                exit 1
            }
        }
        
        # Install dependencies with npm
        $result = Start-Process -FilePath "npm" -ArgumentList "install" -Wait -PassThru -NoNewWindow
        if ($result.ExitCode -ne 0) {
            Write-Host "npm install failed with exit code: $($result.ExitCode)" -ForegroundColor Red
            throw "npm install failed"
        }
        
        Write-Host "Dependencies installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "Failed to install dependencies: $_" -ForegroundColor Red
        exit 1
    } finally {
        Pop-Location
    }
}

function Setup-ClaudeIntegration {
    param ($repoDir, $claudeConfigPath)
    
    Write-Host "Setting up integration with Claude Desktop..." -ForegroundColor Yellow
    
    # Read current Claude config
    try {
        $claudeConfig = Get-Content $claudeConfigPath -Raw | ConvertFrom-Json
    } catch {
        Write-Host "Error reading Claude configuration: $_" -ForegroundColor Red
        exit 1
    }
    
    # Create backup
    $timestamp = Get-Date -Format "yyyy.MM.dd-HH.mm"
    $backupPath = $claudeConfigPath.Replace(".json", "-bk-$timestamp.json")
    
    try {
        Copy-Item $claudeConfigPath -Destination $backupPath
        Write-Host "Created backup of Claude config at: $backupPath" -ForegroundColor Green
    } catch {
        Write-Host "Failed to create backup of Claude configuration: $_" -ForegroundColor Red
        exit 1
    }
    
    # Ensure mcpServers section exists
    if (-not $claudeConfig.mcpServers) {
        $claudeConfig | Add-Member -MemberType NoteProperty -Name "mcpServers" -Value @{}
    }
    
    # Add server configuration
    $claudeConfig.mcpServers.desktopCommander = @{
        "command" = "node"
        "args" = @(
            (Join-Path $repoDir "dist\index.js")
        )
    }
    
    # Write updated config
    try {
        $claudeConfig | ConvertTo-Json -Depth 10 | Set-Content $claudeConfigPath
        Write-Host "Updated Claude configuration successfully" -ForegroundColor Green
    } catch {
        Write-Host "Failed to update Claude configuration: $_" -ForegroundColor Red
        exit 1
    }
}

function Build-Project {
    param ($repoDir)
    
    Write-Host "Building project..." -ForegroundColor Yellow
    
    Push-Location $repoDir
    try {
        $result = Start-Process -FilePath "npm" -ArgumentList "run build" -Wait -PassThru -NoNewWindow
        if ($result.ExitCode -ne 0) {
            Write-Host "npm build failed with exit code: $($result.ExitCode)" -ForegroundColor Red
            throw "npm build failed"
        }
        
        Write-Host "Project built successfully" -ForegroundColor Green
    } catch {
        Write-Host "Failed to build project: $_" -ForegroundColor Red
        exit 1
    } finally {
        Pop-Location
    }
}

# Main installation flow
try {
    # Check for Administrator privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Host "* Run in PowerShell as Administrator" -ForegroundColor Green
    }
    
    # Step 1: Check prerequisites and install if missing
    
    # Check for Node.js and npm
    if (-not (Test-CommandExists "node") -or -not (Test-CommandExists "npm")) {
        Write-Host "Node.js is not installed or not in PATH" -ForegroundColor Yellow
        $nodeInstalled = Install-NodeJS
        if (-not $nodeInstalled) {
            Write-Host "Node.js installation failed. Please install Node.js manually from https://nodejs.org/en/download/" -ForegroundColor Red
            exit 1
        }
    } else {
        $nodeVersion = node --version
        $npmVersion = npm --version
        Write-Host "Node.js $nodeVersion is installed" -ForegroundColor Green
        Write-Host "npm $npmVersion is installed" -ForegroundColor Green
    }
    
    # Check for Git (optional)
    $gitInstalled = $true
    if (-not (Test-CommandExists "git")) {
        Write-Host "Git is not installed. Attempting to install Git automatically..." -ForegroundColor Yellow
        $gitInstalled = Install-Git
    } else {
        $gitVersion = git --version
        Write-Host "Git $gitVersion is installed" -ForegroundColor Green
    }
    
    # Check if Claude Desktop is installed
    $claudeConfigPath = Check-ClaudeDesktop
    if (-not $claudeConfigPath) {
        exit 1
    }
    
    # Step 2: Clone/download repository
    $repoDir = Get-Repository -gitInstalled $gitInstalled
    
    # Step 3: Install dependencies
    Install-Dependencies -repoDir $repoDir
    
    # Step 4: Build the project
    Build-Project -repoDir $repoDir
    
    # Step 5: Set up Claude integration
    Setup-ClaudeIntegration -repoDir $repoDir -claudeConfigPath $claudeConfigPath
    
    # Installation complete
    Write-Host "`nClaudeComputerCommander-Unlocked has been successfully installed!" -ForegroundColor Green
    Write-Host "The installation directory is: $repoDir" -ForegroundColor Cyan
    Write-Host "Please restart Claude Desktop to apply the changes." -ForegroundColor Cyan
    
    Write-Host "`nYou can now ask Claude to:" -ForegroundColor Cyan
    Write-Host "- Execute terminal commands: ""Run ``dir`` and show me the results""" -ForegroundColor Cyan
    Write-Host "- Edit files: ""Find all TODO comments in my project files""" -ForegroundColor Cyan
    Write-Host "- Manage files: ""Create a directory structure for a new React project""" -ForegroundColor Cyan
    Write-Host "- List processes: ""Show me all running Node.js processes""" -ForegroundColor Cyan
    
} catch {
    Write-Host "An unexpected error occurred during installation: $_" -ForegroundColor Red
    exit 1
}