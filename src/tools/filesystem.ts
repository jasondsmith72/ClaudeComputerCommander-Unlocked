import fs from "fs/promises";
import path from "path";
import os from 'os';
import { getAllowedDirectories, expandEnvVars } from "../config.js";
import fsSync from "fs";

// Helper function to log to file instead of console
function logToFile(message: string): void {
    const logFile = path.join(process.cwd(), 'server.log');
    try {
        fsSync.appendFileSync(logFile, `${new Date().toISOString()} [filesystem] ${message}\n`);
    } catch (error) {
        // Silent fail if unable to write to log
    }
}

// Normalize all paths consistently
function normalizePath(p: string): string {
    return path.normalize(p);
}

function expandHome(filepath: string): string {
    if (filepath.startsWith('~/') || filepath === '~') {
        return path.join(os.homedir(), filepath.slice(1));
    }
    return filepath;
}

// Check if a path is within an allowed directory
function isPathAllowed(pathToCheck: string, allowedDirectories: string[]): boolean {
    const isWindows = process.platform === 'win32';
    
    // Case sensitivity handling
    const normalizedPath = isWindows ? pathToCheck.toLowerCase() : pathToCheck;
    
    for (const dir of allowedDirectories) {
        const normalizedDir = isWindows ? dir.toLowerCase() : dir;
        
        // Path equality check
        if (normalizedPath === normalizedDir) {
            logToFile(`Path is allowed - exact match: ${pathToCheck} = ${dir}`);
            return true;
        }
        
        // Path prefix check with directory separator
        // Ensure we have a directory separator at the end to avoid partial matches
        if (normalizedPath.startsWith(normalizedDir + path.sep)) {
            logToFile(`Path is allowed - subdirectory: ${pathToCheck} is under ${dir}`);
            return true;
        }
    }
    
    return false;
}

// Security utilities
export async function validatePath(requestedPath: string): Promise<string> {
    // Get the allowed directories from config
    const allowedDirectories = getAllowedDirectories();
    
    // Log for debugging
    logToFile(`Validating path: ${requestedPath}`);
    logToFile(`Against allowed directories: ${JSON.stringify(allowedDirectories)}`);
    
    // Special handling for Windows %USERNAME% if still present
    let processedPath = requestedPath;
    if (process.platform === 'win32' && processedPath.includes('%')) {
        processedPath = expandEnvVars(processedPath);
        logToFile(`Expanded environment variables: ${requestedPath} → ${processedPath}`);
    }
    
    // Handle home directory expansion
    const expandedPath = expandHome(processedPath);
    if (expandedPath !== processedPath) {
        logToFile(`Expanded home directory: ${processedPath} → ${expandedPath}`);
    }
    
    // Resolve to absolute path
    const absolute = path.isAbsolute(expandedPath)
        ? path.resolve(expandedPath)
        : path.resolve(process.cwd(), expandedPath);
    
    logToFile(`Absolute path to check: ${absolute}`);
    
    // Check if path is within allowed directories
    if (isPathAllowed(absolute, allowedDirectories)) {
        // Path is directly allowed
        return absolute;
    }
    
    // Before rejecting, check if the path is a symlink
    try {
        const realPath = await fs.realpath(absolute);
        logToFile(`Checked real path for symlink: ${absolute} → ${realPath}`);
        
        if (isPathAllowed(realPath, allowedDirectories)) {
            logToFile(`Real path is allowed: ${realPath}`);
            return realPath;
        }
    } catch (error) {
        // If the path doesn't exist yet, check its parent directory
        const parentDir = path.dirname(absolute);
        logToFile(`Checking parent directory: ${parentDir}`);
        
        try {
            const realParentPath = await fs.realpath(parentDir);
            logToFile(`Real parent path: ${realParentPath}`);
            
            if (isPathAllowed(realParentPath, allowedDirectories)) {
                logToFile(`Parent directory is allowed: ${realParentPath}`);
                return absolute; // Return the original absolute path
            }
            
            // Try one level higher if needed
            const grandparentDir = path.dirname(parentDir);
            if (grandparentDir !== parentDir) { // Avoid infinite loop at root
                logToFile(`Checking grandparent directory: ${grandparentDir}`);
                const realGrandparentPath = await fs.realpath(grandparentDir);
                
                if (isPathAllowed(realGrandparentPath, allowedDirectories)) {
                    logToFile(`Grandparent directory is allowed: ${realGrandparentPath}`);
                    return absolute; // Return the original absolute path
                }
            }
        } catch (e) {
            logToFile(`Error checking parent directory: ${e}`);
        }
    }
    
    // Check partial matches for debugging
    logToFile("Checking partial matches for debugging:");
    const normalizedPath = process.platform === 'win32' ? absolute.toLowerCase() : absolute;
    for (const dir of allowedDirectories) {
        const normalizedDir = process.platform === 'win32' ? dir.toLowerCase() : dir;
        if (normalizedPath.includes(normalizedDir) || normalizedDir.includes(normalizedPath)) {
            logToFile(`Partial match found: ${absolute} vs ${dir}`);
        }
    }
    
    // All checks failed - path is not allowed
    logToFile(`Path access DENIED: ${absolute}`);
    throw new Error(`Access denied - path outside allowed directories: ${absolute}`);
}

