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
                id: view
                allowDirectInsertion: true
                width: parent.width
                height: parent.height - bar.height
            }

            FileInfoListViewToolBar {
                id: bar
                target: view
                width: parent.width
                y: view.height
            }
        }

        padding: 5

        width: 400
        height: 600
    }
}
