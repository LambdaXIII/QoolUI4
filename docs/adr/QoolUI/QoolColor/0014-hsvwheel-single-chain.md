# HSVWheel：二维取色表面设计定案（公开组件 + 单向链架构 + 写入钳制两路）

Color 模块迁移适配中，旧 `_private/HSVWheel.qml` 是 v3 迁移的临时载体——逻辑上 v4 QoolUI 并不存在 HSVWheel 这个正式组件。本次将其提升为 `Qool.Color` 公开一级组件（沿用 v3 名字，不改名），独立可复用。核心决策：**单向链驱动架构**（鼠标事件 → 数据 → 光标/圆盘，无"光标↔值"双向绑定）、**写入钳制两路**（值合法，非坐标 clamp）、**参考基线 = 旧行为**（v3 逐点调过的交互手感保留为约束，接口/语义按 v4 重定义）。

## Considered Options

- **一维链投影（拆 hue/sat 为两条独立链）**：被拒——二维表面一次鼠标事件天然设置两个数据（hue+sat），拆成两条链产生中间态时序问题（先行 hue 后行 sat 或反之，中间态颜色闪变/错位）；两个同时写是二维原子动作，语义最简、无时序依赖。
- **光标作为被拖动对象（旧 ColorCursor 的 x/y↔centerx/centery 双向环）**：被拒——光标是值的可视化（`position(hue,sat)` 纯函数派生），非独立可拖对象；双向同步环是死代码包袱（onXChanged 守卫 / onCenterxChanged 无条件写的刻意不对称写回），去除后定位单向、语义清晰。
- **坐标硬钳制（position 返回前 clamp 到圆内）**：被拒——写入层保证值合法（hue/sat 域合法）→ position 输出恒有效；在 position 处加坐标硬限制是冗余且掩埋"值合法性"这一真实契约（光标保护靠值合法而非坐标外观限制）。
- **保留 defaultValue/reset/双击重置（旧 v3 行为）**：被拒——交互契约裁剪对齐 ColorChannelSlider/ColorChannelControl（无 defaultValue/reset、双击无定义行为）；旧双击 reset（回圆心/无彩色）是特化包袱。
- **接口层 hue 越界 clamp 到 0 再写**：被拒——hue<0 代表"无色相"（marker），非数值越界；clamp 到 0 会合成写入（破坏 ColorChannelSlider 已确立的 sat-bump 语义：sat 拖到 0 → hue=-1 → 若 clamp 写 0 → 写方向把 sat 抬回 0.001，拖零被撤销）。接口写 hue<0 **不写**、显示保持最后合法位置。

## Key Decisions

1. **公开一级组件 + 沿用名**：`HSVWheel` 进 `Qool.Color` 公开组件（`QML_FILES` 注册），独立可复用。旧 `_private/HSVWheel.qml` 仅作参考基线，落成验证后随旧族清理移除。
2. **单向链架构**（核心）：`鼠标事件 → setValues() → hue/sat 数据 → position(hue,sat) → 光标定位`。输入层 InteractingArea（MouseArea 子类）响应鼠标，`setValues()` 把坐标经 `surface.check_point/hueAt/saturationAt` 转 hue/sat **两个同时写** assistant；呈现层光标（内联 `CrystalCursor` + `CenterPlacer`，见决策 5）与圆盘（`_private/HSVSurface`）独立从同一数据源（assistant）派生，互不直连。**绝无"光标↔值"双向绑定**。
3. **写入钳制两路**（值合法，非坐标 clamp）：
   - 交互路径：保留 `HSVSurface` 既有 `hueAt`（[0,1)）/`saturationAt`（clamp [0,1]）/`check_point`（圆外钳圆周）映射——旧 v3 手感逐点保留。
   - 接口路径：`hue`/`saturation`/`value` 三个公开属性写入时钳制——hue 越界（<0 无色相）不写/显示保持；sat/value clamp [0,1]；hue>1 圆周归一化（`% 1`，对齐 `QColor::setHsvF` 循环等价存储）。
   - `position` 无坐标硬钳制（纯函数）——值域由写入层保证。