// File operation tools
export async function readFile(filePath: string): Promise<string> {
    const validPath = await validatePath(filePath);
    return fs.readFile(validPath, "utf-8");
}

export async function writeFile(filePath: string, content: string): Promise<void> {
    const validPath = await validatePath(filePath);
    await fs.writeFile(validPath, content, "utf-8");
}

export async function readMultipleFiles(paths: string[]): Promise<string[]> {
    return Promise.all(
        paths.map(async (filePath: string) => {
            try {
                const validPath = await validatePath(filePath);
                const content = await fs.readFile(validPath, "utf-8");
                return `${filePath}:\n${content}\n`;
            } catch (error) {
                const errorMessage = error instanceof Error ? error.message : String(error);
                return `${filePath}: Error - ${errorMessage}`;
            }
        }),
    );
}

export async function createDirectory(dirPath: string): Promise<void> {
    const validPath = await validatePath(dirPath);
    await fs.mkdir(validPath, { recursive: true });
}

export async function listDirectory(dirPath: string): Promise<string[]> {
    const validPath = await validatePath(dirPath);
    const entries = await fs.readdir(validPath, { withFileTypes: true });
    return entries.map((entry) => `${entry.isDirectory() ? "[DIR]" : "[FILE]"} ${entry.name}`);
}

export async function moveFile(sourcePath: string, destinationPath: string): Promise<void> {
    const validSourcePath = await validatePath(sourcePath);
    const validDestPath = await validatePath(destinationPath);
    await fs.rename(validSourcePath, validDestPath);
}

export async function searchFiles(rootPath: string, pattern: string): Promise<string[]> {
    const results: string[] = [];

    async function search(currentPath: string) {
        const entries = await fs.readdir(currentPath, { withFileTypes: true });

        for (const entry of entries) {
            const fullPath = path.join(currentPath, entry.name);
            
            try {
                await validatePath(fullPath);

                if (entry.name.toLowerCase().includes(pattern.toLowerCase())) {
                    results.push(fullPath);
                }

                if (entry.isDirectory()) {
                    await search(fullPath);
                }
            } catch (error) {
                continue;
            }
        }
    }

    const validPath = await validatePath(rootPath);
    await search(validPath);
    return results;
}

export async function getFileInfo(filePath: string): Promise<Record<string, any>> {
    const validPath = await validatePath(filePath);
    const stats = await fs.stat(validPath);
    
    return {
        size: stats.size,
        created: stats.birthtime,
        modified: stats.mtime,
        accessed: stats.atime,
        isDirectory: stats.isDirectory(),
        isFile: stats.isFile(),
        permissions: stats.mode.toString(8).slice(-3),
    };
}

export function listAllowedDirectories(): string[] {
    return getAllowedDirectories();
}
