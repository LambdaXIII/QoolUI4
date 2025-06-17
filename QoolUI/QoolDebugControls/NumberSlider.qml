import QtQuick
import QtQuick.Controls.Basic

Control {
    id: root

    property real from: 0
    property real to: 100
    property real value: defaultValue
    property real defaultValue: 50
    property string name
    readonly property real percent: value / (to - from)
    function reset() {
        root.value = root.defaultValue
    }

    QtObject {
        id: pCtrl
        function format_value(x) {
            let a = Math.round(x * 1000)
            return a / 1000
        }
        function check_value(x) {
            if (x < root.from)
                return root.from
            if (x > root.to)
                return root.to
            return x
        }

        function start_edit() {
            mArea.enabled = false
            nameText.visible = false
            displayText.visible = false
            field.text = root.value
            field.visible = true
            field.forceActiveFocus()
        }
        function end_edit() {
            field.focus = false
            field.visible = false
            let input_number = parseFloat(field.text)
            if (input_number)
                root.value = check_value(input_number)
            nameText.visible = true
            displayText.visible = true
            mArea.enabled = true
        }
        function value_from_mouseX(x) {
            let p = x / root.width
            let delta = (root.to - root.from) * p
            let result = root.from + delta
            return check_value(result)
        }
    }

    padding: 4

    contentItem: Item {
        implicitWidth: 150
        implicitHeight: 24
        Text {
            id: nameText
            text: root.name
            font.pixelSize: 8
            anchors.top: parent.top
            anchors.left: parent.left
            color: palette.text
        }

        Text {
            id: displayText
            font.pixelSize: 20
            text: pCtrl.format_value(root.value)
            anchors.fill: parent
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignBottom
            color: palette.text
            fontSizeMode: Text.Fit
        }

        TextField {
            id: field
            focusReason: Qt.OtherFocusReason
            visible: false
            anchors.fill: parent
            z: 20
            onEditingFinished: pCtrl.end_edit()
        } //TextField
    } //contentItem

    background: Item {
        Rectangle {
            color: palette.base
            anchors.fill: parent
            radius: 4
        }
        Rectangle {
            border.width: 0
            color: palette.accent
            height: parent.height
            width: parent.width * root.percent
            opacity: mArea.dragging ? 0.9 : 0.5
            radius: 4
        }
        Rectangle {
            border.width: 2
            border.color: palette.text
            color: "transparent"
            radius: 4
        }
    }

    MouseArea {
        id: mArea
        containmentMask: root.background
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        anchors.fill: contentItem
        cursorShape: Qt.CrossCursor
        onDoubleClicked: root.reset()
        onClicked: e => {
                       if (dragging)
                       return
                       if (e.button === Qt.LeftButton) {
                           root.value = pCtrl.value_from_mouseX(mouseX)
                       }
                       if (e.button === Qt.RightButton) {
                           pCtrl.start_edit()
                       }
                   }
        property bool dragging: false
        onPressAndHold: dragging = true
        onReleased: dragging = false
        onMouseXChanged: {
            if (!dragging)
                return
            root.value = pCtrl.value_from_mouseX(mouseX)
        }

        onEnabledChanged: dragging = false
    }
}
