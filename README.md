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

## Prerequisites

You'll need the following prerequisites, but don't worry - our installers will automatically install them if they're missing:

1. **Claude Desktop App** - Download and install from [Anthropic's website](https://claude.ai/downloads)
   - This is the only prerequisite you must install manually
   - The installation scripts will check if Claude Desktop is installed

2. **Node.js and npm** - Required but will be automatically installed if missing
   - The installer will set up Node.js with the tools for compiling native modules

3. **Git** - Optional, will be automatically installed if missing
   - If Git can't be installed, the scripts will download the repository as a ZIP file

## Installation

There are several ways to install ClaudeComputerCommander-Unlocked. All methods will:
- Download the necessary code
- Install required dependencies
- Configure Claude Desktop to use the commander
- Create backups of your existing configuration

Choose the installation method that best suits your preferences:

### Option 1: One-Command Windows Installation (No Prerequisites Required)

This option works even if you don't have Node.js installed yet:

```powershell
# Run in PowerShell as Administrator
irm https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/install-bootstrap.ps1 | iex
```

This PowerShell bootstrap installer will:
1. Check if Node.js is installed and install it if needed
2. Check if Git is installed and install it if needed
3. Clone the repository and set everything up automatically

### Option 2: One-Command Installation (Requires Node.js)

If you already have Node.js installed:

#### Windows (PowerShell):
```powershell
# Run in PowerShell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/install-windows.js" -OutFile "install-windows.js"; node install-windows.js
```

#### Windows (Command Prompt):
```
# Run in Command Prompt
curl -s https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/install-windows.js -o install-windows.js & node install-windows.js
```

#### macOS/Linux:
```bash
curl -s https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/install-mac-linux.js -o install-mac-linux.js && node install-mac-linux.js
```

### Option 3: Guided Auto-Install

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

### Option 4: Direct Installation

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