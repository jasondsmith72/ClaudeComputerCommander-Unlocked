# ClaudeComputerCommanderUnlocked

## 🔓 UNRESTRICTED FILE ACCESS

IMPORTANT UPDATE: This version of ClaudeComputerCommander has been modified to provide unrestricted access to all files and drives on your computer. Directory restrictions have been completely removed, allowing Claude to:

((Run as administraotr @ your own risk)) Open Claude desktop as administrator opens root access.

* Access any drive (C:, D:, etc.) and any folder on your system
* Read and write files in any location
* Execute commands that interact with any part of the filesystem
* Navigate and modify system files and folders

This provides maximum flexibility and eliminates permission errors, but please be aware that Claude will have access to all parts of your computer's filesystem. Use with appropriate caution.

Short version. Two key things. Terminal commands and diff based file editing.

This is a server that allows Claude desktop app to execute long-running terminal commands on your computer and manage processes through Model Context Protocol (MCP) + Built on top of MCP Filesystem Server to provide additional search and replace file editing capabilities.

This is a fork of wonderwhy-er/ClaudeComputerCommander with enhanced configuration options.

## Features

* Execute terminal commands with output streaming
* Command timeout and background execution support
* Process management (list and kill processes)
* Session management for long-running commands
* Full filesystem operations:

  + Read/write files
  + Create/list directories
  + Move files/directories
  + Search files
  + Get file metadata
  + Code editing capabilities:
  + Surgical text replacements for small changes
  + Full file rewrites for major changes
  + Multiple file support
  + Pattern-based replacements
* NEW: Full unrestricted filesystem access - Access any file or folder on your computer
* NEW: Command-based fallbacks - Even when direct file access fails, commands will be used as a fallback
* NEW: Improved path handling - Better support for Windows paths and relative directories
* NEW: Cross-platform support - Works on Windows, macOS, and Linux
* NEW: Winget support - Option 1 now uses winget to install Node.js if available

## Prerequisites

You'll need the following prerequisites, but don't worry - our installers will automatically install them if they're missing:

