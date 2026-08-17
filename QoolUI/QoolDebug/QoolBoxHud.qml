import QtQuick
import Qool

Item {
    id: root

    // 目标 QoolBox（默认 parent——须直接作 QoolBox 子项，类型检查保证
    // 挂错父级时 box 为 null，HUD 不工作：调试工具边界暴露，误配置立即可见）
    property QoolBox box: parent

    // 显示内部控制点（int*）
    property bool showIntPoints: true
    // 显示外部控制点（ext*）
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
