@echo off
echo Launching PowerShell installer with JSON fix...
powershell -ExecutionPolicy Bypass -Command "& {$url = 'https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/simple-install.ps1'; Invoke-WebRequest -Uri $url -OutFile 'simple-install.ps1'; ./simple-install.ps1}"
echo.
echo Running additional JSON configuration fix...
powershell -ExecutionPolicy Bypass -Command "& {$url = 'https://raw.githubusercontent.com/jasondsmith72/ClaudeComputerCommander-Unlocked/main/fix-json-config.ps1'; Invoke-WebRequest -Uri $url -OutFile 'fix-json-config.ps1'; ./fix-json-config.ps1}"
pause