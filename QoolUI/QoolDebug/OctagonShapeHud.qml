import QtQuick
import Qool

Item {
    id: root

    property var shape: parent

    readonly property OctagonShapeHelper controller: shape?.shapeControl
                                                     ?? internalController

    OctagonShapeHelper {
        id: internalController
    }

    QtObject {
        id: pCtrl
        property color extPointColor: Qore.style.positive
        property color intPointColor: Qore.style.negative
    }

    PointIndicator {
        name: "extTL"
        infoAnchorFrom: Qore.TopCenter
        infoAnchorTo: Qore.BottomCenter
        parent: root.shape ?? root
        point: root.controller.extTL
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extTR"
        infoAnchorFrom: Qore.TopCenter
        infoAnchorTo: Qore.BottomCenter
        parent: root.shape ?? root
        point: root.controller.extTR
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extBL"
        infoAnchorFrom: Qore.BottomCenter
        infoAnchorTo: Qore.TopCenter
        parent: root.shape ?? root
        point: root.controller.extBL
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extBR"
        infoAnchorFrom: Qore.BottomCenter
        infoAnchorTo: Qore.TopCenter
        parent: root.shape ?? root
        point: root.controller.extBR
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extLT"
        infoAnchorFrom: Qore.LeftCenter
        infoAnchorTo: Qore.RightCenter
        parent: root.shape ?? root
        point: root.controller.extLT
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extLB"
        infoAnchorFrom: Qore.LeftCenter
        infoAnchorTo: Qore.RightCenter
        parent: root.shape ?? root
        point: root.controller.extLB
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extRT"
        infoAnchorFrom: Qore.RightCenter
        infoAnchorTo: Qore.LeftCenter
        parent: root.shape ?? root
        point: root.controller.extRT
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extRB"
        infoAnchorFrom: Qore.RightCenter
        infoAnchorTo: Qore.LeftCenter
        parent: root.shape ?? root
        point: root.controller.extRB
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "intTL"
        infoAnchorFrom: Qore.BottomLeft
        infoAnchorTo: Qore.TopLeft
        parent: root.shape ?? root
        point: root.controller.intTL
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intTR"
        infoAnchorFrom: Qore.BottomRight
        infoAnchorTo: Qore.TopRight
        parent: root.shape ?? root
        point: root.controller.intTR
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intBL"
        infoAnchorFrom: Qore.TopLeft
        infoAnchorTo: Qore.BottomLeft
        parent: root.shape ?? root
        point: root.controller.intBL
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intBR"
        infoAnchorFrom: Qore.RightTop
        infoAnchorTo: Qore.RightBottom
        parent: root.shape ?? root
        point: root.controller.intBR
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intLT"
        infoAnchorFrom: Qore.RightBottom
        infoAnchorTo: Qore.LeftTop
        parent: root.shape ?? root
        point: root.controller.intLT
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intLB"
        infoAnchorFrom: Qore.RightTop
        infoAnchorTo: Qore.LeftBottom
        parent: root.shape ?? root
        point: root.controller.intLB
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intRT"
        infoAnchorFrom: Qore.LeftBottom
        infoAnchorTo: Qore.RightTop
        parent: root.shape ?? root
        point: root.controller.intRT
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intRB"
        infoAnchorFrom: Qore.LeftTop
        infoAnchorTo: Qore.RightBottom
        parent: root.shape ?? root
        point: root.controller.intRB
        color: pCtrl.intPointColor
    }
}
