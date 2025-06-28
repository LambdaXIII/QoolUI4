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

    // palette: QoolPalette {
    //     theme: "midnight"
    // }
    // QoolWindowHud {}
    content: SplitView {
        PageListView {
            SplitView.minimumWidth: 80
            SplitView.maximumWidth: 300
            SplitView.fillHeight: true
        }
        Control {
            SplitView.fillWidth: true
            SplitView.fillHeight: true
            background: OctagonShape {
                settings {
                    cutSize: Qore.style.controlCutSize
                    fillColor: palette.base
                    borderColor: palette.accent
                }
            }
        }
    } //content
}
