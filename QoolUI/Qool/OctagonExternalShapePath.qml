import QtQuick
import QtQuick.Shapes
import Qool

/*!
    \qmltype OctagonExternalShapePath
    \inqmlmodule Qool
    \brief 八边形外轮廓形状路径，绘制 QoolBox 的边框区域。

    由外部 8 点（\c ext*）与内部 8 点（\c int*）构成闭合环，
    所有控制点均委托给 \l QoolBoxShapeControl 计算，本类型自身
    不持有几何数据。边框宽度为 0 时内外部点重合，环退化为零面积，
    不产生绘制。

    供 \l QoolBox 内部使用；宿主一般不需要直接实例化。
*/
ShapePath {
    id: root
    /*! \qmlproperty QoolBoxShapeControl 八边形控制点计算源（来自宿主 QoolBox 的 control）。 */
    property QoolBoxShapeControl control

    joinStyle: ShapePath.BevelJoin
    pathHints: ShapePath.PathLinear | ShapePath.PathNonOverlappingControlPointTriangles

    startX: root.control.extTLx
    startY: root.control.extTLy

    PathLine {
        x: root.control.extTRx
        y: root.control.extTRy
    }
    PathLine {
        x: root.control.extRTx
        y: root.control.extRTy
    }
    PathLine {
        x: root.control.extRBx
        y: root.control.extRBy
    }
    PathLine {
        x: root.control.extBRx
        y: root.control.extBRy
    }
    PathLine {
        x: root.control.extBLx
        y: root.control.extBLy
    }
    PathLine {
        x: root.control.extLBx
        y: root.control.extLBy
    }
    PathLine {
        x: root.control.extLTx
        y: root.control.extLTy
    }
    PathLine {
        x: root.control.extTLx
        y: root.control.extTLy
    }
    //inner
    PathMove {
        x: root.control.intTLx
        y: root.control.intTLy
    }
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
} //border shape
