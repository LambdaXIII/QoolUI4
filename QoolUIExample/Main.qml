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

    // Style.theme: "midnight"

    toolBar: MainWindowToolBar {}

    header: Row {
        ToolButton {
            text: "CHANGE"
            onClicked: {
                root.Style.theme = root.Style.theme === "system" ? "midnight" :
                                                                   "system";
                pageFrame.Style.theme = root.Style.theme;
            }
        }
        ToolButton {
            text: "DEBUG"
            onClicked: {
                console.log(pageFrame.Style.controlBorderColor,
                            pageFrame.backgroundSettings.borderColor);
                console.log(root.Style.window, root.backgroundSettings.fillColor);
            }
        }
        ToolButton {
            text: "DEBUG2"
            onClicked: {
                root.Style.dumpAllChildren();
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
