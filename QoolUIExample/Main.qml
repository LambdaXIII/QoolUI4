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

    header: Flow {
        Repeater {
            model: ThemeHQ.themes
            delegate: ToolButton {
                text: modelData
                checkable: true
                checked: root.Style.theme === modelData
                onClicked: root.Style.theme = modelData
            }
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
