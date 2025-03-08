# ClaudeComputerCommander Configuration Guide
# This script generates instructions for configuring Claude Desktop

Write-Host "Claude Desktop Configuration Guide"
Write-Host "========================================"
Write-Host "This tool will help you configure Claude Desktop to use ClaudeComputerCommander"
Write-Host ""

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
    Write-Host "Could not find ClaudeComputerCommander installation!" -ForegroundColor Red
    Write-Host "Please run the installer first." -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
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
        Write-Host "No Node.js installation found. Will use 'node' command anyway." -ForegroundColor Yellow
    }
}

# Prepare path information for manual configuration
$ConfigPath = $RepoDir
if ($UseSystemNode) {
    $NodePath = "node"
} else {
    $NodePath = Join-Path $NodeDir "node.exe"
}
$IndexPath = Join-Path $RepoDir "dist\index.js"

# Display configuration instructions
Write-Host ""
Write-Host "*** IMPORTANT: YOU MUST MANUALLY CONFIGURE CLAUDE DESKTOP ***" -ForegroundColor Magenta
Write-Host ""
Write-Host "Please follow these steps:" -ForegroundColor Yellow
Write-Host "1. Open Claude Desktop" -ForegroundColor Yellow
Write-Host "2. Click Settings (gear icon) in the bottom left" -ForegroundColor Yellow
Write-Host "3. Go to the Developer tab" -ForegroundColor Yellow
Write-Host "4. Click Edit next to MCP Servers" -ForegroundColor Yellow
Write-Host "5. Paste the following configuration:" -ForegroundColor Yellow
Write-Host ""

$configJson = @"
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
"@

Write-Host $configJson -ForegroundColor Cyan
Write-Host ""
Write-Host "6. Click Save" -ForegroundColor Yellow
Write-Host "7. Restart Claude Desktop" -ForegroundColor Yellow
Write-Host ""

# Create configuration readme
$readmeText = @"
# ClaudeComputerCommander-Unlocked Configuration Instructions

## Configuration Steps

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
- Node.js Path: $($NodePath)
- Index.js Path: $IndexPath

## Using the Commander

After configuration, you can ask Claude to:
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
Write-Host "Detailed instructions have been saved to:" -ForegroundColor Green 
Write-Host "$(Join-Path $RepoDir "CONFIGURATION.md")" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")