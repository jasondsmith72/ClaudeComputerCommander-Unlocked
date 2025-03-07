# Claude Desktop Commander MCP

[![npm downloads](https://img.shields.io/npm/dw/@jasondsmith72/desktop-commander)](https://www.npmjs.com/package/@jasondsmith72/desktop-commander)
[![GitHub Repo](https://img.shields.io/badge/GitHub-jasondsmith72%2FClaudeComputerCommander-blue)](https://github.com/jasondsmith72/ClaudeComputerCommander)

Short version. Two key things. Terminal commands and diff based file editing.

This is a server that allows Claude desktop app to execute long-running terminal commands on your computer and manage processes through Model Context Protocol (MCP) + Built on top of [MCP Filesystem Server](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem) to provide additional search and replace file editing capabilities.

This is a fork of [wonderwhy-er/ClaudeComputerCommander](https://github.com/wonderwhy-er/ClaudeComputerCommander) with custom setup options.

## Features

- Execute terminal commands with output streaming
- Command timeout and background execution support
- Process management (list and kill processes)
- Session management for long-running commands
- Full filesystem operations:
  - Read/write files
  - Create/list directories
  - Move files/directories
  - Search files
  - Get file metadata
  - Code editing capabilities:
  - Surgical text replacements for small changes
  - Full file rewrites for major changes
  - Multiple file support
  - Pattern-based replacements

## Installation
First, ensure you've downloaded and installed the [Claude Desktop app](https://claude.ai/download) and you have [npm installed](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm).

### Option 1: Custom Setup (Recommended)
This method is best if you don't have permissions to directly modify the Claude config file or prefer a guided approach:

1. Clone the repository:
```bash
git clone https://github.com/jasondsmith72/ClaudeComputerCommander.git
cd ClaudeComputerCommander
```

2. Checkout the custom-setup branch:
```bash
git checkout custom-setup
```

3. Run the custom setup:
```bash
npm run setup:custom
```

4. Follow the on-screen instructions to update your Claude config file manually.

5. Restart Claude if it's running.

### Option 2: Regular Setup
If you have permissions to modify the Claude config file:

```bash
git clone https://github.com/jasondsmith72/ClaudeComputerCommander.git
cd ClaudeComputerCommander
npm run setup
```

Restart Claude if running.

### Option 3: Add to claude_desktop_config manually
Add this entry to your claude_desktop_config.json (on Windows, found at %APPDATA%\Claude\claude_desktop_config.json):
```json
{
  "mcpServers": {
    "desktop-commander": {
      "command": "npx",
      "args": [
        "-y",
        "@jasondsmith72/desktop-commander"
      ]
    }
  }
}
```
Restart Claude if running.

## Usage

The server provides these tool categories:

### Terminal Tools
- `execute_command`: Run commands with configurable timeout
- `read_output`: Get output from long-running commands
- `force_terminate`: Stop running command sessions
- `list_sessions`: View active command sessions
- `list_processes`: View system processes
- `kill_process`: Terminate processes by PID
- `block_command`/`unblock_command`: Manage command blacklist

### Filesystem Tools
- `read_file`/`write_file`: File operations
- `create_directory`/`list_directory`: Directory management  
- `move_file`: Move/rename files
- `search_files`: Pattern-based file search
- `get_file_info`: File metadata

### Edit Tools
- `edit_block`: Apply surgical text replacements (best for changes <20% of file size)
- `write_file`: Complete file rewrites (best for large changes >20% or when edit_block fails)

Search/Replace Block Format:
```
filepath.ext
<<<<<<< SEARCH
existing code to replace
=======
new code to insert
>>>>>>> REPLACE
```

Example:
```
src/main.js
<<<<<<< SEARCH
console.log("old message");
=======
console.log("new message");
>>>>>>> REPLACE
```

## Handling Long-Running Commands

For commands that may take a while:

1. `execute_command` returns after timeout with initial output
2. Command continues in background
3. Use `read_output` with PID to get new output
4. Use `force_terminate` to stop if needed

## Model Context Protocol Integration

This project extends the MCP Filesystem Server to enable:
- Local server support in Claude Desktop
- Full system command execution
- Process management
- File operations
- Code editing with search/replace blocks

## Troubleshooting

If you encounter issues setting up or using the MCP server:

1. Check that Claude Desktop is properly installed and has been run at least once
2. Verify that the claude_desktop_config.json file exists and is properly formatted
3. Make sure you have the required permissions to modify the config file
4. Restart Claude Desktop after making changes to the config
5. Check the setup log file (setup-custom.log) for any error messages

## Contributing

If you find this project useful, please consider giving it a ⭐ star on GitHub! This helps others discover the project and encourages further development.

We welcome contributions from the community! Whether you've found a bug, have a feature request, or want to contribute code, here's how you can help:

- **Found a bug?** Open an issue at [github.com/jasondsmith72/ClaudeComputerCommander/issues](https://github.com/jasondsmith72/ClaudeComputerCommander/issues)
- **Have a feature idea?** Submit a feature request in the issues section
- **Want to contribute code?** Fork the repository, create a branch, and submit a pull request
- **Questions or discussions?** Start a discussion in the GitHub Discussions tab

All contributions, big or small, are greatly appreciated!

## License

MIT
