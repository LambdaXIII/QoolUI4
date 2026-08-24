# ColorChannelVerticalSlider：竖直通道滑块公开组件（T.Slider 独立实现 + 填充条样式 + 固定彩虹背景）

RGB/CMYK 面板的竖直通道滑块族（`ChannelBar`/`ChannelSlider`/9 变体）仍是旧拍平件架构：per-channel 变体文件 + `userInteracting` 互斥 Binding + 双击重置，无 T.Slider 模板能力，填充条式轨道视觉没有公开组件形态。本 ADR 定案：公开组件 `ColorChannelVerticalSlider`——仿 `ColorChannelSlider` 的设计（T.Slider 基座、通用 `channel` 寻址、无条件链、契约裁剪、高定），样式保持原有填充条（圆角、从底部填充、身份色渐变、无 hover、无可见手柄）。核心决策：**独立实现不继承**、**填充 = 色相正常值（hue）/ 身份色（非 hue）**、**背景彩虹固定全亮（不跟随当前 sat/value/lightness）**。本次不改动私有竖直族（其整体迁移为后续任务，本组件为其基座）。

## Considered Options

- **继承 `ColorChannelSlider` 并覆写 orientation/background/handle**：被拒——独立实现。理由：填充条式「标准 Slider 框架 + 透明 handle」的结果形态更贴合直觉；继承使公开组件间产生父子关系（reference 文档须列基类），且覆写 delegate 时基类内部 id（pCtrl 等）不可达、几何须外部重算（ADR-0013 拒绝继承 Controls.Slider 的同类问题）。
- **抽私有基类 `ColorChannelSliderBase`（T.Slider + 链），水平/竖直都继承**：被拒——最 DRY 但要重构已定案且已测的 ColorChannelSlider、修订 ADR-0013 结构决策，风险面扩大。
- **组合形态（轨道 + 数值输入 + 底部标题一体）**：被拒——水平族已确立 edit/slider 分离架构（文字归 ColorChannelEdit/ColorChannelControl），竖直族应同构；本次仅迁移轨道（Bar）本身，输入/标题/双击由私有包装层继续承担（不动）。
- **整族迁移（变体删除、面板换用新组件）**：当时被拒——私有族与 RGB/CMYK 面板暂保持原样；**2026-08-24 已执行**（见决策状态），本条为历史记录。
- **填充 = 轨道采样色（`ColorMapper.colorAt` 语义，随当前明暗走样）**：被拒——填充改色相正常值（hue 通道固定 sat、仅随 position 变 hue，不受当前明暗影响）；非 hue 通道自动退化为身份色恒等。
- **hue 彩虹原理式跟随当前 sat/value（或 sat/lightness）**：被拒——背景彩虹固定 `RainbowGradient` 默认参数（sat=1/value=1/alpha=0.25），不随当前明暗变化，与水平族同构。
- **justMoved 1s 高亮（边框随 value 写入 lighter）**：当时被拒（拒绝的是状态暴露与独立 Timer 重复实现）——**2026-08-24 已按 TimerLatch 惯用模式补上**（见决策状态与 Key Decision 6），本条为历史记录。
- **保留 defaultValue/reset/双击重置（原竖直族 UX）**：被拒——高定契约裁剪对齐 ColorChannelSlider/HSVWheel；旧双击重置是包装层行为，不在本组件契约内。
- **可见手柄（还原「按哪拖哪」手感）**：被拒——side×side 透明 Item，无可见视觉、无 hover 反馈；交互（拖动/点击跳转/键盘/RTL）全由模板承担。
- **hue 彩虹填进填充矩形（随 value 拉伸）**：被拒——彩虹塞进填充矩形会被拉伸压缩；彩虹只进 bg（整条锚定），填充为纯色。

## Key Decisions

