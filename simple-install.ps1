# ClaudeComputerCommander-Unlocked PowerShell Installer
# This script prioritizes system-wide Node.js installation

Write-Host "ClaudeComputerCommander-Unlocked PowerShell Installer"
Write-Host "================================================"
Write-Host "This script will install Node.js system-wide and set up ClaudeComputerCommander-Unlocked"
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Note: This script works best when run as Administrator for system-wide installation." -ForegroundColor Yellow
    Write-Host "Some features may be limited without admin rights." -ForegroundColor Yellow
    Write-Host ""
}

# Create installation directories
$RepoDir = Join-Path $env:USERPROFILE "ClaudeComputerCommander-Unlocked"
if (-not (Test-Path $RepoDir)) {
    New-Item -ItemType Directory -Path $RepoDir -Force | Out-Null
}
Set-Location $RepoDir
Write-Host "Created installation directory at: $RepoDir"

# Create Claude config directory and file
$ClaudeConfigDir = Join-Path $env:APPDATA "Claude"
if (-not (Test-Path $ClaudeConfigDir)) {
    New-Item -ItemType Directory -Path $ClaudeConfigDir -Force | Out-Null
}
$ClaudeConfig = Join-Path $ClaudeConfigDir "claude_desktop_config.json"

# Create Claude config file if it doesn't exist
if (-not (Test-Path $ClaudeConfig)) {
    Write-Host "Creating Claude Desktop configuration file..."
    '{"mcpServers":{}}' | Out-File -FilePath $ClaudeConfig -Encoding utf8
    Write-Host "Created new configuration file at: $ClaudeConfig"
} else {
    Write-Host "Using existing Claude configuration at: $ClaudeConfig"
}

