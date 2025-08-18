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

    Dial {
        id: d
        width: 300
        height: 300

        startAngle: -30
        endAngle: 100
        onPositionChanged: console.log(endAngle)

        RectResizer {}
    }
}
