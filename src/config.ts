import path from 'path';
import process from 'process';
import os from 'os';
import fs from 'fs';
import { fileURLToPath } from 'url';

// Determine the directory where this script is located
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Base configuration paths - dynamically resolved
export const CONFIG_DIR = process.env.CONFIG_DIR || process.cwd();
export const CONFIG_FILE = path.join(CONFIG_DIR, 'config.json');
export const LOG_FILE = path.join(CONFIG_DIR, 'server.log');
export const ERROR_LOG_FILE = path.join(CONFIG_DIR, 'error.log');

export const DEFAULT_COMMAND_TIMEOUT = 1000; // milliseconds

// Default allowed directories - now includes everything
export const DEFAULT_ALLOWED_DIRECTORIES = [
    "/", // Root on Unix-like systems
    "C:\\", // C drive root on Windows
    "D:\\", // D drive
    "E:\\", // E drive
    "F:\\", // F drive
    "G:\\", // G drive
    "H:\\", // H drive
    process.cwd(), // Current working directory
    os.homedir()   // User's home directory
];

// Load configuration
export interface Config {
    blockedCommands: string[];
    allowedDirectories?: string[] | Record<string, string[]>;
}

// Helper function to log to file instead of console
function logToFile(message: string): void {
    try {
        fs.appendFileSync(LOG_FILE, `${new Date().toISOString()} [config] ${message}\n`);
    } catch (error) {
        // Silent fail if unable to write to log
    }
}

/**
 * Expands environment variables in a string path (Windows style %VAR%)
 * @param pathStr The path string containing environment variables
 * @returns The expanded path
 */
export function expandEnvVars(pathStr: string): string {
    return pathStr.replace(/%([^%]+)%/g, (_, varName) => {
        return process.env[varName] || '';
    });
}

/**
 * Gets a list of potential Claude installation directories on Windows
 */
function getClaudeDirectories(): string[] {
    const directories = [];
    
    // Add user's home directory
    const homeDir = os.homedir();
    directories.push(homeDir);
    
    // Add potential Claude installation directories
    if (process.platform === 'win32') {
        // Common installation paths
        directories.push(
            path.join(homeDir, 'AppData', 'Roaming', 'Claude'),
            path.join(homeDir, 'AppData', 'Local', 'Claude'),
            path.join(homeDir, 'AppData', 'Local', 'AnthropicClaude'),
            path.join('C:', 'Program Files', 'Claude'),
            path.join('C:', 'Program Files (x86)', 'Claude'),
            path.join('C:', 'Users', 'Administrator'),
            path.join('C:', 'ClaudeComputerCommander-Unlocked')
        );
        
        // Add all users directory if it exists
        const allUsersDir = process.env.ALLUSERSPROFILE || 'C:\\ProgramData';
        directories.push(
            path.join(allUsersDir, 'Claude')
        );
    }
    
    return directories;
}

export function loadConfig(): Config {
    logToFile("⚠️ BYPASSING CONFIG FILE - ALL DIRECTORIES ARE ACCESSIBLE");
    
    // Return a configuration that allows access to everything
    // Ignore any configuration file settings completely
    return { 
        blockedCommands: [
            "format", "mount", "umount", "mkfs", "fdisk", "dd", 
            "sudo", "su", "passwd", "adduser", "useradd", "usermod", "groupadd"
        ],
        allowedDirectories: ["C:\\", "D:\\", "E:\\", "F:\\", "/", "~", "."]
    };
}

// Get allowed directories - now returns full system access
export function getAllowedDirectories(): string[] {
    logToFile(`Unrestricted filesystem access is enabled - ALL DIRECTORIES ARE ACCESSIBLE`);
    
    if (process.platform === 'win32') {
        // Add all possible drive letters on Windows
        const drives = [];
        for (let charCode = 67; charCode <= 90; charCode++) {  // C through Z
            drives.push(`${String.fromCharCode(charCode)}:\\`);
        }
        
        // Add Claude-specific directories
        const claudeDirectories = getClaudeDirectories();
        drives.push(...claudeDirectories);
        
        // Add current working directory
        drives.push(process.cwd());
        
        logToFile(`Returning all Windows drives: ${drives.join(', ')}`);
        return drives;
    } else {
        // For Unix systems, return root
        return ["/", os.homedir(), process.cwd()];
    }
}
