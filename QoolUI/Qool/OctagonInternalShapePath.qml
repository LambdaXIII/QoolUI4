import QtQuick
import QtQuick.Shapes
import Qool

/*!
    \qmltype OctagonInternalShapePath
    \inqmlmodule Qool
    \brief 八边形内部填充形状路径，绘制 QoolBox 的填充区域。

    由内部 8 点（\c int*）构成闭合多边形，控制点委托给
    \l QoolBoxShapeControl 计算。边框宽度大于 0 时内部点相对
    外轮廓向内收缩，使填充区域与边框区域不相交。

    供 \l QoolBox 内部使用；宿主一般不需要直接实例化。
*/
ShapePath {
    id: root
    /*! \qmlproperty QoolBoxShapeControl 八边形控制点计算源（来自宿主 QoolBox 的 control）。 */
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