4. **三值双向接口**：`hue`/`saturation`/`value` 暴露为公开双向属性（外部写 → assistant；assistant 变 → 回读）。`value` 用户操控不写（交互只写 hue/sat）、仅驱动圆盘绘制（压暗层 alpha = 1 - value）——value 由外部通道行/联动驱动。
5. **光标 = 内联 CrystalCursor + CenterPlacer（单向派生定位）**：取色光标是值的可视化——在 `InteractingArea` 内内联 `CrystalCursor`（`Qool.Controls.Components`）+ `CenterPlacer` + `TimerLatch`（不引用独立 `_private/ColorCursor` 组合件，两表面各自内联接线，见 ADR-0017）。实现用 `Qool.Crystal`（弃旧 `ColorCrystal`）；外观反馈结构借鉴 `ColorChannelSliderHandle`（Crystal + 三态展开 hover/userInteracting/值变化锁存 + TimerLatch + HoverHandler + 菱形掩码）；定位仅中心定位（`centerx/centery = position(hue,sat)` 事件驱动赋值，去 x/y↔centerx/centery 双同步环；绑定会被 CenterPlacer 回写破坏，禁止绑定）。两光标（slider handle / surface cursor）同族，维护心智负担小。契约裁剪：无 defaultValue/reset；`delta = Qore.bound(4, size×0.35, 15)`。
6. **HSVSurface 保持 `_private` 不动**：圆盘绘制（色相环 ConicalGradient + 饱和径向 + 明度压暗三层叠加）、映射数学（hueAt/saturationAt/position/check_point + 圆几何）原样复用，仅新增 `darkAlpha` 只读派生契约点（压暗层 alpha 锚，Shape 内 ShapePath 不可经 children 遍历）。
7. **交互契约裁剪**：无 `defaultValue`/`reset`、双击无定义行为。`animationEnabled` 不声明为属性——光标动画门控经 `Style.animationEnabled` 附加属性向下级联（`Style.animationEnabled: seedDone && root.Style.animationEnabled && !area.userInteracting`）。

## Consequences

- 仓库出现第二个"高定组件"（第一个 = ColorChannelSlider，T.Slider 平级通道滑块）——**「高定组件」术语升级进 CONTEXT.md**（ADR-0013 预留触发已命中）。
- 交互层与接口层经 assistant 收敛、`set_hsvHueF` 相等守卫断环（值未变化不广播）；同值写入零信号（无环）。
- 消费方（HSVPanel）改用公开 `HSVWheel`（import Qool.Color，colorAssistant 共享同一实例）；旧 `_private/HSVWheel.qml` 删除。
- `ColorHueCycleModel.md` 文档-代码矛盾一并澄清：HSVWheel **未**消费该 model（源码自绘 ConicalGradient）——文档原称其为 model source 是误导。
- 测试：`tst_qoolcolor_qml` 批次新增 `tst_hsvwheel.qml`（offscreen 惯例；三值双向同步/播种/hue 越界不写/clamp/归一化/darkAlpha 派生/光标圆内/无 reset）。真实鼠标交互（拖动/圆外点击）以人工运行验证覆盖（AGENTS 分级惯例——视觉/交互不可自动化断言）。
- 文档：`docs/reference/Qool.Color/HSVWheel.md`（5 节）+ index.md 登记（实现完备后更新）。

## 决策状态

- 决策已定案（2026-08-22，grill-with-docs 讨论定稿）；实现按本 ADR 执行。
- 与 ADR-0013 不纠缠（0013 定一维通道滑块高定，本 ADR 定二维取色表面——不同形态、不同决策域）；与 ADR-0012（PropertyProxy）无冲突（HSVWheel 固定三通道，直接连 assistant F 属性，不经通用 PropertyProxy 动态寻址）。

## 更正记录

- **2026-08-23（grill-with-docs）**：第 5 条「光标」更正——原定 `_private/HSVWheelCursor` 为 HSVWheel 私有光标，**更正为共用 `_private/ColorCursor`**（HSVWheel 与 HSLBox 共用，取色光标本是一回事，不拆分）。连带：`_private/HSVWheelCursor.qml` 删除（逻辑并入 ColorCursor）；`HSVWheel.qml` 改引用 `ColorCursor`；旧 `_private/ColorCursor.qml`（双模式 + 旧 ColorCrystal + hoveredSize）删除，`ColorCrystal.qml` 连带删除（唯一消费方消失）。实现落地见后续提交。
- **2026-08-23（重构收尾）**：共用 `_private/ColorCursor` **未落地**——HSVWheel/HSLBox 实际各自内联 CrystalCursor + CenterPlacer + TimerLatch + `updateCursor()` 接线（两处复制）；`ColorCursor.qml` 为孤儿件（无实例化点）。第 5 条按代码现状修订为内联接线（见 ADR-0017 定案）。
- **2026-08-28（animationEnabled 迁移收口）**：决策 7 的「`animationEnabled` 父链继承 + 声明序首位」**废弃**——HSVWheel 不再声明该属性，光标动画门控统一读 `Style.animationEnabled`（附加属性向下级联）；「声明序首位」惯例已自 standards-qml.md 移除。决策 7 按现状修订。
