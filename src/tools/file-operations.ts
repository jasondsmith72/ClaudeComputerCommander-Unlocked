// Command execution-based file operations that bypass filesystem restrictions

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import os from 'os';

// Function to log output
function logToFile(message: string): void {
    const logFile = path.join(process.cwd(), 'file-operations.log');
    try {
        fs.appendFileSync(logFile, `${new Date().toISOString()} [file-operations] ${message}\n`);
    } catch (error) {
        // Silent fail if logging fails
    }
}

// Escape strings for safer command execution
function escapePath(filepath: string): string {
    if (process.platform === 'win32') {
        // For Windows - PowerShell escaping
        return filepath.replace(/'/g, "''");
    } else {
        // For Unix systems
        return filepath.replace(/"/g, '\\"');
    }
}

// Read file using command execution
export async function readFileWithCmd(filePath: string): Promise<string> {
    logToFile(`Reading file with command execution: ${filePath}`);
    
    try {
        if (process.platform === 'win32') {
            // Use PowerShell on Windows
            const escapedPath = escapePath(filePath);
            const command = `powershell -Command "Get-Content -Path '${escapedPath}' -Raw -ErrorAction Stop"`;
            const output = execSync(command, { encoding: 'utf8' });
            return output;
        } else {
            // Use cat on Unix systems
            const command = `cat "${escapePath(filePath)}"`;
            const output = execSync(command, { encoding: 'utf8' });
            return output;
        }
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error reading file with command: ${errorMessage}`);
        throw new Error(`Failed to read file: ${errorMessage}`);
    }
}

// Write file using command execution
export async function writeFileWithCmd(filePath: string, content: string): Promise<void> {
    logToFile(`Writing file with command execution: ${filePath}`);
    
    // Create a temporary file
    const tmpDir = os.tmpdir();
    const tempFile = path.join(tmpDir, `claude-temp-${Date.now()}.txt`);
    
    try {
        // Write content to temp file
        fs.writeFileSync(tempFile, content, 'utf8');
        
        if (process.platform === 'win32') {
            // Use PowerShell on Windows
            const escapedPath = escapePath(filePath);
            const escapedTempPath = escapePath(tempFile);
            const command = `powershell -Command "Set-Content -Path '${escapedPath}' -Value (Get-Content -Path '${escapedTempPath}' -Raw) -Force"`;
            execSync(command);
        } else {
            // Use cat on Unix systems
            const command = `cat "${escapePath(tempFile)}" > "${escapePath(filePath)}"`;
            execSync(command);
        }
        
        logToFile(`Successfully wrote to file: ${filePath}`);
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error writing file with command: ${errorMessage}`);
        throw new Error(`Failed to write file: ${errorMessage}`);
    } finally {
        // Clean up temp file
        try {
            fs.unlinkSync(tempFile);
        } catch (err) {
            logToFile(`Warning: Failed to clean up temp file ${tempFile}`);
        }
    }
}

// Create directory using command execution
export async function createDirectoryWithCmd(dirPath: string): Promise<void> {
    logToFile(`Creating directory with command execution: ${dirPath}`);
    
    try {
        if (process.platform === 'win32') {
            // Use PowerShell on Windows
            const escapedPath = escapePath(dirPath);
            const command = `powershell -Command "New-Item -Path '${escapedPath}' -ItemType Directory -Force"`;
            execSync(command);
        } else {
            // Use mkdir on Unix systems
            const command = `mkdir -p "${escapePath(dirPath)}"`;
            execSync(command);
        }
        
        logToFile(`Successfully created directory: ${dirPath}`);
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error creating directory with command: ${errorMessage}`);
        throw new Error(`Failed to create directory: ${errorMessage}`);
    }
}

// List directory using command execution
export async function listDirectoryWithCmd(dirPath: string): Promise<string[]> {
    logToFile(`Listing directory with command execution: ${dirPath}`);
    
    try {
        let output: string;
        
        if (process.platform === 'win32') {
            // Use PowerShell on Windows
            const escapedPath = escapePath(dirPath);
            output = execSync(
                `powershell -Command "Get-ChildItem -Path '${escapedPath}' | ForEach-Object { if ($_.PSIsContainer) {'[DIR] ' + $_.Name} else {'[FILE] ' + $_.Name} }"`,
                { encoding: 'utf8' }
            );
        } else {
            // Use ls on Unix systems
            const command = `ls -la "${escapePath(dirPath)}" | awk '{if(NR>1) print ($$1 ~ /^d/ ? "[DIR] " : "[FILE] ") $$9}'`;
            output = execSync(command, { encoding: 'utf8' });
        }
        
        return output.split('\n').filter(line => line.trim() !== '');
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error listing directory with command: ${errorMessage}`);
        throw new Error(`Failed to list directory: ${errorMessage}`);
    }
}

// Check if a file or directory exists using command execution
export async function existsWithCmd(path: string): Promise<boolean> {
    logToFile(`Checking if path exists with command execution: ${path}`);
    
    try {
        if (process.platform === 'win32') {
            // Use PowerShell on Windows
            const escapedPath = escapePath(path);
            execSync(`powershell -Command "Test-Path -Path '${escapedPath}'"`, { encoding: 'utf8' });
            return true;
        } else {
            // Use test on Unix systems
            execSync(`test -e "${escapePath(path)}"`, { encoding: 'utf8' });
            return true;
        }
    } catch (error) {
        return false;
    }
}

// Move file using command execution
export async function moveFileWithCmd(sourcePath: string, destinationPath: string): Promise<void> {
    logToFile(`Moving file with command execution: ${sourcePath} -> ${destinationPath}`);
    
    try {
        if (process.platform === 'win32') {
            // Use PowerShell on Windows
            const escapedSource = escapePath(sourcePath);
            const escapedDest = escapePath(destinationPath);
            execSync(`powershell -Command "Move-Item -Path '${escapedSource}' -Destination '${escapedDest}' -Force"`);
        } else {
            // Use mv on Unix systems
            const command = `mv "${escapePath(sourcePath)}" "${escapePath(destinationPath)}"`;
            execSync(command);
        }
        
        logToFile(`Successfully moved file: ${sourcePath} -> ${destinationPath}`);
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logToFile(`Error moving file with command: ${errorMessage}`);
        throw new Error(`Failed to move file: ${errorMessage}`);
    }
}
