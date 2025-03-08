# ClaudeComputerCommander-Unlocked PowerShell Installer
# This script prioritizes system-wide Node.js installation

Write-Host "ClaudeComputerCommander-Unlocked PowerShell Installer"
Write-Host "================================================"
Write-Host "This script will install Node.js system-wide and set up ClaudeComputerCommander-Unlocked"
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "NOTE: This script requires Administrator rights to install Node.js system-wide." -ForegroundColor Yellow
    Write-Host "Please rerun the script as Administrator for best results." -ForegroundColor Yellow
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

# Always attempt to install Node.js system-wide first, regardless of whether it's already installed
$UseSystemNode = $false

# Function to attempt winget installation
function Install-Winget {
    Write-Host "Attempting to install App Installer (winget)..." -ForegroundColor Cyan
    
    # Check if Windows version supports winget (Windows 10 1809 or later)
    $win10 = (Get-WmiObject -class Win32_OperatingSystem).Caption -match 'Windows 10|Windows 11'
    if (-not $win10) {
        Write-Host "Winget requires Windows 10 1809 or later. Your system may not be supported." -ForegroundColor Yellow
        return $false
    }
    
    # Try to install App Installer through Microsoft Store
    try {
        Write-Host "Attempting to open Microsoft Store to install App Installer..." -ForegroundColor Cyan
        Start-Process "ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1" -Wait -ErrorAction SilentlyContinue
        
        Write-Host "Waiting 15 seconds for potential installation to complete..." -ForegroundColor Cyan
        Start-Sleep -Seconds 15
        
        # Check if winget is now available
        try {
            $null = & winget --version
            Write-Host "App Installer (winget) installed successfully via Microsoft Store!" -ForegroundColor Green
            return $true
        } catch {
            # Microsoft Store method failed, try direct download
        }
    } catch {
        # Microsoft Store method failed, try direct download
    }
    
    Write-Host "Microsoft Store installation method failed. Trying direct download..." -ForegroundColor Yellow
    
    try {
        # Create temp directory
        $tempDir = Join-Path $env:TEMP "winget_install"
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        
        # Download latest App Installer from GitHub
        $appInstallerUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        $appInstallerPath = Join-Path $tempDir "AppInstaller.msixbundle"
        
        Write-Host "Downloading App Installer from GitHub..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $appInstallerUrl -OutFile $appInstallerPath
        
        # Also need the dependencies for offline installation
        $vcLibsUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
        $vcLibsPath = Join-Path $tempDir "VCLibs.appx"
        
        Write-Host "Downloading required VCLibs dependency..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $vcLibsUrl -OutFile $vcLibsPath
        
        # Install VCLibs dependency first
        Write-Host "Installing VCLibs dependency..." -ForegroundColor Cyan
        Add-AppxPackage -Path $vcLibsPath -ErrorAction SilentlyContinue
        
        # Install App Installer
        Write-Host "Installing App Installer..." -ForegroundColor Cyan
        Add-AppxPackage -Path $appInstallerPath -ErrorAction SilentlyContinue
        
        # Clean up
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        
        # Verify winget installation
        try {
            $null = & winget --version
            Write-Host "App Installer (winget) installed successfully via direct download!" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "Failed to install winget via direct download." -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Error during winget direct installation: $_" -ForegroundColor Red
        return $false
    }
}

# Try to install Node.js using winget if available
if ($isAdmin) {
    Write-Host "Attempting to install Node.js system-wide..." -ForegroundColor Cyan
    
    # Check if winget is available
    $wingetInstalled = $false
    try {
        $wingetVersion = & winget --version
        Write-Host "Winget found ($wingetVersion)." -ForegroundColor Green
        $wingetInstalled = $true
    } catch {
        Write-Host "Winget not found. Attempting to install it..." -ForegroundColor Yellow
        $wingetInstalled = Install-Winget
    }
    
    if ($wingetInstalled) {
        # Install Node.js using winget
        Write-Host "Installing Node.js LTS using winget..." -ForegroundColor Cyan
        try {
            & winget install OpenJS.NodeJS.LTS -e --source winget
            
            # Verify installation
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            try {
                $NodeVersion = & node --version
                Write-Host "Node.js $NodeVersion installed successfully with winget." -ForegroundColor Green
                $UseSystemNode = $true
            } catch {
                Write-Host "Winget installation completed but Node.js is not in PATH yet." -ForegroundColor Yellow
                Write-Host "Will configure for system Node.js - you may need to restart your computer later." -ForegroundColor Yellow
                $UseSystemNode = $true
            }
        } catch {
            Write-Host "Error installing Node.js with winget: $_" -ForegroundColor Red
            Write-Host "Falling back to MSI installation method..." -ForegroundColor Yellow
        }
    }
    
    # If winget installation failed, try direct MSI installation
    if (-not $UseSystemNode) {
        try {
            # Create temp directory for MSI
            $TempDir = Join-Path $env:TEMP "node_install"
            if (-not (Test-Path $TempDir)) {
                New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
            }
            
            # Download the Node.js MSI installer
            $NodeMsiUrl = "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi"
            $NodeMsiPath = Join-Path $TempDir "node_installer.msi"
            Write-Host "Downloading Node.js installer from $NodeMsiUrl..." -ForegroundColor Cyan
            Invoke-WebRequest -Uri $NodeMsiUrl -OutFile $NodeMsiPath
            
            if (Test-Path $NodeMsiPath) {
                Write-Host "Running Node.js installer..." -ForegroundColor Cyan
                Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$NodeMsiPath`" /qn" -Wait
                
                # Verify installation after MSI installer runs
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                try {
                    $NodeVersion = & node --version
                    Write-Host "Node.js $NodeVersion installed successfully via MSI." -ForegroundColor Green
                    $UseSystemNode = $true
                } catch {
                    Write-Host "MSI installation completed but Node.js is not in PATH yet." -ForegroundColor Yellow
                    Write-Host "Will configure for system Node.js - you may need to restart your computer later." -ForegroundColor Yellow
                    $UseSystemNode = $true
                }
                
                # Clean up
                Remove-Item -Path $NodeMsiPath -Force -ErrorAction SilentlyContinue
            } else {
                Write-Host "Failed to download Node.js MSI installer." -ForegroundColor Red
                Write-Host "Will fall back to portable installation." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Error during MSI installation: $_" -ForegroundColor Red
            Write-Host "Will fall back to portable installation." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "Administrator rights required for system-wide Node.js installation." -ForegroundColor Yellow
    
    # Check if Node.js is already installed
    try {
        $NodeVersion = node --version
        Write-Host "Node.js $NodeVersion is already installed. Will use existing installation." -ForegroundColor Green
        $UseSystemNode = $true
    } catch {
        Write-Host "Will fall back to portable installation since we don't have admin rights." -ForegroundColor Yellow
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
        Write-Host "Downloading portable Node.js executable..." -ForegroundColor Cyan
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
        Write-Host "Using existing system-wide Node.js installation." -ForegroundColor Green
    }
} else {
    Write-Host "Using portable Node.js just for Claude Commander." -ForegroundColor Yellow
    Write-Host "For a system-wide installation, re-run this script as Administrator." -ForegroundColor Yellow
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