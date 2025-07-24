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

    readonly property bool containsSelection: pCtrl.containsSelection
    readonly property FileInfoListModel fileInfoListModel: model

    acceptedButtons: Qt.NoButton
    boundsBehavior: Flickable.DragOverBounds
    model: FileInfoListModel {}

    cacheBuffer: 400

    SmartObject {
        id: pCtrl
        property bool containsSelection
        Connections {
            target: root.selectionModel
            function onSelectionChanged() {
                pCtrl.containsSelection = selectionModel.selectedRows(
                            ).length > 0
            }
        }
    }

    delegate: FileInfoDelegate {
        selectionModel: root.selectionModel
        fileInfoListModel: root.fileInfoListModel
        fileInfoDisplay: root.fileInfoDisplay
    }

    function selectAll() {
        selectionModel.selectAll()
    }

    function toggleAll() {
        selectionModel.toggleAll()
    }

    function clearSelection() {
        selectionModel.clear()
    }

    function selectedRows() {
        return selectionModel.selectedRows()
    }

    function selectedFileInfos() {
        let rows = selectionModel.selectedRows()
        return fileInfoListModel.getFileInfos(rows)
    }

    function clear() {
        fileInfoListModel.clear()
    }

    function removeRows(rows) {
        fileInfoListModel.remove(rows)
    }

    function sortFileInfos() {
        fileInfoListModel.sortInfos(false)
    }

    function arrangeFileInfos() {
        fileInfoListModel.sortInfos(true)
    }

    function removeDuplicates() {
        fileInfoListModel.removeDuplicates()
    }
}
