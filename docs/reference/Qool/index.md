# Qool 模块

Qool 基础模块：形状、样式、窗口与工具类型。

Qool 是 QoolUI 的核心模块，提供：

- 形状体系：`QoolBox`（八边形）、`OctagonShape`、`OctagonCurvedShape`
  ——由 `QoolBoxShapeControl` 数值计算控制点，命中判定走 O(1)
  线性不等式。
- 样式体系：`Style` 附加属性 + `Theme` 值类型（见 [Style](Style.md) 与
  [Style 体系](../../articles/style-system.md)）。
- 窗口：`QoolWindow`、`QoolWindowBasic`（见 `QoolWindow 配件哲学`）。
- 工具：`CutSizeBinding`、`ItemAnimatedResizer`、`PositionLocker`、
  `TimerLatch`、`Floater`、`PositionTracker`、`ItemTracker`、`PropertyProxy`、
  `GeoLocker`、`Qore`、`QoolPalette`、`PixelFont` 等。

## 组件参考

- [BasicLabel](BasicLabel.md)
- [BasicRotationBehavior](BasicRotationBehavior.md)
- [Crystal](Crystal.md)
- [CutSizeBinding](CutSizeBinding.md)
- [CutSizesLocker](CutSizesLocker.md)
- [DragMoveArea](DragMoveArea.md)
- [Floater](Floater.md)
- [GeoLocker](GeoLocker.md)
- [HalfCrystal](HalfCrystal.md)
- [ItemAnimatedResizer](ItemAnimatedResizer.md)
- [ItemTracker](ItemTracker.md)
- [OctagonCurvedExternalShapePath](OctagonCurvedExternalShapePath.md)
- [OctagonCurvedInternalShapePath](OctagonCurvedInternalShapePath.md)
- [OctagonCurvedShape](OctagonCurvedShape.md)
- [OctagonExternalShapePath](OctagonExternalShapePath.md)
- [OctagonInternalShapePath](OctagonInternalShapePath.md)
- [OctagonShape](OctagonShape.md)
- [OffsetProjector](OffsetProjector.md)
- [PositionTracker](PositionTracker.md)
- [PropertyProxy](PropertyProxy.md)
- [QoolBox](QoolBox.md)
- [QoolBoxGadget](QoolBoxGadget.md)
- [QoolBoxSettings](QoolBoxSettings.md)
- [QoolBoxShapeControl](QoolBoxShapeControl.md)
- [RectGadget](RectGadget.md)
- [ShapeControl](ShapeControl.md)
- [Style](Style.md)
- [ThemeHQ](ThemeHQ.md)
- [ThemeHQModel](ThemeHQModel.md)
- [TimerLatch](TimerLatch.md)

## QoolBox control 回退值机制

QoolBox 的 `control` 属性在 `settings` 尚未就绪时保持默认实例
（Binding 的 `when` 不成立时属性回退到初始值——初始值不能为
null，否则回退即悬空）。因此 `control` 始终非空，形状路径与
命中判定可安全引用；宿主不应假定 control 在 settings 就绪前
会丢失。

## 附录：OffsetProjector 属性

### `vector2d Qool::OffsetProjector::direction`

位移方向（期望移动方向）。默认 (1, 0)。计算时归一化；与
`refDirection` 的点积必须 > 0（见 OffsetProjector 符号规则）。

### `vector2d Qool::OffsetProjector::refDirection`

距离的度量方向。默认 (1, 0)。计算时归一化；与 `direction`
的点积必须 > 0（见 OffsetProjector 符号规则）。

### `real Qool::OffsetProjector::refDistance`

沿 `refDirection` 方向的移动距离。默认 0。为 0 时 offset
恒为零向量（方向输入变化不产生 offsetChanged 通知）。

### `vector2d Qool::OffsetProjector::offset`

实际位移向量（只读）。满足 offset ∥ direction_unit 且
offset·refDirection_unit == refDistance（见 OffsetProjector 类文档）。
