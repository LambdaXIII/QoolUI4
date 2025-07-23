import QtQuick
import Qool
import QtQuick.Shapes
import Qool.Controls.Components
import Qool.Controls
import Qool.File

BasicPage {
    id: root

    title: qsTr("试炼场")
    note: qsTr("测试一些东西……")

    BasicControl {

        contentItem: Item {
            FileInfoListView {
                allowDirectInsertion: true
                width: parent.width
                height: parent.height - toolBar.height
            }

            FileInfoListViewToolBar {
                id: toolBar
                width: parent.width
            }
        }
        width: 400
        height: 600
    }
}
