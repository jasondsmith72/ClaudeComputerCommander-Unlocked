#!/usr/bin/env node

import { getAllowedDirectories } from './dist/config.js';
import fs from 'fs';
import path from 'path';
import os from 'os';

console.log('Testing Allowed Paths Configuration');
console.log('===================================');

// Get all allowed directories
const allowedDirs = getAllowedDirectories();

console.log('Current Platform:', process.platform);
console.log('Current User:', os.userInfo().username);
console.log('Current Working Directory:', process.cwd());
console.log('\nAllowed Directories:');
allowedDirs.forEach((dir, index) => {
    console.log(`  [${index + 1}] ${dir}`);
});

console.log('\nTesting directory access:');

// Test some common directories
const testDirs = [
    os.homedir(),
    path.join(os.homedir(), 'Documents'),
    path.join(os.homedir(), 'Desktop'),
    path.join(os.homedir(), 'Downloads'),
    '/tmp',
    'C:\\Windows',
    'C:\\Program Files',
    'C:\\Users',
    path.join(process.cwd(), 'src'),
    path.join(process.cwd(), 'dist'),
    path.join(process.cwd(), 'node_modules'),
];

// Function to check if a path is within allowed directories
function isPathAllowed(testPath) {
    // Normalize paths for consistent comparison
    const normalizedTestPath = path.normalize(testPath);
    
    // Check if the path is directly in the allowed list
    for (const allowedDir of allowedDirs) {
        const normalizedAllowedDir = path.normalize(allowedDir);
        
        // Direct match
        if (normalizedTestPath === normalizedAllowedDir) {
            return true;
        }
        
        // Check if test path is a subdirectory of an allowed directory
        if (normalizedTestPath.startsWith(normalizedAllowedDir + path.sep)) {
            return true;
        }
    }
    
    return false;
}

// Test each directory
testDirs.forEach(dir => {
    const allowed = isPathAllowed(dir);
    const exists = fs.existsSync(dir);
    
    console.log(`  ${dir}`);
    console.log(`    Allowed: ${allowed ? '✅ Yes' : '❌ No'}`);
    console.log(`    Exists:  ${exists ? '✅ Yes' : '❌ No'}`);
});

console.log('\nTest finished. Use this information to troubleshoot directory access issues.');
console.log('To allow more directories, edit the config.json file.');
