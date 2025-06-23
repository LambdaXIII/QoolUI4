import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Qool

SlimPopup {
    id: root
    property QoolWindow window: parent
    // popupType: Popup.Native
    width: root.window.dummyItems.content.width
    height: root.window.dummyItems.content.height
    x: root.window.dummyItems.content.x
    y: root.window.dummyItems.content.y
    contentItem: Rectangle {
        color: "transparent"
        border.width: 1
        border.color: "red"
    }
    enabled: false
}
