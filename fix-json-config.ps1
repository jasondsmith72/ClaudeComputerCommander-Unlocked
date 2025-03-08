# Fix Claude Desktop JSON Configuration
# This script only fixes the claude_desktop_config.json file

Write-Host "Claude Desktop JSON Configuration Fix" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "This will create a valid JSON configuration file for Claude Desktop."
Write-Host ""

# Find the Claude config file
$ClaudeConfigDir = Join-Path $env:APPDATA "Claude"
$ClaudeConfigPath = Join-Path $ClaudeConfigDir "claude_desktop_config.json"
Write-Host "Using configuration at: $ClaudeConfigPath"

# Get the ClaudeComputerCommander path
$RepoDir = Join-Path $env:USERPROFILE "ClaudeComputerCommander-Unlocked"
if (-not (Test-Path $RepoDir)) {
    Write-Host "Warning: ClaudeComputerCommander directory not found at expected path." -ForegroundColor Yellow
    $RepoDir = Read-Host "Please enter the full path to your ClaudeComputerCommander-Unlocked installation"
}

# Create a backup of the existing config with date/time stamp
$BackupCreated = $false
if (Test-Path $ClaudeConfigPath) {
    $CurrentDate = Get-Date -Format "yyyy-MM-dd-HH.mm"
    $BackupPath = Join-Path $ClaudeConfigDir "claude_desktop_config-backup-$CurrentDate.json"
    try {
        Copy-Item -Path $ClaudeConfigPath -Destination $BackupPath -Force
        Write-Host "Created backup of current configuration at: $BackupPath" -ForegroundColor Green
        $BackupCreated = $true
    }
    catch {
        Write-Host "Warning: Failed to create backup file. Will proceed anyway." -ForegroundColor Yellow
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

# Prepare the path to the index.js file with proper escaping
$IndexPath = Join-Path $RepoDir "dist\index.js"
$IndexPath = $IndexPath.Replace('\', '\\')

# Create the configuration JSON with exact structure
$correctJson = @"
{
  "mcpServers": {
    "desktopCommander": {
      "command": "node",
      "args": [
        "$IndexPath"
      ]
    }
  }
}
"@

# Write the configuration file using System.IO.File to ensure proper encoding without BOM
try {
    # If the directory doesn't exist, create it
    if (-not (Test-Path $ClaudeConfigDir)) {
        New-Item -ItemType Directory -Path $ClaudeConfigDir -Force | Out-Null
        Write-Host "Created Claude Desktop configuration directory." -ForegroundColor Green
    }
    
    # Write the file with UTF-8 encoding without BOM
    [System.IO.File]::WriteAllText($ClaudeConfigPath, $correctJson, [System.Text.Encoding]::UTF8)
    Write-Host "Configuration file created successfully." -ForegroundColor Green
    
    # Validate the JSON
    try {
        $testJson = Get-Content -Path $ClaudeConfigPath -Raw | ConvertFrom-Json
        Write-Host "JSON validation successful!" -ForegroundColor Green
    } catch {
        Write-Host "Warning: JSON validation failed. Creating minimal configuration..." -ForegroundColor Yellow
        Write-Host "Error: $_" -ForegroundColor Red
        
        # Create an ultra-minimal configuration as a fallback
        [System.IO.File]::WriteAllText($ClaudeConfigPath, '{"mcpServers":{}}', [System.Text.Encoding]::UTF8)
        Write-Host "Created minimal fallback configuration." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error writing configuration file: $_" -ForegroundColor Red
    Write-Host "Attempting to create minimal configuration..." -ForegroundColor Yellow
    
    try {
        [System.IO.File]::WriteAllText($ClaudeConfigPath, '{"mcpServers":{}}', [System.Text.Encoding]::UTF8)
        Write-Host "Created minimal fallback configuration." -ForegroundColor Yellow
    } catch {
        Write-Host "Critical error: Could not write configuration file." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "JSON configuration fix complete." -ForegroundColor Green
Write-Host "Path: $ClaudeConfigPath" -ForegroundColor Cyan
Write-Host ""

if ($BackupCreated) {
    Write-Host "A backup of your previous configuration was created at:"
    Write-Host $BackupPath -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "Please restart Claude Desktop for changes to take effect."
Write-Host "If Claude is already running, close it and start it again."
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")