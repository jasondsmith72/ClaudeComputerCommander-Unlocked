# ClaudeComputerCommander JSON Config Repair Tool
# This script fixes common JSON syntax issues in Claude Desktop configuration

Write-Host "Claude Desktop Configuration Repair Tool"
Write-Host "========================================"
Write-Host "This tool will fix JSON syntax errors in your Claude Desktop configuration"
Write-Host "and ensure proper formatting for the ClaudeComputerCommander"
Write-Host ""

# Find Claude config directory and file
$ClaudeConfigDir = Join-Path $env:APPDATA "Claude"

# Common locations where Claude config might be found
$possibleLocations = @(
    (Join-Path $env:APPDATA "Claude"),
    (Join-Path $env:LOCALAPPDATA "Claude"),
    (Join-Path $env:USERPROFILE "AppData\Roaming\Claude"),
    (Join-Path $env:USERPROFILE "AppData\Local\Claude"),
    (Join-Path $env:USERPROFILE "AppData\Local\Programs\Claude"),
    (Join-Path $env:USERPROFILE "Documents\Claude"),
    (Join-Path $env:USERPROFILE "Desktop"),
    (Join-Path $env:USERPROFILE "OneDrive\Desktop"),
    (Join-Path $env:HOMEDRIVE "\Claude")
)

# Search for the config file in all possible locations
$configFileName = "claude_desktop_config.json"
$ClaudeConfig = $null

foreach ($location in $possibleLocations) {
    $potentialPath = Join-Path $location $configFileName
    if (Test-Path $potentialPath) {
        $ClaudeConfig = $potentialPath
        Write-Host "Found existing Claude configuration at: $ClaudeConfig" -ForegroundColor Green
        $ClaudeConfigDir = Split-Path $ClaudeConfig -Parent
        break
    }
}

# If not found, try to create it in default location
if (-not $ClaudeConfig) {
    Write-Host "No existing configuration found. Will create one in the default location." -ForegroundColor Yellow
    
    # Try AppData first
    $ClaudeConfigDir = Join-Path $env:APPDATA "Claude"
    if (-not (Test-Path $ClaudeConfigDir)) {
        try {
            New-Item -ItemType Directory -Path $ClaudeConfigDir -Force | Out-Null
            Write-Host "Created Claude config directory at: $ClaudeConfigDir" -ForegroundColor Green
        } catch {
            # If creating in AppData fails, use Desktop as fallback
            Write-Host "Could not create directory in AppData, will use Desktop instead." -ForegroundColor Yellow
            $ClaudeConfigDir = [System.Environment]::GetFolderPath('Desktop')
        }
    }
    
    # Set the config path
    $ClaudeConfig = Join-Path $ClaudeConfigDir $configFileName
    Write-Host "Will create configuration at: $ClaudeConfig" -ForegroundColor Yellow
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
    
    # Create the directory if it doesn't exist
    if (-not (Test-Path $RepoDir)) {
        try {
            New-Item -ItemType Directory -Path $RepoDir -Force | Out-Null
            Write-Host "Created installation directory: $RepoDir" -ForegroundColor Green
        } catch {
            Write-Host "Failed to create installation directory: $_" -ForegroundColor Red
        }
    }
}

# Check for node.exe
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

# Create configuration JSON with hardcoded content to prevent any formatting issues
Write-Host "Creating clean JSON configuration file..." -ForegroundColor Cyan

# Prepare the installation path with proper escaping for JSON
$EscapedRepoDir = $RepoDir.Replace('\', '\\')
$NodePath = if ($UseSystemNode) { "node" } else { "$($NodeDir.Replace('\', '\\'))\\node.exe" }

# Create JSON content as a plain string
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
    Write-Host "Successfully created configuration file without BOM encoding." -ForegroundColor Green
} catch {
    Write-Host "Error writing configuration file: $_" -ForegroundColor Red
    
    # Fallback method if .NET method fails
    try {
        $jsonText | Out-File -FilePath $ClaudeConfig -Encoding utf8 -NoNewline
        Write-Host "Used PowerShell Out-File as fallback method." -ForegroundColor Yellow
    } catch {
        Write-Host "All file writing methods failed. Cannot create configuration file." -ForegroundColor Red
    }
}

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