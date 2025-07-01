import QtQuick
import QtQuick.Controls
import Qool
import "components"
import Qool.Debug

SplitView {
    id: root

    Item {
        id: shapeFace
        SplitView.fillHeight: true
        SplitView.fillWidth: true
        clip: true

        OctagonRoundedShape {
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

            OctagonShapeHud {}
        }
        z: -1

        RectIndicator {
            anchors.fill: parent
            color: "purple"
        }
    }

    OctagonShapeControlPanel {
        id: control
        SplitView.fillHeight: true
        SplitView.preferredWidth: implicitWidth
        onWannaDumpInfo: shape.shapeControl.dumpInfo()
    }
}
