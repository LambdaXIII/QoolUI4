import QtQuick
import QtQuick.Dialogs
import "_private"

DBGControl {
    id: root
    property color value: defaultValue
    property color defaultValue: "darkgrey"
    property string name

    function reset() {
        root.value = defaultValue
    }

    function chooseColor() {
        dialog.selectedColor = root.value
        dialog.open()
    }

    ColorDialog {
        id: dialog
        onAccepted: {
            root.value = dialog.selectedColor
        }
    }

    contentItem: Item {
        implicitHeight: 24
        implicitWidth: 100
        Text {
            text: root.name
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 12
            fontSizeMode: Text.Fit
            color: Style.text
            anchors.centerIn: parent
        }
    } //contentItem

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.chooseColor()
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onDoubleTapped: root.reset()
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    Binding {
        target: root.background
        property: "color"
        value: root.value
        when: Component.completed
    }
}