1. **T.Slider 独立实现**：`ColorChannelVerticalSlider` 直接基于 `QtQuick.Templates.Slider`，不继承 ColorChannelSlider。**链模型照搬**（PropertyProxy 无条件双向 + clamp [0,1] + sat-bump + hue<0 守卫 + onCompleted 播种 + 同值收敛），链处注释「同源 ColorChannelSlider，改动须双处同步」（复制即承担双处维护风险，注释为 MUST）。
2. **orientation 默认 `Qt.Vertical`**；implicit 25×150（background 驱动，竖直家族惯例）。双形态：水平时填充锚定值 0 端、沿值增大方向生长（LTR 左 / RTL 右），α 渐变沿生长轴，hue 彩虹沿值方向（hue 0 值 0 端 → hue 1 值 1 端）；RTL 跟随 `mirrored`（垂直不受 RTL 影响）。`ColorChannelVerticalSlider` 的 Vertical = 默认 orientation + 填充条身份，非唯一形态。
3. **高定组件**：通道视觉（填充条/彩虹/边框）完全内化为组件语义，不暴露变体式外观接口；模板级 background/handle delegate 仍是唯一插拔口；交互契约裁剪（无 defaultValue/reset/双击）；通用单组件（`channel: int`，无 per-channel 变体文件）。
4. **填充 = 色相正常值（hue）/ 身份色（非 hue）**：`filler` 渐变双色——`color2 = pCtrl.channelColor`（主色）、`color1 = isHue ? channelColor : Qt.alpha(channelColor, 0.2)`。hue 通道的 `channelColor` = 色相正常值（`HSVHue` = `hsva(position, 1, 1, 1)`、`HSLHue` = `hsla(position, 1, .5, 1)`——固定 sat、HSV value=1 / HSL lightness=0.5 纯色，仅随 position 变 hue，不受当前明暗影响）；非 hue 通道 = 身份色恒等。（**2026-08-25 修订：填充尺寸 width/height 与渐变端点色 color1/color2 均经 Behavior 动画，全部挂 fillHost 宿主**；「填充色纯绑定零动画」为历史记录，见决策状态。渐变锚定改像素点 + stops 反排，见 Key Decision 6 修订。）
5. **身份色映射**（共享查表 `ColorNameHQ.channelColor`，C++ `ColorLiterals::channelColor`）：9 通道——Red/Blue/Cyan/Magenta/Yellow 纯通道色、Green = `Qt.green`（#00ff00）、Alpha = gray、Black = darkGray、HSVValue/HSLLightness = lightGray；HSVSaturation = `hsva(hsvHueF, 1, hsvValueF)`、HSLSaturation = `hsla(hslHueF, 1, hslLightnessF)`（原理式——改 sat 后真实结果色，对齐水平族 Sat 端点语义）。
6. **背景**：`background` = `RectShape`（radius 4、borderWidth 1、填充 = `Qt.alpha(channelColor, 0.1)` 淡染，两个 `BasicColorBehavior` 门控动画）+ `fillGradient`（`isHue` 时 `RainbowGradient`——11 档 `hsva(p, 1, 1, 0.25)` 固定全亮半透明、整条锚定沿值方向；否则 `null`）。边框 = 通道标识色 + justMoved 高亮（见决策状态 2026-08-24 修订——`TimerLatch` 挂 valueChanged，写入后 `Qt.lighter(channelColor, 1.4)` 保持 `Style.movementDuration * 2` 窗口后回落，无公开状态）。（**2026-08-25 修订：填充条（contentItem）改走 Shapes 路径 + 宿主-跟随者架构 + fillMin，见决策状态。**）
7. **透明手柄**：side×side 透明 Item（无可见视觉、无 hover 反馈）+ 内嵌 `MouseArea`（`NoButton` 不拦截模板拖动，仅 cursorShape 随方向切换——水平 SizeHorCursor / 垂直 SizeVerCursor，对齐 ColorChannelSlider 手柄）。交互（拖动/键盘步进/点击跳转/RTL）全由模板承担。
8. **文件结构**：公开 `ColorChannelVerticalSlider.qml`（T.Slider 自包含行为 + 链 + channel 分派 background/handle）；`_private/RainbowGradient.qml`（hue 彩虹渐变组件，与水平族共用）。填充条视觉（fillBox/filler）内联进公开组件 contentItem，无独立 `_private` 轨道件。
9. **私有竖直族不动**：`ChannelBar`/`ChannelSlider`/9 变体/RGBPanel/CMYKPanel/NumInput/InteractingArea 本次一律不修改——继续服务现有消费方；其整体迁移（以本组件为基座）为后续任务，不在本 ADR 承诺范围。

## Consequences

