# ColorChannelSlider：高定设计定案（T.Slider 平级 + 通道视觉内化 + 交互契约裁剪）

Color 模块迁移适配中，旧 `_private/ColorSlider.qml`（标题+数值输入行 + 轨道+光标行）拆分为两个独立公开组件：文字部分已由 `ColorChannelEdit` 承接；拖动部分由 `ColorChannelSlider` 承接。本组件为通用单通道滑块（`channel: int` + PropertyProxy 动态寻址，链模式对齐 ColorChannelEdit）。核心决策：**高定组件**——通道视觉（渐变/光标/描边）完全内化为组件语义，不暴露外观覆写接口；交互契约裁剪（移除 defaultValue/reset/双击）；渐变经 `_private` 静态 QML 渐变组件承载（`ChannelGradient` / `RainbowGradient`），Hue 为唯一渐变特化（自带彩虹）。

## Considered Options

- **基于 Qool.Controls.Slider 实例化/继承并覆写 background/handle**：被拒——Slider 几何模型（pCtrl 的 side/shrinkSize）在组件作用域内不可达，覆写 delegate 须外部重算同套公式；默认 handle 内建反馈（latch/resizer/hover）替换即丢、须重建；且视觉体系不同构（Slider 为 Style 驱动 accent/buttonText，通道滑块为通道数据驱动）。复用 = 复制。
- **手写 Item + InteractingArea（旧模式拍平件）**：被拒——T.Slider 模板免费提供拖动/键盘步进/点击跳转/RTL，旧自写拖动映射无存在理由。
- **基类 + 变体文件（旧 ColorSlider 模式）**：被拒——ColorChannelEdit 已确立通用单组件模式；行为差异仅 hue 一处（sat-bump），channel 判断内化，不做变体文件。
- **可插拔外观接口（fillGradient/strokeColor/leftPoint/rightPoint 别名，旧 ColorSlider 暴露）**：被拒——通道渐变是组件语义本身（轨道显示通道数据），非宿主定制面；可插拔由模板级 delegate 替换承接。
- **保留 defaultValue/reset/双击重置**：被拒——per-channel 默认与重置语义是旧特化包袱，通用组件无重置契约。
- **环绕限幅（CycleBetweenEdges）保留**：被拒——新基座下 value 恒 `[0,1]`（模板拖动映射 + 裁剪链），assistant 越界仅来自外部程序写入；裁剪可达同等安全且语义简单。
- **渐变经 JS 双函数动态映射（旧 `ColorChannelSliderColors.js` 模式，Alpha/Sat 动态端点依赖 assistant）**：被拒——动态端点语义废弃，渐变改静态 QML 组件承载（见 Key Decision 5）。
- **轨道用裸 Shape（旧手写 ShapePath）**：被拒——Crystal（Qool 模块）已提供 fillGradient/borderColor/borderWidth/掩码，直接复用现成组件。

## Key Decisions

1. **T.Slider 平级实现**：`ColorChannelSlider` 直接基于 `QtQuick.Templates.Slider`，与 `Qool.Controls.Slider` 为兄弟组件（同模板交互 + Crystal 视觉语言家族，互不继承）。两套视觉体系有意分叉：Slider 样式驱动、通道滑块通道数据驱动。
2. **高定：关闭外观接口**：不暴露变体式外观参数（fillGradient/strokeColor 别名等）。**边界定义**：高定 ≠ 不可插拔——模板级 `background`/`handle` delegate 整体替换仍是唯一插拔口（宿主可整换轨道/光标）；关闭的是"变体式外观参数"。
3. **交互契约裁剪**：移除 `defaultValue`/`reset`/双击重置。T.Slider 模板点击跳转/键盘/拖动免费保留。`value` 初始默认统一 1——hue 为循环量（`Qt.hsva(1,1,1,1)` ≡ `Qt.hsva(0,1,1,1)`），1/0 视觉等价，无副作用；链在 onCompleted 从 assistant 播种，默认只影响播种前一瞬。`orientation` 显式锚定 `Qt.Horizontal`（模板默认值显式化，与竖直族对称）。
4. **行为内化**（公开组件自包含，对齐 ColorChannelEdit 先例）：
   - **无条件双向链**：`root.value ↔ PropertyProxy(assistant, channelNameF) ↔ colorAssistant`，同值守卫收敛——无拖动互斥门控。链模型与 ColorChannelVerticalSlider 同源，改动须双处同步。
   - **读方向越界守卫**：assistant 通道越界（hue < 0 无色相）不写 `value`——显示保持最后位置，且避免写方向 sat-bump 回环抬回 0.001。
   - **写方向裁剪 + sat-bump**：`value` 裁剪 `[0,1]`（`ColorNameHQ.clampChannelRange`，越界仅外部程序写入）；channel 为 hue（HSVHue/HSLHue）且 assistant 当前 hue < 0（无色相色）时，先写对应 sat = 0.001 再写 hue——无色相色上拖 hue 必须有可见反馈（旧 UX 契约，勿删）。
   - **播种**：`Component.onCompleted` 从 assistant 现读真实通道值（越界跳过）；随后解锁动画（`seedDone`）。
   - **handle 位置动画**：`displayValue` 中间层（= `visualPosition`）+ 门控 `BasicNumberBehavior`（`seedDone && animationEnabled && !pressed` 时开）——拖动中光标跟手（无动画）、松手/外部改值平滑过渡。
   - **值变化锁存**：`TimerLatch`（`Style.movementDuration * 2` 窗口）——value 瞬时事件 → 持续 expanded 窗口，避免改值瞬间收缩再展开闪动。
