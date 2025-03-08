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

# Create/clean installation directory
if (Test-Path $RepoDir) {
    Write-Host "Existing installation found. Creating backup..." -ForegroundColor Yellow
    try {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupDir = "${RepoDir}-backup-${timestamp}"
        Move-Item -Path $RepoDir -Destination $backupDir -ErrorAction Stop
        Write-Host "Backed up to: $backupDir" -ForegroundColor Green
    } catch {
        Write-Host "Could not backup existing installation. Will try to continue anyway..." -ForegroundColor Red
        # Try to clean the directory
        try {
            Get-ChildItem -Path $RepoDir -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "Could not clean directory. Installation may be incomplete." -ForegroundColor Red
        }
    }
}

# First check if Node.js is already installed
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
    # Create the installation directory if it doesn't exist
    if (-not (Test-Path $RepoDir)) {
        New-Item -ItemType Directory -Path $RepoDir -Force | Out-Null
        Write-Host "Created installation directory at: $RepoDir"
    }
    
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
    # Clone repository (note: we're not in the target directory yet)
    Write-Host "Cloning ClaudeComputerCommander-Unlocked repository..." -ForegroundColor Cyan
    try {
        # If the directory doesn't exist, create it first
        if (-not (Test-Path $RepoDir)) {
            New-Item -ItemType Directory -Path $RepoDir -Force | Out-Null
            Write-Host "Created installation directory at: $RepoDir"
        }
        
        # Clone into the directory 
        & git clone https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked.git $RepoDir
        Write-Host "Repository cloned successfully." -ForegroundColor Green
        
        # Now change to the repository directory
        Set-Location $RepoDir
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
        
        # Create target directory if it doesn't exist
        if (-not (Test-Path $RepoDir)) {
            New-Item -ItemType Directory -Path $RepoDir -Force | Out-Null
            Write-Host "Created installation directory at: $RepoDir"
        }
        
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
        
        # Now change to the repository directory
        Set-Location $RepoDir
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
        
        # Change to the repository directory
        Set-Location $RepoDir
    }
}

# Create a temporary package.json without the prepare script
$tempPackageJsonPath = Join-Path $RepoDir "package.json.temp"
if (Test-Path (Join-Path $RepoDir "package.json")) {
    $packageJsonContent = Get-Content -Path (Join-Path $RepoDir "package.json") -Raw
    # Remove the prepare script to avoid double building
    $packageJsonContent = $packageJsonContent -replace '"prepare": "npm run build",', ''
    $packageJsonContent | Out-File -FilePath $tempPackageJsonPath -Encoding utf8
    
    # Backup the original package.json
    Copy-Item -Path (Join-Path $RepoDir "package.json") -Destination (Join-Path $RepoDir "package.json.original") -Force
    
    # Replace with our modified version
    Copy-Item -Path $tempPackageJsonPath -Destination (Join-Path $RepoDir "package.json") -Force
    
    # Clean up temp file
    Remove-Item -Path $tempPackageJsonPath -Force -ErrorAction SilentlyContinue
}

# Install dependencies
Write-Host "Installing dependencies..." -ForegroundColor Cyan
$npmCommand = if ($UseSystemNode) { "npm" } else { Join-Path $NodeDir "npm.cmd" }
$nodeCommand = if ($UseSystemNode) { "node" } else { Join-Path $NodeDir "node.exe" }

