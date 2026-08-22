# ColorChannelSlider：高定设计定案（T.Slider 平级 + 通道视觉内化 + 交互契约裁剪）

Color 模块迁移适配中，旧 `_private/ColorSlider.qml`（标题+数值输入行 + 轨道+光标行）拆分为两个独立公开组件：文字部分已由 `ColorChannelEdit` 承接（已完成，commit e229db8/8b40cbb）；拖动部分本次由 `ColorChannelSlider` 承接。本组件为通用单通道滑块（`channel: int` + PropertyProxy 动态寻址，链模式对齐 ColorChannelEdit）。核心决策：**高定组件**——通道视觉（渐变/光标/描边）完全内化为组件语义，不暴露外观覆写接口；交互契约裁剪（移除 defaultValue/reset/双击）；渐变经 `_private` JS 双函数映射；Hue 为唯一渐变特化（自带彩虹，不响应双色）。

## Considered Options

- **基于 Qool.Controls.Slider 实例化/继承并覆写 background/handle**：被拒——Slider 几何模型（pCtrl 的 side/shrinkSize）在组件作用域内不可达，覆写 delegate 须外部重算同套公式；默认 handle 内建反馈（latch/resizer/hover）替换即丢、须重建；且视觉体系不同构（Slider 为 Style 驱动 accent/buttonText，通道滑块为通道数据驱动）。复用 = 复制。
- **手写 Item + InteractingArea（旧模式拍平件）**：被拒——T.Slider 模板免费提供拖动/键盘步进/点击跳转/RTL/inverted range，旧自写拖动映射（`cursor.size/2` 偏移 + CutAtEdges）就是模板 position 语义，无存在理由。
- **基类 + 变体文件（旧 ColorSlider 模式）**：被拒——ColorChannelEdit 已确立通用单组件模式；行为差异仅 hue 一处（sat-bump），channel 判断内化，不做变体文件。
- **可插拔外观接口（fillGradient/strokeColor/leftPoint/rightPoint 别名，旧 ColorSlider 暴露）**：被拒——通道渐变是组件语义本身（轨道显示通道数据），非宿主定制面；可插拔由模板级 delegate 替换承接（见 Key Decisions 2）。
- **保留 defaultValue/reset/双击重置**：被拒——per-channel 默认（Hue=0/Value=1/Alpha=1）与重置语义是旧特化包袱，通用组件无重置契约。
- **环绕限幅（CycleBetweenEdges）保留**：被拒——新基座下 value 恒 `[0,1]`（模板拖动映射 + 裁剪链），assistant 越界仅来自外部程序写入；裁剪可达同等安全且语义简单。
- **渐变全静态字面量表**：被拒——Alpha（终点 = `assistant.solidColor`，旧语义）与 Saturation（轨道必须有 hue/亮度参与）无法静态，两函数承载动态分支。
- **轨道用裸 Shape（旧 `ColorSliderBackground` 手写 ShapePath）**：被拒——Crystal（Qool 模块，OctagonShape 特化 cut=shortEdge/2）在宽轨道下与旧六边形几何完全同形，且已提供 fillGradient/borderColor/borderWidth/掩码——"用当前 QoolUI 组件重写"的直接答案。

## Key Decisions

1. **T.Slider 平级实现**：`ColorChannelSlider` 直接基于 `QtQuick.Templates.Slider`，与 `Qool.Controls.Slider` 为兄弟组件（同模板交互 + Crystal 视觉语言家族，互不继承）。两套视觉体系有意分叉：Slider 样式驱动、通道滑块通道数据驱动。
2. **高定：关闭外观接口**：不暴露变体式外观参数（fillGradient/strokeColor 别名等）。**边界定义**：高定 ≠ 不可插拔——模板级 `background`/`handle` delegate 整体替换仍是唯一插拔口（宿主可整换轨道/光标）；关闭的是"变体式外观参数"。与 AGENTS「多层插拔（v4 设计哲学）」的关系：可插拔由模板 delegate 层承接，特化外观参数不再叠加。
3. **交互契约裁剪**：移除 `defaultValue`/`reset`/双击重置（旧双击 = 回 defaultValue）。T.Slider 模板点击跳转/键盘/拖动免费保留。`value` 初始默认统一 1——hue 为循环量（`Qt.hsva(1,1,1,1)` ≡ `Qt.hsva(0,1,1,1)`），1/0 视觉等价，无副作用；链在 onCompleted 从 assistant 播种，默认只影响播种前一瞬。
4. **行为内化**（公开组件自包含，对齐 ColorChannelEdit 先例）：
   - **无条件双向链**：`root.value ↔ PropertyProxy(assistant, channelNameF) ↔ colorAssistant`，同值守卫收敛——无拖动互斥门控（链防抖由模板拖动语义 + 同值守卫承担）。
   - **sat-bump 保留**：channel 为 hue（HSVHue/HSLHue）且 assistant 当前 hue < 0（无色相色）时，先写对应 sat = 0.001 再写 hue——无色相色上拖 hue 必须有可见反馈（旧 UX 契约，勿删）。
   - **限幅改裁剪**：环绕（CycleBetweenEdges 含 -1 修正）废弃，统一裁剪 `[0,1]`（语义简化，见 Considered Options）。
   - **handle 位置动画**：displayValue 中间层 + 门控 Behavior（`pressed` 时关）——拖动中光标跟手（无动画）、松手/外部改值平滑过渡（旧 value/displayValue 分离语义）。
