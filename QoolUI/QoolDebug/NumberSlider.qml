import QtQuick
import QtQuick.Controls.Basic
import "_private"

DBGControl {
    id: root

    property real from: 0
    property real to: 100
    property real value: defaultValue
    property real defaultValue: 50
    property string name
    property bool checkBeforeSet: true
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
            field.selectAll()
        }
        function end_edit() {
            field.focus = false
            field.visible = false
            let input_number = parseFloat(field.text)
            if (input_number !== null)
                root.value = root.checkBeforeSet ? check_value(
                                                       input_number) : input_number
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

    contentItem: Item {
        implicitWidth: 150
        implicitHeight: 24
        Text {
            id: nameText
            text: root.name
            font.pixelSize: 12
            anchors.top: parent.top
            anchors.left: parent.left
            color: Style.buttonText
        }

        Text {
            id: displayText
            font.pixelSize: 20
            text: pCtrl.format_value(root.value)
            anchors.fill: parent
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignBottom
            color: Style.buttonText
            fontSizeMode: Text.Fit
        }

        TextField {
            id: field
            focusReason: Qt.OtherFocusReason
            verticalAlignment: TextField.AlignVCenter
            visible: false
            width: Math.max(parent.width, implicitWidth)
            height: Math.max(parent.height, implicitHeight)
            anchors.centerIn: parent
            z: 20
            onEditingFinished: pCtrl.end_edit()
        } //TextField

        Rectangle {
            border.width: 0
            color: mArea.dragging ? Style.highlight : Style.mid
            height: parent.height
            width: parent.width * root.percent
            radius: 4
            z: -10
        }
    } //contentItem

    background: Rectangle {
        color: Style.button
        border.color: Style.buttonText
        border.width: 1
        radius: 4
    }

    MouseArea {
        id: mArea
        containmentMask: root.background
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        anchors.fill: root.contentItem
        cursorShape: Qt.CrossCursor
        onDoubleClicked: root.reset()
        onClicked: e => {
                       if (dragging) {
                           e.accepted = false
                           return
                       }
                       if (e.button === Qt.LeftButton) {
                           root.value = pCtrl.value_from_mouseX(mouseX)
                       }
                       if (e.button === Qt.RightButton) {
                           pCtrl.start_edit()
                       }
                   }
        property bool dragging: false
        onPressed: dragging = true
        onReleased: dragging = false
        onMouseXChanged: {
            if (!dragging)
                return
            root.value = pCtrl.value_from_mouseX(mouseX)
        }

        onEnabledChanged: dragging = false
    }
}
