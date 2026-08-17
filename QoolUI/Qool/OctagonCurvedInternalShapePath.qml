import QtQuick
import QtQuick.Shapes
import Qool

// 八边形圆角内部填充形状路径：控制点委托 QoolBoxShapeControl，本类型
// 不持有几何；供 QoolBox 内部使用。详细契约见
// docs/reference/Qool/OctagonCurvedInternalShapePath.md。
ShapePath {
    id: root

    // 八边形控制点计算源（来自宿主 QoolBox 的 control）
    property QoolBoxShapeControl control

    joinStyle: ShapePath.BevelJoin
    strokeWidth: 0
    strokeColor: "transparent"

    startX: control.intTLx
    startY: control.intTLy

    // 内弧半径：内环相邻点弦长/√2（spec D5——control 不加派生属性，
    // Shape 自身从内环点推出；弦长 0 → 半径 0 退化自洽）。
    readonly property QtObject pCtrl: QtObject {
        readonly property real radiusTR: Math.hypot(
            control.intRTx - control.intTRx, control.intRTy - control.intTRy)
            / Math.SQRT2
        readonly property real radiusBR: Math.hypot(
            control.intBRx - control.intRBx, control.intBRy - control.intRBy)
            / Math.SQRT2
        readonly property real radiusBL: Math.hypot(
            control.intBLx - control.intLBx, control.intBLy - control.intLBy)
            / Math.SQRT2
        readonly property real radiusTL: Math.hypot(
            control.intTLx - control.intLTx, control.intTLy - control.intLTy)
            / Math.SQRT2
    }

    PathLine {
        x: control.intTRx
        y: control.intTRy
    }

    PathArc {
        radiusX: root.pCtrl.radiusTR
        radiusY: root.pCtrl.radiusTR
        relativeX: radiusX
        relativeY: radiusY
    }

    PathLine {
        x: control.intRBx
        y: control.intRBy
    }

    PathArc {
        radiusX: root.pCtrl.radiusBR
        radiusY: root.pCtrl.radiusBR
        x: control.intBRx
        y: control.intBRy
    }

    PathLine {
        x: control.intBLx
        y: control.intBLy
    }

    PathArc {
        radiusX: root.pCtrl.radiusBL
        radiusY: root.pCtrl.radiusBL
        x: control.intLBx
        y: control.intLBy
    }

    PathLine {
        x: control.intLTx
        y: control.intLTy
    }

    PathArc {
        radiusX: root.pCtrl.radiusTL
        radiusY: root.pCtrl.radiusTL
        x: control.intTLx
        y: control.intTLy
    }
} //curved fill shape
