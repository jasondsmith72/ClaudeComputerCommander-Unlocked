# Fix Claude Desktop Configuration File Script
# This script repairs the claude_desktop_config.json file

Write-Host "Claude Desktop Configuration Repair Tool"
Write-Host "========================================="
Write-Host "This script will repair your Claude Desktop configuration file."
Write-Host ""

# Find the Claude config file
$ClaudeConfigDir = Join-Path $env:APPDATA "Claude"
$ClaudeConfig = Join-Path $ClaudeConfigDir "claude_desktop_config.json"

if (-not (Test-Path $ClaudeConfig)) {
    Write-Host "Claude configuration file not found at: $ClaudeConfig" -ForegroundColor Red
    Write-Host "Please make sure Claude Desktop is installed correctly."
    exit 1
}

# Create a backup of the existing config
$BackupPath = Join-Path $ClaudeConfigDir "claude_desktop_config.backup.json"
Copy-Item -Path $ClaudeConfig -Destination $BackupPath -Force
Write-Host "Created backup of current configuration at: $BackupPath" -ForegroundColor Cyan

# Get ClaudeComputerCommander directory path
$RepoDir = Join-Path $env:USERPROFILE "ClaudeComputerCommander-Unlocked"
if (-not (Test-Path $RepoDir)) {
    $RepoDir = Read-Host "Please enter the full path to your ClaudeComputerCommander-Unlocked installation directory"
}

# Check for Node.js
$UseSystemNode = $false
try {
    $NodeVersion = node --version
    Write-Host "Found Node.js $NodeVersion installed system-wide. Will use it." -ForegroundColor Green
    $UseSystemNode = $true
} catch {
    $NodeDir = Join-Path $RepoDir "node"
    if (Test-Path (Join-Path $NodeDir "node.exe")) {
        Write-Host "Found portable Node.js installation. Will use it." -ForegroundColor Green
    } else {
        Write-Host "No Node.js installation found. Please run the installation script first." -ForegroundColor Red
        exit 1
    }
}

# Create a valid configuration
Write-Host "Creating valid Claude Desktop configuration..." -ForegroundColor Cyan

if ($UseSystemNode) {
    # Configuration for system-wide Node.js
    $ValidConfig = @{
        mcpServers = @{
            desktopCommander = @{
                command = "node"
                args = @("$($RepoDir.Replace('\','\\'))\dist\index.js")
            }
        }
    }
} else {
    # Configuration for portable Node.js
    $NodeDir = Join-Path $RepoDir "node"
    $ValidConfig = @{
        mcpServers = @{
            desktopCommander = @{
                command = "$($NodeDir.Replace('\','\\'))\node.exe"
                args = @("$($RepoDir.Replace('\','\\'))\dist\index.js")
            }
        }
    }
}

# Write the valid configuration to file
$ValidConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $ClaudeConfig -Encoding utf8

Write-Host "Configuration file has been repaired successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Please restart Claude Desktop to apply the changes."
Write-Host "If Claude is already running, close it and start it again."
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")