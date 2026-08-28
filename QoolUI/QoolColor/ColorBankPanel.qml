pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qool
import Qool.Color
import "_private"

GridLayout {
    id: root

    property int cells: 24

    property ColorBank colorBank: ColorBank {}

    property color color: "transparent"

    columns: 6
    columnSpacing: 8
    rowSpacing: 6

    Component {
        id: cell
        ColorPreviewer {
            id: cellControl
            required property int index
            color: root.colorBank.cellColor(index)
            radius: 4
            implicitWidth: 50
            implicitHeight: 30
            horizontalRatio: 0.8
            backgroundColor1: "lightGray"
            backgroundColor2: "darkGray"
            enabled: root.color !== cellControl.color
            Connections {
                target: root.colorBank
                function onCellColorUpdated(i) {
                    if (i === cellControl.index)
                        cellControl.color = root.colorBank.cellColor(index);
                }
            }
            AbstractButton {
                width: parent.width / 2
                height: parent.height
                contentItem: ColorNumText {
                    text: "S"
                    horizontalAlignment: Text.AlignHCenter
                    opacity: enabled && parent.hovered ? 1 : 0
                    color: ThemeHQ.recommendForeground(cellControl.color)
                }
                onClicked: root.colorBank.setCellColor(cellControl.index, root.color)
            }
            AbstractButton {
                width: parent.width / 2
                height: parent.height
                x: parent.width / 2
                contentItem: ColorNumText {
                    text: "L"
                    horizontalAlignment: Text.AlignHCenter
                    opacity: enabled && parent.hovered ? 1 : 0
                    color: ThemeHQ.recommendForeground(cellControl.color)
                }

                onClicked: root.color = cellControl.color
            }
        }
    }

    Repeater {
        model: root.cells
        delegate: cell
    } //Repeater
}
