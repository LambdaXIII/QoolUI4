import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Qool
import Qool.DebugControls
import "pages"

QoolWindow {
    width: 1024
    height: 720
    visible: true
    title: qsTr("Hello World")

    content: OctagonShapeTestPage {}
}
