# ColorChannelVerticalSlider：竖直通道滑块公开组件（T.Slider 独立实现 + 填充条样式 + 轨道采样色填充）

RGB/CMYK 面板的竖直通道滑块族（`ChannelBar`/`ChannelSlider`/9 变体）仍是旧拍平件架构：per-channel 变体文件 + `userInteracting` 互斥 Binding + 双击重置，无 T.Slider 模板能力，填充条式轨道视觉没有公开组件形态。本 ADR 定案：新增公开组件 `ColorChannelVerticalSlider`——仿 `ColorChannelSlider` 的设计（T.Slider 基座、通用 `channel` 寻址、无条件链、契约裁剪、高定），但**样式保持原有填充条**（圆角、从底部填充、身份色渐变、justMoved 高亮、无 hover、无可见手柄）。核心决策：**独立实现不继承**、**填充 = 轨道在填充顶边的采样色**（对齐 `Qool.Controls.Slider` 的 `ColorMapper.colorAt` 语义）、**hue 彩虹原理式跟随当前 sat/value/lightness**（类似 HSVWheel/HSLBox 背景）、**颜色零动画纯绑定**。本次不改动私有竖直族（其整体迁移为后续任务，本组件为其基座）。

## Considered Options

- **继承 `ColorChannelSlider` 并覆写 orientation/background/handle**：被拒——用户定案独立实现。理由：RangeSlider 式「标准 Slider 框架 + 透明 handle」的结果形态更贴合直觉；继承使公开组件间产生父子关系（reference 文档须列基类），且覆写 delegate 时基类内部 id（pCtrl 等）不可达、几何须外部重算（ADR-0013 拒绝继承 Controls.Slider 的同类问题）。
- **抽私有基类 `ColorChannelSliderBase`（T.Slider + 链），水平/竖直都继承**：被拒——最 DRY 但要重构已定案且已测的 ColorChannelSlider、修订 ADR-0013 结构决策（「行为基类落点：公开组件自包含」），风险面扩大。
- **组合形态（轨道 + 数值输入 + 底部标题一体）**：被拒——水平族已确立 edit/slider 分离架构（文字归 ColorChannelEdit/ColorChannelControl），竖直族应同构；T.Slider 基座下塞输入+标题布局别扭；本次仅迁移轨道（Bar）本身，输入/标题/双击由私有包装层继续承担（不动）。
- **整族迁移（变体删除、面板换用新组件）**：被拒（本次）——`ChannelSlider` 本次不动、仅实现 Bar；私有族与 RGB/CMYK 面板保持原样，整体现代化属后续独立任务。
- **填充色 = `assistant.solidColor`**：被拒——用户定案：填充 = **背景彩虹在 value 处的对应色**（轨道采样语义，对齐 Controls.Slider 手柄 `colorMapper.colorAt(position)`）。solidColor 随 assistant 的 sat/value 走样且不反映轨道本身，轨道采样色与轨道渐变一致、边界无缝；非 hue 通道自动退化为身份色恒等（零行为变化）。
- **hue 彩虹固定 `hsva(p,1,1,1)`（对齐水平族 TrackHue）**：被拒——用户定案：竖直族彩虹**原理式跟随**当前 sat/value（HSV）或 sat/lightness（HSL），类似 HSVWheel/HSLBox 背景（当前颜色深则彩虹暗、灰则彩虹灰），所见即所得；与水平族 TrackHue 有意不同。
- **填充色加 Behavior（随高度动画同步平滑）**：被拒——填充色纯绑定 position 派生（数学函数），零动画、自然随动。填充色与填充高度均由 position 派生（**外观面**，非契约决策）；采样源 = 缓动中的填充高度——动画中间值颜色随填充移动、边界恒无缝（实现说明，拖动中 Behavior 关闭两者恒等）。
- **保留 defaultValue/reset/双击重置（原竖直族 UX）**：被拒——高定契约裁剪对齐 ColorChannelSlider/HSVWheel；旧双击重置是包装层行为，不在本组件契约内。
- **全条透明手柄（还原「按哪拖哪」手感）**：被拒（用户定案 25×25）——side×side 与 ColorChannelSlider 手柄几何一致；T.Slider 拖动/点击跳转/键盘在控件层（水平族已实证覆写 handle 后交互仍工作），栏上其余位置点击跳转覆盖。
- **hue 彩虹填进填充矩形（随 value 拉伸）**：被拒——彩虹塞进填充矩形会被拉伸压缩，填充上边界色 ≠ 当前色相，语义丢失；彩虹只进 bg（整条锚定），填充为纯采样色。

## Key Decisions

