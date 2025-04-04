#!/usr/bin/env node

import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { server } from './server.js';
import { commandManager } from './command-manager.js';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

// Determine the directory where this script is located
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Log process info for debugging
function logProcessInfo() {
  console.log({
    cwd: process.cwd(),
    scriptDir: __dirname,
    nodeVersion: process.version,
    platform: process.platform
  });
}

async function runSetup() {
  try {
    const setupScript = join(__dirname, 'setup-claude-server.js');
    const { default: setupModule } = await import(setupScript);
    if (typeof setupModule === 'function') {
      await setupModule();
    }
  } catch (error) {
    console.error('Setup error:', error);
    process.exit(1);
  }
}

async function runServer() {
  try {
    // Check if first argument is "setup"
    if (process.argv[2] === 'setup') {
      await runSetup();
      return;
    }
    
    // For debugging - uncomment if needed
    // logProcessInfo();
    
    // Handle uncaught exceptions
    process.on('uncaughtException', async (error) => {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error(`Uncaught exception: ${errorMessage}`);
      process.exit(1);
    });

    // Handle unhandled rejections
    process.on('unhandledRejection', async (reason) => {
      const errorMessage = reason instanceof Error ? reason.message : String(reason);
      console.error(`Unhandled rejection: ${errorMessage}`);
      process.exit(1);
    });

    const transport = new StdioServerTransport();
    
    // Load blocked commands from config file
    await commandManager.loadBlockedCommands();

    await server.connect(transport);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    process.stderr.write(JSON.stringify({
      type: 'error',
      timestamp: new Date().toISOString(),
      message: `Failed to start server: ${errorMessage}`
    }) + '\n');
    process.exit(1);
  }
}

runServer().catch(async (error) => {
  const errorMessage = error instanceof Error ? error.message : String(error);
  process.stderr.write(JSON.stringify({
    type: 'error',
    timestamp: new Date().toISOString(),
    message: `Fatal error running server: ${errorMessage}`
  }) + '\n');
  process.exit(1);
});
