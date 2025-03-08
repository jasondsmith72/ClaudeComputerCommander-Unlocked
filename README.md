# ClaudeComputerCommanderUnlocked

Short version. Two key things. Terminal commands and diff based file editing.

This is a server that allows Claude desktop app to execute long-running terminal commands on your computer and manage processes through Model Context Protocol (MCP) + Built on top of MCP Filesystem Server to provide additional search and replace file editing capabilities.

This is a fork of wonderwhy-er/ClaudeComputerCommander with enhanced configuration options.

## 🔓 UNRESTRICTED FILE ACCESS

IMPORTANT UPDATE: This version of ClaudeComputerCommander has been modified to provide unrestricted access to all files and drives on your computer. Directory restrictions have been completely removed, allowing Claude to:

((Run as administraotr @ your own risk)) Open Claude desktop as administrator opens root access.

* Access any drive (C:, D:, etc.) and any folder on your system
* Read and write files in any location
* Execute commands that interact with any part of the filesystem
* Navigate and modify system files and folders

This provides maximum flexibility and eliminates permission errors, but please be aware that Claude will have access to all parts of your computer's filesystem. Use with appropriate caution.

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

You'll need the following prerequisites, but don't worry - our one-command installers will automatically install them if they're missing:

1. **Claude Desktop App** - Download and install from [Anthropic's website](https://claude.ai/downloads)
   - This is the only prerequisite you must install manually
   - The installation scripts will check if Claude Desktop is installed

2. **Node.js and npm** - Required but will be automatically installed if missing
   - The installer will set up Node.js with the tools for compiling native modules

3. **Git** - Optional, will be automatically installed if missing
   - If Git can't be installed, the scripts will download the repository as a ZIP file

## Installation

The easiest way to install is using our one-command installation option, which handles everything automatically including installing any missing prerequisites (except Claude Desktop).

### Option 1: One-Command Installation (Recommended)

For the easiest installation experience:

#### Windows:
```
curl -s https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/install-windows.js -o install-windows.js && node install-windows.js
```

#### macOS/Linux:
```
curl -s https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/install-mac-linux.js -o install-mac-linux.js && node install-mac-linux.js
```

These scripts will:
1. Check for prerequisites and install them if missing (Node.js with native module tools, Git)
2. Clone the repository
3. Install dependencies
4. Set up the integration with Claude Desktop
5. Guide you through the configuration process

### Option 2: Guided Auto-Install 

This method uses the repository's built-in setup scripts:

1. Clone the repository:

```
git clone https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked.git
```

2. Navigate to the cloned directory

```
cd ClaudeComputerCommander-Unlocked
```

3. Install dependencies

```
npm install
```

4. Run the guided setup script (works on both Windows and macOS/Linux):

```
node setup-claude-custom.js
```

The script will automatically detect your OS, create backups of existing configurations, and guide you through the setup process.

### Option 3: Direct Installation

For users who prefer a direct installation without prompts:

```
git clone https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked.git
cd ClaudeComputerCommander-Unlocked
npm install
```

For Windows:
```
node setup-claude-windows.js
```

For macOS/Linux:
```
node setup-claude-server.js
```

### Upgrading from a Previous Version

If you're upgrading from a previous version of ClaudeComputerCommander:

1. Uninstall the old version first:
   ```
   # Navigate to your ORIGINAL ClaudeComputerCommander directory
   cd path/to/your/original/ClaudeComputerCommander
   
   # Run the uninstall script
   node uninstall.js
   ```

2. Follow the installation steps above for the new version

### Configuration Files

Several pre-configured setup options are available:

- `config-unrestricted.json`: Full unrestricted filesystem access with maximum capabilities
- `config-administrator.json`: Administrator mode with elevated permissions
- `config-admin-unrestricted.json`: Combination of administrator mode and unrestricted access
- `config-improved.json`: Enhanced capabilities without full unrestricted access
- `config-simple.json`: Basic functionality for simple use cases

#### How to Use Configuration Files

By default:
- The guided auto-installer will use `config-unrestricted.json` as the default configuration
- The direct installation scripts also use `config-unrestricted.json` by default

To use a different configuration:

1. After installation, copy your preferred configuration to `config.json`:
   ```
   # For example, to use the administrator configuration:
   cp config-administrator.json config.json
   ```

2. If the server is already running, restart it or restart Claude Desktop

3. If you want to switch configurations later:
   ```
   # First, make a backup of your current config
   cp config.json config-backup.json
   
   # Then copy the new configuration
   cp config-improved.json config.json
   ```

Each configuration offers different security and capability levels:
- `config-unrestricted.json`: No filesystem restrictions, allowing access to any file
- `config-administrator.json`: Elevated permissions with some filesystem restrictions
- `config-admin-unrestricted.json`: Most powerful option with admin privileges + unrestricted access
- `config-improved.json`: Enhanced capabilities with reasonable security restrictions
- `config-simple.json`: Most restrictive with limited access to secure directories only

### Uninstalling

To uninstall ClaudeComputerCommander-Unlocked:

1. Navigate to your ClaudeComputerCommander-Unlocked directory:
   ```
   cd path/to/ClaudeComputerCommander-Unlocked
   ```

2. Run the uninstall script:
   ```
   node uninstall.js
   ```

3. The script will automatically:
   - Find your Claude Desktop configuration
   - Create a backup of the current config
   - Remove the ClaudeComputerCommander entries
   - Save the updated configuration

4. After uninstalling, you can safely delete the directory if desired:
   ```
   # Optional: Remove the directory (Windows)
   rmdir /s /q ClaudeComputerCommander-Unlocked
   
   # Optional: Remove the directory (macOS/Linux)
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