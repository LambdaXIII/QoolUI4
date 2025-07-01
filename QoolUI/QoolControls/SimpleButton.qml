import QtQuick
import QtQuick.Templates as T
import Qool
import Qool.Controls.Components

T.AbstractButton {
    id: root

    property bool animationEnabled: parent?.animationEnabled
                                    ?? Qore.animationEnabled

    property color backgroundColor: palette.button
    property color textColor: palette.buttonText
    property color highlightColor: palette.highlight
    property color highlightedTextColor: palette.highlightedText
    property real radius: Math.max(2, Math.floor(Qore.style.controlCutSize / 2))
    property real borderWidth: QoolConstants.controlBorderWidth
    property color borderColor: palette.midlight

    font.pixelSize: Qore.style.controlTextSize
    hoverEnabled: enabled

    //TODO: Create a way to provide disable colors
    contentItem: BasicButtonText {
        text: root.action?.text ?? root.text
        color: {
            if (!root.enabled)
                return Qore.style.negative
            return root.checked ? root.highlightedTextColor : root.textColor
        }
        leftPadding: root.radius
        rightPadding: root.radius
        font: root.font
        BasicColorBehavior on color {
            enabled: root.animationEnabled
        }
    }
    padding: root.borderWidth + Math.round(root.radius / 2)

    implicitWidth: leftPadding + implicitContentWidth + rightPadding
    implicitHeight: topPadding + implicitContentHeight + bottomPadding

    background: Rectangle {
        implicitWidth: 5
        implicitHeight: 5
        radius: root.radius
        border.width: root.borderWidth
        border.color: {
            if (!root.enabled)
                return Qore.style.negative
            return (root.hovered
                    || root.checked) ? root.highlightColor : root.borderColor
        }
        color: {
            if (!root.enabled)
                return palette.window
            return root.checked ? root.highlightColor : root.backgroundColor
        }
    }

    Rectangle {
        anchors {
            fill: parent
            topMargin: parent.topInset
            bottomMargin: parent.bottomInset
            leftMargin: parent.leftInset
            rightMargin: parent.rightInset
        }
        z: 85
        radius: parent.radius
        border.width: root.borderWidth
        border.color: root.highlightColor
        gradient: Gradient {
            orientation: Gradient.Vertical
            stops: [
                GradientStop {
                    position: 0.1
                    color: "transparent"
                },
                GradientStop {
                    position: 1
                    color: Qt.alpha(root.highlightColor, 0.1)
                }
            ]
        }
        opacity: root.hovered ? 1 : 0
        BasicNumberBehavior on opacity {
            enabled: root.animationEnabled
        }
    }

    Rectangle {
        id: cover
        visible: root.down
        anchors {
            fill: parent
            topMargin: parent.topInset
            bottomMargin: parent.bottomInset
            leftMargin: parent.leftInset
            rightMargin: parent.rightInset
        }
        z: 90
        radius: parent.radius
        color: root.highlightColor
        border.width: root.borderWidth
        border.color: root.highlightedTextColor
        PaPaWall {
            id: papaWall
            clip: true
            highColor: "transparent"
            lowColor: root.highlightedTextColor
            anchors.fill: parent
            anchors.topMargin: 1
            anchors.bottomMargin: 1
            anchors.leftMargin: root.radius + 1
            anchors.rightMargin: root.radius + 1
        }
        onVisibleChanged: if (!visible)
                              papaWall.refresh()
    } //cover
}
