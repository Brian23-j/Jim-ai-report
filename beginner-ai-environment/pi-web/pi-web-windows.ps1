param(
    [ValidateSet('install', 'start', 'stop', 'status', 'open', 'log', 'update', 'watchdog')]
    [string]$Action = 'status'
)
$ErrorActionPreference = 'Stop'
$InstallDir = Join-Path $env:LOCALAPPDATA 'pi-web-manager'
$Port = 30141

function Refresh-Path {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user;$env:Path"
}
function Get-Node {
    $command = Get-Command node.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    throw 'node.exe was not found. Run install-pi-web.bat again.'
}
function Test-Node {
    try {
        $node = Get-Node
        $version = & $node -p 'process.versions.node'
        return ($LASTEXITCODE -eq 0 -and [version]$version -ge [version]'22.19.0')
    } catch { return $false }
}
function Get-Npm {
    $command = Get-Command npm.cmd -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    throw 'npm.cmd was not found. Reinstall Node.js with npm included.'
}
function Invoke-Npm([string[]]$NpmArgs) {
    $npm = Get-Npm
    & $npm @NpmArgs
    if ($LASTEXITCODE -ne 0) { throw "npm failed (exit $LASTEXITCODE)." }
}
function Get-Entry {
    $npm = Get-Npm
    $lines = & $npm root -g
    if ($LASTEXITCODE -ne 0) { throw 'npm root -g failed.' }
    $root = ($lines | Select-Object -Last 1).Trim()
    $entry = Join-Path $root '@agegr\pi-web\bin\pi-web.js'
    if (!(Test-Path -LiteralPath $entry -PathType Leaf)) {
        throw "pi-web entry file is missing: $entry. Run install-pi-web.bat again."
    }
    return $entry
}
function Invoke-Pi([string[]]$PiArgs) {
    $node = Get-Node
    $entry = Get-Entry
    & $node $entry @PiArgs
    if ($LASTEXITCODE -ne 0) { throw "pi-web failed (exit $LASTEXITCODE)." }
}
function Test-Running {
    $node = Get-Node
    $entry = Get-Entry
    $status = & $node $entry status 2>&1
    return ($LASTEXITCODE -eq 0 -and ($status -join "`n") -match 'https?://[^\s]*:30141(?:/|\s|$)')
}
function Start-Pi {
    if (Test-Running) { Write-Host "pi-web is running: http://127.0.0.1:$Port"; return }
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    $node = Get-Node
    $entry = Get-Entry
    $env:PI_WEB_IDLE_TIMEOUT_MS = '0'
    $env:PI_WEB_NO_OPEN = '1'
    $arguments = '"{0}" --port {1}' -f $entry, $Port
    $process = Start-Process -FilePath $node -ArgumentList $arguments -WindowStyle Hidden -WorkingDirectory $InstallDir -RedirectStandardOutput (Join-Path $InstallDir 'pi-web.log') -RedirectStandardError (Join-Path $InstallDir 'pi-web.err.log') -PassThru
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 1
        if (Test-Running) { Write-Host "pi-web is running: http://127.0.0.1:$Port"; return }
        $process.Refresh()
        if ($process.HasExited) { break }
    }
    throw "Startup was not confirmed. Read logs with pi log ($InstallDir)."
}
function Install-Manager {
    if (!(Test-Node)) {
        Write-Host 'Installing Node.js LTS...'
        $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
        if ($winget) {
            & $winget.Source install --id OpenJS.NodeJS.LTS --exact --accept-source-agreements --accept-package-agreements
            Refresh-Path
        }
        if (!(Test-Node)) {
            $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') { 'arm64' } else { 'x64' }
            $msi = Join-Path $env:TEMP ('pi-web-node-' + [guid]::NewGuid().ToString() + '.msi')
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -UseBasicParsing -Uri "https://nodejs.org/dist/v22.19.0/node-v22.19.0-$arch.msi" -OutFile $msi
                $result = Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" -ArgumentList @('/i', "`"$msi`"", '/passive', '/norestart') -Wait -PassThru
                if ($result.ExitCode -notin @(0, 3010)) { throw "Node.js installer failed (exit $($result.ExitCode))." }
            } finally { Remove-Item -LiteralPath $msi -Force -ErrorAction SilentlyContinue }
            Refresh-Path
        }
    }
    if (!(Test-Node)) { throw 'Node.js 22.19.0+ is required. Finish installation, then run this installer again.' }
    Invoke-Npm -NpmArgs @('install', '-g', '@agegr/pi-web@latest')
    Refresh-Path
    $null = Get-Entry
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    $target = Join-Path $InstallDir 'pi-web-windows.ps1'
    if ([IO.Path]::GetFullPath($PSCommandPath) -ne [IO.Path]::GetFullPath($target)) {
        Copy-Item -LiteralPath $PSCommandPath -Destination $target -Force
    }
    $wrapper = @'
