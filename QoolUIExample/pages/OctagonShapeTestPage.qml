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
        }
        z: -1
    }

    OctagonShapeControlPanel {
        id: control
        SplitView.fillHeight: true
        SplitView.preferredWidth: implicitWidth
    }
}
