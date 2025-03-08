@echo off
echo Launching Claude Desktop JSON Configuration Fix...
powershell -ExecutionPolicy Bypass -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/fix-json-config.ps1' -OutFile 'fix-json-config.ps1'; ./fix-json-config.ps1}"
pause