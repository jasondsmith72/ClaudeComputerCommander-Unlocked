import path from 'path';
import process from 'process';
import os from 'os';
import fs from 'fs';

export const CONFIG_FILE = path.join(process.cwd(), 'config.json');
export const LOG_FILE = path.join(process.cwd(), 'server.log');
export const ERROR_LOG_FILE = path.join(process.cwd(), 'error.log');

export const DEFAULT_COMMAND_TIMEOUT = 1000; // milliseconds

// Default allowed directories - now we'll allow access to all drives
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
    // Special handling for %USERNAME% which is commonly used
    if (pathStr.includes('%USERNAME%')) {
        const username = process.env.USERNAME || process.env.USER || os.userInfo().username;
        logToFile(`Expanding %USERNAME% to: ${username}`);
        pathStr = pathStr.replace(/%USERNAME%/g, username);
    }
    
    // General environment variable expansion
    return pathStr.replace(/%([^%]+)%/g, (_, varName) => {
        const value = process.env[varName] || '';
        logToFile(`Expanding %${varName}% to: ${value}`);
        return value;
    });
}

export function loadConfig(): Config {
    try {
        if (fs.existsSync(CONFIG_FILE)) {
            const configContent = fs.readFileSync(CONFIG_FILE, 'utf8');
            logToFile(`Loaded raw config content: ${configContent.slice(0, 200)}...`);
            
            const config = JSON.parse(configContent) as Config;
            
            // Ensure config has required fields
            if (!config.blockedCommands) {
                config.blockedCommands = [];
            }
            
            // Always allow full filesystem access
            config.allowedDirectories = DEFAULT_ALLOWED_DIRECTORIES;
            
            // Log the full parsed config
            logToFile(`Using unrestricted filesystem access configuration`);
            
            return config;
        }
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error loading config: ${errorMessage}`);
    }
    
    // Return default config with unrestricted access if loading fails
    return { 
        blockedCommands: [],
        allowedDirectories: DEFAULT_ALLOWED_DIRECTORIES
    };
}

// Get allowed directories from config or defaults - now always returns unrestricted access
export function getAllowedDirectories(): string[] {
    logToFile(`Using unrestricted filesystem access. All drives and folders are accessible.`);
    
    // Return a list of root paths for all possible drive letters on Windows
    if (process.platform === 'win32') {
        const drives = [];
        // Add all possible drive letters
        for (let charCode = 65; charCode <= 90; charCode++) {
            const driveLetter = String.fromCharCode(charCode);
            drives.push(`${driveLetter}:\\`);
        }
        logToFile(`Windows detected - allowing access to all drives: ${drives.join(', ')}`);
        return drives;
    }
    
    // For Unix-like systems (Linux, macOS), allow access to root
    logToFile(`Unix-like system detected - allowing access to root directory /`);
    return ["/"];
}