- 仓库出现第三个高定组件（ColorChannelSlider、HSVWheel 之后）——**「高定组件」术语沿用**（CONTEXT.md 实例列表含 `ColorChannelVerticalSlider`，定义不动）。
- 仓库出现第二套轨道视觉线：水平族 Crystal 六边形轨道与竖直族填充条轨道（原 RGB/CMYK 面板视觉）——有意并存；两族 hue 彩虹均固定全亮（`RainbowGradient` 默认参数，不随明暗）。
- 链照搬 = 双处维护风险（ColorChannelSlider 与 ColorChannelVerticalSlider）——同源同步注释为 MUST；后续链修复须双处应用。
- 填充语义与 `ColorMapper.colorAt` 无关（hue 固定正常色、非 hue 身份色恒等）——无采样色、无边框采样（边框 = 身份色恒等）。
- 私有竖直族曾为旧模式（userInteracting 互斥 Binding/双击重置）——**2026-08-24 迁移收口已完成**：面板换用 ColorChannelControl 竖直列，变体/ChannelBar/NumInput 删除，旧模式随之退场。
- 测试：`tst_qoolcolor_qml` 增补 `tst_colorchannelverticalslider.qml`（链/播种/填充几何/通道分派/契约裁剪显式断言，offscreen 惯例，实例 `animationEnabled: false`）；示例页 Playground 增补竖直滑块演示（含 hue）人工验收交互手感。
- 文档：`docs/reference/Qool.Color/ColorChannelVerticalSlider.md` + index.md 登记。

## 决策状态

- 决策已定案（2026-08-23，grill-with-docs 讨论定稿）；2026-08-23 重构收尾按代码现状修订——hue 填充改色相正常值（HSL lightness 0.5 为正确纯色）、背景彩虹改固定全亮（不跟随）、justMoved 移除、身份色改共享查表（Green = #00ff00、Value/Lightness = lightGray）、删除独立轨道/Colors.js 文件。
- 2026-08-24 迁移收口修订：justMoved 高亮由「拒绝」改为「已补」——被拒的是 justMoved 状态暴露与独立 Timer 重复实现，视觉反馈本身为新组件遗漏（用户裁定）；按家族惯用模式挂 `TimerLatch`（窗口 `Style.movementDuration * 2`，非旧 ChannelBar 固定 1000ms）。私有竖直族整体迁移完成：RGB/CMYK 面板换用 `ColorChannelControl { orientation: Qt.Vertical }`，`ChannelBar`/`ChannelSlider`/9 变体/`NumInput` 删除；双击重置随迁移退场（本 ADR 契约裁剪先例）；HSVValue 短标签 VAL→BRIT（还原旧面板标题）。
- **2026-08-25 修订（bug 3 修复后按代码现状）**：填充条渲染与几何架构因 Qt scene graph 缺陷改写——`Rectangle` 圆角渐变节点在主轴尺寸单帧骤缩时触发 `qsgbasicinternalrectanglenode.cpp`「index == vertexCount」断言（真实场景：vslider 填充条随 value 骤缩；HSVWheel 圆外拖动；color 页拖动），经裸 `Rectangle` 消融 + `RectShape` 对照实验验证 Shapes 路径免疫，`filler` 由 `Rectangle` 改 `RectShape`（Shapes 路径，勿改回）。架构随之改为**宿主-跟随者**：几何三态分派（orientation × mirrored，竖直不受 RTL 影响，if-return 绑定块）、配色（color1/color2/startColor/endColor）、渐变锚点（gradStart/gradEnd）与全部尺寸/颜色动画（BasicNumberBehavior/BasicColorBehavior，`animationReallyEnabled` 门控）上移 `fillHost`（DummyItem），`filler`（RectShape）纯跟随 `x/y/w/h`（勿直挂几何绑定——RectShape 曾求值异常）。渐变锚定改像素点：`gradStart` 竖直钉 `fillMin/2`、水平随镜像换向，`gradEnd` 跟填充末端，stops `{0: startColor, 0.9: endColor}` 去起始端 0.1 缩进保留末端平头。**新增 `fillMin`**（= `trackShape.radius × 2` = 8，仅竖直态高度生效）：position=0 时填充条不消失，保留一个轨道圆角直径高的极小渐变条（用户外观设计定案，min 暂定 track radius × 2）。背景 `RainbowGradient` 仍经 `createObject()` 实例化（无 parent，属正常写法）。
- 与 ADR-0013（高定边界定义、链模式）同源复用；与 ADR-0012（PropertyProxy 无状态代理语义）无冲突；orientation/RTL 由模板承载（ADR-0010 模式）。
