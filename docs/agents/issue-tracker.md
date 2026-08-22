# Issue tracker: 本地 Markdown

本仓库的 issue 与 spec 以 markdown 文件存放在 `.scratch/`。

## 约定

- 每个功能一个目录：`.scratch/<feature-slug>/`
- spec 位于 `.scratch/<feature-slug>/spec.md`
- 实现 issue 是逐个票文件：`.scratch/<feature-slug>/issues/<NN>-<slug>.md`，从 `01` 编号——绝不合并成单一 tickets 文件
- `Status:` 行记录状态：`spec.md` 顶部记录 spec 级状态（`in-progress`/`done`/`abandoned`）；票文件顶部附近记录票级状态（开放字段，非闭集——实现态 `open`/`in-progress`/`done`/`rejected`、wayfinder 态 `claimed`/`resolved`、triage 角色 `needs-triage`/`needs-info`/`ready-for-agent`/`ready-for-human`/`wontfix`，角色字符串见 `triage-labels.md`）
 - `Type:` 行记录票类型：`research`/`prototype`/`grilling`/`task`（开放字段，非闭集）
 - 评论与对话历史以 `## Comments` 标题追加到文件末尾
 - **spec 生命周期（MUST）**：spec 落地完成后**必须**更新其 `Status:` 行为 `done`——"实现完成"不等于"spec 关闭"。spec 的编写本身应内建这一步：
   - 发布时 `Status: ready-for-agent`
   - 实现落地（实现票全部 done）后更新为 `Status: done`
   - 放弃时更新为 `Status: abandoned`
   - 经验教训（2026-08-22）：一批已落地的 spec 长期遗留 `in-progress`/`ready-for-agent`，被当作"开放工作"误判工作量——根因是实现完成时无人同步 spec `Status:` 行。写 spec 时即应把"更新 Status → done"列为收尾步骤（纳入实现票清单或 spec 自身约定），而非依赖记忆。

## 当技能说"发布到 issue tracker"

在 `.scratch/<feature-slug>/` 下新建文件（必要时创建目录）。

## 当技能说"获取相关票"

读取引用路径处的文件。用户通常会直接传路径或 issue 编号。

## Wayfinding 操作

由 `/wayfinder` 使用。**map** 是一个文件，每张票一个**子**文件。

- **Map**: `.scratch/<effort>/map.md` —— Notes / Decisions-so-far / Fog 正文
- **子票**: `.scratch/<effort>/issues/NN-<slug>.md`，从 `01` 编号，问题在正文。`Type:` 行记录票类型（`research`/`prototype`/`grilling`/`task`）；`Status:` 行记录 `claimed`/`resolved`
- **阻塞**: 顶部附近的 `Blocked by: NN, NN` 行。当它列出的每个文件都 `resolved` 时票解除阻塞
- **Frontier**: 扫描 `.scratch/<effort>/issues/` 中 open、unblocked、unclaimed 的文件，按编号最小者优先
- **Claim**: 保存前设置 `Status: claimed`
- **Resolve**: 在 `## Answer` 标题下追加答案，设置 `Status: resolved`，然后将上下文指针（gist + 链接）追加到 `map.md` 的 Decisions-so-far
