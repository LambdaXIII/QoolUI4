import QtQuick
import Qool
import Qool.DebugControls
import "pages"

QoolWindow {
    id: root
    width: 1024
    height: 720
    visible: true
    title: qsTr("Hello World")

    content: OctagonShapeTestPage {}

    RectIndicator {
        name: "content"
        color:"red"
        parent: root.content
    }
}
