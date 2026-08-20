# RangeSlider orientation × RTL：默认件对齐 Qt 官方接口（同 Slider 决策模式）

Qool.Controls.RangeSlider 是 T.RangeSlider 模板子类，模板继承暴露
`orientation`（Qt.Horizontal/Qt.Vertical）与 RTL 镜像（`visualPosition`/
LayoutMirroring）能力，但默认件此前全水平硬编码：轨道 Crystal 只沿宽度铺满、
两个 handle 只沿 x 轴定位（窄条宽 = 可用高/2、行程 = availableWidth − 宽×2）、
前景 rangeBox 只水平映射区间（x/width 公式）、background implicit 固定
150×25、shrinkSize 基准取 root.height——宿主设置 `orientation: Qt.Vertical`
或置于 RTL 环境时视觉与 Qt 官方行为不一致。与 Slider 同缺口（ADR-0010 已
声明 RangeSlider 属独立票另行评估）。决策：默认件对齐 Qt 官方 Basic.RangeSlider
的 orientation 与 RTL 行为，**完整复用 ADR-0010 的正交统一设计模式**，不引入
第二套视觉系统；并利用 RangeSlider 无渐变的天然差异简化 RTL 处理。

## Considered Options

- **逐项打补丁**（垂直时轨道/handle/前景各加分支）：被拒——与 ADR-0010 论证
  相同，RTL 与垂直两维度交叉时补丁叠加（4 种组合）各自为政，维护面 ×4，且易
  与模板 visualPosition 镜像语义冲突。
- **完全复用模板维度（采纳）**：orientation 选择主轴（x/y），由模板
  `horizontal` 承载；RTL 沿主轴方向反转，由模板 `visualPosition` 镜像免费
  承载——两维度自由组合，组合正确性由模板保证，默认件零特判。与 ADR-0010
  同源。
- **RangeSlider 特有简化——无渐变端对调（采纳）**：Slider 因轨道为渐变、须
  在 RTL 时对调渐变 x 端点使 accent 随值增大端移动（ADR-0010 Key Decisions）；
  RangeSlider 轨道与前景均为**纯色轴对称 Crystal**（轨道 = backgroundColor
  75% 透明、前景 = color，无渐变通道）——六边形左右对称，RTL 下视觉本就
  不变，**无需任何对调逻辑**。这是 RangeSlider 相对 Slider 的唯一实质简化点。
- **side 法向抽象（采纳）**：照搬 Slider `side = horizontal ? availableHeight :
  availableWidth`——同时修正 RangeSlider 现存缺陷：`shrinkSize = Qore.bound(
  3, root.height × 0.25, 25)` 在垂直时基准轴错误（垂直法向是宽度非高度）。

## Key Decisions

- **pCtrl 引入 side 法向抽象**：`side = horizontal ? availableHeight :
  availableWidth`；`shrinkSize = Qore.bound(3, side * 0.25, 25)`、
  `halfShrinkSpace = shrinkSize / 2` 全部改基于 side——横竖对称、镜像无关
  （法向居中不随镜像变化），与 Slider 一致。
- **background implicit 随 orientation 交换**：background 显式 implicit
  150×25 ↔ 25×150，对齐官方"垂直默认窄"惯例；implicit 公式结构本身不变
  （Math.max(background, contentItem) 保留，background 项自适应即生效）。
- **轨道 Crystal 换轴**：主轴铺满、法向收缩居中——水平 `width` 满 /
  `height − shrinkSize` / `y = halfShrinkSpace`；垂直 `height` 满 /
  `width − shrinkSize` / `x = halfShrinkSpace`（与 Slider 轨道几何同式）。
  垂直时成瘦六边形（上下尖 + 左右直边），沿用既有形态学结论（示例页
  Page_InputControls2：瘦轨道可直接作竖直滑块背景）。
- **双 handle 换轴 + 窄条换向**：
  - 窄条换向：水平竖条 `w = side / 2`、`h = side`；垂直横条 `w = side`、
    `h = side / 2`（法向满、主轴厚 = 法向 / 2）。
  - 定位双分支：水平 `x = leftPadding + visualPosition × (availableWidth − w×2)`、
    y 居中；垂直 `y = topPadding + visualPosition × (availableHeight − h×2)`、
    x 居中。
  - **不相交公式随轴换（关键）**：行程 `availableWidth − width×2` ↔
    `availableHeight − height×2`——"任意值两 handle 永不相交"契约的垂直版本
    必须同步换轴，否则垂直时两 handle 会相交；second 起步偏移 `+ width` ↔
    `+ height`。
  - 光标换向：`horizontal ? Qt.SplitHCursor : Qt.SplitVCursor`。
