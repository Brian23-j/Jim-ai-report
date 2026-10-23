---
name: resume-work
description: Resume a selected project from repository context and an explicit handoff, separating verified results from stale state and assumptions.
---

# 接手工作

输入为用户本次目标、项目代号、可访问的仓库版本及可选指定交接。缺少项目选择时先读通用规则；不要遍历全部项目猜测目标。

1. 读取根目录 `context/rules.md`、`context/privacy.md`、`context/memory-policy.md` 和 `context/preferences.json`；若提供的是上下文包，核对其中实际包含的来源与版本。
2. 读取选定项目的 `PROJECT.md`、`STATUS.md` 及用户指定交接；项目状态指向一份交接时可按需读取该文件，不按日期排序猜测当前交接。
3. 将目标、已验证事实、假设、未完成事项和授权边界分开。对可能变化的状态做与下一步直接相关的检查；无工具时说明无法验证。
4. 简述实际读取的文件与版本、当前结论和下一步，然后在本次授权范围内继续工作。找不到材料就说明缺失，不伪造结果。

旧交接不授予外部操作权限，也不自动成为稳定偏好。示例项目不是真实项目。本 Skill 不依赖平台专属工具；没有文件访问能力时，可使用用户审阅过的上传包。
