# pi-web Windows 安装环境

双击安装 Node.js、pi-web 和后台管理工具。安装器支持单独下载使用，管理脚本安装到 `%LOCALAPPDATA%\pi-web-manager`。

## 安装

1. 下载本目录的 `install-pi-web.cmd` 或 `install-pi-web.bat` 原始文件。GitHub 文件页面使用 **Download raw file**，保存后确认扩展名是 `.cmd` 或 `.bat`。
2. 双击运行。缺少同目录的 `pi-web-windows.ps1` 时，安装器从本仓库的 `main` 分支下载配套脚本；下载失败会显示地址对应的网络错误。
3. 脚本检查 Node.js 完整版本，最低 `22.19.0`。需要安装时优先使用 winget，回退使用 Node.js `22.19.0` MSI，并按 x64 / ARM64 选择包。Windows 安装界面弹出时完成安装。
4. 安装完成后，浏览器打开 <http://127.0.0.1:30141>。
5. 打开新的命令提示符窗口，运行 `pi status` 查看状态。

也可下载整个目录，在同目录保留 [`pi-web-windows.ps1`](pi-web-windows.ps1) 后双击安装器，此时直接使用本地配套脚本。

## 日常管理

安装器自动把管理目录加入当前用户 PATH。新打开的命令提示符可直接使用：

```text
pi start
pi stop
pi status
pi open
pi log
pi update
```

当前窗口尚未刷新 PATH 时，可直接运行：

```bat
"%LOCALAPPDATA%\pi-web-manager\pi.cmd" status
```

仓库中的 [`pi.bat`](pi.bat) 同样支持这些命令。直接双击它会显示命令用法。

## 后台运行

- 使用 `node.exe` 和 `bin\pi-web.js` 的绝对路径启动，运行目录固定为管理目录。
- 日志保存为管理目录的 `pi-web.log` 和 `pi-web.err.log`。
- 当前用户登录时通过启动文件夹快捷方式运行。
- 注册当前用户的每五分钟检查任务；任务注册失败时显示原因，登录启动仍可使用。
- `pi stop` 写入停止标记，守护任务尊重手动停止。`pi start` 清除标记并启动。
- 安装时清理旧版两个计划任务和旧版启动文件夹中的 `.cmd`。

## “找不到文件”的修复

旧版安装器生成启动文件时执行了内部命令，造成生成文件内容缺失；刷新 PATH 时读取旧变量；后台启动依赖 PATH 中的 `pi-web.cmd`。本版使用独立 PowerShell 文件和绝对路径，安装完成前检查入口文件实际存在，并确认服务器状态。

重新运行新版安装器覆盖管理文件。若仍有报错，窗口会保留具体错误。使用 `pi log` 查看启动日志。网络下载失败、npm 安装失败、Node 版本错误、入口文件缺失与启动超时均会显示对应原因。

## 文件说明与验证

| 文件 | 用途 |
| --- | --- |
| [install-pi-web.cmd](install-pi-web.cmd) | 双击安装入口 |
| [install-pi-web.bat](install-pi-web.bat) | 与 `.cmd` 相同的兼容入口 |
| [pi-web-windows.ps1](pi-web-windows.ps1) | 安装、路径解析、后台启动、管理和守护逻辑 |
| [pi.bat](pi.bat) | 管理入口 |

运行条件：Windows 10/11、Windows PowerShell 5.1、可访问 GitHub、Node.js 与 npm 下载服务。Node MSI 安装按系统设置请求提升权限。

脚本使用 ASCII 文本、批处理采用 CRLF，避免中文代码页影响命令解析。仓库结构校验和工具自检可在开发机运行；Windows 实机安装与登录任务效果仍需实机验证。

开发验证命令：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test_pi_windows.ps1
```

该测试用模拟命令验证版本、状态、参数和错误传播，保持本机安装与任务配置原样。
