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
        // 默认激活即可（无 when 门控）：组件完成前 target 为 null 时
        // Binding 静默，background 就绪后 target 绑定自动重求值生效。
        // （曾有误用 when: Component.completed——Component 无 completed
        // 属性，求值 undefined 导致 Binding 永不激活、背景色不跟随。）
    }
}
