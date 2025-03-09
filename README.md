# ClaudeComputerCommanderUnlocked

## 🔓 UNRESTRICTED FILE ACCESS

IMPORTANT: This version of ClaudeComputerCommander has been modified to provide unrestricted access to all files and drives on your computer.

Short version: This server allows Claude desktop app to execute terminal commands on your computer and manage files through Model Context Protocol (MCP).

This is a fork of wonderwhy-er/ClaudeComputerCommander with enhanced configuration options.

## Features

* Execute terminal commands with output streaming
* Full unrestricted filesystem access - Access any file or folder on your computer
* Process management (list and kill processes)
* Session management for long-running commands
* Full filesystem operations (read/write files, create/list directories, move files/directories, etc.)
* Code editing capabilities with surgical text replacements

## Easy Installation

There are two main steps to get ClaudeComputerCommanderUnlocked working:

1. Install ClaudeComputerCommanderUnlocked
2. Configure Claude Desktop to use it

### Prerequisites

You'll need:

1. **Claude Desktop App** - Download and install from [Anthropic's website](https://claude.ai/downloads)
2. **Node.js and npm** - Will be automatically installed by our script if not present
3. **Git** - Optional, will be downloaded as ZIP if not present

### PowerShell Installation (Recommended)

The most reliable installation method using PowerShell:

```powershell
# Run in PowerShell
iwr https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/simple-install.ps1 -OutFile simple-install.ps1; ./simple-install.ps1
```

This script will:
1. Install Node.js if not present (using winget, MSI, or portable installation)
2. Download and install ClaudeComputerCommanderUnlocked
3. Provide instructions for manually configuring Claude Desktop

### Manual Configuration

After running the installation script, you'll need to manually configure Claude Desktop:

1. Open Claude Desktop application
2. Click on Settings (gear icon) in the bottom left
3. Go to the "Developer" tab
4. Click "Edit" next to "MCP Servers"
5. Add the configuration provided by the installation script
6. Click "Save"
7. Restart Claude Desktop

The installation script will show you the exact configuration you need to add.

## Usage

After installation and configuration, start Claude desktop app and you can ask Claude to:

- Execute terminal commands: "Run `ls -la` and show me the results"
- Edit files: "Find all TODO comments in my project files"
- Manage files: "Create a directory structure for a new React project"
- List processes: "Show me all running Node.js processes"

## Security Notice

This tool gives Claude access to terminal commands and filesystem operations on your computer. Use responsibly and be aware of the security implications.

## License

MIT license
