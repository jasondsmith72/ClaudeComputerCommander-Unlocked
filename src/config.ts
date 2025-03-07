import path from 'path';
import process from 'process';
import os from 'os';
import fs from 'fs';

export const CONFIG_FILE = path.join(process.cwd(), 'config.json');
export const LOG_FILE = path.join(process.cwd(), 'server.log');
export const ERROR_LOG_FILE = path.join(process.cwd(), 'error.log');
export const ACCESS_LOG_FILE = path.join(process.cwd(), 'access.log');
export const COMMAND_LOG_FILE = path.join(process.cwd(), 'command.log');

export const DEFAULT_COMMAND_TIMEOUT = 1000; // milliseconds

// Default allowed directories
export const DEFAULT_ALLOWED_DIRECTORIES = [
    process.cwd(), // Current working directory
    os.homedir()   // User's home directory
];

// Permission types
export enum PermissionType {
    READ_ONLY = 'read_only',
    READ_WRITE = 'read_write',
    FULL_ACCESS = 'full_access'
}

// Access control for directories
export interface DirectoryPermission {
    path: string;
    permission: PermissionType;
}

// Load configuration
export interface Config {
    blockedCommands: string[];
    allowedDirectories?: string[];
    directoryPermissions?: DirectoryPermission[];
    limitCommandOutput?: number; // Limit the output size from commands in KB
    enableLogging?: boolean;     // Enable detailed logging of all operations
    securityLevel?: 'low' | 'medium' | 'high'; // Security level setting
    backupFrequency?: number;    // How often to backup config and logs (days)
    commandAliases?: Record<string, string>; // Custom command aliases
}

// Convert legacy allowedDirectories to the new directoryPermissions format
function convertLegacyDirectories(dirs: string[]): DirectoryPermission[] {
    return dirs.map(dir => ({
        path: dir,
        permission: PermissionType.FULL_ACCESS // Default to full access for backward compatibility
    }));
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
            
            // Handle legacy allowedDirectories configuration
            if (config.allowedDirectories && !config.directoryPermissions) {
                // Convert legacy format to new format
                config.directoryPermissions = convertLegacyDirectories(config.allowedDirectories);
            }
            
            // If we have directory permissions, expand any paths with ~
            if (config.directoryPermissions) {
                config.directoryPermissions = config.directoryPermissions.map(dirPerm => ({
                    path: expandPath(dirPerm.path),
                    permission: dirPerm.permission
                }));
            }
            
            // If we have allowed directories, expand any paths with ~
            if (config.allowedDirectories) {
                config.allowedDirectories = config.allowedDirectories.map(dir => expandPath(dir));
            }

            // Set default values for new properties
            if (config.securityLevel === undefined) {
                config.securityLevel = 'medium';
            }
            
            if (config.enableLogging === undefined) {
                config.enableLogging = true;
            }
            
            if (config.limitCommandOutput === undefined) {
                config.limitCommandOutput = 1024; // Default to 1MB
            }
            
            if (config.backupFrequency === undefined) {
                config.backupFrequency = 7; // Default to weekly
            }
            
            if (config.commandAliases === undefined) {
                config.commandAliases = {};
            }
            
            return config;
        }
    } catch (error) {
        console.error('Error loading config:', error);
    }
    
    // Return default config if loading fails
    return { 
        blockedCommands: [],
        allowedDirectories: DEFAULT_ALLOWED_DIRECTORIES,
        directoryPermissions: DEFAULT_ALLOWED_DIRECTORIES.map(dir => ({
            path: dir,
            permission: PermissionType.FULL_ACCESS
        })),
        securityLevel: 'medium',
        enableLogging: true,
        limitCommandOutput: 1024,
        backupFrequency: 7,
        commandAliases: {}
    };
}

// Helper function to expand ~ to home directory
export function expandPath(dirPath: string): string {
    if (dirPath.startsWith('~')) {
        return dirPath.replace('~', os.homedir());
    }
    return dirPath;
}

// Get allowed directories from config or defaults
export function getAllowedDirectories(): string[] {
    const config = loadConfig();
    
    // If we have the new directoryPermissions format, use that
    if (config.directoryPermissions && config.directoryPermissions.length > 0) {
        return config.directoryPermissions.map(dirPerm => dirPerm.path);
    }
    
    // Otherwise use legacy allowedDirectories or defaults
    return config.allowedDirectories || DEFAULT_ALLOWED_DIRECTORIES;
}

// Check if a specific operation is allowed on a path
export function isOperationAllowed(filePath: string, operation: 'read' | 'write' | 'execute'): boolean {
    const config = loadConfig();
    
    // Handle case with no directory permissions (legacy config)
    if (!config.directoryPermissions || config.directoryPermissions.length === 0) {
        return true; // Default to allowed for backward compatibility
    }
    
    // Normalize paths for comparison
    const normalizedPath = path.normalize(filePath).toLowerCase();
    
    // Look for a matching permission
    for (const dirPerm of config.directoryPermissions) {
        const normalizedDir = path.normalize(dirPerm.path).toLowerCase();
        
        // Check if path is within this directory
        if (normalizedPath.startsWith(normalizedDir)) {
            switch (dirPerm.permission) {
                case PermissionType.READ_ONLY:
                    return operation === 'read';
                case PermissionType.READ_WRITE:
                    return operation === 'read' || operation === 'write';
                case PermissionType.FULL_ACCESS:
                    return true;
                default:
                    return false;
            }
        }
    }
    
    return false; // No matching directory found
}

// Log access attempts for security auditing
export function logAccess(operation: string, path: string, success: boolean): void {
    const config = loadConfig();
    
    if (!config.enableLogging) {
        return;
    }
    
    const timestamp = new Date().toISOString();
    const logMessage = `${timestamp} - ${operation} - ${path} - ${success ? 'SUCCESS' : 'DENIED'}\n`;
    
    try {
        fs.appendFileSync(ACCESS_LOG_FILE, logMessage);
    } catch (error) {
        console.error('Failed to write to access log:', error);
    }
}

// Log command execution for security auditing
export function logCommand(command: string, pid: number): void {
    const config = loadConfig();
    
    if (!config.enableLogging) {
        return;
    }
    
    const timestamp = new Date().toISOString();
    const logMessage = `${timestamp} - COMMAND - PID:${pid} - ${command}\n`;
    
    try {
        fs.appendFileSync(COMMAND_LOG_FILE, logMessage);
    } catch (error) {
        console.error('Failed to write to command log:', error);
    }
}

// Get command alias if exists
export function getCommandAlias(command: string): string {
    const config = loadConfig();
    if (config.commandAliases && config.commandAliases[command]) {
        return config.commandAliases[command];
    }
    return command; // Return original if no alias exists
}
