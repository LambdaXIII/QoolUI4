import QtQuick
import Qool
import Qool.File
import Qool.Controls
import Qool.Controls.Components
import Qool.Models

FileDropper {
    id: root

    property FileInfoListModel fileInfoListModel: FileInfoListModel {}
    property alias selectionModel: view.selectionModel

    title: qsTr("文件列表")

    contentItem: Item {
        FileInfoListView {
            id: view
            model: root.fileInfoListModel
            clip: true
            width: parent.width
            height: parent.height - bar.height
            ScrollBar.vertical: ScrollBar {}
        }

        FileInfoListViewToolBar {
            id: bar
            target: view
            width: parent.width
            y: view.height
        }

        BasicDecorativeText {
            text: qsTr("拖动到这里即可添加文件")
            anchors.centerIn: parent
            visible: view.count === 0
            z: -20
            opacity: 0.5
        }
    }

    padding: 5

    implicitWidth: 400
    implicitHeight: 400

    onAccepted: urls => root.fileInfoListModel.append(urls)
}
