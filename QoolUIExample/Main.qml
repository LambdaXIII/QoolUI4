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
            cutSizeTL: 60
            cutSizeBL: 20
            cutSizeTR: 60
            cutSizeBR: 100
            fillColor: "green"
        }
    }
}
