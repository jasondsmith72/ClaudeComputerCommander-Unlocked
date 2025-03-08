# Emergency Fix for Claude Desktop Configuration
# This is the simplest possible fix with no dependencies

Write-Host "Claude Desktop Emergency Fix" -ForegroundColor Red
Write-Host "===========================" -ForegroundColor Red
Write-Host "This tool will fix the 'Unexpected token' error in claude_desktop_config.json"
Write-Host ""

# Find the Claude config directory and file
$ClaudeConfigDir = Join-Path $env:APPDATA "Claude"
$ClaudeConfigPath = Join-Path $ClaudeConfigDir "claude_desktop_config.json"

# Create the config directory if it doesn't exist
if (-not (Test-Path $ClaudeConfigDir)) {
    try {
        New-Item -ItemType Directory -Path $ClaudeConfigDir -Force | Out-Null
        Write-Host "Created Claude configuration directory at: $ClaudeConfigDir" -ForegroundColor Green
    } catch {
        Write-Host "Error creating Claude directory: $_" -ForegroundColor Red
        Write-Host "Please create the directory manually: $ClaudeConfigDir" -ForegroundColor Yellow
    }
}

# Create a backup with timestamp
$BackupCreated = $false
if (Test-Path $ClaudeConfigPath) {
    $CurrentDate = Get-Date -Format "yyyy-MM-dd-HH.mm.ss"
    $BackupPath = Join-Path $ClaudeConfigDir "claude_desktop_config-backup-$CurrentDate.json"
    try {
        Copy-Item -Path $ClaudeConfigPath -Destination $BackupPath -Force
        Write-Host "Created backup at: $BackupPath" -ForegroundColor Green
        $BackupCreated = $true
    } catch {
        Write-Host "Warning: Could not create backup: $_" -ForegroundColor Yellow
    }
}

# Create the minimal valid JSON configuration
try {
    # Use direct System.IO.File method to write UTF-8 without BOM
    [System.IO.File]::WriteAllText($ClaudeConfigPath, '{"mcpServers":{}}', [System.Text.Encoding]::UTF8)
    Write-Host "Successfully created minimal valid configuration!" -ForegroundColor Green
    
    # Verify the file exists and is readable
    if (Test-Path $ClaudeConfigPath) {
        $fileSize = (Get-Item $ClaudeConfigPath).Length
        Write-Host "Verification: File exists and is $fileSize bytes." -ForegroundColor Green
    } else {
        Write-Host "Warning: File was written but cannot be found." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error creating configuration file: $_" -ForegroundColor Red
    Write-Host "Manual intervention required. Please create the file at: $ClaudeConfigPath" -ForegroundColor Yellow
    Write-Host "with the following content: {`"mcpServers`":{}}" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Fix completed. Please restart Claude Desktop." -ForegroundColor Cyan
Write-Host ""
if ($BackupCreated) {
    Write-Host "A backup of your previous configuration was created at:"
    Write-Host $BackupPath -ForegroundColor Cyan
}
Write-Host ""
Write-Host "Note: This fix creates a minimal configuration with no Commander settings."
Write-Host "After Claude starts successfully, run the proper installation script again."
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")