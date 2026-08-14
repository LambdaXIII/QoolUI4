import QtQuick
import Qool

/*!
    \qmltype QoolBoxHud
    \inqmlmodule Qool.Debug
    \brief QoolBox 专用调试叠加层：显示外/内部控制点（ext* / int* 16 点）。

    必须**直接作为 \l QoolBox 的子项**使用：\c box 属性默认取 \c parent，
    且要求该 parent 是 QoolBox（属性类型检查）——挂错父级（非 QoolBox）
    时 box 为 null，HUD 不工作（调试工具边界暴露原则：误配置立即可见）。

    调试件只消费 QoolBox 公开面（\c box.control 的 ext* / int* 16 点），
    无白盒契约。原 OctagonShapeHud（重定位，ADR-0008——control 公开后
    不再需要 objectName/findChild 内部方案）。
*/
Item {
    id: root

    /*! \qmlproperty QoolBox 目标 QoolBox（默认 parent——须直接作 QoolBox 子项）。 */
    property QoolBox box: parent

    /*! \qmlproperty bool 显示内部控制点（int*）。 */
    property bool showIntPoints: true
    /*! \qmlproperty bool 显示外部控制点（ext*）。 */
    property bool showExtPoints: true

    QtObject {
        id: pCtrl
        property color extPointColor: Style.positive
        property color intPointColor: Style.negative
    }

    // 控制点坐标 = box 内部坐标系——PointIndicator 挂到 box 下（本地坐标
    // 一致）。box 为 null（误用）时挂 root 兜底，point 求值 undefined——
    // 可见异常属调试工具边界暴露。
    PointIndicator {
        name: "extTL"
        infoAnchorFrom: Qore.TopCenter
        infoAnchorTo: Qore.BottomCenter
        parent: root.box ?? root
        point: root.box.control.extTL
        color: pCtrl.extPointColor
        visible: root.showExtPoints
    }

    PointIndicator {
        name: "extTR"
        infoAnchorFrom: Qore.TopCenter
        infoAnchorTo: Qore.BottomCenter
        parent: root.box ?? root
        point: root.box.control.extTR
        color: pCtrl.extPointColor
        visible: root.showExtPoints
    }

    PointIndicator {
        name: "extBL"
        infoAnchorFrom: Qore.BottomCenter
        infoAnchorTo: Qore.TopCenter
        parent: root.box ?? root
        point: root.box.control.extBL
        color: pCtrl.extPointColor
        visible: root.showExtPoints
    }

    PointIndicator {
        name: "extBR"
        infoAnchorFrom: Qore.BottomCenter
        infoAnchorTo: Qore.TopCenter
        parent: root.box ?? root
        point: root.box.control.extBR
        color: pCtrl.extPointColor
        visible: root.showExtPoints
    }

    PointIndicator {
        name: "extLT"
        infoAnchorFrom: Qore.LeftCenter
        infoAnchorTo: Qore.RightCenter
        parent: root.box ?? root
        point: root.box.control.extLT
        color: pCtrl.extPointColor
        visible: root.showExtPoints
    }

    PointIndicator {
        name: "extLB"
        infoAnchorFrom: Qore.LeftCenter
        infoAnchorTo: Qore.RightCenter
        parent: root.box ?? root
        point: root.box.control.extLB
        color: pCtrl.extPointColor
        visible: root.showExtPoints
    }

    PointIndicator {
        name: "extRT"
        infoAnchorFrom: Qore.RightCenter
        infoAnchorTo: Qore.LeftCenter
        parent: root.box ?? root
        point: root.box.control.extRT
        color: pCtrl.extPointColor
        visible: root.showExtPoints
    }

    PointIndicator {
        name: "extRB"
        infoAnchorFrom: Qore.RightCenter
        infoAnchorTo: Qore.LeftCenter
        parent: root.box ?? root
        point: root.box.control.extRB
        color: pCtrl.extPointColor
        visible: root.showExtPoints
    }

    PointIndicator {
        name: "intTL"
        infoAnchorFrom: Qore.BottomLeft
        infoAnchorTo: Qore.TopLeft
        parent: root.box ?? root
        point: root.box.control.intTL
        color: pCtrl.intPointColor
        visible: root.showIntPoints
    }

    PointIndicator {
        name: "intTR"
        infoAnchorFrom: Qore.BottomRight
        infoAnchorTo: Qore.TopRight
        parent: root.box ?? root
        point: root.box.control.intTR
        color: pCtrl.intPointColor
        visible: root.showIntPoints
    }

    PointIndicator {
        name: "intBL"
        infoAnchorFrom: Qore.TopLeft
        infoAnchorTo: Qore.BottomLeft
        parent: root.box ?? root
        point: root.box.control.intBL
        color: pCtrl.intPointColor
        visible: root.showIntPoints
    }

    PointIndicator {
        name: "intBR"
        infoAnchorFrom: Qore.RightTop
        infoAnchorTo: Qore.RightBottom
        parent: root.box ?? root
        point: root.box.control.intBR
        color: pCtrl.intPointColor
        visible: root.showIntPoints
    }

    PointIndicator {
        name: "intLT"
        infoAnchorFrom: Qore.RightBottom
        infoAnchorTo: Qore.LeftTop
        parent: root.box ?? root
        point: root.box.control.intLT
        color: pCtrl.intPointColor
        visible: root.showIntPoints
    }

    PointIndicator {
        name: "intLB"
        infoAnchorFrom: Qore.RightTop
        infoAnchorTo: Qore.LeftBottom
        parent: root.box ?? root
        point: root.box.control.intLB
        color: pCtrl.intPointColor
        visible: root.showIntPoints
    }

    PointIndicator {
        name: "intRT"
        infoAnchorFrom: Qore.LeftBottom
        infoAnchorTo: Qore.RightTop
        parent: root.box ?? root
        point: root.box.control.intRT
        color: pCtrl.intPointColor
        visible: root.showIntPoints
    }

    PointIndicator {
        name: "intRB"
        infoAnchorFrom: Qore.LeftTop
        infoAnchorTo: Qore.RightBottom
        parent: root.box ?? root
        point: root.box.control.intRB
        color: pCtrl.intPointColor
        visible: root.showIntPoints
    }
}
