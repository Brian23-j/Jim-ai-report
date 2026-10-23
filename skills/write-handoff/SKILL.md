---
name: write-handoff
description: Prepare a compact evidence-based session handoff when the user requests a handoff or wants to switch AI assistants.
---

# 整理交接

用户要求交接时，先读取根目录的中立工作、隐私和记忆规则。以本次实际观察为依据，使用 `templates/handoff.md` 的字段；只有上传包时，按目标、范围、版本、已完成、已验证、未验证、阻塞和下一步这些字段组织。

- 写明检查时间及可复现证据；把执行成功与最终结果生效分开，把缺少验证的事项明确列出。
- 只保留继续工作需要的资料，去掉凭证、个人敏感信息及原始对话。
- 明确来源版本、授权边界和必须重新检查的动态状态；不承诺另一个 AI 已加载。
- 需要保存且已获相应维护授权时，新建 `handoffs/<项目代号>/<日期>-<主题>.md`，不覆盖同名快照，并在项目 `STATUS.md` 指向本次交接。没有写权限时提供可复制文本，说明尚未写入。
- 交接不自动变成长期偏好；只有明确同意的具体长期变更才写入 `context/preferences.json`。

交付时给出保存位置或文本，以及尚未验证的事项。
