# Fix Claude Desktop JSON Configuration
# This script only fixes the claude_desktop_config.json file

Write-Host "Claude Desktop JSON Configuration Fix" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "This will create a valid JSON configuration file for Claude Desktop."
Write-Host ""

# Find the Claude config file
$ClaudeConfigPath = Join-Path $env:APPDATA "Claude\claude_desktop_config.json"
Write-Host "Using configuration at: $ClaudeConfigPath"

# Get the ClaudeComputerCommander path
$RepoDir = Join-Path $env:USERPROFILE "ClaudeComputerCommander-Unlocked"
if (-not (Test-Path $RepoDir)) {
    Write-Host "Warning: ClaudeComputerCommander directory not found at expected path." -ForegroundColor Yellow
    $RepoDir = Read-Host "Please enter the full path to your ClaudeComputerCommander-Unlocked installation"
}

# Create a backup of the existing config
if (Test-Path $ClaudeConfigPath) {
    $BackupPath = $ClaudeConfigPath -replace ".json$", ".backup.json"
    Copy-Item -Path $ClaudeConfigPath -Destination $BackupPath -Force
    Write-Host "Created backup of current configuration at: $BackupPath" -ForegroundColor Green
}

# Create the configuration JSON with the exactly correct format
$correctJson = @"
{
  "mcpServers": {
    "desktopCommander": {
      "command": "node",
      "args": [
        "$($RepoDir.Replace('\', '\\'))\\dist\\index.js"
      ]
    }
  }
}
"@

# Write the configuration to file
$correctJson | Out-File -FilePath $ClaudeConfigPath -Encoding utf8 -NoNewline

Write-Host ""
Write-Host "Successfully created a valid JSON configuration." -ForegroundColor Green
Write-Host "Path: $ClaudeConfigPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Please restart Claude Desktop for changes to take effect."
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")