import QtQuick
import QtQuick.Controls
import Qool
import Qool.Controls
import Qool.Color

ListView {
    id: root

    property string category: "DEFAULT"

    readonly property string currentColorName: ColorHQ.colorName(pCtrl.currentColor)
    readonly property color currentColor: pCtrl.currentColor

    model: ColorHQ.colorNames(root.category)

    ButtonGroup {
        id: colorBtnGroup
    }

    delegate: ColorNameButton {
        required property string modelData
        color: ColorHQ.color(modelData)
        text: modelData
        checkable: true
        ButtonGroup.group: colorBtnGroup
        width: ListView.view.width
        onCheckedChanged: if (checked)
            pCtrl.currentColor = color
    }

    SmartObject {
        id: pCtrl
        property color currentColor
    }

    implicitWidth: 250
    implicitHeight: 400
}
