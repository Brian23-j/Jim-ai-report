# 本地工具

需要 Python 3.10+。Windows `.bat` / `.cmd` 文件兼容 UTF-8 与 GBK / GB18030 编码，其余自建文本按 UTF-8 校验。仅使用标准库，不联网，不调用 AI，不读平台配置，不自动安装、提交或写入长期记忆。

## 校验

```sh
python3 scripts/validate.py
python3 -m unittest discover -s scripts -p 'test_*.py'
```

校验必要目录、JSON 偏好结构、Skill 必填字段、Markdown 相对文件引用和常见凭证线索。Skill frontmatter 的 `name` / `description` 在本仓库使用单行标量；这是本工具的检查子集，不是完整 YAML 解析器。

在 Git 仓库中检查已跟踪文件和未忽略的新文件，因此已被跟踪但后来加入忽略规则的秘密文件仍会被检查。非 Git 目录使用文件遍历，跳过 `.git/`、`.local/`、`exports/`、虚拟环境和 Python 缓存。符号链接默认拒绝，只允许文档中指定的两个本地 Skills 链接指回本仓库 `skills/`。单文件限制 256 KiB。

凭证检查只报告路径、行号和类型，不打印命中值。它不能识别全部秘密、个人敏感信息或历史泄露，不能代替人工审查、专用 secret scanner 或凭证轮换。没有配置 CI；本地运行是提交前的维护步骤。

`library/` 为第三方导入输入，按其 `manifest.json` 核对文件集合、大小与 SHA-256，拒绝越界、符号链接、敏感文件名及常见令牌/私钥格式，并检查 ZIP/JAR 完整性和成员路径。不会执行包中代码；不对第三方的原始文档链接、Skill 方言或 JSON 业务结构套用自建内容的格式检查。单个导入文件上限 16 MiB。示例中的凭证赋值经导入时人工审阅及占位符替换，后续维护仍需审查差异。

## 按需导出

```sh
python3 scripts/export_context.py
python3 scripts/export_context.py --project example \
  --handoff handoffs/example/2026-10-20-demo.md \
  --skill resume-work --skill write-handoff
```

输出 UTF-8 Markdown 到标准输出，需手动重定向到 `.local/` 才保存。默认四个中立源文件：工作、隐私、记忆规则和偏好。项目参数只增加 `PROJECT.md` / `STATUS.md`；交接必须显式指定，且属于选定项目。Skill 参数可重复，只导出该 Skill 的 `SKILL.md`，**不自动追踪 Skill 引用的资源或嵌套文件**；需要这些资料时自行审阅并提供。

包中标注生成 UTC 时间、来源 Git 提交（非 Git 目录为 unknown）、工作区状态及每个来源文件的 SHA-256。未提交改动存在时，提交号不能代表全部内容，应以文件哈希区分快照。总输入最多 512 KiB；这是字节限制，不是 token 限制。

导出器拒绝越界路径、符号链接、缺失文件及命中基础凭证规则的选定内容；不会上传或自动脱敏。Markdown 中的引用仍是来源路径，不保证上传后能跳转。运行后必须审查内容，确认符合本次任务的披露范围。
