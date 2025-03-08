#!/usr/bin/env node

/**
 * All-in-one installation script for ClaudeComputerCommander-Unlocked on macOS/Linux
 * This script handles:
 * 1. Checking for prerequisites and installing them if missing
 * 2. Cloning the repository
 * 3. Setting up the integration with Claude Desktop
 */

import { execSync } from 'child_process';
import { existsSync, mkdirSync, writeFileSync, readFileSync, unlinkSync } from 'fs';
import { join, resolve } from 'path';
import { homedir, platform } from 'os';

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

function executeCommand(command, errorMessage, silent = false) {
  try {
    return execSync(command, { stdio: silent ? 'pipe' : 'inherit' }).toString().trim();
  } catch (error) {
    if (errorMessage) {
      log(errorMessage, 'ERROR');
      log(error.message, 'ERROR');
    }
    return null;
  }
}

// Determine if we're on macOS
const isMac = platform() === 'darwin';

// Install Node.js if missing (macOS)
async function installNodeJsMac() {
  log('Installing Node.js on macOS...');
  
  // Check if Homebrew is installed
  const brewInstalled = executeCommand('which brew', null, true);
  if (!brewInstalled) {
    log('Homebrew is not installed. Installing Homebrew first...', 'INFO');
    executeCommand(
      '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"',
      'Failed to install Homebrew. Please install it manually from https://brew.sh/'
    );
    
    // Update PATH for current session
    const brewPath = '/opt/homebrew/bin:/usr/local/bin';
    process.env.PATH = `${brewPath}:${process.env.PATH}`;
    
    // Verify Homebrew installation
    const brewVerify = executeCommand('which brew', null, true);
    if (!brewVerify) {
      log('Failed to install Homebrew. Please install it manually from https://brew.sh/', 'ERROR');
      return false;
    }
  }
  
  // Install Node.js via Homebrew
  log('Installing Node.js via Homebrew...');
  executeCommand('brew install node', 'Failed to install Node.js via Homebrew');
  
  // Install native module compilation tools
  log('Installing tools for native modules...');
  executeCommand('xcode-select --install || true', 'Note: Developer command-line tools installation might require user interaction');
  
  // Verify installation
  const nodeVersion = executeCommand('node --version', null, true);
  const npmVersion = executeCommand('npm --version', null, true);
  
  if (nodeVersion && npmVersion) {
    log(`Node.js ${nodeVersion} and npm ${npmVersion} installed successfully`, 'SUCCESS');
    return true;
  } else {
    log('Node.js installation might have failed. Please try installing manually from https://nodejs.org/en/download/', 'ERROR');
    return false;
  }
}

// Install Node.js if missing (Linux)
async function installNodeJsLinux() {
  log('Installing Node.js on Linux...');
  
  // Detect the Linux distribution
  let distro = '';
  if (existsSync('/etc/debian_version')) {
    distro = 'debian';
  } else if (existsSync('/etc/fedora-release')) {
    distro = 'fedora';
  } else if (existsSync('/etc/redhat-release')) {
    distro = 'redhat';
  } else if (existsSync('/etc/arch-release')) {
    distro = 'arch';
  } else {
    log('Unsupported Linux distribution. Please install Node.js manually from https://nodejs.org/en/download/', 'ERROR');
    return false;
  }
  
  // Install Node.js based on the distribution
  if (distro === 'debian') {
    // For Debian/Ubuntu
    log('Detected Debian/Ubuntu-based distribution');
    log('Updating package index...');
    executeCommand('sudo apt-get update', 'Failed to update package index');
    
    log('Installing Node.js via apt...');
    executeCommand('sudo apt-get install -y nodejs npm build-essential', 'Failed to install Node.js via apt');
  } else if (distro === 'fedora') {
    // For Fedora
    log('Detected Fedora-based distribution');
    log('Installing Node.js via dnf...');
    executeCommand('sudo dnf install -y nodejs npm gcc-c++ make', 'Failed to install Node.js via dnf');
  } else if (distro === 'redhat') {
    // For RHEL/CentOS
    log('Detected RHEL/CentOS-based distribution');
    log('Installing Node.js via yum...');
    executeCommand('sudo yum install -y nodejs npm gcc-c++ make', 'Failed to install Node.js via yum');
  } else if (distro === 'arch') {
    // For Arch Linux
    log('Detected Arch-based distribution');
    log('Installing Node.js via pacman...');
    executeCommand('sudo pacman -S --noconfirm nodejs npm base-devel', 'Failed to install Node.js via pacman');
  }
  
  // Verify installation
  const nodeVersion = executeCommand('node --version', null, true);
  const npmVersion = executeCommand('npm --version', null, true);
  
  if (nodeVersion && npmVersion) {
    log(`Node.js ${nodeVersion} and npm ${npmVersion} installed successfully`, 'SUCCESS');
    return true;
  } else {
    log('Node.js installation might have failed. Please try installing manually from https://nodejs.org/en/download/', 'ERROR');
    return false;
  }
}

