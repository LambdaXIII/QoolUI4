import QtQuick
import Qool

Item {
    id: root

    property OctagonShape shape: parent as OctagonShape

    readonly property OctagonShapeHelper controller: shape?.shapeControl ?? internalController

    OctagonShapeHelper {
        id: internalController
    }

    QtObject {
        id: pCtrl
        property color extPointColor: "darkgreen"
        property color intPointColor: "darkred"
    }

    PointIndicator {
        name: "extTL"
        infoPosition: Qore.TopCenter
        parent: root.shape ?? root
        point: root.controller.extTL
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extTR"
        infoPosition: Qore.TopCenter
        parent: root.shape ?? root
        point: root.controller.extTR
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extBL"
        infoPosition: Qore.BottomCenter
        parent: root.shape ?? root
        point: root.controller.extBL
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extBR"
        infoPosition: Qore.BottomCenter
        parent: root.shape ?? root
        point: root.controller.extBR
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extLT"
        infoPosition: Qore.LeftCenter
        parent: root.shape ?? root
        point: root.controller.extLT
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extLB"
        infoPosition: Qore.LeftCenter
        parent: root.shape ?? root
        point: root.controller.extLB
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extRT"
        infoPosition: Qore.RightCenter
        parent: root.shape ?? root
        point: root.controller.extRT
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extRB"
        infoPosition: Qore.RightCenter
        parent: root.shape ?? root
        point: root.controller.extRB
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "intTL"
        infoPosition: Qore.BottomRight
        parent: root.shape ?? root
        point: root.controller.intTL
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intTR"
        infoPosition: Qore.BottomLeft
        parent: root.shape ?? root
        point: root.controller.intTR
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intBL"
        infoPosition: Qore.TopRight
        parent: root.shape ?? root
        point: root.controller.intBL
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intBR"
        infoPosition: Qore.TopLeft
        parent: root.shape ?? root
        point: root.controller.intBR
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intLT"
        infoPosition: Qore.RightBottom
        parent: root.shape ?? root
        point: root.controller.intLT
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intLB"
        infoPosition: Qore.RightTop
        parent: root.shape ?? root
        point: root.controller.intLB
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intRT"
        infoPosition: Qore.LeftBottom
        parent: root.shape ?? root
        point: root.controller.intRT
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intRB"
        infoPosition: Qore.LeftTop
        parent: root.shape ?? root
        point: root.controller.intRB
        color: pCtrl.intPointColor
    }
}
