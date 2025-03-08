import fs from 'fs/promises';
import { existsSync } from 'fs';
import path from 'path';
import { CONFIG_FILE } from './config.js';

class CommandManager {
  private blockedCommands: Set<string> = new Set();

  async loadBlockedCommands(): Promise<void> {
    try {
      // Handle both absolute and relative paths
      const configPath = path.isAbsolute(CONFIG_FILE) 
        ? CONFIG_FILE 
        : path.join(process.cwd(), CONFIG_FILE);
        
      // Check if file exists before trying to read it
      if (existsSync(configPath)) {
        const configData = await fs.readFile(configPath, 'utf-8');
        const config = JSON.parse(configData);
        this.blockedCommands = new Set(config.blockedCommands);
      } else {
        console.log(`Config file not found at ${configPath}, using default settings`);
        this.blockedCommands = new Set([
          "format", "mount", "umount", "mkfs", "fdisk", "dd", 
          "sudo", "su", "passwd", "adduser", "useradd", "usermod", "groupadd"
        ]);
      }
    } catch (error) {
      console.log(`Error loading config: ${error}, using default settings`);
      this.blockedCommands = new Set();
    }
  }

  async saveBlockedCommands(): Promise<void> {
    try {
      // Handle both absolute and relative paths
      const configPath = path.isAbsolute(CONFIG_FILE) 
        ? CONFIG_FILE 
        : path.join(process.cwd(), CONFIG_FILE);
        
      const config = {
        blockedCommands: Array.from(this.blockedCommands)
      };
      await fs.writeFile(configPath, JSON.stringify(config, null, 2), 'utf-8');
    } catch (error) {
      console.error(`Error saving config: ${error}`);
    }
  }

  validateCommand(command: string): boolean {
    const baseCommand = command.split(' ')[0].toLowerCase().trim();
    return !this.blockedCommands.has(baseCommand);
  }

  async blockCommand(command: string): Promise<boolean> {
    command = command.toLowerCase().trim();
    if (this.blockedCommands.has(command)) {
      return false;
    }
    this.blockedCommands.add(command);
    await this.saveBlockedCommands();
    return true;
  }

  async unblockCommand(command: string): Promise<boolean> {
    command = command.toLowerCase().trim();
    if (!this.blockedCommands.has(command)) {
      return false;
    }
    this.blockedCommands.delete(command);
    await this.saveBlockedCommands();
    return true;
  }

  listBlockedCommands(): string[] {
    return Array.from(this.blockedCommands).sort();
  }
}

export const commandManager = new CommandManager();
