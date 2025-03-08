@echo off
echo Launching Claude configuration repair tool...
powershell -ExecutionPolicy Bypass -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/fix-claude-config.ps1' -OutFile 'fix-claude-config.ps1'; ./fix-claude-config.ps1}"
pause