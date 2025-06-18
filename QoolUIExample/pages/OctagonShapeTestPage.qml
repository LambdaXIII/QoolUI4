import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qool
import "components"
import Qool.DebugControls

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
                fillColor: control.fillColor
                borderColor: control.borderColor
            }

            PointIndicator {
                name: "extTL"
                textPosition: Qool.TopLeft
                point: shape.shapeControl.extTL
            }
            PointIndicator {
                name: "extTR"
                textPosition: Qool.TopRight
                point: shape.shapeControl.extTR
            }
        }
        z: -1
    }

    OctagonShapeControlPanel {
        id: control
        SplitView.fillHeight: true
        SplitView.preferredWidth: implicitWidth
        onWannaDumpInfo: shape.settings.dumpInfo()
    }
}