- **前景 rangeBox 换轴**：水平 `x` 随 first 视觉位 / `width` = 区间视觉宽 +
  自身高 / `height` 满；垂直 `y` 随 first 视觉位 / `height` = 区间视觉高 +
  自身宽 / `width` 满。尖角外溢余量由 `height` ↔ `width`（切角 = 短边/2，竖条
  时短边为宽）。`ItemAnimatedResizer` 的 from/to 绑定 rangeBox 尺寸，自动随轴，
  无需改。
- **RTL 免费（与 0010 同源）**：定位已全部用 `visualPosition`——水平 RTL 由
  模板镜像；垂直 `visualPosition` 恒 = 1 − position（Qt 垂直惯例，值增大
  handle 在顶，与 RTL 无关——对齐 ADR-0010 对 T.Slider 的实测结论）。轨道/前景
  纯色轴对称，无渐变端对调需求。
- **Crystal 零改动**：`cut = min(width, height) / 2` 对宽高互换旋转对称——水平
  六边形与垂直瘦六边形同一几何自动成立，形状/掩码均不动（与 ADR-0010 同）。
- **交互免费**：value 全部经模板交互（拖动/键盘/wheel 按 orientation 映射、
  RTL 经 visualPosition 反算）——零自建，与 ADR-0009 模板 handle 回归、ADR-0010
  同源。

## Consequences

- 行为插拔点不变：`first.handle`/`second.handle`/`background` 仍为模板插拔件，
  替换后自动布局仍生效（Control 自动布局），orientation/RTL 适配随默认件。
- 颜色链路零改动：前景纯色 `color` 属性级绑定（无 ColorMapper，无 Slider 的
  colorAt 采样冻结陷阱）；RTL 无颜色采样错位问题（Slider 需改
  `colorAt(position)`，RangeSlider 无此环节）。
- 测试：现有 tst_rangeslider 水平断言数学等价不破（200×40 → side =
  availableHeight = 40、shrinkSize = bound(3,10,25) = 10 不变，水平分支公式
  等价）；新增垂直几何（横条 handle、行程 = availableHeight − h×2、rangeBox
  的 y/height 公式）、垂直 + RTL 组合用例。
- 文档：RangeSlider.md 几何契约章节补 orientation × RTL 正交描述（参照
  Slider.md 已有章节）；示例页可选加垂直演示。
- VerticalSlider 独立组件不受影响（本次不触碰）；VerticalRangeSlider 便捷
  封装是否新增按需后议，不在本决策范围。
- 与 ADR-0009 正交无冲突：0009 决策（三层结构、模板 handle 回归、锁存回归）为
  结构/交互架构层面，orientation/RTL 为几何/方向行为层面，二者可叠加。
- 待实现阶段实测确认一点：垂直 `visualPosition` 恒 = 1 − position 的结论来自
  ADR-0010 对 T.Slider 的 offscreen 实测，T.RangeSlider 实现时复测对齐；若行为
  有别，仅影响垂直方向断言，决策层面（用 visualPosition 不特判）不变。

## 决策状态

- 决策先行锚定（2026-08-21，实现前——ADR 记录决策、与实现解耦，优先保证正确
  性与时效性，不拖至实现后补记）。
- 实施 spec 待立（对齐 ADR-0010 的 spec 先行惯例：`.scratch/` 下 spec →
  `ready-for-agent`）。
- 实现细节若与决策偏差，按既有惯例在本文档末尾追加"实现演进"记录。

## 实现演进（2026-08-21 配色统一走 Style + VerticalSlider 移除）

- **配色统一走 Style**：原 Key Decisions「轨道 = backgroundColor 75% 透明、
  前景 = color」的实例色属性已删除（RangeSlider 与 Slider 同步）——现为轨
  道 = `Style.buttonText` 75% 透明（Qt palette 名、实义 control 前景色）+
  `ThemeHQ.recommendForeground(Style.buttonText)` 描边，前景 = `Style.accent`；
  纯色轴对称、RTL 无需渐变端对调的简化结论不变。
- **VerticalSlider 移除**：原「VerticalSlider 独立组件不受影响（本次不触碰）」
  不再成立——已完全移除，竖直需求由 `orientation: Qt.Vertical` 承担（同
  ADR-0010 演进）。
