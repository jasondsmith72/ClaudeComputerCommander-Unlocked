import fs from "fs/promises";
import path from "path";
import os from 'os';
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

// Path validation - completely bypassed
export async function validatePath(requestedPath: string): Promise<string> {
    // Simply normalize the path without any validation
    logToFile(`Path requested (NO VALIDATION): ${requestedPath}`);
    
    // Handle home directory expansion
    let processedPath = requestedPath;
    if (processedPath.startsWith('~')) {
        processedPath = expandHome(processedPath);
    }
    
    // Handle environment variables on Windows
    if (process.platform === 'win32' && processedPath.includes('%')) {
        processedPath = processedPath.replace(/%([^%]+)%/g, (_, varName) => {
            return process.env[varName] || '';
        });
    }
    
    // Convert to absolute path
    const absolute = path.isAbsolute(processedPath)
        ? processedPath
        : path.resolve(process.cwd(), processedPath);
    
    logToFile(`Access GRANTED to path: ${absolute}`);
    return absolute;
}

// File operation tools
export async function readFile(filePath: string): Promise<string> {
    // No validation - direct file access
    try {
        const fullPath = path.isAbsolute(filePath) 
            ? filePath
            : path.resolve(process.cwd(), filePath);
        
        return await fs.readFile(fullPath, "utf-8");
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error reading file ${filePath}: ${errorMessage}`);
        throw error;
    }
}

export async function writeFile(filePath: string, content: string): Promise<void> {
    // No validation - direct file access
    try {
        const fullPath = path.isAbsolute(filePath)
            ? filePath
            : path.resolve(process.cwd(), filePath);
        
        // Ensure directory exists before writing
        const dirPath = path.dirname(fullPath);
        await fs.mkdir(dirPath, { recursive: true });
        
        await fs.writeFile(fullPath, content, "utf-8");
        logToFile(`Successfully wrote to file: ${fullPath}`);
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error writing to file ${filePath}: ${errorMessage}`);
        throw error;
    }
}

export async function readMultipleFiles(paths: string[]): Promise<string[]> {
    return Promise.all(
        paths.map(async (filePath: string) => {
            try {
                const fullPath = path.isAbsolute(filePath)
                    ? filePath
                    : path.resolve(process.cwd(), filePath);
                
                const content = await fs.readFile(fullPath, "utf-8");
                return `${filePath}:\n${content}\n`;
            } catch (error) {
                const errorMessage = error instanceof Error ? error.message : String(error);
                return `${filePath}: Error - ${errorMessage}`;
            }
        }),
    );
}

export async function createDirectory(dirPath: string): Promise<void> {
    // No validation - direct directory creation
    try {
        const fullPath = path.isAbsolute(dirPath)
            ? dirPath
            : path.resolve(process.cwd(), dirPath);
        
        await fs.mkdir(fullPath, { recursive: true });
        logToFile(`Successfully created directory: ${fullPath}`);
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error creating directory ${dirPath}: ${errorMessage}`);
        throw error;
    }
}

export async function listDirectory(dirPath: string): Promise<string[]> {
    // No validation - direct directory listing
    try {
        const fullPath = path.isAbsolute(dirPath)
            ? dirPath
            : path.resolve(process.cwd(), dirPath);
        
        const entries = await fs.readdir(fullPath, { withFileTypes: true });
        return entries.map((entry) => `${entry.isDirectory() ? "[DIR]" : "[FILE]"} ${entry.name}`);
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error listing directory ${dirPath}: ${errorMessage}`);
        throw error;
    }
}

export async function moveFile(sourcePath: string, destinationPath: string): Promise<void> {
    // No validation - direct file move
    try {
        const fullSourcePath = path.isAbsolute(sourcePath)
            ? sourcePath
            : path.resolve(process.cwd(), sourcePath);
            
        const fullDestPath = path.isAbsolute(destinationPath)
            ? destinationPath
            : path.resolve(process.cwd(), destinationPath);
        
        // Ensure destination directory exists
        const destDir = path.dirname(fullDestPath);
        await fs.mkdir(destDir, { recursive: true });
        
        await fs.rename(fullSourcePath, fullDestPath);
        logToFile(`Successfully moved file: ${fullSourcePath} → ${fullDestPath}`);
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error moving file ${sourcePath} to ${destinationPath}: ${errorMessage}`);
        throw error;
    }
}

export async function searchFiles(rootPath: string, pattern: string): Promise<string[]> {
    const results: string[] = [];
    const fullRootPath = path.isAbsolute(rootPath)
        ? rootPath
        : path.resolve(process.cwd(), rootPath);

    async function search(currentPath: string) {
        try {
            const entries = await fs.readdir(currentPath, { withFileTypes: true });

            for (const entry of entries) {
                const fullPath = path.join(currentPath, entry.name);
                
                if (entry.name.toLowerCase().includes(pattern.toLowerCase())) {
                    results.push(fullPath);
                }

                if (entry.isDirectory()) {
                    try {
                        await search(fullPath);
                    } catch (error) {
                        // Ignore errors in recursive search
                        logToFile(`Error searching subdirectory ${fullPath}: ${error}`);
                    }
                }
            }
        } catch (error) {
            logToFile(`Error searching directory ${currentPath}: ${error}`);
        }
    }

    await search(fullRootPath);
    return results;
}

export async function getFileInfo(filePath: string): Promise<Record<string, any>> {
    // No validation - direct file info retrieval
    try {
        const fullPath = path.isAbsolute(filePath)
            ? filePath
            : path.resolve(process.cwd(), filePath);
            
        const stats = await fs.stat(fullPath);
        
        return {
            size: stats.size,
            created: stats.birthtime,
            modified: stats.mtime,
            accessed: stats.atime,
            isDirectory: stats.isDirectory(),
            isFile: stats.isFile(),
            permissions: stats.mode.toString(8).slice(-3),
        };
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error getting file info for ${filePath}: ${errorMessage}`);
        throw error;
    }
}

export function listAllowedDirectories(): string[] {
    logToFile("⚠️ FULL FILESYSTEM ACCESS ENABLED - NO RESTRICTIONS");
    return ["ALL DIRECTORIES ARE ACCESSIBLE - No path restrictions are in place"];
}
