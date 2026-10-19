---
name: maintain-preferences
description: Propose or apply user-confirmed changes to stable preferences, preserving explicit consent and keeping project state and session handoffs separate.
---

# 维护稳定偏好

先读取 `context/memory-policy.md`、`context/privacy.md` 及当前 `context/preferences.json`。没有文件访问能力时，使用用户提供的当前版本；未获得当前内容时不要声称已完成合并。

1. 判断信息的归属：跨任务的稳定偏好、项目规范/动态，还是会话交接。单次任务行为不能推导全局偏好；秘密或个人敏感信息不能保存。
2. 展示具体新增、修改或删除内容、适用范围与不敏感来源摘要，可使用 `templates/preference-change.md`。
3. 用户手动编辑，或已有明确同意覆盖该具体内容及范围时，才更新源文件。授权不足时给出待审提案；不以沉默或仓库写权限代替同意。
4. 条目记录唯一 `id`、`statement`、`scope`、`confirmed_on`、`source`。不虚构确认日期或来源。修改或删除时保留无关条目，执行仓库校验并审阅差异。
5. 明确实际修改及提交状态，提醒已有上传包需要重新生成。本 Skill 不同步或修改平台内置记忆。
