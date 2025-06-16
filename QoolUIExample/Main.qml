import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Qool
import "pages"

Window {
    width: 600
    height: 400
    visible: true
    title: qsTr("Hello World")

    OctagonShapeTestPage {
        anchors.fill: parent
    }
}
