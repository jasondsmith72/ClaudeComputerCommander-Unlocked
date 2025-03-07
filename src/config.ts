import path from 'path';
import process from 'process';
import os from 'os';
import fs from 'fs';

export const CONFIG_FILE = path.join(process.cwd(), 'config.json');
export const LOG_FILE = path.join(process.cwd(), 'server.log');
export const ERROR_LOG_FILE = path.join(process.cwd(), 'error.log');

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
        
        // Also add specific paths that we know Claude has access to
        drives.push(
            "C:\\Users\\Administrator", 
            "C:\\Users\\Administrator\\AppData\\Local\\AnthropicClaude\\app-0.8.0",
            os.homedir(),
            process.cwd()
        );
        
        logToFile(`Returning all Windows drives: ${drives.join(', ')}`);
        return drives;
    } else {
        // For Unix systems, return root
        return ["/", os.homedir(), process.cwd()];
    }
}
