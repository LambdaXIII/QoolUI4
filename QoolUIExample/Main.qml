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

    OctagonShape {
        id: shape
        anchors.fill: parent
        settings {
            borderWidth: 60
            cutSizeTL: 20
            cutSizeBL: 160
            cutSizeTR: 60
            cutSizeBR: 100
            fillColor: "green"
        }
    }
}
