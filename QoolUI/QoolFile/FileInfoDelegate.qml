import QtQuick
import QtQuick.Controls
import Qool
import Qool.File
import Qool.Models

Control {
    id: root

    required property fileinfo fileInfo
    required property int index
    required property MultiRowSelectionModel selectionModel
    required property FileInfoListModel fileInfoListModel

    property Component fileInfoDisplay: BasicFileInfoDisplay {}

    readonly property bool checked: pCtrl.checked

    width: parent?.width ?? ListView?.contentWidth ?? implicitWidth

    SmartObject {
        id: pCtrl

        readonly property color inserterColor: Qt.alpha(root.Style.positive,
                                                        0.8)
        readonly property real inserterSplitPos: 0.6

        property bool checked: root.selectionModel?.isRowSelected(root.index)
        property point old_position

        Connections {
            target: root.selectionModel
            function onSelectionChanged() {
                pCtrl.checked = root.selectionModel.isRowSelected(root.index)
            }
        }
    }

    contentItem: Loader {
        id: contentLoader
        sourceComponent: root.fileInfoDisplay
        Binding {
            target: contentLoader.item
            property: "checked"
            value: pCtrl.checked
        }

        Binding {
            target: contentLoader.item
            property: "fileInfo"
            value: root.fileInfo
        }
    }

    Drag.active: mouseArea.held
    Drag.dragType: Drag.Automatic
    Drag.hotSpot.y: root.height / 2
    Drag.hotSpot.x: root.width / 2

    MouseArea {
        id: mouseArea
        enabled: !dropZone.containsDrag
        anchors.fill: parent
        property bool held
        pressAndHoldInterval: 200
        onPressAndHold: {
            root.selectionModel.multiSelectRow(root.index, true)
            held = true
        }
        onReleased: held = false
        onClicked: ev => {
                       if (ev.modifiers & Qt.ShiftModifier) {
                           root.selectionModel.rangeSelectRow(root.index)
                       } else if (ev.modifiers & Qt.ControlModifier) {
                           root.selectionModel.multiSelectRow(root.index)
                       } else {
                           root.selectionModel.toggleRow(root.index)
                       }
                   }
        drag.target: mouseArea.held ? parent : undefined
        drag.axis: Drag.YAxis
    }

    DropArea {
        id: dropZone
        anchors.fill: parent
        z: 50
        readonly property bool isOnTop: containsDrag
                                        && drag.y <= height * pCtrl.inserterSplitPos
                                        && acceptable
        readonly property bool isOnBottom: containsDrag
                                           && drag.y > height * pCtrl.inserterSplitPos
                                           && acceptable
        readonly property bool acceptable: drag.source != root

        onDropped: ev => {
                       if (!acceptable) {
                           return
                       }
                       const source = ev.source as FileInfoDelegate
                       const targetIndex = isOnTop ? root.index : root.index + 1
                       if (source) {
                           let from = root.selectionModel.selectedRows()
                           if (from.length === 0) {
                               root.fileInfoListModel.move(source.index,
                                                           targetIndex)
                           } else {
                               from.push(source.index)
                               let new_rows = root.fileInfoListModel.move(
                                   from, targetIndex)
                               root.selectionModel.selectRows(new_rows)
                           }
                       } else if (ev.hasUrls) {
                           root.fileInfoListModel.insert(targetIndex, ev.urls)
                       }
                   }

        Rectangle {
            width: parent.width
            height: parent.height / 2
            z: 51
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                    position: 0
                    color: pCtrl.inserterColor
                }
                GradientStop {
                    position: 1
                    color: "transparent"
                }
            }
            opacity: dropZone.isOnTop ? 1 : 0
            BasicNumberBehavior on opacity {}
        }

        Rectangle {
            width: parent.width
            height: parent.height / 2
            y: parent.height / 2
            z: 51
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                    position: 1
                    color: pCtrl.inserterColor
                }
                GradientStop {
                    position: 0
                    color: "transparent"
                }
            }
            opacity: dropZone.isOnBottom ? 1 : 0
            BasicNumberBehavior on opacity {}
        }
    } //dropZone
}
