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

// Security utilities - now completely bypassed to allow full access
export async function validatePath(requestedPath: string): Promise<string> {
    // Log request for debugging
    logToFile(`Validating path (all access allowed): ${requestedPath}`);
    
    // Expand environment variables if needed
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
    
    logToFile(`Absolute path (access granted): ${absolute}`);
    
    // No validation is performed - all paths are allowed
    return absolute;
}

// File operation tools
export async function readFile(filePath: string): Promise<string> {
    const validPath = await validatePath(filePath);
    try {
        return await fs.readFile(validPath, "utf-8");
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error reading file ${validPath}: ${errorMessage}`);
        throw error;
    }
}

export async function writeFile(filePath: string, content: string): Promise<void> {
    const validPath = await validatePath(filePath);
    try {
        // Ensure directory exists before writing
        const dirPath = path.dirname(validPath);
        await fs.mkdir(dirPath, { recursive: true });
        await fs.writeFile(validPath, content, "utf-8");
        logToFile(`Successfully wrote to file: ${validPath}`);
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error writing to file ${validPath}: ${errorMessage}`);
        throw error;
    }
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
    try {
        await fs.mkdir(validPath, { recursive: true });
        logToFile(`Successfully created directory: ${validPath}`);
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error creating directory ${validPath}: ${errorMessage}`);
        throw error;
    }
}

export async function listDirectory(dirPath: string): Promise<string[]> {
    const validPath = await validatePath(dirPath);
    try {
        const entries = await fs.readdir(validPath, { withFileTypes: true });
        return entries.map((entry) => `${entry.isDirectory() ? "[DIR]" : "[FILE]"} ${entry.name}`);
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error listing directory ${validPath}: ${errorMessage}`);
        throw error;
    }
}

export async function moveFile(sourcePath: string, destinationPath: string): Promise<void> {
    const validSourcePath = await validatePath(sourcePath);
    const validDestPath = await validatePath(destinationPath);
    
    try {
        // Ensure destination directory exists
        const destDir = path.dirname(validDestPath);
        await fs.mkdir(destDir, { recursive: true });
        
        await fs.rename(validSourcePath, validDestPath);
        logToFile(`Successfully moved file: ${validSourcePath} → ${validDestPath}`);
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error moving file ${validSourcePath} to ${validDestPath}: ${errorMessage}`);
        throw error;
    }
}

export async function searchFiles(rootPath: string, pattern: string): Promise<string[]> {
    const results: string[] = [];

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

    const validPath = await validatePath(rootPath);
    await search(validPath);
    return results;
}

export async function getFileInfo(filePath: string): Promise<Record<string, any>> {
    const validPath = await validatePath(filePath);
    try {
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
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error getting file info for ${validPath}: ${errorMessage}`);
        throw error;
    }
}

export function listAllowedDirectories(): string[] {
    logToFile("All directories are allowed - unrestricted filesystem access is enabled");
    if (process.platform === 'win32') {
        return ["All Windows drives (C:, D:, etc.) are accessible"];
    } else {
        return ["Full filesystem access (/) is enabled"];
    }
}
