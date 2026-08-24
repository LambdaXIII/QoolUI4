# ColorChannelEdit 镜像布局：响应 Control 内置只读 `mirrored`，不自声明

ColorChannelEdit 已有 orientation 双布局（水平：长标签贴左 + 数字贴右；竖直：短标签在上 + 数字在下居中）。宿主需要镜像形态（水平左右对调 / 竖直上下对调）。本次定案：**不自声明 `mirrored` 属性，坐标绑定直接消费 `Control` 内置的同名只读属性**；开启方式为 `LayoutMirroring.enabled: true`（组件自身或任一祖先）。

机制约束（实测）：Qt 6.11 的 `QQuickControl` 声明 `Q_PROPERTY(bool mirrored READ isMirrored NOTIFY mirroredChanged FINAL)`（qquickcontrol_p.h）。QML 文档中重声明 `property bool mirrored` 触发「Cannot override FINAL property」，且症状极具误导性——报错行号指向无关行、组件整体 unavailable（实例化处报 Type unavailable），不指向冲突属性本身。该机制约束同时是设计依据：内置语义（LayoutMirroring 驱动的有效镜像状态）与需求「本来就是同一个作用」。

## Considered Options

- **自声明 `property bool mirrored: false`（本任务初始方案）**：被拒——与基座 FINAL 属性冲突，组件无法实例化（见上）；即便 Qt 未来放开，也与家族既有消费方式分裂。
- **自声明换名（如 `reversed`/`flip`）避开冲突**：被拒——同义异名制造第二套概念；ColorChannelSlider/ColorChannelVerticalSlider 已消费 T.Slider 内置 `mirrored`（ADR-0010/0011 的 RTL 线），族内必须同名同义。
- **响应内置只读 `mirrored`（采纳）**——零新增 API；语义即 Qt 官方镜像语义（LayoutMirroring），RTL 场景天然正确（layoutDirection 变化经 LayoutMirroring 传播时自动生效）；与滑块族同构。

## Key Decisions

1. **响应而非声明**：tag/editor 坐标绑定按 `root.mirrored` 取反。水平：editor 贴左（x=0）、tag 贴右（右缘贴边），5px 间隙不变；竖直：editor 在上（y=0）、tag 堆其下，水平居中不变。
2. **只换元素位置**：文字内容、方向、对齐不受镜像影响——长短标签分派仍只看 orientation（水平 channelTag / 竖直 channelTagShort）；隐式尺寸为对称和/最大值，不受镜像影响。
3. **宿主契约**：`LayoutMirroring.enabled: true` 开启（组件自身或祖先，可动态切换）；`mirrored` 为只读投影，宿主不得（也无法）直接赋值。
4. **族级约定**：Color 模块公开组件的镜像一律消费基座内置只读 `mirrored` 并在手工绑定布局中手动取反坐标（QML 手工定位不随 LayoutMirroring 自动翻转，anchors/positioners 才会）——后续新组件沿用，勿再自声明。

## Consequences

- ColorChannelEdit 无新增公开 API——reference 文档 Properties 表将 `mirrored` 记为只读继承属性；orientation/mirrored 双维共四种形态均由纯声明式绑定承载，无命令式分支。
- 测试驱动方式特殊：用例经 `e.LayoutMirroring.enabled = true`（JS 赋值 attached 属性）驱动并断言内置 `mirrored` 跟随，不能直接给 `mirrored` 赋值。
- 与 ADR-0010/0011（Slider 族 orientation/RTL）、ADR-0013/0018（通道组件高定边界）无冲突；本文将其镜像约定延伸到编辑类组件。

## 决策状态

- 决策已定案（2026-08-24，用户确认「内置已有则直接响应」）；实现、测试（tst_colorchanneledit 9/9）、文档同步同日完成。
