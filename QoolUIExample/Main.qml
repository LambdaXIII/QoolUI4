import QtQuick
import Qool

Window {
    width: 640
    height: 480
    visible: true
    title: qsTr("Hello World")

    MyItem {
        id: myitem
    }

    Text {
        text: myitem.greeting()
        anchors.centerIn: parent
    }
}
