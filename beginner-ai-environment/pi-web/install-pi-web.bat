@echo off
setlocal DisableDelayedExpansion
set "PI_SETUP_LOCAL=%~dp0pi-web-windows.ps1"
set "PI_SETUP_URL=https://raw.githubusercontent.com/Brian23-j/Jim-ai-report/main/beginner-ai-environment/pi-web/pi-web-windows.ps1"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $script=$env:PI_SETUP_LOCAL; $tempFile=$null; try { if (!(Test-Path -LiteralPath $script -PathType Leaf)) { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $tempFile=Join-Path $env:TEMP ('pi-web-setup-'+[guid]::NewGuid().ToString()+'.ps1'); Invoke-WebRequest -UseBasicParsing -Uri $env:PI_SETUP_URL -OutFile $tempFile; $script=$tempFile }; & $script -Action install; exit $LASTEXITCODE } catch { Write-Host ('[ERROR] '+$_.Exception.Message); exit 1 } finally { if ($tempFile) { Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue } }"
set "PI_SETUP_RESULT=%errorlevel%"
echo.
if not "%PI_SETUP_RESULT%"=="0" echo Installation failed. Read the error above. Run this file again after fixing it.
pause
exit /b %PI_SETUP_RESULT%
