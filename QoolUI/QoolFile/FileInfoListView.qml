import QtQuick
import QtQuick.Controls
import Qool
import Qool.Controls
import Qool.Controls.Components

import Qool.File

/*!
    \qmltype FileInfoListView
    \inqmlmodule Qool.File
    \brief 特化于 FileInfoListModel 的多选文件列表视图（多层插拔的 View 层）。

    与 FileInfoListModel 配套的特化视图，内置多选（MultiRowSelectionModel）与
    排序、去重等列表操作。多层插拔的 View 层：\c delegate 默认
    FileInfoDelegate，可整体替换；\c fileInfoDisplay 透传给 delegate 内的展示
    组件（默认 BasicFileInfoDisplay），可只替换展示组件而不丢失 Delegate 行为。
*/
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
