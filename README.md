
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

## Installation

First, ensure you've downloaded and installed the Claude Desktop app and you have npm installed.

### Option 1: Custom Setup (Recommended)

This method is best if you don't have permissions to directly modify the Claude config file or prefer a guided approach:

1. Clone the repository:

```
git clone https://github.com/jasondsmith72/ClaudeComputerCommanderUnlocked.git
```

2. Navigate to the cloned directory

```
cd ClaudeComputerCommanderUnlocked
```

3. Install dependencies

```
npm install
```

4. Run the custom setup script:

```
node setup-claude-custom.js
```

Follow the prompts to select your Claude app location, configuration options, and to start the server.

### Option 2: Automated Setup

Use this method if you have the standard Claude installation:

```
git clone https://github.com/jasondsmith72/ClaudeComputerCommanderUnlocked.git
cd ClaudeComputerCommanderUnlocked
npm install
```

For Windows:
```
node setup-claude-windows.js
```

For macOS/Linux (with standard installation locations):
```
node setup-claude-server.js
```

### Configuration Files

Several pre-configured setup options are available:

- `config-unrestricted.json`: Full unrestricted filesystem access with maximum capabilities
- `config-administrator.json`: Administrator mode with elevated permissions
- `config-admin-unrestricted.json`: Combination of administrator mode and unrestricted access
- `config-improved.json`: Enhanced capabilities without full unrestricted access
- `config-simple.json`: Basic functionality for simple use cases

### Uninstalling

To revert changes and remove the server:
```
node uninstall.js
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