@echo off
setlocal
if "%~1"=="" goto usage
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0pi-web-windows.ps1" -Action "%~1"
exit /b %errorlevel%
:usage
echo Usage: pi start ^| stop ^| status ^| open ^| log ^| update
exit /b 0
'@
    Set-Content -LiteralPath (Join-Path $InstallDir 'pi.cmd') -Value $wrapper -Encoding ASCII
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (@($userPath -split ';') -notcontains $InstallDir) {
        [Environment]::SetEnvironmentVariable('Path', "$userPath;$InstallDir", 'User')
    }
    # Replace the old flag-based tasks and broken launcher only during installation.
    foreach ($name in @('pi-web-autostart', 'pi-web-watchdog')) {
        try {
            $task = Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
            if ($task) { Unregister-ScheduledTask -TaskName $name -Confirm:$false }
        } catch { throw "Old task cleanup failed for ${name}: $($_.Exception.Message). Run this installer as administrator once." }
    }
    $startup = [Environment]::GetFolderPath('Startup')
    $legacy = Join-Path $startup 'pi-web-autostart.cmd'
    Remove-Item -LiteralPath $legacy -Force -ErrorAction SilentlyContinue
    $powershell = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut((Join-Path $startup 'pi-web-autostart.lnk'))
    $shortcut.TargetPath = $powershell
    $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$target`" -Action start"
    $shortcut.WorkingDirectory = $InstallDir
    $shortcut.WindowStyle = 7
    $shortcut.Save()
    # Interactive user task: use the same account and PATH as the installed app.
    try {
        $taskAction = New-ScheduledTaskAction -Execute $powershell -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$target`" -Action watchdog"
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Minutes 5)
        $principal = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
        Register-ScheduledTask -TaskName 'pi-web-watchdog' -Action $taskAction -Trigger $trigger -Principal $principal -Force | Out-Null
    } catch { Write-Host "Watchdog registration failed: $($_.Exception.Message). Login startup is installed." }
    Remove-Item -LiteralPath (Join-Path $InstallDir 'stopped') -Force -ErrorAction SilentlyContinue
    Start-Pi
    Start-Process "http://127.0.0.1:$Port"
    Write-Host "Installed in $InstallDir. Open a new Command Prompt to use pi start / stop / status / log."
}
try {
    Refresh-Path
    switch ($Action) {
        'install' { Install-Manager }
        'start' {
            Remove-Item -LiteralPath (Join-Path $InstallDir 'stopped') -Force -ErrorAction SilentlyContinue
            Start-Pi
        }
        'stop' {
            New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $InstallDir 'stopped') -Value 'manual stop'
            if (Test-Running) { Invoke-Pi -PiArgs @('stop', '--port', "$Port") }
        }
        'status' { Invoke-Pi -PiArgs @('status') }
        'open' { Start-Process "http://127.0.0.1:$Port" }
        'log' {
            foreach ($name in @('pi-web.log', 'pi-web.err.log')) {
                Write-Host "===== $name ====="
                $file = Join-Path $InstallDir $name
                if (Test-Path -LiteralPath $file) { Get-Content -LiteralPath $file -Tail 50 }
                else { Write-Host "Log has not been created: $file" }
            }
        }
        'update' {
            New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $InstallDir 'stopped') -Value 'update in progress'
            if (Test-Running) { Invoke-Pi -PiArgs @('stop', '--port', "$Port") }
            Invoke-Npm -NpmArgs @('install', '-g', '@agegr/pi-web@latest')
            Remove-Item -LiteralPath (Join-Path $InstallDir 'stopped') -Force
            Start-Pi
        }
        'watchdog' { if (!(Test-Path -LiteralPath (Join-Path $InstallDir 'stopped'))) { Start-Pi } }
    }
    exit 0
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
