import QtQuick
import QtQuick.Dialogs
import "_private"

/*!
    \qmltype ColorButton
    \inqmlmodule Qool.Debug
    \brief 调色按钮：右键弹出颜色选择对话框，双击重置为默认色。

    调试工具：显示 \c name 标签，背景色同步当前 \c value。交互——
    右键单击弹出 ColorDialog 选择颜色（\c value 随之更新）；左键双击
    重置为 \c defaultValue；悬停显示手型光标。
*/

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

/*!
    \qmlproperty color Qool::ColorButton::value
    \brief 当前颜色。经对话框选择或 reset() 更新；背景色同步。
*/

/*!
    \qmlproperty color Qool::ColorButton::defaultValue
    \brief 默认颜色（默认 "darkgrey"），reset() 的复位目标。
*/

/*!
    \qmlproperty string Qool::ColorButton::name
    \brief 按钮显示标签。
*/

/*!
    \qmlmethod void Qool::ColorButton::reset()
    \brief 重置 value 为 defaultValue。
*/

/*!
    \qmlmethod void Qool::ColorButton::chooseColor()
    \brief 弹出颜色选择对话框（预选当前 value）。
*/
