#!/usr/bin/env node

/**
 * All-in-one installation script for ClaudeComputerCommander-Unlocked on macOS/Linux
 * This script handles:
 * 1. Checking for prerequisites
 * 2. Installing them if missing
 * 3. Cloning the repository
 * 4. Setting up the integration with Claude Desktop
 */

import { execSync } from 'child_process';
import { existsSync, mkdirSync, writeFileSync, readFileSync } from 'fs';
import { join, resolve } from 'path';
import { homedir } from 'os';

// Define log levels and colors for console output
const LOG_LEVELS = {
  INFO: '\x1b[36m%s\x1b[0m',    // Cyan
  SUCCESS: '\x1b[32m%s\x1b[0m', // Green
  WARN: '\x1b[33m%s\x1b[0m',    // Yellow
  ERROR: '\x1b[31m%s\x1b[0m',   // Red
};

// Helper functions
function log(message, level = 'INFO') {
  console.log(LOG_LEVELS[level], `[${level}] ${message}`);
}

function executeCommand(command, errorMessage) {
  try {
    return execSync(command, { stdio: 'pipe' }).toString().trim();
  } catch (error) {
    if (errorMessage) {
      log(errorMessage, 'ERROR');
      log(error.message, 'ERROR');
    }
    return null;
  }
}

// Check prerequisites
async function checkPrerequisites() {
  log('Checking prerequisites...');

  // Check for Node.js and npm
  const nodeVersion = executeCommand('node --version');
  if (!nodeVersion) {
    log('Node.js is not installed or not in PATH', 'ERROR');
    log('Please download and install Node.js from https://nodejs.org/en/download/', 'INFO');
    process.exit(1);
  }
  log(`Node.js ${nodeVersion} is installed`, 'SUCCESS');

  const npmVersion = executeCommand('npm --version');
  if (!npmVersion) {
    log('npm is not installed or not in PATH', 'ERROR');
    log('Please install npm, which usually comes with Node.js', 'INFO');
    process.exit(1);
  }
  log(`npm ${npmVersion} is installed`, 'SUCCESS');

  // Check for Git (optional)
  const gitVersion = executeCommand('git --version');
  if (!gitVersion) {
    log('Git is not installed. We will download the repository as a zip file instead.', 'WARN');
  } else {
    log(`Git ${gitVersion} is installed`, 'SUCCESS');
  }

  // Check if Claude Desktop is installed
  const claudeConfigPath = join(homedir(), 'Library', 'Application Support', 'Claude', 'claude_desktop_config.json');
  if (!existsSync(claudeConfigPath)) {
    log('Claude Desktop is not installed or has not been run yet', 'ERROR');
    log('Please download and install Claude Desktop from https://claude.ai/downloads', 'INFO');
    log('After installation, run Claude Desktop at least once before continuing', 'INFO');
    process.exit(1);
  }
  log('Claude Desktop is installed', 'SUCCESS');

  return { gitInstalled: !!gitVersion, claudeConfigPath };
}

// Clone or download repository
async function getRepository(gitInstalled) {
  log('Setting up repository...');
  
  const repoDir = join(homedir(), 'ClaudeComputerCommander-Unlocked');
  
  if (existsSync(repoDir)) {
    log(`Repository already exists at ${repoDir}`, 'WARN');
    log('Using existing repository. If you want a fresh install, please delete the directory first.', 'WARN');
  } else {
    if (gitInstalled) {
      // Clone with Git
      log('Cloning repository with Git...');
      executeCommand(`git clone https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked.git "${repoDir}"`, 
        'Failed to clone repository');
    } else {
      // Download as ZIP and extract
      log('Downloading repository as ZIP...');
      const tempZip = join(homedir(), 'claude_commander.zip');
      
      // Download with curl
      executeCommand(
        `curl -L https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked/archive/refs/heads/main.zip -o "${tempZip}"`,
        'Failed to download repository'
      );
      
      // Create directory
      mkdirSync(repoDir, { recursive: true });
      
      // Extract with unzip
      executeCommand(
        `unzip -q "${tempZip}" -d "${homedir()}"`,
        'Failed to extract repository. Please install unzip with "brew install unzip" on macOS or "sudo apt install unzip" on Linux.'
      );
      
      // Move contents from extracted directory to target
      executeCommand(
        `mv "${join(homedir(), 'ClaudeComputerCommander-Unlocked-main', '*')}" "${repoDir}"`,
        'Failed to move repository files'
      );
      
      // Clean up
      executeCommand(`rm "${tempZip}"`);
      executeCommand(`rm -rf "${join(homedir(), 'ClaudeComputerCommander-Unlocked-main')}"`);
    }
    
    log(`Repository set up at ${repoDir}`, 'SUCCESS');
  }
  
  return repoDir;
}

