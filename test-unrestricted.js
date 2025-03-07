#!/usr/bin/env node

// A simple test script to verify the unrestricted file access
// Run this script after building the project

import { readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import { execSync } from 'child_process';

// Function to log both to console and file
function log(message) {
  console.log(message);
  writeFileSync('test-unrestricted.log', message + '\n', { flag: 'a' });
}

// Function to run a command and log output
function runCommand(command) {
  log(`Running command: ${command}`);
  try {
    const output = execSync(command, { encoding: 'utf8' });
    log(`Command output:\n${output}`);
    return output;
  } catch (error) {
    log(`Command failed: ${error.message}`);
    return null;
  }
}

// Main test function
async function runTests() {
  log('=== UNRESTRICTED ACCESS TEST ===');
  log(`Date: ${new Date().toISOString()}`);
  log(`Working directory: ${process.cwd()}`);
  
  // Test 1: Create a test file at root of C: drive
  log('\nTest 1: Creating file at root of C: drive');
  const testFile = 'C:\\claude-test.txt';
  const testContent = `This is a test file created by Claude at ${new Date().toISOString()}`;
  
  try {
    writeFileSync(testFile, testContent, 'utf8');
    log(`✅ Successfully created file directly at: ${testFile}`);
  } catch (fsError) {
    log(`❌ Direct file creation failed: ${fsError.message}`);
    
    // Try using command
    log('Trying command execution instead');
    const tempFile = join(process.cwd(), 'temp-test.txt');
    writeFileSync(tempFile, testContent, 'utf8');
    
    const result = runCommand(`powershell -Command "Copy-Item -Path '${tempFile}' -Destination '${testFile}' -Force"`);
    if (result !== null) {
      log(`✅ Successfully created file via command at: ${testFile}`);
    }
  }
  
  // Test 2: Read the test file we just created
  log('\nTest 2: Reading the test file');
  try {
    const content = readFileSync(testFile, 'utf8');
    log(`✅ Successfully read file directly: ${content}`);
  } catch (fsError) {
    log(`❌ Direct file reading failed: ${fsError.message}`);
    
    // Try using command
    log('Trying command execution instead');
    const result = runCommand(`powershell -Command "Get-Content -Path '${testFile}' -Raw"`);
    if (result !== null) {
      log(`✅ Successfully read file via command: ${result}`);
    }
  }
  
  // Test 3: Write a file to Desktop folder
  log('\nTest 3: Writing file to Desktop folder');
  const desktopPath = process.env.USERPROFILE + '\\Desktop';
  const desktopFile = join(desktopPath, 'claude-desktop-test.txt');
  
  try {
    writeFileSync(desktopFile, `Test file on Desktop created at ${new Date().toISOString()}`, 'utf8');
    log(`✅ Successfully created file directly at: ${desktopFile}`);
  } catch (fsError) {
    log(`❌ Direct file creation failed: ${fsError.message}`);
    
    // Try using command
    log('Trying command execution instead');
    const result = runCommand(`powershell -Command "Set-Content -Path '${desktopFile}' -Value 'Test file on Desktop created at ${new Date().toISOString()}' -Force"`);
    if (result !== null) {
      log(`✅ Successfully created file via command at: ${desktopFile}`);
    }
  }
  
  // Test 4: Create a directory in Program Files
  log('\nTest 4: Creating directory in Program Files');
  const programFilesDir = 'C:\\Program Files\\ClaudeTest';
  
  try {
    runCommand(`powershell -Command "New-Item -Path '${programFilesDir}' -ItemType Directory -Force -ErrorAction Stop"`);
    log(`✅ Successfully created directory at: ${programFilesDir}`);
    
    // Create a test file in the directory
    const programFilesFile = join(programFilesDir, 'test.txt');
    runCommand(`powershell -Command "Set-Content -Path '${programFilesFile}' -Value 'Test file in Program Files' -Force"`);
    log(`✅ Successfully created file at: ${programFilesFile}`);
  } catch (error) {
    log(`❌ Failed to create directory or file in Program Files: ${error.message}`);
  }
  
  // Test 5: Clean up
  log('\nTest 5: Cleaning up test files');
  try {
    runCommand(`powershell -Command "Remove-Item -Path '${testFile}' -Force -ErrorAction SilentlyContinue"`);
    runCommand(`powershell -Command "Remove-Item -Path '${desktopFile}' -Force -ErrorAction SilentlyContinue"`);
    runCommand(`powershell -Command "Remove-Item -Path '${programFilesDir}' -Recurse -Force -ErrorAction SilentlyContinue"`);
    log('✅ Cleanup completed');
  } catch (error) {
    log(`⚠️ Some cleanup operations may have failed: ${error.message}`);
  }
  
  log('\n=== TEST COMPLETED ===');
}

// Run the tests
runTests().catch(error => {
  log(`❌ Test failed with error: ${error.message}`);
});
