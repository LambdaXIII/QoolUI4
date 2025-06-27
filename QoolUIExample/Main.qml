import QtQuick
import QtQuick.Controls
import Qool
import Qool.DebugControls
import "pages"

QoolWindow {
    id: root
    width: 1024
    height: 720
    visible: true
    title: qsTr("Hello World")

    content: PaletteSheet {}

    palette: QoolPalette {
        theme: "midnight"
    }

    Component.onCompleted: {
        console.log(StyleDB.count);
    }
}
