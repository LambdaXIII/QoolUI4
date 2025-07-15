import QtQuick
import QtQuick.Controls
import Qool.Controls

Control {
    id: root

    property url current_url: "pages/Page_Welcome.qml"

    ButtonGroup {
        id: pageButtons
    }

    contentItem: ListView {
        model: PageListModel {}
        delegate: ClickableText {
            text: model.title
            checkable: true
            ButtonGroup.group: pageButtons
            width: ListView.view.width
            onCheckedChanged: if (checked)
                                  root.current_url = "pages/" + model.page

            ToolTip {
                visible: hovered
                delay: Application.styleHints.mousePressAndHoldInterval
                contentItem: Text {
                    text: model.note
                    color: Style.toolTipText
                }
                background: Rectangle {
                    color: Style.toolTipBase
                    border.width: 1
                    radius: 8
                    border.color: Style.toolTipText
                }
            }
        }
        implicitWidth: 100
    }
}
