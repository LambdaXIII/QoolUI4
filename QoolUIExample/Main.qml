import QtQuick
import QtQuick.Controls

import Qool
import Qool.Controls.Components
import Qool.Debug
import "pages"

QoolWindow {
    id: root
    width: 1024
    height: 720
    visible: true
    title: qsTr("Hello World")

    palette: QoolPalette {
        theme: "midnight"
    }
    QoolWindowHud {
        window: root
    }
    content: SplitView {
        PageListView {
            SplitView.minimumWidth: 80
            SplitView.maximumWidth: 300
            SplitView.fillHeight: true
        }
        BasicControlFrame {
            title: qsTr("内容")
            SplitView.fillWidth: true
            SplitView.fillHeight: true

            ControlLockedCover {}
        }
    } //content

    // Component.onCompleted: Qore.style.dumpInfo()
}
