# rea-skill · 个人知识与工作流

在不同 AI 之间复用**经用户选择并审核的上下文、Skills 和工作约定**。Markdown / JSON / YAML 是唯一事实源，Git 负责版本管理；各平台入口和导出包只引用或派生自这些文件。

这是私有知识仓库，不是聊天记录备份器。初版没有导入个人资料、真实项目或历史对话，也没有替用户设定长期偏好。

## 目录与事实归属

| 路径 | 保存什么 | 何时更新 |
| --- | --- | --- |
| [context/](context/README.md) | 通用工作规则、隐私规则、记忆维护规则、稳定偏好 | 用户手动维护，或明确授权具体更新 |
| [projects/](projects/README.md) | 每个项目的范围、规范、动态状态和决策 | 在已授权的项目维护范围内更新，注明证据和时间 |
| [handoffs/](handoffs/README.md) | 一次会话的交接快照、已验证结果、下一步 | 用户要求交接时新建；不自动升级为长期记忆 |
| [skills/](skills/README.md) | 可复用、带 SKILL.md 的工作流程 | 按实际复用需求维护 |
| [templates/](templates/README.md) | 项目、交接、偏好变更、Skill 模板 | 根据使用情况改进 |
| [scripts/](scripts/README.md) | 本地校验、按需导出、工具自检 | 不联网，不调用 AI，不安装或修改平台设置 |
| [AGENTS.md](AGENTS.md) / [CLAUDE.md](CLAUDE.md) | Codex / Claude Code 的薄入口 | 规则变化时更新引用；不复制偏好副本 |

`projects/example/` 和 `handoffs/example/` 均为虚构示例，不是用户的实际项目。`.local/` 用于未审核草稿和派生包，默认不提交。

## 开始使用

使用你已有的 GitHub 认证方式克隆私有仓库；不要把令牌放进 URL：

```sh
git clone https://github.com/Brian23-j/rea-skill.git
cd rea-skill
python3 scripts/validate.py
python3 -m unittest discover -s scripts -p 'test_*.py'
```

需要 Python 3.10+ 和 Git。可从 [项目模板](templates/project.md)、[状态模板](templates/status.md) 创建 `projects/<项目代号>/PROJECT.md` 与 `STATUS.md`，将真实姓名等改为不敏感的代号。偏好初始为空，只有用户确认的、适合长期复用的信息才进入 [preferences.json](context/preferences.json)。

## 在不同 AI 中使用

### ChatGPT 和 Claude 网页聊天

让有权限的连接工具读取**明确的分支或提交**及所需文件，并要求 AI 列出实际读到的路径、版本和缺失信息。仅贴私有仓库 URL 不保证 AI 能访问内容；无法读取时，手动上传经过检查的上下文包。

```sh
mkdir -p .local
python3 scripts/export_context.py > .local/context.md
# 仅增加明确选定的项目、交接与 Skill；以下为虚构演示
python3 scripts/export_context.py --project example \
  --handoff handoffs/example/2026-10-20-demo.md \
  --skill resume-work > .local/example-context.md
```

默认包只含通用规则、隐私规则、记忆规则和已确认偏好，不扫描全部项目或交接。检查生成包，再上传或粘贴到新聊天；导出并不等于授权上传。可以配合 [启动提示模板](templates/start-session.md)。没有工具的聊天只能提出修改文本，不能声称已经提交仓库。

### Codex

在本仓库克隆目录中开始任务，入口为根目录 `AGENTS.md`。请显式指定项目、交接文件和需要的 Skill，并让 AI 确认已读文件。`skills/` 是中立来源目录，不能假定平台会自动发现它。

如希望本地 Codex 自动发现 Skills，可在**本克隆目录**中建立本地链接；目标已存在时先检查，不覆盖：

```sh
mkdir -p .agents
ln -s ../skills .agents/skills
```

也可以直接要求“读取 `skills/resume-work/SKILL.md` 并按它继续工作”。链接仅是可选适配，不会安装到全局，也不会赋予任何工具权限。其他代码仓库不会自动加载本仓库规则；应在那个任务中明确提供经过选择的文件或上下文包。

### Claude Code

在本克隆目录启动；`CLAUDE.md` 引用同一份中立规则。需要 Skills 自动发现时，可建立本地适配链接：

```sh
mkdir -p .claude
ln -s ../skills .claude/skills
```

目标已存在则先检查，不替换已有配置。重新打开会话并确认发现了哪些 Skills；若版本或运行环境不识别链接，直接读取选定的 `SKILL.md`。不要将 Claude Code 的目录机制等同于 Claude 网页版的上传机制。

平台机制参考（2026-10-20 核对，后续以官方文档为准）：[Codex AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)、[Codex Skills](https://learn.chatgpt.com/docs/build-skills)、[Claude Code 项目记忆](https://code.claude.com/docs/en/memory)、[Claude Code Skills](https://code.claude.com/docs/en/skills)。

## 日常维护与切换

1. 开始前更新本地版本：工作区干净时运行 `git pull --ff-only`；有改动时先审查、提交到分支，避免丢失草稿。
2. 只读取当前任务所需内容；核对项目状态与交接时间，遇到矛盾先验证现状。
3. 结束时按 [交接模板](templates/handoff.md) 提炼目标、验证证据、未完成事项和下一步，不保存原始对话。
4. 长期偏好变更先给出具体差异及保存范围；本次明确授权已经覆盖的更新无需重复询问。授权不明时保留待审建议，不写入长期记忆。
5. 提交前运行校验和工具自检，检查 `git diff` 与 `git diff --cached`，仅暂存本次审核过的具体文件。在分支中提交并通过 PR 审阅；不要使用强制推送来解决同步冲突。
6. 新 AI 读取同一提交下的选定文件或导出包，说明已知事实和待验证事项后继续。

示例：

```sh
git switch -c update/project-context
python3 scripts/validate.py
git diff
# 只暂存实际改动且审核过的文件，例如：
git add projects/example/STATUS.md
git diff --cached
git commit -m "docs: update reviewed project status"
git push -u origin update/project-context
```

## 隐私和同步边界

必须遵守 [隐私规则](context/privacy.md) 和 [长期记忆规则](context/memory-policy.md)。**禁止提交 API Key、密码、私钥、访问令牌、Cookie、原始对话及个人敏感信息**；私有仓库也不适合存放这些数据。忽略规则和校验都不能替代人工审查，也不会删除已经进入 Git 历史的内容。

仓库同步的是文件版本，不会自动同步各 AI 的全部对话、平台内置记忆、隐藏状态、插件、账号凭证、工具权限或运行环境。云端也不自动获得本地文件。上传包是一个快照；后续修改需重新拉取或导出。平台的持久化记忆可能另行启用，应在各自设置中检查和控制，本仓库不能替你关闭它们。

没有配置后台采集、定时同步、自动记忆写入或自动提交。所有示例都是示例；只有经验证并注明来源的项目事实才应被下一位 AI 当作工作依据。
