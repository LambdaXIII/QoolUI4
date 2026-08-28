# Qool.Controls.Components 模块

控件基础原件层（类比 QtQuick.Controls 的组件基底）：被 `Qool.Controls`
依赖的基础原件，亦可独立消费。

Qool.Controls.Components 提供 QoolUI 控件系列的基础原件：

- 基础原件：`BasicControl`、`BasicButton`、`BasicText`、`BasicTextField`、
  `BasicTextArea`、`BasicItemDelegate` 等。
- 视觉基底：`QoolBGBox`（八边形背景盒）、`ControlHighlightCover`、
  `ControlPressedCover`、`ControlLockedCover`、`PaPaWall`、`IndexIndicator`、
  `SplitViewHandle` 等。
- 行为能力件：`CrystalCursor`（延迟缩放基准件——光标/手柄家族共用骨架）。
- 菜单件：`RadioIndicator`（单选指示器）、`QoolMenuBarItem`（菜单栏条目）。


## 组件参考

- [BasicTextField](BasicTextField.md)
- [CrystalCursor](CrystalCursor.md)
- [QoolMenuBarItem](QoolMenuBarItem.md)
- [RadioIndicator](RadioIndicator.md)

其余基础原件文档随模块文档补全（当前以源码与 ADR 为契约来源）。
