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

    \qmlmethod void selectAll()

    全选所有行（等价 selectionModel.selectAll()）。

    \qmlmethod void toggleAll()

    反转所有行的选中状态。

    \qmlmethod void clearSelection()

    清空当前选中。

    \qmlmethod list<int> selectedRows()

    返回当前选中的行索引列表（来自 selectionModel.selectedRows()）。

    \qmlmethod list<fileinfo> selectedFileInfos()

    返回选中行对应的 FileInfo 对象列表。经
    \c fileInfoListModel.infos(rows) 查询——注意模型方法名是
    \c infos()（getFileInfos 不存在，调用会静默失败）。

    \qmlmethod void clear()

    清空模型数据（等价 fileInfoListModel.clear()）。

    \qmlmethod void removeRows(list<int> rows)

    按行索引列表移除数据（等价 fileInfoListModel.remove(rows)）。

    \qmlmethod void sortFileInfos()

    按路径排序且不去重（fileInfoListModel.sortInfos(false)）。

    \qmlmethod void arrangeFileInfos()

    按路径排序并去重（fileInfoListModel.sortInfos(true)）。

    \qmlmethod void removeDuplicates()

    移除列表中的重复项（等价 fileInfoListModel.removeDuplicates()）。
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
        // 模型方法名是 infos()（getFileInfos 不存在，调用会静默失败）
        return fileInfoListModel.infos(rows)
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