// Install dependencies
async function installDependencies(repoDir) {
  log('Installing dependencies...');
  
  process.chdir(repoDir);
  executeCommand('npm install', 'Failed to install dependencies');
  
  log('Dependencies installed successfully', 'SUCCESS');
}

// Set up Claude integration
async function setupClaudeIntegration(repoDir, claudeConfigPath) {
  log('Setting up integration with Claude Desktop...');
  
  process.chdir(repoDir);
  
  // Read current Claude config
  let claudeConfig;
  try {
    const configContent = readFileSync(claudeConfigPath, 'utf8');
    claudeConfig = JSON.parse(configContent);
  } catch (error) {
    log('Error reading Claude configuration', 'ERROR');
    log(error.message, 'ERROR');
    process.exit(1);
  }
  
  // Create backup
  const now = new Date();
  const timestamp = `${now.getFullYear()}.${(now.getMonth() + 1).toString().padStart(2, '0')}.${now.getDate().toString().padStart(2, '0')}-${now.getHours().toString().padStart(2, '0')}.${now.getMinutes().toString().padStart(2, '0')}`;
  const backupPath = claudeConfigPath.replace('.json', `-bk-${timestamp}.json`);
  
  try {
    writeFileSync(backupPath, JSON.stringify(claudeConfig, null, 2));
    log(`Created backup of Claude config at: ${backupPath}`, 'SUCCESS');
  } catch (error) {
    log('Failed to create backup of Claude configuration', 'ERROR');
    log(error.message, 'ERROR');
    process.exit(1);
  }
  
  // Ensure mcpServers section exists
  if (!claudeConfig.mcpServers) {
    claudeConfig.mcpServers = {};
  }
  
  // Add server configuration
  claudeConfig.mcpServers.desktopCommander = {
    "command": "node",
    "args": [
      join(repoDir, 'dist', 'index.js')
    ]
  };
  
  // Write updated config
  try {
    writeFileSync(claudeConfigPath, JSON.stringify(claudeConfig, null, 2));
    log('Updated Claude configuration successfully', 'SUCCESS');
  } catch (error) {
    log('Failed to update Claude configuration', 'ERROR');
    log(error.message, 'ERROR');
    process.exit(1);
  }
}

// Build the project
async function buildProject(repoDir) {
  log('Building project...');
  
  process.chdir(repoDir);
  executeCommand('npm run build', 'Failed to build project');
  
  log('Project built successfully', 'SUCCESS');
}

// Main installation function
async function install() {
  try {
    log('Starting ClaudeComputerCommander-Unlocked installation...');
    
    // Step 1: Check prerequisites
    const { gitInstalled, claudeConfigPath } = await checkPrerequisites();
    
    // Step 2: Clone/download repository
    const repoDir = await getRepository(gitInstalled);
    
    // Step 3: Install dependencies
    await installDependencies(repoDir);
    
    // Step 4: Build the project
    await buildProject(repoDir);
    
    // Step 5: Set up Claude integration
    await setupClaudeIntegration(repoDir, claudeConfigPath);
    
    // Installation complete
    log('ClaudeComputerCommander-Unlocked has been successfully installed!', 'SUCCESS');
    log(`The installation directory is: ${repoDir}`, 'INFO');
    log('Please restart Claude Desktop to apply the changes.', 'INFO');
    log('\nYou can now ask Claude to:', 'INFO');
    log('- Execute terminal commands: "Run `ls -la` and show me the results"', 'INFO');
    log('- Edit files: "Find all TODO comments in my project files"', 'INFO');
    log('- Manage files: "Create a directory structure for a new React project"', 'INFO');
    log('- List processes: "Show me all running Node.js processes"', 'INFO');
    
  } catch (error) {
    log('An unexpected error occurred during installation', 'ERROR');
    log(error.message, 'ERROR');
    process.exit(1);
  }
}

// Run the installation
install();