1. **Claude Desktop App** - Download and install from [Anthropic's website](https://claude.ai/downloads)
   - The installer will offer to help you download it if needed
   - Our installers will now create the config file even if Claude doesn't

2. **Node.js and npm** - Will be automatically installed
   - The installer now tries to use winget to install Node.js system-wide
   - Falls back to a portable version of Node.js if winget is not available
   - No manual installation required

3. **Git** - Optional, will be automatically installed if missing
   - If Git can't be installed, the scripts will download the repository as a ZIP file

## Installation

There are several ways to install ClaudeComputerCommander-Unlocked. All methods will:
- Download the necessary code
- Configure Claude Desktop to use the commander
- Create backups of your existing configuration

Choose the installation method that best suits your preferences:

### NEW: PowerShell Installation (RECOMMENDED)

The most reliable installation method using PowerShell:

#### For Command Prompt (CMD):
```cmd
curl -s https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/simple-install-ps.bat -o simple-install-ps.bat && simple-install-ps.bat
```

#### For PowerShell:
```powershell
# Run in PowerShell
iwr https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/simple-install.ps1 -OutFile simple-install.ps1; .\simple-install.ps1
```

This script:
1. Detects if Node.js is already installed on your system and uses it
2. Downloads and configures a portable Node.js if needed
3. Works reliably across different Windows versions and configurations
4. Handles all configuration automatically

### Option 1: Ultra-Simple Install

The absolute simplest installation method:

#### For Command Prompt (CMD):
```cmd
curl -s https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/simple-install.bat -o simple-install.bat && simple-install.bat
```

#### For PowerShell:
```powershell
# Run in PowerShell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/simple-install.bat" -OutFile "simple-install.bat"; ./simple-install.bat
```

#### PowerShell (Short Version):
```powershell
# Run in PowerShell
iwr https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/simple-install.bat -OutFile simple-install.bat; ./simple-install.bat
```

This batch file:
1. Tries to install Node.js system-wide using winget for better compatibility
2. Falls back to direct node.exe download if winget is not available
3. Creates a minimal, streamlined installation
4. Uses direct file copying rather than complex scripts
5. Works on virtually any Windows system
6. Perfect for troubleshooting when other methods fail

### Option 2: Quick Install

Standard installation with more features:

#### For Command Prompt (CMD):
```cmd
curl -s https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/direct-install.bat -o direct-install.bat && direct-install.bat
```

#### For PowerShell:
```powershell
# Run in PowerShell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/direct-install.bat" -OutFile "direct-install.bat"; ./direct-install.bat
```

This batch file:
1. Creates the Claude config file if it doesn't exist
2. Downloads a portable version of Node.js (no installation required)
3. Sets up everything automatically with zero dependencies
4. Works even on locked-down systems where you can't install software
5. Run as Administrator if possible for best results

### Option 3: Complete Install with Claude Detection

If you want a more thorough installation that can help you install Claude if needed:

#### For Command Prompt (CMD):
```cmd
curl -s https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/force-install.bat -o force-install.bat && force-install.bat
```

#### For PowerShell:
```powershell
# Run in PowerShell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/force-install.bat" -OutFile "force-install.bat"; ./force-install.bat
```

This script:
1. Checks if Claude Desktop is installed, offers to download it if not
2. Creates the Claude config file if it doesn't exist
3. Downloads a portable version of Node.js
4. Sets up everything automatically
5. Perfect for complete first-time setup

### Option 4: Diagnostic & Manual Install

If you're having trouble and want to diagnose Claude configuration issues:

#### For Command Prompt (CMD):
```cmd
curl -s https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/find-claude-config.bat -o find-claude-config.bat && find-claude-config.bat
```

#### For PowerShell:
```powershell
# Run in PowerShell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/find-claude-config.bat" -OutFile "find-claude-config.bat"; ./find-claude-config.bat
```

This script will:
1. Search your entire system for Claude Desktop installation and configuration
2. Generate a report of all potential Claude config locations
3. Help you determine where to place the configuration

### Option 5: PowerShell Bootstrap Installation

For PowerShell users, this option works even if you don't have Node.js installed:

```powershell
# Run in PowerShell as Administrator
irm https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/install-bootstrap.ps1 | iex
```

This PowerShell bootstrap installer will:
1. Check if Node.js is installed and install it if needed
2. Check if Git is installed and install it if needed
3. Clone the repository and set everything up automatically

### Option 6: One-Command Installation (Requires Node.js)

If you already have Node.js installed:

#### Windows (PowerShell):
```powershell
# Run in PowerShell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/install-windows.js" -OutFile "install-windows.js"; node install-windows.js
```

#### Windows (Command Prompt):
```cmd
curl -s https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/install-windows.js -o install-windows.js & node install-windows.js
```

#### macOS/Linux:
```bash
curl -s https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/install-mac-linux.js -o install-mac-linux.js && node install-mac-linux.js
```

### Option 7: Winget Installation

For Windows 10/11 users who prefer to install Node.js system-wide:

#### For Command Prompt (CMD):
```cmd
curl -s https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/winget-install.bat -o winget-install.bat && winget-install.bat
```

#### For PowerShell:
```powershell
# Run in PowerShell as Administrator
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/winget-install.bat" -OutFile "winget-install.bat"; ./winget-install.bat
```

This batch file:
1. Uses winget to install Node.js system-wide (requires administrator privileges)
2. Creates the Claude config file if it doesn't exist
3. Sets up everything automatically using the system-wide Node.js
4. No portable Node.js required - uses your system installation
5. Run as Administrator for best results

### Option 8: Guided Auto-Install

This method provides an interactive setup experience:

1. Clone the repository:
```
git clone https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked.git
cd ClaudeComputerCommander-Unlocked
npm install
```

2. Run the guided setup script:
```
node setup-claude-custom.js
```

### Option 9: Direct Installation

For users who prefer a direct installation without prompts:

1. Clone and install dependencies:
```
git clone https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked.git
cd ClaudeComputerCommander-Unlocked
npm install
```

2. Run the appropriate setup script:

For Windows:
```
node setup-claude-windows.js
```

For macOS/Linux:
```
node setup-claude-server.js
```

### Upgrading from a Previous Version

If you're upgrading from a previous version:

1. Uninstall the old version first:
   ```
   cd path/to/your/original/ClaudeComputerCommander
   node uninstall.js
   ```

2. Follow any of the installation methods above for the new version

## Manual Configuration

If the automatic configuration fails, you can manually configure Claude Desktop:

1. First locate your Claude Desktop configuration file using the diagnostic script:
   ```
   find-claude-config.bat
   ```
   
2. Open the configuration file in a text editor

3. Add or modify the mcpServers section to look like this:
   ```json
   "mcpServers": {
     "desktopCommander": {
       "command": "C:\\Users\\YourUsername\\ClaudeComputerCommander-Unlocked\\node\\node.exe",
       "args": [
         "C:\\Users\\YourUsername\\ClaudeComputerCommander-Unlocked\\dist\\index.js"
       ]
     }
   }
   ```
   (Replace YourUsername with your actual Windows username)

4. Save the file and restart Claude Desktop

## Configuration Options

Several pre-configured setup options are available:

- `config-unrestricted.json`: Full unrestricted filesystem access with maximum capabilities
- `config-administrator.json`: Administrator mode with elevated permissions
- `config-admin-unrestricted.json`: Combination of administrator mode and unrestricted access
- `config-improved.json`: Enhanced capabilities without full unrestricted access
- `config-simple.json`: Basic functionality for simple use cases

By default, all installation methods use `config-unrestricted.json`.

### Changing Configuration

To use a different configuration:

1. After installation, copy your preferred configuration to `config.json`:
   ```
   cp config-administrator.json config.json
   ```

2. Restart Claude Desktop to apply the changes

Each configuration offers different security and capability levels, from completely unrestricted access to more limited secure options.

### Uninstalling

To uninstall:

1. Navigate to your installation directory:
   ```
   cd path/to/ClaudeComputerCommander-Unlocked
   ```

2. Run the uninstall script:
   ```
   node uninstall.js
   ```

3. Optionally remove the directory:
   ```
   # Windows
   rmdir /s /q ClaudeComputerCommander-Unlocked
   
   # macOS/Linux
   rm -rf ClaudeComputerCommander-Unlocked
   ```

## Usage

1. After installation, start Claude desktop app
2. You can now ask Claude to:

- Execute terminal commands: "Run `ls -la` and show me the results"
- Edit files: "Find all TODO comments in my project files"
- Manage files: "Create a directory structure for a new React project"
- List processes: "Show me all running Node.js processes"

## Security Notice

This tool gives Claude access to terminal commands and filesystem operations on your computer. Use responsibly and be aware of the security implications.

## License

MIT license