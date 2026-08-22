# HSVWheel + HSLBox：二维取色表面统一用共用 ColorCursor

ADR-0016 产出共用 `ColorCursor`（CrystalCursor + CenterPlacer + surface 交互）后，两个二维取色表面（HSVWheel、HSLBox）的光标统一改用该共用件——取色光标对两表面是同一回事（ADR-0014 更正记录已预告）。本 ADR 定案：HSVWheel 改引用 ColorCursor（替换 HSVWheelCursor），HSLBox 公开化（`Qool.Color` 公开组件，单向链架构对齐 HSVWheel），两者共用同一光标。

## Considered Options

- **HSLBox 保留私有光标（各表面各写一份光标）**：被拒——取色光标语义与行为完全一致（值位置 = 中心点、Crystal 菱形、三态展开），拆分是重复代码（ADR-0014 原错误决策已更正）。共用是「本来一回事」的回归。
- **HSLBox 公开化不采用单向链（沿用旧 setValues + reset 模式）**：被拒——单向链架构（ADR-0014 定案）是二维取色表面统一主线：鼠标事件 → 数据 → 光标/表面派生，无「光标↔值」双向绑定。HSLBox 照搬同构。
- **保留 HSLBox 的 reset/双击（sat=1, ltn=0.5 纯色中点）**：被拒——交互契约裁剪对齐 HSVWheel/ColorChannelSlider（无 defaultValue/reset、双击无定义）；纯色中点 UX 是特化包袱，宿主需要可自实现。与 HSVWheel 的「圆心/无彩色」reset 一并裁掉，勿统一语义、勿保留。
- **HSLBox 暴露三属性 vs 双属性**：定案三属性——对齐 HSVWheel 三属性架构（HSVWheel: hue/sat/value；HSLBox: hue/sat/lightness）。hue 由外部（面板组合行）驱动、驱动 HSLSurface 色相渐变；交互写 sat/ltn。

## Key Decisions

1. **共用 ColorCursor**：HSVWheel 与 HSLBox 均使用 ADR-0016 的 `_private/ColorCursor`（组合 CrystalCursor + CenterPlacer）。定位经 CenterPlacer centerx/centery = `position(...)` 映射；`currentColor → color`；hover/交互/值变化「或」→ expanded。
2. **HSVWheel 改引用**：现有公开 `HSVWheel.qml` 内 `_private/HSVWheelCursor` 替换为 `_private/ColorCursor`；`HSVWheelCursor.qml` 删除（ADR-0016 清理清单）。
3. **HSLBox 公开化**：新建 `Qool.Color/HSLBox.qml` 公开一级组件（`QML_FILES` 注册），单向链架构对齐 HSVWheel：
   - 接口三属性 `hue`/`saturation`/`lightness`（双向）；`animationEnabled` 父链继承（声明序首位）；`colorAssistant` 默认自带。
   - 交互写 `hslSaturationF`/`hslLightnessF`（hue 外部驱动；hue<0 无色相时先置 0——HSL 平面需要有效色相才能取色）。
   - 写入钳制两路：交互路径保留 HSLSurface 既有映射（sat = x/w、ltn = 1 − y/h）；接口路径 hue 越界（<0）不写/显示保持、sat/ltn clamp [0,1]。
   - 契约裁剪：无 defaultValue/reset、双击无定义。
4. **HSLSurface 保持 `_private` 不动**：取色面绘制（satBox/lightnessBox/strokeBox 三层）+ 映射数学（saturationAt/lightnessAt/position）原样复用，仅消费方（公开 HSLBox）接线。
5. **HSLPanel 改引用**：`HSLPanel.qml` 内 `_private/HSLBox` 替换为公开 `HSLBox`（import Qool.Color，共享 colorAssistant）；旧 `_private/HSLBox.qml` 删除。
6. **hue 通道语义沿用**：面板色相组合行 `channel: HSVHue`（驱动 hsvHueF，两域经 colorAssistant.color 同步）——v3 既有行为，公开 HSLBox 不改变该语义（hue 属性回读 hslHueF，经 color 同步收敛）。

## Consequences

- 两二维取色表面（HSVWheel/HSLBox）光标统一共用 ColorCursor——光标代码单点维护，表面各自只保留取色映射与接口。
- 删除：`HSVWheelCursor.qml`（并入 ColorCursor）、旧 `_private/HSLBox.qml`；新增：公开 `HSLBox.qml`。
- 测试：`tst_qoolcolor_qml` 新增 `tst_hslbox.qml`（三值双向/播种/hue 越界不写/clamp/光标域内/无 reset，对齐 tst_hsvwheel 模式）；HSVWheel 既有用例随光标替换回归。
- 文档：`docs/reference/Qool.Color/HSLBox.md`（5 节）+ index.md 登记；HSVWheel.md 光标引用更新。
- 依赖：本 ADR 依赖 ADR-0015（CenterPlacer）+ ADR-0016（CrystalCursor/ColorCursor）先行落地。

## 决策状态

- 决策已定案（2026-08-23，grill-with-docs 讨论定稿）；实现按本 ADR 执行。
- 与 ADR-0014 关系：0014 定 HSVWheel 单向链/钳制/契约原则（仍有效），本 ADR 定「两表面统一用 ColorCursor」新决策域（0014 更正记录预告的实现）。
