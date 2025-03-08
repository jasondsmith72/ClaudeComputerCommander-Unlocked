# ClaudeComputerCommander-Unlocked PowerShell Installer
# This script properly fetches the complete repository, installs dependencies, and configures Claude Desktop

Write-Host "ClaudeComputerCommander-Unlocked PowerShell Installer"
Write-Host "================================================"
Write-Host "This script will set up ClaudeComputerCommander-Unlocked"
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "NOTE: Some features work better with Administrator rights." -ForegroundColor Yellow
    Write-Host ""
}

# Set installation directory
$RepoDir = Join-Path $env:USERPROFILE "ClaudeComputerCommander-Unlocked"
Write-Host "Installing to: $RepoDir" -ForegroundColor Cyan

# Create/clean installation directory
if (Test-Path $RepoDir) {
    Write-Host "Existing installation found. Creating backup..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupDir = "${RepoDir}-backup-${timestamp}"
    Move-Item -Path $RepoDir -Destination $backupDir
    Write-Host "Backed up to: $backupDir" -ForegroundColor Green
}

New-Item -ItemType Directory -Path $RepoDir -Force | Out-Null
Set-Location $RepoDir
Write-Host "Created installation directory at: $RepoDir"

# Locate Claude Desktop configuration
$possibleConfigDirs = @(
    (Join-Path $env:APPDATA "Claude"),
    (Join-Path $env:USERPROFILE "OneDrive\Desktop"),
    (Join-Path $env:USERPROFILE "Desktop"),
    (Join-Path $env:LOCALAPPDATA "Claude")
)

$ClaudeConfig = $null
$configFileName = "claude_desktop_config.json"

# First look for existing config file
foreach ($dir in $possibleConfigDirs) {
    $configPath = Join-Path $dir $configFileName
    if (Test-Path $configPath) {
        $ClaudeConfig = $configPath
        $ClaudeConfigDir = $dir
        Write-Host "Found existing Claude Desktop configuration at: $ClaudeConfig" -ForegroundColor Green
        break
    }
}

# If not found, create in default location
if (-not $ClaudeConfig) {
    $ClaudeConfigDir = Join-Path $env:APPDATA "Claude"
    if (-not (Test-Path $ClaudeConfigDir)) {
        New-Item -ItemType Directory -Path $ClaudeConfigDir -Force | Out-Null
    }
    $ClaudeConfig = Join-Path $ClaudeConfigDir $configFileName
    Write-Host "Will create Claude Desktop configuration at: $ClaudeConfig" -ForegroundColor Yellow
}

# Create backup of existing config
$BackupCreated = $false
if (Test-Path $ClaudeConfig) {
    $Timestamp = Get-Date -Format "yyyy-MM-dd-HH.mm"
    $BackupFile = [System.IO.Path]::ChangeExtension($ClaudeConfig, "bk-$Timestamp.json")
    Copy-Item -Path $ClaudeConfig -Destination $BackupFile -Force
    Write-Host "Created backup of existing config at: $BackupFile" -ForegroundColor Green
    $BackupCreated = $true
}

