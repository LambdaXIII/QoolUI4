import QtQuick
import QtQuick.Shapes
import Qool

// 八边形圆角外轮廓形状路径（双环挖空描边）：控制点委托
// QoolBoxShapeControl，本类型不持有几何；供 QoolBox 内部使用。
ShapePath {
    id: root

    // 八边形控制点计算源（来自宿主 QoolBox 的 control）
    property QoolBoxShapeControl control

    joinStyle: ShapePath.BevelJoin
    strokeWidth: 0
    strokeColor: "transparent"

    startX: control.extTLx
    startY: control.extTLy

    // 内弧半径：内环相邻点弦长/√2（control 不加派生属性，Shape 自身从
    // 内环点推出；弦长 0 → 半径 0 退化自洽）。
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
        x: control.extTRx
        y: control.extTRy
    }

    PathArc {
        radiusX: root.control.settings.cutSizeTR
        radiusY: root.control.settings.cutSizeTR
        relativeX: radiusX
        relativeY: radiusY
    }

    PathLine {
        x: control.extRBx
        y: control.extRBy
    }

    PathArc {
        radiusX: root.control.settings.cutSizeBR
        radiusY: root.control.settings.cutSizeBR
        x: control.extBRx
        y: control.extBRy
    }

    PathLine {
        x: control.extBLx
        y: control.extBLy
    }

    PathArc {
        radiusX: root.control.settings.cutSizeBL
        radiusY: root.control.settings.cutSizeBL
        x: control.extLBx
        y: control.extLBy
    }

    PathLine {
        x: control.extLTx
        y: control.extLTy
    }

    PathArc {
        radiusX: root.control.settings.cutSizeTL
        radiusY: root.control.settings.cutSizeTL
        x: control.extTLx
        y: control.extTLy
    }

    // 内环（挖空）：内弧半径 = 内环相邻点弦长/√2
    PathMove {
        x: control.intTLx
        y: control.intTLy
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
} //curved border shape
