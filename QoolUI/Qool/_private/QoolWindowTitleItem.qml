import QtQuick
import QtQuick.Window

Text {
    id: root
    color: Window.window.active ? palette.accent : palette.windowText
    font.pointSize: QoolConstants.windowTitlePixelSize
    horizontalAlignment: Text.AlignRight
    verticalAlignment: Text.AlignVCenter
    leftPadding: 10
    rightPadding: 10
}
