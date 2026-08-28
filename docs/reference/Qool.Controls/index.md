# Qool.Controls 模块

控件基础层（类比 QtQuick.Controls）：可编辑文本、数值步进、选择与滚动控件。

Qool.Controls 提供 QoolUI 控件系列：

- 文本编辑：`EditableText`（双层强化编辑文本——展示层 + 编辑会话）、
  `EditableTextBox`（带壳的 EditableText）、`BasicTextArea`（多行基底）。
- 数值输入：`SpinBox`（裸步进器，int/double 一体）。
- 选择控件：`ComboBox`（可编辑下拉框）、`Slider` / `RangeSlider`
  （范围滑块）、`Dial`（圆形转盘）。
- 进度与滚动：`ProgressBar`、`ScrollIndicator`、`ScrollView`。
- 基础件：`Button`、`ToolButton`、`ClickableText`（带下划线反馈的可点击
  文本）、`QoolBGBox`（八边形背景盒）、`IndexIndicator`、`PaPaWall`
  （并行竖条动画墙）。
- Action 实例化：`ActionInstantiator`（把 `Action` 列表实例化为
  `ClickableText` 条目）。
- 菜单：`MenuBar`（菜单栏）、`Menu`（弹出菜单）、`MenuItem`、
  `MenuSeparator`（可带文字的分隔线）、`MenuBanner`（菜单横幅）。


控件样式遵循 `Qool.Style`（`root.Style.*` 附加属性）。

## 组件参考

- [ActionInstantiator](ActionInstantiator.md)
- [Button](Button.md)
- [ClickableText](ClickableText.md)
- [ComboBox](ComboBox.md)
- [Dial](Dial.md)
- [EditableText](EditableText.md)
- [EditableTextBox](EditableTextBox.md)
- [IndexIndicator](IndexIndicator.md)
- [Menu](Menu.md)
- [MenuBar](MenuBar.md)
- [MenuBanner](MenuBanner.md)
- [MenuItem](MenuItem.md)
- [MenuSeparator](MenuSeparator.md)
- [PaPaWall](PaPaWall.md)
- [ProgressBar](ProgressBar.md)
- [QoolBGBox](QoolBGBox.md)
- [RangeSlider](RangeSlider.md)
- [ScrollIndicator](ScrollIndicator.md)
- [ScrollView](ScrollView.md)
- [Slider](Slider.md)
- [SpinBox](SpinBox.md)
- [ToolButton](ToolButton.md)
- [BasicTextArea](BasicTextArea.md)
