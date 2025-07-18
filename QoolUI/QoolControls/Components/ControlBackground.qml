import QtQuick
import Qool

QoolBox {
    id: root

    property string title

    //titleComponent must have a text property
    property Component titleComponent: BasicControlTitleText {
        color: root.settings.borderColor
    }

    settings {
        cutSize: Style.controlCutSize
        borderWidth: Style.controlBorderWidth
        borderColor: root.borderColor
        fillColor: root.backgroundColor
    }

    QtObject {
        id: pCtrl
    }
}
