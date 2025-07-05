import QtQuick
import QtQuick.Controls

import Qool
import Qool.Controls
import Qool.Controls.Components
import Qool.Debug
import "pages"

QoolWindow {
    id: root
    width: 1024
    height: 720
    visible: true
    title: qsTr("Hello, Qool World!")

    palette: QoolPalette {
        theme: "midnight"
    }

    content: SplitView {
        PageListView {
            SplitView.minimumWidth: 80
            SplitView.maximumWidth: 300
            SplitView.fillHeight: true
        }
        ControlFrame {
            title: qsTr("内容")
            SplitView.fillWidth: true
            SplitView.fillHeight: true
            contentItem: Page_Playground {}
        }
    } //content

    // Component.onCompleted: Qore.style.dumpInfo()
    Component.onCompleted: console.log(Style.theme)
}
