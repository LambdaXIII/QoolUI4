pragma ValueTypeBehavior: Addressable

import QtQuick
import QtQuick.Controls
import Qool
import QtQuick.Shapes
import Qool.Controls.Components
import Qool.Controls
import Qool.File

BasicPage {
    id: root

    title: qsTr("试炼场")
    note: qsTr("测试一些东西……")

    FileInfoListControl {}

    Component.onCompleted: {
        let a = "c:/windows";
        let b = a as fileinfo;
        console.log(b);
    }
}
