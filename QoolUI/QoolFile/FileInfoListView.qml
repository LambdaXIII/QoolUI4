import QtQuick
import QtQuick.Controls
import Qool
import Qool.Controls
import Qool.Controls.Components
import Qool.Models

import Qool.File

ListView {
    id: root

    property Component fileInfoDisplay: BasicFileInfoDisplay {}

    property MultiRowSelectionModel selectionModel: MultiRowSelectionModel {
        model: root.model
    }

    property bool allowDirectInsertion: false

    readonly property bool containsSelection: pCtrl.containsSelection
    readonly property FileInfoListModel fileInfoListModel: model

    boundsBehavior: Flickable.DragOverBounds

    model: FileInfoListModel {}

    SmartObject {
        id: pCtrl
        property bool containsSelection
        Connections {
            target: root.selectionModel
            function onSelectionChanged() {
                pCtrl.containsSelection = selectionModel.selectedRows().length > 0;
            }
        }
    }

    delegate: FileInfoDelegate {
        allowDirectInsertion: root.allowDirectInsertion
        selectionModel: root.selectionModel
        fileInfoListModel: root.fileInfoListModel
        fileInfoDisplay: root.fileInfoDisplay
    }

    BasicDecorativeText {
        id: emptyText
        visible: root.count === 0
        anchors.centerIn: parent
        z: -10
        text: root.allowDirectInsertion ? qsTr("直接拖入文件即可添加") : qsTr("<空>")
    }

    DropArea {
        id: defaultDropZone
        anchors.fill: parent
        z: -10
        enabled: root.allowDirectInsertion && root.count === 0
        onDropped: e => {
                       if (e.hasUrls)
                       root.fileInfoListModel.append(e.urls);
                   }
    }

    function selectAll() {
        selectionModel.selectAll();
    }

    function toggleAll() {
        selectionModel.toggleAll();
    }

    function clearSelection() {
        selectionModel.clear();
    }

    function selectedRows() {
        return selectionModel.selectedRows();
    }

    function selectedFileInfos() {
        let rows = selectionModel.selectedRows();
        return fileInfoListModel.getFileInfos(rows);
    }

    function clear() {
        fileInfoListModel.clear();
    }

    function removeRows(rows) {
        fileInfoListModel.remove(rows);
    }

    function sortFileInfos() {
        fileInfoListModel.sortInfos(false);
    }

    function arrangeFileInfos() {
        fileInfoListModel.sortInfos(true);
    }

    function removeDuplicates() {
        fileInfoListModel.removeDuplicates();
    }
}
