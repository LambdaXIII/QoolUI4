import QtQuick
import QtQuick.Controls
import Qool
import Qool.Controls

Control {
    id: root

    property FileInfoListView target: parent

    readonly property bool targetContainsItem: root.target?.count > 0
    readonly property bool targetContainsSelection: targetContainsItem
                                                    && root.target.containsSelection

    Style.active.buttonText: Style.active.infoColor
    Style.disabled.buttonText: Qt.darker(Style.active.negative, 1.5)

    contentItem: Flow {
        spacing: 4
        ActionInstantiator {
            Action {
                text: qsTr("全选")
                enabled: root.targetContainsItem
                onTriggered: {
                    root.target.selectAll();
                }
            }
            Action {
                text: qsTr("反选")
                enabled: root.targetContainsSelection
                onTriggered: {
                    root.target.toggleAll();
                }
            }
            Action {
                text: qsTr("取消选择")
                enabled: root.targetContainsSelection
                onTriggered: {
                    root.target.clearSelection();
                }
            }
            Action {
                text: qsTr("移除选择")
                enabled: root.targetContainsSelection
                onTriggered: {
                    let rows = root.target.selectedRows();
                    root.target.removeRows(rows);
                }
            }
            Action {
                text: qsTr("移除所有")
                enabled: root.targetContainsItem
                onTriggered: {
                    root.target.clear();
                }
            }
            Action {
                text: qsTr("自动排序")
                enabled: root.targetContainsItem
                onTriggered: {
                    root.target.sortFileInfos();
                }
            }
            Action {
                text: qsTr("移除重复")
                enabled: root.targetContainsItem
                onTriggered: {
                    root.target.removeDuplicates();
                }
            }
        }
    }//contentItem

    padding: 2
    topInset: 5
    bottomInset: 5
}
