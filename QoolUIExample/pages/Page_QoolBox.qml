import QtQuick
import QtQuick.Controls
import Qool
import Qool.Controls
import "components"
import Qool.Debug

BasicPage {
    id: root
    title: qsTr("QoolBox")
    note: qsTr("酷酷的 Box")

    OctagonShapeHud {
        id: hud
        parent: box_shape.shape
        showExtPoints: control.showExtPoints
        showIntPoints: control.showIntPoints
    }

    SplitView {
        id: cc
        anchors.fill: parent

        Item {
            id: shapeFace
            SplitView.fillHeight: true
            SplitView.fillWidth: true
            clip: true

            QoolBox {
                id: box_shape
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
                    cutSizesLocked: control.lockCorners
                    offsetX: control.offsetX
                    offsetY: control.offsetY
                }
                curved: control.rounded
            }

            z: -1
        }

        QoolBoxShapeControlPanel {
            id: control
            SplitView.fillHeight: true
            SplitView.preferredWidth: implicitWidth
            onWannaDumpInfo: shape.shapeControl.dumpInfo()
        }
    } //cc
}
