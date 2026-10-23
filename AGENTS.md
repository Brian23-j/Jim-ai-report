# AI 工作入口

先读取 [context/rules.md](context/rules.md)、[context/privacy.md](context/privacy.md)、[context/memory-policy.md](context/memory-policy.md) 和 [context/preferences.json](context/preferences.json)，再按当前任务读取对应项目、指定交接和需要的 Skill。

以上文件是平台中立的事实源；此入口不维护规则副本。无法读取某个引用时明确说明缺失，不推测其内容。不要批量读取所有项目或把示例当成用户事实。

维护本仓库时：Python 3.10+，仅标准库；运行 `python3 scripts/validate.py` 和 `python3 -m unittest discover -s scripts -p 'test_*.py'`，审阅具体差异后提交。写权限不代表可自动更新长期记忆。