5. **渐变双函数映射**（`_private/ChannelSliderColors.js`）：`fromColor(channel, assistant)` / `toColor(channel, assistant)`——两函数各维护静态表 + 动态分支。10 通道静态字面量：RGB 黑→纯通道色（"通道贡献从无到有"）；HSVValue/HSLLightness 黑→白（旧 Value 语义）；CMYK 白→纯通道色（墨量 0=纸白）。2 通道动态：Alpha `transparent → solidColor`（旧语义）；HSVSaturation 灰(当前亮度)→`hsva(hue,1,v)`、HSLSaturation 灰(当前亮度)→`hsla(hue,1,l)`（原理式——轨道每位置 = 改 sat 后真实结果色，亮度钉死为当前值）。
6. **Hue 彩虹特化**（`_private/ColorChannelSliderTrackHue.qml`）：11 档彩虹 `hsva(p,1,1,1)`（旧语义），自带渐变、不响应 from/to 双色；薄覆盖基类 `gradient` 属性，几何零重复（锚定几何与基类同源 `ColorChannelSliderColors.js gradientAnchors`）。
7. **轨道 = Crystal**：background delegate（Item，T.Slider 契约）内 Crystal 轨道——`fillGradient`（ShapeGradient）承接双色渐变、`borderColor` 内描边环承接旧 stroke、`cut = 短边/2` 与旧六边形同形。渐变锚定按 cut 计算（`x1 = cut → x2 = w − cut`），旧 leftPoint/rightPoint 作废。**收缩模型对齐 Qool.Controls.Slider**（`side = horizontal ? availableHeight : availableWidth`、`shrinkSize = Qore.bound(3, side×0.25, 25)`、轨道收缩 + 法向居中）——展开光标"顶出轨道但不出控件"三心对齐。orientation/RTL 由模板免费承载，渐变端锚定值增大视觉端（对齐 ADR-0010 模式：水平 RTL 对调 x 端、垂直固定 from 底 → to 顶）。
8. **描边统一规则**：`assistant.recommendedForegroundColor`（旧水平族三变体同规则），高定内化、不暴露。
9. **文件结构**：公开 `ColorChannelSlider.qml`（T.Slider 自包含行为 + channel 分派 background/handle）；`_private/` 视觉件——`ColorChannelSliderTrack.qml`（双色基类）、`ColorChannelSliderTrackHue.qml`（彩虹覆写）、`ColorChannelSliderHandle.qml`（共享光标：Crystal 菱形 + solidColor + 三态展开 + 掩码 + 位置动画）、`ColorChannelSliderColors.js`（双函数映射 + 锚定几何 gradientAnchors）。行为基类落点：公开组件自包含，_private 只放视觉件。

## Consequences

- 仓库出现两个 T.Slider 家族组件（Qool.Controls.Slider 样式驱动 / ColorChannelSlider 通道数据驱动）——兄弟关系，视觉体系有意分叉，不互相继承。
- 消费方（HSV/HSL 面板水平滑块）迁移后不再能覆写 fillGradient——旧变体 `ColorSlider_Hue/Value/Alpha` 随迁移废弃（清理清单阶段裁定，见 journal active_works 2026-08-21-color-migration-adaptation.md）。
- 双色映射集中于 JS——改通道端点色一处维护；动态端点（Alpha/Sat）依赖 assistant，改色语义须同时理解。
- 渐变表语义（RGB 黑→纯色、CMYK 白→纯色、Sat 原理式）为数据决策，JS 注释承载，不升级为术语。
- 测试：`tst_qoolcolor_qml` 增补（几何断言 + 链同步，offscreen 惯例）；示例页 Playground 人工验收（无合成鼠标的交互映射以人工运行验证，既有惯例）。
- 文档：`docs/reference/Qool.Color/ColorChannelSlider.md`（5 节）+ index.md 登记（实现完备后更新）。
- 术语：**高定组件** 已升级进 CONTEXT.md（ADR-0013 预留触发已命中——第二个高定组件 HSVWheel 出现，见 ADR-0014）；边界定义（通道视觉内化、不暴露外观接口、通用单组件）沿用本 ADR。

## 决策状态

- 决策已定案（2026-08-21，grill-with-docs 讨论定稿）；实现按本 ADR 执行。
- 与 ADR-0010/0011 同源（orientation/RTL 正交模式复用）；与 ADR-0012（PropertyProxy）无冲突（链消费其无状态代理语义）。
