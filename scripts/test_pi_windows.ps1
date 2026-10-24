# Run with Windows PowerShell 5.1+ or pwsh. Mocks avoid installation and task changes.
$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot '../beginner-ai-environment/pi-web/pi-web-windows.ps1'
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($source, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors -join "`n") }
$functions = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)
foreach ($definition in $functions) { . ([scriptblock]::Create($definition.Extent.Text)) }
function Assert($condition, $message) { if (!$condition) { throw $message } }
$script:fakeVersion = '22.18.0'
function Fake-Node {
    $global:LASTEXITCODE = 0
    if ($args[0] -eq '-p') { return $script:fakeVersion }
    return $script:fakeStatus
}
function Get-Node { return 'Fake-Node' }
Assert (!(Test-Node)) 'Node 22.18.0 must fail version validation.'
$script:fakeVersion = '22.19.0'
Assert (Test-Node) 'Node 22.19.0 must pass version validation.'
$script:fakeVersion = '24.1.0'
Assert (Test-Node) 'Newer Node versions must pass version validation.'

function Get-Entry { return 'C:\Users\Test User\node_modules\@agegr\pi-web\bin\pi-web.js' }
$script:fakeStatus = 'No pi-web server is running.'
Assert (!(Test-Running)) 'Empty server list must be stopped.'
$script:fakeStatus = '  http://127.0.0.1:301410  pid 42'
Assert (!(Test-Running)) 'A different port must not match.'
$script:fakeStatus = '  http://127.0.0.1:30141  pid 42'
Assert (Test-Running) 'Port 30141 must match.'

function Fake-Npm { $script:receivedArgs = @($args); $global:LASTEXITCODE = $script:npmExit }
function Get-Npm { return 'Fake-Npm' }
$script:npmExit = 0
Invoke-Npm -NpmArgs @('install', '-g', '@agegr/pi-web@latest')
Assert (($script:receivedArgs -join '|') -eq 'install|-g|@agegr/pi-web@latest') 'npm arguments must be preserved.'
$script:npmExit = 1
$failed = $false
try { Invoke-Npm -NpmArgs @('install') } catch { $failed = $true }
Assert $failed 'npm failure must terminate installation.'

# Verify the background launch command with a path containing spaces.
$InstallDir = Join-Path ([IO.Path]::GetTempPath()) ('pi-web-test-' + [guid]::NewGuid().ToString())
$Port = 30141
$script:checks = 0
function Test-Running { $script:checks++; return ($script:checks -gt 1) }
function Start-Sleep { param($Seconds) }
function Start-Process {
    param($FilePath, $ArgumentList, $WindowStyle, $WorkingDirectory, $RedirectStandardOutput, $RedirectStandardError, [switch]$PassThru)
    $script:launchFile = $FilePath
    $script:launchArgs = $ArgumentList
    $script:launchDirectory = $WorkingDirectory
    return [pscustomobject]@{ HasExited = $false }
}
try {
    Start-Pi
    Assert ($script:launchFile -eq 'Fake-Node') 'Launch must use resolved Node executable.'
    Assert ($script:launchArgs -eq '"C:\Users\Test User\node_modules\@agegr\pi-web\bin\pi-web.js" --port 30141') 'Entry path must be quoted and launch must omit the unsupported start subcommand.'
    Assert ($script:launchDirectory -eq $InstallDir) 'Launch must use the installed working directory.'
} finally { Remove-Item -LiteralPath $InstallDir -Recurse -Force -ErrorAction SilentlyContinue }
Write-Host 'PASS: syntax, Node versions, server status, npm errors and background launch arguments.'
