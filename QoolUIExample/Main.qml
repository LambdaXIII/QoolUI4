import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Qool

Window {
    width: 600
    height: 400
    visible: true
    title: qsTr("Hello World")

    OctagonShape {
        id: shape
        anchors.fill: parent
        settings {
            borderWidth: 40
            cutSizes: "80"
            fillColor: "green"
        }

        Component.onCompleted: shape.shapeControl.dumpInfo()
    }
}
