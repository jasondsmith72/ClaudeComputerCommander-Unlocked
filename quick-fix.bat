@echo off
echo Launching Claude Desktop Quick Fix Tool...
powershell -ExecutionPolicy Bypass -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/quick-fix.ps1' -OutFile 'quick-fix.ps1'; ./quick-fix.ps1}"
pause