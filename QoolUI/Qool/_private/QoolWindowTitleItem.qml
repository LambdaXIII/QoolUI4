import QtQuick
import QtQuick.Window
import Qool

Text {
    id: root
    color: Window.window.active ? palette.accent : palette.windowText
    font.pointSize: Style.windowTitleTextSize
    horizontalAlignment: Text.AlignRight
    verticalAlignment: Text.AlignVCenter
    leftPadding: 10
    rightPadding: 10
}