# Check for Node.js
$UseSystemNode = $false
try {
    $NodeVersion = & node --version
    Write-Host "Node.js $NodeVersion is already installed." -ForegroundColor Green
    Write-Host "Using existing Node.js installation." -ForegroundColor Green
    $UseSystemNode = $true
} catch {
    Write-Host "No existing Node.js installation found. Will install Node.js..." -ForegroundColor Yellow
    
    # Only try to install Node.js if it's not already installed
    if ($isAdmin) {
        Write-Host "Attempting to install Node.js system-wide..." -ForegroundColor Cyan
        
        # Check if winget is available
        $wingetInstalled = $false
        try {
            $wingetVersion = & winget --version
            Write-Host "Winget found ($wingetVersion)." -ForegroundColor Green
            $wingetInstalled = $true
        } catch {
            Write-Host "Winget not found. Will try MSI installation instead..." -ForegroundColor Yellow
        }
        
        if ($wingetInstalled) {
            # Install Node.js using winget
            Write-Host "Installing Node.js LTS using winget..." -ForegroundColor Cyan
            try {
                & winget install OpenJS.NodeJS.LTS -e --source winget
                
                # Verify installation
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                try {
                    $NodeVersion = & node --version
                    Write-Host "Node.js $NodeVersion installed successfully with winget." -ForegroundColor Green
                    $UseSystemNode = $true
                } catch {
                    Write-Host "Winget installation completed but Node.js is not in PATH yet." -ForegroundColor Yellow
                    Write-Host "Will configure for system Node.js - you may need to restart your computer later." -ForegroundColor Yellow
                    $UseSystemNode = $true
                }
            } catch {
                Write-Host "Error installing Node.js with winget: $_" -ForegroundColor Red
                Write-Host "Falling back to MSI installation method..." -ForegroundColor Yellow
            }
        }
        
        # If winget installation failed, try direct MSI installation
        if (-not $UseSystemNode) {
            try {
                # Create temp directory for MSI
                $TempDir = Join-Path $env:TEMP "node_install"
                if (-not (Test-Path $TempDir)) {
                    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
                }
                
                # Download the Node.js MSI installer
                $NodeMsiUrl = "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi"
                $NodeMsiPath = Join-Path $TempDir "node_installer.msi"
                Write-Host "Downloading Node.js installer from $NodeMsiUrl..." -ForegroundColor Cyan
                Invoke-WebRequest -Uri $NodeMsiUrl -OutFile $NodeMsiPath
                
                if (Test-Path $NodeMsiPath) {
                    Write-Host "Running Node.js installer..." -ForegroundColor Cyan
                    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$NodeMsiPath`" /qn" -Wait
                    
                    # Verify installation after MSI installer runs
                    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                    try {
                        $NodeVersion = & node --version
                        Write-Host "Node.js $NodeVersion installed successfully via MSI." -ForegroundColor Green
                        $UseSystemNode = $true
                    } catch {
                        Write-Host "MSI installation completed but Node.js is not in PATH yet." -ForegroundColor Yellow
                        Write-Host "Will configure for system Node.js - you may need to restart your computer later." -ForegroundColor Yellow
                        $UseSystemNode = $true
                    }
                    
                    # Clean up
                    Remove-Item -Path $NodeMsiPath -Force -ErrorAction SilentlyContinue
                } else {
                    Write-Host "Failed to download Node.js MSI installer." -ForegroundColor Red
                    Write-Host "Will fall back to portable installation." -ForegroundColor Yellow
                }
            } catch {
                Write-Host "Error during MSI installation: $_" -ForegroundColor Red
                Write-Host "Will fall back to portable installation." -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "Administrator rights required for system-wide Node.js installation." -ForegroundColor Yellow
        Write-Host "Will fall back to portable installation." -ForegroundColor Yellow
    }
}

# Fall back to portable Node.js only if system installation failed
if (-not $UseSystemNode) {
    Write-Host "Setting up portable Node.js installation..." -ForegroundColor Yellow
    
    # Download Node.js executable directly
    $NodeDir = Join-Path $RepoDir "node"
    if (-not (Test-Path $NodeDir)) {
        New-Item -ItemType Directory -Path $NodeDir -Force | Out-Null
    }
    
    try {
        Write-Host "Downloading portable Node.js executable..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri "https://nodejs.org/dist/v20.11.1/win-x64/node.exe" -OutFile (Join-Path $NodeDir "node.exe")
        Write-Host "Successfully downloaded Node.js executable to $NodeDir\node.exe" -ForegroundColor Green
        
        # Download npm
        Write-Host "Downloading npm files..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri "https://nodejs.org/dist/v20.11.1/node_modules.zip" -OutFile (Join-Path $NodeDir "node_modules.zip")
        Expand-Archive -Path (Join-Path $NodeDir "node_modules.zip") -DestinationPath $NodeDir -Force
        Remove-Item -Path (Join-Path $NodeDir "node_modules.zip") -Force -ErrorAction SilentlyContinue
        Write-Host "Successfully downloaded npm." -ForegroundColor Green
    } catch {
        Write-Host "Failed to download Node.js executable: $_" -ForegroundColor Red
        Write-Host "Please download it manually from: https://nodejs.org/dist/v20.11.1/win-x64/node.exe" -ForegroundColor Red
        Write-Host "and place it in: $NodeDir\node.exe" -ForegroundColor Red
        Write-Host ""
        Write-Host "Press any key to continue anyway..." -ForegroundColor Red
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# Check if Git is installed
$hasGit = $false
try {
    $gitVersion = & git --version
    Write-Host "Git found: $gitVersion" -ForegroundColor Green
    $hasGit = $true
} catch {
    Write-Host "Git not found. Will download repository as ZIP instead." -ForegroundColor Yellow
}

# Clone or download repository
if ($hasGit) {
    # Clone repository
    Write-Host "Cloning ClaudeComputerCommander-Unlocked repository..." -ForegroundColor Cyan
    try {
        & git clone https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked.git $RepoDir
        Write-Host "Repository cloned successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to clone repository: $_" -ForegroundColor Red
        Write-Host "Will download as ZIP instead..." -ForegroundColor Yellow
        $hasGit = $false
    }
}

if (-not $hasGit) {
    # Download as ZIP
    Write-Host "Downloading repository ZIP..." -ForegroundColor Cyan
    $zipUrl = "https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked/archive/main.zip"
    $zipPath = Join-Path $env:TEMP "ClaudeComputerCommander-Unlocked.zip"
    $extractPath = Join-Path $env:TEMP "ClaudeComputerCommander-Unlocked-extract"
    
    try {
        # Download
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
        
        # Create extraction directory
        if (Test-Path $extractPath) { Remove-Item -Path $extractPath -Recurse -Force }
        New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
        
        # Extract
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        
        # Move contents to repo directory
        $extractedDir = Join-Path $extractPath "ClaudeComputerCommander-Unlocked-main"
        if (Test-Path $extractedDir) {
            Get-ChildItem -Path $extractedDir | Copy-Item -Destination $RepoDir -Recurse -Force
        } else {
            Write-Host "Unexpected extraction path. Searching for files..." -ForegroundColor Yellow
            $possibleDirs = Get-ChildItem -Path $extractPath -Directory
            if ($possibleDirs.Count -gt 0) {
                Get-ChildItem -Path $possibleDirs[0].FullName | Copy-Item -Destination $RepoDir -Recurse -Force
            } else {
                Write-Host "Failed to locate extracted files." -ForegroundColor Red
            }
        }
        
        # Clean up
        Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host "Repository downloaded and extracted successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to download or extract repository: $_" -ForegroundColor Red
        Write-Host "Will create minimal files to continue..." -ForegroundColor Yellow
        
        # Create minimal files
        # Create dist directory
        $DistDir = Join-Path $RepoDir "dist"
        if (-not (Test-Path $DistDir)) {
            New-Item -ItemType Directory -Path $DistDir -Force | Out-Null
        }
        
        # Create index.js
        $ServerScript = @"
// Minimal ClaudeComputerCommander Server (EMERGENCY FALLBACK)
console.log('ClaudeComputerCommander-Unlocked emergency fallback is running...');
console.log('This is a minimal version. Please visit the repository for the full version:');
console.log('https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked');

const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');

// Available functions
const execute_command = async (command) => {
  console.log(`Executing command: ${command}`);
  const { exec } = require('child_process');
  return new Promise((resolve) => {
    exec(command, (error, stdout, stderr) => {
      resolve({ output: stdout || stderr, pid: Math.floor(Math.random() * 10000) });
    });
  });
};

// Minimal server implementation
const server = {
  connect: async (transport) => {
    console.log('Server connected');
    transport.onRequest(async (request) => {
      console.log('Received request:', request);
      let response = { error: 'Function not implemented' };
      
      if (request.function === 'execute_command') {
        response = await execute_command(request.parameters.command);
      }
      
      return response;
    });
  }
};

// Start server
const transport = new StdioServerTransport();
server.connect(transport)
  .catch(error => console.error('Server error:', error));
"@
        $ServerScript | Out-File -FilePath (Join-Path $DistDir "index.js") -Encoding utf8
        
        # Create config.json
        $ConfigContent = @"
{
  "allowedDirectories": ["*"],
  "allowedCommands": ["*"],
  "fallbackMode": true
}
"@
        $ConfigContent | Out-File -FilePath (Join-Path $RepoDir "config.json") -Encoding utf8
        
        Write-Host "Created minimal server files." -ForegroundColor Yellow
    }
}

# Install dependencies and build
Write-Host "Installing dependencies and building project..." -ForegroundColor Cyan
$npmCommand = if ($UseSystemNode) { "npm" } else { Join-Path $NodeDir "npm.cmd" }
$nodeCommand = if ($UseSystemNode) { "node" } else { Join-Path $NodeDir "node.exe" }

# Check for package.json to determine if we have a full repo
$hasPackageJson = Test-Path (Join-Path $RepoDir "package.json")
if ($hasPackageJson) {
    try {
        Set-Location $RepoDir
        # Install dependencies
        & $npmCommand install
        # Build project
        & $npmCommand run build
        Write-Host "Dependencies installed and project built successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error installing dependencies or building project: $_" -ForegroundColor Red
        Write-Host "Will use fallback server instead..." -ForegroundColor Yellow
    }
} else {
    Write-Host "Incomplete repository download. Using minimal server." -ForegroundColor Yellow
    
    # Install minimum required packages
    try {
        Set-Location $RepoDir
        # Create minimal package.json
        $PackageJsonContent = @"
{
  "name": "claude-computer-commander-unlocked-minimal",
  "version": "1.0.0",
  "description": "Minimal fallback for ClaudeComputerCommander-Unlocked",
  "main": "dist/index.js",
  "dependencies": {
    "@modelcontextprotocol/sdk": "^0.4.0"
  }
}
"@
        $PackageJsonContent | Out-File -FilePath (Join-Path $RepoDir "package.json") -Encoding utf8
        
        # Install minimum dependencies
        & $npmCommand install --no-optional
        Write-Host "Installed minimum required dependencies." -ForegroundColor Yellow
    } catch {
        Write-Host "Error installing minimum dependencies: $_" -ForegroundColor Red
    }
}

# Create a startup script
if ($UseSystemNode) {
    @"
@echo off
node "$($RepoDir.Replace('\','\\'))\dist\index.js"
"@ | Out-File -FilePath (Join-Path $RepoDir "start-commander.bat") -Encoding ascii
} else {
    $NodeDir = Join-Path $RepoDir "node"
    @"
@echo off
"$($NodeDir.Replace('\','\\'))\node.exe" "$($RepoDir.Replace('\','\\'))\dist\index.js"
"@ | Out-File -FilePath (Join-Path $RepoDir "start-commander.bat") -Encoding ascii
}

# Create Claude Desktop configuration with hardcoded format to prevent issues
Write-Host "Creating Claude Desktop configuration..." -ForegroundColor Cyan

# Prepare the installation path with proper escaping for JSON
$EscapedRepoDir = $RepoDir.Replace('\', '\\')
$NodePath = if ($UseSystemNode) { "node" } else { "$($NodeDir.Replace('\', '\\'))\\node.exe" }

# Create JSON content as plain string
$jsonText = @"
{
  "mcpServers": {
    "desktopCommander": {
      "command": "$NodePath",
      "args": [
        "$EscapedRepoDir\\dist\\index.js"
      ]
    }
  }
}
"@

# Write to file using .NET directly to avoid PowerShell encoding issues
try {
    [System.IO.File]::WriteAllText($ClaudeConfig, $jsonText, [System.Text.Encoding]::UTF8)
    Write-Host "Successfully created configuration file." -ForegroundColor Green
} catch {
    Write-Host "Error writing configuration file: $_" -ForegroundColor Red
    
    # Fallback method
    try {
        $jsonText | Out-File -FilePath $ClaudeConfig -Encoding utf8 -NoNewline
        Write-Host "Used PowerShell Out-File as fallback method." -ForegroundColor Yellow
    } catch {
        Write-Host "All file writing methods failed. Cannot create configuration file." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Installation completed successfully!" -ForegroundColor Green
Write-Host ""
if ($UseSystemNode) {
    Write-Host "Using system-wide Node.js installation." -ForegroundColor Green
} else {
    Write-Host "Using portable Node.js just for Claude Commander." -ForegroundColor Yellow
    Write-Host "For a system-wide installation, re-run this script as Administrator." -ForegroundColor Yellow
}
Write-Host ""
Write-Host "The ClaudeComputerCommander-Unlocked has been installed to:"
Write-Host $RepoDir -ForegroundColor Cyan
Write-Host ""
Write-Host "Claude Desktop has been configured to use this installation at:"
Write-Host $ClaudeConfig -ForegroundColor Cyan
Write-Host ""

if ($BackupCreated) {
    Write-Host "A backup of your previous configuration was created at:"
    Write-Host $BackupFile -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "Please restart Claude Desktop to apply the changes."
Write-Host "If Claude is already running, close it and start it again."
Write-Host ""
Write-Host "You can now ask Claude to:"
Write-Host "- Execute terminal commands"
Write-Host "- Edit files"
Write-Host "- Manage files"
Write-Host "- List processes"
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")