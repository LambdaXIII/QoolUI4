# HSVWheel + HSLBox：二维取色表面各自内联光标组合（不共用独立 ColorCursor）

两个二维取色表面（HSVWheel、HSLBox）各自在其交互区内**内联**同一套光标组合——`CrystalCursor` + `CenterPlacer` + `TimerLatch` + `updateCursor()` 接线（两处复制，非共享）。`_private/ColorCursor.qml` 组合件存在但无任何消费者（孤儿件）。本 ADR 定案：HSLBox 公开化（`Qool.Color` 公开组件，单向链架构对齐 HSVWheel）；两表面光标 = 内联 CrystalCursor 接线，不引用独立 ColorCursor 组件。

## Considered Options

- **两表面共用 `_private/ColorCursor` 组合件（各表面引用同一件）**：被拒——实现未落地：HSVWheel/HSLBox 均在根层内联 CrystalCursor + CenterPlacer + TimerLatch，`ColorCursor.qml` 无实例化点。共用件引入双向同步（CenterPlacer 回写破坏绑定）与组合层转发成本，内联接线更直接。
- **HSLBox 保留私有光标（各表面各写一份光标）**：被拒——取色光标语义与行为完全一致（值位置 = 中心点、Crystal 菱形、三态展开）；内联接线是两处同构复制，比各写一份独立私有件更薄。
- **HSLBox 公开化不采用单向链（沿用旧 setValues + reset 模式）**：被拒——单向链架构（ADR-0014 定案）是二维取色表面统一主线：鼠标事件 → 数据 → 光标/表面派生，无「光标↔值」双向绑定。HSLBox 照搬同构。
- **保留 HSLBox 的 reset/双击（sat=1, ltn=0.5 纯色中点）**：被拒——交互契约裁剪对齐 HSVWheel/ColorChannelSlider（无 defaultValue/reset、双击无定义）；纯色中点 UX 是特化包袱，宿主需要可自实现。
- **HSLBox 暴露三属性 vs 双属性**：定案三属性——对齐 HSVWheel 三属性架构（HSVWheel: hue/sat/value；HSLBox: hue/sat/lightness）。hue 由外部（面板组合行）驱动、驱动 HSLSurface 色相渐变；交互写 sat/ltn。

## Key Decisions

1. **光标 = 内联 CrystalCursor 接线**：HSVWheel 与 HSLBox 各自在 `InteractingArea` 内内联 `CrystalCursor`（`Qool.Controls.Components`）+ `CenterPlacer` + `TimerLatch` + `updateCursor()`——两处同构复制，不引用 `_private/ColorCursor`。定位经 `CenterPlacer centerx/centery = position(...)` 映射（事件驱动赋值，禁止绑定——CenterPlacer 回写破坏绑定）；`color = assistant.solidColor`；hover/交互/值变化「或」→ `expanded`；`animationEnabled = seedDone && root.animationEnabled && !area.userInteracting`（拖动中关动画）。
2. **HSLBox 公开化**：`Qool.Color/HSLBox.qml` 公开一级组件（`QML_FILES` 注册），单向链架构对齐 HSVWheel：
   - 接口三属性 `hue`/`saturation`/`lightness`（双向）；`animationEnabled` 父链继承（声明序首位）；`colorAssistant` 默认自带。
   - 交互写 `hslSaturationF`/`hslLightnessF`（hue 外部驱动；hue<0 无色相时先置 0——HSL 平面需要有效色相才能取色）。
   - 写入钳制两路：交互路径保留 HSLSurface 既有映射（sat = x/w、ltn = 1 − y/h）；接口路径 hue 越界（<0 或 NaN）不写/显示保持、hue>1 归一化取模（% 1）、sat/ltn clamp [0,1]。
   - 契约裁剪：无 defaultValue/reset、双击无定义。
3. **HSVWheel 光标替换**：公开 `HSVWheel.qml` 内光标为内联 CrystalCursor + CenterPlacer（`value` 默认 0.5）；`_private/HSVWheelCursor.qml` 已删除。
4. **HSLSurface/HSVSurface 保持 `_private` 不动**：取色面绘制 + 映射数学（saturationAt/lightnessAt/position、hueAt/saturationAt/check_point）原样复用，仅消费方（公开组件）接线。
5. **HSLPanel 改引用**：`HSLPanel.qml` 内 `_private/HSLBox` 替换为公开 `HSLBox`（import Qool.Color，共享 colorAssistant）；旧 `_private/HSLBox.qml` 删除。
6. **hue 通道语义沿用**：面板色相组合行 `channel: HSVHue`（驱动 hsvHueF，两域经 colorAssistant.color 同步）——v3 既有行为，公开 HSLBox 不改变该语义（hue 属性回读 hslHueF，经 color 同步收敛）。

## Consequences

- 两二维取色表面（HSVWheel/HSLBox）光标接线同构（内联 CrystalCursor + CenterPlacer + TimerLatch + updateCursor）——两处复制，无独立组合件。
- `_private/ColorCursor.qml` 为孤儿件（无实例化点）；删除：`HSVWheelCursor.qml`、旧 `_private/HSLBox.qml`；新增：公开 `HSLBox.qml`。
- 测试：`tst_qoolcolor_qml` 新增 `tst_hslbox.qml`（三值双向/播种/hue 越界不写/clamp/光标域内/无 reset，对齐 tst_hsvwheel 模式）；HSVWheel 既有用例回归。
- 文档：`docs/reference/Qool.Color/HSLBox.md` + index.md 登记；HSVWheel.md 光标引用更新；ColorCursor.md 如实标注组件现状（无消费者）。
- 依赖：本 ADR 依赖 ADR-0015（CenterPlacer）+ ADR-0016（CrystalCursor）先行落地。

## 决策状态

- 决策已定案（2026-08-23，grill-with-docs 讨论定稿）；2026-08-23 重构收尾按代码现状修订——「共用 ColorCursor」未落地，两表面改为各自内联 CrystalCursor 接线；`ColorCursor.qml` 保留为孤儿件（无消费者）。
- 与 ADR-0014 关系：0014 定 HSVWheel 单向链/钳制/契约原则（仍有效），本 ADR 定「两表面光标内联接线」。
