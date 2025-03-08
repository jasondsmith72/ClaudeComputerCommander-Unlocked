#!/usr/bin/env node

/**
 * All-in-one installation script for ClaudeComputerCommander-Unlocked on Windows
 * This script handles:
 * 1. Checking for prerequisites and installing them if missing
 * 2. Cloning the repository
 * 3. Setting up the integration with Claude Desktop
 */

import { execSync } from 'child_process';
import { existsSync, mkdirSync, writeFileSync, readFileSync, unlinkSync } from 'fs';
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

// Install Node.js if missing
async function installNodeJs() {
  log('Installing Node.js...');
  
  // Create temp directory for downloads
  const tempDir = join(homedir(), 'temp_node_install');
  if (!existsSync(tempDir)) {
    mkdirSync(tempDir, { recursive: true });
  }
  
  // Download Node.js installer
  const installerPath = join(tempDir, 'node_installer.msi');
  log('Downloading Node.js installer (this might take a minute)...');
  
  executeCommand(
    `powershell -Command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi' -OutFile '${installerPath}'"`,
    'Failed to download Node.js installer'
  );
  
  // Install Node.js with necessary tools for native modules
  log('Installing Node.js with tools for native modules...');
  executeCommand(
    `msiexec.exe /i "${installerPath}" /qb ADDLOCAL=NodeRuntime,npm,DocumentationShortcuts,EnvironmentPathNode,EnvironmentPathNpmModules,AssociateJs,AssociatedFiles,NodePerfCounters INSTALLLEVEL=1 /norestart`,
    'Failed to install Node.js'
  );
  
  // Install native module tools
  log('Installing tools for native modules via npm...');
  executeCommand('npm install --global --production windows-build-tools', 'Note: Native module tools installation may require elevation. You might need to install manually if this fails.');
  
  // Clean up
  try {
    unlinkSync(installerPath);
    log('Cleaned up temporary files', 'SUCCESS');
  } catch (error) {
    log('Failed to clean up temporary files, but installation should still proceed', 'WARN');
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

// Install Git if missing
async function installGit() {
  log('Installing Git...');
  
  // Create temp directory for downloads
  const tempDir = join(homedir(), 'temp_git_install');
  if (!existsSync(tempDir)) {
    mkdirSync(tempDir, { recursive: true });
  }
  
  // Download Git installer
  const installerPath = join(tempDir, 'git_installer.exe');
  log('Downloading Git installer (this might take a minute)...');
  
  executeCommand(
    `powershell -Command "Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.41.0.windows.3/Git-2.41.0.3-64-bit.exe' -OutFile '${installerPath}'"`,
    'Failed to download Git installer'
  );
  
  // Install Git
  log('Installing Git...');
  executeCommand(
    `"${installerPath}" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS="icons,ext\\reg\\shellhere,assoc,assoc_sh"`,
    'Failed to install Git'
  );
  
  // Clean up
  try {
    unlinkSync(installerPath);
    log('Cleaned up temporary files', 'SUCCESS');
  } catch (error) {
    log('Failed to clean up temporary files, but installation should still proceed', 'WARN');
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
    
    const nodeInstalled = await installNodeJs();
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
    gitInstalled = await installGit();
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
  const claudeConfigPath = join(process.env.APPDATA, 'Claude', 'claude_desktop_config.json');
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
      
      // Download with PowerShell
      executeCommand(
        `powershell -Command "Invoke-WebRequest -Uri https://github.com/jasondsmith72/ClaudeComputerCommander-Unlocked/archive/refs/heads/main.zip -OutFile '${tempZip}'"`,
        'Failed to download repository'
      );
      
      // Create directory
      mkdirSync(repoDir, { recursive: true });
      
      // Extract with PowerShell
      executeCommand(
        `powershell -Command "Expand-Archive -Path '${tempZip}' -DestinationPath '${homedir()}' -Force"`,
        'Failed to extract repository'
      );
      
      // Move contents from extracted directory to target
      executeCommand(
        `powershell -Command "Move-Item -Path '${join(homedir(), 'ClaudeComputerCommander-Unlocked-main', '*')}' -Destination '${repoDir}' -Force"`,
        'Failed to move repository files'
      );
      
      // Clean up
      executeCommand(`powershell -Command "Remove-Item -Path '${tempZip}' -Force"`);
      executeCommand(`powershell -Command "Remove-Item -Path '${join(homedir(), 'ClaudeComputerCommander-Unlocked-main')}' -Recurse -Force"`);
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
    log('- Execute terminal commands: "Run `dir` and show me the results"', 'INFO');
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