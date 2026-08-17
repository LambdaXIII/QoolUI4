import QtQuick
import QtQuick.Shapes
import Qool

// 低级 API 组件（spec D5）：required 注入整个 QoolBoxShapeControl——独立
// 使用不自洽是刻意的（供 QoolBox 组装）；containmentMask 挂 control 委托
// O(1) 线性不等式命中判定。详细契约见 docs/reference/Qool/OctagonShape.md。
Shape {
    id: root

    // 八边形控制点计算源（required——宿主注入，供 QoolBox 组装）
    required property QoolBoxShapeControl control
    // 填充到八边形内部区域的任意 Item（Qt 6.8 ShapePath::fillItem）
    property alias fillItem: fillShape.fillItem
    // 渐变填充通道（默认 null——纯色；fillItem 优先于渐变；ShapePath.fillGradient
    // 要求 ShapeGradient 新 API，旧 Gradient 类型不可用）
    property alias fillGradient: fillShape.fillGradient

    OctagonExternalShapePath {
        id: borderShape
        control: root.control
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.control.settings.borderColor
    }

    OctagonInternalShapePath {
        id: fillShape
        control: root.control
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.control.settings.fillColor
    }

    // 命中判定委托数值算法（QObject 掩码）：
    // 切角不命中；判定区随 offset 平移。
    containmentMask: root.control
}
