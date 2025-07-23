import QtQuick
import QtQuick.Controls
import Qool
import Qool.Controls

Item {
    id: root

    signal wannaSelectAll
    signal wannaToggleSelection
    signal wannaClearSelection
    signal wannaRemoveSelectedRows
    signal wannaClearAll

    Action {
        id: action_selectAll
        text: qsTr("全选")
        onTriggered: root.wannaSelectAll()
    }

    Action {
        id: action_reverseSelection
        text: qsTr("反选")
        onTriggered: root.wannaToggleSelection()
    }

    Action {
        id: action_clearSelection
        text: qsTr("取消选择")
        onTriggered: root.wannaClearSelection()
    }

    Action {
        id: action_removeSelectedRows
        text: qsTr("删除所选")
        onTriggered: root.wannaRemoveSelectedRows()
    }

    Action {
        id: action_clearAll
        text: qsTr("清空")
        onTriggered: root.wannaClearAll()
    }
}
