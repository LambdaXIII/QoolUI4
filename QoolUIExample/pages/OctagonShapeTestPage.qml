import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qool
import "components"

SplitView {
    id: root

    Item {
        id: shapeFace
        SplitView.fillHeight: true
        SplitView.fillWidth: true
        clip: true

        OctagonShape {
            id: shape
            anchors.centerIn: parent
            width: control.shapeWidth
            height: control.shapeHeight
            settings {
                borderWidth: control.borderWidth
                cutSizeTL: control.cutSizeTL
                cutSizeBL: control.cutSizeBL
                cutSizeTR: control.cutSizeTR
                cutSizeBR: control.cutSizeBR
            }

            PointIndicator {
                name: "extTL"
                position: shape.shapeControl.extTL
                textPos: PointIndicator.Top
            }
            PointIndicator {
                name: "extTR"
                position: shape.shapeControl.extTR
                textPos: PointIndicator.Top
            }
            PointIndicator {
                name: "extBL"
                position: shape.shapeControl.extBL
                textPos: PointIndicator.Bottom
            }
            PointIndicator {
                name: "extBR"
                position: shape.shapeControl.extBR
                textPos: PointIndicator.Bottom
            }
            PointIndicator {
                name: "extLT"
                position: shape.shapeControl.extLT
                textPos: PointIndicator.Left
            }
            PointIndicator {
                name: "extLB"
                position: shape.shapeControl.extLB
                textPos: PointIndicator.Left
            }
            PointIndicator {
                name: "extRT"
                position: shape.shapeControl.extRT
                textPos: PointIndicator.Right
            }
            PointIndicator {
                name: "extRB"
                position: shape.shapeControl.extRB
                textPos: PointIndicator.Right
            }
        }
        z: -1
    }

    OctagonShapeControlPanel {
        id: control
        SplitView.fillHeight: true
        SplitView.preferredWidth: implicitWidth
    }
}
