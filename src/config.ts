import path from 'path';
import process from 'process';
import os from 'os';
import fs from 'fs';

export const CONFIG_FILE = path.join(process.cwd(), 'config.json');
export const LOG_FILE = path.join(process.cwd(), 'server.log');
export const ERROR_LOG_FILE = path.join(process.cwd(), 'error.log');

export const DEFAULT_COMMAND_TIMEOUT = 1000; // milliseconds

// Default allowed directories
export const DEFAULT_ALLOWED_DIRECTORIES = [
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
function expandEnvVars(pathStr: string): string {
    return pathStr.replace(/%([^%]+)%/g, (_, varName) => {
        return process.env[varName] || '';
    });
}

export function loadConfig(): Config {
    try {
        if (fs.existsSync(CONFIG_FILE)) {
            const configContent = fs.readFileSync(CONFIG_FILE, 'utf8');
            const config = JSON.parse(configContent) as Config;
            
            // Ensure config has required fields
            if (!config.blockedCommands) {
                config.blockedCommands = [];
            }
            
            return config;
        }
    } catch (error) {
        logToFile(`Error loading config: ${error}`);
    }
    
    // Return default config if loading fails
    return { 
        blockedCommands: [],
        allowedDirectories: DEFAULT_ALLOWED_DIRECTORIES
    };
}

// Get allowed directories from config or defaults
export function getAllowedDirectories(): string[] {
    const config = loadConfig();
    let dirs: string[] = [];
    
    if (Array.isArray(config.allowedDirectories)) {
        // Legacy format - array of directories
        dirs = config.allowedDirectories;
    } else if (config.allowedDirectories && typeof config.allowedDirectories === 'object') {
        // New format - platform-specific directories
        const platform = process.platform;
        
        if (config.allowedDirectories[platform]) {
            dirs = config.allowedDirectories[platform];
        } else {
            // Fallback to default
            dirs = DEFAULT_ALLOWED_DIRECTORIES;
        }
    } else {
        // No configuration, use defaults
        dirs = DEFAULT_ALLOWED_DIRECTORIES;
    }
    
    // Process each directory path
    dirs = dirs.map(dir => {
        // Expand Windows environment variables
        if (process.platform === 'win32' && dir.includes('%')) {
            dir = expandEnvVars(dir);
        }
        
        // Handle current directory
        if (dir === '.' || dir === './') {
            return process.cwd();
        }
        
        // Handle home directory
        if (dir.startsWith('~/') || dir === '~') {
            return path.normalize(dir.replace(/^~/, os.homedir()));
        }
        
        // Handle relative paths
        if (dir.startsWith('./')) {
            return path.resolve(process.cwd(), dir.slice(2));
        }
        
        // Make sure all paths are absolute
        return path.resolve(dir);
    });
    
    // Log to file
    logToFile(`Returning allowed directories for platform ${process.platform}: ${JSON.stringify(dirs)}`);
    
    return dirs;
}
