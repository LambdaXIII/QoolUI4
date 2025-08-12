pragma ValueTypeBehavior: Addressable

import QtQuick
import QtQuick.Controls
import Qool
import QtQuick.Shapes
import Qool.Controls.Components
import Qool.Controls
import Qool.Debug

BasicPage {
    id: root

    title: qsTr("试炼场")
    note: qsTr("测试一些东西……")

    Rectangle {
        color: "transparent"
        border.width: 2
        border.color: "red"
        width: 400
        height: 400
        x: 50
        y: 50
        RectResizer {}
    }
}
