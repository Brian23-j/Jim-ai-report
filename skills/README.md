# 可复用工作流程

中立源文件放在 `skills/<skill-name>/SKILL.md`。必须包含 YAML frontmatter 的 `name` 和 `description`，名称与文件夹一致，使用小写字母、数字和连字符；描述说明何时使用。

初版提供：

- [resume-work](resume-work/SKILL.md)：选择最小上下文、核实状态后接手任务。
- [write-handoff](write-handoff/SKILL.md)：根据已观察事实整理会话交接。
- [maintain-preferences](maintain-preferences/SKILL.md)：提出或执行明确获同意的稳定偏好变更。

这些 Skill 不依赖某个平台工具，不包含自执行代码。平台入口及可选本地链接见根目录 README；仅有此目录不保证每个平台自动发现或执行。其他平台直接读取选定 `SKILL.md` 即可。模板位于 `templates/skill.md`，仅在有实际需求时增加脚本或参考资料。