# Check for package.json to determine if we have a full repo
$hasPackageJson = Test-Path (Join-Path $RepoDir "package.json")
if ($hasPackageJson) {
    try {
        # Install dependencies without the prepare script trigger
        & $npmCommand install
        
        # Now explicitly run the build once
        & $npmCommand run build
        
        # Restore the original package.json if it exists
        if (Test-Path (Join-Path $RepoDir "package.json.original")) {
            Copy-Item -Path (Join-Path $RepoDir "package.json.original") -Destination (Join-Path $RepoDir "package.json") -Force
            Remove-Item -Path (Join-Path $RepoDir "package.json.original") -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "Dependencies installed and project built successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error installing dependencies: $_" -ForegroundColor Red
        Write-Host "Will use fallback server instead..." -ForegroundColor Yellow
    }
} else {
    Write-Host "Incomplete repository download. Using minimal server." -ForegroundColor Yellow
    
    # Install minimum required packages
    try {
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

# Prepare path information for configuration
$ConfigPath = $RepoDir
if ($UseSystemNode) {
    $NodePath = "node"
} else {
    $NodePath = Join-Path $NodeDir "node.exe"
}
$IndexPath = Join-Path $RepoDir "dist\index.js"

# Set up Claude config directory and file
$ClaudeConfigDir = Join-Path $env:APPDATA "Claude"
if (-not (Test-Path $ClaudeConfigDir)) {
    New-Item -ItemType Directory -Path $ClaudeConfigDir -Force | Out-Null
    Write-Host "Created Claude config directory at: $ClaudeConfigDir" -ForegroundColor Green
}

$ClaudeConfigFile = Join-Path $ClaudeConfigDir "claude_desktop_config.json"

# Create a backup of the existing config file if it exists
$BackupCreated = $false
if (Test-Path $ClaudeConfigFile) {
    try {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupConfigFile = "$ClaudeConfigFile-backup-$timestamp"
        Copy-Item -Path $ClaudeConfigFile -Destination $backupConfigFile -Force
        Write-Host "Created backup of Claude config: $backupConfigFile" -ForegroundColor Green
        $BackupCreated = $true
    } catch {
        Write-Host "Could not create backup of Claude config: $_" -ForegroundColor Yellow
    }
}

# Create or update the Claude config file with properly formatted JSON
try {
    # Default configuration structure
    $DefaultConfig = @{
        "mcpServers" = @{
            "desktopCommander" = @{
                "command" = $NodePath
                "args" = @($IndexPath)
            }
        }
    }
    
    $ExistingConfig = $null
    if (Test-Path $ClaudeConfigFile) {
        try {
            # Try to read and parse existing config
            $ExistingConfigContent = Get-Content -Path $ClaudeConfigFile -Raw -ErrorAction SilentlyContinue
            $ExistingConfig = $ExistingConfigContent | ConvertFrom-Json -ErrorAction SilentlyContinue
        } catch {
            Write-Host "Existing Claude config file is invalid JSON. Will replace with correct format." -ForegroundColor Yellow
        }
    }
    
    if ($ExistingConfig -ne $null) {
        # Config exists and is valid JSON, update the mcpServers section
        if (-not (Get-Member -InputObject $ExistingConfig -Name "mcpServers" -MemberType Properties)) {
            # mcpServers section doesn't exist, add it
            Add-Member -InputObject $ExistingConfig -MemberType NoteProperty -Name "mcpServers" -Value @{}
        }
        
        # Update or add desktopCommander configuration
        if ($ExistingConfig.mcpServers -eq $null) {
            $ExistingConfig.mcpServers = @{}
        }
        
        $ExistingConfig.mcpServers | Add-Member -MemberType NoteProperty -Name "desktopCommander" -Value @{
            "command" = $NodePath
            "args" = @($IndexPath)
        } -Force
        
        # Convert back to JSON and save
        $UpdatedConfigJson = $ExistingConfig | ConvertTo-Json -Depth 10
        $UpdatedConfigJson | Out-File -FilePath $ClaudeConfigFile -Encoding utf8
    } else {
        # No valid existing config, write a new one
        $NewConfigJson = $DefaultConfig | ConvertTo-Json -Depth 10
        $NewConfigJson | Out-File -FilePath $ClaudeConfigFile -Encoding utf8
    }
    
    Write-Host "Successfully updated Claude configuration file at: $ClaudeConfigFile" -ForegroundColor Green
} catch {
    Write-Host "Error updating Claude configuration: $_" -ForegroundColor Red
    Write-Host "You will need to manually configure Claude to use the ClaudeComputerCommander." -ForegroundColor Yellow
}

# Create template file containing configuration instructions
$readmeText = @"
# ClaudeComputerCommander-Unlocked Configuration Instructions

The installation has completed successfully! 

## Configuration
Claude Desktop has been automatically configured to use ClaudeComputerCommander-Unlocked.
Configuration file: $ClaudeConfigFile

If for any reason automatic configuration failed, you can manually configure it by following these steps:

1. Open Claude Desktop application
2. Click on Settings (gear icon) in the bottom left
3. Go to the "Developer" tab
4. Click "Edit" next to "MCP Servers"
5. Paste the following configuration:

\`\`\`json
{
  "mcpServers": {
    "desktopCommander": {
      "command": "$($NodePath.Replace('\', '\\'))",
      "args": [
        "$($IndexPath.Replace('\', '\\'))"
      ]
    }
  }
}
\`\`\`

6. Click "Save"
7. Restart Claude Desktop

## Installation Details

- Installation Directory: $RepoDir
- Node.js Path: $NodePath
- Index.js Path: $IndexPath

## Using the Commander

You can now ask Claude to:
- Execute terminal commands
- Edit files
- Manage files
- List processes

## Troubleshooting

If you encounter any issues:
- Make sure paths in the configuration match your actual installation
- Verify that Claude Desktop has been restarted
- Check for any error messages in Claude Desktop

"@

$readmeText | Out-File -FilePath (Join-Path $RepoDir "CONFIGURATION.md") -Encoding utf8

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
Write-Host "Claude Desktop has been automatically configured at:"
Write-Host $ClaudeConfigFile -ForegroundColor Cyan
if ($BackupCreated) {
    Write-Host "A backup of your previous configuration was created before changes." -ForegroundColor Green
}
Write-Host ""
Write-Host "*** IMPORTANT: RESTART CLAUDE DESKTOP TO APPLY CHANGES ***" -ForegroundColor Magenta
Write-Host "If Claude Desktop is already running, please close and restart it." -ForegroundColor Yellow
Write-Host ""
Write-Host "You can now ask Claude to:" 
Write-Host "- Execute terminal commands"
Write-Host "- Edit files"
Write-Host "- Manage files"
Write-Host "- List processes"
Write-Host ""
Write-Host "If you encounter any issues, see detailed instructions in:" -ForegroundColor Green 
Write-Host "$(Join-Path $RepoDir "CONFIGURATION.md")" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")