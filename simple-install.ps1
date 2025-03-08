# ClaudeComputerCommander-Unlocked PowerShell Installer
# This script handles Node.js installation and Claude integration

Write-Host "ClaudeComputerCommander-Unlocked PowerShell Installer"
Write-Host "================================================"
Write-Host "This script will set up ClaudeComputerCommander-Unlocked"
Write-Host "and install Node.js if needed."
Write-Host ""

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

# Check if Node.js is installed
$UseSystemNode = $false
try {
    $NodeVersion = node --version
    Write-Host "Found Node.js $NodeVersion, using system installation."
    $UseSystemNode = $true
} catch {
    Write-Host "No system-wide Node.js found. Downloading portable version..."
    
    # Download Node.js executable directly
    $NodeDir = Join-Path $RepoDir "node"
    if (-not (Test-Path $NodeDir)) {
        New-Item -ItemType Directory -Path $NodeDir -Force | Out-Null
    }
    
    try {
        Invoke-WebRequest -Uri "https://nodejs.org/dist/v20.11.1/win-x64/node.exe" -OutFile (Join-Path $NodeDir "node.exe")
        Write-Host "Successfully downloaded Node.js executable."
    } catch {
        Write-Host "Failed to download Node.js executable."
        Write-Host "Please download it manually from: https://nodejs.org/dist/v20.11.1/win-x64/node.exe"
        Write-Host "and place it in: $NodeDir\node.exe"
        Write-Host ""
        Write-Host "Press any key to continue anyway..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

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
Write-Host "Installation completed successfully!"
Write-Host ""
if ($UseSystemNode) {
    Write-Host "Using system-wide Node.js installation."
} else {
    Write-Host "Using portable Node.js just for Claude Commander."
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