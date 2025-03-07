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
 * With improved handling for USERNAME specifically
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
            
            // Log the full parsed config (careful with large configs)
            logToFile(`Parsed config: ${JSON.stringify(config, null, 2)}`);
            
            return config;
        }
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error loading config: ${errorMessage}`);
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
    
    logToFile(`System username: ${os.userInfo().username}`);
    logToFile(`USERNAME env: ${process.env.USERNAME || 'not set'}`);
    logToFile(`USER env: ${process.env.USER || 'not set'}`);
    
    if (Array.isArray(config.allowedDirectories)) {
        // Legacy format - array of directories
        dirs = config.allowedDirectories;
        logToFile(`Using legacy array format for directories: ${JSON.stringify(dirs)}`);
    } else if (config.allowedDirectories && typeof config.allowedDirectories === 'object') {
        // New format - platform-specific directories
        const platform = process.platform;
        
        logToFile(`Current platform: ${platform}`);
        
        if (config.allowedDirectories[platform]) {
            dirs = config.allowedDirectories[platform];
            logToFile(`Using platform-specific directories for ${platform}: ${JSON.stringify(dirs)}`);
        } else {
            // Try to use any available platform set
            const availablePlatforms = Object.keys(config.allowedDirectories);
            if (availablePlatforms.length > 0) {
                const fallbackPlatform = availablePlatforms[0];
                dirs = config.allowedDirectories[fallbackPlatform];
                logToFile(`Platform ${platform} not found in config. Using ${fallbackPlatform} as fallback: ${JSON.stringify(dirs)}`);
            } else {
                // Fallback to default
                dirs = DEFAULT_ALLOWED_DIRECTORIES;
                logToFile(`No platforms defined in config. Using defaults: ${JSON.stringify(dirs)}`);
            }
        }
    } else {
        // No configuration, use defaults
        dirs = DEFAULT_ALLOWED_DIRECTORIES;
        logToFile(`No allowedDirectories in config. Using defaults: ${JSON.stringify(dirs)}`);
    }
    
    // Add the default allowed directories to ensure basic functionality
    dirs = [...dirs, ...DEFAULT_ALLOWED_DIRECTORIES];
    dirs = [...new Set(dirs)]; // Remove duplicates
    
    // Always add current directory and home directory for safety
    const criticalDirs = [process.cwd(), os.homedir()];
    for (const dir of criticalDirs) {
        if (!dirs.includes(dir)) {
            dirs.push(dir);
        }
    }
    
    // Process each directory path
    dirs = dirs.map(dir => {
        logToFile(`Processing directory before expansion: ${dir}`);
        
        // Expand Windows environment variables - more aggressive approach
        if (process.platform === 'win32') {
            if (dir.includes('%')) {
                const expanded = expandEnvVars(dir);
                logToFile(`Expanded Windows env vars: ${dir} → ${expanded}`);
                dir = expanded;
            }
            
            // Special handling for explicit C:\\Users\\USERNAME patterns
            // This helps with manually typed paths where USERNAME isn't in % signs
            const usernamePattern = /C:\\Users\\([^\\]+)(\\|$)/i;
            const match = dir.match(usernamePattern);
            if (match && match[1].toUpperCase() === 'USERNAME') {
                const username = process.env.USERNAME || process.env.USER || os.userInfo().username;
                dir = dir.replace(usernamePattern, `C:\\Users\\${username}$2`);
                logToFile(`Replaced hardcoded USERNAME: ${dir}`);
            }
        }
        
        // Handle current directory
        if (dir === '.' || dir === './') {
            const cwd = process.cwd();
            logToFile(`Expanded current directory: ${dir} → ${cwd}`);
            return cwd;
        }
        
        // Handle home directory
        if (dir.startsWith('~/') || dir === '~') {
            const home = path.normalize(dir.replace(/^~/, os.homedir()));
            logToFile(`Expanded home directory: ${dir} → ${home}`);
            return home;
        }
        
        // Handle relative paths
        if (dir.startsWith('./')) {
            const resolved = path.resolve(process.cwd(), dir.slice(2));
            logToFile(`Expanded relative path: ${dir} → ${resolved}`);
            return resolved;
        }
        
        // Make sure all paths are absolute and normalized
        const normalized = path.normalize(dir);
        const absolute = path.isAbsolute(normalized) ? normalized : path.resolve(process.cwd(), normalized);
        logToFile(`Final normalized absolute path: ${absolute}`);
        return absolute;
    });
    
    // Log the final list
    logToFile(`Final allowed directories for platform ${process.platform}:`);
    dirs.forEach((dir, i) => logToFile(`  ${i+1}. ${dir}`));
    
    return dirs;
}
