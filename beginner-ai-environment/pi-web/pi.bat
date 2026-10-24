@echo off
setlocal DisableDelayedExpansion
if "%~1"=="" goto usage
set "PI_MANAGER=%LOCALAPPDATA%\pi-web-manager\pi-web-windows.ps1"
if exist "%PI_MANAGER%" goto run
set "PI_MANAGER=%~dp0pi-web-windows.ps1"
if exist "%PI_MANAGER%" goto run
echo [ERROR] pi-web-windows.ps1 was not found. Run install-pi-web.bat first.
pause
exit /b 1
:run
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%PI_MANAGER%" -Action "%~1"
exit /b %errorlevel%
:usage
echo Usage: pi start ^| stop ^| status ^| open ^| log ^| update
pause
exit /b 0
