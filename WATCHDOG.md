# QoolUI4 Watchdog

从根目录 `AGENTS.md` 与实战经验提炼的关键要点，供长时间会话中持续盯防；完整依据以 AGENTS.md 为准。

## QML 语言陷阱

- **Loader 的 sourceComponent 内联组件不要加 id**：id 只在本组件作用域可见（Component Scope 规则，文档化语言规则非风格惯例），Loader 外部无法经 id 访问加载对象——必须用 `loader.item`；且动态作用域下内部 id 会遮蔽祖先同名名（scope 混淆）。来源：TextField 实施时无引用 `id: field` 被纠正，2026-08-10。
- **实例上的信号 handler 覆盖组件定义内的同名 handler**：同一对象同一信号只有一个 handler，实例赋值覆盖组件定义值——派生/复用组件时，实例上写 `onEditingFinished` 会吞掉基座内部定义的同名 handler（TextField 编辑层的 onEditingFinished 曾覆盖 BasicTextField 的 rejected 判定）。复用带内部信号处理的组件时，外部触发改用不冲突的信号（如 onActiveFocusChanged），2026-08-10。
