# pi-web Windows 安装环境

这套脚本面向第一次安装人工智能环境的 Windows 用户，用于安装并运行 `pi-web`。

## 安装

1. 下载本目录中的 `install-pi-web.bat`。
2. 双击运行，脚本会检查或安装 Node.js 22，并安装最新版 `@agegr/pi-web`。
3. 按提示输入 `Y`，启动 pi-web。
4. 浏览器打开 <http://127.0.0.1:30141>。

安装脚本还会创建后台启动器、登录启动任务和每 5 分钟检查一次的看门狗任务。

## 日常管理

把 `pi.bat` 放在容易找到的位置，在命令提示符中运行：

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
- Node.js 22 或更高版本；缺少时安装脚本会尝试自动安装
