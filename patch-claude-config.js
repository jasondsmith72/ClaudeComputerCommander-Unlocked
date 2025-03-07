#!/usr/bin/env node

// This script directly modifies the Claude Desktop configuration
// to grant unrestricted filesystem access

import { join } from 'path';
import { readFileSync, writeFileSync, existsSync, appendFileSync, copyFileSync } from 'fs';
import { platform } from 'os';

// Path to Claude config
const claudeConfigPath = join(
    process.env.APPDATA || '',  // Windows
    'Claude', 
    'claude_desktop_config.json'
);

// Create backup filename with timestamp
function getBackupFilename(originalPath) {
    const now = new Date();
    const timestamp = `${now.getFullYear()}.${(now.getMonth() + 1).toString().padStart(2, '0')}.${now.getDate().toString().padStart(2, '0')}-${now.getHours().toString().padStart(2, '0')}.${now.getMinutes().toString().padStart(2, '0')}`;
    const pathObj = originalPath.split('.');
    const extension = pathObj.pop();
    return `${pathObj.join('.')}-bk-${timestamp}.${extension}`;
}

// Setup logging
const LOG_FILE = join(process.cwd(), 'patch-claude-config.log');

function log(message, isError = false) {
    const timestamp = new Date().toISOString();
    const logMessage = `${timestamp} - ${isError ? 'ERROR: ' : ''}${message}\n`;
    try {
        appendFileSync(LOG_FILE, logMessage);
        // Also output to console
        console.log(isError ? `ERROR: ${message}` : message);
    } catch (err) {
        console.error(`Failed to write to log file: ${err.message}`);
    }
}

// Main function
async function main() {
    log('Starting Claude configuration patching...');
    
    // Check if Claude config exists
    if (!existsSync(claudeConfigPath)) {
        log(`Claude config not found at: ${claudeConfigPath}`, true);
        log('Please make sure Claude Desktop is installed and has been run at least once.');
        process.exit(1);
    }
    
    // Backup the config
    const backupPath = getBackupFilename(claudeConfigPath);
    try {
        copyFileSync(claudeConfigPath, backupPath);
        log(`Created backup of Claude config at: ${backupPath}`);
    } catch (err) {
        log(`Error creating backup: ${err.message}`, true);
        process.exit(1);
    }
    
    // Read the config
    let configContent;
    try {
        configContent = readFileSync(claudeConfigPath, 'utf8');
        log('Successfully read Claude configuration');
    } catch (err) {
        log(`Error reading Claude configuration: ${err.message}`, true);
        process.exit(1);
    }
    
    // Parse config
    let config;
    try {
        config = JSON.parse(configContent);
        log('Successfully parsed Claude configuration');
    } catch (err) {
        log(`Error parsing Claude configuration: ${err.message}`, true);
        process.exit(1);
    }
    
    // 1. Ensure mcpServers section exists
    if (!config.mcpServers) {
        config.mcpServers = {};
    }
    
    // 2. Update desktopCommander configuration
    if (config.mcpServers.desktopCommander) {
        // Get the current command and args
        const currentCommand = config.mcpServers.desktopCommander.command;
        const currentArgs = config.mcpServers.desktopCommander.args || [];
        
        log('Current desktopCommander configuration:');
        log(`- Command: ${currentCommand}`);
        log(`- Args: ${JSON.stringify(currentArgs)}`);
        
        // 3. Add permissive environmental variables
        config.mcpServers.desktopCommander.env = {
            ...(config.mcpServers.desktopCommander.env || {}),
            CLAUDE_UNRESTRICTED_ACCESS: "true",
            BYPASS_PATH_VALIDATION: "true",
            NODE_ENV: "development"
        };
        
        log('Added permissive environmental variables to desktopCommander');
    } else {
        log('desktopCommander not found in config - please run the setup script first', true);
        process.exit(1);
    }
    
    // 4. Write the updated config
    try {
        writeFileSync(claudeConfigPath, JSON.stringify(config, null, 2), 'utf8');
        log(`Successfully patched Claude configuration`);
    } catch (err) {
        log(`Error writing Claude configuration: ${err.message}`, true);
        process.exit(1);
    }
    
    // 5. Final instructions
    log('');
    log('✅ Successfully patched Claude Desktop configuration!');
    log('');
    log('IMPORTANT: You must now restart Claude Desktop for changes to take effect.');
    log('');
    log('If this still doesn\'t work, please try the following:');
    log('1. Uninstall and reinstall ClaudeComputerCommander');
    log('2. Run the setup-claude-windows.js script again');
    log('3. Run this patch script again');
    log('4. Restart Claude Desktop');
}

// Run the script
main().catch(err => {
    log(`Unhandled error: ${err.message}`, true);
    process.exit(1);
});
