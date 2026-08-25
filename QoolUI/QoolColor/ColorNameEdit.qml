import QtQuick
import Qool
import Qool.Controls
import Qool.Color
import "_private"

EditableText {
    id: root

    property color value: "white"

    font: PixelFont.normal

    displayItem: ColorNumText {
        horizontalAlignment: Text.AlignRight
        font: root.font
        text: pCtrl.valueColorName
    }
    SmartObject {
        id: pCtrl
        readonly property string valueColorName: ColorNameHQ.colorName(root.value)
        onValueColorNameChanged: ensure_text()

        function ensure_text() {
            root.text = valueColorName;
        }
        Connections {
            target: root
            function onTextChanged() {
                let t = root.text;
                if (t === pCtrl.valueColorName)
                    return;
                if (ColorNameHQ.isValidColorName(t))
                    root.value = ColorNameHQ.color(t);
                else
                    pCtrl.ensure_text(); //撤回一次
            }//onTextChanged
        }//Connections

    }//pCtrl

    Component.onCompleted: pCtrl.ensure_text()
}
