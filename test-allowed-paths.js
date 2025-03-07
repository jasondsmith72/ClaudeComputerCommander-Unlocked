// Test script to check allowed paths configuration
import path from 'path';
import process from 'process';
import os from 'os';
import { getAllowedDirectories } from './dist/config.js';

// Function to simulate path validation logic
function checkPathAccess(testPath, allowedDirs) {
    console.log(`\nTesting path: ${testPath}`);
    
    // Expand ~ to home directory if present
    let expandedPath = testPath;
    if (testPath.startsWith('~')) {
        expandedPath = testPath.replace(/^~/, os.homedir());
    }
    
    // Resolve to absolute path
    const absolute = path.isAbsolute(expandedPath)
        ? path.resolve(expandedPath)
        : path.resolve(process.cwd(), expandedPath);
    
    console.log(`Absolute path: ${absolute}`);
    
    // Check if path is within any allowed directory
    const isWindows = process.platform === 'win32';
    let isAllowed = false;
    let matchedDir = '';
    
    for (const dir of allowedDirs) {
        const normalizedDir = path.normalize(dir);
        const normalizedPath = isWindows ? 
            absolute.toLowerCase() : 
            absolute;
        const normalizedAllowed = isWindows ? 
            normalizedDir.toLowerCase() : 
            normalizedDir;
        
        if (normalizedPath === normalizedAllowed || normalizedPath.startsWith(normalizedAllowed + path.sep)) {
            isAllowed = true;
            matchedDir = normalizedDir;
            break;
        }
    }
    
    if (isAllowed) {
        console.log(`✅ Access ALLOWED (matched directory: ${matchedDir})`);
    } else {
        console.log(`❌ Access DENIED - Path not within any allowed directories`);
    }
    
    return isAllowed;
}

// Main testing function
async function runTests() {
    try {
        console.log('==== Testing Allowed Paths Configuration ====');
        
        // Get configured allowed directories
        const allowedDirs = getAllowedDirectories();
        console.log('\nConfigured allowed directories:');
        allowedDirs.forEach(dir => console.log(`- ${dir}`));
        
        // Test cases
        const testPaths = [
            '.',                                 // Current directory
            './src',                             // Subdirectory of current directory
            '~/Documents',                       // Home documents
            path.join(process.cwd(), 'config.json'), // Absolute path to config file
            '/etc/passwd',                       // System file (should be denied)
            'C:\\Windows\\System32',             // Windows system directory
            '../',                               // Parent directory
            '~/../',                             // Parent of home directory
        ];
        
        // Run tests
        console.log('\n==== Test Results ====');
        const results = testPaths.map(testPath => ({
            path: testPath,
            allowed: checkPathAccess(testPath, allowedDirs)
        }));
        
        // Summary
        console.log('\n==== Summary ====');
        const allowed = results.filter(r => r.allowed).length;
        console.log(`${allowed} of ${testPaths.length} test paths are allowed`);
        
    } catch (error) {
        console.error('Error during testing:', error);
    }
}

// Run the tests
runTests();
