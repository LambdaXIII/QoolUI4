# CrystalCursor：延迟缩放基准件 + ColorCursor 实现（收束三光标重复代码）

Color 模块光标/手柄重构中，三个光标/手柄存在**必然重复的代码**：`Qool.Controls.Slider` handle（内联）、`_private/ColorChannelSliderHandle`（ColorChannelSlider 用）、`_private/ColorCursor`（HSV/HSL 表面共用）。三者共享同一骨架——Crystal 菱形 + 缩放展开 + 延迟锁存 + 色注入。本 ADR 将其收束为 `Qool.Controls.Components.CrystalCursor` 基准件（能力组件「延迟缩放行为」），并实现 `ColorCursor`（组合 CrystalCursor + CenterPlacer + surface 交互），两 Slider 手柄内联接线，删除重复代码。

## Considered Options

- **三者直接统一为一个组件（CrystalCursor 承载全部语义）**：被拒——三者定位/着色语义不同（滑块 x/y 定位 + 采样色/实色；表面 center 定位 + 实色），强行统一成单组件会塞入多套模式、接口膨胀。基准件应「收束必然重复、保留可能性」：只收缩放/延迟/色注入，定位与色源留消费方接线。
- **坐标同步内建于 CrystalCursor（自带 centerx/centery）**：被拒——坐标是独立维度能力（已独立为 CenterPlacer，ADR-0015）；且仅表面场景需要中心坐标，滑块场景用 x/y。内建则基准件携带半数消费方用不到的能力。
- **掩码用独立组件 Crystal4ContainmentMask**：被拒——`Qool.Crystal`（OctagonShape + QoolBoxShapeControl）自带精确菱形 contains 判定，命中域即内部 Crystal 菱形，方形四角自然穿透，无需独立掩码组件。Crystal4ContainmentMask 整体弃用。
- **保留 defaultValue/reset/双击重置（旧 ColorCursor 行为）**：被拒——交互契约裁剪对齐 ColorChannelSlider/HSVWheel（ADR-0013/0014）：无 defaultValue/reset、双击无定义。`expanded` 默认 true（独立使用即展开态，自洽）。
- **锁存监听外部值信号（latchTarget/值变化自动触发）**：被拒——触发源消费方语义各异（Slider 绑 valueChanged、表面绑 colorChanged），基准件不自作聪明监听信号；`expanded` 单一 bool 输入，消费方把 hover/pressed/值变化「或」运算后注入。

## Key Decisions

1. **基准件定位**：`Qool.Controls.Components.CrystalCursor`——能力组件「**延迟缩放行为**」，非三光标的统一替身。收束必然重复（缩放/延迟/色注入/Crystal 基底），保留可能性（定位/色源/掩码决策留消费方）。
2. **结构 = Item 根 + 内部 Crystal**：根（消费方摆尺寸，稳定定位锚）内含 `Qool.Crystal` 菱形（自带 contains 命中判定，无独立掩码）。缩放只作用内部 Crystal，根 footprint 恒定——定位锚不随缩放偏移。
3. **缩放**：内部 Crystal 尺寸 = `ItemAnimatedResizer` 当前值；from = `fullSize − delta`（常态收缩）、to = `fullSize`（展开占满根）；`resized` = 锁存后结果。
*4. **延迟锁存内化**：`expanded`（bool，默认 true）为唯一行为输入——置 true 立即经 resizer 展开（放大无延迟，跟手即时）；置 false 时 TimerLatch 锁存窗口（`delay` = TimerLatch interval 时长）内保持展开、窗口过后才回落收缩（收缩防抖，快速状态变化不闪缩）。**不监听任何值信号**。
5. **色外包**：`color`/`borderColor` 两个公开属性，默认绑定 Style（color = `Style.accent`、borderColor = `ThemeHQ.recommendForeground(color)` 自动对比，对齐 Qool.Crystal 现成默认）。
6. **接口面**：`expanded`（默认 true）/`delta`/`delay`/`color`/`borderColor` 输入；readonly `fullSize` = `min(root.width, root.height)`（根尺寸）、readonly `size` = `crystal.width`（当前动态边长）。**无 x/y 定位、无 center 坐标**（定位留消费方，中心坐标经 CenterPlacer 组合）。
7. **ColorCursor 实现**（`_private`，独立文件保留）：组合 CrystalCursor + CenterPlacer（`target: root`）+ surface 交互映射——`centerx/centery = position(hue/sat)`（或 sat/ltn）绑定 CenterPlacer，`currentColor → color`，hover/交互/值变化「或」→ expanded。旧 `_private/ColorCursor.qml`（双模式 + ColorCrystal + hoveredSize + 双同步环）删除；`ColorCrystal.qml` 连带删除（唯一消费方消失）；`_private/HSVWheelCursor.qml` 删除（逻辑并入 ColorCursor，ADR-0014 更正记录）。
8. **两 Slider 手柄内联接线**：
   - `Qool.Controls.Slider` handle：内联 CrystalCursor——x/y 由模板 visualPosition 驱动、color = 采样色（ColorMapper colorAt）、expanded = hover‖pressed‖值变化锁存「或」。
   - `ColorChannelSlider` handle：内联 CrystalCursor——x/y 由 displayValue 驱动、color = solidColor、expanded = 三态或。
   - `_private/ColorChannelSliderHandle.qml` 删除（唯一消费方 ColorChannelSlider 改内联，独立文件无存在必要）。
9. **契约裁剪**：无 defaultValue/reset、双击无定义；`animationEnabled` 由消费方接线（CrystalCursor 不持有动画总开关，消费方按场景门控）。

## Consequences

- 仓库光标/手柄收敛为：CrystalCursor（基准件）+ 两个内联接线（Slider/ChannelSlider）+ ColorCursor（表面组合件）——重复代码（缩放/延迟/色注入/掩码）单点维护。
- 删除文件：`ColorChannelSliderHandle.qml`、旧 `ColorCursor.qml`、`ColorCrystal.qml`、`HSVWheelCursor.qml`；弃用 `Crystal4ContainmentMask`。
- 消费方（HSVWheel/HSLBox，ADR-0017）改用共用 ColorCursor——取色光标对两表面是同一回事（ADR-0014 更正记录）。
- 测试：`tst_qoolcolor_qml` 新增 ColorCursor 用例（双向坐标经 CenterPlacer/缩放展开/契约无 reset）；`tst_qool_qml` 新增 CenterPlacer 用例（ADR-0015）。真实鼠标交互以人工运行验证覆盖。
- 文档：`docs/reference/Qool.Controls.Components/CrystalCursor.md`（5 节）+ `docs/reference/Qool.Color/ColorCursor.md`（5 节）+ index.md 登记。
- 依赖：本 ADR 依赖 ADR-0015（CenterPlacer）先行落地。

## 决策状态

- 决策已定案（2026-08-23，grill-with-docs 讨论定稿）；实现按本 ADR 执行。
- 与 ADR-0013（ColorChannelSlider 高定）/0014（HSVWheel 单向链）同属 Color 迁移主线：0013 定一维通道滑块、0014 定二维取色表面、本 ADR 定共享光标基底；与 ADR-0015（CenterPlacer）为依赖关系。
