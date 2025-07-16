import QtQuick
import QtQuick.Controls

import Qool
import Qool.Controls
import Qool.Controls.Components
import Qool.Debug
import "pages"

QoolWindow {
    id: root
    objectName: "XXXX"
    width: 1024
    height: 720
    visible: true
    title: qsTr("Hello, Qool World!")

    Style.theme: "midnight"

    ButtonGroup {
        id: langGroup
    }
    toolBar: Flow {
        ToolButton {
            text: "ZH"
            width: 65
            checkable: true
            ButtonGroup.group: langGroup
        }
        ToolButton {
            text: "EN"
              width: 65
            checkable: true
            ButtonGroup.group: langGroup
        }
    }

    content: SplitView {
        PageListView {
            id: tocView
            SplitView.minimumWidth: 80
            SplitView.maximumWidth: 300
            SplitView.fillHeight: true
        }
        PageFrame {
            SplitView.fillWidth: true
            SplitView.fillHeight: true
            page_url: tocView.current_url
        }
    } //content

    // backgroundSettings.borderWidth: 1

    // QoolWindowHud {
    //     window: root
    // }
    Component.onCompleted: Qore.test()
}
