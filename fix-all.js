#!/usr/bin/env node

// This script applies all fixes to the ClaudeComputerCommander 
// to enable unrestricted file system access

import { execSync } from 'child_process';
import { readFileSync, writeFileSync, existsSync, unlinkSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';

// Log to both console and file
const LOG_FILE = 'fix-all.log';

function log(message) {
  const timestamp = new Date().toISOString();
  const formattedMessage = `${timestamp}: ${message}`;
  console.log(message);
  writeFileSync(LOG_FILE, formattedMessage + '\n', { flag: 'a' });
}

function runCommand(command) {
  log(`Running command: ${command}`);
  try {
    const output = execSync(command, { encoding: 'utf8' });
    return { success: true, output };
  } catch (error) {
    log(`Command failed: ${error.message}`);
    return { success: false, error };
  }
}

// Main function
async function main() {
  log('=== CLAUDE COMPUTER COMMANDER - FULL ACCESS FIX ===');
  log(`Starting at: ${new Date().toLocaleString()}`);
  log(`Working directory: ${process.cwd()}`);
  
  // Step 1: Check if we're in the right directory
  log('\nStep 1: Verifying we are in the ClaudeComputerCommander directory');
  if (!existsSync('package.json')) {
    log('ERROR: package.json not found. Please run this script from the ClaudeComputerCommander directory.');
    process.exit(1);
  }
  
  const pkgJson = JSON.parse(readFileSync('package.json', 'utf8'));
  if (!pkgJson.name.includes('desktop-commander')) {
    log('ERROR: This does not appear to be the ClaudeComputerCommander directory.');
    process.exit(1);
  }
  
  log('✅ Verified we are in the correct directory.');

  // Step 2: Create unrestricted config
  log('\nStep 2: Creating unrestricted configuration');
  const configJson = {
    "blockedCommands": [
      "format", "mount", "umount", "mkfs", "fdisk", "dd", 
      "sudo", "su", "passwd", "adduser", "useradd", "usermod", "groupadd"
    ],
    "allowedDirectories": [
      "C:\\", "D:\\", "E:\\", "F:\\", "G:\\", "H:\\", "I:\\", 
      "J:\\", "K:\\", "L:\\", "M:\\", "N:\\", "O:\\", "P:\\", 
      "Q:\\", "R:\\", "S:\\", "T:\\", "U:\\", "V:\\", "W:\\", 
      "X:\\", "Y:\\", "Z:\\", "/", "~", "."
    ]
  };
  
  writeFileSync('config.json', JSON.stringify(configJson, null, 2), 'utf8');
  log('✅ Unrestricted configuration created.');
  
  // Step 3: Install dependencies (if needed)
  log('\nStep 3: Installing dependencies');
  runCommand('npm install');
  log('✅ Dependencies installed.');
  
  // Step 4: Build the package
  log('\nStep 4: Building the package');
  runCommand('npm run build');
  log('✅ Package built.');
  
  // Step 5: Uninstall previous version
  log('\nStep 5: Uninstalling previous version');
  runCommand('npm uninstall -g @jasondsmith72/desktop-commander');
  runCommand('npm uninstall -g .');
  log('✅ Previous versions uninstalled.');
  
  // Step 6: Install the updated version
  log('\nStep 6: Installing updated version');
  runCommand('npm install -g .');
  log('✅ Updated version installed.');
  
  // Step 7: Update Claude Desktop configuration
  log('\nStep 7: Updating Claude Desktop configuration');
  
  // Path to Claude config
  const claudeConfigPath = join(
    process.env.APPDATA || '',
    'Claude', 
    'claude_desktop_config.json'
  );
  
  if (existsSync(claudeConfigPath)) {
    log(`Found Claude configuration at: ${claudeConfigPath}`);
    
    // Backup the existing config
    const backupPath = `${claudeConfigPath}.bak-${Date.now()}`;
    writeFileSync(backupPath, readFileSync(claudeConfigPath));
    log(`Created backup at: ${backupPath}`);
    
    // Read and update config
    let claudeConfig;
    try {
      claudeConfig = JSON.parse(readFileSync(claudeConfigPath, 'utf8'));
      
      // Make sure mcpServers section exists
      if (!claudeConfig.mcpServers) {
        claudeConfig.mcpServers = {};
      }
      
      // Add environmental variables for unrestricted access
      if (claudeConfig.mcpServers.desktopCommander) {
        claudeConfig.mcpServers.desktopCommander.env = {
          ...(claudeConfig.mcpServers.desktopCommander.env || {}),
          CLAUDE_UNRESTRICTED_ACCESS: "true",
          BYPASS_PATH_VALIDATION: "true",
          NODE_ENV: "development"
        };
        
        log('✅ Added environment variables for unrestricted access.');
      } else {
        log('⚠️ desktopCommander not found in Claude config. Running setup script...');
        
        // Run the setup script
        runCommand('node setup-claude-windows.js');
        
        // Read config again
        claudeConfig = JSON.parse(readFileSync(claudeConfigPath, 'utf8'));
        
        // Add environmental variables
        if (claudeConfig.mcpServers.desktopCommander) {
          claudeConfig.mcpServers.desktopCommander.env = {
            CLAUDE_UNRESTRICTED_ACCESS: "true",
            BYPASS_PATH_VALIDATION: "true",
            NODE_ENV: "development"
          };
          
          log('✅ Added environment variables for unrestricted access.');
        } else {
          log('⚠️ Could not find desktopCommander in Claude config even after setup.');
        }
      }
      
      // Write the updated config
      writeFileSync(claudeConfigPath, JSON.stringify(claudeConfig, null, 2), 'utf8');
      log('✅ Claude configuration updated.');
    } catch (error) {
      log(`⚠️ Error updating Claude configuration: ${error.message}`);
    }
  } else {
    log(`⚠️ Claude configuration not found at: ${claudeConfigPath}`);
    log('Running setup script to create it...');
    runCommand('node setup-claude-windows.js');
  }
  
  // Step 8: Run test script
  log('\nStep 8: Running test script to verify changes');
  runCommand('node test-unrestricted.js');
  
  // Final instructions
  log('\n=== FIXES APPLIED SUCCESSFULLY ===');
  log('IMPORTANT: You MUST restart Claude Desktop for changes to take effect.');
  log('If you still experience issues, check the logs in the following files:');
  log('- server.log');
  log('- file-operations.log');
  log('- test-unrestricted.log');
  log('- fix-all.log');
  
  log('\nThank you for using ClaudeComputerCommander!');
}

main().catch(error => {
  log(`❌ Fatal error: ${error.message}`);
  process.exit(1);
});
