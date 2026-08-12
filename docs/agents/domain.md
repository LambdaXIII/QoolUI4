# 领域文档

工程技能在探索代码库时应如何消费本仓库的领域文档。

## 探索前先读

- 仓库根部的 **`CONTEXT.md`**，或
- 若存在 **`CONTEXT-MAP.md`** —— 它指向每个 context 的一份 `CONTEXT.md`。读取与主题相关的每个文件。
- **`docs/adr/`** —— 阅读与你即将工作的区域相关的 ADR。多 context 仓库中还需检查 `src/<context>/docs/adr/` 的 context 级决策。

若这些文件不存在，**静默继续**。不要标记缺失；不要主动建议创建。`/domain-modeling` 技能（经 `/grill-with-docs` 与 `/improve-codebase-architecture` 触达）会在术语或决策真正落定时惰性创建它们。

## 文件结构

单 context 仓库（大多数仓库）：

```
/
├── CONTEXT.md
├── docs/adr/
│   ├── 0001-event-sourced-orders.md
│   └── 0002-postgres-for-write-model.md
└── src/
```

多 context 仓库（根部存在 `CONTEXT-MAP.md`）：

```
/
├── CONTEXT-MAP.md
├── docs/adr/                          ← 系统级决策
└── src/
    ├── ordering/
    │   ├── CONTEXT.md
    │   └── docs/adr/                  ← context 级决策
    └── billing/
        ├── CONTEXT.md
        └── docs/adr/
```

## 使用术语表的词汇

当你的输出命名领域概念时（issue 标题、重构提案、假设、测试名），使用 `CONTEXT.md` 中定义的术语。不要漂移到术语表明确规避的同义词。

若所需概念尚未进入术语表，那是一个信号——要么你在发明项目未使用的语言（重新考虑），要么存在真实缺口（记录给 `/domain-modeling`）。

## 标记 ADR 冲突

若你的输出与既有 ADR 矛盾，显式提出而非静默覆盖：

> _与 ADR-0007（event-sourced orders）矛盾——但值得重新讨论，因为……_
