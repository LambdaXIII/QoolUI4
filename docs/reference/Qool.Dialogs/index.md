# Qool.Dialogs 模块

对话框组件族（ADR-0021）：窗口血统的对话框窗口壳 + 容器无关的表面件。

- `QoolDialog`：预置 DialogSurface 的对话框窗口壳（独立 `Window`，
  `Qt.Dialog | Qt.CustomizeWindowHint | Qt.FramelessWindowHint`，color
  transparent）。开箱即得窗口模态对话框。
- `DialogSurface`：容器无关的对话框表面件（BasicControl 子类）——标题 +
  内容区 + dialog 主题背景。overlay 场景由使用者自拼 `Popup + DialogSurface`。


## 组件参考

- [QoolDialog](QoolDialog.md)
- [DialogSurface](DialogSurface.md)