5. **渐变 = 静态 QML 组件**（`_private`）：轨道渐变由两个静态 QML 渐变组件承载，`fillGradient` 按 `isHue` 分派：
   - **`ChannelGradient`**（非 hue 通道）：`fromColor`/`toColor` 静态映射——`toColor = ColorNameHQ.channelColor(channel)`（C++ 共享查表）；`fromColor` 按通道组取 `transparent`（RGB/HSVValue/HSLLightness/Alpha）/ `black`（CMYK/Black）/ `white`（其余）。渐变从 position 0（toColor = 通道标识色）→ position 1（fromColor）。
   - **`RainbowGradient`**（hue 通道特化）：11 档 `Qt.hsva(p, saturation, value, alpha)`，默认 sat=1/value=1/alpha=0.25——固定全亮，不跟随当前明暗。
   - 渐变锚定：全宽 `x1=0`/`x2=width`（水平）、`y1=0`/`y2=height`（垂直），无内缩；`mirrored`（水平 && RTL）时 x1↔x2 对调（对齐 ADR-0010 模式：渐变锚定值增大视觉端）。
6. **轨道 = Crystal**：background delegate（Item，T.Slider 契约）内 Crystal 轨道——`fillGradient` 承接渐变、`borderColor` 内描边环、锚定收缩（`anchors.margins = pCtrl.halfShrinkSpace`）。**收缩模型**（对齐 Qool.Controls.Slider）：`side = horizontal ? availableHeight : availableWidth`、`shrinkSize = Qore.bound(3, side×0.25, 25)`、轨道收缩 + 法向居中——展开光标"顶出轨道但不出控件"三心对齐。orientation/RTL 由模板免费承载。
7. **描边统一规则**：`assistant.recommendedForegroundColor`（0.5 阈值黑白自动对比），高定内化、不暴露。
8. **handle = CrystalCursor 本体**（ADR-0016 基准件，根即 handle——与 Qool.Controls.Slider 同构）：定位/锁存/光标形状内联实例——x/y 由 `displayValue`（= visualPosition）驱动；`delta = pCtrl.shrinkSize`；`expanded = hoverer.hovered || root.pressed || crystalValueLatch.active`；hover 光标随方向切换（水平 SizeHorCursor / 垂直 SizeVerCursor），`NoButton` 不拦截模板拖动。
9. **文件结构**：公开 `ColorChannelSlider.qml`（T.Slider 自包含行为 + 链 + channel 分派 background/handle）；`_private/` 只放渐变组件——`ChannelGradient.qml`（非 hue 双色渐变）、`RainbowGradient.qml`（hue 彩虹）。轨道/手柄视觉全部内联进公开组件，无独立 `_private` 轨道/手柄件。

## Consequences

- 仓库出现两个 T.Slider 家族组件（Qool.Controls.Slider 样式驱动 / ColorChannelSlider 通道数据驱动）——兄弟关系，视觉体系有意分叉，不互相继承。
- 渐变端点色集中于 `ColorNameHQ.channelColor` 共享查表（C++）+ `ChannelGradient` 静态映射——单处维护；无动态端点（Alpha/Sat 不再依赖 assistant 当前值）。
- 消费方（HSV/HSL 面板水平滑块）迁移后不再能覆写 fillGradient——旧变体 `ColorSlider_Hue/Value/Alpha` 随迁移废弃。
- 测试：`tst_qoolcolor_qml` 增补（几何断言 + 链同步，offscreen 惯例）；示例页 Playground 人工验收（无合成鼠标的交互映射以人工运行验证，既有惯例）。
- 文档：`docs/reference/Qool.Color/ColorChannelSlider.md` + index.md 登记。
- 术语：**高定组件** 已升级进 CONTEXT.md（实例列表含 ColorChannelSlider）。

## 决策状态

- 决策已定案（2026-08-21，grill-with-docs 讨论定稿）；2026-08-23 重构收尾按代码现状修订——渐变由 JS 双函数改静态 QML 组件（ChannelGradient/RainbowGradient）、handle 改 CrystalCursor 本体、删除独立轨道/手柄文件与 `isHsv`。
- 与 ADR-0010/0011 同源（orientation/RTL 正交模式复用）；与 ADR-0012（PropertyProxy）无冲突。
