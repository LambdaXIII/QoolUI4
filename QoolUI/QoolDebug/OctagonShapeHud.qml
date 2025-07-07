import QtQuick
import Qool

Item {
    id: root

    property var shape: parent

    property bool showIntPoints: true
    property bool showExtPoints: true

    readonly property OctagonShapeHelper controller: shape?.shapeControl ?? internalController

    OctagonShapeHelper {
        id: internalController
    }

    QtObject {
        id: pCtrl
        property color extPointColor: Style.positive
        property color intPointColor: Style.negative
    }

    PointIndicator {
        name: "extTL"
        infoAnchorFrom: Qore.TopCenter
        infoAnchorTo: Qore.BottomCenter
        parent: root.shape ?? root
        point: root.controller.extTL
        color: pCtrl.extPointColor
        visible: root.showExtPoints
    }

    PointIndicator {
        name: "extTR"
        infoAnchorFrom: Qore.TopCenter
        infoAnchorTo: Qore.BottomCenter
        parent: root.shape ?? root
        point: root.controller.extTR
        color: pCtrl.extPointColor
        visible: root.showExtPoints
    }

    PointIndicator {
        name: "extBL"
        infoAnchorFrom: Qore.BottomCenter
        infoAnchorTo: Qore.TopCenter
        parent: root.shape ?? root
        point: root.controller.extBL
        color: pCtrl.extPointColor
        visible: root.showExtPoints
    }

    PointIndicator {
        name: "extBR"
        infoAnchorFrom: Qore.BottomCenter
        infoAnchorTo: Qore.TopCenter
        parent: root.shape ?? root
        point: root.controller.extBR
        color: pCtrl.extPointColor
        visible: root.showExtPoints
    }

    PointIndicator {
        name: "extLT"
        infoAnchorFrom: Qore.LeftCenter
        infoAnchorTo: Qore.RightCenter
        parent: root.shape ?? root
        point: root.controller.extLT
        color: pCtrl.extPointColor
        visible: root.showExtPoints
    }

    PointIndicator {
        name: "extLB"
        infoAnchorFrom: Qore.LeftCenter
        infoAnchorTo: Qore.RightCenter
        parent: root.shape ?? root
        point: root.controller.extLB
        color: pCtrl.extPointColor
        visible: root.showExtPoints
    }

    PointIndicator {
        name: "extRT"
        infoAnchorFrom: Qore.RightCenter
        infoAnchorTo: Qore.LeftCenter
        parent: root.shape ?? root
        point: root.controller.extRT
        color: pCtrl.extPointColor
        visible: root.showExtPoints
    }

    PointIndicator {
        name: "extRB"
        infoAnchorFrom: Qore.RightCenter
        infoAnchorTo: Qore.LeftCenter
        parent: root.shape ?? root
        point: root.controller.extRB
        color: pCtrl.extPointColor
        visible: root.showExtPoints
    }

    PointIndicator {
        name: "intTL"
        infoAnchorFrom: Qore.BottomLeft
        infoAnchorTo: Qore.TopLeft
        parent: root.shape ?? root
        point: root.controller.intTL
        color: pCtrl.intPointColor
        visible: root.showIntPoints
    }

    PointIndicator {
        name: "intTR"
        infoAnchorFrom: Qore.BottomRight
        infoAnchorTo: Qore.TopRight
        parent: root.shape ?? root
        point: root.controller.intTR
        color: pCtrl.intPointColor
        visible: root.showIntPoints
    }

    PointIndicator {
        name: "intBL"
        infoAnchorFrom: Qore.TopLeft
        infoAnchorTo: Qore.BottomLeft
        parent: root.shape ?? root
        point: root.controller.intBL
        color: pCtrl.intPointColor
        visible: root.showIntPoints
    }

    PointIndicator {
        name: "intBR"
        infoAnchorFrom: Qore.RightTop
        infoAnchorTo: Qore.RightBottom
        parent: root.shape ?? root
        point: root.controller.intBR
        color: pCtrl.intPointColor
        visible: root.showIntPoints
    }

    PointIndicator {
        name: "intLT"
        infoAnchorFrom: Qore.RightBottom
        infoAnchorTo: Qore.LeftTop
        parent: root.shape ?? root
        point: root.controller.intLT
        color: pCtrl.intPointColor
        visible: root.showIntPoints
    }

    PointIndicator {
        name: "intLB"
        infoAnchorFrom: Qore.RightTop
        infoAnchorTo: Qore.LeftBottom
        parent: root.shape ?? root
        point: root.controller.intLB
        color: pCtrl.intPointColor
        visible: root.showIntPoints
    }

    PointIndicator {
        name: "intRT"
        infoAnchorFrom: Qore.LeftBottom
        infoAnchorTo: Qore.RightTop
        parent: root.shape ?? root
        point: root.controller.intRT
        color: pCtrl.intPointColor
        visible: root.showIntPoints
    }

    PointIndicator {
        name: "intRB"
        infoAnchorFrom: Qore.LeftTop
        infoAnchorTo: Qore.RightBottom
        parent: root.shape ?? root
        point: root.controller.intRB
        color: pCtrl.intPointColor
        visible: root.showIntPoints
    }
}
