@echo off
echo Launching PowerShell installer...
powershell -ExecutionPolicy Bypass -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/simple-install.ps1' -OutFile 'simple-install.ps1'; ./simple-install.ps1}"
pause