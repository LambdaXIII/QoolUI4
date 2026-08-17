import QtQuick
import QtQuick.Shapes
import Qool

// 八边形内部填充形状路径：控制点委托 QoolBoxShapeControl；供 QoolBox
// 内部使用。详细契约见 docs/reference/Qool/OctagonInternalShapePath.md。
ShapePath {
    id: root
    // 八边形控制点计算源（来自宿主 QoolBox 的 control）
    property QoolBoxShapeControl control

    strokeWidth: 0
    strokeColor: "transparent"
    joinStyle: ShapePath.BevelJoin
    pathHints: ShapePath.PathLinear | ShapePath.PathNonOverlappingControlPointTriangles
               | ShapePath.PathConvex

    startX: root.control.intTLx
    startY: root.control.intTLy

    PathLine {
        x: root.control.intTRx
        y: root.control.intTRy
    }
    PathLine {
        x: root.control.intRTx
        y: root.control.intRTy
    }
    PathLine {
        x: root.control.intRBx
        y: root.control.intRBy
    }
    PathLine {
        x: root.control.intBRx
        y: root.control.intBRy
    }
    PathLine {
        x: root.control.intBLx
        y: root.control.intBLy
    }
    PathLine {
        x: root.control.intLBx
        y: root.control.intLBy
    }
    PathLine {
        x: root.control.intLTx
        y: root.control.intLTy
    }
    PathLine {
        x: root.control.intTLx
        y: root.control.intTLy
    }
} //fill shape
