import QtQuick
import QtQuick.Controls
import "_private"

Floater {
    id: root

    property string name
    property bool showName: true
    property bool showPosition: true
    property bool showSize: true
    property color color: palette.highlight
    property bool solid: false
    property real borderWidth: 1

    Component {
        id: bgBox
        Rectangle {
            implicitWidth: 10
            implicitHeight: 10
            color: root.color
        }
    }

    QtObject {
        id: pCtrl
        readonly property color textColor: StyleDB.recommendForeground(
                                               root.color, palette.button,
                                               palette.buttonText)
    }

    floatingItem: Item {
        implicitWidth: 10
        implicitHeight: 10
        Rectangle {
            id: box
            anchors.fill: parent
            border.width: root.borderWidth
            border.color: root.color
            color: root.solid ? Qt.alpha(root.color, 0.5) : "transparent"
        } //box
        Control {
            id: topLeftControl
            visible: root.showName || root.showPosition
            contentItem: Row {
                PropertyTipText {
                    visible: root.showName
                    valueColor: pCtrl.textColor
                    displayValue: root.name
                }
                PropertyTipText {
                    title: "x"
                    titleColor: Qore.style.negative
                    displayValue: root.x
                    valueColor: pCtrl.textColor
                    visible: root.showPosition
                }
                PropertyTipText {
                    title: "y"
                    titleColor: Qore.style.positive
                    displayValue: root.y
                    valueColor: pCtrl.textColor
                    visible: root.showPosition
                }
            } //contentItem
            background: bgBox.createObject()
        } //topLeftControl

        Control {
            id: topRightControl
            visible: root.showSize
            anchors.right: parent.right
            anchors.top: parent.top
            contentItem: PropertyTipText {
                title: "width"
                titleColor: Qore.style.negative
                displayValue: root.width
                valueColor: pCtrl.textColor
            }
            background: bgBox.createObject()
        }
        Control {
            id: bottomLeftControl
            visible: root.showSize
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            contentItem: PropertyTipText {
                title: "height"
                titleColor: Qore.style.positive
                displayValue: root.height
                valueColor: pCtrl.textColor
            }
            background: bgBox.createObject()
        }
        Control {
            id: bottomRightControl
            visible: root.showPosition
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            contentItem: Row {
                PropertyTipText {
                    title: "x"
                    titleColor: Qore.style.negative
                    displayValue: root.x + root.width
                    valueColor: pCtrl.textColor
                    visible: root.showPosition
                }
                PropertyTipText {
                    title: "y"
                    titleColor: Qore.style.positive
                    displayValue: root.y + root.height
                    valueColor: pCtrl.textColor
                    visible: root.showPosition
                }
            } //contentItem
            background: bgBox.createObject()
        } //topLeftControl
    } //floatingItem
}
