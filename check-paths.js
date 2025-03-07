#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import os from 'os';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Function to expand environment variables in a path
function expandEnvVars(pathStr) {
  return pathStr.replace(/%([^%]+)%/g, (_, varName) => {
    return process.env[varName] || '';
  });
}

// Function to normalize all paths
function normalizePath(p) {
  return path.normalize(p);
}

// Function to expand home directory
function expandHome(filepath) {
  if (filepath.startsWith('~/') || filepath === '~') {
    return path.join(os.homedir(), filepath.slice(1));
  }
  return filepath;
}

// Load configuration
function loadConfig() {
  const configFile = path.join(process.cwd(), 'config.json');
  try {
    if (fs.existsSync(configFile)) {
      const configContent = fs.readFileSync(configFile, 'utf8');
      return JSON.parse(configContent);
    }
  } catch (error) {
    console.error(`Error loading config: ${error.message}`);
  }
  
  return { 
    blockedCommands: [],
    allowedDirectories: [
      process.cwd(),
      os.homedir()
    ]
  };
}

// Get allowed directories from config
function getAllowedDirectories() {
  const config = loadConfig();
  let dirs = [];
  
  if (Array.isArray(config.allowedDirectories)) {
    // Legacy format - array of directories
    dirs = config.allowedDirectories;
  } else if (config.allowedDirectories && typeof config.allowedDirectories === 'object') {
    // New format - platform-specific directories
    const platform = process.platform;
    
    if (config.allowedDirectories[platform]) {
      dirs = config.allowedDirectories[platform];
    } else {
      // Fallback to default
      dirs = [process.cwd(), os.homedir()];
    }
  } else {
    // No configuration, use defaults
    dirs = [process.cwd(), os.homedir()];
  }
  
  // Process each directory path
  dirs = dirs.map(dir => {
    console.log(`Processing directory: ${dir}`);
    
    // Expand Windows environment variables
    if (process.platform === 'win32' && dir.includes('%')) {
      const expanded = expandEnvVars(dir);
      console.log(`  Expanded env vars: ${expanded}`);
      dir = expanded;
    }
    
    // Handle current directory
    if (dir === '.' || dir === './') {
      console.log(`  Current directory: ${process.cwd()}`);
      return process.cwd();
    }
    
    // Handle home directory
    if (dir.startsWith('~/') || dir === '~') {
      const home = path.normalize(dir.replace(/^~/, os.homedir()));
      console.log(`  Home directory expansion: ${home}`);
      return home;
    }
    
    // Handle relative paths
    if (dir.startsWith('./')) {
      const resolved = path.resolve(process.cwd(), dir.slice(2));
      console.log(`  Relative path resolution: ${resolved}`);
      return resolved;
    }
    
    // Make sure all paths are absolute
    const absolute = path.resolve(dir);
    console.log(`  Absolute path: ${absolute}`);
    return absolute;
  });
  
  return dirs;
}

// Test directory access
async function testDirectoryAccess(dirs) {
  console.log('\nTesting directory access:');
  
  for (const dir of dirs) {
    try {
      await fs.promises.access(dir, fs.constants.R_OK);
      console.log(`✅ Can read:    ${dir}`);
    } catch (error) {
      console.log(`❌ Cannot read: ${dir} (${error.code})`);
    }
    
    try {
      await fs.promises.access(dir, fs.constants.W_OK);
      console.log(`✅ Can write:   ${dir}`);
    } catch (error) {
      console.log(`❌ Cannot write: ${dir} (${error.code})`);
    }
  }
}

// Main function
async function main() {
  console.log('=== Claude Computer Commander Path Checker ===');
  console.log(`Platform: ${process.platform}`);
  console.log(`Home directory: ${os.homedir()}`);
  console.log(`Current directory: ${process.cwd()}`);
  console.log('\nLoading allowed directories from config.json...');
  
  const allowedDirs = getAllowedDirectories();
  
  console.log('\nFinal allowed directories:');
  allowedDirs.forEach((dir, i) => {
    console.log(`${i+1}. ${dir}`);
  });
  
  await testDirectoryAccess(allowedDirs);
  
  // Try to create a test file in each allowed directory
  console.log('\nTesting file creation:');
  
  for (const dir of allowedDirs) {
    const testFile = path.join(dir, 'claude-test.txt');
    try {
      await fs.promises.writeFile(testFile, 'Test file created by Claude Commander Path Checker');
      console.log(`✅ Created test file: ${testFile}`);
      
      // Remove the test file
      await fs.promises.unlink(testFile);
      console.log(`   Removed test file: ${testFile}`);
    } catch (error) {
      console.log(`❌ Failed to create test file: ${testFile} (${error.code || error.message})`);
    }
  }
}

main().catch(error => {
  console.error(`Error: ${error.message}`);
  process.exit(1);
});
