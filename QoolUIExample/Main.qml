import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Qool

Window {
    width: 640
    height: 480
    visible: true
    title: qsTr("Hello World")

    OctagonRoundedShape {
        id: shape
        anchors.fill: parent
        settings {
            borderWidth: 80
            cutSizes: "20 30 40 60"
            fillColor: "green"
        }

        Component.onCompleted: shape.shapeControl.dumpInfo()
    }
}
