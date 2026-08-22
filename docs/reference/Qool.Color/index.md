# Qool.Color 模块

颜色组件集：多色彩空间编辑面板、快速取色/编辑/预览、色名列表与色银行。

Qool.Color 提供完整的颜色操纵组件面：

- 核心对象：`ColorAssistant`（四空间分量全同步）、`ColorBank`（稀疏
  槽位容器）、`ColorNameHQ`（插件化色名查询单例）、`ColorHueCycleModel`、
  `RandomHSVColorGenerator`。
- 编辑面板：`HSVPanel`、`HSLPanel`、`RGBPanel`、`CMYKPanel`——
  数字输入 + 表面控件 + 滑块组合，可注入共享 ColorAssistant。
- 取色/编辑/预览：`ColorQuickPicker`、`ColorEdit`、`ColorChannelEdit`
  （单通道值编辑）、`ColorChannelSlider`（单通道拖动调值）、
     和 `ColorChannelControl`（单通道编辑+拖动组合行）、`ColorPreviewer`。
- 取色表面：`HSVWheel`（HSV 二维色轮取色——hue/sat 双写 + value 压暗层，
  单向链架构，公开一级组件）；`HSLBox`（HSL 二维取色框——sat/lightness
  双写 + hue 外部驱动，单向链架构，公开一级组件）。
- 列表与银行：`ColorNameList`（分类色名选择）、`ColorBankPanel`
  （槽位存取）。

## 组件参考

- [CMYKPanel](CMYKPanel.md)
- [ColorAssistant](ColorAssistant.md)
- [ColorBank](ColorBank.md)
- [ColorBankPanel](ColorBankPanel.md)
- [ColorChannelControl](ColorChannelControl.md)
- [ColorChannelEdit](ColorChannelEdit.md)
- [ColorChannelVerticalSlider](ColorChannelVerticalSlider.md)
@@
- 取色/编辑/预览：`ColorQuickPicker`、`ColorEdit`、`ColorChannelEdit`
  （单通道值编辑）、`ColorChannelSlider`（单通道拖动调值）、
  `ColorChannelVerticalSlider`（竖直单通道拖动调值，填充条样式）、
  和 `ColorChannelControl`（单通道编辑+拖动组合行）、`ColorPreviewer`。
- [ColorCursor](ColorCursor.md)
- [ColorEdit](ColorEdit.md)
- [ColorHueCycleModel](ColorHueCycleModel.md)
- [ColorNameHQ](ColorNameHQ.md)
- [ColorNameList](ColorNameList.md)
- [ColorPreviewer](ColorPreviewer.md)
- [ColorQuickPicker](ColorQuickPicker.md)
- [HSLBox](HSLBox.md)
- [HSLPanel](HSLPanel.md)
- [HSVPanel](HSVPanel.md)
- [HSVWheel](HSVWheel.md)
- [RGBPanel](RGBPanel.md)
- [RandomHSVColorGenerator](RandomHSVColorGenerator.md)

## 设计说明（易误解处，防误判）

- `RandomHSVColorGenerator` 的 255 量化是刻意设计（防相近色，
  配合**色相与上次差 ≥ 20 去重（sat/value/alpha 无此约束）**）
  ——量化粒度 1.41° 不是缺陷；hue 生成走
  `qRound(hue*360/255)` 整数满环路径，不得改浮点构造。
  int 轨是公开 API 能力面；任一分量 setter 都经统一入口全空间重算。
- `ColorBank` 是无界稀疏容器（存 slot_5 不创建 1..4）；`slots`
  是面板显示范围而非存储边界；组件库刻意不做持久化（宿主三接法：
  注入前构造填充、监听 colorChanged 纪录、继承仿写）。
- 数值输入约定：数字输入框允许 0..1000 整数，`x>1` 时按 `x/1000`
  解释（1000 表示 1.0）。
- 私有拍平件（NumInput/CycleChoice 与视觉件族）经目录 import 使用、
  不注册进模块 qmldir（宿主不可见），将来扩展为完整版进入
  Qool.Controls。
- 色名插件优先级统一由插件 json 的 `priority` 字段定义，接口不提供
  priority 方法。
- 前景对比色统一用 v4 既有设施：`ThemeHQ.recommendForeground`
  （背景→黑/白推荐）与 `ColorAssistant.recommendedForegroundColor`
  （0.5 阈值黑白派生属性）——v4 样式系统无独立 foreground 语义，
  foreground 并入 text 系（QPalette 对位设计）。
- 拍平临时件（NumInput/CycleChoice）动画策略：只保静态外观、布局与
  状态绑定，动画特征移除；高频刷新/属性绑定（光标位置、填充高度等）
  不属于动画，保留。
