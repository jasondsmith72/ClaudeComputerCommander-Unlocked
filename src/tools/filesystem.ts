import fs from "fs/promises";
import path from "path";
import os from 'os';
import fsSync from "fs";
import { execSync } from 'child_process';
import { 
    readFileWithCmd,
    writeFileWithCmd,
    createDirectoryWithCmd,
    listDirectoryWithCmd,
    moveFileWithCmd,
    existsWithCmd
} from './file-operations.js';

// Helper function to log to file instead of console
function logToFile(message: string): void {
    const logFile = path.join(process.cwd(), 'server.log');
    try {
        fsSync.appendFileSync(logFile, `${new Date().toISOString()} [filesystem] ${message}\n`);
    } catch (error) {
        // Silent fail if unable to write to log
    }
}

// Simple path normalization
function normalizePath(p: string): string {
    return path.normalize(p);
}

// Expand home directory
function expandHome(filepath: string): string {
    if (filepath.startsWith('~/') || filepath === '~') {
        return path.join(os.homedir(), filepath.slice(1));
    }
    return filepath;
}

// Path validation is completely bypassed
export async function validatePath(requestedPath: string): Promise<string> {
    logToFile(`Access granted to path without validation: ${requestedPath}`);
    
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
    
    return absolute;
}

// Try different methods to read a file, falling back to command execution if necessary
export async function readFile(filePath: string): Promise<string> {
    const validPath = await validatePath(filePath);
    logToFile(`Reading file: ${validPath}`);
    
    try {
        // First try the regular fs API
        return await fs.readFile(validPath, "utf-8");
    } catch (fsError) {
        logToFile(`Regular fs API failed: ${fsError instanceof Error ? fsError.message : String(fsError)}`);
        logToFile(`Falling back to command execution for reading ${validPath}`);
        
        try {
            // Try command execution if fs API fails
            return await readFileWithCmd(validPath);
        } catch (cmdError) {
            const errorMessage = cmdError instanceof Error ? cmdError.message : String(cmdError);
            logToFile(`Command execution also failed: ${errorMessage}`);
            throw new Error(`Failed to read file "${validPath}": ${errorMessage}`);
        }
    }
}

// Try different methods to write a file, falling back to command execution if necessary
export async function writeFile(filePath: string, content: string): Promise<void> {
    const validPath = await validatePath(filePath);
    logToFile(`Writing file: ${validPath}`);
    
    try {
        // First try the regular fs API
        // Ensure directory exists
        const dirPath = path.dirname(validPath);
        await fs.mkdir(dirPath, { recursive: true }).catch(err => {
            logToFile(`Note: mkdir failed but continuing: ${err instanceof Error ? err.message : String(err)}`);
        });
        
        await fs.writeFile(validPath, content, "utf-8");
        logToFile(`Successfully wrote to file using fs API: ${validPath}`);
    } catch (fsError) {
        logToFile(`Regular fs API failed: ${fsError instanceof Error ? fsError.message : String(fsError)}`);
        logToFile(`Falling back to command execution for writing ${validPath}`);
        
        try {
            // Try command execution if fs API fails
            await writeFileWithCmd(validPath, content);
            logToFile(`Successfully wrote to file using command execution: ${validPath}`);
        } catch (cmdError) {
            const errorMessage = cmdError instanceof Error ? cmdError.message : String(cmdError);
            logToFile(`Command execution also failed: ${errorMessage}`);
            
            // One more desperate attempt - try using echo command
            try {
                logToFile(`Trying last resort echo method for ${validPath}`);
                const tempPath = path.join(os.tmpdir(), `temp-${Date.now()}.txt`);
                fsSync.writeFileSync(tempPath, content, 'utf8');
                
                if (process.platform === 'win32') {
                    execSync(`powershell -Command "Get-Content '${tempPath}' | Set-Content '${validPath}' -Force"`, { encoding: 'utf8' });
                } else {
                    execSync(`cat "${tempPath}" > "${validPath}"`, { encoding: 'utf8' });
                }
                
                fsSync.unlinkSync(tempPath);
                logToFile(`Successfully wrote file using echo method: ${validPath}`);
            } catch (echoError) {
                logToFile(`Echo method also failed: ${echoError instanceof Error ? echoError.message : String(echoError)}`);
                throw new Error(`Failed to write file "${validPath}" after trying multiple methods`);
            }
        }
    }
}

