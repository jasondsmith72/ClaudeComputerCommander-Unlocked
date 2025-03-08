# ClaudeComputerCommander JSON Config Repair Tool
# This script fixes common JSON syntax issues in Claude Desktop configuration

Write-Host "Claude Desktop Configuration Repair Tool"
Write-Host "========================================"
Write-Host "This tool will fix JSON syntax errors in your Claude Desktop configuration"
Write-Host "and ensure proper formatting for the ClaudeComputerCommander"
Write-Host ""

# Find Claude config directory and file
$ClaudeConfigDir = Join-Path $env:APPDATA "Claude"
if (-not (Test-Path $ClaudeConfigDir)) {
    $potentialPaths = @(
        (Join-Path $env:APPDATA "Claude"),
        (Join-Path $env:LOCALAPPDATA "Claude"),
        (Join-Path $env:USERPROFILE "AppData\Roaming\Claude"),
        (Join-Path $env:USERPROFILE "AppData\Local\Claude"),
        (Join-Path $env:USERPROFILE "AppData\Local\Programs\Claude"),
        (Join-Path $env:USERPROFILE "Documents\Claude"),
        (Join-Path $env:ONEDRIVE "Desktop"),
        (Join-Path $env:USERPROFILE "Desktop"),
        (Join-Path $env:HOMEDRIVE "\Claude")
    )
    
    foreach ($path in $potentialPaths) {
        if (Test-Path $path) {
            $ClaudeConfigDir = $path
            Write-Host "Found Claude directory at: $ClaudeConfigDir" -ForegroundColor Green
            break
        }
    }
    
    if (-not (Test-Path $ClaudeConfigDir)) {
        Write-Host "Creating Claude config directory at: $ClaudeConfigDir" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $ClaudeConfigDir -Force | Out-Null
    }
}

# Search for config file in common locations
$configFileName = "claude_desktop_config.json"
$potentialConfigFiles = @(
    (Join-Path $ClaudeConfigDir $configFileName),
    (Join-Path $env:USERPROFILE "Desktop\$configFileName"),
    (Join-Path $env:ONEDRIVE "Desktop\$configFileName")
)

$ClaudeConfig = $null
foreach ($configPath in $potentialConfigFiles) {
    if (Test-Path $configPath) {
        $ClaudeConfig = $configPath
        Write-Host "Found existing configuration at: $ClaudeConfig" -ForegroundColor Green
        break
    }
}

if (-not $ClaudeConfig) {
    # Default to APPDATA location if config not found
    $ClaudeConfig = Join-Path $ClaudeConfigDir $configFileName
    Write-Host "Will create new configuration at: $ClaudeConfig" -ForegroundColor Yellow
}

# Create a backup with date/time stamp
$BackupCreated = $false
if (Test-Path $ClaudeConfig) {
    $Timestamp = Get-Date -Format "yyyy-MM-dd-HH.mm"
    $BackupFile = [System.IO.Path]::ChangeExtension($ClaudeConfig, "bk-$Timestamp.json")
    try {
        Copy-Item -Path $ClaudeConfig -Destination $BackupFile -Force
        Write-Host "Created backup of existing config at: $BackupFile" -ForegroundColor Green
        $BackupCreated = $true
    } catch {
        Write-Host "Failed to create backup: $_" -ForegroundColor Red
    }
}

# Find installation directory of ClaudeComputerCommander
$potentialInstallPaths = @(
    (Join-Path $env:USERPROFILE "ClaudeComputerCommander-Unlocked"),
    (Join-Path $env:USERPROFILE "ClaudeComputerCommander"),
    (Join-Path $env:HOMEDRIVE "ClaudeComputerCommander-Unlocked"),
    (Join-Path $env:HOMEDRIVE "ClaudeComputerCommander"),
    (Join-Path (Get-Location) "ClaudeComputerCommander-Unlocked"),
    (Join-Path (Get-Location) "ClaudeComputerCommander")
)

$RepoDir = $null
foreach ($path in $potentialInstallPaths) {
    if (Test-Path $path) {
        $RepoDir = $path
        Write-Host "Found ClaudeComputerCommander installation at: $RepoDir" -ForegroundColor Green
        break
    }
}

if (-not $RepoDir) {
    $RepoDir = Join-Path $env:USERPROFILE "ClaudeComputerCommander-Unlocked"
    Write-Host "Using default installation path: $RepoDir" -ForegroundColor Yellow
}

# Get Node.js location
$UseSystemNode = $true
$NodeDir = $null
try {
    $NodeVersion = & node --version
    Write-Host "Node.js $NodeVersion is installed on system." -ForegroundColor Green
} catch {
    Write-Host "System Node.js not detected, checking for portable version..." -ForegroundColor Yellow
    $NodePath = Join-Path $RepoDir "node\node.exe"
    if (Test-Path $NodePath) {
        $UseSystemNode = $false
        $NodeDir = Join-Path $RepoDir "node"
        Write-Host "Found portable Node.js at: $NodePath" -ForegroundColor Green
    } else {
        Write-Host "No Node.js installation found. Will configure for system Node.js anyway." -ForegroundColor Yellow
    }
}

# Create Claude Desktop configuration using proper PowerShell approach
Write-Host "Creating Claude Desktop configuration with proper JSON formatting..." -ForegroundColor Cyan

# Define the correct configuration object
if ($UseSystemNode) {
    $configObject = @{
        mcpServers = @{
            desktopCommander = @{
                command = "node"
                args = @(
                    "$RepoDir\dist\index.js"
                )
            }
        }
    }
} else {
    $configObject = @{
        mcpServers = @{
            desktopCommander = @{
                command = "$NodeDir\node.exe"
                args = @(
                    "$RepoDir\dist\index.js"
                )
            }
        }
    }
}

# Convert object to JSON and write to file
$jsonConfig = $configObject | ConvertTo-Json -Depth 10
$jsonConfig | Out-File -FilePath $ClaudeConfig -Encoding utf8 -NoNewline

Write-Host ""
Write-Host "Configuration repair completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "The ClaudeComputerCommander is configured to use installation at:"
Write-Host $RepoDir -ForegroundColor Cyan
Write-Host ""
Write-Host "Claude Desktop will use configuration at:"
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
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")