1. **T.Slider 独立实现**：`ColorChannelVerticalSlider` 直接基于 `QtQuick.Templates.Slider`，不继承 ColorChannelSlider。**链模型照搬**（PropertyProxy 无条件双向 + clamp [0,1] + sat-bump + hue<0 守卫 + onCompleted 播种 + 同值收敛），链处注释「同源 ColorChannelSlider，改动须双处同步」（复制即承担双处维护风险，注释为 MUST）。
2. **orientation 默认 `Qt.Vertical`**（用户定案）；implicit 25×150（background 驱动，竖直家族惯例；orientation 翻转时 implicit 随模板交换，但填充条视觉为竖直定向——水平形态下填充自底部语义未定义，文档明示）。
3. **高定组件第三实例**：通道视觉（填充条/彩虹/边框/justMoved）完全内化为组件语义，不暴露变体式外观接口；模板级 background/handle delegate 仍是唯一插拔口；交互契约裁剪（无 defaultValue/reset/双击）；通用单组件（`channel: int`，无 per-channel 变体文件）。
4. **填充 = 轨道在填充顶边的采样色**：语义对齐 `Qool.Controls.Slider` 的 `ColorMapper.colorAt(position)`（手柄显示轨道在当前位置的采样色）。**hue = 原理式数学函数（跟随当前状态）**：HSVHue = `hsva(value, hsvSaturationF, hsvValueF)`、HSLHue = `hsla(value, hslSaturationF, hslLightnessF)`——「轨道每位置 = 把 hue 改为 p 后的真实结果色」，当前 sat/value（或 sat/lightness）钉死为当前值；非 hue = 身份色恒等（采样退化为原填充）。无需实例化 ColorMapper。
5. **身份色映射**（数据决策，勿改）：9 通道逐字保留原变体字面量——Red/Blue/Cyan/Magenta/Yellow 纯通道色、**Green = Qt 命名色 `#008000`**（原字面量 "green"，勿按水平族纯绿 #00ff00 推断）、Alpha `grey`、Black `darkgrey`、HSVValue/HSLLightness `white`；HSVSaturation = `hsva(hsvHueF,1,hsvValueF)`、HSLSaturation = `hsla(hslHueF,1,hslLightnessF)`（原理式——改 sat 后真实结果色，对齐水平族 Sat 端点语义）。
6. **hue 轨道**：bg = 彩虹（hue 0 底部 → hue 1 顶部，α0.2 半透明），**档色原理式跟随**——HSVHue 档 p = `hsva(p, hsvSaturationF, hsvValueF, 0.2)`、HSLHue 档 p = `hsla(p, hslSaturationF, hslLightnessF, 0.2)`（随 assistant 当前色动态变化，类似 HSVWheel/HSLBox 背景；与水平族 TrackHue 固定 `hsva(p,1,1,1)` 有意不同）；边框 = 采样色。**实现陷阱**：QML `Gradient` position 0 = 顶部——彩虹 stops 须反排（顶部 hue 1 → 底部 hue 0）。11 档 GradientStops 内联声明 + 同源 TrackHue 注释（Gradient 需 QML 对象声明，抽 JS 别扭）。
7. **样式保真清单**（原 ChannelBar/ChannelSlider，逐项保留）：圆角 5/4（边框/内容内缩 padding 4）、从底部填充、填充 α0.9→0.1 纵向渐变、bg 身份色 α0.1 淡染、justMoved 1s 高亮（任何 value 写入触发、边框 lighter 1.4×——含程序写入，刻意行为）、无 hover 态、无可见手柄；平滑填充动画保留（Behavior 于填充高度，门控 `animationEnabled && !pressed`——拖动跟手、非交互平滑），**颜色零动画**（纯绑定；填充色与填充高度均由 position 派生，外观面）。
8. **透明手柄**：side×side（25×25）透明 Item，无可见视觉、无 hover 反馈；交互（拖动/键盘步进/点击跳转/RTL）全由模板承担。
9. **文件结构**：公开 `ColorChannelVerticalSlider.qml`（T.Slider 自包含行为 + 链 + channel 分派 background/handle）；`_private/ColorChannelVerticalTrack.qml`（填充条视觉件：边框/justMoved/bg/填充/彩虹分派）、`_private/ColorChannelVerticalColors.js`（身份色映射数据决策）。
10. **私有竖直族不动**：`ChannelBar`/`ChannelSlider`/9 变体/RGBPanel/CMYKPanel/NumInput/InteractingArea 本次一律不修改——继续服务现有消费方；其整体迁移（以本组件为基座）为后续任务，不在本 ADR 承诺范围。

## Consequences

- 仓库出现第三个高定组件（ColorChannelSlider、HSVWheel 之后）——**「高定组件」术语沿用**（CONTEXT.md 实例列表补 `ColorChannelVerticalSlider`，定义不动）。
- 仓库出现第二套轨道视觉线：水平族 Crystal 六边形轨道与竖直族填充条轨道（原 RGB/CMYK 面板视觉）——有意并存；竖直族 hue 彩虹原理式跟随（与水平族 TrackHue 固定彩虹有意不同）。
- 链照搬 = 双处维护风险（ColorChannelSlider 与 ColorChannelVerticalSlider）——同源同步注释为 MUST；后续链修复须双处应用。
- 填充采样语义对齐 `ColorMapper.colorAt`（Qool 既有类型，Controls.Slider/Dial 实证）——hue 用原理式数学函数实现、非 hue 恒等退化，无需实例化 ColorMapper。
- 私有竖直族仍为旧模式（userInteracting 互斥 Binding/双击重置）——其现代化（变体→channel、链替换、面板迁移、NumInput 清理）为后续独立任务，本 ADR 不承诺。
- 测试：`tst_qoolcolor_qml` 增补 `tst_colorchannelverticalslider.qml`（链/播种/填充几何/采样色/justMoved/通道分派/彩虹动态跟随与方向/契约裁剪显式断言，offscreen 惯例，实例 `animationEnabled: false`）；示例页 Playground 增补竖直滑块演示（含 hue）人工验收交互手感。
- 文档：`docs/reference/Qool.Color/ColorChannelVerticalSlider.md`（5 节）+ index.md 登记（实现完备后更新）。

## 决策状态

- 决策已定案（2026-08-23，grill-with-docs 讨论定稿；含 hue 彩虹原理式跟随的追加决策）；实施规格见 `.scratch/colorchannelverticalslider/spec.md`。
- 与 ADR-0013（高定边界定义、链模式）同源复用；与 ADR-0012（PropertyProxy 无状态代理语义）无冲突；orientation/RTL 由模板承载（ADR-0010 模式）。
