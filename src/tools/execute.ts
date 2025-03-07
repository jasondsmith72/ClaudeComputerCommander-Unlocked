import { spawn } from 'child_process';
import { commandManager } from '../command-manager.js';
import { DEFAULT_COMMAND_TIMEOUT, logCommand, getCommandAlias } from '../config.js';

// Store active command sessions
const activeSessions = new Map();

// Execute a command with optional timeout
export async function executeCommand({ command, timeout_ms = DEFAULT_COMMAND_TIMEOUT }) {
  // Check if command is blocked
  if (await commandManager.isBlocked(command.split(' ')[0])) {
    return {
      content: [{ type: 'text', text: `Error: Command "${command.split(' ')[0]}" is blocked` }],
      isError: true,
    };
  }

  // Check for command aliases and replace if found
  const aliasedCommand = getCommandAlias(command);

  // Create a new command session
  const child = spawn(aliasedCommand, { shell: true });
  const pid = child.pid;

  // Store session data
  activeSessions.set(pid, {
    child,
    command: aliasedCommand,
    output: '',
    isRunning: true,
  });

  // Handle output
  let output = '';
  
  child.stdout.on('data', (data) => {
    const chunk = data.toString();
    output += chunk;
    
    const session = activeSessions.get(pid);
    if (session) {
      session.output += chunk;
    }
  });
  
  child.stderr.on('data', (data) => {
    const chunk = data.toString();
    output += chunk;
    
    const session = activeSessions.get(pid);
    if (session) {
      session.output += chunk;
    }
  });
  
  // Handle process completion
  child.on('close', (code) => {
    const session = activeSessions.get(pid);
    if (session) {
      session.isRunning = false;
      session.exitCode = code;
    }
  });

  // Log the command execution
  logCommand(aliasedCommand, pid);
  
  // Wait for initial output or timeout
  return new Promise((resolve) => {
    const timeoutId = setTimeout(() => {
      resolve({
        content: [
          {
            type: 'text',
            text: output || `Command started with PID: ${pid}. No output yet. Use read_output with this PID to get more output.`,
          },
        ],
        metadata: { pid },
      });
    }, timeout_ms);

    child.on('close', (code) => {
      clearTimeout(timeoutId);
      resolve({
        content: [
          {
            type: 'text',
            text: output || `Command exited with code ${code} and PID: ${pid}. No output produced.`,
          },
        ],
        metadata: { pid, exitCode: code },
      });
    });
  });
}

// Read new output from a running command
export async function readOutput({ pid }) {
  // Check if session exists
  const session = activeSessions.get(pid);
  if (!session) {
    return {
      content: [{ type: 'text', text: `No active session found with PID: ${pid}` }],
      isError: true,
    };
  }

  // Get session output and clear the buffer
  const output = session.output;
  session.output = '';

  // Prepare response based on session state
  const isRunning = session.isRunning;
  const statusText = isRunning ? 'still running' : `exited with code ${session.exitCode}`;

  return {
    content: [
      {
        type: 'text',
        text: output
          ? output
          : `No new output. Process ${statusText}. ${isRunning ? 'Try again later for more output.' : ''}`,
      },
    ],
    metadata: { 
      pid, 
      isRunning,
      exitCode: session.exitCode,
      command: session.command
    },
  };
}

// Force terminate a running command
export async function forceTerminate({ pid }) {
  // Check if session exists
  const session = activeSessions.get(pid);
  if (!session) {
    return {
      content: [{ type: 'text', text: `No active session found with PID: ${pid}` }],
      isError: true,
    };
  }

  try {
    // Attempt to kill the process
    session.child.kill();
    
    // Mark session as not running and update
    session.isRunning = false;
    session.exitCode = -1; // Killed by signal
    
    return {
      content: [{ type: 'text', text: `Process with PID: ${pid} has been terminated` }],
    };
  } catch (error) {
    return {
      content: [{ type: 'text', text: `Error terminating process: ${error.message}` }],
      isError: true,
    };
  }
}

// List all active command sessions
export async function listSessions() {
  const sessions = [];
  
  activeSessions.forEach((session, pid) => {
    sessions.push({
      pid,
      command: session.command,
      isRunning: session.isRunning,
      exitCode: session.exitCode,
    });
  });

  if (sessions.length === 0) {
    return {
      content: [{ type: 'text', text: 'No active command sessions' }],
    };
  }

  return {
    content: [
      {
        type: 'text',
        text: sessions
          .map(s => `PID: ${s.pid} - Command: ${s.command} - Status: ${s.isRunning ? 'Running' : `Exited (${s.exitCode})`}`)
          .join('\n'),
      },
    ],
  };
}

// Cleanup old sessions that have completed
export function cleanupSessions() {
  const now = Date.now();
  const CLEANUP_THRESHOLD_MS = 3600000; // 1 hour
  
  activeSessions.forEach((session, pid) => {
    if (!session.isRunning && (now - session.endTime > CLEANUP_THRESHOLD_MS)) {
      activeSessions.delete(pid);
    }
  });
}

// Schedule regular cleanup
setInterval(cleanupSessions, 300000); // Every 5 minutes
