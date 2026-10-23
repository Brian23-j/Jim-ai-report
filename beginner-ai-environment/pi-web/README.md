# pi-web Windows 安装环境

这套脚本面向第一次安装人工智能环境的 Windows 用户，用于安装并运行 `pi-web`。

## 安装

1. 下载本目录中的 `install-pi-web.bat`。
2. 确认 `node -v` 显示 Node.js 22.19.0 或更高版本，再双击运行安装脚本，安装最新版 `@agegr/pi-web`。

   原始脚本只检查 Node.js 主版本，直装回退包为 22.14.0；该回退版本低于脚本头部声明的最低要求。Node.js 安装入口：<https://nodejs.org/en/download>。
3. 按提示输入 `Y`，启动 pi-web。
4. 浏览器打开 <http://127.0.0.1:30141>。

安装脚本还会创建后台启动器、登录启动任务和每 5 分钟检查一次的看门狗任务。

## 日常管理

把 `pi.bat` 保存到固定文件夹，例如 `C:\AI\pi-web`。打开命令提示符，先运行 `cd /d C:\AI\pi-web`，再执行：

```text
pi start    启动 pi-web
pi stop     停止 pi-web
pi status   查看运行状态
pi open     打开网页界面
pi log      查看最近日志
pi update   更新 pi-web
```

## 文件说明

- `install-pi-web.bat`：首次安装 Node.js、pi-web，并配置后台运行。
- `pi.bat`：安装完成后的启动、停止、状态、日志和更新命令。

## 运行条件

- Windows
- 可访问网络
- PowerShell
- Node.js 22.19.0 或更高版本

两个脚本按用户提供的原始字节保存，当前验证覆盖文件完整性与仓库结构；Windows 实机安装效果待验证。
