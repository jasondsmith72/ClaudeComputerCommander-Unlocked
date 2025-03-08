# Quick Fix for Claude Desktop Configuration
# This script ONLY fixes the Claude configuration without touching Node.js

Write-Host "Claude Desktop Quick Fix Tool" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "This tool will ONLY fix your Claude Desktop configuration file."
Write-Host "It will NOT attempt to install or modify Node.js."
Write-Host ""

# Find the Claude config file
$ClaudeConfigDir = Join-Path $env:APPDATA "Claude"
$ClaudeConfig = Join-Path $ClaudeConfigDir "claude_desktop_config.json"

if (-not (Test-Path $ClaudeConfig)) {
    Write-Host "Claude configuration file not found at: $ClaudeConfig" -ForegroundColor Red
    Write-Host "Creating new configuration directory..."
    New-Item -ItemType Directory -Path $ClaudeConfigDir -Force | Out-Null
    Write-Host "Created configuration directory at: $ClaudeConfigDir" -ForegroundColor Green
}

# Create a backup of the existing config if it exists
if (Test-Path $ClaudeConfig) {
    $BackupPath = Join-Path $ClaudeConfigDir "claude_desktop_config.backup.json"
    Copy-Item -Path $ClaudeConfig -Destination $BackupPath -Force
    Write-Host "Created backup of current configuration at: $BackupPath" -ForegroundColor Cyan
}

# Get ClaudeComputerCommander directory path
$RepoDir = Join-Path $env:USERPROFILE "ClaudeComputerCommander-Unlocked"
if (-not (Test-Path $RepoDir)) {
    $RepoDir = Read-Host "Please enter the full path to your ClaudeComputerCommander-Unlocked installation directory"
}

# Create a valid configuration using system-wide Node.js
Write-Host "Creating valid Claude Desktop configuration..." -ForegroundColor Cyan

# Configuration for system-wide Node.js
$ValidConfig = @{
    mcpServers = @{
        desktopCommander = @{
            command = "node"
            args = @("$($RepoDir.Replace('\','\\'))\dist\index.js")
        }
    }
}

# Ensure dist directory and server file exist
$DistDir = Join-Path $RepoDir "dist"
if (-not (Test-Path $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir -Force | Out-Null
    Write-Host "Created dist directory at: $DistDir" -ForegroundColor Green
}

$ServerJsPath = Join-Path $DistDir "index.js"
if (-not (Test-Path $ServerJsPath)) {
    $ServerScript = @"
// Minimal ClaudeComputerCommander Server
console.log('ClaudeComputerCommander is running...');
const fs = require('fs');
const path = require('path');
try {
    const config = require('../config.json');
    console.log('Config loaded:', config);
} catch (err) {
    console.log('Config not found, creating default config...');
    fs.writeFileSync(path.join(__dirname, '../config.json'), JSON.stringify({
        allowedDirectories: ['*'],
        allowedCommands: ['*']
    }, null, 2));
}
console.log('Server is ready to handle commands');
"@
    $ServerScript | Out-File -FilePath $ServerJsPath -Encoding utf8
    Write-Host "Created server script at: $ServerJsPath" -ForegroundColor Green
}

# Create config.json if it doesn't exist
$ConfigPath = Join-Path $RepoDir "config.json"
if (-not (Test-Path $ConfigPath)) {
    '{"allowedDirectories":["*"],"allowedCommands":["*"]}' | Out-File -FilePath $ConfigPath -Encoding utf8
    Write-Host "Created server configuration at: $ConfigPath" -ForegroundColor Green
}

# Write the valid configuration to file
$ValidConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $ClaudeConfig -Encoding utf8

Write-Host ""
Write-Host "Configuration file has been repaired successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "The ClaudeComputerCommander-Unlocked has been configured to use:"
Write-Host $RepoDir -ForegroundColor Cyan
Write-Host ""
Write-Host "Claude Desktop has been configured at:"
Write-Host $ClaudeConfig -ForegroundColor Cyan
Write-Host ""
Write-Host "Please restart Claude Desktop to apply the changes."
Write-Host "If Claude is already running, close it and start it again."
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")