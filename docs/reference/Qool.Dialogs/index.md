# Qool.Dialogs 模块

对话框组件族（ADR-0021）：窗口血统的对话框窗口壳 + 容器无关的表面件。

- `QoolDialog`：预置 DialogSurface 的对话框窗口壳（独立 `Window`，
  `Qt.Dialog | Qt.CustomizeWindowHint | Qt.FramelessWindowHint`，color
  transparent）。标题走 `Window.title`（surface 跟随），内容走
  `header`/`content`/`footer` 三槽。开箱即得窗口模态对话框。
- `DialogButtonBox`：T.DialogButtonBox 的特化换皮件（裸名导出，接口完全兼容）
  ——机制（standardButtons、role 信号、平台排序、本地化、默认按钮）全部继承
  Template 层，只换 Qool 皮肤：padding 0、spacing 4、无 background、
  delegate 为 DialogButton。对盒内已存在的按钮零干预。
- `DialogButton`：对话域语义按钮——role 驱动语义色（Accept/Yes → positive、
  Destructive → negative，边框+填充；语义填充上前景走
  `ThemeHQ.recommendForeground`）。delegate 产物与自拼用法同一身体。


## 组件参考

- [QoolDialog](QoolDialog.md)
- [DialogSurface](DialogSurface.md)
- [DialogButtonBox](DialogButtonBox.md)
- [DialogButton](DialogButton.md)