export async function readMultipleFiles(paths: string[]): Promise<string[]> {
    return Promise.all(
        paths.map(async (filePath: string) => {
            try {
                const content = await readFile(filePath);
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
    logToFile(`Creating directory: ${validPath}`);
    
    try {
        // First try regular fs API
        await fs.mkdir(validPath, { recursive: true });
        logToFile(`Successfully created directory using fs API: ${validPath}`);
    } catch (fsError) {
        logToFile(`Regular fs API failed: ${fsError instanceof Error ? fsError.message : String(fsError)}`);
        logToFile(`Falling back to command execution for creating directory ${validPath}`);
        
        try {
            // Try command execution if fs API fails
            await createDirectoryWithCmd(validPath);
        } catch (cmdError) {
            const errorMessage = cmdError instanceof Error ? cmdError.message : String(cmdError);
            logToFile(`Command execution also failed: ${errorMessage}`);
            throw new Error(`Failed to create directory "${validPath}": ${errorMessage}`);
        }
    }
}

export async function listDirectory(dirPath: string): Promise<string[]> {
    const validPath = await validatePath(dirPath);
    logToFile(`Listing directory: ${validPath}`);
    
    try {
        // First try regular fs API
        const entries = await fs.readdir(validPath, { withFileTypes: true });
        return entries.map((entry) => `${entry.isDirectory() ? "[DIR]" : "[FILE]"} ${entry.name}`);
    } catch (fsError) {
        logToFile(`Regular fs API failed: ${fsError instanceof Error ? fsError.message : String(fsError)}`);
        logToFile(`Falling back to command execution for listing directory ${validPath}`);
        
        try {
            // Try command execution if fs API fails
            return await listDirectoryWithCmd(validPath);
        } catch (cmdError) {
            const errorMessage = cmdError instanceof Error ? cmdError.message : String(cmdError);
            logToFile(`Command execution also failed: ${errorMessage}`);
            throw new Error(`Failed to list directory "${validPath}": ${errorMessage}`);
        }
    }
}

export async function moveFile(sourcePath: string, destinationPath: string): Promise<void> {
    const validSourcePath = await validatePath(sourcePath);
    const validDestPath = await validatePath(destinationPath);
    
    logToFile(`Moving file: ${validSourcePath} -> ${validDestPath}`);
    
    try {
        // First try regular fs API
        // Ensure destination directory exists
        const destDir = path.dirname(validDestPath);
        await fs.mkdir(destDir, { recursive: true }).catch(err => {
            logToFile(`Note: mkdir failed but continuing: ${err instanceof Error ? err.message : String(err)}`);
        });
        
        await fs.rename(validSourcePath, validDestPath);
        logToFile(`Successfully moved file using fs API: ${validSourcePath} -> ${validDestPath}`);
    } catch (fsError) {
        logToFile(`Regular fs API failed: ${fsError instanceof Error ? fsError.message : String(fsError)}`);
        logToFile(`Falling back to command execution for moving file ${validSourcePath}`);
        
        try {
            // Try command execution if fs API fails
            await moveFileWithCmd(validSourcePath, validDestPath);
        } catch (cmdError) {
            const errorMessage = cmdError instanceof Error ? cmdError.message : String(cmdError);
            logToFile(`Command execution also failed: ${errorMessage}`);
            
            // Last resort - try copy and delete
            try {
                logToFile(`Trying copy and delete method`);
                const content = await readFile(validSourcePath);
                await writeFile(validDestPath, content);
                
                // Try to delete the source file
                try {
                    await fs.unlink(validSourcePath);
                } catch (unlinkErr) {
                    logToFile(`Warning: Could not delete source file after copy: ${unlinkErr instanceof Error ? unlinkErr.message : String(unlinkErr)}`);
                }
                
                logToFile(`Successfully moved file using copy and delete method`);
            } catch (copyError) {
                logToFile(`Copy and delete method also failed: ${copyError instanceof Error ? copyError.message : String(copyError)}`);
                throw new Error(`Failed to move file "${validSourcePath}" to "${validDestPath}" after trying multiple methods`);
            }
        }
    }
}

export async function searchFiles(rootPath: string, pattern: string): Promise<string[]> {
    const validPath = await validatePath(rootPath);
    logToFile(`Searching for files matching "${pattern}" in ${validPath}`);
    
    const results: string[] = [];

    async function search(currentPath: string) {
        try {
            const entries = await listDirectory(currentPath);
            
            for (const entry of entries) {
                const match = entry.match(/^\[(DIR|FILE)\]\s+(.+)$/);
                if (!match) continue;
                
                const isDir = match[1] === "DIR";
                const name = match[2];
                const fullPath = path.join(currentPath, name);
                
                if (name.toLowerCase().includes(pattern.toLowerCase())) {
                    results.push(fullPath);
                }
                
                if (isDir) {
                    try {
                        await search(fullPath);
                    } catch (error) {
                        logToFile(`Error searching subdirectory ${fullPath}: ${error instanceof Error ? error.message : String(error)}`);
                    }
                }
            }
        } catch (error) {
            logToFile(`Error searching directory ${currentPath}: ${error instanceof Error ? error.message : String(error)}`);
        }
    }

    await search(validPath);
    return results;
}

export async function getFileInfo(filePath: string): Promise<Record<string, any>> {
    const validPath = await validatePath(filePath);
    logToFile(`Getting file info for: ${validPath}`);
    
    try {
        // Try regular fs API
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
        // On error, return basic information
        logToFile(`Error getting file info: ${error instanceof Error ? error.message : String(error)}`);
        
        // Check if path exists using command
        const exists = await existsWithCmd(validPath);
        
        if (!exists) {
            throw new Error(`File or directory does not exist: ${validPath}`);
        }
        
        // Return minimal info
        return {
            path: validPath,
            exists: true,
            error: `Could not get detailed info: ${error instanceof Error ? error.message : String(error)}`,
        };
    }
}

export function listAllowedDirectories(): string[] {
    return [
        "UNRESTRICTED ACCESS ENABLED - All filesystem locations are accessible",
        "If experiencing permission issues, commands will be used automatically as a fallback"
    ];
}
