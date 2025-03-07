import fs from "fs/promises";
import path from "path";
import os from 'os';
import { getAllowedDirectories, isOperationAllowed, logAccess } from "../config.js";

// Normalize all paths consistently
function normalizePath(p: string): string {
    return path.normalize(p).toLowerCase();
}

function expandHome(filepath: string): string {
    if (filepath.startsWith('~/') || filepath === '~') {
        return path.join(os.homedir(), filepath.slice(1));
    }
    return filepath;
}

// Security utilities
export async function validatePath(requestedPath: string, operation: 'read' | 'write' | 'execute' = 'read'): Promise<string> {
    // Get the allowed directories from config
    const allowedDirectories = getAllowedDirectories();
    
    const expandedPath = expandHome(requestedPath);
    const absolute = path.isAbsolute(expandedPath)
        ? path.resolve(expandedPath)
        : path.resolve(process.cwd(), expandedPath);
        
    const normalizedRequested = normalizePath(absolute);

    // Check if path is within allowed directories
    const isAllowed = allowedDirectories.some(dir => normalizedRequested.startsWith(normalizePath(dir)));
    if (!isAllowed) {
        logAccess(operation, absolute, false);
        throw new Error(`Access denied - path outside allowed directories: ${absolute}`);
    }

    // Check if the specific operation is allowed
    if (!isOperationAllowed(absolute, operation)) {
        logAccess(operation, absolute, false);
        throw new Error(`Access denied - ${operation} operation not permitted for: ${absolute}`);
    }

    // Handle symlinks by checking their real path
    try {
        const realPath = await fs.realpath(absolute);
        const normalizedReal = normalizePath(realPath);
        const isRealPathAllowed = allowedDirectories.some(dir => normalizedReal.startsWith(normalizePath(dir)));
        if (!isRealPathAllowed) {
            logAccess(operation, realPath, false);
            throw new Error("Access denied - symlink target outside allowed directories");
        }
        
        // Check if the operation is allowed on the real path
        if (!isOperationAllowed(realPath, operation)) {
            logAccess(operation, realPath, false);
            throw new Error(`Access denied - ${operation} operation not permitted for symlink target: ${realPath}`);
        }
        
        logAccess(operation, realPath, true);
        return realPath;
    } catch (error) {
        // For new files that don't exist yet, verify parent directory
        const parentDir = path.dirname(absolute);
        try {
            const realParentPath = await fs.realpath(parentDir);
            const normalizedParent = normalizePath(realParentPath);
            const isParentAllowed = allowedDirectories.some(dir => normalizedParent.startsWith(normalizePath(dir)));
            if (!isParentAllowed) {
                logAccess(operation, parentDir, false);
                throw new Error("Access denied - parent directory outside allowed directories");
            }
            
            // Check if write operation is allowed on parent directory for file creation
            if (operation === 'write' && !isOperationAllowed(realParentPath, 'write')) {
                logAccess('write', parentDir, false);
                throw new Error(`Access denied - write operation not permitted for parent directory: ${parentDir}`);
            }
            
            logAccess(operation, absolute, true);
            return absolute;
        } catch {
            throw new Error(`Parent directory does not exist: ${parentDir}`);
        }
    }
}

// File operation tools
export async function readFile(filePath: string): Promise<string> {
    const validPath = await validatePath(filePath, 'read');
    return fs.readFile(validPath, "utf-8");
}

export async function writeFile(filePath: string, content: string): Promise<void> {
    const validPath = await validatePath(filePath, 'write');
    await fs.writeFile(validPath, content, "utf-8");
}

export async function readMultipleFiles(paths: string[]): Promise<string[]> {
    return Promise.all(
        paths.map(async (filePath: string) => {
            try {
                const validPath = await validatePath(filePath, 'read');
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
    const validPath = await validatePath(dirPath, 'write');
    await fs.mkdir(validPath, { recursive: true });
}

export async function listDirectory(dirPath: string): Promise<string[]> {
    const validPath = await validatePath(dirPath, 'read');
    const entries = await fs.readdir(validPath, { withFileTypes: true });
    return entries.map((entry) => `${entry.isDirectory() ? "[DIR]" : "[FILE]"} ${entry.name}`);
}

export async function moveFile(sourcePath: string, destinationPath: string): Promise<void> {
    // Check both read permissions on source and write permissions on destination
    const validSourcePath = await validatePath(sourcePath, 'read');
    const validDestPath = await validatePath(destinationPath, 'write');
    await fs.rename(validSourcePath, validDestPath);
}

export async function searchFiles(rootPath: string, pattern: string): Promise<string[]> {
    const results: string[] = [];

    async function search(currentPath: string) {
        const entries = await fs.readdir(currentPath, { withFileTypes: true });

        for (const entry of entries) {
            const fullPath = path.join(currentPath, entry.name);
            
            try {
                await validatePath(fullPath, 'read');

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

    const validPath = await validatePath(rootPath, 'read');
    await search(validPath);
    return results;
}

export async function getFileInfo(filePath: string): Promise<Record<string, any>> {
    const validPath = await validatePath(filePath, 'read');
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

// Check if a file is readable
export async function isReadable(filePath: string): Promise<boolean> {
    try {
        await validatePath(filePath, 'read');
        return true;
    } catch (error) {
        return false;
    }
}

// Check if a file is writable
export async function isWritable(filePath: string): Promise<boolean> {
    try {
        await validatePath(filePath, 'write');
        return true;
    } catch (error) {
        return false;
    }
}

// Copy a file with permission validation
export async function copyFile(sourcePath: string, destinationPath: string): Promise<void> {
    const validSourcePath = await validatePath(sourcePath, 'read');
    const validDestPath = await validatePath(destinationPath, 'write');
    
    // Read the source file
    const content = await fs.readFile(validSourcePath);
    
    // Write to the destination
    await fs.writeFile(validDestPath, content);
}

// Delete a file with permission validation
export async function deleteFile(filePath: string): Promise<void> {
    const validPath = await validatePath(filePath, 'write');
    await fs.unlink(validPath);
}

// Check file existence
export async function fileExists(filePath: string): Promise<boolean> {
    try {
        const validPath = await validatePath(filePath, 'read');
        await fs.access(validPath);
        return true;
    } catch (error) {
        return false;
    }
}

// Get disk space information
export async function getDiskSpace(dirPath: string): Promise<{ free: number, total: number }> {
    const validPath = await validatePath(dirPath, 'read');
    
    try {
        // This will depend on the OS - simplified implementation
        if (process.platform === 'win32') {
            // On Windows, could use a child process to run wmic
            return { free: 0, total: 0 }; // Placeholder
        } else {
            // On Unix, could use a child process to run df
            return { free: 0, total: 0 }; // Placeholder
        }
    } catch (error) {
        throw new Error(`Failed to get disk space info: ${error}`);
    }
}
