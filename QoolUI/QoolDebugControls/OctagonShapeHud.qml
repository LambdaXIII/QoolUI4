import QtQuick
import Qool

Item {
    id: root

    property OctagonShape shape: parent as OctagonShape

    readonly property OctagonShapeHelper controller: shape?.shapeControl
                                                     ?? internalController

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
        textPosition: Qool.Top
        parent: root.shape ?? root
        point: root.controller.extTL
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extTR"
        textPosition: Qool.Top
        parent: root.shape ?? root
        point: root.controller.extTR
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extBL"
        textPosition: Qool.Bottom
        parent: root.shape ?? root
        point: root.controller.extBL
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extBR"
        textPosition: Qool.Bottom
        parent: root.shape ?? root
        point: root.controller.extBR
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extLT"
        textPosition: Qool.Left
        parent: root.shape ?? root
        point: root.controller.extLT
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extLB"
        textPosition: Qool.Left
        parent: root.shape ?? root
        point: root.controller.extLB
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extRT"
        textPosition: Qool.Right
        parent: root.shape ?? root
        point: root.controller.extRT
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "extRB"
        textPosition: Qool.Right
        parent: root.shape ?? root
        point: root.controller.extRB
        color: pCtrl.extPointColor
    }

    PointIndicator {
        name: "intTL"
        textPosition: Qool.BottomRight
        parent: root.shape ?? root
        point: root.controller.intTL
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intTR"
        textPosition: Qool.BottomLeft
        parent: root.shape ?? root
        point: root.controller.intTR
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intBL"
        textPosition: Qool.TopRight
        parent: root.shape ?? root
        point: root.controller.intBL
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intBR"
        textPosition: Qool.TopLeft
        parent: root.shape ?? root
        point: root.controller.intBR
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intLT"
        textPosition: Qool.Right
        parent: root.shape ?? root
        point: root.controller.intLT
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intLB"
        textPosition: Qool.Right
        parent: root.shape ?? root
        point: root.controller.intLB
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intRT"
        textPosition: Qool.Left
        parent: root.shape ?? root
        point: root.controller.intRT
        color: pCtrl.intPointColor
    }

    PointIndicator {
        name: "intRB"
        textPosition: Qool.Left
        parent: root.shape ?? root
        point: root.controller.intRB
        color: pCtrl.intPointColor
    }
}
