import fs from "fs/promises";
import path from "path";
import os from 'os';
import { getAllowedDirectories } from "../config.js";
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

// Security utilities
export async function validatePath(requestedPath: string): Promise<string> {
    // Get the allowed directories from config
    const allowedDirectories = getAllowedDirectories();
    
    // Log for debugging
    logToFile(`Validating path: ${requestedPath}`);
    logToFile(`Against allowed directories: ${JSON.stringify(allowedDirectories)}`);
    
    const expandedPath = expandHome(requestedPath);
    const absolute = path.isAbsolute(expandedPath)
        ? path.resolve(expandedPath)
        : path.resolve(process.cwd(), expandedPath);
    
    // Perform case-insensitive path comparison on Windows, case-sensitive elsewhere
    const isWindows = process.platform === 'win32';
    
    // Log the absolute path we're checking
    logToFile(`Absolute path to check: ${absolute}`);
    
    // Check if path is within allowed directories
    let isAllowed = false;
    for (const dir of allowedDirectories) {
        const normalizedDir = normalizePath(dir);
        const normalizedPath = isWindows ? 
            absolute.toLowerCase() : 
            absolute;
        const normalizedAllowed = isWindows ? 
            normalizedDir.toLowerCase() : 
            normalizedDir;
        
        if (normalizedPath === normalizedAllowed || normalizedPath.startsWith(normalizedAllowed + path.sep)) {
            isAllowed = true;
            logToFile(`Path is allowed because it matches or is under: ${normalizedDir}`);
            break;
        }
    }
    
    if (!isAllowed) {
        logToFile(`Path access DENIED: ${absolute}`);
        throw new Error(`Access denied - path outside allowed directories: ${absolute}`);
    }

    // Handle symlinks by checking their real path
    try {
        const realPath = await fs.realpath(absolute);
        
        // Repeat the same check for the real path
        let isRealPathAllowed = false;
        for (const dir of allowedDirectories) {
            const normalizedDir = normalizePath(dir);
            const normalizedPath = isWindows ? 
                realPath.toLowerCase() : 
                realPath;
            const normalizedAllowed = isWindows ? 
                normalizedDir.toLowerCase() : 
                normalizedDir;
            
            if (normalizedPath === normalizedAllowed || normalizedPath.startsWith(normalizedAllowed + path.sep)) {
                isRealPathAllowed = true;
                logToFile(`Real path is allowed because it matches or is under: ${normalizedDir}`);
                break;
            }
        }
        
        if (!isRealPathAllowed) {
            logToFile(`Symlink target access DENIED: ${realPath}`);
            throw new Error("Access denied - symlink target outside allowed directories");
        }
        return realPath;
    } catch (error) {
        // For new files that don't exist yet, verify parent directory
        const parentDir = path.dirname(absolute);
        try {
            const realParentPath = await fs.realpath(parentDir);
            
            // Check if parent directory is allowed
            let isParentAllowed = false;
            for (const dir of allowedDirectories) {
                const normalizedDir = normalizePath(dir);
                const normalizedPath = isWindows ? 
                    realParentPath.toLowerCase() : 
                    realParentPath;
                const normalizedAllowed = isWindows ? 
                    normalizedDir.toLowerCase() : 
                    normalizedDir;
                
                if (normalizedPath === normalizedAllowed || normalizedPath.startsWith(normalizedAllowed + path.sep)) {
                    isParentAllowed = true;
                    logToFile(`Parent dir is allowed because it matches or is under: ${normalizedDir}`);
                    break;
                }
            }
            
            if (!isParentAllowed) {
                logToFile(`Parent directory access DENIED: ${realParentPath}`);
                throw new Error("Access denied - parent directory outside allowed directories");
            }
            return absolute;
        } catch (e) {
            logToFile(`Parent directory does not exist: ${parentDir}`);
            throw new Error(`Parent directory does not exist: ${parentDir}`);
        }
    }
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
