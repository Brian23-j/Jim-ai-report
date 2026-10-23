@echo off
rem ============================================
rem  pi-web 一键安装/环境补齐脚本 (Windows)
rem  仓库: https://github.com/agegr/pi-web
rem  要求: Node.js >= 22.19.0
rem ============================================
setlocal EnableDelayedExpansion

set "NODE_MIN=22"
set "PI_PKG=@agegr/pi-web"

echo.
echo ======== [1/4] 检查 Node.js ========
set "NODE_OK=0"
where node >nul 2>nul && (
    for /f "tokens=* usebackq" %%v in (`node -v`) do set "NODEVER=%%v"
    echo 当前 Node 版本: !NODEVER!
    rem 检查主版本 >= 22 (pi-web 要求 >= 22.19.0)
    for /f "tokens=1 delims=v." %%a in ("!NODEVER!") do (
        if %%a GEQ %NODE_MIN% set "NODE_OK=1"
    )
)
if "!NODE_OK!"=="1" (
    echo Node 版本满足要求，跳过安装。
) else (
    echo 未检测到 Node 或版本过低，开始安装 Node LTS 22 ...
    where winget >nul 2>nul && (
        winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    ) || (
        echo winget 可用，改用 PowerShell 直装 Node v22 LTS MSI ...
        powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v22.14.0/node-v22.14.0-x64.msi' -OutFile \"$env:TEMP\node-lts.msi\"; Start-Process msiexec -ArgumentList '/i',\"$env:TEMP\node-lts.msi\",'/qn' -Wait"
    )
    rem 刷新当前会话 PATH
    for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%b"
    for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USR_PATH=%%b"
    set "PATH=%SYS_PATH%;%USR_PATH%"
    where node >nul 2>nul || (
        echo [错误] Node 安装完成但当前终端找不到，请关闭本窗口重新双击本脚本一次即可。
        pause & exit /b 1
    )
    echo Node 安装成功: 
    node -v
)

echo.
echo ======== [2/4] 检查/安装 pi-web ========
call npm ls -g %PI_PKG% >nul 2>nul
if not errorlevel 1 (
    echo pi-web 已安装，跳过。如需更新可运行: pi-web stop ^&^& npm install -g %PI_PKG%@latest
) else (
    echo 正在全局安装 %PI_PKG% ...
    call npm install -g %PI_PKG%@latest
    if errorlevel 1 (
        echo [错误] pi-web 安装失败，请检查网络后重试。
        pause & exit /b 1
    )
    echo pi-web 安装成功。
)

echo.
echo ======== [3/4] 创建后台启动器 ========
set "LAUNCHER=%APPDATA%\pi-web-launcher.cmd"
> "!LAUNCHER!" (
    @echo off
    rem pi-web 后台启动器: 隐藏窗口 + 禁用10分钟空闲自动关服 + 日志
    set "PI_WEB_IDLE_TIMEOUT_MS=0"
    set "PI_WEB_NO_OPEN=0"
    powershell -NoProfile -Command "Start-Process -WindowStyle Hidden -FilePath 'pi-web.cmd' -ArgumentList 'start','--port','30141' -RedirectStandardOutput '%APPDATA%\pi-web.log' -RedirectStandardError '%APPDATA%\pi-web.err.log'"
)
echo 启动器已写入: !LAUNCHER!

echo.
echo ======== [4/4] 注册开机自启 + 崩溃守护 ========
rem 开机自启(用户登录时)
schtasks /Create /F /TN "pi-web-autostart" /SC ONLOGON /RL HIGHEST /TR "\"%ComSpec%\" /c \"!LAUNCHER!\"" >nul 2>nul
if errorlevel 1 (
    echo [提示] 计划任务创建失败，改用启动文件夹方式...
    copy /y "!LAUNCHER!" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\pi-web-autostart.cmd" >nul
)
rem 看门狗: 每5分钟检查，若 pi-web 未运行则拉起
schtasks /Create /F /TN "pi-web-watchdog" /SC MINUTE /MO 5 /TR "\"%ComSpec%\" /c \"if not exist '%APPDATA%\pi-web-running.flag' call '!LAUNCHER!'\"" >nul 2>nul
rem 标记文件由启动逻辑维护
> "%APPDATA%\pi-web-running.flag" echo started

echo.
echo ============================================
echo  安装完成！可用命令:
echo    pi start   - 后台启动 (关终端也继续运行)
echo    pi stop    - 停止
echo    pi status  - 查看状态
echo    pi log     - 查看日志
echo  首次启动后浏览器自动打开 http://127.0.0.1:30141
echo ============================================
echo.
set /p STARTNOW=是否现在启动 pi-web? (Y/N): 
if /i "!STARTNOW!"=="Y" call "%APPDATA%\pi-web-launcher.cmd" & echo 已启动。
pause
