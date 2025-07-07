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
            ToolTip.text: model.note
            checkable: true
            ButtonGroup.group: pageButtons
            width: ListView.view.width
            onCheckedChanged: if (checked)
                                  root.current_url = "pages/" + model.page
        }
        implicitWidth: 100
    }
}