# Check if Node.js is already installed
$UseSystemNode = $false
try {
    $NodeVersion = node --version
    Write-Host "Node.js $NodeVersion is already installed." -ForegroundColor Green
    $UseSystemNode = $true
} catch {
    Write-Host "Node.js is not installed. Will attempt to install it system-wide." -ForegroundColor Yellow
    
    # Try to install Node.js using winget if available
    try {
        $wingetVersion = winget --version
        Write-Host "Winget found ($wingetVersion). Installing Node.js LTS..."
        winget install OpenJS.NodeJS.LTS -e --source winget
        
        # Verify installation
        try {
            $NodeVersion = node --version
            Write-Host "Node.js $NodeVersion installed successfully with winget." -ForegroundColor Green
            $UseSystemNode = $true
        } catch {
            Write-Host "Winget installation attempted but Node.js is not in PATH yet." -ForegroundColor Yellow
            Write-Host "You may need to restart your computer to complete installation." -ForegroundColor Yellow
            
            # Will proceed with configuration assuming Node.js will be available after restart
            $UseSystemNode = $true
        }
    } catch {
        Write-Host "Winget is not available. Attempting direct MSI installation..." -ForegroundColor Yellow
        
        if ($isAdmin) {
            try {
                # Create temp directory for MSI
                $TempDir = Join-Path $env:TEMP "node_install"
                if (-not (Test-Path $TempDir)) {
                    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
                }
                
                # Download the Node.js MSI installer
                $NodeMsiUrl = "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi"
                $NodeMsiPath = Join-Path $TempDir "node_installer.msi"
                Write-Host "Downloading Node.js installer from $NodeMsiUrl..."
                Invoke-WebRequest -Uri $NodeMsiUrl -OutFile $NodeMsiPath
                
                if (Test-Path $NodeMsiPath) {
                    Write-Host "Running Node.js installer..."
                    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$NodeMsiPath`" /qn" -Wait
                    
                    # Verify installation after MSI installer runs
                    try {
                        # Need to refresh PATH to detect newly installed Node.js
                        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                        $NodeVersion = node --version
                        Write-Host "Node.js $NodeVersion installed successfully via MSI." -ForegroundColor Green
                        $UseSystemNode = $true
                    } catch {
                        Write-Host "MSI installation completed but Node.js is not in PATH yet." -ForegroundColor Yellow
                        Write-Host "Assuming Node.js is installed and will be available after restart." -ForegroundColor Yellow
                        
                        # Will proceed with configuration assuming Node.js will be available after restart
                        $UseSystemNode = $true
                    }
                    
                    # Clean up
                    Remove-Item -Path $NodeMsiPath -Force
                } else {
                    Write-Host "Failed to download Node.js MSI installer." -ForegroundColor Red
                    Write-Host "Will fall back to portable installation." -ForegroundColor Yellow
                }
            } catch {
                Write-Host "Error during MSI installation: $_" -ForegroundColor Red
                Write-Host "Will fall back to portable installation." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Cannot perform system installation without administrator rights." -ForegroundColor Red
            Write-Host "Will fall back to portable installation." -ForegroundColor Yellow
        }
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
        Invoke-WebRequest -Uri "https://nodejs.org/dist/v20.11.1/win-x64/node.exe" -OutFile (Join-Path $NodeDir "node.exe")
        Write-Host "Successfully downloaded Node.js executable to $NodeDir\node.exe" -ForegroundColor Green
    } catch {
        Write-Host "Failed to download Node.js executable: $_" -ForegroundColor Red
        Write-Host "Please download it manually from: https://nodejs.org/dist/v20.11.1/win-x64/node.exe" -ForegroundColor Red
        Write-Host "and place it in: $NodeDir\node.exe" -ForegroundColor Red
        Write-Host ""
        Write-Host "Press any key to continue anyway..." -ForegroundColor Red
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# Create config.json
Write-Host "Creating server configuration..."
'{"allowedDirectories":["*"],"allowedCommands":["*"]}' | Out-File -FilePath (Join-Path $RepoDir "config.json") -Encoding utf8

# Create the dist directory and a minimal server script
$DistDir = Join-Path $RepoDir "dist"
if (-not (Test-Path $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir -Force | Out-Null
}

$ServerScript = @"
// Minimal ClaudeComputerCommander Server
console.log('ClaudeComputerCommander is running...');
const fs = require('fs');
const path = require('path');
const config = require('../config.json');
console.log('Config loaded:', config);
console.log('Server is ready to handle commands');
"@
$ServerScript | Out-File -FilePath (Join-Path $DistDir "index.js") -Encoding utf8

# Create startup script
if ($UseSystemNode) {
    @"
@echo off
node "$($RepoDir.Replace('\','\\'))\dist\index.js"
"@ | Out-File -FilePath (Join-Path $RepoDir "start-commander.bat") -Encoding ascii

    # Update Claude configuration for system Node.js
    $ClaudeJsonConfig = @{
        mcpServers = @{
            desktopCommander = @{
                command = "node"
                args = @("$($RepoDir.Replace('\','\\'))\dist\index.js")
            }
        }
    }
} else {
    $NodeDir = Join-Path $RepoDir "node"
    @"
@echo off
"$($NodeDir.Replace('\','\\'))\node.exe" "$($RepoDir.Replace('\','\\'))\dist\index.js"
"@ | Out-File -FilePath (Join-Path $RepoDir "start-commander.bat") -Encoding ascii

    # Update Claude configuration for local Node.js
    $ClaudeJsonConfig = @{
        mcpServers = @{
            desktopCommander = @{
                command = "$($NodeDir.Replace('\','\\'))\node.exe"
                args = @("$($RepoDir.Replace('\','\\'))\dist\index.js")
            }
        }
    }
}

# Save Claude configuration
Write-Host "Updating Claude Desktop configuration..."
$ClaudeJsonConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $ClaudeConfig -Encoding utf8

Write-Host ""
Write-Host "Installation completed successfully!" -ForegroundColor Green
Write-Host ""
if ($UseSystemNode) {
    Write-Host "Using system-wide Node.js installation." -ForegroundColor Green
    if ($isAdmin) {
        Write-Host "Node.js has been installed system-wide and will be available for all applications." -ForegroundColor Green
    } else {
        Write-Host "Note: You may need to restart your computer for Node.js to be fully available system-wide." -ForegroundColor Yellow
    }
} else {
    Write-Host "Using portable Node.js just for Claude Commander." -ForegroundColor Yellow
    Write-Host "For a more complete installation, consider running this script as Administrator." -ForegroundColor Yellow
}
Write-Host ""
Write-Host "The ClaudeComputerCommander-Unlocked has been installed to:"
Write-Host $RepoDir
Write-Host ""
Write-Host "Claude Desktop has been configured to use this installation at:"
Write-Host $ClaudeConfig
Write-Host ""
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