@echo off
rem ============================================
rem  pi 快捷命令 - pi-web 管理工具
rem  用法: pi start | pi stop | pi status | pi log | pi open
rem ============================================
setlocal EnableDelayedExpansion
set "LAUNCHER=%APPDATA%\pi-web-launcher.cmd"
set "LOGFILE=%APPDATA%\pi-web.log"
set "ERRLOG=%APPDATA%\pi-web.err.log"
set "FLAG=%APPDATA%\pi-web-running.flag"

if "%~1"=="" goto :usage

if /i "%~1"=="start" (
    call pi-web status 2>nul | findstr /i "30141" >nul && (
        echo pi-web 已在运行: http://127.0.0.1:30141
    ) || (
        echo 正在后台启动 pi-web ...
        call "!LAUNCHER!"
        timeout /t 3 /nobreak >nul
        call pi-web status
        echo 已启动。关掉本终端 pi-web 继续运行。
    )
    goto :eof
)

if /i "%~1"=="stop" (
    echo 正在停止 pi-web ...
    call pi-web stop
    del /q "!FLAG!" >nul 2>nul
    echo 已停止。
    goto :eof
)

if /i "%~1"=="status" (
    call pi-web status
    goto :eof
)

if /i "%~1"=="open" (
    start http://127.0.0.1:30141
    goto :eof
)

if /i "%~1"=="log" (
    echo ===== stdout 最后 50 行 =====
    powershell -NoProfile -Command "Get-Content '!LOGFILE!' -Tail 50 -ErrorAction SilentlyContinue"
    echo ===== stderr 最后 20 行 =====
    powershell -NoProfile -Command "Get-Content '!ERRLOG!' -Tail 20 -ErrorAction SilentlyContinue"
    goto :eof
)

if /i "%~1"=="update" (
    call pi-web stop
    call npm install -g @agegr/pi-web@latest
    echo 更新完成，正在重新启动...
    call "!LAUNCHER!"
    goto :eof
)

:usage
echo 用法: pi start ^| stop ^| status ^| open ^| log ^| update
goto :eof
