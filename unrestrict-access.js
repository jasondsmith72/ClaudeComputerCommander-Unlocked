#!/usr/bin/env node

// This script removes all filesystem restrictions in Claude Computer Commander

import fs from 'fs';
import path from 'path';
import { homedir, platform } from 'os';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Define path to configuration
const CONFIG_FILE = path.join(process.cwd(), 'config.json');
const LOG_FILE = path.join(process.cwd(), 'unrestrict-access.log');

// Helper function to log to file and console
function log(message) {
  const timestamp = new Date().toISOString();
  const logMessage = `${timestamp} - ${message}\n`;
  
  try {
    fs.appendFileSync(LOG_FILE, logMessage);
    console.log(message);
  } catch (err) {
    console.error(`Failed to write to log file: ${err.message}`);
  }
}

// Function to get the current username
function getUsername() {
  if (platform() === 'win32') {
    return process.env.USERNAME || process.env.USER || path.basename(homedir());
  } else {
    return process.env.USER || path.basename(homedir());
  }
}

async function main() {
  log('Starting unrestrict-access script...');
  
  // 1. Determine if we're running as Administrator
  const username = getUsername();
  log(`Current username: ${username}`);
  const isAdmin = username.toLowerCase() === 'administrator';
  log(`Running as Administrator: ${isAdmin}`);
  
  // 2. Create unrestricted config content
  let configContent = {};
  
  if (isAdmin) {
    log('Creating config for Administrator account');
    configContent = {
      "blockedCommands": [
        "format", "mount", "umount", "mkfs", "fdisk", "dd", 
        "sudo", "su", "passwd", "adduser", "useradd", "usermod", "groupadd"
      ],
      "allowedDirectories": [
        "C:\\",
        "C:\\Users",
        "C:\\Users\\Administrator",
        "C:\\Users\\Administrator\\Desktop",
        "C:\\Users\\Administrator\\Documents",
        "C:\\Users\\Administrator\\Downloads",
        "C:\\Users\\Administrator\\AppData",
        "C:\\Users\\Administrator\\AppData\\Local",
        "C:\\Users\\Administrator\\AppData\\Local\\AnthropicClaude",
        "C:\\Program Files",
        "C:\\Program Files (x86)",
        "C:\\Windows",
        "D:\\",
        "E:\\",
        "F:\\",
        "~",
        "."
      ]
    };
  } else {
    log('Creating general unrestricted config');
    configContent = {
      "blockedCommands": [
        "format", "mount", "umount", "mkfs", "fdisk", "dd", 
        "sudo", "su", "passwd", "adduser", "useradd", "usermod", "groupadd"
      ],
      "allowedDirectories": platform() === 'win32' ?
        // Windows drives
        [
          "C:\\", "D:\\", "E:\\", "F:\\", "G:\\", "H:\\", "I:\\", "J:\\",
          "K:\\", "L:\\", "M:\\", "N:\\", "O:\\", "P:\\", "Q:\\", "R:\\", 
          "S:\\", "T:\\", "U:\\", "V:\\", "W:\\", "X:\\", "Y:\\", "Z:\\",
          "~", "."
        ] :
        // Unix root
        [
          "/",
          "~",
          "."
        ]
    };
  }
  
  // 3. Backup existing config if present
  if (fs.existsSync(CONFIG_FILE)) {
    const backupFile = `${CONFIG_FILE}.backup-${new Date().toISOString().replace(/:/g, '-')}`;
    try {
      fs.copyFileSync(CONFIG_FILE, backupFile);
      log(`Backed up existing config to ${backupFile}`);
    } catch (err) {
      log(`Warning: Failed to backup config file: ${err.message}`);
    }
  }
  
  // 4. Write new unrestricted config
  try {
    fs.writeFileSync(CONFIG_FILE, JSON.stringify(configContent, null, 2), 'utf8');
    log(`Successfully wrote unrestricted config to ${CONFIG_FILE}`);
  } catch (err) {
    log(`Error: Failed to write config file: ${err.message}`);
    process.exit(1);
  }
  
  log('✅ All filesystem restrictions have been removed!');
  log('Please restart the Claude Desktop application to apply these changes.');
}

main().catch(error => {
  log(`Error: ${error.message}`);
  process.exit(1);
});
