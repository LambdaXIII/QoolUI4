# Qool.Dialogs 模块

对话框组件族（ADR-0021）：窗口血统的对话框窗口壳 + 容器无关的表面件。

- `QoolDialog`：预置 DialogSurface 的对话框窗口壳（独立 `Window`，
  `Qt.Dialog | Qt.CustomizeWindowHint | Qt.FramelessWindowHint`，color
  transparent）。标题走 `Window.title`（surface 跟随），内容走
  `header`/`content`/`footer` 三槽。开箱即得窗口模态对话框。
- `DialogSurface`：容器无关的对话框表面件——QoolBGBox 背景（dialog 主题
  token）+ title 槽 + header/content/footer 三槽。overlay 场景由使用者自拼
  `Popup + DialogSurface`。


## 组件参考

- [QoolDialog](QoolDialog.md)
- [DialogSurface](DialogSurface.md)