// Install Git if missing (macOS)
async function installGitMac() {
  log('Installing Git on macOS...');
  
  // Check if Homebrew is installed
  const brewInstalled = executeCommand('which brew', null, true);
  if (!brewInstalled) {
    // Homebrew should be installed by the Node.js installation step
    log('Homebrew not found. Please install it manually from https://brew.sh/', 'ERROR');
    return false;
  }
  
  // Install Git via Homebrew
  log('Installing Git via Homebrew...');
  executeCommand('brew install git', 'Failed to install Git via Homebrew');
  
  // Verify installation
  const gitVersion = executeCommand('git --version', null, true);
  
  if (gitVersion) {
    log(`Git ${gitVersion} installed successfully`, 'SUCCESS');
    return true;
  } else {
    log('Git installation might have failed, but will continue without Git', 'WARN');
    return false;
  }
}

// Install Git if missing (Linux)
async function installGitLinux() {
  log('Installing Git on Linux...');
  
  // Detect the Linux distribution
  let distro = '';
  if (existsSync('/etc/debian_version')) {
    distro = 'debian';
  } else if (existsSync('/etc/fedora-release')) {
    distro = 'fedora';
  } else if (existsSync('/etc/redhat-release')) {
    distro = 'redhat';
  } else if (existsSync('/etc/arch-release')) {
    distro = 'arch';
  } else {
    log('Unsupported Linux distribution. Please install Git manually.', 'ERROR');
    return false;
  }
  
  // Install Git based on the distribution
  if (distro === 'debian') {
    // For Debian/Ubuntu
    log('Installing Git via apt...');
    executeCommand('sudo apt-get install -y git', 'Failed to install Git via apt');
  } else if (distro === 'fedora') {
    // For Fedora
    log('Installing Git via dnf...');
    executeCommand('sudo dnf install -y git', 'Failed to install Git via dnf');
  } else if (distro === 'redhat') {
    // For RHEL/CentOS
    log('Installing Git via yum...');
    executeCommand('sudo yum install -y git', 'Failed to install Git via yum');
  } else if (distro === 'arch') {
    // For Arch Linux
    log('Installing Git via pacman...');
    executeCommand('sudo pacman -S --noconfirm git', 'Failed to install Git via pacman');
  }
  
  // Verify installation
  const gitVersion = executeCommand('git --version', null, true);
  
  if (gitVersion) {
    log(`Git ${gitVersion} installed successfully`, 'SUCCESS');
    return true;
  } else {
    log('Git installation might have failed, but will continue without Git', 'WARN');
    return false;
  }
}

// Check prerequisites and install if missing
async function checkAndInstallPrerequisites() {
  log('Checking prerequisites...');

  // Check for Node.js and npm
  let nodeVersion = executeCommand('node --version', null, true);
  let npmVersion = executeCommand('npm --version', null, true);
  
  if (!nodeVersion || !npmVersion) {
    log('Node.js is not installed or not in PATH', 'WARN');
    log('Attempting to install Node.js automatically...', 'INFO');
    
    const nodeInstalled = isMac ? await installNodeJsMac() : await installNodeJsLinux();
    if (!nodeInstalled) {
      process.exit(1);
    }
    
    // Refresh versions after installation
    nodeVersion = executeCommand('node --version', null, true);
    npmVersion = executeCommand('npm --version', null, true);
  }
  
  log(`Node.js ${nodeVersion} is installed`, 'SUCCESS');
  log(`npm ${npmVersion} is installed`, 'SUCCESS');

  // Check for Git (optional)
  let gitVersion = executeCommand('git --version', null, true);
  let gitInstalled = !!gitVersion;
  
  if (!gitVersion) {
    log('Git is not installed. Attempting to install Git automatically...', 'WARN');
    gitInstalled = isMac ? await installGitMac() : await installGitLinux();
    if (gitInstalled) {
      gitVersion = executeCommand('git --version', null, true);
      log(`Git ${gitVersion} is installed`, 'SUCCESS');
    } else {
      log('Will download the repository as a zip file instead', 'INFO');
    }
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

  return { gitInstalled, claudeConfigPath };
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
      
      // Check if unzip is available
      const unzipInstalled = executeCommand('which unzip', null, true);
      if (!unzipInstalled) {
        log('unzip utility not found. Attempting to install...', 'WARN');
        if (isMac) {
          executeCommand('brew install unzip', 'Failed to install unzip');
        } else {
          // Try common package managers
          executeCommand('sudo apt-get install -y unzip || sudo yum install -y unzip || sudo dnf install -y unzip || sudo pacman -S --noconfirm unzip', 
            'Failed to install unzip. Please install it manually and try again.');
        }
      }
      
      // Extract with unzip
      executeCommand(
        `unzip -q "${tempZip}" -d "${homedir()}"`,
        'Failed to extract repository. Please make sure unzip is installed.'
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
    
    // Step 1: Check prerequisites and install if missing
    const { gitInstalled, claudeConfigPath } = await checkAndInstallPrerequisites();
    
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