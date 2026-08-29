import QtQuick
import QtQuick.Controls

import Qool
import Qool.Controls
import Qool.Controls.Components
import Qool.Debug
import "pages"

QoolWindow {
    id: root
    width: 1280
    height: 960
    visible: true
    title: qsTr("Hello, Qool World!")

    Style.theme: "midnight"

    toolBar: MainWindowToolBar {}

    content: SplitView {
        PageListView {
            id: tocView
            SplitView.minimumWidth: 80
            SplitView.maximumWidth: 300
            SplitView.fillHeight: true
        }
        PageFrame {
            id: pageFrame
            SplitView.fillWidth: true
            SplitView.fillHeight: true
            page_url: tocView.current_url
        }
    } //content

    Component.onCompleted: {
        root.Style.dumpInfo();
    }
}
