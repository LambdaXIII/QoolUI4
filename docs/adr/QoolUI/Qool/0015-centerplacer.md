# CenterPlacer：中心坐标双向同步挂件（centerx/centery ↔ x/y，任意带几何属性对象）

Color 模块光标/手柄重构中，表面场景（HSVWheel/HSLBox 的光标）与一维场景（Slider 手柄）共用同一视觉骨架（Crystal 菱形 + 缩放 + 延迟），但定位语义不同：滑块用手柄左上角 x/y（模板注入或 displayValue 驱动），表面光标用「组件中心 = 值位置」（`position(hue,sat)` 映射）。中心坐标 ↔ 左上角坐标的换算与双向同步是**独立于视觉的几何能力**——本 ADR 将其抽为独立挂件 `CenterPlacer`，任意带 x/y/width/height 四个属性的 QtObject 均可挂载，获得 centerx/centery 双向等价坐标。

## Considered Options

- **坐标同步内建于光标组件（ColorCursor/CrystalCursor 自带 centerx/centery）**：被拒——同步算法与视觉无关，内建则每个需要中心坐标的组件重复一份 Connections 代码；且 CrystalCursor 作为基准件应保持「能力单一」（延迟缩放行为），坐标是另一维度能力，混入破坏单一职责。
- **用 QML 绑定实现双向（centerx 绑定表达式 + x 绑定表达式互指）**：被拒——双向绑定必然成环（centerx 依赖 x、x 依赖 centerx），QML 绑定引擎无环保证（旧 ColorCursor 的双同步环即死代码包袱，ADR-0014 已批）；且 w/h 参与时绑定表达式互相覆盖。
- **沿用 Qt `Positioner` 命名**：被拒——Qt 语境 Positioner 指 Flow/Grid/Row/Column 布局定位器（自动排列子项），与中心坐标同步语义无关，同名歧义严重。最终命名 `CenterPlacer`（设置 center 即放置 target，动词准确、无歧义）。
- **仅单向（center → x/y 派生，x/y 变化不回写）**：被拒——消费方（滑块场景）用 x/y 定位时，center 成为无法反映实际位置的死属性；「读写 center 等价于 x/y」是完整坐标接口，双向等价才让两套坐标系都可用（消费方按场景自由选择）。

## Key Decisions

1. **独立挂件 + 任意 target**：`CenterPlacer` 为 `Qool` 模块 SmartObject（非 Item，无渲染，对齐 GeoLocker 挂件模式）。`target: QtObject` 注入——任意带 x/y/width/height 四个属性的对象（Item/QtObject 自定义属性均可）。用法：`CenterPlacer { target: cursor }`——设 `placer.centerx/centery` 即改 `cursor.x/y`。
2. **centerx/centery 为挂件自持属性**：QML 无法给 target 动态加属性，center 坐标由挂件自身持有；消费方绑定/读写 `positioner.centerx/centery`，内部同步到 target。
3. **双向等价（读写 center ≡ 读写 x/y）**：`centerx = x + width/2`（几何语义：中心点 vs 左上角）。写 center 代理设 x/y；读 center 反映 x/y 当前值。两套坐标系完整可用，消费方按场景选择（滑块用 x/y、表面用 center）。
4. **Connections 程序化双向同步（防环）**：
   - 读方向：`onXChanged/onYChanged/onWidthChanged/onHeightChanged` → 写 centerx/centery（守卫：同值不写）。
   - 写方向：`onCenterxChanged/onCenteryChanged` → 写 target.x/y（无条件写，同值守卫断环）。
   - w/h 变化参与同步（`center = x + w/2`，根尺寸变化中心随之变）。
   - 与旧 ColorCursor 双同步环的区别：旧件是「onXChanged 带守卫写 center + onCenterxChanged 无条件写 x」的不对称写回 + 绑定混用；本件纯 Connections 程序化、守卫统一、无绑定互指，环被同值守卫 + 单向写回方向彻底断开。
5. **落点 Qool**：与 GeoLocker 同层（几何能力挂件、SmartObject、target 注入）。不依赖 Crystal/Controls，纯几何能力；CrystalCursor（Controls.Components）未来如需中心坐标可 import Qool 获得。

## Consequences

- 仓库出现几何挂件第二例（GeoLocker 锁 x/y/w/h 四维单向 / CenterPlacer 双向 center 坐标）——同层不同能力，命名各表其意（Locker 锁定 / Placer 放置），不构成家族命名强制。
- CrystalCursor（ADR-0016）不内建 centerx/centery——坐标能力经 CenterPlacer 组合获得，基准件保持单一职责。
- 消费方（ColorCursor）保留独立文件：组合 CrystalCursor + CenterPlacer + surface 交互映射。
- 测试：`tst_qool_qml` 批次新增用例（双向同步/守卫断环/w-h 参与/任意 target 对象）。真实场景（光标拖动定位）以人工运行验证覆盖。
- 文档：`docs/reference/Qool/CenterPlacer.md`（5 节）+ index.md 登记。

## 决策状态

- 决策已定案（2026-08-23，grill-with-docs 讨论定稿）；实现按本 ADR 执行。
- 与 ADR-0012（PropertyProxy）同族不同能力（PropertyProxy 无状态属性桥 / CenterPlacer 双向坐标同步）；与 GeoLocker 同层不同语义（单向四维锁定 / 双向中心坐标）。
